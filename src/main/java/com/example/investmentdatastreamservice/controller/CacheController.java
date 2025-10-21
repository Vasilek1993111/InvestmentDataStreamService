package com.example.investmentdatastreamservice.controller;

import com.example.investmentdatastreamservice.service.CacheWarmupService;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;

/**
 * Контроллер для управления кэшем инструментов
 * 
 * <p>
 * Предоставляет REST API для управления кэшем финансовых инструментов:
 * </p>
 * <ul>
 * <li><strong>Прогрев кэша</strong> - загрузка инструментов в кэш</li>
 * <li><strong>Просмотр кэша</strong> - получение информации о содержимом кэша</li>
 * <li><strong>Очистка кэша</strong> - удаление данных из кэша</li>
 * <li><strong>Статистика кэша</strong> - получение метрик кэша</li>
 * </ul>
 * 
 * <p>
 * Поддерживает работу с тремя типами кэшей:
 * </p>
 * <ul>
 * <li>sharesCache - кэш акций</li>
 * <li>futuresCache - кэш фьючерсов</li>
 * <li>indicativesCache - кэш индикативных инструментов</li>
 * </ul>
 * 
 * @author InvestmentDataStreamService
 * @version 1.0
 * @since 2024
 */
@RestController
@RequestMapping("/api/cache")
public class CacheController {

    private final CacheWarmupService cacheWarmupService;
    private final CacheManager cacheManager;

    public CacheController(CacheWarmupService cacheWarmupService, CacheManager cacheManager) {
        this.cacheWarmupService = cacheWarmupService;
        this.cacheManager = cacheManager;
    }

