package com.example.investmentdatastreamservice.service;

import com.example.investmentdatastreamservice.entity.FutureEntity;
import com.example.investmentdatastreamservice.entity.IndicativeEntity;
import com.example.investmentdatastreamservice.entity.ShareEntity;
import com.example.investmentdatastreamservice.repository.FutureRepository;
import com.example.investmentdatastreamservice.repository.IndicativeRepository;
import com.example.investmentdatastreamservice.repository.ShareRepository;
import com.example.investmentdatastreamservice.repository.HistoricalPriceRepository;
import com.example.investmentdatastreamservice.dto.HistoricalPriceDto;
import com.example.investmentdatastreamservice.mapper.HistoricalPriceMapper;
import com.example.investmentdatastreamservice.dto.LimitsDto;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Сервис для прогрева кэша инструментов
 * 
 * <p>
 * Отвечает за автоматическую загрузку инструментов в кэш при старте приложения и предоставляет
 * методы для ручного управления кэшем.
 * </p>
 * 
 * <p>
 * Основные функции:
 * </p>
 * <ul>
 * <li>Автоматический прогрев кэша при старте приложения</li>
 * <li>Ручной прогрев кэша по запросу</li>
 * <li>Получение инструментов из кэша</li>
 * <li>Очистка кэша</li>
 * </ul>
 * 
 * @author InvestmentDataStreamService
 * @version 1.0
 * @since 2024
 */
@Service
public class CacheWarmupService {

    private static final Logger logger = LoggerFactory.getLogger(CacheWarmupService.class);

    private final ShareRepository shareRepository;
    private final FutureRepository futureRepository;
    private final IndicativeRepository indicativeRepository;
    private final LimitsService limitsService;
    private final HistoricalPriceRepository historicalPriceRepository;
    private final CacheManager cacheManager;
    
    public CacheWarmupService(ShareRepository shareRepository, FutureRepository futureRepository,
            IndicativeRepository indicativeRepository, LimitsService limitsService, 
            HistoricalPriceRepository historicalPriceRepository, CacheManager cacheManager) {
        this.shareRepository = shareRepository;
        this.futureRepository = futureRepository;
        this.indicativeRepository = indicativeRepository;
        this.limitsService = limitsService;
        this.historicalPriceRepository = historicalPriceRepository;
        this.cacheManager = cacheManager;
    }

    /**
     * Автоматический прогрев кэша при старте приложения
     * 
     * <p>
     * Загружает все инструменты в кэш после инициализации сервиса:
     * </p>
     * <ul>
     * <li>Все акции</li>
     * <li>Все фьючерсы</li>
     * <li>Все индикативные инструменты</li>
     * </ul>
     */
    @PostConstruct
    public void warmupCacheOnStartup() {
        logger.info("Начинается автоматический прогрев кэша инструментов...");

        try {
            long startTime = System.currentTimeMillis();

            // Загружаем акции
            List<ShareEntity> shares = getAllShares();
            logger.info("Загружено {} акций в кэш", shares.size());

            // Загружаем фьючерсы
            List<FutureEntity> futures = getAllFutures();
            logger.info("Загружено {} фьючерсов в кэш", futures.size());

            // Загружаем индикативные инструменты
            List<IndicativeEntity> indicatives = getAllIndicatives();
            logger.info("Загружено {} индикативных инструментов в кэш", indicatives.size());

            // Прогреваем кэш лимитов для акций и фьючерсов
            warmupLimitsCache(shares, futures);
            
            
            // Прогреваем кэш исторических цен
            warmupHistoricalPricesCache();

            long duration = System.currentTimeMillis() - startTime;
            logger.info("Прогрев кэша завершен за {} мс. Всего инструментов: {}", duration,
                    shares.size() + futures.size() + indicatives.size());

            

        } catch (Exception e) {
            logger.error("Ошибка при автоматическом прогреве кэша: {}", e.getMessage(), e);
        }
    }

