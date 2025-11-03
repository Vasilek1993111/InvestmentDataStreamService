package com.example.investmentdatastreamservice.mapper;

import com.example.investmentdatastreamservice.dto.*;
import com.example.investmentdatastreamservice.service.MarketDataStreamingServiceAdapter.ServiceStats;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

/**
 * Mapper для конвертации статистики сервиса в DTO
 */
@Mapper(componentModel = "spring")
public interface StatsMapper {
    
    StatsMapper INSTANCE = Mappers.getMapper(StatsMapper.class);
    
    /**
     * Конвертирует ServiceStats в ObjectStatsDto
     */
    default ObjectStatsDto toObjectStatsDto(ServiceStats stats) {
        if (stats == null) {
            return null;
        }
        return ObjectStatsDto.builder()
                .general(toGeneralStatsDto(stats))
                .lastPrice(toLastPriceStatsDto(stats))
                .trades(toTradeStatsDto(stats))
                .build();
    }
    
    /**
     * Конвертирует ServiceStats в GeneralStatsDto
     */
    @Mapping(target = "running", source = "running")
    @Mapping(target = "connected", source = "connected")
    @Mapping(target = "totalReceived", source = "totalReceivedAll")
    @Mapping(target = "totalInserted", source = "totalProcessedAll")
    @Mapping(target = "totalProcessed", source = "totalProcessedAll")
    @Mapping(target = "totalErrors", source = "totalErrorsAll")
    @Mapping(target = "overallProcessingRate", source = "overallProcessingRate")
    @Mapping(target = "overallErrorRate", source = "overallErrorRate")
    @Mapping(target = "tradeInsertUtilization", source = "tradeInsertUtilization")
    @Mapping(target = "availableTradeInserts", source = "availableTradeInserts")
    @Mapping(target = "maxConcurrentTradeInserts", source = "maxConcurrentTradeInserts")
    GeneralStatsDto toGeneralStatsDto(ServiceStats stats);
    
    /**
     * Конвертирует ServiceStats в LastPriceStatsDto
     */
    @Mapping(target = "received", source = "totalLastPriceReceived")
    @Mapping(target = "processed", source = "totalLastPriceProcessed")
    @Mapping(target = "inserted", source = "totalLastPriceInserted")
    @Mapping(target = "errors", source = "totalErrorsAll")
    @Mapping(target = "receivedShares", source = "totalLastPriceReceivedShares")
    @Mapping(target = "receivedFutures", source = "totalLastPriceReceivedFutures")
    @Mapping(target = "receivedIndicatives", source = "totalLastPriceReceivedIndicatives")
    @Mapping(target = "processingRate", expression = "java(calculateProcessingRate(stats.getTotalLastPriceReceived(), stats.getTotalLastPriceProcessed()))")
    @Mapping(target = "errorRate", expression = "java(calculateErrorRate(stats.getTotalLastPriceProcessed(), stats.getTotalErrorsAll()))")
    LastPriceStatsDto toLastPriceStatsDto(ServiceStats stats);
    
    /**
     * Конвертирует ServiceStats в TradeStatsDto
     */
    @Mapping(target = "received", source = "totalTradeMessagesReceived")
    @Mapping(target = "processed", source = "totalTradesProcessed")
    @Mapping(target = "inserted", source = "totalTradesInserted")
    @Mapping(target = "errors", source = "totalErrorsAll")
    @Mapping(target = "receivedShares", source = "totalTradeReceivedShares")
    @Mapping(target = "receivedFutures", source = "totalTradeReceivedFutures")
    @Mapping(target = "receivedIndicatives", source = "totalTradeReceivedIndicatives")
    @Mapping(target = "processingRate", ignore = true)
    @Mapping(target = "errorRate", ignore = true)
    TradeStatsDto toTradeStatsDto(ServiceStats stats);
    
    /**
     * Конвертирует ServiceStats в ServiceHealthDto
     */
    @Mapping(target = "isRunning", source = "running")
    @Mapping(target = "isConnected", source = "connected")
    @Mapping(target = "totalProcessed", source = "totalProcessedAll")
    @Mapping(target = "totalErrors", source = "totalErrorsAll")
    @Mapping(target = "totalReceived", source = "totalReceivedAll")
    @Mapping(target = "availableInserts", source = "availableTradeInserts")
    @Mapping(target = "maxConcurrentInserts", source = "maxConcurrentTradeInserts")
    @Mapping(target = "insertUtilization", source = "tradeInsertUtilization")
    @Mapping(target = "errorRate", source = "overallErrorRate")
    @Mapping(target = "processingRate", source = "overallProcessingRate")
    ServiceHealthDto toServiceHealthDto(ServiceStats stats);
    
    /**
     * Вычисляет процент обработки
     */
    default double calculateProcessingRate(long received, long processed) {
        return received > 0 ? (double) processed / received : 0.0;
    }
    
    /**
     * Вычисляет процент ошибок
     */
    default double calculateErrorRate(long processed, long errors) {
        return (processed + errors) > 0 ? (double) errors / (processed + errors) : 0.0;
    }
}
