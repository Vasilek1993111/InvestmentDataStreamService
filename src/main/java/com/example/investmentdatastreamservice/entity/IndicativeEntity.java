package com.example.investmentdatastreamservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Entity для хранения информации об индикативных инструментах
 * 
 * Представляет справочную информацию о торговых инструментах типа "индикативный" (индексы, товары и
 * другие) с основными характеристиками.
 */
@Entity
@Table(name = "indicatives", schema = "invest")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class IndicativeEntity {

    @Id
    @Column(name = "figi", nullable = false, length = 255)
    private String figi;

    @Column(name = "buy_available_flag")
    private Boolean buyAvailableFlag;

    @Column(name = "class_code", length = 255)
    private String classCode;

    @Column(name = "currency", length = 255)
    private String currency;

    @Column(name = "exchange", length = 255)
    private String exchange;

    @Column(name = "name", length = 255)
    private String name;

    @Column(name = "sell_available_flag")
    private Boolean sellAvailableFlag;

    @Column(name = "ticker", length = 255)
    private String ticker;

    @Column(name = "uid", length = 255)
    private String uid;
}
