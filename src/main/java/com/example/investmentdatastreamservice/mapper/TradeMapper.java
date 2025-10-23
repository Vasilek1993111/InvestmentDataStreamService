package com.example.investmentdatastreamservice.mapper;

import com.example.investmentdatastreamservice.dto.TradeDto;
import com.example.investmentdatastreamservice.entity.TradeEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * Mapper для конвертации между TradeEntity и TradeDto
 * 
 * Использует MapStruct для автоматической генерации кода маппинга.
 * Обеспечивает преобразование между слоями Entity и DTO.
 */
@Mapper(componentModel = "spring")
public interface TradeMapper {
    
    TradeMapper INSTANCE = Mappers.getMapper(TradeMapper.class);
    
    /**
     * Конвертирует Entity в DTO
     * 
     * @param entity сущность сделки
     * @return DTO сделки
     */
    @Mapping(source = "id.figi", target = "figi")
    @Mapping(source = "id.time", target = "time")
    @Mapping(source = "id.direction", target = "direction")
    TradeDto toDto(TradeEntity entity);
    
    /**
     * Конвертирует DTO в Entity
     * 
     * @param dto DTO сделки
     * @return сущность сделки
     */
    @Mapping(source = "figi", target = "id.figi")
    @Mapping(source = "time", target = "id.time")
    @Mapping(source = "direction", target = "id.direction")
    TradeEntity toEntity(TradeDto dto);
    
    /**
     * Конвертирует список Entity в список DTO
     * 
     * @param entities список сущностей сделок
     * @return список DTO сделок
     */
    List<TradeDto> toDtoList(List<TradeEntity> entities);
    
    /**
     * Конвертирует список DTO в список Entity
     * 
     * @param dtos список DTO сделок
     * @return список сущностей сделок
     */
    List<TradeEntity> toEntityList(List<TradeDto> dtos);
}
