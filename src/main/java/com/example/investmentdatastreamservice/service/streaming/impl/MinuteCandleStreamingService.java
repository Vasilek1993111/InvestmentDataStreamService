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
import com.example.investmentdatastreamservice.repository.ShareRepository;
import com.example.investmentdatastreamservice.service.streaming.MultiStreamManager;
import com.example.investmentdatastreamservice.service.streaming.SubscriptionBatcher;
import com.example.investmentdatastreamservice.service.streaming.StreamingMetrics;
import com.example.investmentdatastreamservice.service.streaming.StreamingService;
import com.example.investmentdatastreamservice.service.streaming.processor.CandleProcessor;

import io.grpc.stub.StreamObserver;
import ru.tinkoff.piapi.contract.v1.Candle;
import ru.tinkoff.piapi.contract.v1.CandleInstrument;
import ru.tinkoff.piapi.contract.v1.MarketDataRequest;
import ru.tinkoff.piapi.contract.v1.MarketDataResponse;
import ru.tinkoff.piapi.contract.v1.SubscribeCandlesRequest;
import ru.tinkoff.piapi.contract.v1.SubscribeCandlesResponse;
import ru.tinkoff.piapi.contract.v1.SubscriptionAction;
import ru.tinkoff.piapi.contract.v1.SubscriptionInterval;

/**
 * Сервис для потоковой обработки минутных свечей
 * 
 * Высокопроизводительный сервис для получения и обработки минутных свечей
 * от T-Invest API с поддержкой множественных stream-соединений для обхода
 * лимита в 300 подписок на один stream.
 * 
 * Особенности:
 * - Разделяет инструменты на батчи по 250 штук
 * - Создает отдельное gRPC соединение для каждого батча
 * - Соблюдает rate limit: 100 запросов в минуту
 * - Автоматическое переподключение при ошибках
 */
@Service
public class MinuteCandleStreamingService implements StreamingService<Candle> {
    
    private static final Logger log = LoggerFactory.getLogger(MinuteCandleStreamingService.class);
    
    @Value("${tinkoff.api.token}")
    private String apiToken;
    
    private final CandleProcessor processor;
    private final ShareRepository shareRepository;
    private final FutureRepository futureRepository;
    
    private final AtomicBoolean isRunning = new AtomicBoolean(false);
    private final StreamingMetrics metrics;
    private final SubscriptionBatcher batcher;
    
    // Множественные stream-соединения
    private MultiStreamManager multiStreamManager;
    private final AtomicInteger successfulSubscriptions = new AtomicInteger(0);
    private final AtomicInteger failedSubscriptions = new AtomicInteger(0);
    
    public MinuteCandleStreamingService(
            CandleProcessor processor,
            ShareRepository shareRepository,
            FutureRepository futureRepository) {
        
        this.processor = processor;
        this.shareRepository = shareRepository;
        this.futureRepository = futureRepository;
        this.metrics = new StreamingMetrics("MinuteCandleStreamingService");
        this.batcher = new SubscriptionBatcher(); // 250 инструментов на батч
        
        log.info("MinuteCandleStreamingService initialized with multi-stream support");
    }
    
    @Override
    public CompletableFuture<Void> start() {
        return CompletableFuture.runAsync(() -> {
            if (isRunning.get()) {
                log.warn("MinuteCandle streaming service is already running");
                return;
            }
            
            log.info("🚀 Starting MinuteCandle streaming service with multi-stream support...");
            isRunning.set(true);
            metrics.setRunning(true);
            successfulSubscriptions.set(0);
            failedSubscriptions.set(0);
            
            try {
                // Получаем список инструментов
                List<String> instruments = getAllInstruments();
                
                if (instruments.isEmpty()) {
                    log.warn("No instruments found for MinuteCandle subscription");
                    isRunning.set(false);
                    metrics.setRunning(false);
                    return;
                }
                
                log.info("📊 Found {} instruments for MinuteCandle subscription", instruments.size());
                
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
                            log.error("❌ Failed to start MinuteCandle streaming", throwable);
                            isRunning.set(false);
                            metrics.setRunning(false);
                            scheduleReconnect();
                        } else {
                            log.info("🎉 MinuteCandle streaming service started successfully");
                            log.info("📈 Subscribed: {} successful, {} failed", 
                                successfulSubscriptions.get(), failedSubscriptions.get());
                        }
                    })
                    .join(); // Ждем завершения подписок
                
            } catch (Exception e) {
                log.error("❌ Error starting MinuteCandle streaming service", e);
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
            SubscribeCandlesRequest request = SubscribeCandlesRequest.newBuilder()
                .setSubscriptionAction(SubscriptionAction.SUBSCRIPTION_ACTION_SUBSCRIBE)
                .addAllInstruments(batch.stream()
                    .map(figi -> CandleInstrument.newBuilder()
                        .setInstrumentId(figi)
                        .setInterval(SubscriptionInterval.SUBSCRIPTION_INTERVAL_ONE_MINUTE)
                        .build())
                    .toList())
                .build();
            
            MarketDataRequest marketDataRequest = MarketDataRequest.newBuilder()
                .setSubscribeCandlesRequest(request)
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
                log.warn("MinuteCandle streaming service is not running");
                return;
            }
            
