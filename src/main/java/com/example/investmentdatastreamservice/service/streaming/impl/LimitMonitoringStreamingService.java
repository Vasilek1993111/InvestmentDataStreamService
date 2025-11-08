package com.example.investmentdatastreamservice.service.streaming.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.example.investmentdatastreamservice.repository.FutureRepository;
import com.example.investmentdatastreamservice.repository.IndicativeRepository;
import com.example.investmentdatastreamservice.repository.ShareRepository;
import com.example.investmentdatastreamservice.service.LimitMonitorService;
import com.example.investmentdatastreamservice.service.streaming.MultiStreamManager;
import com.example.investmentdatastreamservice.service.streaming.SubscriptionBatcher;
import com.example.investmentdatastreamservice.service.streaming.StreamingMetrics;
import com.example.investmentdatastreamservice.service.streaming.StreamingService;

import io.grpc.stub.StreamObserver;
import jakarta.annotation.PreDestroy;
import java.util.concurrent.TimeUnit;
import ru.tinkoff.piapi.contract.v1.LastPrice;
import ru.tinkoff.piapi.contract.v1.LastPriceInstrument;
import ru.tinkoff.piapi.contract.v1.MarketDataRequest;
import ru.tinkoff.piapi.contract.v1.MarketDataResponse;
import ru.tinkoff.piapi.contract.v1.SubscribeLastPriceRequest;
import ru.tinkoff.piapi.contract.v1.SubscribeLastPriceResponse;
import ru.tinkoff.piapi.contract.v1.SubscriptionAction;

/**
 * Сервис для мониторинга лимитов через поток LastPrice
 * 
 * Специализированный сервис для отслеживания приближения к лимитам инструментов
 * и отправки уведомлений в Telegram при достижении пороговых значений.
 * 
 * С поддержкой множественных stream-соединений для обхода лимита в 300 подписок.
 * 
 * Особенности:
 * - Разделяет инструменты на батчи по 250 штук
 * - Создает отдельное gRPC соединение для каждого батча
 * - Соблюдает rate limit: 100 запросов в минуту
 * - Автоматическое переподключение при ошибках
 */
@Service
public class LimitMonitoringStreamingService implements StreamingService<LastPrice> {
    
    private static final Logger log = LoggerFactory.getLogger(LimitMonitoringStreamingService.class);
    
    @Value("${tinkoff.api.token}")
    private String apiToken;
    
    private final LimitMonitorService limitMonitorService;
    private final ShareRepository shareRepository;
    private final FutureRepository futureRepository;
    private final IndicativeRepository indicativeRepository;
    
    private final AtomicBoolean isRunning = new AtomicBoolean(false);
    private final StreamingMetrics metrics;
    private final SubscriptionBatcher batcher;
    
    // Множественные stream-соединения
    private MultiStreamManager multiStreamManager;
    private final AtomicInteger successfulSubscriptions = new AtomicInteger(0);
    private final AtomicInteger failedSubscriptions = new AtomicInteger(0);
    
    public LimitMonitoringStreamingService(
            LimitMonitorService limitMonitorService,
            ShareRepository shareRepository,
            FutureRepository futureRepository,
            IndicativeRepository indicativeRepository) {
        
        this.limitMonitorService = limitMonitorService;
        this.shareRepository = shareRepository;
        this.futureRepository = futureRepository;
        this.indicativeRepository = indicativeRepository;
        this.metrics = new StreamingMetrics("LimitMonitoringStreamingService");
        this.batcher = new SubscriptionBatcher(); // 250 инструментов на батч
        
        log.info("LimitMonitoringStreamingService initialized with multi-stream support");
    }
    
