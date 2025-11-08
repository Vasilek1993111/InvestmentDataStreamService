package com.example.investmentdatastreamservice.service.streaming;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.grpc.ClientInterceptor;
import io.grpc.ForwardingClientCall;
import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import io.grpc.Metadata;
import io.grpc.stub.StreamObserver;
import ru.tinkoff.piapi.contract.v1.MarketDataRequest;
import ru.tinkoff.piapi.contract.v1.MarketDataResponse;
import ru.tinkoff.piapi.contract.v1.MarketDataStreamServiceGrpc;

/**
 * Менеджер множественных stream-соединений для обхода API лимита в 300 подписок
 * 
 * Управляет несколькими GrpcConnectionManager'ами, каждый из которых
 * обрабатывает свой батч инструментов (до 250 на stream).
 */
public class MultiStreamManager {
    
    private static final Logger log = LoggerFactory.getLogger(MultiStreamManager.class);
    
    private final String token;
    private final List<GrpcConnectionManager> connectionManagers;
    private final AtomicBoolean isRunning = new AtomicBoolean(false);
    private final AtomicInteger activeConnections = new AtomicInteger(0);
    
    /**
     * Общий observer для всех stream'ов
     */
    private StreamObserver<MarketDataResponse> sharedResponseObserver;
    
    public MultiStreamManager(String token, int expectedBatchCount) {
        this.token = token;
        this.connectionManagers = new CopyOnWriteArrayList<>();
        
        log.info("MultiStreamManager initialized for up to {} stream connections", expectedBatchCount);
    }
    
    /**
     * Устанавливает общий observer для всех stream'ов
     */
    public void setSharedResponseObserver(StreamObserver<MarketDataResponse> observer) {
        this.sharedResponseObserver = observer;
        log.info("Shared response observer set for all streams");
    }
    
    /**
     * Создает новое stream-соединение для батча
     * 
     * @param batchIndex индекс батча (для логирования)
     * @return новый GrpcConnectionManager
     */
    public GrpcConnectionManager createStreamForBatch(int batchIndex) {
        // Создаем auth interceptor для токена
        ClientInterceptor authInterceptor = new ClientInterceptor() {
            @Override
            public <ReqT, RespT> io.grpc.ClientCall<ReqT, RespT> interceptCall(
                    io.grpc.MethodDescriptor<ReqT, RespT> method, 
                    io.grpc.CallOptions callOptions,
                    io.grpc.Channel next) {
                return new ForwardingClientCall.SimpleForwardingClientCall<>(
                        next.newCall(method, callOptions)) {
                    @Override
                    public void start(Listener<RespT> responseListener, Metadata headers) {
                        headers.put(
                                Metadata.Key.of("Authorization", Metadata.ASCII_STRING_MARSHALLER),
                                "Bearer " + token);
                        super.start(responseListener, headers);
                    }
                };
            }
        };
        
        // Создаем новый channel для этого stream
        ManagedChannel channel = ManagedChannelBuilder
            .forAddress("invest-public-api.tinkoff.ru", 443)
            .useTransportSecurity()
            .intercept(authInterceptor)
            .keepAliveTime(30, TimeUnit.SECONDS)
            .keepAliveTimeout(5, TimeUnit.SECONDS)
            .keepAliveWithoutCalls(true)
            .maxInboundMessageSize(4 * 1024 * 1024) // 4MB
            .maxInboundMetadataSize(8 * 1024) // 8KB
            .enableRetry()
            .maxRetryAttempts(3)
            .build();
        
        // Создаем stub для этого channel
        MarketDataStreamServiceGrpc.MarketDataStreamServiceStub stub = 
            MarketDataStreamServiceGrpc.newStub(channel);
        
        // Создаем connection manager с этим stub
        GrpcConnectionManager manager = new GrpcConnectionManager(stub);
        
        if (sharedResponseObserver != null) {
            manager.setResponseObserver(sharedResponseObserver);
        }
        
        connectionManagers.add(manager);
        
        log.info("Created stream connection #{} (total connections: {})", 
            batchIndex + 1, connectionManagers.size());
        
        return manager;
    }
    
