package com.example.investmentdatastreamservice.service;

import java.util.concurrent.atomic.AtomicBoolean;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.example.investmentdatastreamservice.service.streaming.MarketDataStreamingOrchestrator;
import com.example.investmentdatastreamservice.service.streaming.metrics.StreamingMetricsManager.AggregatedMetrics;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;

/**
 * Адаптер для обратной совместимости со старым MarketDataStreamingService
 * 
 * Предоставляет тот же интерфейс, что и старый сервис, но использует новую архитектуру
 * под капотом. Это позволяет сохранить существующие API endpoints без изменений.
 */
@Service
public class MarketDataStreamingServiceAdapter {
    
    private static final Logger log = LoggerFactory.getLogger(MarketDataStreamingServiceAdapter.class);
    
    private final MarketDataStreamingOrchestrator orchestrator;
    
    // Состояние для обратной совместимости
    private final AtomicBoolean isRunning = new AtomicBoolean(false);
    private final AtomicBoolean isConnected = new AtomicBoolean(false);
    
    public MarketDataStreamingServiceAdapter(MarketDataStreamingOrchestrator orchestrator) {
        this.orchestrator = orchestrator;
    }
    
    @PostConstruct
    public void init() {
        log.info("MarketDataStreamingServiceAdapter initialized");
    }
    
    /**
     * Запуск стриминга данных (совместимость со старым API)
     */
    public void startStreaming() {
        log.info("Starting streaming via adapter...");
        
        try {
            orchestrator.startAllServices().get(30, java.util.concurrent.TimeUnit.SECONDS);
            isRunning.set(true);
            log.info("Streaming started successfully via adapter");
        } catch (Exception e) {
            log.error("Failed to start streaming via adapter", e);
            throw new RuntimeException("Failed to start streaming", e);
        }
    }
    
    /**
     * Остановка стриминга данных (совместимость со старым API)
     */
    public void stopStreaming() {
        log.info("Stopping streaming via adapter...");
        
        try {
            orchestrator.stopAllServices().get(30, java.util.concurrent.TimeUnit.SECONDS);
            isRunning.set(false);
            isConnected.set(false);
            log.info("Streaming stopped successfully via adapter");
        } catch (Exception e) {
            log.error("Failed to stop streaming via adapter", e);
            throw new RuntimeException("Failed to stop streaming", e);
        }
    }
    
    /**
     * Принудительное переподключение (совместимость со старым API)
     */
    public void forceReconnect() {
        log.info("Force reconnecting via adapter...");
        
        try {
            orchestrator.reconnectAllServices().get(30, java.util.concurrent.TimeUnit.SECONDS);
            log.info("Reconnection completed via adapter");
        } catch (Exception e) {
            log.error("Failed to reconnect via adapter", e);
            throw new RuntimeException("Failed to reconnect", e);
        }
    }
    
    /**
     * Получение статистики в старом формате
     */
    public ServiceStats getServiceStats() {
        AggregatedMetrics metrics = orchestrator.getAggregatedMetrics();
        
        // Обновляем состояние подключения на основе метрик
        isConnected.set(metrics.getConnectedServices() > 0);
        
        return new ServiceStats(
            isRunning.get(),
            isConnected.get(),
            metrics.getTotalProcessed(), // totalTradeProcessed
            metrics.getTotalErrors(),    // totalTradeErrors
            metrics.getTotalReceived(),  // totalReceived
            metrics.getTotalProcessed(), // totalTradeReceived
            0, // tradeQueueSize (не используется в новой архитектуре)
            200, // tradeBufferCapacity (максимальное значение)
            metrics.getTotalProcessed(), // totalTradeInserted
            metrics.getTotalReceived(),   // totalLastPriceReceived
            metrics.getTotalProcessed(),  // totalLastPriceProcessed
            metrics.getTotalProcessed(),  // totalLastPriceInserted
            0, // totalLastPriceReceivedShares
            0, // totalLastPriceReceivedFutures
            0, // totalLastPriceReceivedIndicatives
            0, // totalTradeReceivedShares
            0, // totalTradeReceivedFutures
            0  // totalTradeReceivedIndicatives
        );
    }
    
    @PreDestroy
    public void shutdown() {
        log.info("Shutting down MarketDataStreamingServiceAdapter...");
        if (isRunning.get()) {
            stopStreaming();
        }
    }
    
    /**
     * Статистика сервиса в старом формате для обратной совместимости
     */
    public static class ServiceStats {
        private final boolean isRunning;
        private final boolean isConnected;
        private final long totalTradeProcessed;
        private final long totalTradeErrors;
        private final long totalReceived;
        private final long totalTradeReceived;
        private final int tradeQueueSize;
        private final int tradeBufferCapacity;
        private final long totalTradeInserted;
        private final long totalLastPriceReceived;
        private final long totalLastPriceProcessed;
        private final long totalLastPriceInserted;
        private final long totalLastPriceReceivedShares;
        private final long totalLastPriceReceivedFutures;
        private final long totalLastPriceReceivedIndicatives;
        private final long totalTradeReceivedShares;
        private final long totalTradeReceivedFutures;
        private final long totalTradeReceivedIndicatives;
        
