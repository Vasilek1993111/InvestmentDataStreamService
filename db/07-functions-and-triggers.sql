create function bulk_insert_last_prices(p_figi character varying, p_time timestamp without time zone, p_price numeric, p_currency character varying, p_exchange character varying) returns void
    language plpgsql
as
$$
DECLARE
    partition_name TEXT;
    target_date DATE;
BEGIN
    -- Определяем дату и партицию
    target_date := p_time::DATE;
    partition_name := 'last_prices_' || TO_CHAR(target_date, 'YYYY_MM_DD');

    -- Проверяем существование партиции
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables
        WHERE schemaname = 'invest'
          AND tablename = partition_name
    ) THEN
        PERFORM invest.create_last_prices_daily_partition(target_date);
    END IF;

    -- Вставляем данные
    INSERT INTO invest.last_prices (figi, time, price, currency, exchange)
    VALUES (p_figi, p_time, p_price, p_currency, p_exchange)
    ON CONFLICT (figi, time) DO NOTHING;
END;
$$;

comment on function bulk_insert_last_prices(varchar, timestamp, numeric, varchar, varchar) is 'Функция для оптимизированной вставки данных с проверкой дневных партиций';

alter function bulk_insert_last_prices(varchar, timestamp, numeric, varchar, varchar) owner to postgres;

grant execute on function bulk_insert_last_prices(varchar, timestamp, numeric, varchar, varchar) to admin;

create function calculate_daily_candle_statistics() returns trigger
    language plpgsql
as
$$
BEGIN
    -- Вычисляем расширенную статистику
    NEW.price_change := NEW.close - NEW.open;

    IF NEW.open > 0 THEN
        NEW.price_change_percent := (NEW.price_change / NEW.open) * 100;
    ELSE
        NEW.price_change_percent := 0;
    END IF;

    -- Определяем тип свечи
    IF NEW.close > NEW.open THEN
        NEW.candle_type := 'BULLISH';
    ELSIF NEW.close < NEW.open THEN
        NEW.candle_type := 'BEARISH';
    ELSE
        NEW.candle_type := 'DOJI';
    END IF;

    -- Вычисляем размер тела свечи
    NEW.body_size := ABS(NEW.price_change);

    -- Вычисляем тени
    NEW.upper_shadow := NEW.high - GREATEST(NEW.open, NEW.close);
    NEW.lower_shadow := LEAST(NEW.open, NEW.close) - NEW.low;

    -- Вычисляем диапазон
    NEW.high_low_range := NEW.high - NEW.low;

    -- Вычисляем среднюю цену
    NEW.average_price := (NEW.high + NEW.low + NEW.close) / 3;

    RETURN NEW;
END;
$$;

alter function calculate_daily_candle_statistics() owner to postgres;

grant execute on function calculate_daily_candle_statistics() to admin;


create function calculate_duration_ms() returns trigger
    language plpgsql
as
$$
BEGIN
    IF NEW.end_time IS NOT NULL AND NEW.start_time IS NOT NULL THEN
        NEW.duration_ms = EXTRACT(EPOCH FROM (NEW.end_time - NEW.start_time)) * 1000;
    END IF;
    RETURN NEW;
END;
$$;

alter function calculate_duration_ms() owner to postgres;

grant execute on function calculate_duration_ms() to admin;



create function calculate_minute_candle_statistics() returns trigger
    language plpgsql
as
$$
BEGIN
    -- Вычисляем расширенную статистику
    NEW.price_change := NEW.close - NEW.open;
    NEW.price_change_percent := CASE
                                    WHEN NEW.open > 0 THEN ((NEW.close - NEW.open) / NEW.open) * 100
                                    ELSE 0
        END;
    NEW.candle_type := CASE
                           WHEN NEW.close > NEW.open THEN 'BULLISH'
                           WHEN NEW.close < NEW.open THEN 'BEARISH'
                           ELSE 'DOJI'
        END;
    NEW.body_size := ABS(NEW.close - NEW.open);
    NEW.upper_shadow := NEW.high - GREATEST(NEW.close, NEW.open);
    NEW.lower_shadow := LEAST(NEW.open, NEW.close) - NEW.low;
    NEW.high_low_range := NEW.high - NEW.low;
    NEW.average_price := (NEW.high + NEW.low + NEW.open + NEW.close) / 4;

    RETURN NEW;
