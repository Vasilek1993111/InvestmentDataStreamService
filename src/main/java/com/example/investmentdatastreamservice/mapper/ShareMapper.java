package com.example.investmentdatastreamservice.mapper;

import com.example.investmentdatastreamservice.dto.ShareDto;
import com.example.investmentdatastreamservice.entity.ShareEntity;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * Mapper для конвертации между ShareEntity и ShareDto
 * 
 * Использует MapStruct для автоматической генерации кода маппинга.
 * Обеспечивает преобразование между слоями Entity и DTO.
 */
@Mapper(componentModel = "spring")
public interface ShareMapper {
    
    ShareMapper INSTANCE = Mappers.getMapper(ShareMapper.class);
    
    /**
     * Конвертирует Entity в DTO
     * 
     * @param entity сущность акции
     * @return DTO акции
     */
    ShareDto toDto(ShareEntity entity);
    
    /**
     * Конвертирует DTO в Entity
     * 
     * @param dto DTO акции
     * @return сущность акции
     */
    ShareEntity toEntity(ShareDto dto);
    
    /**
     * Конвертирует список Entity в список DTO
     * 
     * @param entities список сущностей акций
     * @return список DTO акций
     */
    List<ShareDto> toDtoList(List<ShareEntity> entities);
    
    /**
     * Конвертирует список DTO в список Entity
     * 
     * @param dtos список DTO акций
     * @return список сущностей акций
     */
    List<ShareEntity> toEntityList(List<ShareDto> dtos);
}
