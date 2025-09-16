package com.example.investmentdatastreamservice.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Entity для хранения минутных свечей
 * 
 * Представляет данные о минутных свечах торговых инструментов с OHLCV данными и временными метками.
 * Таблица разделена по партициям по времени.
 */
@Entity
@Table(name = "candles", schema = "invest")
@IdClass(CandleKey.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CandleEntity {

    @Id
    @Column(name = "figi", nullable = false, length = 255)
    private String figi;

    @Id
    @Column(name = "time", nullable = false)
    private LocalDateTime time;

    @Column(name = "volume", nullable = false)
    private Long volume;

    @Column(name = "high", nullable = false, precision = 18, scale = 9)
    private BigDecimal high;

    @Column(name = "low", nullable = false, precision = 18, scale = 9)
    private BigDecimal low;

    @Column(name = "close", nullable = false, precision = 18, scale = 9)
    private BigDecimal close;

    @Column(name = "open", nullable = false, precision = 18, scale = 9)
    private BigDecimal open;

    @Column(name = "is_complete", nullable = false)
    private Boolean isComplete;

    @Column(name = "created_at", nullable = false, insertable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false, insertable = false, updatable = false)
    private LocalDateTime updatedAt;
}
