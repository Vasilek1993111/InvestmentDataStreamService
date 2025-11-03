package com.example.investmentdatastreamservice.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.investmentdatastreamservice.entity.LastPriceEntity;
import com.example.investmentdatastreamservice.entity.LastPriceKey;

/**
 * Repository для работы с ценами последних сделок (LastPrice)
 * 
 * Предоставляет методы для работы с потоком цен последних сделок,
 * включая поиск по временным диапазонам и инструментам.
 */
@Repository
public interface LastPriceRepository extends JpaRepository<LastPriceEntity, LastPriceKey> {

    /**
     * Найти последнюю цену по FIGI инструмента
     * 
     * @param figi идентификатор инструмента
     * @return последняя цена или empty, если не найдена
     */
    @Query("SELECT lp FROM LastPriceEntity lp WHERE lp.id.figi = :figi ORDER BY lp.id.time DESC LIMIT 1")
    Optional<LastPriceEntity> findLastByFigi(@Param("figi") String figi);

    /**
     * Найти цены по временному диапазону
     * 
     * @param from начальное время
     * @param to конечное время
     * @return список цен, отсортированный по времени (новые первые)
     */
    @Query("SELECT lp FROM LastPriceEntity lp WHERE lp.id.time BETWEEN :from AND :to ORDER BY lp.id.time DESC")
    List<LastPriceEntity> findByTimeBetween(@Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);

    /**
     * Найти цены по FIGI инструмента
     * 
     * @param figi идентификатор инструмента
     * @return список цен, отсортированный по времени (новые первые)
     */
    @Query("SELECT lp FROM LastPriceEntity lp WHERE lp.id.figi = :figi ORDER BY lp.id.time DESC")
    List<LastPriceEntity> findByFigiOrderByTimeDesc(@Param("figi") String figi);

    /**
     * Найти цены по FIGI в указанном временном диапазоне
     * 
     * @param figi идентификатор инструмента
     * @param from начальное время
     * @param to конечное время
     * @return список цен в указанном диапазоне
     */
    @Query("SELECT lp FROM LastPriceEntity lp WHERE lp.id.figi = :figi AND lp.id.time BETWEEN :from AND :to ORDER BY lp.id.time DESC")
    List<LastPriceEntity> findByFigiAndTimeBetween(@Param("figi") String figi,
            @Param("from") LocalDateTime from, @Param("to") LocalDateTime to);

    /**
     * Подсчитать количество цен в временном диапазоне
     * 
     * @param from начальное время
     * @param to конечное время
     * @return количество записей
     */
    @Query("SELECT COUNT(lp) FROM LastPriceEntity lp WHERE lp.id.time BETWEEN :from AND :to")
    Long countByTimeBetween(@Param("from") LocalDateTime from, @Param("to") LocalDateTime to);

    /**
     * Подсчитать количество цен по FIGI в временном диапазоне
     * 
     * @param figi идентификатор инструмента
     * @param from начальное время
     * @param to конечное время
     * @return количество записей
     */
    @Query("SELECT COUNT(lp) FROM LastPriceEntity lp WHERE lp.id.figi = :figi AND lp.id.time BETWEEN :from AND :to")
    Long countByFigiAndTimeBetween(@Param("figi") String figi, @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);

    /**
     * Получить среднюю цену по FIGI в временном диапазоне
     * 
     * @param figi идентификатор инструмента
     * @param from начальное время
     * @param to конечное время
     * @return средняя цена
     */
    @Query("SELECT AVG(lp.price) FROM LastPriceEntity lp WHERE lp.id.figi = :figi AND lp.id.time BETWEEN :from AND :to")
    Double getAveragePriceByFigiAndTimeBetween(@Param("figi") String figi,
            @Param("from") LocalDateTime from, @Param("to") LocalDateTime to);

    /**
     * Получить минимальную цену по FIGI в временном диапазоне
     * 
     * @param figi идентификатор инструмента
     * @param from начальное время
     * @param to конечное время
     * @return минимальная цена
     */
    @Query("SELECT MIN(lp.price) FROM LastPriceEntity lp WHERE lp.id.figi = :figi AND lp.id.time BETWEEN :from AND :to")
    java.math.BigDecimal getMinPriceByFigiAndTimeBetween(@Param("figi") String figi,
            @Param("from") LocalDateTime from, @Param("to") LocalDateTime to);

    /**
     * Получить максимальную цену по FIGI в временном диапазоне
     * 
     * @param figi идентификатор инструмента
     * @param from начальное время
     * @param to конечное время
     * @return максимальная цена
     */
    @Query("SELECT MAX(lp.price) FROM LastPriceEntity lp WHERE lp.id.figi = :figi AND lp.id.time BETWEEN :from AND :to")
    java.math.BigDecimal getMaxPriceByFigiAndTimeBetween(@Param("figi") String figi,
            @Param("from") LocalDateTime from, @Param("to") LocalDateTime to);
}

