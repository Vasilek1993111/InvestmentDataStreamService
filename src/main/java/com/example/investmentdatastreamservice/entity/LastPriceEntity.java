package com.example.investmentdatastreamservice.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "last_prices", schema = "invest")
public class LastPriceEntity {
    @EmbeddedId
    private LastPriceKey id;
    @Column(nullable = false, precision = 18, scale = 9)
    private BigDecimal price;
    private String currency;
    private String exchange;

    public LastPriceEntity() {}

    public LastPriceEntity(String figi, LocalDateTime time, BigDecimal price,
                           String currency, String exchange) {
        // Сохраняем время как есть, без конвертации
        this.id = new LastPriceKey(figi, time);
        this.price = price;
        this.currency = currency;
        this.exchange = exchange;
    }
    // getters/setters
    public LastPriceKey getId() {
        return id;
    }

    public void setId(LastPriceKey id) {
        this.id = id;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }

    public String getCurrency() {
        return currency;
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public String getExchange() {
        return exchange;
    }

    public void setExchange(String exchange) {
        this.exchange = exchange;
    }
}

