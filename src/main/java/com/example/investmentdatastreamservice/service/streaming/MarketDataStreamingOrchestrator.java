package com.example.investmentdatastreamservice.service.streaming;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicBoolean;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.example.investmentdatastreamservice.service.streaming.impl.LastPriceStreamingService;
import com.example.investmentdatastreamservice.service.streaming.impl.TradeStreamingService;
import com.example.investmentdatastreamservice.service.streaming.impl.LimitMonitoringStreamingService;
import com.example.investmentdatastreamservice.service.streaming.metrics.StreamingMetricsManager;
import com.example.investmentdatastreamservice.service.streaming.metrics.StreamingMetricsManager.AggregatedMetrics;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;

/**
 * Главный сервис для управления всеми потоковыми сервисами
 * 
 * Координирует работу всех потоковых сервисов (LastPrice, Trade, Candle),
 * предоставляет единый API для управления и мониторинга всей системы потоковых данных.
 */
@Service
public class MarketDataStreamingOrchestrator {
    
    private static final Logger log = LoggerFactory.getLogger(MarketDataStreamingOrchestrator.class);
    
    private final LastPriceStreamingService lastPriceService;
    private final TradeStreamingService tradeService;
    private final LimitMonitoringStreamingService limitMonitoringService;
    private final StreamingMetricsManager metricsManager;
    
    private final AtomicBoolean isInitialized = new AtomicBoolean(false);
    
    public MarketDataStreamingOrchestrator(
            LastPriceStreamingService lastPriceService,
            TradeStreamingService tradeService,
            LimitMonitoringStreamingService limitMonitoringService,
            StreamingMetricsManager metricsManager) {
        
        this.lastPriceService = lastPriceService;
        this.tradeService = tradeService;
        this.limitMonitoringService = limitMonitoringService;
        this.metricsManager = metricsManager;
    }
    
    /**
     * Инициализация оркестратора
     */
    @PostConstruct
    public void init() {
        log.info("=== MARKET DATA STREAMING ORCHESTRATOR INITIALIZATION ===");
        
        // Регистрируем все сервисы в менеджере метрик
        metricsManager.registerService(lastPriceService);
        metricsManager.registerService(tradeService);
        metricsManager.registerService(limitMonitoringService);
        
        isInitialized.set(true);
        
        log.info("MarketDataStreamingOrchestrator initialized successfully");
        log.info("Registered services: LastPrice, Trade, LimitMonitoring");
        log.info("================================================================");
    }
    
    /**
     * Запуск всех потоковых сервисов
     * 
     * @return CompletableFuture, завершающийся при запуске всех сервисов
     */
    public CompletableFuture<Void> startAllServices() {
        if (!isInitialized.get()) {
            return CompletableFuture.failedFuture(new IllegalStateException("Orchestrator not initialized"));
        }
        
        log.info("Starting all streaming services...");
        
        return CompletableFuture.allOf(
            lastPriceService.start().thenRun(() -> {
                metricsManager.incrementServicesStarted();
                log.info("LastPrice service started");
            }),
            tradeService.start().thenRun(() -> {
                metricsManager.incrementServicesStarted();
                log.info("Trade service started");
            }),
            limitMonitoringService.start().thenRun(() -> {
                metricsManager.incrementServicesStarted();
                log.info("Limit monitoring service started");
            })
        ).whenComplete((result, throwable) -> {
            if (throwable != null) {
                log.error("Error starting streaming services", throwable);
            } else {
                log.info("All streaming services started successfully");
            }
        });
    }
    
    /**
     * Остановка всех потоковых сервисов
     * 
     * @return CompletableFuture, завершающийся при остановке всех сервисов
     */
    public CompletableFuture<Void> stopAllServices() {
        log.info("Stopping all streaming services...");
        
        return CompletableFuture.allOf(
            lastPriceService.stop().thenRun(() -> {
                metricsManager.incrementServicesStopped();
                log.info("LastPrice service stopped");
            }),
            tradeService.stop().thenRun(() -> {
                metricsManager.incrementServicesStopped();
                log.info("Trade service stopped");
            }),
            limitMonitoringService.stop().thenRun(() -> {
                metricsManager.incrementServicesStopped();
                log.info("Limit monitoring service stopped");
            })
        ).whenComplete((result, throwable) -> {
            if (throwable != null) {
                log.error("Error stopping streaming services", throwable);
            } else {
                log.info("All streaming services stopped successfully");
            }
        });
    }
    
    /**
     * Переподключение всех сервисов
     * 
     * @return CompletableFuture, завершающийся при переподключении всех сервисов
     */
    public CompletableFuture<Void> reconnectAllServices() {
        log.info("Reconnecting all streaming services...");
        
        return CompletableFuture.allOf(
            lastPriceService.reconnect().thenRun(() -> {
                metricsManager.incrementReconnections();
                log.info("LastPrice service reconnected");
            }),
            tradeService.reconnect().thenRun(() -> {
                metricsManager.incrementReconnections();
                log.info("Trade service reconnected");
            }),
            limitMonitoringService.reconnect().thenRun(() -> {
                metricsManager.incrementReconnections();
                log.info("Limit monitoring service reconnected");
            })
        ).whenComplete((result, throwable) -> {
            if (throwable != null) {
                log.error("Error reconnecting streaming services", throwable);
            } else {
                log.info("All streaming services reconnected successfully");
            }
        });
    }
    
