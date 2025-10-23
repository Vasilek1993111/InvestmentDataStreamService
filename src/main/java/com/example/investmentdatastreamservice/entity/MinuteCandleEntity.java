package com.example.investmentdatastreamservice.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;


@Entity
@Table(name = "minute_candles", schema = "invest")
@IdClass(MinuteCandleKey.class)
public class MinuteCandleEntity {
    
    @Id
    @Column(name = "figi", nullable = false)
    private String figi;
    
    @Column(name = "volume", nullable = false)
    private long volume;
    
    @Column(name = "high", nullable = false, precision = 18, scale = 9)
    private BigDecimal high;
    
    @Column(name = "low", nullable = false, precision = 18, scale = 9)
    private BigDecimal low;
    
    @Id
    @Column(name = "time", nullable = false)
    private Instant time;
    
    @Column(name = "close", nullable = false, precision = 18, scale = 9)
    private BigDecimal close;
    
    @Column(name = "open", nullable = false, precision = 18, scale = 9)
    private BigDecimal open;
    
    @Column(name = "is_complete", nullable = false)
    private boolean isComplete;
    
    // Расширенная статистика
    @Column(name = "price_change", precision = 18, scale = 9)
    private BigDecimal priceChange;
    
    @Column(name = "price_change_percent", precision = 18, scale = 4)
    private BigDecimal priceChangePercent;
    
    @Column(name = "candle_type", length = 20)
    private String candleType;
    
    @Column(name = "body_size", precision = 18, scale = 9)
    private BigDecimal bodySize;
    
    @Column(name = "upper_shadow", precision = 18, scale = 9)
    private BigDecimal upperShadow;
    
    @Column(name = "lower_shadow", precision = 18, scale = 9)
    private BigDecimal lowerShadow;
    
    @Column(name = "high_low_range", precision = 18, scale = 9)
    private BigDecimal highLowRange;
    
    @Column(name = "average_price", precision = 18, scale = 2)
    private BigDecimal averagePrice;
    
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public MinuteCandleEntity() {
        this.createdAt = ZonedDateTime.now(ZoneId.of("Europe/Moscow")).toInstant();
        this.updatedAt = ZonedDateTime.now(ZoneId.of("Europe/Moscow")).toInstant();
    }

    public MinuteCandleEntity(String figi, long volume, BigDecimal high, BigDecimal low, 
                             Instant time, BigDecimal close, BigDecimal open, boolean isComplete) {
        this();
        this.figi = figi;
        this.volume = volume;
        this.high = high;
        this.low = low;
        // Конвертируем время в московское время (UTC+3)
        this.time = convertToMoscowTime(time);
        this.close = close;
        this.open = open;
        this.isComplete = isComplete;
        
        // Вычисляем расширенную статистику
        calculateExtendedStatistics();
    }
    
    /**
     * Вычисляет расширенную статистику для свечи
     */
    public void calculateExtendedStatistics() {
        if (open != null && close != null && high != null && low != null) {
            this.priceChange = close.subtract(open);
            this.priceChangePercent = open.compareTo(BigDecimal.ZERO) > 0 
                ? priceChange.divide(open, 4, java.math.RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100))
                : BigDecimal.ZERO;
            
            this.candleType = close.compareTo(open) > 0 ? "BULLISH" : 
                             close.compareTo(open) < 0 ? "BEARISH" : "DOJI";
            
            this.bodySize = priceChange.abs();
            this.upperShadow = high.subtract(close.max(open));
            this.lowerShadow = open.min(close).subtract(low);
            this.highLowRange = high.subtract(low);
            this.averagePrice = high.add(low).add(open).add(close).divide(BigDecimal.valueOf(4), 2, java.math.RoundingMode.HALF_UP);
        }
    }
    
    /**
     * Конвертирует время в московское время (UTC+3)
     * Время от T-Bank API приходит в UTC, мы сохраняем его в московской временной зоне
     */
    private Instant convertToMoscowTime(Instant time) {
        if (time == null) {
            return null;
        }
        // Время от API в UTC, конвертируем в московское время
        ZonedDateTime utcTime = time.atZone(ZoneId.of("UTC"));
        ZonedDateTime moscowTime = utcTime.withZoneSameInstant(ZoneId.of("Europe/Moscow"));
        return moscowTime.toInstant();
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = ZonedDateTime.now(ZoneId.of("Europe/Moscow")).toInstant();
    }

    // Getters and Setters
    public String getFigi() { return figi; }
    public void setFigi(String figi) { this.figi = figi; }

    public long getVolume() { return volume; }
    public void setVolume(long volume) { this.volume = volume; }

    public BigDecimal getHigh() { return high; }
    public void setHigh(BigDecimal high) { this.high = high; }

    public BigDecimal getLow() { return low; }
    public void setLow(BigDecimal low) { this.low = low; }

    public Instant getTime() { return time; }
    public void setTime(Instant time) { this.time = convertToMoscowTime(time); }

    public BigDecimal getClose() { return close; }
    public void setClose(BigDecimal close) { this.close = close; }

    public BigDecimal getOpen() { return open; }
    public void setOpen(BigDecimal open) { this.open = open; }

    public boolean isComplete() { return isComplete; }
    public void setComplete(boolean complete) { isComplete = complete; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }

    // Getters and Setters for extended statistics
    public BigDecimal getPriceChange() { return priceChange; }
    public void setPriceChange(BigDecimal priceChange) { this.priceChange = priceChange; }

    public BigDecimal getPriceChangePercent() { return priceChangePercent; }
    public void setPriceChangePercent(BigDecimal priceChangePercent) { this.priceChangePercent = priceChangePercent; }

    public String getCandleType() { return candleType; }
    public void setCandleType(String candleType) { this.candleType = candleType; }

    public BigDecimal getBodySize() { return bodySize; }
    public void setBodySize(BigDecimal bodySize) { this.bodySize = bodySize; }

    public BigDecimal getUpperShadow() { return upperShadow; }
    public void setUpperShadow(BigDecimal upperShadow) { this.upperShadow = upperShadow; }

    public BigDecimal getLowerShadow() { return lowerShadow; }
    public void setLowerShadow(BigDecimal lowerShadow) { this.lowerShadow = lowerShadow; }

    public BigDecimal getHighLowRange() { return highLowRange; }
    public void setHighLowRange(BigDecimal highLowRange) { this.highLowRange = highLowRange; }

    public BigDecimal getAveragePrice() { return averagePrice; }
    public void setAveragePrice(BigDecimal averagePrice) { this.averagePrice = averagePrice; }
}
