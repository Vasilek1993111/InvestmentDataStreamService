package com.example.investmentdatastreamservice.config;

import io.github.cdimascio.dotenv.Dotenv;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;

import jakarta.annotation.PostConstruct;

/**
 * Конфигурация для загрузки переменных окружения из .env файлов
 * 
 * Автоматически загружает соответствующий .env файл в зависимости от активного профиля Spring
 * Должен инициализироваться самым первым
 */
@Configuration
@Order(Integer.MIN_VALUE)
public class EnvironmentConfig {

    private static final Logger logger = LoggerFactory.getLogger(EnvironmentConfig.class);

    @PostConstruct
    public void loadEnvironmentVariables() {
        try {
            String activeProfile = System.getProperty("spring.profiles.active", "test");
            String envFile = getEnvFileName(activeProfile);
            
            logger.info("Loading environment variables from: {}", envFile);
            
            Dotenv dotenv = Dotenv.configure()
                .filename(envFile)
                .ignoreIfMalformed()
                .ignoreIfMissing()
                .load();
            
            // Загружаем переменные в System Properties для Spring
            dotenv.entries().forEach(entry -> {
                String key = entry.getKey();
                String value = entry.getValue();
                
                // Устанавливаем только если переменная еще не установлена
                if (System.getProperty(key) == null) {
                    System.setProperty(key, value);
                    logger.debug("Loaded environment variable: {} = {}", key, 
                        key.toLowerCase().contains("token") || key.toLowerCase().contains("password") 
                            ? "***" : value);
                }
            });
            
            logger.info("Successfully loaded {} environment variables from {}", 
                dotenv.entries().size(), envFile);
            
        } catch (Exception e) {
            logger.error("Error loading environment variables from .env file: {}", e.getMessage());
            logger.warn("Continuing with system environment variables only");
        }
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