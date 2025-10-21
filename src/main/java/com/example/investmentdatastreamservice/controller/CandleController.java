package com.example.investmentdatastreamservice.controller;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.example.investmentdatastreamservice.service.CandleStreamingService;
import com.example.investmentdatastreamservice.service.CandleStreamingService.CandleStreamingStats;

/**
 * REST контроллер для работы с минутными свечами
 * 
 * <p>
 * Предоставляет API для получения и анализа минутных свечей:
 * </p>
 * <ul>
 * <li>Получение свечей по FIGI и периоду</li>
 * <li>Получение последних свечей</li>
 * <li>Фильтрация по типу свечи (BULLISH/BEARISH/DOJI)</li>
 * <li>Фильтрация по объему и изменению цены</li>
 * <li>Статистика по свечам</li>
 * </ul>
 * 
 * @author InvestmentDataStreamService
 * @version 1.0
 * @since 2024
 */
@RestController
@RequestMapping("/api/candles")
public class CandleController {

    private final CandleStreamingService candleStreamingService;

    public CandleController(CandleStreamingService candleStreamingService) {
        this.candleStreamingService = candleStreamingService;
    }



    /**
     * Запустить подписку на минутные свечи
     * 
     * <p>
     * Подписывается на получение минутных свечей в реальном времени для всех акций и фьючерсов из
     * кэша.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * POST / api / candles / subscription / start
     * </pre>
     * 
     * <p>
     * <strong>Пример ответа:</strong>
     * </p>
     * 
     * <pre>
     * {
     *   "success": true,
     *   "message": "Подписка на свечи успешно запущена",
     *   "timestamp": "2024-10-21T12:30:00"
     * }
     * </pre>
     * 
     * @return результат запуска подписки
     */
    @PostMapping("/subscription/start")
    public ResponseEntity<Map<String, Object>> startCandleSubscription() {
        try {
            candleStreamingService.startCandleSubscription();

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Подписка на свечи успешно запущена");
            response.put("timestamp", LocalDateTime.now().toString());

            return ResponseEntity.ok(response);
        } catch (IllegalStateException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            response.put("timestamp", LocalDateTime.now().toString());
            return ResponseEntity.status(400).body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при запуске подписки на свечи: " + e.getMessage());
            response.put("timestamp", LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Остановить подписку на минутные свечи
     * 
     * <p>
     * Останавливает получение минутных свечей в реальном времени.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * POST / api / candles / subscription / stop
     * </pre>
     * 
     * <p>
     * <strong>Пример ответа:</strong>
     * </p>
     * 
     * <pre>
     * {
     *   "success": true,
     *   "message": "Подписка на свечи успешно остановлена",
     *   "timestamp": "2024-10-21T12:30:00"
     * }
     * </pre>
     * 
     * @return результат остановки подписки
     */
    @PostMapping("/subscription/stop")
    public ResponseEntity<Map<String, Object>> stopCandleSubscription() {
        try {
            candleStreamingService.stopCandleSubscription();

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Подписка на свечи успешно остановлена");
            response.put("timestamp", LocalDateTime.now().toString());

            return ResponseEntity.ok(response);
        } catch (IllegalStateException e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            response.put("timestamp", LocalDateTime.now().toString());
            return ResponseEntity.status(400).body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при остановке подписки на свечи: " + e.getMessage());
            response.put("timestamp", LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получить статистику подписки на свечи
     * 
     * <p>
     * Возвращает информацию о текущем состоянии подписки на свечи:
     * </p>
     * <ul>
     * <li>Статус подписки (активна/неактивна)</li>
     * <li>Статус подключения к API</li>
     * <li>Количество полученных свечей</li>
     * <li>Количество сохраненных свечей</li>
     * <li>Количество ошибок</li>
     * <li>Утилизация потоков вставки</li>
     * </ul>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET / api / candles / subscription / stats
     * </pre>
     * 
     * @return статистика подписки
     */
    @GetMapping("/subscription/stats")
    public ResponseEntity<Map<String, Object>> getCandleSubscriptionStats() {
        try {
            CandleStreamingStats stats = candleStreamingService.getStats();

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("isRunning", stats.isRunning());
            response.put("isConnected", stats.isConnected());
            response.put("totalReceived", stats.getTotalReceived());
            response.put("totalProcessed", stats.getTotalProcessed());
            response.put("actualCandleCount", stats.getActualCandleCount());
            response.put("totalErrors", stats.getTotalErrors());
            response.put("pendingOperations", stats.getPendingOperations());
            response.put("availableInserts", stats.getAvailableInserts());
            response.put("maxConcurrentInserts", stats.getMaxConcurrentInserts());
            response.put("insertUtilization", stats.getInsertUtilization());
            response.put("errorRate", stats.getErrorRate());
            response.put("timestamp", LocalDateTime.now().toString());

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении статистики: " + e.getMessage());
            response.put("timestamp", LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получить статус подписки на свечи
     * 
     * <p>
     * Быстрая проверка статуса подписки.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET / api / candles / subscription / status
     * </pre>
     * 
     * @return статус подписки
     */
    @GetMapping("/subscription/status")
    public ResponseEntity<Map<String, Object>> getCandleSubscriptionStatus() {
        try {
            CandleStreamingStats stats = candleStreamingService.getStats();

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("isRunning", stats.isRunning());
            response.put("isConnected", stats.isConnected());
            response.put("timestamp", LocalDateTime.now().toString());

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении статуса: " + e.getMessage());
            response.put("timestamp", LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }
}

