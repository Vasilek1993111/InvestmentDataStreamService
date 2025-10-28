package com.example.investmentdatastreamservice.service.streaming;

import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Базовые метрики для потоковых сервисов
 * 
 * Предоставляет стандартный набор метрик для мониторинга производительности
 * потоковых сервисов.
 */
public class StreamingMetrics {
    
    private final AtomicLong totalReceived = new AtomicLong(0);
    private final AtomicLong totalProcessed = new AtomicLong(0);
    private final AtomicLong totalErrors = new AtomicLong(0);
    private final AtomicLong totalDropped = new AtomicLong(0);
    private final AtomicBoolean isRunning = new AtomicBoolean(false);
    private final AtomicBoolean isConnected = new AtomicBoolean(false);
    
    private final String serviceName;
    private final long startTime;
    
    public StreamingMetrics(String serviceName) {
        this.serviceName = serviceName;
        this.startTime = System.currentTimeMillis();
    }
    
    // Getters
    public long getTotalReceived() { return totalReceived.get(); }
    public long getTotalProcessed() { return totalProcessed.get(); }
    public long getTotalErrors() { return totalErrors.get(); }
    public long getTotalDropped() { return totalDropped.get(); }
    public boolean isRunning() { return isRunning.get(); }
    public boolean isConnected() { return isConnected.get(); }
    public String getServiceName() { return serviceName; }
    public long getUptime() { return System.currentTimeMillis() - startTime; }
    
    // Setters
    public void setRunning(boolean running) { this.isRunning.set(running); }
    public void setConnected(boolean connected) { this.isConnected.set(connected); }
    
    // Increment methods
    public long incrementReceived() { return totalReceived.incrementAndGet(); }
    public long incrementProcessed() { return totalProcessed.incrementAndGet(); }
    public long incrementErrors() { return totalErrors.incrementAndGet(); }
    public long incrementDropped() { return totalDropped.incrementAndGet(); }
    
    // Calculated metrics
    public long getPendingOperations() {
        return totalReceived.get() - totalProcessed.get() - totalErrors.get() - totalDropped.get();
    }
    
    public double getProcessingRate() {
        long received = totalReceived.get();
        return received > 0 ? (double) totalProcessed.get() / received : 0.0;
    }
    
    public double getErrorRate() {
        long total = totalProcessed.get() + totalErrors.get();
        return total > 0 ? (double) totalErrors.get() / total : 0.0;
    }
    
    public double getThroughputPerSecond() {
        long uptimeSeconds = getUptime() / 1000;
        return uptimeSeconds > 0 ? (double) totalProcessed.get() / uptimeSeconds : 0.0;
    }
    
    @Override
    public String toString() {
        return String.format(
            "StreamingMetrics[%s]: received=%d, processed=%d, errors=%d, dropped=%d, " +
            "pending=%d, processingRate=%.2f%%, errorRate=%.2f%%, throughput=%.2f/s, " +
            "running=%s, connected=%s, uptime=%dms",
            serviceName, getTotalReceived(), getTotalProcessed(), getTotalErrors(), 
            getTotalDropped(), getPendingOperations(), getProcessingRate() * 100, 
            getErrorRate() * 100, getThroughputPerSecond(), isRunning(), isConnected(), getUptime()
        );
    }
}