END;
$$;

alter function calculate_minute_candle_statistics() owner to postgres;

grant execute on function calculate_minute_candle_statistics() to admin;

create function cleanup_old_daily_partitions(retention_days integer DEFAULT 730) returns void
    language plpgsql
as
$$
DECLARE
    partition_record RECORD;
    cutoff_date DATE;
BEGIN
    -- Определяем дату отсечения
    cutoff_date := CURRENT_DATE - (retention_days * INTERVAL '1 day');

    -- Находим партиции старше указанного периода
    FOR partition_record IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'invest'
          AND tablename LIKE 'last_prices_%'
          AND tablename ~ '^last_prices_\d{4}_\d{2}_\d{2}$'
          AND TO_DATE(SUBSTRING(tablename FROM 'last_prices_(\d{4}_\d{2}_\d{2})'), 'YYYY_MM_DD') < cutoff_date
        LOOP
            -- Удаляем старую партицию
            EXECUTE 'DROP TABLE IF EXISTS invest.' || partition_record.tablename || ' CASCADE';
            RAISE NOTICE 'Удалена старая дневная партиция %', partition_record.tablename;
        END LOOP;
END;
$$;

comment on function cleanup_old_daily_partitions(integer) is 'Функция для очистки старых дневных партиций (по умолчанию старше 760 дней)';

alter function cleanup_old_daily_partitions(integer) owner to postgres;

grant execute on function cleanup_old_daily_partitions(integer) to admin;



create function create_daily_partition_candles(table_name text, partition_date date) returns void
    language plpgsql
as
$$
DECLARE
    partition_name TEXT;
    next_date DATE;
    start_time TEXT;
    end_time TEXT;
BEGIN
    partition_name := table_name || '_' || to_char(partition_date, 'YYYY_MM_DD');
    next_date := partition_date + INTERVAL '1 day';
    start_time := to_char(partition_date, 'YYYY-MM-DD') || ' 00:00:00+03';
    end_time := to_char(next_date, 'YYYY-MM-DD') || ' 00:00:00+03';

    EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
                   partition_name, table_name, start_time, end_time);
END;
$$;

comment on function create_daily_partition_candles(text, date) is 'Функция для автоматического создания ежедневных партиций таблицы minute_candles';

alter function create_daily_partition_candles(text, date) owner to postgres;

grant execute on function create_daily_partition_candles(text, date) to admin;



create function create_daily_partitions_for_period(start_date date, end_date date) returns void
    language plpgsql
as
$$
DECLARE
    current_day DATE;  -- Переименовал переменную чтобы избежать конфликта
    partition_name TEXT;
    next_day DATE;
BEGIN
    current_day := start_date;

    WHILE current_day <= end_date LOOP
            partition_name := 'last_prices_' || TO_CHAR(current_day, 'YYYY_MM_DD');

            -- Проверяем, существует ли партиция
            IF NOT EXISTS (
                SELECT 1 FROM pg_tables
                WHERE schemaname = 'invest'
                  AND tablename = partition_name
            ) THEN
                next_day := current_day + INTERVAL '1 day';

                -- Создаем партицию
                EXECUTE format('CREATE TABLE invest.%I PARTITION OF invest.last_prices
                FOR VALUES FROM (%L) TO (%L)',
                               partition_name,
                               current_day,
                               next_day
                        );

                -- Добавляем комментарий
                EXECUTE format('COMMENT ON TABLE invest.%I IS %L',
                               partition_name,
                               'Партиция сделок за ' || TO_CHAR(current_day, 'DD.MM.YYYY')
                        );

                RAISE NOTICE 'Создана дневная партиция %', partition_name;
            END IF;

            current_day := current_day + INTERVAL '1 day';
        END LOOP;
END;
$$;

comment on function create_daily_partitions_for_period(date, date) is 'Функция для массового создания дневных партиций за период';

alter function create_daily_partitions_for_period(date, date) owner to postgres;

