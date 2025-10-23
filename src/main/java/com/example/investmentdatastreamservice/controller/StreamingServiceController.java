package com.example.investmentdatastreamservice.controller;

import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.example.investmentdatastreamservice.dto.*;
import com.example.investmentdatastreamservice.mapper.StatsMapper;
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
    private final StatsMapper statsMapper;

    public StreamingServiceController(MarketDataStreamingService streamingService, StatsMapper statsMapper) {
        this.streamingService = streamingService;
        this.statsMapper = statsMapper;
    }

    /**
     * Получить статистику производительности потокового сервиса
     * 
     * @return статистика сервиса
     */
    @GetMapping("/stats")
    public ResponseEntity<ObjectStatsDto> getServiceStats() {
        ServiceStats stats = streamingService.getServiceStats();
        ObjectStatsDto objectStats = statsMapper.toObjectStatsDto(stats);
        return ResponseEntity.ok(objectStats);
    }

    /**
     * Запуск стриминга данных
     * 
     * <p>
     * Запускает получение данных в реальном времени от T-Invest API:
     * </p>
     * <ul>
     * <li>LastPrice - цены последних сделок</li>
     * <li>Trades - обезличенные сделки</li>
     * </ul>
     * 
     * @return HTTP 200 OK при успешном запуске
     */
    @PostMapping("/start")
    public ResponseEntity<Map<String, Object>> startStreaming() {
        try {
            streamingService.startStreaming();
            Map<String, Object> response =
                    Map.of("success", true, "message", "Стриминг данных успешно запущен",
                            "timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of("success", false, "message",
                    "Ошибка при запуске стриминга: " + e.getMessage(), "timestamp",
                    java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Остановка стриминга данных
     * 
     * <p>
     * Останавливает получение данных от T-Invest API.
     * </p>
     * 
     * @return HTTP 200 OK при успешной остановке
     */
    @PostMapping("/stop")
    public ResponseEntity<Map<String, Object>> stopStreaming() {
        try {
            streamingService.stopStreaming();
            Map<String, Object> response =
                    Map.of("success", true, "message", "Стриминг данных успешно остановлен",
                            "timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of("success", false, "message",
                    "Ошибка при остановке стриминга: " + e.getMessage(), "timestamp",
                    java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Принудительное переподключение к T-Invest API
     * 
     * @return HTTP 200 OK при успешном запросе переподключения
     */
    @PostMapping("/reconnect")
    public ResponseEntity<Map<String, Object>> forceReconnect() {
        try {
            streamingService.forceReconnect();
            Map<String, Object> response =
                    Map.of("success", true, "message", "Переподключение инициировано", "timestamp",
                            java.time.LocalDateTime.now().toString());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = Map.of("success", false, "message",
                    "Ошибка при переподключении: " + e.getMessage(), "timestamp",
                    java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
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
    public ResponseEntity<ServiceHealthDto> getServiceHealth() {
        ServiceStats stats = streamingService.getServiceStats();
        ServiceHealthDto health = statsMapper.toServiceHealthDto(stats);
        return ResponseEntity.ok(health);
    }



}
