package com.example.investmentdatastreamservice.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.investmentdatastreamservice.service.streaming.StreamingMetrics;
import com.example.investmentdatastreamservice.service.streaming.impl.LastPriceStreamingService;

/**
 * REST контроллер для управления стримом цен последних сделок (LastPrice)
 * 
 * Предоставляет endpoints для запуска, остановки и мониторинга потока last_price.
 * Данные записываются в таблицу invest.last_prices.
 */
@RestController
@RequestMapping("/api/stream/last-price")
public class LastPriceStreamController {

    private final LastPriceStreamingService lastPriceStreamingService;

    public LastPriceStreamController(LastPriceStreamingService lastPriceStreamingService) {
        this.lastPriceStreamingService = lastPriceStreamingService;
    }

    /**
     * Запуск стрима цен последних сделок
     * 
     * <p>
     * Запускает получение данных о ценах последних сделок в реальном времени от T-Invest API
     * и сохраняет их в таблицу invest.last_prices.
     * </p>
     * 
     * @return HTTP 200 OK при успешном запуске
     */
    @PostMapping("/start")
    public ResponseEntity<Map<String, Object>> startStream() {
        try {
            lastPriceStreamingService.start().join();
            Map<String, Object> response = Map.of(
                "success", true,
                "message", "LastPrice streaming started successfully",
                "service", "LastPriceStreamingService",
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of(
                "success", false,
                "message", "Error starting last price streaming: " + e.getMessage(),
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Остановка стрима цен последних сделок
     * 
     * @return HTTP 200 OK при успешной остановке
     */
    @PostMapping("/stop")
    public ResponseEntity<Map<String, Object>> stopStream() {
        try {
            lastPriceStreamingService.stop().join();
            Map<String, Object> response = Map.of(
                "success", true,
                "message", "LastPrice streaming stopped successfully",
                "service", "LastPriceStreamingService",
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of(
                "success", false,
                "message", "Error stopping last price streaming: " + e.getMessage(),
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
            lastPriceStreamingService.reconnect();
            Map<String, Object> response = Map.of(
                "success", true,
                "message", "LastPrice streaming reconnection initiated",
                "service", "LastPriceStreamingService",
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of(
                "success", false,
                "message", "Error reconnecting last price streaming: " + e.getMessage(),
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
        boolean isRunning = lastPriceStreamingService.isRunning();
        boolean isConnected = lastPriceStreamingService.isConnected();
        
        Map<String, Object> response = Map.of(
            "service", "LastPriceStreamingService",
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
        StreamingMetrics metrics = lastPriceStreamingService.getMetrics();
        
        Map<String, Object> response = Map.of(
            "service", "LastPriceStreamingService",
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

