package com.example.investmentdatastreamservice.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO для исторических максимумов и минимумов цен
 * 
 * Представляет данные о исторических максимумах и минимумах цен для API ответов.
 * Содержит информацию о тикере, названии, валюте и других параметрах инструмента.
 */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public  class HistoricalPriceDto {
        private String figi;
        private String ticker;
        private String instrumentType;
        private BigDecimal historicalHigh;
        private OffsetDateTime historicalHighDate;
        private BigDecimal historicalLow;
        private OffsetDateTime historicalLowDate;
    }

