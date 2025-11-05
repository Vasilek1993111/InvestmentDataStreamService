package com.example.investmentdatastreamservice.service;

import java.math.BigDecimal;
import java.math.RoundingMode;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class HistoricalPricesChecker {
    private static final Logger logger = LoggerFactory.getLogger(HistoricalPricesChecker.class);

    /**
     * Проверка приближения к историческому экстремуму
     * 
     * @param figi FIGI инструмента
     * @param ticker тикер инструмента
     * @param instrumentName название инструмента
     * @param currentPrice текущая цена
     * @param historicalLimitPrice исторический экстремум (максимум или минимум)
     * @param approachThresholdHistoricalPrice порог приближения (десятичное значение, например 0.01 = 1%)
     * @param limitType тип лимита ("UP" для максимума, "DOWN" для минимума)
     * @param historicalExtremeDate дата исторического экстремума
     * @return true если достигнут или приближается к экстремуму, false иначе
     */
    public boolean checkHistoricalPricesApproachLimit(String figi, String ticker, String instrumentName, 
                                                      BigDecimal currentPrice, BigDecimal historicalLimitPrice, 
                                                      BigDecimal approachThresholdHistoricalPrice,
                                                      String limitType, java.time.OffsetDateTime historicalExtremeDate) {
        if (currentPrice == null || historicalLimitPrice == null) {
            return false;
        }

        BigDecimal distanceToLimit = calculateDistanceToLimitHistoricalPrice(currentPrice, historicalLimitPrice);
        BigDecimal distanceToLimitPercent = distanceToLimit.multiply(new BigDecimal("100"));
        BigDecimal approachThresholdPercent = approachThresholdHistoricalPrice.multiply(new BigDecimal("100"));

        // Проверяем, достигнут ли исторический экстремум
        boolean isLimitReached = isLimitHistoricalPriceReached(currentPrice, historicalLimitPrice, limitType);
        
        // Проверяем, приближается ли к экстремуму
        boolean isApproachingLimit = distanceToLimit.compareTo(approachThresholdHistoricalPrice) <= 0 && !isLimitReached;

        // Логируем информацию о проверке исторического экстремума
        logger.debug("Проверка исторического экстремума {} для {} ({}): текущая цена={}, экстремум={}, расстояние={}%, порог приближения={}%", 
                    limitType, ticker, figi, currentPrice, historicalLimitPrice, 
                    distanceToLimitPercent.setScale(2, RoundingMode.HALF_UP),
                    approachThresholdPercent.setScale(2, RoundingMode.HALF_UP));

        return isLimitReached || isApproachingLimit;
    }

    /**
     * Вычисление расстояния до исторического экстремума в процентах
     */
    private BigDecimal calculateDistanceToLimitHistoricalPrice(BigDecimal currentPrice, BigDecimal historicalLimitPrice) {
        if (currentPrice == null || historicalLimitPrice == null || currentPrice.compareTo(BigDecimal.ZERO) == 0) {
            return BigDecimal.ZERO;
        }

        BigDecimal difference = historicalLimitPrice.subtract(currentPrice).abs();
        return difference.divide(currentPrice, 4, RoundingMode.HALF_UP);
    }

    /**
     * Проверка, достигнут ли исторический экстремум
     */
    private boolean isLimitHistoricalPriceReached(BigDecimal currentPrice, BigDecimal historicalLimitPrice, String limitType) {
        if (currentPrice == null || historicalLimitPrice == null) {
            return false;
        }
        
        if ("UP".equals(limitType)) {
            // Для максимума: текущая цена >= исторического максимума
            return currentPrice.compareTo(historicalLimitPrice) >= 0;
        } else if ("DOWN".equals(limitType)) {
            // Для минимума: текущая цена <= исторического минимума
            return currentPrice.compareTo(historicalLimitPrice) <= 0;
        }
        return false;
    }
}
