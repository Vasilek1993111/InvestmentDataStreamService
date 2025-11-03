-- Альтернативное решение: триггер для преобразования пустых строк в NULL
-- Этот триггер автоматически преобразует пустые строки в NULL при вставке/обновлении

-- Создаем функцию триггера
CREATE OR REPLACE FUNCTION invest_candles.convert_empty_strategy_applicable()
RETURNS TRIGGER AS $$
BEGIN
    -- Преобразуем пустую строку в NULL
    IF NEW.strategy_applicable = '' THEN
        NEW.strategy_applicable := NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Создаем триггер для таблицы candle_pattern_analysis
CREATE TRIGGER trg_convert_empty_strategy_applicable
    BEFORE INSERT OR UPDATE ON invest_candles.candle_pattern_analysis
    FOR EACH ROW
    EXECUTE FUNCTION invest_candles.convert_empty_strategy_applicable();

-- Комментарии
COMMENT ON FUNCTION invest_candles.convert_empty_strategy_applicable() 
IS 'Функция триггера для преобразования пустых строк в NULL в поле strategy_applicable';

COMMENT ON TRIGGER trg_convert_empty_strategy_applicable ON invest_candles.candle_pattern_analysis 
IS 'Триггер для автоматического преобразования пустых строк в NULL в поле strategy_applicable';