    /**
     * Ручной прогрев кэша
     * 
     * <p>
     * Очищает текущий кэш и загружает все инструменты заново.
     * </p>
     * <p>
     * Используется для принудительного обновления кэша без перезапуска приложения.
     * </p>
     * 
     * @throws Exception если произошла ошибка при загрузке данных
     */
    public void manualWarmupCache() throws Exception {
        logger.info("Начинается ручной прогрев кэша инструментов...");

        try {
            long startTime = System.currentTimeMillis();

            // Очищаем кэши
            evictAllCaches();

            // Загружаем данные заново
            List<ShareEntity> shares = getAllShares();
            logger.info("Загружено {} акций в кэш", shares.size());

            List<FutureEntity> futures = getAllFutures();
            logger.info("Загружено {} фьючерсов в кэш", futures.size());

            List<IndicativeEntity> indicatives = getAllIndicatives();
            logger.info("Загружено {} индикативных инструментов в кэш", indicatives.size());

            // Прогреваем кэш лимитов для акций и фьючерсов
            warmupLimitsCache(shares, futures);

            // Прогреваем кэш исторических цен
            warmupHistoricalPricesCache();

            long duration = System.currentTimeMillis() - startTime;
            logger.info("Ручной прогрев кэша завершен за {} мс. Всего инструментов: {}", duration,
                    shares.size() + futures.size() + indicatives.size());

        } catch (Exception e) {
            logger.error("Ошибка при ручном прогреве кэша: {}", e.getMessage(), e);
            throw e;
        }
    }

    /**
     * Получить все акции из кэша
     * 
     * <p>
     * При первом вызове загружает данные из БД и сохраняет в кэш. При последующих вызовах
     * возвращает данные из кэша.
     * </p>
     * 
     * @return список всех акций
     */
    @Cacheable(value = "sharesCache", key = "'all'")
    public List<ShareEntity> getAllShares() {
        logger.debug("Загрузка акций из БД");
        return shareRepository.findAll();
    }

    /**
     * Получить все фьючерсы из кэша
     * 
     * <p>
     * При первом вызове загружает данные из БД и сохраняет в кэш. При последующих вызовах
     * возвращает данные из кэша.
     * </p>
     * 
     * @return список всех фьючерсов
     */
    @Cacheable(value = "futuresCache", key = "'all'")
    public List<FutureEntity> getAllFutures() {
        logger.debug("Загрузка фьючерсов из БД");
        return futureRepository.findAll();
    }

    /**
     * Получить все индикативные инструменты из кэша
     * 
     * <p>
     * При первом вызове загружает данные из БД и сохраняет в кэш. При последующих вызовах
     * возвращает данные из кэша.
     * </p>
     * 
     * @return список всех индикативных инструментов
     */
    @Cacheable(value = "indicativesCache", key = "'all'")
    public List<IndicativeEntity> getAllIndicatives() {
        logger.debug("Загрузка индикативных инструментов из БД");
        return indicativeRepository.findAll();
    }

    /**
     * Очистить все кэши инструментов
     * 
     * <p>
     * Удаляет все записи из кэшей акций, фьючерсов, индикативных инструментов и исторических цен.
     * </p>
     */
    @CacheEvict(value = {"sharesCache", "futuresCache", "indicativesCache", "historicalPricesCache"}, allEntries = true)
    public void evictAllCaches() {
        logger.info("Все кэши инструментов очищены");
    }


