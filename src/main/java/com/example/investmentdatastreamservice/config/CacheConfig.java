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
 * </ul>
 * 
 * <p>
 * Использует Caffeine в качестве провайдера кэша с настройками:
 * </p>
 * <ul>
 * <li>Максимальный размер кэша: 10,000 записей</li>
 * <li>Время жизни записи после записи: 24 часа</li>
 * <li>Время жизни записи после последнего доступа: 12 часов</li>
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
     * <li>Максимальное количество записей: 10,000</li>
     * <li>Время жизни после записи: 24 часа</li>
     * <li>Время жизни после доступа: 12 часов</li>
     * <li>Запись статистики использования кэша</li>
     * </ul>
     * 
     * @return настроенный CacheManager
     */
    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager =
                new CaffeineCacheManager("sharesCache", "futuresCache", "indicativesCache");

        cacheManager.setCaffeine(
                Caffeine.newBuilder().maximumSize(10_000).expireAfterWrite(24, TimeUnit.HOURS)
                        .expireAfterAccess(12, TimeUnit.HOURS).recordStats());

        return cacheManager;
    }
}

