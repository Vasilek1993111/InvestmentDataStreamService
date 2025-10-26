package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;


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
    private String basicAsset;
    private String currency;
    private String exchange;
    private Boolean shortEnabled;
    private BigDecimal minPriceIncrement;
    private Integer lot;
    private BigDecimal basicAssetSize;
    
    
}
