package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO для статистики, сгруппированной на 3 объекта: общая, lastPrice, trades
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ObjectStatsDto {
    
    private GeneralStatsDto general;
    private LastPriceStatsDto lastPrice;
    private TradeStatsDto trades;
}
