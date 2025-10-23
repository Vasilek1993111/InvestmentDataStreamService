package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * DTO для фьючерсов
 * 
 * Представляет данные о фьючерсах для API ответов.
 * Содержит информацию о тикере, названии, валюте и других параметрах фьючерса.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FutureDto {
    
    private String figi;
    private String ticker;
    private String name;
    private String currency;
    private String exchange;
    private String sector;
    private String tradingStatus;
    private Boolean shortEnabled;
    private String assetUid;
    private BigDecimal minPriceIncrement;
    private Integer lot;
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
