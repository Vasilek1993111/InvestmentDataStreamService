package com.example.investmentdatastreamservice.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.investmentdatastreamservice.service.streaming.StreamingMetrics;
import com.example.investmentdatastreamservice.service.streaming.impl.TradeStreamingService;

/**
 * REST контроллер для управления стримом обезличенных сделок (Trades)
 * 
 * Предоставляет endpoints для запуска, остановки и мониторинга потока trades.
 * Данные записываются в таблицу invest.trades.
 */
@RestController
@RequestMapping("/api/stream/trades")
public class TradeStreamController {

    private final TradeStreamingService tradeStreamingService;

    public TradeStreamController(TradeStreamingService tradeStreamingService) {
        this.tradeStreamingService = tradeStreamingService;
    }

    /**
     * Запуск стрима обезличенных сделок
     * 
     * <p>
     * Запускает получение данных о сделках в реальном времени от T-Invest API
     * и сохраняет их в таблицу invest.trades.
     * </p>
     * 
     * @return HTTP 200 OK при успешном запуске
     */
    @PostMapping("/start")
    public ResponseEntity<Map<String, Object>> startStream() {
        try {
            tradeStreamingService.start().join();
            Map<String, Object> response = Map.of(
                "success", true,
                "message", "Trade streaming started successfully",
                "service", "TradeStreamingService",
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of(
                "success", false,
                "message", "Error starting trade streaming: " + e.getMessage(),
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Остановка стрима обезличенных сделок
     * 
     * @return HTTP 200 OK при успешной остановке
     */
    @PostMapping("/stop")
    public ResponseEntity<Map<String, Object>> stopStream() {
        try {
            tradeStreamingService.stop().join();
            Map<String, Object> response = Map.of(
                "success", true,
                "message", "Trade streaming stopped successfully",
                "service", "TradeStreamingService",
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of(
                "success", false,
                "message", "Error stopping trade streaming: " + e.getMessage(),
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
            tradeStreamingService.reconnect();
            Map<String, Object> response = Map.of(
                "success", true,
                "message", "Trade streaming reconnection initiated",
                "service", "TradeStreamingService",
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of(
                "success", false,
                "message", "Error reconnecting trade streaming: " + e.getMessage(),
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
        boolean isRunning = tradeStreamingService.isRunning();
        boolean isConnected = tradeStreamingService.isConnected();
        
        Map<String, Object> response = Map.of(
            "service", "TradeStreamingService",
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
        StreamingMetrics metrics = tradeStreamingService.getMetrics();
        
        Map<String, Object> response = Map.of(
            "service", "TradeStreamingService",
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

