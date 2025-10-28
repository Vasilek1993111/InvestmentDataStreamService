package com.example.investmentdatastreamservice.service.streaming;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import io.grpc.stub.StreamObserver;
import ru.tinkoff.piapi.contract.v1.MarketDataRequest;
import ru.tinkoff.piapi.contract.v1.MarketDataResponse;
import ru.tinkoff.piapi.contract.v1.MarketDataStreamServiceGrpc;

/**
 * Менеджер подключений к gRPC API
 * 
 * Централизованное управление подключениями к T-Invest API с автоматическим
 * переподключением, мониторингом состояния и оптимизацией производительности.
 */
@Component
public class GrpcConnectionManager {
    
    private static final Logger log = LoggerFactory.getLogger(GrpcConnectionManager.class);
    
    private final MarketDataStreamServiceGrpc.MarketDataStreamServiceStub streamStub;
    private final ScheduledExecutorService reconnectScheduler;
    private final ExecutorService connectionExecutor;
    
    private final AtomicBoolean isConnected = new AtomicBoolean(false);
    private final AtomicReference<StreamObserver<MarketDataRequest>> requestObserver = new AtomicReference<>();
    private final AtomicReference<StreamObserver<MarketDataResponse>> responseObserver = new AtomicReference<>();
    
    // Конфигурация переподключений
    private static final int INITIAL_RECONNECT_DELAY_MS = 1000;
    private static final int MAX_RECONNECT_DELAY_MS = 30000;
    private static final double RECONNECT_BACKOFF_MULTIPLIER = 1.5;
    
    private volatile int currentReconnectDelay = INITIAL_RECONNECT_DELAY_MS;
    
    public GrpcConnectionManager(MarketDataStreamServiceGrpc.MarketDataStreamServiceStub streamStub) {
        this.streamStub = streamStub;
        this.reconnectScheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "grpc-reconnect-scheduler");
            t.setDaemon(true);
            return t;
        });
        this.connectionExecutor = Executors.newCachedThreadPool(r -> {
            Thread t = new Thread(r, "grpc-connection-worker");
            t.setDaemon(true);
            return t;
        });
    }
    
    /**
     * Установка обработчика ответов
     * 
     * @param responseObserver обработчик ответов от API
     */
    public void setResponseObserver(StreamObserver<MarketDataResponse> responseObserver) {
        this.responseObserver.set(responseObserver);
    }
    
    /**
     * Открытие нового подключения
     * 
     * @return CompletableFuture, завершающийся при успешном подключении
     */
    public CompletableFuture<Void> connect() {
        return CompletableFuture.runAsync(() -> {
            try {
                log.info("Opening new gRPC connection to T-Invest API...");
                
                StreamObserver<MarketDataResponse> observer = responseObserver.get();
                if (observer == null) {
                    throw new IllegalStateException("Response observer not set");
                }
                
                StreamObserver<MarketDataRequest> requestObs = streamStub.marketDataStream(observer);
                requestObserver.set(requestObs);
                isConnected.set(true);
                
                // Сброс задержки переподключения при успешном подключении
                currentReconnectDelay = INITIAL_RECONNECT_DELAY_MS;
                
                log.info("Successfully connected to T-Invest API");
                
            } catch (Exception e) {
                isConnected.set(false);
                log.error("Failed to connect to T-Invest API", e);
                throw new RuntimeException("Connection failed", e);
            }
        }, connectionExecutor);
    }
    
    /**
     * Отправка запроса через подключение
     * 
     * @param request запрос для отправки
     * @return CompletableFuture, завершающийся при отправке
     */
    public CompletableFuture<Void> sendRequest(MarketDataRequest request) {
        return CompletableFuture.runAsync(() -> {
            StreamObserver<MarketDataRequest> observer = requestObserver.get();
            if (observer == null || !isConnected.get()) {
                throw new IllegalStateException("Not connected to T-Invest API");
            }
            
            try {
                observer.onNext(request);
                log.debug("Request sent successfully");
            } catch (Exception e) {
                log.error("Failed to send request", e);
                isConnected.set(false);
                throw new RuntimeException("Request sending failed", e);
            }
        }, connectionExecutor);
    }
    
    /**
     * Закрытие подключения
     * 
     * @return CompletableFuture, завершающийся при закрытии
     */
    public CompletableFuture<Void> disconnect() {
        return CompletableFuture.runAsync(() -> {
            try {
                StreamObserver<MarketDataRequest> observer = requestObserver.getAndSet(null);
                if (observer != null) {
                    observer.onCompleted();
                }
                isConnected.set(false);
                log.info("Disconnected from T-Invest API");
            } catch (Exception e) {
                log.warn("Error during disconnect", e);
            }
        }, connectionExecutor);
    }
    
    /**
     * Планирование переподключения с экспоненциальной задержкой
     * 
     * @param callback функция для выполнения при переподключении
     */
    public void scheduleReconnect(Runnable callback) {
        if (!isConnected.get()) {
            log.info("Scheduling reconnect in {}ms", currentReconnectDelay);
            
            reconnectScheduler.schedule(() -> {
                try {
                    callback.run();
                } catch (Exception e) {
                    log.error("Error during reconnect callback", e);
                    // Увеличиваем задержку при ошибке
                    increaseReconnectDelay();
                    scheduleReconnect(callback);
                }
            }, currentReconnectDelay, TimeUnit.MILLISECONDS);
        }
    }
    
    /**
     * Увеличение задержки переподключения
     */
    private void increaseReconnectDelay() {
        currentReconnectDelay = Math.min(
            (int) (currentReconnectDelay * RECONNECT_BACKOFF_MULTIPLIER),
            MAX_RECONNECT_DELAY_MS
        );
    }
    
    /**
     * Проверка состояния подключения
     */
    public boolean isConnected() {
        return isConnected.get();
    }
    
    /**
     * Принудительное переподключение
     * 
     * @return CompletableFuture, завершающийся при переподключении
     */
    public CompletableFuture<Void> forceReconnect() {
        return disconnect().thenCompose(v -> connect());
    }
    
    /**
     * Завершение работы менеджера
     */
    public void shutdown() {
        log.info("Shutting down GrpcConnectionManager...");
        
        try {
            disconnect().get(5, TimeUnit.SECONDS);
        } catch (Exception e) {
            log.warn("Error during disconnect on shutdown", e);
        }
        
        reconnectScheduler.shutdown();
        connectionExecutor.shutdown();
        
        try {
            if (!reconnectScheduler.awaitTermination(2, TimeUnit.SECONDS)) {
                reconnectScheduler.shutdownNow();
            }
            if (!connectionExecutor.awaitTermination(5, TimeUnit.SECONDS)) {
                connectionExecutor.shutdownNow();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("Interrupted during shutdown", e);
        }
        
        log.info("GrpcConnectionManager shutdown completed");
    }
}
