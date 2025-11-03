-- Исправление ограничения chk_strategy_applicable для разрешения пустых строк
-- Это исправляет ошибку при вставке данных с пустыми строками в поле strategy_applicable

-- Удаляем старое ограничение
ALTER TABLE invest_candles.candle_pattern_analysis 
DROP CONSTRAINT IF EXISTS chk_strategy_applicable;

-- Добавляем новое ограничение, которое разрешает пустые строки
ALTER TABLE invest_candles.candle_pattern_analysis 
ADD CONSTRAINT chk_strategy_applicable 
CHECK (strategy_applicable IN ('Y', 'N', '') OR strategy_applicable IS NULL);

-- Обновляем комментарий к столбцу
COMMENT ON COLUMN invest_candles.candle_pattern_analysis.strategy_applicable 
IS 'Флаг применимости стратегии: Y - применима, N - не применима, пустая строка или NULL - не оценена';
