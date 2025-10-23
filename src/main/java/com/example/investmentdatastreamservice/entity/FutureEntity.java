package com.example.investmentdatastreamservice.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.example.investmentdatastreamservice.utils.TimeZoneUtils;

@Entity
@Table(name = "futures", schema = "invest")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FutureEntity {
    @Id
    private String figi;
    
    @Column(name = "ticker", nullable = false)
    private String ticker;
    
    @Column(name = "asset_type", nullable = false)
    private String assetType;
    
    @Column(name = "basic_asset", nullable = false)
    private String basicAsset;
    
    @Column(name = "currency", nullable = false)
    private String currency;
    
    @Column(name = "exchange", nullable = false)
    private String exchange;
    
    @Column(name = "short_enabled")
    private Boolean shortEnabled;
    
    @Column(name = "expiration_date")
    private LocalDateTime expirationDate;
    
    @Column(name = "min_price_increment")
    private BigDecimal minPriceIncrement;
    
    @Column(name = "lot")
    private Integer lot;
    
    @Column(name = "basic_asset_size", precision = 18, scale = 9)
    private BigDecimal basicAssetSize;
    
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now(TimeZoneUtils.getMoscowZone());
    
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now(TimeZoneUtils.getMoscowZone());

    public FutureEntity(String figi, String ticker, String assetType, String basicAsset, 
                       String currency, String exchange, Boolean shortEnabled, LocalDateTime expirationDate, BigDecimal minPriceIncrement, Integer lot, BigDecimal basicAssetSize) {
        this.figi = figi;
        this.ticker = ticker;
        this.assetType = assetType;
        this.basicAsset = basicAsset;
        this.currency = currency;
        this.exchange = exchange;
        this.shortEnabled = shortEnabled;
        this.expirationDate = expirationDate;
        this.minPriceIncrement = minPriceIncrement;
        this.lot = lot;
        this.basicAssetSize = basicAssetSize;
        this.createdAt = LocalDateTime.now(TimeZoneUtils.getMoscowZone());
        this.updatedAt = LocalDateTime.now(TimeZoneUtils.getMoscowZone());
    }


    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now(TimeZoneUtils.getMoscowZone());
    }
}
