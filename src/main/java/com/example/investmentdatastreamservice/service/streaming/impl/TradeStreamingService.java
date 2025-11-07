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
import com.example.investmentdatastreamservice.service.streaming.processor.TradeProcessor;

import io.grpc.stub.StreamObserver;
import ru.tinkoff.piapi.contract.v1.MarketDataRequest;
import ru.tinkoff.piapi.contract.v1.MarketDataResponse;
import ru.tinkoff.piapi.contract.v1.SubscribeTradesRequest;
import ru.tinkoff.piapi.contract.v1.SubscribeTradesResponse;
import ru.tinkoff.piapi.contract.v1.SubscriptionAction;
import ru.tinkoff.piapi.contract.v1.Trade;
import ru.tinkoff.piapi.contract.v1.TradeInstrument;

/**
 * Сервис для потоковой обработки обезличенных сделок (Trade)
 * 
 * Высокопроизводительный сервис для получения и обработки обезличенных сделок
 * от T-Invest API с автоматическим переподключением и детальным мониторингом.
 */
@Service
public class TradeStreamingService implements StreamingService<Trade> {
    
    private static final Logger log = LoggerFactory.getLogger(TradeStreamingService.class);
    
    private final GrpcConnectionManager connectionManager;
    private final TradeProcessor processor;
    private final ShareRepository shareRepository;
    private final FutureRepository futureRepository;
    private final IndicativeRepository indicativeRepository;
    
    private final AtomicBoolean isRunning = new AtomicBoolean(false);
    private final StreamingMetrics metrics;
    
    public TradeStreamingService(
            GrpcConnectionManager connectionManager,
            TradeProcessor processor,
            ShareRepository shareRepository,
            FutureRepository futureRepository,
            IndicativeRepository indicativeRepository) {
        
        this.connectionManager = connectionManager;
        this.processor = processor;
        this.shareRepository = shareRepository;
        this.futureRepository = futureRepository;
        this.indicativeRepository = indicativeRepository;
        this.metrics = new StreamingMetrics("TradeStreamingService");
        
        log.info("TradeStreamingService initialized with GrpcConnectionManager: {}", 
            System.identityHashCode(connectionManager));
        
        // Настраиваем обработчик ответов
        setupResponseObserver();
    }
    
    @Override
    public CompletableFuture<Void> start() {
        return CompletableFuture.runAsync(() -> {
            if (isRunning.get()) {
                log.warn("Trade streaming service is already running");
                return;
            }
            
            log.info("Starting Trade streaming service...");
            isRunning.set(true);
            metrics.setRunning(true);
            
            try {
                // Получаем список инструментов
                List<String> instruments = getAllInstruments();
                
                if (instruments.isEmpty()) {
                    log.warn("No instruments found for Trade subscription");
                    isRunning.set(false);
                    metrics.setRunning(false);
                    return;
                }
                
                log.info("Subscribing to Trades for {} instruments", instruments.size());
                
                // Создаем запрос на подписку
                SubscribeTradesRequest request = SubscribeTradesRequest.newBuilder()
                    .setSubscriptionAction(SubscriptionAction.SUBSCRIPTION_ACTION_SUBSCRIBE)
                    .addAllInstruments(instruments.stream()
                        .map(figi -> TradeInstrument.newBuilder().setInstrumentId(figi).build())
                        .toList())
                    .build();
                
                MarketDataRequest marketDataRequest = MarketDataRequest.newBuilder()
                    .setSubscribeTradesRequest(request)
                    .build();
                
                // Подключаемся и отправляем запрос
                connectionManager.connect()
                    .thenCompose(v -> connectionManager.sendRequest(marketDataRequest))
                    .whenComplete((result, throwable) -> {
                        if (throwable != null) {
                            log.error("Failed to start Trade streaming", throwable);
                            isRunning.set(false);
                            metrics.setRunning(false);
                            scheduleReconnect();
                        } else {
                            log.info("Trade streaming service started successfully");
                        }
                    });
                
            } catch (Exception e) {
                log.error("Error starting Trade streaming service", e);
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
                log.warn("Trade streaming service is not running");
                return;
            }
            
            log.info("Stopping Trade streaming service...");
            isRunning.set(false);
            metrics.setRunning(false);
            
            try {
                // Отправляем запрос на отписку
                List<String> instruments = getAllInstruments();
                if (!instruments.isEmpty()) {
                    SubscribeTradesRequest unsubscribeRequest = SubscribeTradesRequest.newBuilder()
                        .setSubscriptionAction(SubscriptionAction.SUBSCRIPTION_ACTION_UNSUBSCRIBE)
                        .addAllInstruments(instruments.stream()
                            .map(figi -> TradeInstrument.newBuilder().setInstrumentId(figi).build())
                            .toList())
                        .build();
                    
                    MarketDataRequest marketDataRequest = MarketDataRequest.newBuilder()
                        .setSubscribeTradesRequest(unsubscribeRequest)
                        .build();
                    
                    connectionManager.sendRequest(marketDataRequest).join();
                }
                
                // Отключаемся
                connectionManager.disconnect().join();
                
                log.info("Trade streaming service stopped successfully");
                
            } catch (Exception e) {
                log.error("Error stopping Trade streaming service", e);
            }
        });
    }
    
