package com.example.investmentdatastreamservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;

/**
 * DTO для данных о приближении к лимитам инструмента
 * 
 * Содержит информацию о текущей цене, лимитах и состоянии приближения
 * для отправки уведомлений в Telegram.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LimitAlertDto {
    
    private String figi;
    private String ticker;
    private String instrumentName;
    private LocalDateTime eventTime;
    private BigDecimal currentPrice;
    private BigDecimal limitPrice;
    private String limitType; // UP или DOWN
    private BigDecimal limitDown;
    private BigDecimal limitUp;
    private BigDecimal closePriceOs; // Цена закрытия ОС последняя
    private BigDecimal closePriceEvening; // Цена закрытия вечерней сессии последняя
    private BigDecimal distanceToLimit; // Расстояние до лимита в процентах
    private boolean isLimitReached; // Достигнут ли лимит
    private boolean isApproachingLimit; // Приближается ли к лимиту (1%)
    private boolean isHistorical; // Флаг для исторических экстремумов (true) или биржевых лимитов (false)
    private OffsetDateTime historicalExtremeDate; // Дата исторического экстремума (для исторических лимитов)
}