grant execute on function create_daily_partitions_for_period(date, date) to admin;



create function create_daily_partitions_for_period_fast(start_date date, end_date date) returns void
    language plpgsql
as
$$
DECLARE
    current_day DATE;
    partition_name TEXT;
    next_day DATE;
    sql_commands TEXT[] := '{}';
    single_command TEXT;
BEGIN
    current_day := start_date;

    -- Собираем все команды создания партиций в массив
    WHILE current_day <= end_date LOOP
            partition_name := 'last_prices_' || TO_CHAR(current_day, 'YYYY_MM_DD');

            -- Проверяем, существует ли партиция
            IF NOT EXISTS (
                SELECT 1 FROM pg_tables
                WHERE schemaname = 'invest'
                  AND tablename = partition_name
            ) THEN
                next_day := current_day + INTERVAL '1 day';

                -- Формируем команду создания партиции
                single_command := format('CREATE TABLE invest.%I PARTITION OF invest.last_prices
                FOR VALUES FROM (%L) TO (%L)',
                                         partition_name,
                                         current_day,
                                         next_day
                                  );

                -- Добавляем команду в массив
                sql_commands := array_append(sql_commands, single_command);

                -- Формируем команду добавления комментария
                single_command := format('COMMENT ON TABLE invest.%I IS %L',
                                         partition_name,
                                         'Партиция сделок за ' || TO_CHAR(current_day, 'DD.MM.YYYY')
                                  );

                -- Добавляем команду комментария в массив
                sql_commands := array_append(sql_commands, single_command);

                RAISE NOTICE 'Подготовлена дневная партиция %', partition_name;
            END IF;

            current_day := current_day + INTERVAL '1 day';
        END LOOP;

    -- Выполняем все команды одной транзакцией
    IF array_length(sql_commands, 1) > 0 THEN
        RAISE NOTICE 'Выполняем % команд создания партиций...', array_length(sql_commands, 1);

        -- Выполняем все команды
        FOR i IN 1..array_length(sql_commands, 1) LOOP
                EXECUTE sql_commands[i];
            END LOOP;

        RAISE NOTICE 'Все партиции созданы успешно!';
    ELSE
        RAISE NOTICE 'Все партиции уже существуют';
    END IF;
END;
$$;

comment on function create_daily_partitions_for_period_fast(date, date) is 'Оптимизированная функция для быстрого создания дневных партиций за период';

alter function create_daily_partitions_for_period_fast(date, date) owner to postgres;

grant execute on function create_daily_partitions_for_period_fast(date, date) to admin;



create function create_last_prices_daily_partition(target_date date) returns void
    language plpgsql
as
$$
DECLARE
    partition_name TEXT;
    start_date DATE;
    end_date DATE;
BEGIN
    -- Определяем имя партиции (YYYY_MM_DD)
    partition_name := 'last_prices_' || TO_CHAR(target_date, 'YYYY_MM_DD');

    -- Определяем диапазон дат (день)
    start_date := target_date;
    end_date := target_date + INTERVAL '1 day';

    -- Проверяем, существует ли уже партиция
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables
        WHERE schemaname = 'invest'
          AND tablename = partition_name
    ) THEN
        -- Создаем партицию
        EXECUTE format('CREATE TABLE invest.%I PARTITION OF invest.last_prices
            FOR VALUES FROM (%L) TO (%L)',
                       partition_name,
                       start_date,
                       end_date
                );

        -- Добавляем комментарий
        EXECUTE format('COMMENT ON TABLE invest.%I IS %L',
                       partition_name,
                       'Партиция сделок за ' || TO_CHAR(target_date, 'DD.MM.YYYY')
                );

        RAISE NOTICE 'Создана дневная партиция % для даты %', partition_name, target_date;
    ELSE
        RAISE NOTICE 'Дневная партиция % уже существует', partition_name;
    END IF;
END;
$$;

comment on function create_last_prices_daily_partition(date) is 'Функция для автоматического создания дневных партиций';

alter function create_last_prices_daily_partition(date) owner to postgres;

grant execute on function create_last_prices_daily_partition(date) to admin;



