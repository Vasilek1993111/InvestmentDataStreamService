package com.example.investmentdatastreamservice.entity;

import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.Objects;

@Embeddable
public class LastPriceKey implements Serializable {
    private String figi;
    private LocalDateTime time;

    // Конструкторы
    public LastPriceKey() {}

    public LastPriceKey(String figi, LocalDateTime time) {
        this.figi = figi;
        this.time = time;
    }

    // Геттеры и сеттеры
    public String getFigi() {
        return figi;
    }

    public void setFigi(String figi) {
        this.figi = figi;
    }

    public LocalDateTime getTime() {
        return time;
    }

    public void setTime(LocalDateTime time) {
        this.time = time;
    }

    // Реализация equals и hashCode (обязательно для композитных ключей)
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        LastPriceKey that = (LastPriceKey) o;
        return Objects.equals(figi, that.figi) && Objects.equals(time, that.time);
    }

    @Override
    public int hashCode() {
        return Objects.hash(figi, time);
    }
}
