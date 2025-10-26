package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;


/**
 * DTO для акций
 * 
 * Представляет данные об акциях для API ответов.
 * Содержит информацию о тикере, названии, валюте и других параметрах акции.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShareDto {
    
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
}
