package com.example.investmentdatastreamservice.config;

import lombok.Data;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Конфигурационные свойства для мониторинга лимитов
 * 
 * <p>
 * Читает значения из файлов конфигурации:
 * <ul>
 * <li>application.properties (базовые значения)</li>
 * <li>application-prod.properties (для продакшн профиля)</li>
 * <li>application-test.properties (для тестового профиля)</li>
 * </ul>
 * </p>
 * 
 * <p>
 * Значения могут быть переопределены через переменные окружения или параметры запуска.
 * </p>
 * 
 * <p>
 * Структура свойств в конфигурационных файлах:
 * <ul>
 * <li>limit.monitor.approach.threshold - порог приближения к биржевым лимитам (в процентах)</li>
 * <li>limit.monitor.historical.approach.threshold - порог приближения к историческим экстремумам (в процентах)</li>
 * </ul>
 * </p>
 * 
 * @author InvestmentDataStreamService
 * @version 1.0
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "limit.monitor")
public class LimitMonitorProperties {
    
    private static final Logger logger = LoggerFactory.getLogger(LimitMonitorProperties.class);
    
    /**
     * Настройки порога приближения к лимиту
     */
    private ApproachThreshold approach = new ApproachThreshold();
    
    /**
     * Настройки порога приближения к историческим экстремумам
     */
    private Historical historical = new Historical();
    
    /**
     * Устанавливает порог приближения к биржевым лимитам
     * 
     * @param threshold порог в процентах (например, 1.0 = 1%)
     * @throws IllegalArgumentException если значение некорректно
     */
    public void setApproachThreshold(BigDecimal threshold) {
        validateThreshold(threshold, "approach");
        this.approach.setThreshold(threshold);
        logger.info("✅ Порог приближения к биржевым лимитам изменен: {}%", 
                   threshold.setScale(2, RoundingMode.HALF_UP));
    }
    
    /**
     * Устанавливает порог приближения к историческим экстремумам
     * 
     * @param threshold порог в процентах (например, 1.0 = 1%)
     * @throws IllegalArgumentException если значение некорректно
     */
    public void setHistoricalApproachThreshold(BigDecimal threshold) {
        validateThreshold(threshold, "historical");
        this.historical.getApproach().setThreshold(threshold);
        logger.info("✅ Порог приближения к историческим экстремумам изменен: {}%", 
                   threshold.setScale(2, RoundingMode.HALF_UP));
    }
    
    /**
     * Получает порог приближения к биржевым лимитам
     * 
     * @return порог в процентах
     */
    public BigDecimal getApproachThreshold() {
        return this.approach.getThreshold();
    }
    
    /**
     * Получает порог приближения к историческим экстремумам
     * 
     * @return порог в процентах
     */
    public BigDecimal getHistoricalApproachThreshold() {
        return this.historical.getApproach().getThreshold();
    }
    
    /**
     * Валидация порога
     * 
     * @param threshold значение порога
     * @param type тип порога (для логирования)
     * @throws IllegalArgumentException если значение некорректно
     */
    private void validateThreshold(BigDecimal threshold, String type) {
        if (threshold == null) {
            throw new IllegalArgumentException("Порог " + type + " не может быть null");
        }
        if (threshold.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Порог " + type + " не может быть отрицательным: " + threshold);
        }
        if (threshold.compareTo(BigDecimal.valueOf(100)) > 0) {
            throw new IllegalArgumentException("Порог " + type + " не может быть больше 100%: " + threshold);
        }
    }
    
    /**
     * Класс для настроек порога приближения к биржевым лимитам
     */
    @Data
    public static class ApproachThreshold {
        /**
         * Порог приближения к лимиту в процентах (например, 1.0 = 1%)
         * 
         * Уведомления отправляются когда цена приближается к лимиту 
         * на указанный процент или меньше.
         * 
         * Значение по умолчанию: 1.0
         */
        private BigDecimal threshold = BigDecimal.valueOf(1.0);
        
        /**
         * Устанавливает порог с валидацией
         * 
         * @param threshold порог в процентах
         * @throws IllegalArgumentException если значение некорректно
         */
        public void setThreshold(BigDecimal threshold) {
            if (threshold == null) {
                throw new IllegalArgumentException("Порог не может быть null");
            }
            if (threshold.compareTo(BigDecimal.ZERO) < 0) {
                throw new IllegalArgumentException("Порог не может быть отрицательным: " + threshold);
            }
            if (threshold.compareTo(BigDecimal.valueOf(100)) > 0) {
                throw new IllegalArgumentException("Порог не может быть больше 100%: " + threshold);
            }
            this.threshold = threshold;
        }
    }
    
    /**
     * Класс для настроек порога приближения к историческим экстремумам
     */
    @Data
    public static class Historical {
        /**
         * Настройки порога приближения к историческим экстремумам
         */
        private ApproachThreshold approach = new ApproachThreshold();
    }
}