    /**
     * Прогрев кэша инструментов
     * 
     * <p>
     * Принудительно загружает все основные инструменты в кэш:
     * </p>
     * <ul>
     * <li>Все акции</li>
     * <li>Все фьючерсы</li>
     * <li>Все индикативные инструменты</li>
     * </ul>
     * 
     * <p>
     * Полезно для:
     * </p>
     * <ul>
     * <li>Принудительного обновления кэша без перезапуска приложения</li>
     * <li>Тестирования производительности</li>
     * <li>Восстановления кэша после очистки</li>
     * </ul>
     * 
     * <p>
     * <strong>Примеры использования:</strong>
     * </p>
     * 
     * <pre>
     * POST / api / cache / warmup
     * </pre>
     * 
     * <p>
     * <strong>Пример ответа:</strong>
     * </p>
     * 
     * <pre>
     * {
     *   "success": true,
     *   "message": "Кэш успешно прогрет",
     *   "timestamp": "2024-10-21T10:30:00"
     * }
     * </pre>
     * 
     * @return результат операции прогрева кэша
     */
    @PostMapping("/warmup")
    public ResponseEntity<Map<String, Object>> warmupCache() {
        try {
            cacheWarmupService.manualWarmupCache();

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Кэш успешно прогрет");
            response.put("timestamp", LocalDateTime.now().toString());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Ошибка при прогреве кэша: " + e.getMessage());
            response.put("timestamp", LocalDateTime.now().toString());

            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Просмотр содержимого кэша
     * 
     * <p>
     * Возвращает информацию о содержимом всех кэшей или конкретного кэша.
     * </p>
     * 
     * <p>
     * Параметры запроса:
     * </p>
     * <ul>
     * <li>cacheName (опционально) - имя конкретного кэша для просмотра</li>
     * <li>limit (опционально) - максимальное количество записей для отображения (по умолчанию
     * 100)</li>
     * </ul>
     * 
     * <p>
     * <strong>Примеры использования:</strong>
     * </p>
     * 
     * <pre>
     * GET /api/cache/content                          - все кэши
     * GET /api/cache/content?cacheName=sharesCache    - только кэш акций
     * GET /api/cache/content?limit=50                 - все кэши, до 50 записей каждый
     * </pre>
     * 
     * @param cacheName имя кэша для просмотра (опционально)
     * @param limit максимальное количество записей (опционально, по умолчанию 100)
     * @return информация о содержимом кэша
     */
    @GetMapping("/content")
    public ResponseEntity<Map<String, Object>> getCacheContent(
            @RequestParam(required = false) String cacheName,
            @RequestParam(defaultValue = "100") int limit) {

        try {
            Map<String, Object> response = new HashMap<>();
            response.put("timestamp", LocalDateTime.now().toString());

            if (cacheName != null && !cacheName.isEmpty()) {
                // Просмотр конкретного кэша
                Cache cache = cacheManager.getCache(cacheName);
                if (cache == null) {
                    response.put("error", "Кэш '" + cacheName + "' не найден");
                    return ResponseEntity.badRequest().body(response);
                }

                Map<String, Object> cacheInfo = getCacheInfo(cache, limit);
                response.put("cacheName", cacheName);
                response.putAll(cacheInfo);

            } else {
                // Просмотр всех кэшей
                Map<String, Object> allCaches = new HashMap<>();
                String[] cacheNames = {"sharesCache", "futuresCache", "indicativesCache"};

                for (String name : cacheNames) {
                    Cache cache = cacheManager.getCache(name);
                    if (cache != null) {
                        Map<String, Object> cacheInfo = getCacheInfo(cache, limit);
                        allCaches.put(name, cacheInfo);
                    }
                }

                response.put("caches", allCaches);
            }

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Ошибка при получении содержимого кэша: " + e.getMessage());
            response.put("timestamp", LocalDateTime.now().toString());

            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Статистика кэша
     * 
     * <p>
     * Возвращает общую статистику по всем кэшам:
     * </p>
     * <ul>
     * <li>Количество кэшей</li>
     * <li>Общее количество записей во всех кэшах</li>
     * <li>Статистика по каждому кэшу</li>
     * <li>Информация о производительности (hits, misses, evictions)</li>
     * </ul>
     * 
     * <p>
     * <strong>Пример использования:</strong>
     * </p>
     * 
     * <pre>
     * GET / api / cache / stats
     * </pre>
     * 
     * <p>
     * <strong>Пример ответа:</strong>
     * </p>
     * 
     * <pre>
     * {
     *   "timestamp": "2024-10-21T10:30:00",
     *   "totalCaches": 3,
     *   "activeCaches": 3,
     *   "totalEntries": 1500,
     *   "cacheDetails": {
     *     "sharesCache": {
     *       "entryCount": 1000,
     *       "hitRate": 0.95
     *     },
     *     ...
     *   }
     * }
     * </pre>
     * 
     * @return статистика кэша
     */
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getCacheStats() {
        try {
            Map<String, Object> stats = new HashMap<>();
            stats.put("timestamp", LocalDateTime.now().toString());

            String[] cacheNames = {"sharesCache", "futuresCache", "indicativesCache"};
            Map<String, Object> cacheStats = new HashMap<>();
            int totalEntries = 0;
            int activeCaches = 0;

            for (String cacheName : cacheNames) {
                Cache cache = cacheManager.getCache(cacheName);
                if (cache != null) {
                    activeCaches++;
                    Map<String, Object> cacheInfo = getCacheInfo(cache, Integer.MAX_VALUE);
                    cacheStats.put(cacheName, cacheInfo);
                    totalEntries += (Integer) cacheInfo.getOrDefault("entryCount", 0);
                }
            }

            stats.put("totalCaches", cacheNames.length);
            stats.put("activeCaches", activeCaches);
            stats.put("totalEntries", totalEntries);
            stats.put("cacheDetails", cacheStats);

            return ResponseEntity.ok(stats);

        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Ошибка при получении статистики кэша: " + e.getMessage());
            response.put("timestamp", LocalDateTime.now().toString());

            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Очистка кэша
     * 
     * <p>
     * Очищает содержимое кэша. Можно очистить конкретный кэш или все кэши.
     * </p>
     * 
     * <p>
     * <strong>Примеры использования:</strong>
     * </p>
     * 
     * <pre>
     * DELETE /api/cache/clear                          - очистить все кэши
     * DELETE /api/cache/clear?cacheName=sharesCache    - очистить только кэш акций
     * </pre>
     * 
     * @param cacheName имя кэша для очистки (опционально, если не указано - очищаются все кэши)
     * @return результат операции очистки
     */
    @DeleteMapping("/clear")
    public ResponseEntity<Map<String, Object>> clearCache(
            @RequestParam(required = false) String cacheName) {

        try {
            Map<String, Object> response = new HashMap<>();
            response.put("timestamp", LocalDateTime.now().toString());

            if (cacheName != null && !cacheName.isEmpty()) {
                // Очистка конкретного кэша
                Cache cache = cacheManager.getCache(cacheName);
                if (cache == null) {
                    response.put("error", "Кэш '" + cacheName + "' не найден");
                    return ResponseEntity.badRequest().body(response);
                }

                cache.clear();
                response.put("success", true);
                response.put("message", "Кэш '" + cacheName + "' успешно очищен");
                response.put("clearedCache", cacheName);

            } else {
                // Очистка всех кэшей
                String[] cacheNames = {"sharesCache", "futuresCache", "indicativesCache"};
                List<String> clearedCaches = new ArrayList<>();

                for (String name : cacheNames) {
                    Cache cache = cacheManager.getCache(name);
                    if (cache != null) {
                        cache.clear();
                        clearedCaches.add(name);
                    }
                }

                response.put("success", true);
                response.put("message", "Все кэши успешно очищены");
                response.put("clearedCaches", clearedCaches);
            }

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при очистке кэша: " + e.getMessage());
            response.put("timestamp", LocalDateTime.now().toString());

            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получение информации о конкретном кэше
     * 
     * <p>
     * Анализирует содержимое кэша и возвращает статистику:
     * </p>
     * <ul>
     * <li>Имя кэша</li>
     * <li>Тип используемой реализации кэша</li>
     * <li>Количество записей</li>
     * <li>Примеры записей (ограничено параметром limit)</li>
     * <li>Статистика использования (hits, misses, evictions)</li>
     * </ul>
     * 
     * @param cache кэш для анализа
     * @param limit максимальное количество записей для отображения
     * @return информация о кэше
     */
    private Map<String, Object> getCacheInfo(Cache cache, int limit) {
        Map<String, Object> info = new HashMap<>();

        try {
            // Получаем информацию о кэше
            info.put("name", cache.getName());
            info.put("nativeCache", cache.getNativeCache().getClass().getSimpleName());

            // Подсчитываем записи (это может быть медленно для больших кэшей)
            int entryCount = 0;
            List<Map<String, Object>> sampleEntries = new ArrayList<>();

            if (cache.getNativeCache() instanceof com.github.benmanes.caffeine.cache.Cache) {
                com.github.benmanes.caffeine.cache.Cache<?, ?> caffeineCache =
                        (com.github.benmanes.caffeine.cache.Cache<?, ?>) cache.getNativeCache();

                entryCount = (int) caffeineCache.estimatedSize();

                // Получаем статистику производительности
                com.github.benmanes.caffeine.cache.stats.CacheStats cacheStats =
                        caffeineCache.stats();
                Map<String, Object> statsMap = new HashMap<>();
                statsMap.put("hitCount", cacheStats.hitCount());
                statsMap.put("missCount", cacheStats.missCount());
                statsMap.put("hitRate", cacheStats.hitRate());
                statsMap.put("evictionCount", cacheStats.evictionCount());
                statsMap.put("loadSuccessCount", cacheStats.loadSuccessCount());
                statsMap.put("loadFailureCount", cacheStats.loadFailureCount());
                info.put("statistics", statsMap);

                // Получаем образцы записей
                int count = 0;
                for (Map.Entry<?, ?> entry : caffeineCache.asMap().entrySet()) {
                    if (count >= limit)
                        break;

                    Map<String, Object> entryInfo = new HashMap<>();
                    entryInfo.put("key", entry.getKey().toString());
                    entryInfo.put("valueType", entry.getValue().getClass().getSimpleName());

                    // Для списков показываем размер
                    if (entry.getValue() instanceof List) {
                        entryInfo.put("valueSize", ((List<?>) entry.getValue()).size());
                    }

                    sampleEntries.add(entryInfo);
                    count++;
                }
            }

            info.put("entryCount", entryCount);
            info.put("sampleEntries", sampleEntries);
            info.put("sampleLimit", Math.min(limit, entryCount));

        } catch (Exception e) {
            info.put("error", "Ошибка при получении информации о кэше: " + e.getMessage());
        }

        return info;
    }
}