    /**
     * Прогрев кэша лимитов для акций и фьючерсов
     * 
     * <p>
     * Загружает лимиты для всех акций и фьючерсов в кэш для быстрого доступа.
     * Обрабатывает ошибки gracefully, не прерывая работу приложения.
     * </p>
     * 
     * @param shares список акций
     * @param futures список фьючерсов
     */
    private void warmupLimitsCache(List<ShareEntity> shares, List<FutureEntity> futures) {
        logger.info("🔥 Начинается прогрев кэша лимитов для {} акций и {} фьючерсов", 
                shares.size(), futures.size());
        
        long startTime = System.currentTimeMillis();
        int successCount = 0;
        int errorCount = 0;
        int skippedCount = 0;

        // Прогреваем лимиты для акций
        logger.info("📈 Прогрев лимитов для акций...");
        for (ShareEntity share : shares) {
            if (share.getFigi() != null && !share.getFigi().trim().isEmpty()) {
                try {
                    logger.debug("🔄 Запрос лимитов для акции: {} ({})", share.getTicker(), share.getFigi());
                    // Вызываем getLimits - получаем данные из API
                    LimitsDto limits = limitsService.getLimits(share.getFigi());
                    if (limits != null && limits.getLimitDown() != null && limits.getLimitUp() != null) {
                        // Принудительно сохраняем в кэш (так как @Cacheable не работает при вызове изнутри класса)
                        limitsService.saveLimitsToCache(share.getFigi(), limits);
                        successCount++;
                        logger.debug("✅ Акция {} - лимиты получены и принудительно сохранены в кэш", share.getTicker());
                    } else {
                        errorCount++;
                        logger.debug("⚠️ Акция {} - лимиты пустые", share.getTicker());
                    }
                } catch (Exception e) {
                    errorCount++;
                    logger.debug("❌ Ошибка при загрузке лимитов для акции {}: {}", 
                            share.getFigi(), e.getMessage());
                }
            } else {
                skippedCount++;
            }
        }

        // Прогреваем лимиты для фьючерсов
        logger.info("📈 Прогрев лимитов для фьючерсов...");
        for (FutureEntity future : futures) {
            if (future.getFigi() != null && !future.getFigi().trim().isEmpty()) {
                try {
                    logger.debug("🔄 Запрос лимитов для фьючерса: {} ({})", future.getTicker(), future.getFigi());
                    // Вызываем getLimits - получаем данные из API
                    LimitsDto limits = limitsService.getLimits(future.getFigi());
                    if (limits != null && limits.getLimitDown() != null && limits.getLimitUp() != null) {
                        // Принудительно сохраняем в кэш (так как @Cacheable не работает при вызове изнутри класса)
                        limitsService.saveLimitsToCache(future.getFigi(), limits);
                        successCount++;
                        logger.debug("✅ Фьючерс {} - лимиты получены и принудительно сохранены в кэш", future.getTicker());
                    } else {
                        errorCount++;
                        logger.debug("⚠️ Фьючерс {} - лимиты пустые", future.getTicker());
                    }
                } catch (Exception e) {
                    errorCount++;
                    logger.debug("❌ Ошибка при загрузке лимитов для фьючерса {}: {}", 
                            future.getFigi(), e.getMessage());
                }
            } else {
                skippedCount++;
            }
        }

        long duration = System.currentTimeMillis() - startTime;
        logger.info("🔥 Прогрев кэша лимитов завершен за {} мс. Успешно: {}, Ошибок: {}, Пропущено: {}", 
                duration, successCount, errorCount, skippedCount);
        
        if (errorCount > 0) {
            logger.warn("При прогреве кэша лимитов произошло {} ошибок. Проверьте подключение к Tinkoff API и токен аутентификации.", errorCount);
        }
    }

    /**
     * Прогрев кэша исторических цен
     * 
     * Загружает все исторические цены из БД и сохраняет в кэш:
     * 1. Весь список с ключом 'all' (для получения всех цен сразу)
     * 2. Каждая запись по FIGI (для быстрого доступа по конкретному инструменту)
     * 
     * Использует принудительное сохранение через CacheManager, так как @Cacheable не работает
     * при вызове методов изнутри класса (ограничение Spring AOP).
     */
    private void warmupHistoricalPricesCache() {
        logger.info("📊 Начинается прогрев кэша исторических цен...");
        
        long startTime = System.currentTimeMillis();
        try {
            Cache cache = cacheManager.getCache("historicalPricesCache");
            if (cache == null) {
                logger.error("❌ Кэш 'historicalPricesCache' не найден!");
                return;
            }
            
            // Загружаем все исторические цены напрямую из репозитория (без сервиса, чтобы избежать лишних вызовов)
            List<HistoricalPriceDto> historicalPrices = historicalPriceRepository.findAll().stream()
                    .map(HistoricalPriceMapper.INSTANCE::toDto)
                    .toList();
            logger.info("📊 Загружено {} исторических цен из БД", historicalPrices.size());
            
            // Сохраняем весь список в кэш с ключом 'all'
            cache.put("all", historicalPrices);
            logger.info("📊 Весь список исторических цен сохранен в кэш с ключом 'all'");
            
            // Сохраняем каждую запись по FIGI для быстрого доступа
            int successCount = 0;
            for (HistoricalPriceDto historicalPrice : historicalPrices) {
                if (historicalPrice != null && historicalPrice.getFigi() != null) {
                    try {
                        // Принудительно сохраняем в кэш по ключу FIGI
                        cache.put(historicalPrice.getFigi(), historicalPrice);
                        successCount++;
                    } catch (Exception e) {
                        logger.debug("❌ Ошибка при сохранении исторических цен для {} в кэш: {}", 
                                historicalPrice.getFigi(), e.getMessage());
                    }
                }
            }
            
            long duration = System.currentTimeMillis() - startTime;
            logger.info("📊 Прогрев кэша исторических цен завершен за {} мс. Сохранено записей: {} (всего: {})", 
                    duration, successCount, historicalPrices.size());
        } catch (Exception e) {
            logger.error("❌ Ошибка при прогреве кэша исторических цен: {}", e.getMessage(), e);
        }
    }
    
