package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * DTO для минутных свечей
 * 
 * Представляет данные о минутных свечах для API ответов.
 * Содержит основную информацию о свече и расширенную статистику.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MinuteCandleDto {
    
    private String figi;
    private long volume;
    private BigDecimal high;
    private BigDecimal low;
    private Instant time;
    private BigDecimal close;
    private BigDecimal open;
    private boolean isComplete;
    
    // Расширенная статистика
    private BigDecimal priceChange;
    private BigDecimal priceChangePercent;
    private String candleType;
    private BigDecimal bodySize;
    private BigDecimal upperShadow;
    private BigDecimal lowerShadow;
    private BigDecimal highLowRange;
    private BigDecimal averagePrice;
    
    private Instant createdAt;
    private Instant updatedAt;
}