create function create_monthly_partition(table_name text, start_date date) returns void
    language plpgsql
as
$$
DECLARE
    partition_name TEXT;
    end_date DATE;
BEGIN
    partition_name := table_name || '_' || to_char(start_date, 'YYYY_MM');
    end_date := start_date + INTERVAL '1 month';

    EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
                   partition_name, table_name, start_date, end_date);
END;
$$;

comment on function create_monthly_partition(text, date) is 'Функция для автоматического создания месячных партиций таблицы close_prices';

alter function create_monthly_partition(text, date) owner to postgres;

grant execute on function create_monthly_partition(text, date) to admin;




create function create_monthly_partition_daily_candles(table_name text, start_date date) returns void
    language plpgsql
as
$$
DECLARE
    partition_name TEXT;
    next_month DATE;
    start_time TEXT;
    end_time TEXT;
BEGIN
    partition_name := table_name || '_' || to_char(start_date, 'YYYY_MM');
    next_month := start_date + INTERVAL '1 month';
    start_time := to_char(start_date, 'YYYY-MM-01') || ' 00:00:00+03';
    end_time := to_char(next_month, 'YYYY-MM-01') || ' 00:00:00+03';

    EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
                   partition_name, table_name, start_time, end_time);
END;
$$;

comment on function create_monthly_partition_daily_candles(text, date) is 'Функция для автоматического создания месячных партиций таблицы daily_candles';

alter function create_monthly_partition_daily_candles(text, date) owner to postgres;

grant execute on function create_monthly_partition_daily_candles(text, date) to admin;




create function create_monthly_partition_evening(table_name text, start_date date) returns void
    language plpgsql
as
$$
DECLARE
    partition_name TEXT;
    end_date DATE;
BEGIN
    partition_name := table_name || '_' || to_char(start_date, 'YYYY_MM');
    end_date := start_date + INTERVAL '1 month';

    EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
                   partition_name, table_name, start_date, end_date);
END;
$$;

comment on function create_monthly_partition_evening(text, date) is 'Функция для автоматического создания месячных партиций таблицы close_prices_evening_session';

alter function create_monthly_partition_evening(text, date) owner to postgres;

grant execute on function create_monthly_partition_evening(text, date) to admin;




create function ensure_open_prices_partition(p_date date) returns text
    language plpgsql
as
$$
declare
    v_start date := date_trunc('month', p_date)::date;
    v_end   date := (date_trunc('month', p_date) + interval '1 month')::date;
    v_part  text := format('open_prices_%s', to_char(v_start, 'YYYY_MM'));
    v_sql   text;
begin
    -- создаем партицию при отсутствии
    perform 1
    from pg_class c
             join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = current_schema()
      and c.relname = v_part;

    if not found then
        v_sql := format(
                'create table if not exists %I partition of open_prices for values from (%L) to (%L);',
                v_part, v_start, v_end
                 );
        execute v_sql;

        -- права на партицию
        v_sql := format('alter table %I owner to postgres;', v_part);
        execute v_sql;

        v_sql := format('grant select on %I to tester;', v_part);
        execute v_sql;

        v_sql := format('grant delete, insert, references, select, trigger, truncate, update on %I to admin;', v_part);
        execute v_sql;

        -- комментарий на партицию
-- комментарий на партицию
        v_sql := format(
                'comment on table %I is ''Партиция для %s — %s'';',
                v_part, to_char(v_start, 'YYYY-MM-DD'), to_char(v_end - 1, 'YYYY-MM-DD')
                 );
        execute v_sql;
    end if;

    return v_part;
end;
$$;

alter function ensure_open_prices_partition(date) owner to postgres;

grant execute on function ensure_open_prices_partition(date) to admin;




create function get_daily_partition_info()
    returns TABLE(partition_name text, partition_date date, row_count bigint, size_pretty text, size_bytes bigint, min_time timestamp without time zone, max_time timestamp without time zone)
    language plpgsql
