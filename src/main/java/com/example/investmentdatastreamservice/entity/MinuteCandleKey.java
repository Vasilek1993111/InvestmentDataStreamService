package com.example.investmentdatastreamservice.entity;

import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;

public class MinuteCandleKey implements Serializable {
    private String figi;
    private Instant time;

    public MinuteCandleKey() {}

    public MinuteCandleKey(String figi, Instant time) {
        this.figi = figi;
        this.time = time;
    }

    public String getFigi() {
        return figi;
    }

    public void setFigi(String figi) {
        this.figi = figi;
    }

    public Instant getTime() {
        return time;
    }

    public void setTime(Instant time) {
        this.time = time;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        MinuteCandleKey that = (MinuteCandleKey) o;
        return Objects.equals(figi, that.figi) && Objects.equals(time, that.time);
    }

    @Override
    public int hashCode() {
        return Objects.hash(figi, time);
    }
}
