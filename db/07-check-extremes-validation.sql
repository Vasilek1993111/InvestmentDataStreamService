-- ============================================================================
-- СКРИПТ ПРОВЕРКИ ЭКСТРЕМУМОВ ДЛЯ ИНСТРУМЕНТА
-- ============================================================================

-- 1. Информация об инструменте
SELECT 
    COALESCE(s.ticker, f.ticker, ind.ticker) AS ticker,
    COALESCE(s.name, f.ticker, ind.name) AS name,
    CASE
        WHEN s.figi IS NOT NULL THEN 'share'
        WHEN f.figi IS NOT NULL THEN 'future'
        WHEN ind.figi IS NOT NULL THEN 'indicative'
        ELSE 'unknown'
    END AS instrument_type,
    'BBG004S68DD6' AS figi  -- ЗАМЕНИТЕ НА НУЖНЫЙ FIGI
FROM (SELECT 'BBG004S68DD6'::VARCHAR(255) AS figi) t  -- ЗАМЕНИТЕ НА НУЖНЫЙ FIGI
LEFT JOIN invest_ref.shares s ON t.figi = s.figi
LEFT JOIN invest_ref.futures f ON t.figi = f.figi
LEFT JOIN invest_ref.indicatives ind ON t.figi = ind.figi;

-- 2. Расчет экстремумов из daily_candles
WITH candle_extremes AS (
    SELECT 
        dc.figi,
        dc.time,
        dc.high,
        dc.low,
        dc.upper_shadow,
        dc.lower_shadow,
        dc.high + COALESCE(dc.upper_shadow, 0) AS historical_high,
        dc.low - COALESCE(dc.lower_shadow, 0) AS historical_low,
        dc.open,
        dc.close,
        dc.volume,
        dc.candle_type
    FROM invest_candles.daily_candles dc
    WHERE dc.figi = 'BBG004S68DD6'  -- ЗАМЕНИТЕ НА НУЖНЫЙ FIGI
      AND (dc.upper_shadow IS NOT NULL OR dc.lower_shadow IS NOT NULL)
),
extreme_values AS (
    SELECT 
        MAX(historical_high) AS max_historical_high,
        MIN(historical_low) AS min_historical_low
    FROM candle_extremes
)
SELECT 
    'РАСЧЕТНЫЕ ЭКСТРЕМУМЫ' AS report_section,
    ev.max_historical_high AS historical_high,
    ev.min_historical_low AS historical_low,
    NULL::TIMESTAMP WITH TIME ZONE AS high_date,
    NULL::TIMESTAMP WITH TIME ZONE AS low_date
FROM extreme_values ev;

-- 3. Сравнение с материализованным представлением
SELECT 
    'СРАВНЕНИЕ С MATERIALIZED VIEW' AS report_section,
    CASE
        WHEN calc.figi IS NOT NULL THEN 'РАСЧЕТНОЕ'
        ELSE NULL
    END AS source_calc,
    CASE
        WHEN mv.figi IS NOT NULL THEN 'MATERIALIZED VIEW'
        ELSE NULL
    END AS source_mv,
    calc.max_historical_high AS calc_historical_high,
    mv.historical_high AS mv_historical_high,
    CASE 
        WHEN ABS(COALESCE(calc.max_historical_high, 0) - COALESCE(mv.historical_high, 0)) < 0.0001 THEN 'OK'
        ELSE 'РАЗЛИЧИЕ'
    END AS high_match,
    calc.min_historical_low AS calc_historical_low,
    mv.historical_low AS mv_historical_low,
    CASE 
        WHEN ABS(COALESCE(calc.min_historical_low, 0) - COALESCE(mv.historical_low, 0)) < 0.0001 THEN 'OK'
        ELSE 'РАЗЛИЧИЕ'
    END AS low_match,
    mv.historical_high_date,
    mv.historical_low_date
FROM (
    SELECT 
        'BBG004S68DD6'::VARCHAR(255) AS figi,  -- ЗАМЕНИТЕ НА НУЖНЫЙ FIGI
        MAX(dc.high + COALESCE(dc.upper_shadow, 0)) AS max_historical_high,
        MIN(dc.low - COALESCE(dc.lower_shadow, 0)) AS min_historical_low
    FROM invest_candles.daily_candles dc
    WHERE dc.figi = 'BBG004S68DD6'  -- ЗАМЕНИТЕ НА НУЖНЫЙ FIGI
      AND (dc.upper_shadow IS NOT NULL OR dc.lower_shadow IS NOT NULL)
) calc
FULL OUTER JOIN invest_views.historical_price_extremes mv 
    ON calc.figi = mv.figi
WHERE calc.figi = 'BBG004S68DD6' OR mv.figi = 'BBG004S68DD6';  -- ЗАМЕНИТЕ НА НУЖНЫЙ FIGI

-- 6. Общая статистика по свечам
SELECT 
    'СТАТИСТИКА' AS report_section,
    COUNT(*) AS total_candles,
    COUNT(CASE WHEN upper_shadow IS NOT NULL THEN 1 END) AS candles_with_upper_shadow,
    COUNT(CASE WHEN lower_shadow IS NOT NULL THEN 1 END) AS candles_with_lower_shadow,
    MIN(time) AS first_candle_date,
    MAX(time) AS last_candle_date,
    AVG(high) AS avg_high,
    AVG(low) AS avg_low,
    AVG(volume) AS avg_volume
FROM invest_candles.daily_candles
WHERE figi = 'BBG004S68DD6';  -- ЗАМЕНИТЕ НА НУЖНЫЙ FIGI

-- ============================================================================


