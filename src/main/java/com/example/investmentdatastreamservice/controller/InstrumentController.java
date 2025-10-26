package com.example.investmentdatastreamservice.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import com.example.investmentdatastreamservice.dto.FutureDto;
import com.example.investmentdatastreamservice.dto.IndicativeDto;
import com.example.investmentdatastreamservice.dto.LimitsDto;
import com.example.investmentdatastreamservice.dto.ShareDto;
import com.example.investmentdatastreamservice.entity.FutureEntity;
import com.example.investmentdatastreamservice.entity.IndicativeEntity;
import com.example.investmentdatastreamservice.entity.ShareEntity;
import com.example.investmentdatastreamservice.mapper.FutureMapper;
import com.example.investmentdatastreamservice.mapper.IndicativeMapper;
import com.example.investmentdatastreamservice.mapper.ShareMapper;
import com.example.investmentdatastreamservice.service.CacheWarmupService;
import com.example.investmentdatastreamservice.service.LimitsService;

/**
 * REST контроллер для работы с финансовыми инструментами
 * 
 * <p>
 * Предоставляет API для получения информации об инструментах из кэша:
 * </p>
 * <ul>
 * <li>Акции (Shares)</li>
 * <li>Фьючерсы (Futures)</li>
 * <li>Индикативные инструменты (Indicatives)</li>
 * </ul>
 * 
 * <p>
 * Все данные берутся из кэша, что обеспечивает высокую скорость ответа.
 * </p>
 * 
 * @author InvestmentDataStreamService
 * @version 1.0
 * @since 2024
 */
@RestController
@RequestMapping("/api/instruments")
public class InstrumentController {

    private final CacheWarmupService cacheWarmupService;
    private final ShareMapper shareMapper;
    private final FutureMapper futureMapper;
    private final IndicativeMapper indicativeMapper;
    private final LimitsService limitsService;

    public InstrumentController(CacheWarmupService cacheWarmupService, ShareMapper shareMapper, 
                               FutureMapper futureMapper, IndicativeMapper indicativeMapper,
                               LimitsService limitsService) {
        this.cacheWarmupService = cacheWarmupService;
        this.shareMapper = shareMapper;
        this.futureMapper = futureMapper;
        this.indicativeMapper = indicativeMapper;
        this.limitsService = limitsService;
    }