    @Override
    public CompletableFuture<Void> start() {
        return CompletableFuture.runAsync(() -> {
            if (isRunning.get()) {
                log.warn("Limit monitoring streaming service is already running");
                return;
            }
            
            log.info("🚀 Запуск сервиса мониторинга лимитов с поддержкой множественных stream...");
            log.info("📊 Сервис будет отслеживать приближение к лимитам инструментов");
            log.info("📤 Уведомления будут отправляться в Telegram канал");
            isRunning.set(true);
            metrics.setRunning(true);
            successfulSubscriptions.set(0);
            failedSubscriptions.set(0);
            
            try {
                // Получаем список инструментов
                List<String> instruments = getAllInstruments();
                
                if (instruments.isEmpty()) {
                    log.warn("No instruments found for limit monitoring subscription");
                    isRunning.set(false);
                    metrics.setRunning(false);
                    return;
                }
                
                log.info("📊 Found {} instruments for limit monitoring subscription", instruments.size());
                
                // Разделяем на батчи
                List<List<String>> batches = batcher.createBatches(instruments);
                SubscriptionBatcher.BatchInfo batchInfo = batcher.getBatchInfo(instruments);
                
                log.info("📦 Created {} batches: {}", batches.size(), batchInfo);
                log.info("🔗 Each batch will use separate gRPC stream connection");
                
                // Создаем менеджер множественных стримов
                multiStreamManager = new MultiStreamManager(apiToken, batches.size());
                
                // Настраиваем общий response observer для всех стримов
                setupResponseObserver();
                
                // Создаем stream для каждого батча
                for (int i = 0; i < batches.size(); i++) {
                    multiStreamManager.createStreamForBatch(i);
                }
                
                // Подключаем все stream'ы
                multiStreamManager.connectAll()
                    .thenCompose(v -> {
                        log.info("✅ All stream connections established");
                        return subscribeAllBatches(batches);
                    })
                    .whenComplete((result, throwable) -> {
                        if (throwable != null) {
                            log.error("❌ Failed to start limit monitoring streaming", throwable);
                            isRunning.set(false);
                            metrics.setRunning(false);
                            scheduleReconnect();
                        } else {
                            log.info("🎉 Limit monitoring streaming service started successfully");
                            log.info("📈 Subscribed: {} successful, {} failed", 
                                successfulSubscriptions.get(), failedSubscriptions.get());
                        }
                    })
                    .join(); // Ждем завершения подписок
                
            } catch (Exception e) {
                log.error("❌ Error starting limit monitoring streaming service", e);
                isRunning.set(false);
                metrics.setRunning(false);
                scheduleReconnect();
            }
        });
    }
    
