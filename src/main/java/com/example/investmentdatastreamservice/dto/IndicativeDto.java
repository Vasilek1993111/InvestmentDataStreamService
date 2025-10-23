package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO для индикативных инструментов
 * 
 * Представляет данные об индикативных инструментах для API ответов.
 * Содержит информацию о тикере, названии, валюте и других параметрах инструмента.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class IndicativeDto {
    
    private String figi;
    private String ticker;
    private String name;
    private String currency;
    private String exchange;
    private String classCode;
    private String uid;
    private Boolean sellAvailableFlag;
    private Boolean buyAvailableFlag;
}
