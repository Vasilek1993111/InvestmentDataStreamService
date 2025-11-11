package com.example.investmentdatastreamservice.controller;

import com.example.investmentdatastreamservice.dto.ThresholdUpdateRequest;
import com.example.investmentdatastreamservice.dto.ThresholdsUpdateRequest;
import com.example.investmentdatastreamservice.service.LimitMonitorService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

/**
 * REST контроллер для управления настройками мониторинга лимитов
 * 
 * <p>
 * Предоставляет API для получения и изменения порогов приближения к лимитам:
 * <ul>
 * <li>Порог приближения к биржевым лимитам</li>
 * <li>Порог приближения к историческим экстремумам</li>
 * </ul>
 * </p>
 * 
 * @author InvestmentDataStreamService
 * @version 1.0
 */
@RestController
@RequestMapping("/api/limit-monitor")
public class LimitMonitorController {

    private final LimitMonitorService limitMonitorService;

    public LimitMonitorController(LimitMonitorService limitMonitorService) {
        this.limitMonitorService = limitMonitorService;
    }

    /**
     * Получить текущие пороги мониторинга
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET /api/limit-monitor/thresholds
     * </pre>
     * 
     * @return текущие значения порогов
     */
    @GetMapping("/thresholds")
    public ResponseEntity<Map<String, Object>> getThresholds() {
        try {
            BigDecimal approachThreshold = limitMonitorService.getApproachThreshold();
            BigDecimal historicalThreshold = limitMonitorService.getHistoricalApproachThreshold();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("approachThreshold", approachThreshold);
            response.put("historicalApproachThreshold", historicalThreshold);
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении порогов: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Обновить порог приближения к биржевым лимитам
     * 
     * <p>
     * Автоматически синхронизирует внутренние значения порогов при обновлении.
     * Дополнительная синхронизация не требуется.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * POST /api/limit-monitor/thresholds/approach
     * Content-Type: application/json
     * 
     * {
     *   "threshold": 2.0
     * }
     * </pre>
     * 
     * @param request объект с новым значением порога
     * @return результат обновления
     */
    @PostMapping("/thresholds/approach")
    public ResponseEntity<Map<String, Object>> updateApproachThreshold(@RequestBody ThresholdUpdateRequest request) {
        try {
            if (request.getThreshold() == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", "Параметр 'threshold' обязателен");
                response.put("timestamp", java.time.LocalDateTime.now().toString());
                return ResponseEntity.badRequest().body(response);
            }
            
            // Обновление автоматически синхронизирует внутренние значения
            limitMonitorService.updateApproachThreshold(request.getThreshold());
            
            BigDecimal currentThreshold = limitMonitorService.getApproachThreshold();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Порог приближения к биржевым лимитам успешно обновлен и синхронизирован");
            response.put("threshold", currentThreshold);
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при обновлении порога: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Обновить порог приближения к историческим экстремумам
     * 
     * <p>
     * Автоматически синхронизирует внутренние значения порогов при обновлении.
     * Дополнительная синхронизация не требуется.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * POST /api/limit-monitor/thresholds/historical
     * Content-Type: application/json
     * 
     * {
     *   "threshold": 1.5
     * }
     * </pre>
     * 
     * @param request объект с новым значением порога
     * @return результат обновления
     */
    @PostMapping("/thresholds/historical")
    public ResponseEntity<Map<String, Object>> updateHistoricalThreshold(@RequestBody ThresholdUpdateRequest request) {
        try {
            if (request.getThreshold() == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", "Параметр 'threshold' обязателен");
                response.put("timestamp", java.time.LocalDateTime.now().toString());
                return ResponseEntity.badRequest().body(response);
            }
            
            // Обновление автоматически синхронизирует внутренние значения
            limitMonitorService.updateHistoricalApproachThreshold(request.getThreshold());
            
            BigDecimal currentThreshold = limitMonitorService.getHistoricalApproachThreshold();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Порог приближения к историческим экстремумам успешно обновлен и синхронизирован");
            response.put("threshold", currentThreshold);
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при обновлении порога: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Обновить оба порога одновременно
     * 
     * <p>
     * Автоматически синхронизирует внутренние значения порогов при обновлении.
     * Дополнительная синхронизация не требуется.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * POST /api/limit-monitor/thresholds
     * Content-Type: application/json
     * 
     * {
     *   "approachThreshold": 2.0,
     *   "historicalApproachThreshold": 1.5
     * }
     * </pre>
     * 
     * @param request объект с новыми значениями порогов
     * @return результат обновления
     */
    @PostMapping("/thresholds")
    public ResponseEntity<Map<String, Object>> updateThresholds(@RequestBody ThresholdsUpdateRequest request) {
        try {
            Map<String, Object> response = new HashMap<>();
            Map<String, Object> updated = new HashMap<>();
            
            if (request.getApproachThreshold() != null) {
                // Обновление автоматически синхронизирует внутренние значения
                limitMonitorService.updateApproachThreshold(request.getApproachThreshold());
                updated.put("approachThreshold", limitMonitorService.getApproachThreshold());
            }
            
            if (request.getHistoricalApproachThreshold() != null) {
                // Обновление автоматически синхронизирует внутренние значения
                limitMonitorService.updateHistoricalApproachThreshold(request.getHistoricalApproachThreshold());
                updated.put("historicalApproachThreshold", limitMonitorService.getHistoricalApproachThreshold());
            }
            
            if (updated.isEmpty()) {
                response.put("success", false);
                response.put("error", "Необходимо указать хотя бы один порог для обновления");
                response.put("timestamp", java.time.LocalDateTime.now().toString());
                return ResponseEntity.badRequest().body(response);
            }
            
            response.put("success", true);
            response.put("message", "Пороги успешно обновлены и синхронизированы");
            response.put("updated", updated);
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.badRequest().body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при обновлении порогов: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получить статистику мониторинга лимитов
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET /api/limit-monitor/statistics
     * </pre>
     * 
     * @return статистика мониторинга
     */
    @GetMapping("/statistics")
    public ResponseEntity<Map<String, Object>> getStatistics() {
        try {
            Map<String, Object> statistics = limitMonitorService.getStatistics();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("data", statistics);
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении статистики: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }
}

