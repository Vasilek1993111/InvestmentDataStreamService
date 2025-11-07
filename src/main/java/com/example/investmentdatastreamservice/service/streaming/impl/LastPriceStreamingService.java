package com.example.investmentdatastreamservice.service.streaming.impl;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicBoolean;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.example.investmentdatastreamservice.repository.FutureRepository;
import com.example.investmentdatastreamservice.repository.IndicativeRepository;
import com.example.investmentdatastreamservice.repository.ShareRepository;
import com.example.investmentdatastreamservice.service.streaming.GrpcConnectionManager;
import com.example.investmentdatastreamservice.service.streaming.StreamingMetrics;
import com.example.investmentdatastreamservice.service.streaming.StreamingService;
import com.example.investmentdatastreamservice.service.streaming.processor.LastPriceProcessor;

import io.grpc.stub.StreamObserver;
import ru.tinkoff.piapi.contract.v1.LastPrice;
import ru.tinkoff.piapi.contract.v1.LastPriceInstrument;
import ru.tinkoff.piapi.contract.v1.MarketDataRequest;
import ru.tinkoff.piapi.contract.v1.MarketDataResponse;
import ru.tinkoff.piapi.contract.v1.SubscribeLastPriceRequest;
import ru.tinkoff.piapi.contract.v1.SubscribeLastPriceResponse;
import ru.tinkoff.piapi.contract.v1.SubscriptionAction;

/**
 * Сервис для потоковой обработки цен последних сделок (LastPrice)
 * 
 * Высокопроизводительный сервис для получения и обработки цен последних сделок
 * от T-Invest API с автоматическим переподключением и детальным мониторингом.
 */
@Service
public class LastPriceStreamingService implements StreamingService<LastPrice> {
    
    private static final Logger log = LoggerFactory.getLogger(LastPriceStreamingService.class);
    
    private final GrpcConnectionManager connectionManager;
    private final LastPriceProcessor processor;
    private final ShareRepository shareRepository;
    private final FutureRepository futureRepository;
    private final IndicativeRepository indicativeRepository;
    
    private final AtomicBoolean isRunning = new AtomicBoolean(false);
    private final StreamingMetrics metrics;
    
    public LastPriceStreamingService(
            GrpcConnectionManager connectionManager,
            LastPriceProcessor processor,
            ShareRepository shareRepository,
            FutureRepository futureRepository,
            IndicativeRepository indicativeRepository) {
        
        this.connectionManager = connectionManager;
        this.processor = processor;
        this.shareRepository = shareRepository;
        this.futureRepository = futureRepository;
        this.indicativeRepository = indicativeRepository;
        this.metrics = new StreamingMetrics("LastPriceStreamingService");
        
        log.info("LastPriceStreamingService initialized with GrpcConnectionManager: {}", 
            System.identityHashCode(connectionManager));
        
        // Настраиваем обработчик ответов
        setupResponseObserver();
    }
    
    @Override
    public CompletableFuture<Void> start() {
        return CompletableFuture.runAsync(() -> {
            if (isRunning.get()) {
                log.warn("LastPrice streaming service is already running");
                return;
            }
            
            log.info("Starting LastPrice streaming service...");
            isRunning.set(true);
            metrics.setRunning(true);
            
            try {
                // Получаем список инструментов
                List<String> instruments = getAllInstruments();
                
                if (instruments.isEmpty()) {
                    log.warn("No instruments found for LastPrice subscription");
                    isRunning.set(false);
                    metrics.setRunning(false);
                    return;
                }
                
                log.info("Subscribing to LastPrice for {} instruments", instruments.size());
                
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
                            log.error("Failed to start LastPrice streaming", throwable);
                            isRunning.set(false);
                            metrics.setRunning(false);
                            scheduleReconnect();
                        } else {
                            log.info("LastPrice streaming service started successfully");
                        }
                    });
                
            } catch (Exception e) {
                log.error("Error starting LastPrice streaming service", e);
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
                log.warn("LastPrice streaming service is not running");
                return;
            }
            
            log.info("Stopping LastPrice streaming service...");
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
                
                log.info("LastPrice streaming service stopped successfully");
                
            } catch (Exception e) {
                log.error("Error stopping LastPrice streaming service", e);
            }
        });
    }
    
    @Override
    public CompletableFuture<Void> reconnect() {
        return CompletableFuture.runAsync(() -> {
            log.info("Force reconnecting LastPrice streaming service...");
            
            connectionManager.forceReconnect()
                .thenCompose(v -> start())
                .whenComplete((result, throwable) -> {
                    if (throwable != null) {
                        log.error("Failed to reconnect LastPrice streaming service", throwable);
                    } else {
                        log.info("LastPrice streaming service reconnected successfully");
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
        return "LastPriceStreamingService";
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
                log.error("LastPrice stream error", t);
                metrics.incrementErrors(); // 👈 фиксируем ошибку потока
                metrics.setConnected(false);
                scheduleReconnect();
            }
            
            @Override
            public void onCompleted() {
                log.info("LastPrice stream completed");
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
        log.info("=== LASTPRICE SUBSCRIPTION RESPONSE ===");
        log.info("Total subscriptions: {}", response.getLastPriceSubscriptionsList().size());
        response.getLastPriceSubscriptionsList().forEach(subscription -> 
            log.info("  FIGI {} -> {}", subscription.getFigi(), subscription.getSubscriptionStatus())
        );
        log.info("=====================================");
    }
    
    /**
     * Обработка данных LastPrice
     */
    private void handleLastPriceData(LastPrice lastPrice) {
        metrics.incrementReceived(); // 👈 получено новое сообщение

        processor.process(lastPrice)
            .whenComplete((result, throwable) -> {
                if (throwable != null) {
                    metrics.incrementErrors(); // 👈 ошибка обработки
                    processor.handleError(throwable);
                } else {
                    metrics.incrementProcessed(); // 👈 успешно обработано
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
        
        // Добавляем индикативные инструменты
        instruments.addAll(indicativeRepository.findAllDistinctFigi().stream()
            .filter(figi -> figi != null && !figi.trim().isEmpty())
            .toList());
        
        log.info("Found {} instruments for LastPrice subscription", instruments.size());
        return instruments;
    }
    
    /**
     * Планирование переподключения
     */
    private void scheduleReconnect() {
        if (isRunning.get()) {
            connectionManager.scheduleReconnect(() -> {
                if (isRunning.get()) {
                    log.info("Attempting to reconnect LastPrice streaming service...");
                    start();
                }
            });
        }
    }
}







