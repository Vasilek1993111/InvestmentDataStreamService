package com.example.investmentdatastreamservice.mapper;

import com.example.investmentdatastreamservice.dto.FutureDto;
import com.example.investmentdatastreamservice.entity.FutureEntity;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * Mapper для конвертации между FutureEntity и FutureDto
 * 
 * Использует MapStruct для автоматической генерации кода маппинга.
 * Обеспечивает преобразование между слоями Entity и DTO.
 */
@Mapper(componentModel = "spring")
public interface FutureMapper {
    
    FutureMapper INSTANCE = Mappers.getMapper(FutureMapper.class);
    
    /**
     * Конвертирует Entity в DTO
     * 
     * @param entity сущность фьючерса
     * @return DTO фьючерса
     */
    FutureDto toDto(FutureEntity entity);
    
    /**
     * Конвертирует DTO в Entity
     * 
     * @param dto DTO фьючерса
     * @return сущность фьючерса
     */
    FutureEntity toEntity(FutureDto dto);
    
    /**
     * Конвертирует список Entity в список DTO
     * 
     * @param entities список сущностей фьючерсов
     * @return список DTO фьючерсов
     */
    List<FutureDto> toDtoList(List<FutureEntity> entities);
    
    /**
     * Конвертирует список DTO в список Entity
     * 
     * @param dtos список DTO фьючерсов
     * @return список сущностей фьючерсов
     */
    List<FutureEntity> toEntityList(List<FutureDto> dtos);
}