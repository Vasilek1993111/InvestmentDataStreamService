package com.example.investmentdatastreamservice.entity;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Column;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Entity для исторических максимумов и минимумов цен
 * 
 * Представляет данные о исторических максимумах и минимумах цен для базы данных.
 * Содержит информацию о тикере, названии, валюте и других параметрах инструмента.
 */
@Entity
@Table(name = "historical_price_extremes", schema = "invest")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class HistoricalPricesEntity {
    @Id
    @Column(name = "figi", nullable = false)
    private String figi;
    @Column(name = "ticker", nullable = false)
    private String ticker;
    @Column(name = "instrument_type", nullable = false)
    private String instrumentType;
    @Column(name = "historical_high", nullable = false)
    private BigDecimal historicalHigh;
    @Column(name = "historical_high_date", nullable = false)
    private OffsetDateTime historicalHighDate;
    @Column(name = "historical_low", nullable = false)
    private BigDecimal historicalLow;
    @Column(name = "historical_low_date", nullable = false)
    private OffsetDateTime historicalLowDate;

}
