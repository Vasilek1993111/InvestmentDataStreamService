package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO для общей статистики сервиса
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GeneralStatsDto {
    
    private boolean running;
    private boolean connected;
    private long totalReceived;
    private long totalProcessed;
    private long totalInserted;
    private long totalErrors;
    private double overallProcessingRate;
    private double overallErrorRate;
    private double tradeInsertUtilization;
    private int availableTradeInserts;
    private int maxConcurrentTradeInserts;
}
