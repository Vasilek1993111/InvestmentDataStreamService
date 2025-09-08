package com.example.investmentdatastreamservice.repository;

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
 * Высокопроизводительный batch repository для котировок и сделок
 * 
 * Предоставляет оптимизированные методы для массовой вставки и обновления данных в таблицу trades с
 * минимальной задержкой и максимальной пропускной способностью.
 */
@Repository
public interface TradeBatchRepository extends JpaRepository<TradeEntity, TradeKey> {

        /**
         * Высокопроизводительная batch вставка с использованием UPSERT
         * 
         * @param trades список сделок для вставки/обновления
         */
        @Modifying
        @Transactional
        @Query(value = """
                        INSERT INTO invest.trades (figi, time, direction, price, quantity, currency, exchange, trade_source, trade_direction)
                        VALUES (:#{#trades[0].id.figi}, :#{#trades[0].id.time}, :#{#trades[0].id.direction},
                                :#{#trades[0].price}, :#{#trades[0].quantity}, :#{#trades[0].currency},
                                :#{#trades[0].exchange}, :#{#trades[0].tradeSource}, :#{#trades[0].tradeDirection})
                        ON CONFLICT (figi, time, direction)
                        DO UPDATE SET
                            price = EXCLUDED.price,
                            quantity = EXCLUDED.quantity,
                            currency = EXCLUDED.currency,
                            exchange = EXCLUDED.exchange,
                            trade_source = EXCLUDED.trade_source,
                            trade_direction = EXCLUDED.trade_direction
                        """,
                        nativeQuery = true)
        void upsertBatch(@Param("trades") List<TradeEntity> trades);

        /**
         * Высокопроизводительная batch вставка без конфликтов
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
         * Высокопроизводительная batch вставка с игнорированием дубликатов
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
                        ON CONFLICT (figi, time, direction) DO NOTHING
                        """,
                        nativeQuery = true)
        void insertBatchIgnoreDuplicates(@Param("trades") List<TradeEntity> trades);
}