    @Override
    public CompletableFuture<Void> reconnect() {
        return CompletableFuture.runAsync(() -> {
            log.info("Force reconnecting Trade streaming service...");
            
            connectionManager.forceReconnect()
                .thenCompose(v -> start())
                .whenComplete((result, throwable) -> {
                    if (throwable != null) {
                        log.error("Failed to reconnect Trade streaming service", throwable);
                    } else {
                        log.info("Trade streaming service reconnected successfully");
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
        return "TradeStreamingService";
    }
    
    @Override
    public Class<Trade> getDataType() {
        return Trade.class;
    }
    
    /**
     * Настройка обработчика ответов от API
     */
    private void setupResponseObserver() {
        StreamObserver<MarketDataResponse> responseObserver = new StreamObserver<>() {
            @Override
            public void onNext(MarketDataResponse response) {
                if (response.hasSubscribeTradesResponse()) {
                    handleSubscriptionResponse(response.getSubscribeTradesResponse());
                } else if (response.hasTrade()) {
                    handleTradeData(response.getTrade());
                }
            }
            
            @Override
            public void onError(Throwable t) {
                log.error("Trade stream error", t);
                metrics.incrementErrors(); // 👈 фиксируем ошибку
                metrics.setConnected(false);
                scheduleReconnect();
            }
            
            @Override
            public void onCompleted() {
                log.info("Trade stream completed");
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
    private void handleSubscriptionResponse(SubscribeTradesResponse response) {
        metrics.setConnected(true);
        log.info("=== TRADES SUBSCRIPTION RESPONSE ===");
        log.info("Total subscriptions: {}", response.getTradeSubscriptionsList().size());
        response.getTradeSubscriptionsList().forEach(subscription -> 
            log.info("  FIGI {} -> {}", subscription.getFigi(), subscription.getSubscriptionStatus())
        );
        log.info("===================================");
    }
    
    /**
     * Обработка данных Trade
     */
    private void handleTradeData(Trade trade) {
        metrics.incrementReceived(); // 👈 сообщение получено
    
        processor.process(trade)
            .whenComplete((result, throwable) -> {
                if (throwable != null) {
                    metrics.incrementErrors(); // 👈 ошибка при обработке
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
        
        log.info("Found {} instruments for Trade subscription", instruments.size());
        return instruments;
    }
    
    /**
     * Планирование переподключения
     */
    private void scheduleReconnect() {
        if (isRunning.get()) {
            connectionManager.scheduleReconnect(() -> {
                if (isRunning.get()) {
                    log.info("Attempting to reconnect Trade streaming service...");
                    start();
                }
            });
        }
    }
}







