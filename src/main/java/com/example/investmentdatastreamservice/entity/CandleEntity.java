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
 * <p>
 * Представляет данные о минутных свечах торговых инструментов с расширенной аналитикой:
 * </p>
 * <ul>
 * <li>OHLCV данные (Open, High, Low, Close, Volume)</li>
 * <li>Технический анализ (тип свечи, размер тела, тени)</li>
 * <li>Изменение цены (абсолютное и процентное)</li>
 * <li>Средняя цена и диапазон</li>
 * </ul>
 * 
 * <p>
 * Таблица разделена по партициям по времени (ежедневное партиционирование).
 * </p>
 * 
 * @author InvestmentDataStreamService
 * @version 2.0
 * @since 2024
 */
@Entity
@Table(name = "minute_candles", schema = "invest")
@IdClass(CandleKey.class)
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CandleEntity {

    /** Уникальный идентификатор инструмента (Financial Instrument Global Identifier) */
    @Id
    @Column(name = "figi", nullable = false, length = 255)
    private String figi;

    /** Время начала минутной свечи в московской таймзоне */
    @Id
    @Column(name = "time", nullable = false)
    private LocalDateTime time;

    /** Цена открытия за минуту с точностью до 9 знаков после запятой */
    @Column(name = "open", nullable = false, precision = 18, scale = 9)
    private BigDecimal open;

    /** Максимальная цена за минуту с точностью до 9 знаков после запятой */
    @Column(name = "high", nullable = false, precision = 18, scale = 9)
    private BigDecimal high;

    /** Минимальная цена за минуту с точностью до 9 знаков после запятой */
    @Column(name = "low", nullable = false, precision = 18, scale = 9)
    private BigDecimal low;

    /** Цена закрытия за минуту с точностью до 9 знаков после запятой */
    @Column(name = "close", nullable = false, precision = 18, scale = 9)
    private BigDecimal close;

    /** Объем торгов за минуту (количество лотов) */
    @Column(name = "volume", nullable = false)
    private Long volume;

    /** Флаг завершенности свечи (true - свеча завершена, false - формируется) */
    @Column(name = "is_complete", nullable = false)
    private Boolean isComplete;

    /** Изменение цены (close - open) */
    @Column(name = "price_change", precision = 18, scale = 9)
    private BigDecimal priceChange;

    /** Процентное изменение цены */
    @Column(name = "price_change_percent", precision = 18, scale = 4)
    private BigDecimal priceChangePercent;

    /** Тип свечи: BULLISH, BEARISH, DOJI */
    @Column(name = "candle_type", length = 20)
    private String candleType;

    /** Размер тела свечи (абсолютное значение изменения цены) */
    @Column(name = "body_size", precision = 18, scale = 9)
    private BigDecimal bodySize;

    /** Верхняя тень свечи */
    @Column(name = "upper_shadow", precision = 18, scale = 9)
    private BigDecimal upperShadow;

    /** Нижняя тень свечи */
    @Column(name = "lower_shadow", precision = 18, scale = 9)
    private BigDecimal lowerShadow;

    /** Диапазон цен (high - low) */
    @Column(name = "high_low_range", precision = 18, scale = 9)
    private BigDecimal highLowRange;

    /** Средняя цена (high + low + open + close) / 4 */
    @Column(name = "average_price", precision = 18, scale = 2)
    private BigDecimal averagePrice;

    /** Время создания записи в московской таймзоне */
    @Column(name = "created_at", nullable = false, insertable = false, updatable = false)
    private LocalDateTime createdAt;

    /** Время последнего обновления записи в московской таймзоне */
    @Column(name = "updated_at", nullable = false, insertable = false, updatable = false)
    private LocalDateTime updatedAt;
}
