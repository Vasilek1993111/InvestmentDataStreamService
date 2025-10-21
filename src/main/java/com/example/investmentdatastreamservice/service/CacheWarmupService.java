package com.example.investmentdatastreamservice.service;

import com.example.investmentdatastreamservice.entity.FutureEntity;
import com.example.investmentdatastreamservice.entity.IndicativeEntity;
import com.example.investmentdatastreamservice.entity.ShareEntity;
import com.example.investmentdatastreamservice.repository.FutureRepository;
import com.example.investmentdatastreamservice.repository.IndicativeRepository;
import com.example.investmentdatastreamservice.repository.ShareRepository;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
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

    public CacheWarmupService(ShareRepository shareRepository, FutureRepository futureRepository,
            IndicativeRepository indicativeRepository) {
        this.shareRepository = shareRepository;
        this.futureRepository = futureRepository;
        this.indicativeRepository = indicativeRepository;
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
     * Удаляет все записи из кэшей акций, фьючерсов и индикативных инструментов.
     * </p>
     */
    @CacheEvict(value = {"sharesCache", "futuresCache", "indicativesCache"}, allEntries = true)
    public void evictAllCaches() {
        logger.info("Все кэши инструментов очищены");
    }

    /**
     * Очистить кэш акций
     */
    @CacheEvict(value = "sharesCache", allEntries = true)
    public void evictSharesCache() {
        logger.info("Кэш акций очищен");
    }

    /**
     * Очистить кэш фьючерсов
     */
    @CacheEvict(value = "futuresCache", allEntries = true)
    public void evictFuturesCache() {
        logger.info("Кэш фьючерсов очищен");
    }

    /**
     * Очистить кэш индикативных инструментов
     */
    @CacheEvict(value = "indicativesCache", allEntries = true)
    public void evictIndicativesCache() {
        logger.info("Кэш индикативных инструментов очищен");
    }
}

