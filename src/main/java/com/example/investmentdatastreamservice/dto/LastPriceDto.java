package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * DTO для цен последних сделок
 * 
 * Представляет данные о ценах последних сделок для API ответов.
 * Содержит информацию о цене, валюте и бирже.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LastPriceDto {
    
    private String figi;
    private LocalDateTime time;
    private BigDecimal price;
    private String currency;
    private String exchange;
}

