package com.example.investmentdatastreamservice.controller;

import com.example.investmentdatastreamservice.service.LimitMonitorService;
import com.example.investmentdatastreamservice.service.streaming.MarketDataStreamingOrchestrator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * Контроллер для управления мониторингом лимитов
 * 
 * Предоставляет API для управления сервисом мониторинга лимитов,
 * получения статистики и управления уведомлениями.
 */
@RestController
@RequestMapping("/api/limit-monitoring")
public class LimitMonitoringController {
    
    private static final Logger logger = LoggerFactory.getLogger(LimitMonitoringController.class);
    
    private final LimitMonitorService limitMonitorService;
    private final MarketDataStreamingOrchestrator orchestrator;
    
    public LimitMonitoringController(
            LimitMonitorService limitMonitorService,
            MarketDataStreamingOrchestrator orchestrator) {
        this.limitMonitorService = limitMonitorService;
        this.orchestrator = orchestrator;
    }
    
    /**
     * Получить статистику мониторинга лимитов
     * 
     * @return статистика работы сервиса мониторинга лимитов
     */
    @GetMapping("/statistics")
    public ResponseEntity<Map<String, Object>> getStatistics() {
        try {
            Map<String, Object> stats = limitMonitorService.getStatistics();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", stats);
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Ошибка при получении статистики мониторинга лимитов", e);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении статистики: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.status(500).body(response);
        }
    }
    
    /**
     * Запустить сервис мониторинга лимитов
     * 
     * @return результат запуска сервиса
     */
    @PostMapping("/start")
    public ResponseEntity<Map<String, Object>> startLimitMonitoring() {
        try {
            orchestrator.startService("LimitMonitoringStreamingService").join();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Сервис мониторинга лимитов запущен");
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Ошибка при запуске сервиса мониторинга лимитов", e);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при запуске сервиса: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.status(500).body(response);
        }
    }
    
    /**
     * Остановить сервис мониторинга лимитов
     * 
     * @return результат остановки сервиса
     */
    @PostMapping("/stop")
    public ResponseEntity<Map<String, Object>> stopLimitMonitoring() {
        try {
            orchestrator.stopService("LimitMonitoringStreamingService").join();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Сервис мониторинга лимитов остановлен");
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Ошибка при остановке сервиса мониторинга лимитов", e);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при остановке сервиса: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.status(500).body(response);
        }
    }
    
    /**
     * Переподключить сервис мониторинга лимитов
     * 
     * @return результат переподключения сервиса
     */
    @PostMapping("/reconnect")
    public ResponseEntity<Map<String, Object>> reconnectLimitMonitoring() {
        try {
            orchestrator.reconnectService("LimitMonitoringStreamingService").join();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Сервис мониторинга лимитов переподключен");
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Ошибка при переподключении сервиса мониторинга лимитов", e);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при переподключении сервиса: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.status(500).body(response);
        }
    }
    
    /**
     * Получить статус сервиса мониторинга лимитов
     * 
     * @return статус сервиса
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getStatus() {
        try {
            Map<String, MarketDataStreamingOrchestrator.ServiceStatus> allStatuses = orchestrator.getAllServiceStatuses();
            MarketDataStreamingOrchestrator.ServiceStatus serviceStatus = allStatuses.get("LimitMonitoringStreamingService");
            
            Map<String, Object> status = new HashMap<>();
            if (serviceStatus != null) {
                status.put("isRunning", serviceStatus.isRunning());
                status.put("isConnected", serviceStatus.isConnected());
                status.put("totalReceived", serviceStatus.getTotalReceived());
                status.put("totalProcessed", serviceStatus.getTotalProcessed());
                status.put("totalErrors", serviceStatus.getTotalErrors());
            } else {
                status.put("isRunning", false);
                status.put("isConnected", false);
                status.put("totalReceived", 0);
                status.put("totalProcessed", 0);
                status.put("totalErrors", 0);
            }
            status.put("serviceName", "LimitMonitoringStreamingService");
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", status);
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Ошибка при получении статуса сервиса мониторинга лимитов", e);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении статуса: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.status(500).body(response);
        }
    }
    
    /**
     * Очистить кэш уведомлений за предыдущие дни
     * 
     * @return результат очистки кэша
     */
    @PostMapping("/clear-cache")
    public ResponseEntity<Map<String, Object>> clearNotificationCache() {
        try {
            limitMonitorService.clearDailyNotifications();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Кэш уведомлений очищен");
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Ошибка при очистке кэша уведомлений", e);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при очистке кэша: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.status(500).body(response);
        }
    }
}
