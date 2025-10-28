package com.example.investmentdatastreamservice.service.streaming.metrics;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import com.example.investmentdatastreamservice.service.streaming.StreamingService;
import com.example.investmentdatastreamservice.service.streaming.StreamingMetrics;

/**
 * Централизованный менеджер метрик для всех потоковых сервисов
 * 
 * Предоставляет единую точку сбора и агрегации метрик от всех потоковых сервисов,
 * включая общую статистику, производительность и состояние системы.
 */
@Component
public class StreamingMetricsManager {
    
    private static final Logger log = LoggerFactory.getLogger(StreamingMetricsManager.class);
    
    private final Map<String, StreamingService<?>> services = new ConcurrentHashMap<>();
    private final Map<String, StreamingMetrics> serviceMetrics = new ConcurrentHashMap<>();
    
    // Глобальные счетчики
    private final AtomicLong totalServicesStarted = new AtomicLong(0);
    private final AtomicLong totalServicesStopped = new AtomicLong(0);
    private final AtomicLong totalReconnections = new AtomicLong(0);
    
    /**
     * Регистрация потокового сервиса
     * 
     * @param service сервис для регистрации
     */
    public void registerService(StreamingService<?> service) {
        String serviceName = service.getServiceName();
        services.put(serviceName, service);
        serviceMetrics.put(serviceName, service.getMetrics());
        
        log.info("Registered streaming service: {}", serviceName);
    }
    
    /**
     * Отмена регистрации потокового сервиса
     * 
     * @param serviceName имя сервиса
     */
    public void unregisterService(String serviceName) {
        services.remove(serviceName);
        serviceMetrics.remove(serviceName);
        
        log.info("Unregistered streaming service: {}", serviceName);
    }
    
    /**
     * Получение метрик конкретного сервиса
     * 
     * @param serviceName имя сервиса
     * @return метрики сервиса или null если не найден
     */
    public StreamingMetrics getServiceMetrics(String serviceName) {
        return serviceMetrics.get(serviceName);
    }
    
    /**
     * Получение агрегированных метрик всех сервисов
     * 
     * @return агрегированные метрики
     */
    public AggregatedMetrics getAggregatedMetrics() {
        long totalReceived = 0;
        long totalProcessed = 0;
        long totalErrors = 0;
        long totalDropped = 0;
        int runningServices = 0;
        int connectedServices = 0;
        
        for (StreamingMetrics metrics : serviceMetrics.values()) {
            totalReceived += metrics.getTotalReceived();
            totalProcessed += metrics.getTotalProcessed();
            totalErrors += metrics.getTotalErrors();
            totalDropped += metrics.getTotalDropped();
            
            if (metrics.isRunning()) {
                runningServices++;
            }
            if (metrics.isConnected()) {
                connectedServices++;
            }
        }
        
        return new AggregatedMetrics(
            totalReceived,
            totalProcessed,
            totalErrors,
            totalDropped,
            runningServices,
            connectedServices,
            services.size(),
            totalServicesStarted.get(),
            totalServicesStopped.get(),
            totalReconnections.get()
        );
    }
    
    /**
     * Получение детализированных метрик по сервисам
     * 
     * @return карта метрик по именам сервисов
     */
    public Map<String, StreamingMetrics> getAllServiceMetrics() {
        return Map.copyOf(serviceMetrics);
    }
    
    /**
     * Получение списка всех зарегистрированных сервисов
     * 
     * @return список сервисов
     */
    public List<StreamingService<?>> getAllServices() {
        return List.copyOf(services.values());
    }
    
    /**
     * Получение сервиса по имени
     * 
     * @param serviceName имя сервиса
     * @return сервис или null если не найден
     */
    public StreamingService<?> getService(String serviceName) {
        return services.get(serviceName);
    }
    
    /**
     * Увеличение счетчика запущенных сервисов
     */
    public void incrementServicesStarted() {
        totalServicesStarted.incrementAndGet();
    }
    
