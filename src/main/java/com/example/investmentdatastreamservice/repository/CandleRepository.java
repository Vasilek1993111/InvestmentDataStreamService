package com.example.investmentdatastreamservice.repository;

import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.example.investmentdatastreamservice.entity.CandleEntity;
import com.example.investmentdatastreamservice.entity.CandleKey;

/**
 * Repository для работы с минутными свечами
 * 
 * Предоставляет методы для поиска, сохранения и получения данных о минутных свечах торговых
 * инструментов.
 */
@Repository
public interface CandleRepository extends JpaRepository<CandleEntity, CandleKey> {

    /**
     * Находит свечи по FIGI инструмента
     * 
     * @param figi идентификатор инструмента
     * @return список свечей для указанного инструмента
     */
    List<CandleEntity> findByFigiOrderByTimeAsc(String figi);

    /**
     * Находит свечи по FIGI в указанном временном диапазоне
     * 
     * @param figi идентификатор инструмента
     * @param startTime начало периода
     * @param endTime конец периода
     * @return список свечей в указанном диапазоне
     */
    @Query("SELECT c FROM CandleEntity c WHERE c.figi = :figi AND c.time >= :startTime AND c.time <= :endTime ORDER BY c.time ASC")
    List<CandleEntity> findByFigiAndTimeBetween(@Param("figi") String figi,
            @Param("startTime") LocalDateTime startTime, @Param("endTime") LocalDateTime endTime);

    /**
     * Находит последнюю свечу для указанного инструмента
     * 
     * @param figi идентификатор инструмента
     * @return последняя свеча или null, если не найдена
     */
    @Query("SELECT c FROM CandleEntity c WHERE c.figi = :figi ORDER BY c.time DESC LIMIT 1")
    CandleEntity findLastCandleByFigi(@Param("figi") String figi);

    /**
     * Находит неполные свечи (is_complete = false)
     * 
     * @return список неполных свечей
     */
    @Query("SELECT c FROM CandleEntity c WHERE c.isComplete = false ORDER BY c.time ASC")
    List<CandleEntity> findIncompleteCandles();

    /**
     * Находит неполные свечи для указанного инструмента
     * 
     * @param figi идентификатор инструмента
     * @return список неполных свечей для указанного инструмента
     */
    @Query("SELECT c FROM CandleEntity c WHERE c.figi = :figi AND c.isComplete = false ORDER BY c.time ASC")
    List<CandleEntity> findIncompleteCandlesByFigi(@Param("figi") String figi);

    /**
     * Обновляет свечу как завершенную
     * 
     * @param figi идентификатор инструмента
     * @param time время свечи
     */
    @Modifying
    @Query("UPDATE CandleEntity c SET c.isComplete = true, c.updatedAt = CURRENT_TIMESTAMP WHERE c.figi = :figi AND c.time = :time")
    void markCandleAsComplete(@Param("figi") String figi, @Param("time") LocalDateTime time);

    /**
     * Удаляет старые свечи (старше указанной даты)
     * 
     * @param beforeDate дата, до которой удалять свечи
     * @return количество удаленных записей
     */
    @Modifying
    @Query("DELETE FROM CandleEntity c WHERE c.time < :beforeDate")
    int deleteOldCandles(@Param("beforeDate") LocalDateTime beforeDate);

    /**
     * Подсчитывает количество свечей для указанного инструмента
     * 
     * @param figi идентификатор инструмента
     * @return количество свечей
     */
    long countByFigi(String figi);

    /**
     * Подсчитывает количество свечей в указанном временном диапазоне
     * 
     * @param startTime начало периода
     * @param endTime конец периода
     * @return количество свечей в диапазоне
     */
    @Query("SELECT COUNT(c) FROM CandleEntity c WHERE c.time >= :startTime AND c.time <= :endTime")
    long countByTimeBetween(@Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);
}
