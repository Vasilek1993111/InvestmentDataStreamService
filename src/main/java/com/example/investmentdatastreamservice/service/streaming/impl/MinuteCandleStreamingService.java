package com.example.investmentdatastreamservice.service.streaming.impl;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicBoolean;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.example.investmentdatastreamservice.repository.FutureRepository;
import com.example.investmentdatastreamservice.repository.ShareRepository;
import com.example.investmentdatastreamservice.service.streaming.GrpcConnectionManager;
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
 * от T-Invest API с автоматическим переподключением и детальным мониторингом.
 */
@Service
public class MinuteCandleStreamingService implements StreamingService<Candle> {
    
    private static final Logger log = LoggerFactory.getLogger(MinuteCandleStreamingService.class);
    
    private final GrpcConnectionManager connectionManager;
    private final CandleProcessor processor;
    private final ShareRepository shareRepository;
    private final FutureRepository futureRepository;
    
    private final AtomicBoolean isRunning = new AtomicBoolean(false);
    private final StreamingMetrics metrics;
    
    public MinuteCandleStreamingService(
            GrpcConnectionManager connectionManager,
            CandleProcessor processor,
            ShareRepository shareRepository,
            FutureRepository futureRepository) {
        
        this.connectionManager = connectionManager;
        this.processor = processor;
        this.shareRepository = shareRepository;
        this.futureRepository = futureRepository;
        this.metrics = new StreamingMetrics("MinuteCandleStreamingService");
        
        log.info("MinuteCandleStreamingService initialized with GrpcConnectionManager: {}", 
            System.identityHashCode(connectionManager));
        
        // Настраиваем обработчик ответов
        setupResponseObserver();
    }
    
    @Override
    public CompletableFuture<Void> start() {
        return CompletableFuture.runAsync(() -> {
            if (isRunning.get()) {
                log.warn("MinuteCandle streaming service is already running");
                return;
            }
            
            log.info("Starting MinuteCandle streaming service...");
            isRunning.set(true);
            metrics.setRunning(true);
            
            try {
                // Получаем список инструментов
                List<String> instruments = getAllInstruments();
                
                if (instruments.isEmpty()) {
                    log.warn("No instruments found for MinuteCandle subscription");
                    isRunning.set(false);
                    metrics.setRunning(false);
                    return;
                }
                
                log.info("Subscribing to MinuteCandles for {} instruments", instruments.size());
                
                // Создаем запрос на подписку
                SubscribeCandlesRequest request = SubscribeCandlesRequest.newBuilder()
                    .setSubscriptionAction(SubscriptionAction.SUBSCRIPTION_ACTION_SUBSCRIBE)
                    .addAllInstruments(instruments.stream()
                        .map(figi -> CandleInstrument.newBuilder()
                            .setInstrumentId(figi)
                            .setInterval(SubscriptionInterval.SUBSCRIPTION_INTERVAL_ONE_MINUTE)
                            .build())
                        .toList())
                    .build();
                
                MarketDataRequest marketDataRequest = MarketDataRequest.newBuilder()
                    .setSubscribeCandlesRequest(request)
                    .build();
                
                // Подключаемся и отправляем запрос
                connectionManager.connect()
                    .thenCompose(v -> connectionManager.sendRequest(marketDataRequest))
                    .whenComplete((result, throwable) -> {
                        if (throwable != null) {
                            log.error("Failed to start MinuteCandle streaming", throwable);
                            isRunning.set(false);
                            metrics.setRunning(false);
                            scheduleReconnect();
                        } else {
                            log.info("MinuteCandle streaming service started successfully");
                        }
                    });
                
            } catch (Exception e) {
                log.error("Error starting MinuteCandle streaming service", e);
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
                log.warn("MinuteCandle streaming service is not running");
                return;
            }
            
            log.info("Stopping MinuteCandle streaming service...");
            isRunning.set(false);
            metrics.setRunning(false);
            
            try {
                // Отправляем запрос на отписку
                List<String> instruments = getAllInstruments();
                if (!instruments.isEmpty()) {
                    SubscribeCandlesRequest unsubscribeRequest = SubscribeCandlesRequest.newBuilder()
                        .setSubscriptionAction(SubscriptionAction.SUBSCRIPTION_ACTION_UNSUBSCRIBE)
                        .addAllInstruments(instruments.stream()
                            .map(figi -> CandleInstrument.newBuilder()
                                .setInstrumentId(figi)
                                .setInterval(SubscriptionInterval.SUBSCRIPTION_INTERVAL_ONE_MINUTE)
                                .build())
                            .toList())
                        .build();
                    
                    MarketDataRequest marketDataRequest = MarketDataRequest.newBuilder()
                        .setSubscribeCandlesRequest(unsubscribeRequest)
                        .build();
                    
                    connectionManager.sendRequest(marketDataRequest).join();
                }
                
                // Отключаемся
                connectionManager.disconnect().join();
                
                log.info("MinuteCandle streaming service stopped successfully");
                
            } catch (Exception e) {
                log.error("Error stopping MinuteCandle streaming service", e);
            }
        });
    }
    
    @Override
    public CompletableFuture<Void> reconnect() {
        return CompletableFuture.runAsync(() -> {
            log.info("Force reconnecting MinuteCandle streaming service...");
            
            connectionManager.forceReconnect()
                .thenCompose(v -> start())
                .whenComplete((result, throwable) -> {
                    if (throwable != null) {
                        log.error("Failed to reconnect MinuteCandle streaming service", throwable);
                    } else {
                        log.info("MinuteCandle streaming service reconnected successfully");
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
        return "MinuteCandleStreamingService";
    }
    
    @Override
    public Class<Candle> getDataType() {
        return Candle.class;
    }
    
    /**
     * Настройка обработчика ответов от API
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
                log.error("MinuteCandle stream error", t);
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
        
        connectionManager.setResponseObserver(responseObserver);
    }
    
    /**
     * Обработка ответа на подписку
     */
    private void handleSubscriptionResponse(SubscribeCandlesResponse response) {
        metrics.setConnected(true);
        log.info("=== MINUTE CANDLES SUBSCRIPTION RESPONSE ===");
        log.info("Total subscriptions: {}", response.getCandlesSubscriptionsList().size());
        response.getCandlesSubscriptionsList().forEach(subscription -> 
            log.info("  FIGI {} -> {}", subscription.getFigi(), subscription.getSubscriptionStatus())
        );
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
            connectionManager.scheduleReconnect(() -> {
                if (isRunning.get()) {
                    log.info("Attempting to reconnect MinuteCandle streaming service...");
                    start();
                }
            });
        }
    }
}

