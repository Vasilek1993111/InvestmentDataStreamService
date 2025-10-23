package com.example.investmentdatastreamservice.mapper;

import com.example.investmentdatastreamservice.dto.MinuteCandleDto;
import com.example.investmentdatastreamservice.entity.MinuteCandleEntity;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * Mapper для конвертации между MinuteCandleEntity и MinuteCandleDto
 * 
 * Использует MapStruct для автоматической генерации кода маппинга.
 * Обеспечивает преобразование между слоями Entity и DTO.
 */
@Mapper(componentModel = "spring")
public interface MinuteCandleMapper {
    
    MinuteCandleMapper INSTANCE = Mappers.getMapper(MinuteCandleMapper.class);
    
    /**
     * Конвертирует Entity в DTO
     * 
     * @param entity сущность минутной свечи
     * @return DTO минутной свечи
     */
    @org.mapstruct.Mapping(target = "isComplete", source = "complete")
    MinuteCandleDto toDto(MinuteCandleEntity entity);
    
    /**
     * Конвертирует DTO в Entity
     * 
     * @param dto DTO минутной свечи
     * @return сущность минутной свечи
     */
    MinuteCandleEntity toEntity(MinuteCandleDto dto);
    
    /**
     * Конвертирует список Entity в список DTO
     * 
     * @param entities список сущностей минутных свечей
     * @return список DTO минутных свечей
     */
    List<MinuteCandleDto> toDtoList(List<MinuteCandleEntity> entities);
    
    /**
     * Конвертирует список DTO в список Entity
     * 
     * @param dtos список DTO минутных свечей
     * @return список сущностей минутных свечей
     */
    List<MinuteCandleEntity> toEntityList(List<MinuteCandleDto> dtos);
}
