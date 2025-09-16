package com.example.investmentdatastreamservice.entity;

import java.io.Serializable;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Составной ключ для CandleEntity
 * 
 * Состоит из FIGI инструмента и времени свечи для уникальной идентификации каждой минутной свечи.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CandleKey implements Serializable {

    private String figi;
    private LocalDateTime time;

    @Override
    public boolean equals(Object o) {
        if (this == o)
            return true;
        if (o == null || getClass() != o.getClass())
            return false;
        CandleKey candleKey = (CandleKey) o;
        return figi != null ? figi.equals(candleKey.figi)
                : candleKey.figi == null && time != null ? time.equals(candleKey.time)
                        : candleKey.time == null;
    }

    @Override
    public int hashCode() {
        int result = figi != null ? figi.hashCode() : 0;
        result = 31 * result + (time != null ? time.hashCode() : 0);
        return result;
    }
}
