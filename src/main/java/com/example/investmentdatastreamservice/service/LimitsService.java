package com.example.investmentdatastreamservice.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.math.BigDecimal;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.stereotype.Service;

import com.example.investmentdatastreamservice.dto.LimitsDto;
import com.example.investmentdatastreamservice.utils.QuotationUtils;

import ru.tinkoff.piapi.core.MarketDataService;
import ru.tinkoff.piapi.contract.v1.GetOrderBookResponse;
import ru.tinkoff.piapi.contract.v1.Quotation;

import java.util.HashMap;
import java.util.Map;

@Service
public class LimitsService {
    private static final Logger logger = LoggerFactory.getLogger(LimitsService.class);
    private final MarketDataService marketDataService;
    private final CacheManager cacheManager;
    
    public LimitsService(MarketDataService marketDataService, CacheManager cacheManager) {
        this.marketDataService = marketDataService;
        this.cacheManager = cacheManager;
    }

    /**
     * Получить лимиты для инструмента (делает запрос к API и кэширует результат)
     * 
     * Лимиты кэшируются для быстрого доступа. Кэш автоматически очищается через определенное время.
     * 
     * @param instrumentId FIGI инструмента
     * @return лимиты инструмента
     */
    @Cacheable(value = "limitsCache", key = "#instrumentId")
    public LimitsDto getLimits(String instrumentId) {
        logger.info("🔍 API ЗАПРОС лимитов для инструмента: {}", instrumentId);
        try {
            if (marketDataService == null) {
                logger.error("MarketDataService не инициализирован. Проверьте конфигурацию Tinkoff API.");
                return new LimitsDto(instrumentId, null, null);
            }
            
            GetOrderBookResponse limitsResponse = marketDataService.getOrderBook(instrumentId, 1).join();
            logger.info("Получен ответ OrderBook для инструмента {}: hasLimitUp={}, hasLimitDown={}",
                    instrumentId, limitsResponse.hasLimitUp(), limitsResponse.hasLimitDown());

            if (limitsResponse.hasLimitUp() && limitsResponse.hasLimitDown()) {
                Quotation limitUp = limitsResponse.getLimitUp();
                Quotation limitDown = limitsResponse.getLimitDown();

                BigDecimal limitDownDecimal = QuotationUtils.toBigDecimal(limitDown);
                BigDecimal limitUpDecimal = QuotationUtils.toBigDecimal(limitUp);

                LimitsDto limits = new LimitsDto(instrumentId, limitDownDecimal, limitUpDecimal);
                
                logger.info(
                        "✅ Лимиты для инструмента {}: limitDown={}, limitUp={} - БУДЕТ СОХРАНЕНО В КЭШ",
                        instrumentId, limitDownDecimal, limitUpDecimal);

                return limits;
            } else {
                logger.warn("Лимиты не найдены в OrderBook для инструмента {}: hasLimitUp={}, hasLimitDown={}",
                        instrumentId, limitsResponse.hasLimitUp(), limitsResponse.hasLimitDown());
            }

        } catch (Exception ex) {
            if (ex.getMessage() != null && ex.getMessage().contains("Токен доступа не найден или не активен")) {
                logger.error("Ошибка аутентификации при получении лимитов для инструмента {}: {}", instrumentId, ex.getMessage());
                logger.error("Проверьте правильность токена Tinkoff API в переменных окружения");
            } else {
                logger.error("Ошибка при получении лимитов для инструмента {}: {}", instrumentId, ex.getMessage(), ex);
            }
        }
        logger.warn("❌ Возвращаем пустой список лимитов для инструмента {}", instrumentId);
        return new LimitsDto(instrumentId, null, null);
    }


    /**
     * Принудительно сохранить лимиты в кэш
     * 
     * @param instrumentId FIGI инструмента
     * @param limits лимиты для сохранения
     */
    public void saveLimitsToCache(String instrumentId, LimitsDto limits) {
        try {
            Cache cache = cacheManager.getCache("limitsCache");
            if (cache != null) {
                cache.put(instrumentId, limits);
                logger.debug("✅ Лимиты для инструмента {} принудительно сохранены в кэш", instrumentId);
            } else {
                logger.error("❌ Кэш 'limitsCache' не найден!");
            }
        } catch (Exception e) {
            logger.error("❌ Ошибка при принудительном сохранении лимитов в кэш для инструмента {}: {}", instrumentId, e.getMessage());
        }
    }

