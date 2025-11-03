-- ALTER запрос для добавления столбца strategy_applicable к существующей таблице candle_pattern_analysis

-- Добавляем столбец для флага применимости стратегии
ALTER TABLE invest_candles.candle_pattern_analysis 
ADD COLUMN strategy_applicable char(1) DEFAULT NULL;

-- Добавляем ограничение на допустимые значения
ALTER TABLE invest_candles.candle_pattern_analysis 
ADD CONSTRAINT chk_strategy_applicable 
CHECK (strategy_applicable IN ('Y', 'N') OR strategy_applicable IS NULL);

-- Добавляем комментарий к новому столбцу
COMMENT ON COLUMN invest_candles.candle_pattern_analysis.strategy_applicable 
IS 'Флаг применимости стратегии: Y - применима, N - не применима, NULL - не оценена';

-- Создаем индекс для оптимизации запросов по новому столбцу
CREATE INDEX idx_candle_pattern_analysis_strategy_applicable 
ON invest_candles.candle_pattern_analysis (strategy_applicable);

-- Обновляем представление в схеме invest для включения нового столбца
DROP VIEW IF EXISTS invest.candle_pattern_analysis;

CREATE VIEW invest.candle_pattern_analysis AS
SELECT 
    id,
    figi,
    analysis_date,
    pattern_start_date,
    pattern_end_date,
    candle_type,
    consecutive_days,
    avg_volume,
    avg_price_change,
    total_price_change,
    strategy_applicable,
    created_at
FROM invest_candles.candle_pattern_analysis;

COMMENT ON VIEW invest.candle_pattern_analysis 
IS 'Синоним для таблицы candle_pattern_analysis из схемы invest_candles';

-- Восстанавливаем права доступа на представление
ALTER VIEW invest.candle_pattern_analysis OWNER TO postgres;
GRANT SELECT ON invest.candle_pattern_analysis TO tester;
GRANT SELECT ON invest.candle_pattern_analysis TO admin;
