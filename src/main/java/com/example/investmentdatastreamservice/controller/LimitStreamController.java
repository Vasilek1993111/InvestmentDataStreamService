package com.example.investmentdatastreamservice.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.investmentdatastreamservice.service.streaming.StreamingMetrics;
import com.example.investmentdatastreamservice.service.streaming.impl.LimitMonitoringStreamingService;

/**
 * REST контроллер для управления стримом мониторинга лимитов
 * 
 * Предоставляет endpoints для запуска, остановки и мониторинга потока limit monitoring.
 * Использует LastPrice для отслеживания приближения к лимитам и отправки уведомлений в Telegram.
 */
@RestController
@RequestMapping("/api/stream/limits")
public class LimitStreamController {

    private final LimitMonitoringStreamingService limitMonitoringService;

    public LimitStreamController(LimitMonitoringStreamingService limitMonitoringService) {
        this.limitMonitoringService = limitMonitoringService;
    }

    /**
     * Запуск стрима мониторинга лимитов
     * 
     * <p>
     * Запускает получение данных о ценах последних сделок в реальном времени от T-Invest API
     * для отслеживания приближения к лимитам и отправки уведомлений в Telegram.
     * </p>
     * 
     * @return HTTP 200 OK при успешном запуске
     */
    @PostMapping("/start")
    public ResponseEntity<Map<String, Object>> startStream() {
        try {
            limitMonitoringService.start().join();
            Map<String, Object> response = Map.of(
                "success", true,
                "message", "Limit monitoring streaming started successfully",
                "service", "LimitMonitoringStreamingService",
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of(
                "success", false,
                "message", "Error starting limit monitoring streaming: " + e.getMessage(),
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Остановка стрима мониторинга лимитов
     * 
     * @return HTTP 200 OK при успешной остановке
     */
    @PostMapping("/stop")
    public ResponseEntity<Map<String, Object>> stopStream() {
        try {
            limitMonitoringService.stop().join();
            Map<String, Object> response = Map.of(
                "success", true,
                "message", "Limit monitoring streaming stopped successfully",
                "service", "LimitMonitoringStreamingService",
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of(
                "success", false,
                "message", "Error stopping limit monitoring streaming: " + e.getMessage(),
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Принудительное переподключение стрима
     * 
     * @return HTTP 200 OK при успешном запросе переподключения
     */
    @PostMapping("/reconnect")
    public ResponseEntity<Map<String, Object>> reconnect() {
        try {
            limitMonitoringService.reconnect();
            Map<String, Object> response = Map.of(
                "success", true,
                "message", "Limit monitoring streaming reconnection initiated",
                "service", "LimitMonitoringStreamingService",
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of(
                "success", false,
                "message", "Error reconnecting limit monitoring streaming: " + e.getMessage(),
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получить состояние стрима
     * 
     * @return информация о состоянии стрима
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getStatus() {
        boolean isRunning = limitMonitoringService.isRunning();
        boolean isConnected = limitMonitoringService.isConnected();
        
        Map<String, Object> response = Map.of(
            "service", "LimitMonitoringStreamingService",
            "running", isRunning,
            "connected", isConnected,
            "timestamp", java.time.LocalDateTime.now().toString()
        );
        return ResponseEntity.ok(response);
    }

    /**
     * Получить метрики стрима
     * 
     * @return метрики производительности стрима
     */
    @GetMapping("/metrics")
    public ResponseEntity<Map<String, Object>> getMetrics() {
        StreamingMetrics metrics = limitMonitoringService.getMetrics();
        
        Map<String, Object> response = Map.of(
            "service", "LimitMonitoringStreamingService",
            "running", metrics.isRunning(),
            "connected", metrics.isConnected(),
            "totalReceived", metrics.getTotalReceived(),
            "totalProcessed", metrics.getTotalProcessed(),
            "totalErrors", metrics.getTotalErrors(),
            "totalDropped", metrics.getTotalDropped(),
            "timestamp", java.time.LocalDateTime.now().toString()
        );
        return ResponseEntity.ok(response);
    }
}

