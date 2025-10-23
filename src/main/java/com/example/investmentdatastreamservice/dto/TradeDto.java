package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * DTO для сделок
 * 
 * Представляет данные о сделках для API ответов.
 * Содержит информацию о цене, количестве, валюте и других параметрах сделки.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TradeDto {
    
    private String figi;
    private LocalDateTime time;
    private String direction;
    private BigDecimal price;
    private Long quantity;
    private String currency;
    private String exchange;
    private String tradeSource;
    private String tradeDirection;
}
