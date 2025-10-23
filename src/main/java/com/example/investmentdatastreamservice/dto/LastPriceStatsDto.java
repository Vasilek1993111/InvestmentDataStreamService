package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO для статистики по LastPrice данным
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LastPriceStatsDto {
    
    private long received;
    private long processed;
    private long inserted;
    private long errors;
    private double processingRate;
    private double errorRate;
    private long receivedShares;
    private long receivedFutures;
    private long receivedIndicatives;
}
