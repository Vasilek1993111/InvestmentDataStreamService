package com.example.investmentdatastreamservice.service;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import com.example.investmentdatastreamservice.dto.HistoricalPriceDto;
import com.example.investmentdatastreamservice.mapper.HistoricalPriceMapper;
import com.example.investmentdatastreamservice.repository.HistoricalPriceRepository;

/**
 * Сервис для работы с историческими максимумами и минимумами цен
 * 
 * Предоставляет методы для работы с историческими максимумами и минимумами цен.
 * Использует кэширование для оптимизации производительности.
 */
@Service
public class HistoricalPricesService {
    private static final Logger logger = LoggerFactory.getLogger(HistoricalPricesService.class);
    private final HistoricalPriceRepository historicalPriceRepository;

    public HistoricalPricesService(HistoricalPriceRepository historicalPriceRepository) {       
        this.historicalPriceRepository = historicalPriceRepository;
    }

    /**
     * Получить все исторические цены из кэша
     * 
     * При первом вызове загружает данные из БД и сохраняет в кэш.
     * При последующих вызовах возвращает данные из кэша.
     * TTL кэша: 24 часа.
     * 
     * @return список всех исторических цен
     */
    @Cacheable(value = "historicalPricesCache", key = "'all'")
    public List<HistoricalPriceDto> getAllHistoricalPrices() {
        logger.info("Загрузка всех исторических цен из БД");
        return historicalPriceRepository.findAll().stream().
                                            map(HistoricalPriceMapper.INSTANCE::toDto).toList();
    }
    
    /**
     * Получить историческую цену по FIGI из кэша
     * 
     * При первом вызове загружает данные из БД и сохраняет в кэш.
     * При последующих вызовах возвращает данные из кэша.
     * TTL кэша: 24 часа.
     * 
     * @param figi FIGI инструмента
     * @return историческая цена или null если не найдена
     */
    @Cacheable(value = "historicalPricesCache", key = "#figi")
    public HistoricalPriceDto getHistoricalPriceByFigi(String figi){
        logger.debug("Загрузка исторической цены для FIGI: {} из БД", figi);
        return HistoricalPriceMapper.INSTANCE.toDto(historicalPriceRepository.findById(figi).orElse(null));
    }
  
}
