package com.example.investmentdatastreamservice.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Конфигурация для включения планировщика задач
 * 
 * Включает Spring Scheduler для выполнения периодических задач
 * мониторинга лимитов и очистки кэша уведомлений.
 */
@Configuration
@EnableScheduling
public class SchedulingConfig {
    // Конфигурация планировщика задач
    // Настройки пула потоков и другие параметры
    // задаются в application.properties
}
