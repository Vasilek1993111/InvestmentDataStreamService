package com.example.investmentdatastreamservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Entity для хранения информации о фьючерсах
 * 
 * Представляет справочную информацию о торговых инструментах типа "фьючерс" с основными
 * характеристиками и связями.
 */
@Entity
@Table(name = "futures", schema = "invest")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FutureEntity {

    @Id
    @Column(name = "figi", nullable = false, length = 255)
    private String figi;

    @Column(name = "ticker", nullable = false, length = 255)
    private String ticker;

    @Column(name = "asset_type", nullable = false, length = 255)
    private String assetType;

    @Column(name = "basic_asset", length = 255)
    private String basicAsset;

    @Column(name = "currency", nullable = false, length = 255)
    private String currency;

    @Column(name = "exchange", nullable = false, length = 255)
    private String exchange;

    @Column(name = "stock_ticker", length = 255)
    @JoinColumn(name = "stock_ticker", referencedColumnName = "ticker")
    private String stockTicker;
}
