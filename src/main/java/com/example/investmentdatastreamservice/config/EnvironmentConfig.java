package com.example.investmentdatastreamservice.config;

import org.springframework.context.annotation.Configuration;
import io.github.cdimascio.dotenv.Dotenv;
import jakarta.annotation.PostConstruct;

/**
 * Конфигурация для загрузки переменных окружения из .env файла
 */
@Configuration
public class EnvironmentConfig {

    @PostConstruct
    public void loadEnvironmentVariables() {
        try {
            Dotenv dotenv = Dotenv.configure().ignoreIfMalformed().ignoreIfMissing().load();

            // Устанавливаем переменные окружения для Spring Boot
            dotenv.entries().forEach(entry -> {
                if (System.getProperty(entry.getKey()) == null) {
                    System.setProperty(entry.getKey(), entry.getValue());
                }
            });

            System.out.println("Environment variables loaded from .env file");
        } catch (Exception e) {
            System.err.println("Failed to load .env file: " + e.getMessage());
        }
    }
}
