package com.example.investmentdatastreamservice.service.streaming.impl;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicBoolean;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.DependsOn;
import org.springframework.stereotype.Service;
import org.springframework.core.annotation.Order;

import com.example.investmentdatastreamservice.repository.FutureRepository;
import com.example.investmentdatastreamservice.repository.IndicativeRepository;
import com.example.investmentdatastreamservice.repository.ShareRepository;
import com.example.investmentdatastreamservice.service.LimitMonitorService;
import com.example.investmentdatastreamservice.service.streaming.GrpcConnectionManager;
import com.example.investmentdatastreamservice.service.streaming.StreamingMetrics;
import com.example.investmentdatastreamservice.service.streaming.StreamingService;

import io.grpc.stub.StreamObserver;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
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
 * <p>
 * Автоматически запускается при старте приложения для непрерывного мониторинга
 * лимитов инструментов и отправки уведомлений в Telegram.
 * </p>
 */
@Service
@DependsOn("cacheWarmupService") // Зависит только от прогрева кэша
@Order(100) // Запускается после кэша и других сервисов
public class LimitMonitoringStreamingService implements StreamingService<LastPrice> {
    
    private static final Logger log = LoggerFactory.getLogger(LimitMonitoringStreamingService.class);
    
    private final GrpcConnectionManager connectionManager;
    private final LimitMonitorService limitMonitorService;
    private final ShareRepository shareRepository;
    private final FutureRepository futureRepository;
    private final IndicativeRepository indicativeRepository;
    
    private final AtomicBoolean isRunning = new AtomicBoolean(false);
    private final StreamingMetrics metrics;
    private final ScheduledExecutorService startupScheduler = Executors.newSingleThreadScheduledExecutor(r -> {
        Thread t = new Thread(r, "limit-monitoring-startup-scheduler");
        t.setDaemon(true);
        return t;
    });
    
    public LimitMonitoringStreamingService(
            GrpcConnectionManager connectionManager,
            LimitMonitorService limitMonitorService,
            ShareRepository shareRepository,
            FutureRepository futureRepository,
            IndicativeRepository indicativeRepository) {
        
        this.connectionManager = connectionManager;
        this.limitMonitorService = limitMonitorService;
        this.shareRepository = shareRepository;
        this.futureRepository = futureRepository;
        this.indicativeRepository = indicativeRepository;
        this.metrics = new StreamingMetrics("LimitMonitoringStreamingService");
        
        // Настраиваем обработчик ответов
        setupResponseObserver();
    }
    
    /**
     * Автоматический запуск сервиса при старте приложения
     * 
     * <p>
     * Сервис автоматически запускается после инициализации всех зависимостей
     * (кэш инструментов, кэш лимитов, репозитории) для начала мониторинга лимитов.
     * </p>
     * 
     * <p>
     * Выполняет:
     * - Подписку на LastPrice для всех инструментов
     * - Начало отслеживания приближения к лимитам
     * - Отправку уведомлений в Telegram при достижении пороговых значений
     * </p>
     * 
     * <p>
     * Использует ScheduledExecutorService для запуска с небольшой задержкой,
     * чтобы гарантировать полную инициализацию всех зависимостей (кэш лимитов).
     * </p>
     */
    @PostConstruct
    public void autoStart() {
        log.info("=== АВТОМАТИЧЕСКИЙ ЗАПУСК СЕРВИСА МОНИТОРИНГА ЛИМИТОВ ===");
        log.info("🚀 Сервис мониторинга лимитов будет запущен автоматически...");
        log.info("📊 Будет отслеживаться приближение к лимитам всех инструментов");
        log.info("📤 Уведомления будут отправляться в Telegram канал");
        log.info("⏳ Ожидание инициализации зависимостей (кэш лимитов)...");
        
        // Запускаем сервис с небольшой задержкой для обеспечения готовности всех зависимостей
        // (кэш лимитов должен быть прогрет через CacheWarmupService)
        startupScheduler.schedule(() -> {
            try {
                log.info("▶️ Запуск сервиса мониторинга лимитов...");
                start().whenComplete((result, throwable) -> {
                    if (throwable != null) {
                        log.error("❌ Ошибка при автоматическом запуске сервиса мониторинга лимитов", throwable);
                        log.info("💡 Сервис можно запустить вручную через API: POST /api/limit-monitoring/start");
                    } else {
                        log.info("✅ Сервис мониторинга лимитов успешно запущен и готов к работе");
                        log.info("📊 Начато отслеживание лимитов для всех инструментов");
                        log.info("📤 Уведомления будут отправляться в Telegram при приближении к лимитам (1%) или достижении");
                        log.info("🔄 Автоматическое переподключение настроено");
                        log.info("================================================================");
                    }
                });
                
            } catch (Exception e) {
                log.error("Ошибка при автоматическом запуске сервиса мониторинга лимитов", e);
                log.info("💡 Сервис можно запустить вручную через API: POST /api/limit-monitoring/start");
            }
        }, 3, TimeUnit.SECONDS);
    }
    
