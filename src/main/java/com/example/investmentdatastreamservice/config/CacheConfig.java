package com.example.investmentdatastreamservice.config;

import java.util.concurrent.TimeUnit;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import com.github.benmanes.caffeine.cache.Caffeine;

/**
 * Конфигурация кэширования для инструментов
 * 
 * <p>
 * Настраивает кэширование для следующих типов инструментов:
 * </p>
 * <ul>
 * <li><strong>sharesCache</strong> - кэш акций</li>
 * <li><strong>futuresCache</strong> - кэш фьючерсов</li>
 * <li><strong>indicativesCache</strong> - кэш индикативных инструментов</li>
 * <li><strong>limitsCache</strong> - кэш лимитов инструментов</li>
 * <li><strong>notificationsCache</strong> - кэш уведомлений о лимитах</li>
 * <li><strong>historicalPricesCache</strong> - кэш исторических экстремумов цен</li>
 * </ul>
 * 
 * <p>
 * Использует Caffeine в качестве провайдера кэша с настройками:
 * </p>
 * <ul>
 * <li>Максимальный размер кэша: 10,000 записей (для всех кэшей)</li>
 * <li>Время жизни записи после записи: 24 часа (строго, независимо от доступа)</li>
 * </ul>
 * 
 * @author InvestmentDataStreamService
 * @version 1.0
 * @since 2024
 */
@Configuration
@EnableCaching
public class CacheConfig {

    /**
     * Создает и настраивает менеджер кэша
     * 
     * <p>
     * Настройки кэша:
     * </p>
 * <ul>
 * <li>Максимальное количество записей: 10,000 (для всех кэшей)</li>
 * <li>Время жизни после записи: 24 часа (строго, независимо от доступа)</li>
 * <li>Запись статистики использования кэша</li>
 * </ul>
     * 
     * @return настроенный CacheManager
     */
    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager =
                new CaffeineCacheManager("sharesCache",
                 "futuresCache", 
                 "indicativesCache",
                  "limitsCache",
                  "notificationsCache",
                  "historicalPricesCache");

        cacheManager.setCaffeine(
                Caffeine.newBuilder().maximumSize(10_000).expireAfterWrite(24, TimeUnit.HOURS)
                        .recordStats());

        return cacheManager;
    }
}

