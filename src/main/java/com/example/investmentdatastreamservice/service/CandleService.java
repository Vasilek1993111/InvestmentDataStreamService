package com.example.investmentdatastreamservice.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import org.springframework.stereotype.Service;
import com.example.investmentdatastreamservice.dto.MinuteCandleDto;

/**
 * Сервис для работы с минутными свечами
 * 
 * <p>
 * Предоставляет методы для вычисления технических показателей свечей.
 * </p>
 * 
 * @author InvestmentDataStreamService
 * @version 1.0
 * @since 2024
 */
@Service
public class CandleService {

    /**
     * Вычислить технические показатели для свечи
     * 
     * <p>
     * Вычисляет:
     * </p>
     * <ul>
     * <li>Изменение цены</li>
     * <li>Процентное изменение</li>
     * <li>Тип свечи (BULLISH/BEARISH/DOJI)</li>
     * <li>Размер тела</li>
     * <li>Верхняя и нижняя тени</li>
     * <li>Диапазон цен</li>
     * <li>Средняя цена</li>
     * </ul>
     * 
     * @param open цена открытия
     * @param high максимальная цена
     * @param low минимальная цена
     * @param close цена закрытия
     * @return объект MinuteCandleDto с вычисленными показателями
     */
    public MinuteCandleDto enrichCandleWithTechnicalIndicators(BigDecimal open, BigDecimal high,
            BigDecimal low, BigDecimal close) {

        MinuteCandleDto candle = MinuteCandleDto.builder()
                .open(open)
                .high(high)
                .low(low)
                .close(close)
                .build();

        // Изменение цены (close - open)
        BigDecimal priceChange = close.subtract(open);
        candle.setPriceChange(priceChange);

        // Процентное изменение цены
        if (open.compareTo(BigDecimal.ZERO) != 0) {
            BigDecimal priceChangePercent = priceChange.divide(open, 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100));
            candle.setPriceChangePercent(priceChangePercent);
        } else {
            candle.setPriceChangePercent(BigDecimal.ZERO);
        }

        // Размер тела свечи
        BigDecimal bodySize = priceChange.abs();
        candle.setBodySize(bodySize);

        // Тип свечи
        String candleType;
        BigDecimal threshold = BigDecimal.valueOf(0.0001); // Порог для DOJI
        if (bodySize.compareTo(threshold) < 0) {
            candleType = "DOJI";
        } else if (close.compareTo(open) > 0) {
            candleType = "BULLISH";
        } else {
            candleType = "BEARISH";
        }
        candle.setCandleType(candleType);

        // Верхняя тень
        BigDecimal maxOfOpenClose = open.max(close);
        BigDecimal upperShadow = high.subtract(maxOfOpenClose);
        candle.setUpperShadow(upperShadow);

        // Нижняя тень
        BigDecimal minOfOpenClose = open.min(close);
        BigDecimal lowerShadow = minOfOpenClose.subtract(low);
        candle.setLowerShadow(lowerShadow);

        // Диапазон цен (high - low)
        BigDecimal highLowRange = high.subtract(low);
        candle.setHighLowRange(highLowRange);

        // Средняя цена (high + low + open + close) / 4
        BigDecimal averagePrice = high.add(low).add(open).add(close).divide(BigDecimal.valueOf(4),
                2, RoundingMode.HALF_UP);
        candle.setAveragePrice(averagePrice);

        return candle;
    }
}