    /**
     * Обновление кэша исторических цен
     * 
     * Очищает кэш и загружает данные заново из БД.
     * Использует принудительное сохранение через CacheManager для гарантированного попадания в кэш.
     * 
     * @return статистика обновления
     */
    public java.util.Map<String, Object> refreshHistoricalPricesCache() {
        logger.info("🔄 Начинается обновление кэша исторических цен...");
        
        long startTime = System.currentTimeMillis();
        try {
            Cache cache = cacheManager.getCache("historicalPricesCache");
            if (cache == null) {
                logger.error("❌ Кэш 'historicalPricesCache' не найден!");
                return java.util.Map.of(
                    "success", false,
                    "error", "Кэш 'historicalPricesCache' не найден",
                    "durationMs", System.currentTimeMillis() - startTime
                );
            }
            
            // Очищаем кэш
            evictHistoricalPricesCache();
            
            // Загружаем данные заново напрямую из репозитория (без сервиса, чтобы избежать лишних вызовов)
            List<HistoricalPriceDto> historicalPrices = historicalPriceRepository.findAll().stream()
                    .map(HistoricalPriceMapper.INSTANCE::toDto)
                    .toList();
            logger.info("📊 Загружено {} исторических цен из БД", historicalPrices.size());
            
            // Сохраняем весь список в кэш с ключом 'all'
            cache.put("all", historicalPrices);
            
            // Сохраняем каждую запись по FIGI для быстрого доступа
            int successCount = 0;
            for (HistoricalPriceDto historicalPrice : historicalPrices) {
                if (historicalPrice != null && historicalPrice.getFigi() != null) {
                    try {
                        // Принудительно сохраняем в кэш по ключу FIGI
                        cache.put(historicalPrice.getFigi(), historicalPrice);
                        successCount++;
                    } catch (Exception e) {
                        logger.debug("❌ Ошибка при сохранении исторических цен для {} в кэш: {}", 
                                historicalPrice.getFigi(), e.getMessage());
                    }
                }
            }
            
            long duration = System.currentTimeMillis() - startTime;
            logger.info("✅ Обновление кэша исторических цен завершено за {} мс. Сохранено записей: {} (всего: {})", 
                    duration, successCount, historicalPrices.size());
            
            return java.util.Map.of(
                "success", true,
                "successCount", successCount,
                "totalCount", historicalPrices.size(),
                "durationMs", duration
            );
        } catch (Exception e) {
            logger.error("❌ Ошибка при обновлении кэша исторических цен: {}", e.getMessage(), e);
            return java.util.Map.of(
                "success", false,
                "error", e.getMessage(),
                "durationMs", System.currentTimeMillis() - startTime
            );
        }
    }
    
    /**
     * Очистить кэш исторических цен
     */
    @CacheEvict(value = "historicalPricesCache", allEntries = true)
    public void evictHistoricalPricesCache() {
        logger.info("🗑️ Кэш исторических цен очищен");
    }
}