    /**
     * Увеличение счетчика остановленных сервисов
     */
    public void incrementServicesStopped() {
        totalServicesStopped.incrementAndGet();
    }
    
    /**
     * Увеличение счетчика переподключений
     */
    public void incrementReconnections() {
        totalReconnections.incrementAndGet();
    }
    
    /**
     * Проверка состояния всех сервисов
     * 
     * @return true если все сервисы работают и подключены
     */
    public boolean areAllServicesHealthy() {
        return serviceMetrics.values().stream()
            .allMatch(metrics -> metrics.isRunning() && metrics.isConnected());
    }
    
    /**
     * Получение количества проблемных сервисов
     * 
     * @return количество сервисов с ошибками
     */
    public long getProblematicServicesCount() {
        return serviceMetrics.values().stream()
            .mapToLong(metrics -> metrics.getTotalErrors())
            .sum();
    }
    
    /**
     * Агрегированные метрики всех сервисов
     */
    public static class AggregatedMetrics {
        private final long totalReceived;
        private final long totalProcessed;
        private final long totalErrors;
        private final long totalDropped;
        private final int runningServices;
        private final int connectedServices;
        private final int totalServices;
        private final long totalServicesStarted;
        private final long totalServicesStopped;
        private final long totalReconnections;
        
        public AggregatedMetrics(long totalReceived, long totalProcessed, long totalErrors, 
                               long totalDropped, int runningServices, int connectedServices,
                               int totalServices, long totalServicesStarted, long totalServicesStopped,
                               long totalReconnections) {
            this.totalReceived = totalReceived;
            this.totalProcessed = totalProcessed;
            this.totalErrors = totalErrors;
            this.totalDropped = totalDropped;
            this.runningServices = runningServices;
            this.connectedServices = connectedServices;
            this.totalServices = totalServices;
            this.totalServicesStarted = totalServicesStarted;
            this.totalServicesStopped = totalServicesStopped;
            this.totalReconnections = totalReconnections;
        }
        
        // Getters
        public long getTotalReceived() { return totalReceived; }
        public long getTotalProcessed() { return totalProcessed; }
        public long getTotalErrors() { return totalErrors; }
        public long getTotalDropped() { return totalDropped; }
        public int getRunningServices() { return runningServices; }
        public int getConnectedServices() { return connectedServices; }
        public int getTotalServices() { return totalServices; }
        public long getTotalServicesStarted() { return totalServicesStarted; }
        public long getTotalServicesStopped() { return totalServicesStopped; }
        public long getTotalReconnections() { return totalReconnections; }
        
        // Calculated metrics
        public long getPendingOperations() {
            return totalReceived - totalProcessed - totalErrors - totalDropped;
        }
        
        public double getOverallProcessingRate() {
            return totalReceived > 0 ? (double) totalProcessed / totalReceived : 0.0;
        }
        
        public double getOverallErrorRate() {
            long total = totalProcessed + totalErrors;
            return total > 0 ? (double) totalErrors / total : 0.0;
        }
        
        public double getServiceHealthRate() {
            return totalServices > 0 ? (double) connectedServices / totalServices : 0.0;
        }
        
        public double getServiceAvailabilityRate() {
            return totalServices > 0 ? (double) runningServices / totalServices : 0.0;
        }
        
        @Override
        public String toString() {
            return String.format(
                "AggregatedMetrics: received=%d, processed=%d, errors=%d, dropped=%d, " +
                "pending=%d, running=%d/%d, connected=%d/%d, " +
                "processingRate=%.2f%%, errorRate=%.2f%%, healthRate=%.2f%%, availabilityRate=%.2f%%",
                totalReceived, totalProcessed, totalErrors, totalDropped, getPendingOperations(),
                runningServices, totalServices, connectedServices, totalServices,
                getOverallProcessingRate() * 100, getOverallErrorRate() * 100,
                getServiceHealthRate() * 100, getServiceAvailabilityRate() * 100
            );
        }
    }
}
