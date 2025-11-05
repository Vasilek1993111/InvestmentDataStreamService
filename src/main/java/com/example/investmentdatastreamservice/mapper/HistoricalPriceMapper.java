package com.example.investmentdatastreamservice.mapper;

import com.example.investmentdatastreamservice.dto.HistoricalPriceDto;
import com.example.investmentdatastreamservice.entity.HistoricalPricesEntity;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * Mapper для конвертации между HistoricalPricesEntity и HistoricalPriceDto
 * 
 * Использует MapStruct для автоматической генерации кода маппинга.
 * Обеспечивает преобразование между слоями Entity и DTO.
 */
@Mapper(componentModel = "spring")
public interface HistoricalPriceMapper {
    
    HistoricalPriceMapper INSTANCE = Mappers.getMapper(HistoricalPriceMapper.class);
    
    /**
     * Конвертирует Entity в DTO
     * 
     * @param entity сущность исторических цен
     * @return DTO исторических цен
     */
    HistoricalPriceDto toDto(HistoricalPricesEntity entity);
    
    /**
     * Конвертирует DTO в Entity
     * 
     * @param dto DTO исторических цен
     * @return сущность исторических цен
     */
    HistoricalPricesEntity toEntity(HistoricalPriceDto dto);
    
    /**
     * Конвертирует список Entity в список DTO
     * 
     * @param entities список сущностей исторических цен
     * @return список DTO исторических цен
     */
    List<HistoricalPriceDto> toDtoList(List<HistoricalPricesEntity> entities);
    
    /**
     * Конвертирует список DTO в список Entity
     * 
     * @param dtos список DTO исторических цен
     * @return список сущностей исторических цен
     */
    List<HistoricalPricesEntity> toEntityList(List<HistoricalPriceDto> dtos);
}