    /**
     * Получить лимиты из кэша без запроса к API
     * 
     * @param instrumentId FIGI инструмента
     * @return лимиты из кэша или null, если не найдены
     */
    public LimitsDto getLimitsFromCache(String instrumentId) {
        try {
            Cache cache = cacheManager.getCache("limitsCache");
            if (cache != null) {
                logger.debug("🔍 Поиск в кэше для инструмента: {}", instrumentId);
                Cache.ValueWrapper wrapper = cache.get(instrumentId);
                if (wrapper != null) {
                    LimitsDto limits = (LimitsDto) wrapper.get();
                    logger.info("✅ Лимиты для инструмента {} НАЙДЕНЫ в кэше: {}", instrumentId, limits);
                    return limits;
                } else {
                    logger.warn("❌ Лимиты для инструмента {} НЕ НАЙДЕНЫ в кэше", instrumentId);
                }
            } else {
                logger.error("❌ Кэш 'limitsCache' не найден!");
            }
            return null;
        } catch (Exception e) {
            logger.error("❌ Ошибка при получении лимитов из кэша для инструмента {}: {}", instrumentId, e.getMessage());
            return null;
        }
    }

    /**
     * Получить все лимиты из кэша
     * 
     * @return Map с FIGI и соответствующими лимитами
     */
    public Map<String, LimitsDto> getAllLimitsFromCache() {
        Map<String, LimitsDto> allLimits = new HashMap<>();
        try {
            Cache cache = cacheManager.getCache("limitsCache");
            if (cache != null) {
                logger.debug("🔍 Получение всех лимитов из кэша...");
                @SuppressWarnings("unchecked")
                com.github.benmanes.caffeine.cache.Cache<String, LimitsDto> caffeineCache = 
                    (com.github.benmanes.caffeine.cache.Cache<String, LimitsDto>) cache.getNativeCache();
                if (caffeineCache != null) {
                    logger.info("📊 Caffeine кэш найден, размер: {}", caffeineCache.estimatedSize());
                    caffeineCache.asMap().forEach((key, value) -> {
                        if (value != null) {
                            allLimits.put(key, value);
                            logger.debug("✅ Найден в кэше: {} -> {}", key, value);
                        }
                    });
                    logger.info("📊 Всего лимитов извлечено из кэша: {}", allLimits.size());
                } else {
                    logger.error("❌ Caffeine кэш не найден!");
                }
            } else {
                logger.error("❌ Spring кэш 'limitsCache' не найден!");
            }
        } catch (Exception e) {
            logger.error("❌ Ошибка при получении всех лимитов из кэша: {}", e.getMessage(), e);
        }
        return allLimits;
    }

    /**
     * Проверить, есть ли лимиты в кэше для инструмента
     * 
     * @param instrumentId FIGI инструмента
     * @return true, если лимиты есть в кэше
     */
    public boolean hasLimitsInCache(String instrumentId) {
        return getLimitsFromCache(instrumentId) != null;
    }

    /**
     * Получить статистику кэша лимитов
     * 
     * @return статистика кэша
     */
    public Map<String, Object> getCacheStats() {
        Map<String, Object> stats = new HashMap<>();
        try {
            Cache cache = cacheManager.getCache("limitsCache");
            if (cache != null) {
                @SuppressWarnings("unchecked")
                com.github.benmanes.caffeine.cache.Cache<String, LimitsDto> caffeineCache = 
                    (com.github.benmanes.caffeine.cache.Cache<String, LimitsDto>) cache.getNativeCache();
                if (caffeineCache != null) {
                    stats.put("size", caffeineCache.estimatedSize());
                    stats.put("hitRate", caffeineCache.stats().hitRate());
                    stats.put("missRate", caffeineCache.stats().missRate());
                    stats.put("requestCount", caffeineCache.stats().requestCount());
                }
            }
        } catch (Exception e) {
            logger.error("Ошибка при получении статистики кэша: {}", e.getMessage());
        }
        return stats;
    }
}
