package com.example.investmentdatastreamservice.repository;

import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import com.example.investmentdatastreamservice.entity.TradeEntity;
import com.example.investmentdatastreamservice.entity.TradeKey;

/**
 * Repository для работы с обезличенными сделками (Trade)
 * 
 * Предоставляет высокопроизводительные методы для работы с потоком обезличенных сделок, включая
 * batch операции для минимальной задержки и максимальной пропускной способности.
 */
@Repository
public interface TradeRepository extends JpaRepository<TradeEntity, TradeKey> {

    /**
     * Высокопроизводительная batch вставка обезличенных сделок
     * 
     * @param trades список сделок для вставки
     */
    @Modifying
    @Transactional
    @Query(value = """
            INSERT INTO invest.trades (figi, time, direction, price, quantity, currency, exchange, trade_source, trade_direction)
            VALUES (:#{#trades[0].id.figi}, :#{#trades[0].id.time}, :#{#trades[0].id.direction},
                    :#{#trades[0].price}, :#{#trades[0].quantity}, :#{#trades[0].currency},
                    :#{#trades[0].exchange}, :#{#trades[0].tradeSource}, :#{#trades[0].tradeDirection})
            """,
            nativeQuery = true)
    void insertBatch(@Param("trades") List<TradeEntity> trades);

    /**
     * Найти сделки по временному диапазону
     * 
     * @param from начальное время
     * @param to конечное время
     * @return список сделок, отсортированный по времени (новые первые)
     */
    @Query("SELECT t FROM TradeEntity t WHERE t.id.time BETWEEN :from AND :to ORDER BY t.id.time DESC")
    List<TradeEntity> findByTimeBetween(@Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);

    /**
     * Найти сделки по FIGI инструмента
     * 
     * @param figi идентификатор инструмента
     * @return список сделок, отсортированный по времени (новые первые)
     */
    @Query("SELECT t FROM TradeEntity t WHERE t.id.figi = :figi ORDER BY t.id.time DESC")
    List<TradeEntity> findByFigiOrderByTimeDesc(@Param("figi") String figi);

    /**
     * Найти сделки по FIGI и направлению
     * 
     * @param figi идентификатор инструмента
     * @param direction направление сделки (BUY/SELL)
     * @return список сделок, отсортированный по времени (новые первые)
     */
    @Query("SELECT t FROM TradeEntity t WHERE t.id.figi = :figi AND t.id.direction = :direction ORDER BY t.id.time DESC")
    List<TradeEntity> findByFigiAndDirectionOrderByTimeDesc(@Param("figi") String figi,
            @Param("direction") String direction);

    /**
     * Подсчитать количество сделок в временном диапазоне
     * 
     * @param from начальное время
     * @param to конечное время
     * @return количество сделок
     */
    @Query("SELECT COUNT(t) FROM TradeEntity t WHERE t.id.time BETWEEN :from AND :to")
    Long countByTimeBetween(@Param("from") LocalDateTime from, @Param("to") LocalDateTime to);

    /**
     * Подсчитать количество сделок по FIGI в временном диапазоне
     * 
     * @param figi идентификатор инструмента
     * @param from начальное время
     * @param to конечное время
     * @return количество сделок
     */
    @Query("SELECT COUNT(t) FROM TradeEntity t WHERE t.id.figi = :figi AND t.id.time BETWEEN :from AND :to")
    Long countByFigiAndTimeBetween(@Param("figi") String figi, @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);

    /**
     * Получить среднюю цену сделок по FIGI в временном диапазоне
     * 
     * @param figi идентификатор инструмента
     * @param from начальное время
     * @param to конечное время
     * @return средняя цена
     */
    @Query("SELECT AVG(t.price) FROM TradeEntity t WHERE t.id.figi = :figi AND t.id.time BETWEEN :from AND :to")
    Double getAveragePriceByFigiAndTimeBetween(@Param("figi") String figi,
            @Param("from") LocalDateTime from, @Param("to") LocalDateTime to);

    /**
     * Получить общий объем сделок по FIGI в временном диапазоне
     * 
     * @param figi идентификатор инструмента
     * @param from начальное время
     * @param to конечное время
     * @return общий объем
     */
    @Query("SELECT SUM(t.quantity) FROM TradeEntity t WHERE t.id.figi = :figi AND t.id.time BETWEEN :from AND :to")
    Long getTotalVolumeByFigiAndTimeBetween(@Param("figi") String figi,
            @Param("from") LocalDateTime from, @Param("to") LocalDateTime to);
}