    @Override
    public CompletableFuture<Void> start() {
        return CompletableFuture.runAsync(() -> {
            if (isRunning.get()) {
                log.warn("Limit monitoring streaming service is already running");
                return;
            }
            
            log.info("🚀 Запуск сервиса мониторинга лимитов...");
            log.info("📊 Сервис будет отслеживать приближение к лимитам инструментов");
            log.info("📤 Уведомления будут отправляться в Telegram канал");
            isRunning.set(true);
            metrics.setRunning(true);
            
            try {
                // Получаем список инструментов
                List<String> instruments = getAllInstruments();
                
                if (instruments.isEmpty()) {
                    log.warn("No instruments found for limit monitoring subscription");
                    isRunning.set(false);
                    metrics.setRunning(false);
                    return;
                }
                
                log.info("Subscribing to LastPrice for limit monitoring for {} instruments", instruments.size());
                
                // Создаем запрос на подписку
                SubscribeLastPriceRequest request = SubscribeLastPriceRequest.newBuilder()
                    .setSubscriptionAction(SubscriptionAction.SUBSCRIPTION_ACTION_SUBSCRIBE)
                    .addAllInstruments(instruments.stream()
                        .map(figi -> LastPriceInstrument.newBuilder().setInstrumentId(figi).build())
                        .toList())
                    .build();
                
                MarketDataRequest marketDataRequest = MarketDataRequest.newBuilder()
                    .setSubscribeLastPriceRequest(request)
                    .build();
                
                // Подключаемся и отправляем запрос
                connectionManager.connect()
                    .thenCompose(v -> connectionManager.sendRequest(marketDataRequest))
                    .whenComplete((result, throwable) -> {
                        if (throwable != null) {
                            log.error("Failed to start limit monitoring streaming", throwable);
                            isRunning.set(false);
                            metrics.setRunning(false);
                            scheduleReconnect();
                        } else {
                            log.info("Limit monitoring streaming service started successfully");
                        }
                    });
                
            } catch (Exception e) {
                log.error("Error starting limit monitoring streaming service", e);
                isRunning.set(false);
                metrics.setRunning(false);
                scheduleReconnect();
            }
        });
    }
    
    @Override
    public CompletableFuture<Void> stop() {
        return CompletableFuture.runAsync(() -> {
            if (!isRunning.get()) {
                log.warn("Limit monitoring streaming service is not running");
                return;
            }
            
            log.info("Stopping limit monitoring streaming service...");
            isRunning.set(false);
            metrics.setRunning(false);
            
            try {
                // Отправляем запрос на отписку
                List<String> instruments = getAllInstruments();
                if (!instruments.isEmpty()) {
                    SubscribeLastPriceRequest unsubscribeRequest = SubscribeLastPriceRequest.newBuilder()
                        .setSubscriptionAction(SubscriptionAction.SUBSCRIPTION_ACTION_UNSUBSCRIBE)
                        .addAllInstruments(instruments.stream()
                            .map(figi -> LastPriceInstrument.newBuilder().setInstrumentId(figi).build())
                            .toList())
                        .build();
                    
                    MarketDataRequest marketDataRequest = MarketDataRequest.newBuilder()
                        .setSubscribeLastPriceRequest(unsubscribeRequest)
                        .build();
                    
                    connectionManager.sendRequest(marketDataRequest).join();
                }
                
                // Отключаемся
                connectionManager.disconnect().join();
                
                log.info("Limit monitoring streaming service stopped successfully");
                
            } catch (Exception e) {
                log.error("Error stopping limit monitoring streaming service", e);
            }
        });
    }
    
    @Override
    public CompletableFuture<Void> reconnect() {
        return CompletableFuture.runAsync(() -> {
            log.info("Force reconnecting limit monitoring streaming service...");
            
            connectionManager.forceReconnect()
                .thenCompose(v -> start())
                .whenComplete((result, throwable) -> {
                    if (throwable != null) {
                        log.error("Failed to reconnect limit monitoring streaming service", throwable);
                    } else {
                        log.info("Limit monitoring streaming service reconnected successfully");
                    }
                });
        });
    }
    
    @Override
    public boolean isRunning() {
        return isRunning.get();
    }
    
    @Override
    public boolean isConnected() {
        return connectionManager.isConnected();
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
     * Настройка обработчика ответов от API
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
                log.error("Limit monitoring stream error", t);
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
        
        connectionManager.setResponseObserver(responseObserver);
    }
    
    /**
     * Обработка ответа на подписку
     */
    private void handleSubscriptionResponse(SubscribeLastPriceResponse response) {
        metrics.setConnected(true);
        log.info("=== LIMIT MONITORING SUBSCRIPTION RESPONSE ===");
        log.info("Total subscriptions: {}", response.getLastPriceSubscriptionsList().size());
        response.getLastPriceSubscriptionsList().forEach(subscription -> 
            log.info("  FIGI {} -> {}", subscription.getFigi(), subscription.getSubscriptionStatus())
        );
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
            connectionManager.scheduleReconnect(() -> {
                if (isRunning.get()) {
                    log.info("Attempting to reconnect limit monitoring streaming service...");
                    start();
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
        
        // Останавливаем планировщик запуска
        startupScheduler.shutdown();
        try {
            if (!startupScheduler.awaitTermination(2, TimeUnit.SECONDS)) {
                startupScheduler.shutdownNow();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            startupScheduler.shutdownNow();
        }
        
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