            log.info("⏹️ Stopping MinuteCandle streaming service...");
            isRunning.set(false);
            metrics.setRunning(false);
            
            try {
                if (multiStreamManager != null) {
                    // Отключаем все stream'ы
                    multiStreamManager.disconnectAll().join();
                    log.info("✅ All streams disconnected");
                }
                
                log.info("✅ MinuteCandle streaming service stopped successfully");
                
            } catch (Exception e) {
                log.error("❌ Error stopping MinuteCandle streaming service", e);
            }
        });
    }
    
    @Override
    public CompletableFuture<Void> reconnect() {
        return CompletableFuture.runAsync(() -> {
            log.info("🔄 Force reconnecting MinuteCandle streaming service...");
            
            if (multiStreamManager != null) {
                multiStreamManager.forceReconnectAll()
                    .thenCompose(v -> start())
                    .whenComplete((result, throwable) -> {
                        if (throwable != null) {
                            log.error("❌ Failed to reconnect MinuteCandle streaming service", throwable);
                        } else {
                            log.info("✅ MinuteCandle streaming service reconnected successfully");
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
        return "MinuteCandleStreamingService";
    }
    
    @Override
    public Class<Candle> getDataType() {
        return Candle.class;
    }
    
    /**
     * Настройка обработчика ответов от API (общий для всех stream'ов)
     */
    private void setupResponseObserver() {
        StreamObserver<MarketDataResponse> responseObserver = new StreamObserver<>() {
            @Override
            public void onNext(MarketDataResponse response) {
                metrics.incrementReceived(); // <--- считаем полученные сообщения

                if (response.hasSubscribeCandlesResponse()) {
                    handleSubscriptionResponse(response.getSubscribeCandlesResponse());
                } else if (response.hasCandle()) {
                    handleCandleData(response.getCandle());
                } else {
                    metrics.incrementDropped(); // <--- неизвестный тип ответа
                }
            }
            
            @Override
            public void onError(Throwable t) {
                log.error("❌ MinuteCandle stream error", t);
                metrics.setConnected(false);
                metrics.incrementErrors(); // <--- можно считать как сетевую ошибку
                scheduleReconnect();
            }
            
            @Override
            public void onCompleted() {
                log.info("MinuteCandle stream completed");
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
    private void handleSubscriptionResponse(SubscribeCandlesResponse response) {
        metrics.setConnected(true);
        
        int batchSuccessful = 0;
        int batchFailed = 0;
        
        log.info("=== MINUTE CANDLES SUBSCRIPTION RESPONSE ===");
        log.info("Total subscriptions in response: {}", response.getCandlesSubscriptionsList().size());
        
        for (var subscription : response.getCandlesSubscriptionsList()) {
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
        log.info("==========================================");
    }
    
    /**
     * Обработка данных Candle
     */
    private void handleCandleData(Candle candle) {
        processor.process(candle)
        .whenComplete((result, throwable) -> {
            if (throwable != null) {
                processor.handleError(throwable);
                metrics.incrementErrors(); // <--- ошибка обработки
            } else {
                metrics.incrementProcessed(); // <--- свеча успешно обработана
            }
        });
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
        
        log.info("Found {} instruments for MinuteCandle subscription", instruments.size());
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
                        log.info("🔄 Attempting to reconnect MinuteCandle streaming service...");
                        reconnect();
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    log.warn("Reconnect scheduling interrupted");
                }
            });
        }
    }
}

