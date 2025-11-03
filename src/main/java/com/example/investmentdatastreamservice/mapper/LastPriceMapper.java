package com.example.investmentdatastreamservice.mapper;

import com.example.investmentdatastreamservice.dto.LastPriceDto;
import com.example.investmentdatastreamservice.entity.LastPriceEntity;
import com.example.investmentdatastreamservice.entity.LastPriceKey;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

import java.util.List;

/**
 * Mapper для конвертации между LastPriceEntity и LastPriceDto
 * 
 * Использует MapStruct для автоматической генерации кода маппинга.
 * Обеспечивает преобразование между слоями Entity и DTO.
 */
@Mapper(componentModel = "spring")
public interface LastPriceMapper {
    
    LastPriceMapper INSTANCE = Mappers.getMapper(LastPriceMapper.class);
    
    /**
     * Конвертирует Entity в DTO
     * 
     * @param entity сущность последней цены
     * @return DTO последней цены
     */
    @Mapping(source = "id.figi", target = "figi")
    @Mapping(source = "id.time", target = "time")
    LastPriceDto toDto(LastPriceEntity entity);
    
    /**
     * Конвертирует DTO в Entity
     * 
     * @param dto DTO последней цены
     * @return сущность последней цены
     */
    default LastPriceEntity toEntity(LastPriceDto dto) {
        if (dto == null) {
            return null;
        }
        LastPriceEntity entity = new LastPriceEntity();
        entity.setId(new LastPriceKey(dto.getFigi(), dto.getTime()));
        entity.setPrice(dto.getPrice());
        entity.setCurrency(dto.getCurrency());
        entity.setExchange(dto.getExchange());
        return entity;
    }
    
    /**
     * Конвертирует список Entity в список DTO
     * 
     * @param entities список сущностей последних цен
     * @return список DTO последних цен
     */
    List<LastPriceDto> toDtoList(List<LastPriceEntity> entities);
    
    /**
     * Конвертирует список DTO в список Entity
     * 
     * @param dtos список DTO последних цен
     * @return список сущностей последних цен
     */
    default List<LastPriceEntity> toEntityList(List<LastPriceDto> dtos) {
        if (dtos == null) {
            return null;
        }
        return dtos.stream().map(this::toEntity).toList();
    }
}