    /**
     * Запуск конкретного сервиса
     * 
     * @param serviceName имя сервиса
     * @return CompletableFuture, завершающийся при запуске сервиса
     */
    public CompletableFuture<Void> startService(String serviceName) {
        StreamingService<?> service = metricsManager.getService(serviceName);
        if (service == null) {
            return CompletableFuture.failedFuture(new IllegalArgumentException("Service not found: " + serviceName));
        }
        
        log.info("Starting service: {}", serviceName);
        return service.start().thenRun(() -> {
            metricsManager.incrementServicesStarted();
            log.info("Service {} started", serviceName);
        });
    }
    
    /**
     * Остановка конкретного сервиса
     * 
     * @param serviceName имя сервиса
     * @return CompletableFuture, завершающийся при остановке сервиса
     */
    public CompletableFuture<Void> stopService(String serviceName) {
        StreamingService<?> service = metricsManager.getService(serviceName);
        if (service == null) {
            return CompletableFuture.failedFuture(new IllegalArgumentException("Service not found: " + serviceName));
        }
        
        log.info("Stopping service: {}", serviceName);
        return service.stop().thenRun(() -> {
            metricsManager.incrementServicesStopped();
            log.info("Service {} stopped", serviceName);
        });
    }
    
    /**
     * Переподключение конкретного сервиса
     * 
     * @param serviceName имя сервиса
     * @return CompletableFuture, завершающийся при переподключении сервиса
     */
    public CompletableFuture<Void> reconnectService(String serviceName) {
        StreamingService<?> service = metricsManager.getService(serviceName);
        if (service == null) {
            return CompletableFuture.failedFuture(new IllegalArgumentException("Service not found: " + serviceName));
        }
        
        log.info("Reconnecting service: {}", serviceName);
        return service.reconnect().thenRun(() -> {
            metricsManager.incrementReconnections();
            log.info("Service {} reconnected", serviceName);
        });
    }
    
    /**
     * Получение агрегированных метрик всех сервисов
     * 
     * @return агрегированные метрики
     */
    public AggregatedMetrics getAggregatedMetrics() {
        return metricsManager.getAggregatedMetrics();
    }
    
    /**
     * Получение метрик конкретного сервиса
     * 
     * @param serviceName имя сервиса
     * @return метрики сервиса
     */
    public StreamingMetrics getServiceMetrics(String serviceName) {
        return metricsManager.getServiceMetrics(serviceName);
    }
    
    /**
     * Получение состояния всех сервисов
     * 
     * @return карта состояний сервисов
     */
    public java.util.Map<String, ServiceStatus> getAllServiceStatuses() {
        return metricsManager.getAllServices().stream()
            .collect(java.util.stream.Collectors.toMap(
                StreamingService::getServiceName,
                service -> new ServiceStatus(
                    service.isRunning(),
                    service.isConnected(),
                    service.getMetrics().getTotalReceived(),
                    service.getMetrics().getTotalProcessed(),
                    service.getMetrics().getTotalErrors()
                )
            ));
    }
    
    /**
     * Проверка состояния системы
     * 
     * @return true если все сервисы работают и подключены
     */
    public boolean isSystemHealthy() {
        return metricsManager.areAllServicesHealthy();
    }
    
    /**
     * Получение списка всех сервисов
     * 
     * @return список сервисов
     */
    public List<StreamingService<?>> getAllServices() {
        return metricsManager.getAllServices();
    }
    
    /**
     * Завершение работы оркестратора
     */
    @PreDestroy
    public void shutdown() {
        log.info("Shutting down MarketDataStreamingOrchestrator...");
        
        try {
            stopAllServices().get(30, java.util.concurrent.TimeUnit.SECONDS);
        } catch (Exception e) {
            log.error("Error during shutdown", e);
        }
        
        log.info("MarketDataStreamingOrchestrator shutdown completed");
    }
    
    /**
     * Статус сервиса
     */
    public static class ServiceStatus {
        private final boolean isRunning;
        private final boolean isConnected;
        private final long totalReceived;
        private final long totalProcessed;
        private final long totalErrors;
        
        public ServiceStatus(boolean isRunning, boolean isConnected, long totalReceived, 
                           long totalProcessed, long totalErrors) {
            this.isRunning = isRunning;
            this.isConnected = isConnected;
            this.totalReceived = totalReceived;
            this.totalProcessed = totalProcessed;
            this.totalErrors = totalErrors;
        }
        
        // Getters
        public boolean isRunning() { return isRunning; }
        public boolean isConnected() { return isConnected; }
        public long getTotalReceived() { return totalReceived; }
        public long getTotalProcessed() { return totalProcessed; }
        public long getTotalErrors() { return totalErrors; }
        
        public boolean isHealthy() {
            return isRunning && isConnected && totalErrors == 0;
        }
        
        public double getProcessingRate() {
            return totalReceived > 0 ? (double) totalProcessed / totalReceived : 0.0;
        }
        
        public double getErrorRate() {
            long total = totalProcessed + totalErrors;
            return total > 0 ? (double) totalErrors / total : 0.0;
        }
    }
}
