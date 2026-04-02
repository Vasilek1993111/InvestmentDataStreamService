package com.example.investmentdatastreamservice.config;

import io.github.cdimascio.dotenv.Dotenv;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationContextInitializer;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import java.util.HashMap;
import java.util.Map;

/**
 * Инициализатор переменных окружения из .env файлов
 * 
 * Выполняется на самой ранней стадии инициализации Spring Context
 * до создания любых бинов, что позволяет загружать переменные окружения
 * для использования в конфигурации.
 */
public class EnvironmentInitializer implements ApplicationContextInitializer<ConfigurableApplicationContext> {

    private static final Logger logger = LoggerFactory.getLogger(EnvironmentInitializer.class);

    @Override
    public void initialize(ConfigurableApplicationContext applicationContext) {
        ConfigurableEnvironment environment = applicationContext.getEnvironment();
        
        String activeProfile = environment.getActiveProfiles().length > 0 
            ? environment.getActiveProfiles()[0] 
            : "default";

        String envFile = getEnvFileName(activeProfile);
        
        logger.info("=== LOADING ENVIRONMENT VARIABLES ===");
        logger.info("Active profile: {}", activeProfile);
        logger.info("Looking for environment file: {}", envFile);
        
        try {
            // Загружаем соответствующий .env файл
            Dotenv dotenv = Dotenv.configure()
                .filename(envFile)
                .ignoreIfMalformed()
                .ignoreIfMissing()
                .load();

            // Преобразуем переменные в Map
            Map<String, Object> envProperties = new HashMap<>();
            dotenv.entries().forEach(entry -> {
                envProperties.put(entry.getKey(), entry.getValue());
            });

            // Добавляем переменные в Spring Environment
            MapPropertySource propertySource = new MapPropertySource("dotenv", envProperties);
            environment.getPropertySources().addFirst(propertySource);

            logger.info("✅ Loaded environment variables from: {}", envFile);
            logger.info("🔧 Loaded {} environment variables", envProperties.size());
            
            if (!envProperties.containsKey("T_INVEST_TEST_TOKEN")
                    && !envProperties.containsKey("T_INVEST_PROD_TOKEN")) {
                logger.warn("T-Invest API token was not found in {}", envFile);
            }

            if (!envProperties.containsKey("SPRING_DATASOURCE_TEST_USERNAME")
                    && !envProperties.containsKey("SPRING_DATASOURCE_PROD_USERNAME")) {
                logger.warn("Datasource username was not found in {}", envFile);
            }

        } catch (Exception e) {
            logger.warn("⚠️  Warning: Could not load {} - using default values", envFile);
            logger.warn("💡 Create {} file based on {}.example", envFile, envFile);
            logger.debug("Failed to load environment file {}", envFile, e);
        }

        logger.info("=== ENVIRONMENT LOADING COMPLETED ===");
    }

    /**
     * Определяет имя .env файла в зависимости от активного профиля
     */
    private String getEnvFileName(String activeProfile) {
        switch (activeProfile.toLowerCase()) {
            case "test":
                return ".env.test";
            case "prod":
            case "production":
                return ".env.prod";
            default:
                return ".env";
        }
    }
}
