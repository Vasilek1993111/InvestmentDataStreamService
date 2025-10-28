package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO для агрегированной статистики всех потоковых сервисов
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AggregatedStatsDto {
    
    private long totalReceived;
    private long totalProcessed;
    private long totalErrors;
    private long totalDropped;
    private long pendingOperations;
    private int runningServices;
    private int connectedServices;
    private int totalServices;
    private double overallProcessingRate;
    private double overallErrorRate;
    private double serviceHealthRate;
    private double serviceAvailabilityRate;
}