as
$$
BEGIN
    RETURN QUERY
        SELECT
            p.tablename::TEXT as partition_name,
            TO_DATE(SUBSTRING(p.tablename FROM 'last_prices_(\d{4}_\d{2}_\d{2})'), 'YYYY_MM_DD') as partition_date,
            COALESCE(s.n_tup_ins - s.n_tup_del, 0) as row_count,
            pg_size_pretty(pg_total_relation_size('invest.'||p.tablename)) as size_pretty,
            pg_total_relation_size('invest.'||p.tablename) as size_bytes,
            (SELECT MIN(time) FROM invest.last_prices WHERE
                time::DATE = TO_DATE(SUBSTRING(p.tablename FROM 'last_prices_(\d{4}_\d{2}_\d{2})'), 'YYYY_MM_DD')) as min_time,
            (SELECT MAX(time) FROM invest.last_prices WHERE
                time::DATE = TO_DATE(SUBSTRING(p.tablename FROM 'last_prices_(\d{4}_\d{2}_\d{2})'), 'YYYY_MM_DD')) as max_time
        FROM pg_tables p
                 LEFT JOIN pg_stat_user_tables s ON s.relname = p.tablename AND s.schemaname = p.schemaname
        WHERE p.schemaname = 'invest'
          AND p.tablename LIKE 'last_prices_%'
          AND p.tablename ~ '^last_prices_\d{4}_\d{2}_\d{2}$'
        ORDER BY partition_date DESC;
END;
$$;

comment on function get_daily_partition_info() is 'Функция для получения детальной информации о дневных партициях';

alter function get_daily_partition_info() owner to postgres;

grant execute on function get_daily_partition_info() to admin;




create function get_last_prices_daily_stats(p_start_date date DEFAULT NULL::date, p_end_date date DEFAULT NULL::date, p_figi character varying DEFAULT NULL::character varying)
    returns TABLE(trade_date date, total_trades bigint, unique_instruments bigint, avg_price numeric, min_price numeric, max_price numeric)
    language plpgsql
as
$$
DECLARE
    start_date DATE;
    end_date DATE;
BEGIN
    -- Устанавливаем даты по умолчанию
    start_date := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '7 days');
    end_date := COALESCE(p_end_date, CURRENT_DATE);

    RETURN QUERY
        SELECT
            time::DATE as trade_date,
            COUNT(*) as total_trades,
            COUNT(DISTINCT figi) as unique_instruments,
            AVG(price) as avg_price,
            MIN(price) as min_price,
            MAX(price) as max_price
        FROM invest.last_prices
        WHERE time >= start_date
          AND time < end_date + INTERVAL '1 day'
          AND (p_figi IS NULL OR figi = p_figi)
        GROUP BY time::DATE
        ORDER BY trade_date DESC;
END;
$$;

comment on function get_last_prices_daily_stats(date, date, varchar) is 'Функция для получения дневной статистики по сделкам';

alter function get_last_prices_daily_stats(date, date, varchar) owner to postgres;

grant execute on function get_last_prices_daily_stats(date, date, varchar) to admin;





create function last_prices_daily_partition_trigger() returns trigger
    language plpgsql
as
$$
DECLARE
    partition_name TEXT;
    target_date DATE;
BEGIN
    -- Определяем дату и имя партиции
    target_date := NEW.time::DATE;
    partition_name := 'last_prices_' || TO_CHAR(target_date, 'YYYY_MM_DD');

    -- Проверяем, существует ли партиция
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables
        WHERE schemaname = 'invest'
          AND tablename = partition_name
    ) THEN
        -- Создаем партицию автоматически
        PERFORM invest.create_last_prices_daily_partition(target_date);
    END IF;

    RETURN NEW;
END;
$$;

comment on function last_prices_daily_partition_trigger() is 'Триггер для автоматического создания дневных партиций при вставке данных';

alter function last_prices_daily_partition_trigger() owner to postgres;

grant execute on function last_prices_daily_partition_trigger() to admin;




create function trg_open_prices_ensure_partition() returns trigger
    language plpgsql
as
$$
begin
    perform ensure_open_prices_partition(new.price_date);
    return new;
end;
$$;

alter function trg_open_prices_ensure_partition() owner to postgres;

grant execute on function trg_open_prices_ensure_partition() to admin;

