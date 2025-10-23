package com.example.investmentdatastreamservice.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;

import java.util.Arrays;
import java.util.List;

/**
 * Конфигурация и валидация окружения
 * 
 * Проверяет корректность настроек для разных профилей и выводит предупреждения
 * о потенциальных проблемах конфигурации.
 */
@Configuration
public class EnvironmentConfig {

    private static final Logger log = LoggerFactory.getLogger(EnvironmentConfig.class);

    @Value("${spring.profiles.active:default}")
    private String activeProfile;

    @Value("${tinkoff.api.token:}")
    private String tinkoffApiToken;

    @Value("${spring.datasource.password:}")
    private String dbPassword;

    @Value("${server.port:8084}")
    private int serverPort;

    @Value("${spring.datasource.hikari.maximum-pool-size:20}")
    private int maxPoolSize;

    @Value("${app.performance.trade-insert-threads:12}")
    private int tradeInsertThreads;

    @Value("${app.performance.max-concurrent-inserts:200}")
    private int maxConcurrentInserts;

    /**
     * Валидация конфигурации при запуске приложения
     */
    @EventListener(ApplicationReadyEvent.class)
    public void validateConfiguration() {
        log.info("=== ENVIRONMENT CONFIGURATION VALIDATION ===");
        log.info("Active Profile: {}", activeProfile);
        log.info("Server Port: {}", serverPort);
        log.info("Max Pool Size: {}", maxPoolSize);
        log.info("Trade Insert Threads: {}", tradeInsertThreads);
        log.info("Max Concurrent Inserts: {}", maxConcurrentInserts);

        validateProfileSpecificSettings();
        validateSecuritySettings();
        validatePerformanceSettings();
        validateDatabaseSettings();

        log.info("=== CONFIGURATION VALIDATION COMPLETED ===");
    }

    /**
     * Валидация настроек для конкретного профиля
     */
    private void validateProfileSpecificSettings() {
        List<String> validProfiles = Arrays.asList("test", "prod", "default");
        
        if (!validProfiles.contains(activeProfile)) {
            log.warn("Unknown profile '{}'. Valid profiles: {}", activeProfile, validProfiles);
        }

        if ("test".equals(activeProfile)) {
            validateTestProfile();
        } else if ("prod".equals(activeProfile)) {
            validateProdProfile();
        }
    }

    /**
     * Валидация настроек для тестового профиля
     */
    @Profile("test")
    private void validateTestProfile() {
        log.info("Validating TEST profile settings...");
        
        if (maxPoolSize > 20) {
            log.warn("TEST: High pool size ({}) for test environment. Consider reducing to save resources.", maxPoolSize);
        }
        
        if (tradeInsertThreads > 8) {
            log.warn("TEST: High thread count ({}) for test environment. Consider reducing.", tradeInsertThreads);
        }
        
        log.info("TEST profile validation completed");
    }

    /**
     * Валидация настроек для продакшн профиля
     */
    @Profile("prod")
    private void validateProdProfile() {
        log.info("Validating PRODUCTION profile settings...");
        
        if (maxPoolSize < 30) {
            log.warn("PROD: Low pool size ({}) for production. Consider increasing for better performance.", maxPoolSize);
        }
        
        if (tradeInsertThreads < 16) {
            log.warn("PROD: Low thread count ({}) for production. Consider increasing for better throughput.", tradeInsertThreads);
        }
        
        if (maxConcurrentInserts < 100) {
            log.warn("PROD: Low concurrent inserts limit ({}) for production. Consider increasing.", maxConcurrentInserts);
        }
        
        log.info("PRODUCTION profile validation completed");
    }

    /**
     * Валидация настроек безопасности
     */
    private void validateSecuritySettings() {
        log.info("Validating security settings...");
        
        // Проверка токена API
        if (tinkoffApiToken == null || tinkoffApiToken.trim().isEmpty()) {
            log.error("SECURITY: Tinkoff API token is not set! Set TINKOFF_API_TOKEN environment variable.");
        } else if ("test-token-please-replace".equals(tinkoffApiToken)) {
            log.warn("SECURITY: Using default test token. Replace with real token for production!");
        } else {
            log.info("SECURITY: API token is configured (length: {})", tinkoffApiToken.length());
        }
        
        // Проверка пароля БД
        if (dbPassword == null || dbPassword.trim().isEmpty()) {
            log.error("SECURITY: Database password is not set!");
        } else if ("123password123".equals(dbPassword)) {
            log.warn("SECURITY: Using default database password. Change for production!");
        } else {
            log.info("SECURITY: Database password is configured");
        }
        
        log.info("Security validation completed");
    }

    /**
     * Валидация настроек производительности
     */
    private void validatePerformanceSettings() {
        log.info("Validating performance settings...");
        
        // Проверка соотношения потоков и пула соединений
        int recommendedPoolSize = tradeInsertThreads * 2;
        if (maxPoolSize < recommendedPoolSize) {
            log.warn("PERFORMANCE: Pool size ({}) may be too low for thread count ({}). Recommended: {}", 
                    maxPoolSize, tradeInsertThreads, recommendedPoolSize);
        }
        
        // Проверка лимитов
        if (maxConcurrentInserts > maxPoolSize * 2) {
            log.warn("PERFORMANCE: Max concurrent inserts ({}) may exceed pool capacity ({}).", 
                    maxConcurrentInserts, maxPoolSize);
        }
        
        // Проверка порта
        if (serverPort < 1024 && serverPort != 8084) {
            log.warn("PERFORMANCE: Port {} may require elevated privileges.", serverPort);
        }
        
        log.info("Performance validation completed");
    }

    /**
     * Валидация настроек базы данных
     */
    private void validateDatabaseSettings() {
        log.info("Validating database settings...");
        
        // Проверка пула соединений
        if (maxPoolSize < 5) {
            log.warn("DATABASE: Very low pool size ({}) may cause connection issues.", maxPoolSize);
        }
        
        if (maxPoolSize > 100) {
            log.warn("DATABASE: Very high pool size ({}) may cause resource exhaustion.", maxPoolSize);
        }
        
        log.info("Database validation completed");
    }

    /**
     * Получить информацию о конфигурации
     */
    public String getConfigurationInfo() {
        return String.format(
            "Profile: %s, Port: %d, Pool Size: %d, Threads: %d, Max Inserts: %d",
            activeProfile, serverPort, maxPoolSize, tradeInsertThreads, maxConcurrentInserts
        );
    }
}