package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * DTO для запроса обновления порога приближения к лимитам
 * 
 * Используется в API для изменения порогов мониторинга лимитов.
 * 
 * @author InvestmentDataStreamService
 * @version 1.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ThresholdUpdateRequest {
    
    /**
     * Порог в процентах (например, 1.0 = 1%)
     * 
     * Должен быть в диапазоне от 0 до 100
     */
    private BigDecimal threshold;
}

