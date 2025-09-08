package com.example.investmentdatastreamservice.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Entity для хранения котировок и обезличенных сделок
 * 
 * Представляет поток котировок и обезличенных сделок с составным ключом (FIGI + время +
 * направление) для максимальной производительности и минимальной задержки при обработке.
 * 
 * Оптимизировано для высокочастотной обработки данных от T-Invest API.
 */
@Entity
@Table(name = "trades", schema = "invest")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TradeEntity {

    @EmbeddedId
    private TradeKey id;

    @Column(nullable = false, precision = 18, scale = 9)
    private BigDecimal price;

    @Column(nullable = false)
    private Long quantity;

    @Column(nullable = false, length = 10)
    private String currency;

    @Column(nullable = false, length = 50)
    private String exchange;

    @Column(length = 20)
    private String tradeSource;

    @Column(length = 20)
    private String tradeDirection;

    /**
     * Конструктор для удобного создания entity из Trade объекта
     * 
     * @param figi идентификатор финансового инструмента
     * @param time время совершения сделки
     * @param direction направление сделки (BUY/SELL)
     * @param price цена сделки
     * @param quantity количество
     * @param currency валюта
     * @param exchange биржа
     * @param tradeSource источник сделки
     */
    public TradeEntity(String figi, LocalDateTime time, String direction, BigDecimal price,
            Long quantity, String currency, String exchange, String tradeSource) {
        this.id = new TradeKey(figi, time, direction);
        this.price = price;
        this.quantity = quantity;
        this.currency = currency;
        this.exchange = exchange;
        this.tradeSource = tradeSource;
        this.tradeDirection = direction;
    }
}
