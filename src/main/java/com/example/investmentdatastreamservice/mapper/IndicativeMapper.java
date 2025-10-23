package com.example.investmentdatastreamservice.mapper;

import com.example.investmentdatastreamservice.dto.IndicativeDto;
import com.example.investmentdatastreamservice.entity.IndicativeEntity;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * Mapper для конвертации между IndicativeEntity и IndicativeDto
 * 
 * Использует MapStruct для автоматической генерации кода маппинга.
 * Обеспечивает преобразование между слоями Entity и DTO.
 */
@Mapper(componentModel = "spring")
public interface IndicativeMapper {
    
    IndicativeMapper INSTANCE = Mappers.getMapper(IndicativeMapper.class);
    
    /**
     * Конвертирует Entity в DTO
     * 
     * @param entity сущность индикативного инструмента
     * @return DTO индикативного инструмента
     */
    IndicativeDto toDto(IndicativeEntity entity);
    
    /**
     * Конвертирует DTO в Entity
     * 
     * @param dto DTO индикативного инструмента
     * @return сущность индикативного инструмента
     */
    IndicativeEntity toEntity(IndicativeDto dto);
    
    /**
     * Конвертирует список Entity в список DTO
     * 
     * @param entities список сущностей индикативных котировок
     * @return список DTO индикативных котировок
     */
    List<IndicativeDto> toDtoList(List<IndicativeEntity> entities);
    
    /**
     * Конвертирует список DTO в список Entity
     * 
     * @param dtos список DTO индикативных котировок
     * @return список сущностей индикативных котировок
     */
    List<IndicativeEntity> toEntityList(List<IndicativeDto> dtos);
}
