package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO для статистики конкретного потокового сервиса
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ServiceStatsDto {
    
    private String serviceName;
    private boolean isRunning;
    private boolean isConnected;
    private long totalReceived;
    private long totalProcessed;
    private long totalErrors;
    private long totalDropped;
    private long pendingOperations;
    private double processingRate;
    private double errorRate;
    private double throughputPerSecond;
    private long uptime;
}