    /**
     * Подключает все stream'ы
     */
    public CompletableFuture<Void> connectAll() {
        if (connectionManagers.isEmpty()) {
            log.warn("No connection managers to connect");
            return CompletableFuture.completedFuture(null);
        }
        
        log.info("Connecting {} stream connections...", connectionManagers.size());
        isRunning.set(true);
        
        List<CompletableFuture<Void>> futures = new ArrayList<>();
        
        for (int i = 0; i < connectionManagers.size(); i++) {
            final int index = i;
            GrpcConnectionManager manager = connectionManagers.get(i);
            
            CompletableFuture<Void> future = manager.connect()
                .thenRun(() -> {
                    activeConnections.incrementAndGet();
                    log.info("Stream connection #{} established ({}/{})", 
                        index + 1, activeConnections.get(), connectionManagers.size());
                })
                .exceptionally(throwable -> {
                    log.error("Failed to establish stream connection #{}: {}", 
                        index + 1, throwable.getMessage());
                    return null;
                });
            
            futures.add(future);
        }
        
        return CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]))
            .thenRun(() -> {
                log.info("All {} stream connections established successfully", activeConnections.get());
            });
    }
    
    /**
     * Отправляет запрос на подписку через указанный stream
     * 
     * @param batchIndex индекс батча
     * @param request запрос на подписку
     * @param delayMs задержка перед отправкой (для rate limiting)
     */
    public CompletableFuture<Void> sendBatchSubscription(
            int batchIndex, 
            MarketDataRequest request,
            long delayMs) {
        
        if (batchIndex < 0 || batchIndex >= connectionManagers.size()) {
            return CompletableFuture.failedFuture(
                new IllegalArgumentException("Invalid batch index: " + batchIndex));
        }
        
        GrpcConnectionManager manager = connectionManagers.get(batchIndex);
        
        if (delayMs > 0) {
            log.info("Waiting {}ms before subscribing batch {}/{} (rate limiting)...", 
                delayMs, batchIndex + 1, connectionManagers.size());
            
            return CompletableFuture.runAsync(() -> {
                try {
                    TimeUnit.MILLISECONDS.sleep(delayMs);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    log.warn("Interrupted while waiting to send batch subscription");
                }
            }).thenCompose(v -> {
                log.info("Subscribing batch {}/{} ({} instruments)", 
                    batchIndex + 1, connectionManagers.size(), 
                    request.getSubscribeLastPriceRequest().getInstrumentsCount());
                return manager.sendRequest(request);
            });
        } else {
            log.info("Subscribing batch {}/{} ({} instruments)", 
                batchIndex + 1, connectionManagers.size(), 
                request.getSubscribeLastPriceRequest().getInstrumentsCount());
            return manager.sendRequest(request);
        }
    }
    
    /**
     * Отключает все stream'ы
     */
    public CompletableFuture<Void> disconnectAll() {
        if (connectionManagers.isEmpty()) {
            return CompletableFuture.completedFuture(null);
        }
        
        log.info("Disconnecting {} stream connections...", connectionManagers.size());
        isRunning.set(false);
        
        List<CompletableFuture<Void>> futures = new ArrayList<>();
        
        for (GrpcConnectionManager manager : connectionManagers) {
            futures.add(manager.disconnect()
                .exceptionally(throwable -> {
                    log.warn("Error disconnecting stream: {}", throwable.getMessage());
                    return null;
                }));
        }
        
        return CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]))
            .thenRun(() -> {
                activeConnections.set(0);
                connectionManagers.clear();
                log.info("All stream connections disconnected");
            });
    }
    
    /**
     * Принудительное переподключение всех stream'ов
     */
    public CompletableFuture<Void> forceReconnectAll() {
        log.info("Force reconnecting all streams...");
        
        return disconnectAll()
            .thenCompose(v -> connectAll())
            .whenComplete((result, throwable) -> {
                if (throwable != null) {
                    log.error("Failed to force reconnect all streams", throwable);
                } else {
                    log.info("All streams reconnected successfully");
                }
            });
    }
    
    /**
     * Проверяет, все ли stream'ы подключены
     */
    public boolean isAllConnected() {
        if (connectionManagers.isEmpty()) {
            return false;
        }
        return connectionManagers.stream().allMatch(GrpcConnectionManager::isConnected);
    }
    
    /**
     * Получает количество активных соединений
     */
    public int getActiveConnectionCount() {
        return (int) connectionManagers.stream()
            .filter(GrpcConnectionManager::isConnected)
            .count();
    }
    
    /**
     * Получает общее количество stream'ов
     */
    public int getTotalStreamCount() {
        return connectionManagers.size();
    }
    
    /**
     * Проверяет, работает ли менеджер
     */
    public boolean isRunning() {
        return isRunning.get();
    }
}