        public ServiceStats(boolean isRunning, boolean isConnected, long totalTradeProcessed,
                long totalTradeErrors, long totalReceived, long totalTradeReceived,
                int tradeQueueSize, int tradeBufferCapacity, long totalTradeInserted,
                long totalLastPriceReceived, long totalLastPriceProcessed,
                long totalLastPriceInserted, long totalLastPriceReceivedShares,
                long totalLastPriceReceivedFutures, long totalLastPriceReceivedIndicatives,
                long totalTradeReceivedShares, long totalTradeReceivedFutures,
                long totalTradeReceivedIndicatives) {
            this.isRunning = isRunning;
            this.isConnected = isConnected;
            this.totalTradeProcessed = totalTradeProcessed;
            this.totalTradeErrors = totalTradeErrors;
            this.totalReceived = totalReceived;
            this.totalTradeReceived = totalTradeReceived;
            this.tradeQueueSize = tradeQueueSize;
            this.tradeBufferCapacity = tradeBufferCapacity;
            this.totalTradeInserted = totalTradeInserted;
            this.totalLastPriceReceived = totalLastPriceReceived;
            this.totalLastPriceProcessed = totalLastPriceProcessed;
            this.totalLastPriceInserted = totalLastPriceInserted;
            this.totalLastPriceReceivedShares = totalLastPriceReceivedShares;
            this.totalLastPriceReceivedFutures = totalLastPriceReceivedFutures;
            this.totalLastPriceReceivedIndicatives = totalLastPriceReceivedIndicatives;
            this.totalTradeReceivedShares = totalTradeReceivedShares;
            this.totalTradeReceivedFutures = totalTradeReceivedFutures;
            this.totalTradeReceivedIndicatives = totalTradeReceivedIndicatives;
        }
        
        // Getters для совместимости со старым API
        public boolean isRunning() { return isRunning; }
        public boolean isConnected() { return isConnected; }
        public long getTotalTradeProcessed() { return totalTradeProcessed; }
        public long getTotalTradeErrors() { return totalTradeErrors; }
        public long getTotalReceived() { return totalReceived; }
        public long getTotalTradeReceived() { return totalTradeReceived; }
        public long getTotalTradeInserted() { return totalTradeInserted; }
        public int getAvailableTradeInserts() { return tradeQueueSize; }
        public int getMaxConcurrentTradeInserts() { return tradeBufferCapacity; }
        public double getTradeInsertUtilization() {
            return tradeBufferCapacity > 0 ? (double) (tradeBufferCapacity - tradeQueueSize) / tradeBufferCapacity : 0.0;
        }
        public double getTradeErrorRate() {
            long total = totalTradeProcessed + totalTradeErrors;
            return total > 0 ? (double) totalTradeErrors / total : 0.0;
        }
        public double getTradeProcessingRate() {
            return totalTradeReceived > 0 ? (double) totalTradeProcessed / totalTradeReceived : 0.0;
        }
        public long getTotalProcessedAll() { return totalTradeInserted; }
        public long getTotalErrorsAll() { return totalTradeErrors; }
        public long getTotalReceivedAll() { return totalReceived + totalTradeReceived; }
        public long getTotalLastPriceReceived() { return totalLastPriceReceived; }
        public long getTotalLastPriceProcessed() { return totalLastPriceProcessed; }
        public long getTotalLastPriceInserted() { return totalLastPriceInserted; }
        public long getTotalLastPriceReceivedShares() { return totalLastPriceReceivedShares; }
        public long getTotalLastPriceReceivedFutures() { return totalLastPriceReceivedFutures; }
        public long getTotalLastPriceReceivedIndicatives() { return totalLastPriceReceivedIndicatives; }
        public long getTotalTradeReceivedShares() { return totalTradeReceivedShares; }
        public long getTotalTradeReceivedFutures() { return totalTradeReceivedFutures; }
        public long getTotalTradeReceivedIndicatives() { return totalTradeReceivedIndicatives; }
        public long getTotalTradeMessagesReceived() { return totalTradeReceived; }
        public long getTotalTradesInserted() { return totalTradeInserted; }
        public long getTotalTradesProcessed() { return totalTradeProcessed; }
        public double getOverallErrorRate() {
            long total = getTotalProcessedAll() + getTotalErrorsAll();
            return total > 0 ? (double) getTotalErrorsAll() / total : 0.0;
        }
        public double getOverallProcessingRate() {
            return getTotalReceivedAll() > 0 ? (double) getTotalProcessedAll() / getTotalReceivedAll() : 0.0;
        }
    }
}
