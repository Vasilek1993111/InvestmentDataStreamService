package com.example.investmentdatastreamservice.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.example.investmentdatastreamservice.service.MarketDataStreamingService;
import com.example.investmentdatastreamservice.service.MarketDataStreamingService.ServiceStats;

/**
 * REST контроллер для мониторинга и управления потоковым сервисом
 * 
 * Предоставляет endpoints для мониторинга производительности и управления потоковым сервисом
 * данных.
 */
@RestController
@RequestMapping("/api/streaming-service")
public class StreamingServiceController {

    private final MarketDataStreamingService streamingService;

    public StreamingServiceController(MarketDataStreamingService streamingService) {
        this.streamingService = streamingService;
    }

    /**
     * Получить статистику производительности потокового сервиса
     * 
     * @return статистика сервиса
     */
    @GetMapping("/stats")
    public ResponseEntity<ServiceStats> getServiceStats() {
        ServiceStats stats = streamingService.getServiceStats();
        return ResponseEntity.ok(stats);
    }

    /**
     * Принудительное переподключение к T-Invest API
     * 
     * @return HTTP 200 OK при успешном запросе переподключения
     */
    @PostMapping("/reconnect")
    public ResponseEntity<Void> forceReconnect() {
        streamingService.forceReconnect();
        return ResponseEntity.ok().build();
    }

    /**
     * Получить состояние подключения
     * 
     * @return true если подключен к T-Invest API
     */
    @GetMapping("/status")
    public ResponseEntity<Boolean> getConnectionStatus() {
        ServiceStats stats = streamingService.getServiceStats();
        return ResponseEntity.ok(stats.isConnected());
    }

    /**
     * Получить детальную информацию о состоянии сервиса
     * 
     * @return детальная информация о сервисе
     */
    @GetMapping("/health")
    public ResponseEntity<ServiceHealth> getServiceHealth() {
        ServiceStats stats = streamingService.getServiceStats();
        ServiceHealth health = new ServiceHealth(stats.isRunning(), stats.isConnected(),
                stats.getTotalProcessedAll(), stats.getTotalErrorsAll(),
                stats.getTotalReceivedAll(), stats.getAvailableTradeInserts(),
                stats.getMaxConcurrentTradeInserts(), stats.getTradeInsertUtilization(),
                stats.getOverallErrorRate(), stats.getOverallProcessingRate());
        return ResponseEntity.ok(health);
    }



    /**
     * Детальная информация о состоянии сервиса
     */
    public static class ServiceHealth {
        private final boolean isRunning;
        private final boolean isConnected;
        private final long totalProcessed;
        private final long totalErrors;
        private final long totalReceived;
        private final int availableInserts;
        private final int maxConcurrentInserts;
        private final double insertUtilization;
        private final double errorRate;
        private final double processingRate;

        public ServiceHealth(boolean isRunning, boolean isConnected, long totalProcessed,
                long totalErrors, long totalReceived, int availableInserts,
                int maxConcurrentInserts, double insertUtilization, double errorRate,
                double processingRate) {
            this.isRunning = isRunning;
            this.isConnected = isConnected;
            this.totalProcessed = totalProcessed;
            this.totalErrors = totalErrors;
            this.totalReceived = totalReceived;
            this.availableInserts = availableInserts;
            this.maxConcurrentInserts = maxConcurrentInserts;
            this.insertUtilization = insertUtilization;
            this.errorRate = errorRate;
            this.processingRate = processingRate;
        }

        public boolean isRunning() {
            return isRunning;
        }

        public boolean isConnected() {
            return isConnected;
        }

        public long getTotalProcessed() {
            return totalProcessed;
        }

        public long getTotalErrors() {
            return totalErrors;
        }

        public long getTotalReceived() {
            return totalReceived;
        }

        public int getAvailableInserts() {
            return availableInserts;
        }

        public int getMaxConcurrentInserts() {
            return maxConcurrentInserts;
        }

        public double getInsertUtilization() {
            return insertUtilization;
        }

        public double getErrorRate() {
            return errorRate;
        }

        public double getProcessingRate() {
            return processingRate;
        }
    }
}
