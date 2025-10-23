package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO для детальной информации о состоянии сервиса
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ServiceHealthDto {
    
    private boolean isRunning;
    private boolean isConnected;
    private long totalProcessed;
    private long totalErrors;
    private long totalReceived;
    private int availableInserts;
    private int maxConcurrentInserts;
    private double insertUtilization;
    private double errorRate;
    private double processingRate;
}
