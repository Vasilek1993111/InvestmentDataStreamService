package com.example.investmentdatastreamservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Entity для хранения информации об акциях
 * 
 * Представляет справочную информацию о торговых инструментах типа "акция" с основными
 * характеристиками.
 */
@Entity
@Table(name = "shares", schema = "invest")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ShareEntity {

    @Id
    @Column(nullable = false, length = 50)
    private String figi;

    @Column(nullable = false, length = 20)
    private String ticker;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, length = 10)
    private String currency;

    @Column(nullable = false, length = 50)
    private String exchange;
}
