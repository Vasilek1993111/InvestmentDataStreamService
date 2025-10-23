package com.example.investmentdatastreamservice.config;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.context.ApplicationContextInitializer;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import java.util.HashMap;
import java.util.Map;

/**
 * Конфигурация для загрузки переменных окружения из .env файлов
 * 
 * Загружается на самой ранней стадии инициализации Spring Context
 * Автоматически загружает соответствующий .env файл в зависимости от активного профиля:
 * - .env.test для профиля 'test'
 * - .env.prod для профиля 'prod'
 * - .env для остальных случаев
 */
public class DotenvConfig implements ApplicationContextInitializer<ConfigurableApplicationContext> {

    @Override
    public void initialize(ConfigurableApplicationContext applicationContext) {
        ConfigurableEnvironment environment = applicationContext.getEnvironment();
        
        String activeProfile = environment.getActiveProfiles().length > 0 
            ? environment.getActiveProfiles()[0] 
            : "default";

        String envFile = getEnvFileName(activeProfile);
        
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

            System.out.println("✅ Loaded environment variables from: " + envFile);
            System.out.println("📋 Active profile: " + activeProfile);
            System.out.println("🔧 Loaded " + envProperties.size() + " environment variables");

        } catch (Exception e) {
            System.out.println("⚠️  Warning: Could not load " + envFile + " - using default values");
            System.out.println("💡 Create " + envFile + " file based on " + envFile + ".example");
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
