package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * DTO для запроса обновления нескольких порогов мониторинга лимитов
 * 
 * Используется в API для одновременного изменения обоих порогов.
 * 
 * @author InvestmentDataStreamService
 * @version 1.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ThresholdsUpdateRequest {
    
    /**
     * Порог приближения к биржевым лимитам в процентах (например, 1.0 = 1%)
     * 
     * Должен быть в диапазоне от 0 до 100
     * Может быть null, если не требуется обновление этого порога
     */
    private BigDecimal approachThreshold;
    
    /**
     * Порог приближения к историческим экстремумам в процентах (например, 1.0 = 1%)
     * 
     * Должен быть в диапазоне от 0 до 100
     * Может быть null, если не требуется обновление этого порога
     */
    private BigDecimal historicalApproachThreshold;
}

