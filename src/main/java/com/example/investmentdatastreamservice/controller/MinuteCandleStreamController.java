package com.example.investmentdatastreamservice.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.investmentdatastreamservice.service.streaming.StreamingMetrics;
import com.example.investmentdatastreamservice.service.streaming.impl.MinuteCandleStreamingService;

/**
 * REST контроллер для управления стримом минутных свечей
 * 
 * Предоставляет endpoints для запуска, остановки и мониторинга потока minute_candles.
 * Данные записываются в таблицу invest.minute_candles.
 */
@RestController
@RequestMapping("/api/stream/minute-candles")
public class MinuteCandleStreamController {

    private final MinuteCandleStreamingService candleStreamingService;

    public MinuteCandleStreamController(MinuteCandleStreamingService candleStreamingService) {
        this.candleStreamingService = candleStreamingService;
    }

    /**
     * Запуск стрима минутных свечей
     * 
     * <p>
     * Запускает получение данных о минутных свечах в реальном времени от T-Invest API
     * и сохраняет их в таблицу invest.minute_candles.
     * </p>
     * 
     * @return HTTP 200 OK при успешном запуске
     */
    @PostMapping("/start")
    public ResponseEntity<Map<String, Object>> startStream() {
        try {
            candleStreamingService.start().join();
            Map<String, Object> response = Map.of(
                "success", true,
                "message", "MinuteCandle streaming started successfully",
                "service", "MinuteCandleStreamingService",
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of(
                "success", false,
                "message", "Error starting minute candle streaming: " + e.getMessage(),
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Остановка стрима минутных свечей
     * 
     * @return HTTP 200 OK при успешной остановке
     */
    @PostMapping("/stop")
    public ResponseEntity<Map<String, Object>> stopStream() {
        try {
            candleStreamingService.stop().join();
            Map<String, Object> response = Map.of(
                "success", true,
                "message", "MinuteCandle streaming stopped successfully",
                "service", "MinuteCandleStreamingService",
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of(
                "success", false,
                "message", "Error stopping minute candle streaming: " + e.getMessage(),
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
            candleStreamingService.reconnect();
            Map<String, Object> response = Map.of(
                "success", true,
                "message", "MinuteCandle streaming reconnection initiated",
                "service", "MinuteCandleStreamingService",
                "timestamp", java.time.LocalDateTime.now().toString()
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of(
                "success", false,
                "message", "Error reconnecting minute candle streaming: " + e.getMessage(),
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
        boolean isRunning = candleStreamingService.isRunning();
        boolean isConnected = candleStreamingService.isConnected();
        
        Map<String, Object> response = Map.of(
            "service", "MinuteCandleStreamingService",
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
        StreamingMetrics metrics = candleStreamingService.getMetrics();
        
        Map<String, Object> response = Map.of(
            "service", "MinuteCandleStreamingService",
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