    /**
     * Подписывается на все батчи с соблюдением rate limit
     */
    private CompletableFuture<Void> subscribeAllBatches(List<List<String>> batches) {
        log.info("📡 Starting batch subscriptions with rate limiting...");
        
        List<CompletableFuture<Void>> futures = new ArrayList<>();
        
        for (int i = 0; i < batches.size(); i++) {
            final int batchIndex = i;
            final List<String> batch = batches.get(i);
            
            // Задержка между батчами для соблюдения rate limit (100 запросов/мин)
            long delayMs = i * SubscriptionBatcher.BATCH_DELAY_MS;
            
            log.info("📤 Preparing batch {}/{}: {} instruments (delay: {}ms)", 
                batchIndex + 1, batches.size(), batch.size(), delayMs);
            
            // Создаем запрос на подписку для батча
            SubscribeLastPriceRequest request = SubscribeLastPriceRequest.newBuilder()
                .setSubscriptionAction(SubscriptionAction.SUBSCRIPTION_ACTION_SUBSCRIBE)
                .addAllInstruments(batch.stream()
                    .map(figi -> LastPriceInstrument.newBuilder().setInstrumentId(figi).build())
                    .toList())
                .build();
            
            MarketDataRequest marketDataRequest = MarketDataRequest.newBuilder()
                .setSubscribeLastPriceRequest(request)
                .build();
            
            // Отправляем запрос через соответствующий stream с задержкой
            CompletableFuture<Void> future = multiStreamManager.sendBatchSubscription(
                batchIndex, marketDataRequest, delayMs)
                .whenComplete((result, throwable) -> {
                    if (throwable != null) {
                        log.error("❌ Failed to subscribe batch {}/{}", batchIndex + 1, batches.size(), throwable);
                    } else {
                        log.info("✅ Batch {}/{} subscription request sent", batchIndex + 1, batches.size());
                    }
                });
            
            futures.add(future);
        }
        
        return CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]))
            .thenRun(() -> {
                log.info("✅ All batch subscription requests completed");
            });
    }
    
    @Override
    public CompletableFuture<Void> stop() {
        return CompletableFuture.runAsync(() -> {
            if (!isRunning.get()) {
                log.warn("Limit monitoring streaming service is not running");
                return;
            }
            
            log.info("⏹️ Stopping limit monitoring streaming service...");
            isRunning.set(false);
            metrics.setRunning(false);
            
            try {
                if (multiStreamManager != null) {
                    // Отключаем все stream'ы
                    multiStreamManager.disconnectAll().join();
                    log.info("✅ All streams disconnected");
                }
                
                log.info("✅ Limit monitoring streaming service stopped successfully");
                
            } catch (Exception e) {
                log.error("❌ Error stopping limit monitoring streaming service", e);
            }
        });
    }
    
    @Override
    public CompletableFuture<Void> reconnect() {
        return CompletableFuture.runAsync(() -> {
            log.info("🔄 Force reconnecting limit monitoring streaming service...");
            
            if (multiStreamManager != null) {
                multiStreamManager.forceReconnectAll()
                    .thenCompose(v -> start())
                    .whenComplete((result, throwable) -> {
                        if (throwable != null) {
                            log.error("❌ Failed to reconnect limit monitoring streaming service", throwable);
                        } else {
                            log.info("✅ Limit monitoring streaming service reconnected successfully");
                        }
                    });
            } else {
                log.warn("MultiStreamManager is null, starting fresh...");
                start();
            }
        });
    }
    
    @Override
    public boolean isRunning() {
        return isRunning.get();
    }
    
    @Override
    public boolean isConnected() {
        return multiStreamManager != null && multiStreamManager.isAllConnected();
    }
    
    @Override
    public StreamingMetrics getMetrics() {
        return metrics;
    }
    
    @Override
    public String getServiceName() {
        return "LimitMonitoringStreamingService";
    }
    
    @Override
    public Class<LastPrice> getDataType() {
        return LastPrice.class;
    }
    
    /**
     * Настройка обработчика ответов от API (общий для всех stream'ов)
     */
    private void setupResponseObserver() {
        StreamObserver<MarketDataResponse> responseObserver = new StreamObserver<>() {
            @Override
            public void onNext(MarketDataResponse response) {
                if (response.hasSubscribeLastPriceResponse()) {
                    handleSubscriptionResponse(response.getSubscribeLastPriceResponse());
                } else if (response.hasLastPrice()) {
                    handleLastPriceData(response.getLastPrice());
                }
            }
            
            @Override
            public void onError(Throwable t) {
                log.error("❌ Limit monitoring stream error", t);
                metrics.setConnected(false);
                scheduleReconnect();
            }
            
            @Override
            public void onCompleted() {
                log.info("Limit monitoring stream completed");
                metrics.setConnected(false);
                if (isRunning.get()) {
                    scheduleReconnect();
                }
            }
        };
        
        if (multiStreamManager != null) {
            multiStreamManager.setSharedResponseObserver(responseObserver);
        }
    }
    
    /**
     * Обработка ответа на подписку
     */
    private void handleSubscriptionResponse(SubscribeLastPriceResponse response) {
        metrics.setConnected(true);
        
        int batchSuccessful = 0;
        int batchFailed = 0;
        
        log.info("=== LIMIT MONITORING SUBSCRIPTION RESPONSE ===");
        log.info("Total subscriptions in response: {}", response.getLastPriceSubscriptionsList().size());
        
        for (var subscription : response.getLastPriceSubscriptionsList()) {
            String status = subscription.getSubscriptionStatus().toString();
            log.info("  FIGI {} -> {}", subscription.getFigi(), status);
            
            if (status.contains("SUCCESS")) {
                batchSuccessful++;
                successfulSubscriptions.incrementAndGet();
            } else {
                batchFailed++;
                failedSubscriptions.incrementAndGet();
            }
        }
        
        log.info("Batch result: {} successful, {} failed", batchSuccessful, batchFailed);
        log.info("Total result: {} successful, {} failed", 
            successfulSubscriptions.get(), failedSubscriptions.get());
        log.info("=============================================");
    }
    
    /**
     * Обработка данных LastPrice для мониторинга лимитов
     */
    private void handleLastPriceData(LastPrice lastPrice) {
        try {
            metrics.incrementReceived();
            
            // Конвертируем время в UTC+3 (московское время)
            java.time.Instant eventInstant = java.time.Instant.ofEpochSecond(
                lastPrice.getTime().getSeconds(), 
                lastPrice.getTime().getNanos()
            );
            java.time.LocalDateTime eventTime = java.time.LocalDateTime.ofInstant(
                eventInstant, 
                java.time.ZoneOffset.of("+3")
            );
            
            // Конвертируем цену
            java.math.BigDecimal priceValue = java.math.BigDecimal.valueOf(lastPrice.getPrice().getUnits())
                .add(java.math.BigDecimal.valueOf(lastPrice.getPrice().getNano()).movePointLeft(9));
            
            // Передаем данные в сервис мониторинга лимитов
            limitMonitorService.processLastPrice(lastPrice.getFigi(), priceValue, eventTime);
            
            metrics.incrementProcessed();
            
            // Логирование каждые 1000 записей
            if (metrics.getTotalReceived() % 1000 == 0) {
                log.info("Limit monitoring processing: {}", metrics);
            }
            
        } catch (Exception e) {
            metrics.incrementErrors();
            log.error("Error processing LastPrice for limit monitoring: {}", lastPrice.getFigi(), e);
        }
    }
    
    /**
     * Получение списка всех инструментов
     */
    private List<String> getAllInstruments() {
        List<String> instruments = new java.util.ArrayList<>();
        
        // Добавляем акции
        instruments.addAll(shareRepository.findAllDistinctFigi().stream()
            .filter(figi -> figi != null && !figi.trim().isEmpty())
            .toList());
        
        // Добавляем фьючерсы
        instruments.addAll(futureRepository.findAllFigis().stream()
            .filter(figi -> figi != null && !figi.trim().isEmpty())
            .toList());
        
        // Добавляем индикативные инструменты
        instruments.addAll(indicativeRepository.findAllDistinctFigi().stream()
            .filter(figi -> figi != null && !figi.trim().isEmpty())
            .toList());
        
        log.info("Found {} instruments for limit monitoring subscription", instruments.size());
        return instruments;
    }
    
    /**
     * Планирование переподключения
     */
    private void scheduleReconnect() {
        if (isRunning.get()) {
            log.info("⏰ Scheduling reconnect in 30 seconds...");
            CompletableFuture.runAsync(() -> {
                try {
                    Thread.sleep(30000); // 30 секунд
                    if (isRunning.get()) {
                        log.info("🔄 Attempting to reconnect limit monitoring streaming service...");
                        reconnect();
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    log.warn("Reconnect scheduling interrupted");
                }
            });
        }
    }
    
    /**
     * Корректное завершение работы сервиса
     */
    @PreDestroy
    public void shutdown() {
        log.info("Завершение работы сервиса мониторинга лимитов...");
        
        // Останавливаем сервис
        if (isRunning.get()) {
            try {
                stop().get(30, TimeUnit.SECONDS);
                log.info("Сервис мониторинга лимитов корректно остановлен");
            } catch (Exception e) {
                log.error("Ошибка при остановке сервиса мониторинга лимитов", e);
            }
        }
    }
}