    /**
     * Получить все акции
     * 
     * <p>
     * Возвращает полный список всех акций из кэша.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET / api / instruments / shares
     * </pre>
     * 
     * @return список всех акций
     */
    @GetMapping("/shares")
    public ResponseEntity<Map<String, Object>> getAllShares() {
        try {
            List<ShareEntity> shares = cacheWarmupService.getAllShares();
            List<ShareDto> shareDtos = shareMapper.toDtoList(shares);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("count", shareDtos.size());
            response.put("data", shareDtos);
            response.put("timestamp", java.time.LocalDateTime.now().toString());

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении акций: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получить акцию по FIGI
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET / api / instruments / shares / BBG004730N88
     * </pre>
     * 
     * @param figi FIGI акции
     * @return акция или 404 Not Found
     */
    @GetMapping("/shares/{figi}")
    public ResponseEntity<Map<String, Object>> getShareByFigi(@PathVariable String figi) {
        try {
            Optional<ShareEntity> share = cacheWarmupService.getAllShares().stream()
                    .filter(s -> s.getFigi().equals(figi)).findFirst();

            if (share.isPresent()) {
                ShareDto shareDto = shareMapper.toDto(share.get());
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("data", shareDto);
                response.put("timestamp", java.time.LocalDateTime.now().toString());
                return ResponseEntity.ok(response);
            } else {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", "Акция с FIGI '" + figi + "' не найдена");
                response.put("timestamp", java.time.LocalDateTime.now().toString());
                return ResponseEntity.status(404).body(response);
            }
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении акции: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получить все фьючерсы
     * 
     * <p>
     * Возвращает полный список всех фьючерсов из кэша.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET / api / instruments / futures
     * </pre>
     * 
     * @return список всех фьючерсов
     */
    @GetMapping("/futures")
    public ResponseEntity<Map<String, Object>> getAllFutures() {
        try {
            List<FutureEntity> futures = cacheWarmupService.getAllFutures();
            List<FutureDto> futureDtos = futureMapper.toDtoList(futures);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("count", futureDtos.size());
            response.put("data", futureDtos);
            response.put("timestamp", java.time.LocalDateTime.now().toString());

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении фьючерсов: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получить фьючерс по FIGI
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET / api / instruments / futures / FUTSI123456
     * </pre>
     * 
     * @param figi FIGI фьючерса
     * @return фьючерс или 404 Not Found
     */
    @GetMapping("/futures/{figi}")
    public ResponseEntity<Map<String, Object>> getFutureByFigi(@PathVariable String figi) {
        try {
            Optional<FutureEntity> future = cacheWarmupService.getAllFutures().stream()
                    .filter(f -> f.getFigi().equals(figi)).findFirst();

            if (future.isPresent()) {
                FutureDto futureDto = futureMapper.toDto(future.get());
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("data", futureDto);
                response.put("timestamp", java.time.LocalDateTime.now().toString());
                return ResponseEntity.ok(response);
            } else {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", "Фьючерс с FIGI '" + figi + "' не найден");
                response.put("timestamp", java.time.LocalDateTime.now().toString());
                return ResponseEntity.status(404).body(response);
            }
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении фьючерса: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получить все индикативные инструменты
     * 
     * <p>
     * Возвращает полный список всех индикативных инструментов из кэша.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET / api / instruments / indicatives
     * </pre>
     * 
     * @return список всех индикативных инструментов
     */
    @GetMapping("/indicatives")
    public ResponseEntity<Map<String, Object>> getAllIndicatives() {
        try {
            List<IndicativeEntity> indicatives = cacheWarmupService.getAllIndicatives();
            List<IndicativeDto> indicativeDtos = indicativeMapper.toDtoList(indicatives);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("count", indicativeDtos.size());
            response.put("data", indicativeDtos);
            response.put("timestamp", java.time.LocalDateTime.now().toString());

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error",
                    "Ошибка при получении индикативных инструментов: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получить индикативный инструмент по FIGI
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET / api / instruments / indicatives / IND123456
     * </pre>
     * 
     * @param figi FIGI индикативного инструмента
     * @return индикативный инструмент или 404 Not Found
     */
    @GetMapping("/indicatives/{figi}")
    public ResponseEntity<Map<String, Object>> getIndicativeByFigi(@PathVariable String figi) {
        try {
            Optional<IndicativeEntity> indicative = cacheWarmupService.getAllIndicatives().stream()
                    .filter(i -> i.getFigi().equals(figi)).findFirst();

            if (indicative.isPresent()) {
                IndicativeDto indicativeDto = indicativeMapper.toDto(indicative.get());
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("data", indicativeDto);
                response.put("timestamp", java.time.LocalDateTime.now().toString());
                return ResponseEntity.ok(response);
            } else {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", "Индикативный инструмент с FIGI '" + figi + "' не найден");
                response.put("timestamp", java.time.LocalDateTime.now().toString());
                return ResponseEntity.status(404).body(response);
            }
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error",
                    "Ошибка при получении индикативного инструмента: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Поиск инструментов
     * 
     * <p>
     * Поиск по тикеру или названию инструмента.
     * </p>
     * 
     * <p>
     * <strong>Примеры запросов:</strong>
     * </p>
     * 
     * <pre>
     * GET / api / instruments / search?q = SBER GET / api / instruments / search?q = Сбербанк GET
     * / api / instruments / search?q = Si
     * </pre>
     * 
     * @param query поисковый запрос
     * @return найденные инструменты
     */
    @GetMapping("/search")
    public ResponseEntity<Map<String, Object>> searchInstruments(@RequestParam String q) {
        try {
            String query = q.toLowerCase();

            List<ShareEntity> shares =
                    cacheWarmupService.getAllShares().stream()
                            .filter(s -> s.getTicker().toLowerCase().contains(query)
                                    || s.getName().toLowerCase().contains(query))
                            .limit(20).toList();

            List<FutureEntity> futures = cacheWarmupService.getAllFutures().stream()
                    .filter(f -> f.getTicker().toLowerCase().contains(query)).limit(20).toList();

            List<IndicativeEntity> indicatives =
                    cacheWarmupService.getAllIndicatives().stream()
                            .filter(i -> i.getTicker() != null
                                    && i.getTicker().toLowerCase().contains(query))
                            .limit(20).toList();

            // Конвертируем в DTO
            List<ShareDto> shareDtos = shareMapper.toDtoList(shares);
            List<FutureDto> futureDtos = futureMapper.toDtoList(futures);
            List<IndicativeDto> indicativeDtos = indicativeMapper.toDtoList(indicatives);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("query", q);
            response.put("results",
                    Map.of("shares", shareDtos, "futures", futureDtos, "indicatives", indicativeDtos));
            response.put("totalCount", shareDtos.size() + futureDtos.size() + indicativeDtos.size());
            response.put("timestamp", java.time.LocalDateTime.now().toString());

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при поиске инструментов: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получить статистику по инструментам
     * 
     * <p>
     * Возвращает количество инструментов каждого типа.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET / api / instruments / summary
     * </pre>
     * 
     * @return статистика по инструментам
     */
    @GetMapping("/summary")
    public ResponseEntity<Map<String, Object>> getInstrumentsSummary() {
        try {
            int sharesCount = cacheWarmupService.getAllShares().size();
            int futuresCount = cacheWarmupService.getAllFutures().size();
            int indicativesCount = cacheWarmupService.getAllIndicatives().size();

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("shares", sharesCount);
            response.put("futures", futuresCount);
            response.put("indicatives", indicativesCount);
            response.put("total", sharesCount + futuresCount + indicativesCount);
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

    /**
     * Получить лимиты для инструмента по FIGI из кэша
     * 
     * <p>
     * Возвращает лимиты (верхний и нижний) для указанного инструмента из кэша.
     * Данные берутся из кэша, который был прогрет при запуске приложения.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET /api/instruments/limits/BBG004730N88
     * </pre>
     * 
     * @param figi FIGI инструмента
     * @return лимиты инструмента из кэша
     */
    @GetMapping("/limits/{figi}")
    public ResponseEntity<Map<String, Object>> getLimitsByFigi(@PathVariable String figi) {
        try {
            // Получаем лимиты ТОЛЬКО из кэша (без запроса к API)
            LimitsDto limits = limitsService.getLimitsFromCache(figi);
            
            Map<String, Object> response = new HashMap<>();
            if (limits != null) {
                response.put("success", true);
                response.put("figi", figi);
                response.put("data", limits);
                response.put("fromCache", true);
            } else {
                response.put("success", false);
                response.put("error", "Лимиты для инструмента '" + figi + "' не найдены в кэше");
                response.put("figi", figi);
            }
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении лимитов для инструмента '" + figi + "': " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получить лимиты для всех акций из кэша
     * 
     * <p>
     * Возвращает лимиты для всех акций из кэша. Данные берутся из кэша,
     * который был прогрет при запуске приложения.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET /api/instruments/limits/shares
     * </pre>
     * 
     * @return лимиты для всех акций из кэша
     */
    @GetMapping("/limits/shares")
    public ResponseEntity<Map<String, Object>> getSharesLimits() {
        try {
            // Получаем акции из кэша и конвертируем в DTO
            List<ShareEntity> shares = cacheWarmupService.getAllShares();
            List<ShareDto> shareDtos = shareMapper.toDtoList(shares);
            
            List<Map<String, Object>> limitsList = new java.util.ArrayList<>();
            
            for (ShareDto share : shareDtos) {
                if (share.getFigi() != null && !share.getFigi().trim().isEmpty()) {
                    // Получаем лимиты ТОЛЬКО из кэша (без запроса к API)
                    LimitsDto limits = limitsService.getLimitsFromCache(share.getFigi());
                    if (limits != null) {
                        Map<String, Object> limitData = new HashMap<>();
                        limitData.put("figi", share.getFigi());
                        limitData.put("ticker", share.getTicker());
                        limitData.put("name", share.getName());
                        limitData.put("limitDown", limits.getLimitDown());
                        limitData.put("limitUp", limits.getLimitUp());
                        limitsList.add(limitData);
                    }
                }
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("count", limitsList.size());
            response.put("data", limitsList);
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении лимитов акций: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получить лимиты для всех фьючерсов из кэша
     * 
     * <p>
     * Возвращает лимиты для всех фьючерсов из кэша. Данные берутся из кэша,
     * который был прогрет при запуске приложения.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET /api/instruments/limits/futures
     * </pre>
     * 
     * @return лимиты для всех фьючерсов из кэша
     */
    @GetMapping("/limits/futures")
    public ResponseEntity<Map<String, Object>> getFuturesLimits() {
        try {
            // Получаем фьючерсы из кэша и конвертируем в DTO
            List<FutureEntity> futures = cacheWarmupService.getAllFutures();
            List<FutureDto> futureDtos = futureMapper.toDtoList(futures);
            
            List<Map<String, Object>> limitsList = new java.util.ArrayList<>();
            
            for (FutureDto future : futureDtos) {
                if (future.getFigi() != null && !future.getFigi().trim().isEmpty()) {
                    // Получаем лимиты ТОЛЬКО из кэша (без запроса к API)
                    LimitsDto limits = limitsService.getLimitsFromCache(future.getFigi());
                    if (limits != null) {
                        Map<String, Object> limitData = new HashMap<>();
                        limitData.put("figi", future.getFigi());
                        limitData.put("ticker", future.getTicker());
                        limitData.put("basicAsset", future.getBasicAsset());
                        limitData.put("limitDown", limits.getLimitDown());
                        limitData.put("limitUp", limits.getLimitUp());
                        limitsList.add(limitData);
                    }
                }
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("count", limitsList.size());
            response.put("data", limitsList);
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении лимитов фьючерсов: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получить статистику по лимитам из кэша
     * 
     * <p>
     * Возвращает статистику по количеству инструментов с лимитами.
     * Данные берутся из кэша, который был прогрет при запуске приложения.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET /api/instruments/limits/summary
     * </pre>
     * 
     * @return статистика по лимитам из кэша
     */
    @GetMapping("/limits/summary")
    public ResponseEntity<Map<String, Object>> getLimitsSummary() {
        try {
            // Получаем данные из кэша и конвертируем в DTO
            List<ShareEntity> shares = cacheWarmupService.getAllShares();
            List<FutureEntity> futures = cacheWarmupService.getAllFutures();
            List<ShareDto> shareDtos = shareMapper.toDtoList(shares);
            List<FutureDto> futureDtos = futureMapper.toDtoList(futures);
            
            int sharesWithLimits = 0;
            int futuresWithLimits = 0;
            int sharesWithoutLimits = 0;
            int futuresWithoutLimits = 0;
            
            // Проверяем акции
            for (ShareDto share : shareDtos) {
                if (share.getFigi() != null && !share.getFigi().trim().isEmpty()) {
                    // Получаем лимиты ТОЛЬКО из кэша (без запроса к API)
                    LimitsDto limits = limitsService.getLimitsFromCache(share.getFigi());
                    if (limits != null && limits.getLimitDown() != null && limits.getLimitUp() != null) {
                        sharesWithLimits++;
                    } else {
                        sharesWithoutLimits++;
                    }
                }
            }
            
            // Проверяем фьючерсы
            for (FutureDto future : futureDtos) {
                if (future.getFigi() != null && !future.getFigi().trim().isEmpty()) {
                    // Получаем лимиты ТОЛЬКО из кэша (без запроса к API)
                    LimitsDto limits = limitsService.getLimitsFromCache(future.getFigi());
                    if (limits != null && limits.getLimitDown() != null && limits.getLimitUp() != null) {
                        futuresWithLimits++;
                    } else {
                        futuresWithoutLimits++;
                    }
                }
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("shares", Map.of(
                "withLimits", sharesWithLimits,
                "withoutLimits", sharesWithoutLimits,
                "total", sharesWithLimits + sharesWithoutLimits
            ));
            response.put("futures", Map.of(
                "withLimits", futuresWithLimits,
                "withoutLimits", futuresWithoutLimits,
                "total", futuresWithLimits + futuresWithoutLimits
            ));
            response.put("total", Map.of(
                "withLimits", sharesWithLimits + futuresWithLimits,
                "withoutLimits", sharesWithoutLimits + futuresWithoutLimits,
                "total", sharesWithLimits + sharesWithoutLimits + futuresWithLimits + futuresWithoutLimits
            ));
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении статистики лимитов: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Получить статистику кэша лимитов
     * 
     * <p>
     * Возвращает статистику кэша лимитов для отладки.
     * </p>
     * 
     * <p>
     * <strong>Пример запроса:</strong>
     * </p>
     * 
     * <pre>
     * GET /api/instruments/limits/cache-stats
     * </pre>
     * 
     * @return статистика кэша лимитов
     */
    @GetMapping("/limits/cache-stats")
    public ResponseEntity<Map<String, Object>> getLimitsCacheStats() {
        try {
            Map<String, Object> cacheStats = limitsService.getCacheStats();
            Map<String, LimitsDto> allLimits = limitsService.getAllLimitsFromCache();
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("cacheStats", cacheStats);
            response.put("cachedLimitsCount", allLimits.size());
            response.put("cachedLimits", allLimits.keySet());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "Ошибка при получении статистики кэша: " + e.getMessage());
            response.put("timestamp", java.time.LocalDateTime.now().toString());
            return ResponseEntity.status(500).body(response);
        }
    }
}

