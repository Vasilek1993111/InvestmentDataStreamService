package com.example.investmentdatastreamservice.repository;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import com.example.investmentdatastreamservice.entity.IndicativeEntity;

/**
 * Repository для работы с индикативными инструментами
 * 
 * Предоставляет методы для поиска и получения информации о торговых инструментах типа
 * "индикативный" (индексы, товары и другие).
 */
public interface IndicativeRepository extends JpaRepository<IndicativeEntity, String> {

    /**
     * Возвращает все уникальные FIGI из таблицы индикативных инструментов
     * 
     * @return список уникальных FIGI индикативных инструментов
     */
    @Query("SELECT DISTINCT i.figi FROM IndicativeEntity i")
    List<String> findAllDistinctFigi();

    /**
     * Находит индикативный инструмент по тикеру
     * 
     * @param ticker тикер инструмента
     * @return индикативный инструмент или null, если не найден
     */
    IndicativeEntity findByTicker(String ticker);

    /**
     * Находит индикативные инструменты по бирже
     * 
     * @param exchange биржа
     * @return список индикативных инструментов
     */
    List<IndicativeEntity> findByExchange(String exchange);

    /**
     * Находит индикативные инструменты по валюте
     * 
     * @param currency валюта
     * @return список индикативных инструментов
     */
    List<IndicativeEntity> findByCurrency(String currency);

    /**
     * Находит доступные для покупки индикативные инструменты
     * 
     * @return список доступных для покупки индикативных инструментов
     */
    @Query("SELECT i FROM IndicativeEntity i WHERE i.buyAvailableFlag = true")
    List<IndicativeEntity> findAvailableForBuy();

    /**
     * Находит доступные для продажи индикативные инструменты
     * 
     * @return список доступных для продажи индикативных инструментов
     */
    @Query("SELECT i FROM IndicativeEntity i WHERE i.sellAvailableFlag = true")
    List<IndicativeEntity> findAvailableForSell();
}
