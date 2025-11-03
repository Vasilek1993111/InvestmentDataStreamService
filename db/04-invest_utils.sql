--Схема invest_utils - схема для хранения вспомогательных таблиц и функций
--На текущий момент в ней хранится таблица логирования работы методов и функции для создания партиций
CREATE SCHEMA IF NOT EXISTS invest_utils;


-- auto-generated definition
create table invest_utils.system_logs
(
    id          bigserial primary key,
    task_id     varchar(255)             not null,
    endpoint    varchar(255)             not null,
    method      varchar(255)             not null,
    status      varchar(255)             not null,
    message     text                     not null,
    start_time  timestamp with time zone not null,
    end_time    timestamp with time zone,
    duration_ms bigint,
    created_at  timestamp with time zone default now()
);

comment on table invest_utils.system_logs is 'Упрощенная таблица для записи логов работы методов';

comment on column invest_utils.system_logs.task_id is 'ID задачи';

comment on column invest_utils.system_logs.endpoint is 'Название эндпоинта';

comment on column invest_utils.system_logs.method is 'HTTP метод';

comment on column invest_utils.system_logs.status is 'Статус выполнения';

comment on column invest_utils.system_logs.message is 'Текстовое сообщение о работе';

comment on column invest_utils.system_logs.start_time is 'Время начала';

comment on column invest_utils.system_logs.end_time is 'Время завершения';

comment on column invest_utils.system_logs.duration_ms is 'Длительность в миллисекундах';

alter table invest_utils.system_logs
    owner to postgres;

-- Создание синонима в схеме invest для удобства использования
create or replace view invest.system_logs as
select 
    id,
    task_id,
    endpoint,
    method,
    status,
    message,
    start_time,
    end_time,
    duration_ms,
    created_at
from invest_utils.system_logs;

comment on view invest.system_logs is 'Синоним для таблицы system_logs из схемы invest_utils';

-- Права доступа на представление
alter view invest.system_logs owner to postgres;

-- ============================================================================
-- ФУНКЦИИ ДЛЯ СОЗДАНИЯ ПАРТИЦИЙ
-- ============================================================================

-- Функция для создания дневной партиции для invest_candles.minute_candles
create or replace function invest_utils.create_minute_candles_partition(p_date date)
returns text
language plpgsql
as $$
declare
    v_partition_name text;
    v_start_time timestamp with time zone;
    v_end_time timestamp with time zone;
    v_prev_date date;
begin
    -- Формируем имя партиции: minute_candles_YYYY_MM_DD
    v_partition_name := 'invest_candles.minute_candles_' || to_char(p_date, 'YYYY_MM_DD');
    
    -- Предыдущий день (для начала диапазона)
    v_prev_date := p_date - interval '1 day';
    
    -- Диапазон: от предыдущего дня 21:00 UTC до текущего дня 21:00 UTC
    v_start_time := (to_char(v_prev_date, 'YYYY-MM-DD') || ' 21:00:00+00')::timestamp with time zone;
    v_end_time := (to_char(p_date, 'YYYY-MM-DD') || ' 21:00:00+00')::timestamp with time zone;
    
    -- Проверяем, существует ли партиция
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'invest_candles'
          and c.relname = 'minute_candles_' || to_char(p_date, 'YYYY_MM_DD')
    ) then
        raise notice 'Партиция % уже существует', v_partition_name;
        return v_partition_name || ' уже существует';
    end if;
    
    -- Создаем партицию
    execute format(
        'create table invest_candles.minute_candles_%s partition of invest_candles.minute_candles ' ||
        'for values from (%L) to (%L)',
        to_char(p_date, 'YYYY_MM_DD'),
        v_start_time,
        v_end_time
    );
    
    -- Устанавливаем владельца
    execute format(
        'alter table invest_candles.minute_candles_%s owner to postgres',
        to_char(p_date, 'YYYY_MM_DD')
    );
    
    raise notice 'Создана партиция % для даты %', v_partition_name, p_date;
    return v_partition_name || ' создана успешно';
end;
$$;

comment on function invest_utils.create_minute_candles_partition(date) is 'Функция для автоматического создания дневной партиции таблицы invest_candles.minute_candles';

alter function invest_utils.create_minute_candles_partition(date) owner to postgres;

-- Функция для создания месячной партиции для invest_candles.daily_candles
create or replace function invest_utils.create_daily_candles_partition(p_date date)
returns text
language plpgsql
as $$
declare
    v_partition_name text;
    v_start_time timestamp with time zone;
    v_end_time timestamp with time zone;
    v_month_start date;
    v_next_month date;
    v_prev_month_end date;
begin
    -- Определяем начало месяца указанной даты
    v_month_start := date_trunc('month', p_date)::date;
    
    -- Формируем имя партиции: daily_candles_YYYY_MM
    v_partition_name := 'invest_candles.daily_candles_' || to_char(v_month_start, 'YYYY_MM');
    
    -- Предыдущий месяц (последний день) для начала диапазона
    v_prev_month_end := v_month_start - interval '1 day';
    
    -- Следующий месяц
    v_next_month := v_month_start + interval '1 month';
    
    -- Диапазон: от последнего дня предыдущего месяца 21:00 UTC до последнего дня текущего месяца 21:00 UTC
    v_start_time := (to_char(v_prev_month_end, 'YYYY-MM-DD') || ' 21:00:00+00')::timestamp with time zone;
    v_end_time := (to_char(v_next_month - interval '1 day', 'YYYY-MM-DD') || ' 21:00:00+00')::timestamp with time zone;
    
    -- Проверяем, существует ли партиция
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'invest_candles'
          and c.relname = 'daily_candles_' || to_char(v_month_start, 'YYYY_MM')
    ) then
        raise notice 'Партиция % уже существует', v_partition_name;
        return v_partition_name || ' уже существует';
    end if;
    
    -- Создаем партицию
    execute format(
        'create table invest_candles.daily_candles_%s partition of invest_candles.daily_candles ' ||
        'for values from (%L) to (%L)',
        to_char(v_month_start, 'YYYY_MM'),
        v_start_time,
        v_end_time
    );
    
    -- Устанавливаем владельца
    execute format(
        'alter table invest_candles.daily_candles_%s owner to postgres',
        to_char(v_month_start, 'YYYY_MM')
    );
    
    raise notice 'Создана партиция % для месяца %', v_partition_name, to_char(v_month_start, 'YYYY-MM');
    return v_partition_name || ' создана успешно';
end;
$$;

comment on function invest_utils.create_daily_candles_partition(date) is 'Функция для автоматического создания месячной партиции таблицы invest_candles.daily_candles';

alter function invest_utils.create_daily_candles_partition(date) owner to postgres;

-- Функция для создания месячной партиции для invest_prices.close_prices
create or replace function invest_utils.create_close_prices_partition(p_date date)
returns text
language plpgsql
as $$
declare
    v_partition_name text;
    v_month_start date;
    v_next_month date;
begin
    -- Определяем начало месяца указанной даты
    v_month_start := date_trunc('month', p_date)::date;
    
    -- Формируем имя партиции: close_prices_YYYY_MM
    v_partition_name := 'invest_prices.close_prices_' || to_char(v_month_start, 'YYYY_MM');
    
    -- Следующий месяц
    v_next_month := v_month_start + interval '1 month';
    
    -- Проверяем, существует ли партиция
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'invest_prices'
          and c.relname = 'close_prices_' || to_char(v_month_start, 'YYYY_MM')
    ) then
        raise notice 'Партиция % уже существует', v_partition_name;
        return v_partition_name || ' уже существует';
    end if;
    
    -- Создаем партицию
    execute format(
        'create table invest_prices.close_prices_%s partition of invest_prices.close_prices ' ||
        'for values from (%L) to (%L)',
        to_char(v_month_start, 'YYYY_MM'),
        v_month_start,
        v_next_month
    );
    
    -- Устанавливаем владельца
    execute format(
        'alter table invest_prices.close_prices_%s owner to postgres',
        to_char(v_month_start, 'YYYY_MM')
    );
    
    raise notice 'Создана партиция % для месяца %', v_partition_name, to_char(v_month_start, 'YYYY-MM');
    return v_partition_name || ' создана успешно';
end;
$$;

comment on function invest_utils.create_close_prices_partition(date) is 'Функция для автоматического создания месячной партиции таблицы invest_prices.close_prices';

alter function invest_utils.create_close_prices_partition(date) owner to postgres;

-- Функция для создания месячной партиции для invest_prices.close_prices_evening_session
create or replace function invest_utils.create_close_prices_evening_session_partition(p_date date)
returns text
language plpgsql
as $$
declare
    v_partition_name text;
    v_month_start date;
    v_next_month date;
begin
    -- Определяем начало месяца указанной даты
    v_month_start := date_trunc('month', p_date)::date;
    
    -- Формируем имя партиции: close_prices_evening_session_YYYY_MM
    v_partition_name := 'invest_prices.close_prices_evening_session_' || to_char(v_month_start, 'YYYY_MM');
    
    -- Следующий месяц
    v_next_month := v_month_start + interval '1 month';
    
    -- Проверяем, существует ли партиция
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'invest_prices'
          and c.relname = 'close_prices_evening_session_' || to_char(v_month_start, 'YYYY_MM')
    ) then
        raise notice 'Партиция % уже существует', v_partition_name;
        return v_partition_name || ' уже существует';
    end if;
    
    -- Создаем партицию
    execute format(
        'create table invest_prices.close_prices_evening_session_%s partition of invest_prices.close_prices_evening_session ' ||
        'for values from (%L) to (%L)',
        to_char(v_month_start, 'YYYY_MM'),
        v_month_start,
        v_next_month
    );
    
    -- Устанавливаем владельца
    execute format(
        'alter table invest_prices.close_prices_evening_session_%s owner to postgres',
        to_char(v_month_start, 'YYYY_MM')
    );
    
    raise notice 'Создана партиция % для месяца %', v_partition_name, to_char(v_month_start, 'YYYY-MM');
    return v_partition_name || ' создана успешно';
end;
$$;

comment on function invest_utils.create_close_prices_evening_session_partition(date) is 'Функция для автоматического создания месячной партиции таблицы invest_prices.close_prices_evening_session';

alter function invest_utils.create_close_prices_evening_session_partition(date) owner to postgres;

-- Функция для создания дневной партиции для invest_prices.last_prices
create or replace function invest_utils.create_last_prices_partition(p_date date)
returns text
language plpgsql
as $$
declare
    v_partition_name text;
    v_start_time timestamp(6);
    v_end_time timestamp(6);
begin
    -- Формируем имя партиции: last_prices_YYYY_MM_DD
    v_partition_name := 'invest_prices.last_prices_' || to_char(p_date, 'YYYY_MM_DD');
    
    -- Диапазон: от начала дня до начала следующего дня
    v_start_time := p_date::timestamp(6);
    v_end_time := (p_date + interval '1 day')::timestamp(6);
    
    -- Проверяем, существует ли партиция
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'invest_prices'
          and c.relname = 'last_prices_' || to_char(p_date, 'YYYY_MM_DD')
    ) then
        raise notice 'Партиция % уже существует', v_partition_name;
        return v_partition_name || ' уже существует';
    end if;
    
    -- Создаем партицию
    execute format(
        'create table invest_prices.last_prices_%s partition of invest_prices.last_prices ' ||
        'for values from (%L) to (%L)',
        to_char(p_date, 'YYYY_MM_DD'),
        v_start_time,
        v_end_time
    );
    
    -- Добавляем комментарий
    execute format(
        'comment on table invest_prices.last_prices_%s is %L',
        to_char(p_date, 'YYYY_MM_DD'),
        'Партиция сделок за ' || to_char(p_date, 'DD.MM.YYYY')
    );
    
    -- Устанавливаем владельца
    execute format(
        'alter table invest_prices.last_prices_%s owner to postgres',
        to_char(p_date, 'YYYY_MM_DD')
    );
    
    raise notice 'Создана партиция % для даты %', v_partition_name, p_date;
    return v_partition_name || ' создана успешно';
end;
$$;

comment on function invest_utils.create_last_prices_partition(date) is 'Функция для автоматического создания дневной партиции таблицы invest_prices.last_prices';

alter function invest_utils.create_last_prices_partition(date) owner to postgres;

-- Функция для создания месячной партиции для invest_prices.open_prices
create or replace function invest_utils.create_open_prices_partition(p_date date)
returns text
language plpgsql
as $$
declare
    v_partition_name text;
    v_month_start date;
    v_next_month date;
begin
    -- Определяем начало месяца указанной даты
    v_month_start := date_trunc('month', p_date)::date;
    
    -- Формируем имя партиции: open_prices_YYYY_MM
    v_partition_name := 'invest_prices.open_prices_' || to_char(v_month_start, 'YYYY_MM');
    
    -- Следующий месяц
    v_next_month := v_month_start + interval '1 month';
    
    -- Проверяем, существует ли партиция
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'invest_prices'
          and c.relname = 'open_prices_' || to_char(v_month_start, 'YYYY_MM')
    ) then
        raise notice 'Партиция % уже существует', v_partition_name;
        return v_partition_name || ' уже существует';
    end if;
    
    -- Создаем партицию
    execute format(
        'create table invest_prices.open_prices_%s partition of invest_prices.open_prices ' ||
        'for values from (%L) to (%L)',
        to_char(v_month_start, 'YYYY_MM'),
        v_month_start,
        v_next_month
    );
    
    -- Добавляем комментарий
    execute format(
        'comment on table invest_prices.open_prices_%s is %L',
        to_char(v_month_start, 'YYYY_MM'),
        'Партиция для ' || to_char(v_month_start, 'YYYY-MM-DD') || ' — ' || 
        to_char(v_next_month - interval '1 day', 'YYYY-MM-DD')
    );
    
    -- Устанавливаем владельца
    execute format(
        'alter table invest_prices.open_prices_%s owner to postgres',
        to_char(v_month_start, 'YYYY_MM')
    );
    
    raise notice 'Создана партиция % для месяца %', v_partition_name, to_char(v_month_start, 'YYYY-MM');
    return v_partition_name || ' создана успешно';
end;
$$;

comment on function invest_utils.create_open_prices_partition(date) is 'Функция для автоматического создания месячной партиции таблицы invest_prices.open_prices';

alter function invest_utils.create_open_prices_partition(date) owner to postgres;

-- Функция для создания дневной партиции для invest_prices.trades
create or replace function invest_utils.create_trades_partition(p_date date)
returns text
language plpgsql
as $$
declare
    v_partition_name text;
    v_start_time timestamp(6);
    v_end_time timestamp(6);
begin
    -- Формируем имя партиции: trades_YYYY_MM_DD
    v_partition_name := 'invest_prices.trades_' || to_char(p_date, 'YYYY_MM_DD');
    
    -- Диапазон: от начала дня до начала следующего дня
    v_start_time := p_date::timestamp(6);
    v_end_time := (p_date + interval '1 day')::timestamp(6);
    
    -- Проверяем, существует ли партиция
    if exists (
        select 1
        from pg_class c
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'invest_prices'
          and c.relname = 'trades_' || to_char(p_date, 'YYYY_MM_DD')
    ) then
        raise notice 'Партиция % уже существует', v_partition_name;
        return v_partition_name || ' уже существует';
    end if;
    
    -- Создаем партицию
    execute format(
        'create table invest_prices.trades_%s partition of invest_prices.trades ' ||
        'for values from (%L) to (%L)',
        to_char(p_date, 'YYYY_MM_DD'),
        v_start_time,
        v_end_time
    );
    
    -- Добавляем комментарий
    execute format(
        'comment on table invest_prices.trades_%s is %L',
        to_char(p_date, 'YYYY_MM_DD'),
        'Партиция сделок за ' || to_char(p_date, 'DD.MM.YYYY')
    );
    
    -- Устанавливаем владельца
    execute format(
        'alter table invest_prices.trades_%s owner to postgres',
        to_char(p_date, 'YYYY_MM_DD')
    );
    
    raise notice 'Создана партиция % для даты %', v_partition_name, p_date;
    return v_partition_name || ' создана успешно';
end;
$$;

comment on function invest_utils.create_trades_partition(date) is 'Функция для автоматического создания дневной партиции таблицы invest_prices.trades';

alter function invest_utils.create_trades_partition(date) owner to postgres;

-- ============================================================================
-- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ ФУНКЦИЙ ДЛЯ СОЗДАНИЯ ПАРТИЦИЙ
-- ============================================================================

-- Пример 1: Создание дневной партиции для минутных свечей на конкретную дату
-- Создает партицию minute_candles_2024_12_01 для данных за 1 декабря 2024 года
SELECT invest_utils.create_minute_candles_partition('2024-12-01'::date);

-- Пример 2: Создание дневной партиции для текущей даты
-- Создает партицию для сегодняшнего дня
SELECT invest_utils.create_minute_candles_partition(CURRENT_DATE);

-- Пример 3: Создание дневной партиции для завтрашнего дня
-- Полезно для подготовки партиций заранее
SELECT invest_utils.create_minute_candles_partition(CURRENT_DATE + INTERVAL '1 day');

-- Пример 4: Массовое создание дневных партиций для периода
-- Создает партиции для всех дней в декабре 2024 года
DO $$
DECLARE
    v_date date;
BEGIN
    FOR v_date IN 
        SELECT generate_series('2024-12-01'::date, '2024-12-31'::date, INTERVAL '1 day')::date
    LOOP
        PERFORM invest_utils.create_minute_candles_partition(v_date);
    END LOOP;
END $$;

-- Пример 5: Создание месячной партиции для дневных свечей
-- Создает партицию daily_candles_2024_12 для декабря 2024 года
-- (можно указать любую дату из месяца, например 15 декабря)
SELECT invest_utils.create_daily_candles_partition('2024-12-15'::date);

-- Пример 6: Создание месячной партиции для текущего месяца
-- Создает партицию для месяца текущей даты
SELECT invest_utils.create_daily_candles_partition(CURRENT_DATE);

-- Пример 7: Создание месячной партиции для следующего месяца
-- Полезно для подготовки партиций заранее
SELECT invest_utils.create_daily_candles_partition((CURRENT_DATE + INTERVAL '1 month')::date);

-- Пример 8: Массовое создание месячных партиций для периода
-- Создает партиции для всех месяцев с января по декабрь 2024 года
DO $$
DECLARE
    v_date date;
BEGIN
    FOR v_date IN 
        SELECT generate_series('2024-01-01'::date, '2024-12-01'::date, INTERVAL '1 month')::date
    LOOP
        PERFORM invest_utils.create_daily_candles_partition(v_date);
    END LOOP;
END $$;

-- Пример 9: Проверка существования партиции перед созданием (автоматически выполняется функцией)
-- Функция автоматически проверяет существование партиции и возвращает сообщение:
-- Если партиция существует: "invest_candles.minute_candles_2024_12_01 уже существует"
-- Если партиция создана: "invest_candles.minute_candles_2024_12_01 создана успешно"
SELECT invest_utils.create_minute_candles_partition('2024-12-01'::date);
-- Повторный вызов для той же даты вернет сообщение о том, что партиция уже существует

-- Пример 10: Создание партиций для обеих таблиц на будущий период
-- Подготовка партиций на неделю вперед для минутных свечей и на месяц вперед для дневных
DO $$
DECLARE
    v_date date;
BEGIN
    -- Создаем дневные партиции на неделю вперед
    FOR v_date IN 
        SELECT generate_series(CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', INTERVAL '1 day')::date
    LOOP
        PERFORM invest_utils.create_minute_candles_partition(v_date);
    END LOOP;
    
    -- Создаем месячные партиции на 3 месяца вперед
    FOR v_date IN 
        SELECT generate_series(CURRENT_DATE, CURRENT_DATE + INTERVAL '3 months', INTERVAL '1 month')::date
    LOOP
        PERFORM invest_utils.create_daily_candles_partition(v_date);
    END LOOP;
    
    RAISE NOTICE 'Партиции созданы успешно';
END $$;

-- ============================================================================
-- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ ФУНКЦИЙ ДЛЯ СОЗДАНИЯ ПАРТИЦИЙ invest_prices.close_prices
-- ============================================================================

-- Пример 11: Создание месячной партиции для close_prices
-- Создает партицию close_prices_2024_12 для декабря 2024 года
-- (можно указать любую дату из месяца, например 15 декабря)
SELECT invest_utils.create_close_prices_partition('2024-12-15'::date);

-- Пример 12: Создание партиции для текущего месяца
-- Создает партицию для месяца текущей даты
SELECT invest_utils.create_close_prices_partition(CURRENT_DATE);

-- Пример 13: Создание партиции для следующего месяца
-- Полезно для подготовки партиций заранее
SELECT invest_utils.create_close_prices_partition((CURRENT_DATE + INTERVAL '1 month')::date);

-- Пример 14: Массовое создание партиций для close_prices за период
-- Создает партиции для всех месяцев с января по декабрь 2024 года
DO $$
DECLARE
    v_date date;
BEGIN
    FOR v_date IN 
        SELECT generate_series('2024-01-01'::date, '2024-12-01'::date, INTERVAL '1 month')::date
    LOOP
        PERFORM invest_utils.create_close_prices_partition(v_date);
    END LOOP;
END $$;

-- ============================================================================
-- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ ФУНКЦИЙ ДЛЯ СОЗДАНИЯ ПАРТИЦИЙ invest_prices.close_prices_evening_session
-- ============================================================================

-- Пример 15: Создание месячной партиции для close_prices_evening_session
-- Создает партицию close_prices_evening_session_2024_12 для декабря 2024 года
SELECT invest_utils.create_close_prices_evening_session_partition('2024-12-15'::date);

-- Пример 16: Создание партиции для текущего месяца
SELECT invest_utils.create_close_prices_evening_session_partition(CURRENT_DATE);

-- Пример 17: Создание партиции для следующего месяца
SELECT invest_utils.create_close_prices_evening_session_partition((CURRENT_DATE + INTERVAL '1 month')::date);

-- Пример 18: Массовое создание партиций для close_prices_evening_session за период
DO $$
DECLARE
    v_date date;
BEGIN
    FOR v_date IN 
        SELECT generate_series('2024-01-01'::date, '2024-12-01'::date, INTERVAL '1 month')::date
    LOOP
        PERFORM invest_utils.create_close_prices_evening_session_partition(v_date);
    END LOOP;
END $$;

-- Пример 19: Создание партиций для обеих таблиц invest_prices одновременно
-- Создает партиции для close_prices и close_prices_evening_session на несколько месяцев вперед
DO $$
DECLARE
    v_date date;
BEGIN
    -- Создаем партиции на 6 месяцев вперед для обеих таблиц
    FOR v_date IN 
        SELECT generate_series(CURRENT_DATE, CURRENT_DATE + INTERVAL '6 months', INTERVAL '1 month')::date
    LOOP
        PERFORM invest_utils.create_close_prices_partition(v_date);
        PERFORM invest_utils.create_close_prices_evening_session_partition(v_date);
    END LOOP;
    
    RAISE NOTICE 'Партиции для invest_prices созданы успешно';
END $$;

-- Пример 20: Проверка существования партиции (автоматически выполняется функцией)
-- Функция автоматически проверяет существование и возвращает сообщение:
-- Если партиция существует: "invest_prices.close_prices_2024_12 уже существует"
-- Если партиция создана: "invest_prices.close_prices_2024_12 создана успешно"
SELECT invest_utils.create_close_prices_partition('2024-12-01'::date);
SELECT invest_utils.create_close_prices_evening_session_partition('2024-12-01'::date);

-- ============================================================================
-- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ ФУНКЦИЙ ДЛЯ СОЗДАНИЯ ПАРТИЦИЙ invest_prices.last_prices
-- ============================================================================

-- Пример 21: Создание дневной партиции для last_prices на конкретную дату
-- Создает партицию last_prices_2024_12_01 для данных за 1 декабря 2024 года
SELECT invest_utils.create_last_prices_partition('2024-12-01'::date);

-- Пример 22: Создание дневной партиции для текущей даты
-- Создает партицию для сегодняшнего дня
SELECT invest_utils.create_last_prices_partition(CURRENT_DATE);

-- Пример 23: Создание дневной партиции для завтрашнего дня
-- Полезно для подготовки партиций заранее
SELECT invest_utils.create_last_prices_partition(CURRENT_DATE + INTERVAL '1 day');

-- Пример 24: Массовое создание дневных партиций для периода
-- Создает партиции для всех дней в декабре 2024 года
DO $$
DECLARE
    v_date date;
BEGIN
    FOR v_date IN 
        SELECT generate_series('2024-12-01'::date, '2024-12-31'::date, INTERVAL '1 day')::date
    LOOP
        PERFORM invest_utils.create_last_prices_partition(v_date);
    END LOOP;
END $$;

-- Пример 25: Создание партиций на неделю вперед
-- Подготовка партиций для следующей недели
DO $$
DECLARE
    v_date date;
BEGIN
    FOR v_date IN 
        SELECT generate_series(CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', INTERVAL '1 day')::date
    LOOP
        PERFORM invest_utils.create_last_prices_partition(v_date);
    END LOOP;
    
    RAISE NOTICE 'Партиции для last_prices созданы успешно';
END $$;

-- Пример 26: Проверка существования партиции last_prices
-- Функция автоматически проверяет существование и возвращает сообщение:
-- Если партиция существует: "invest_prices.last_prices_2024_12_01 уже существует"
-- Если партиция создана: "invest_prices.last_prices_2024_12_01 создана успешно"
SELECT invest_utils.create_last_prices_partition('2024-12-01'::date);
-- Повторный вызов для той же даты вернет сообщение о том, что партиция уже существует

-- ============================================================================
-- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ ФУНКЦИЙ ДЛЯ СОЗДАНИЯ ПАРТИЦИЙ invest_prices.open_prices
-- ============================================================================

-- Пример 27: Создание месячной партиции для open_prices
-- Создает партицию open_prices_2024_12 для декабря 2024 года
-- (можно указать любую дату из месяца, например 15 декабря)
SELECT invest_utils.create_open_prices_partition('2024-12-15'::date);

-- Пример 28: Создание партиции для текущего месяца
-- Создает партицию для месяца текущей даты
SELECT invest_utils.create_open_prices_partition(CURRENT_DATE);

-- Пример 29: Создание партиции для следующего месяца
-- Полезно для подготовки партиций заранее
SELECT invest_utils.create_open_prices_partition((CURRENT_DATE + INTERVAL '1 month')::date);

-- Пример 30: Массовое создание партиций для open_prices за период
-- Создает партиции для всех месяцев с января по декабрь 2024 года
DO $$
DECLARE
    v_date date;
BEGIN
    FOR v_date IN 
        SELECT generate_series('2024-01-01'::date, '2024-12-01'::date, INTERVAL '1 month')::date
    LOOP
        PERFORM invest_utils.create_open_prices_partition(v_date);
    END LOOP;
END $$;

-- Пример 31: Проверка существования партиции open_prices
-- Функция автоматически проверяет существование и возвращает сообщение:
-- Если партиция существует: "invest_prices.open_prices_2024_12 уже существует"
-- Если партиция создана: "invest_prices.open_prices_2024_12 создана успешно"
SELECT invest_utils.create_open_prices_partition('2024-12-01'::date);
-- Повторный вызов для того же месяца вернет сообщение о том, что партиция уже существует

-- Пример 32: Создание партиций для обеих таблиц invest_prices одновременно
-- Создает партиции для open_prices и close_prices на несколько месяцев вперед
DO $$
DECLARE
    v_date date;
BEGIN
    -- Создаем партиции на 6 месяцев вперед для обеих таблиц
    FOR v_date IN 
        SELECT generate_series(CURRENT_DATE, CURRENT_DATE + INTERVAL '6 months', INTERVAL '1 month')::date
    LOOP
        PERFORM invest_utils.create_open_prices_partition(v_date);
        PERFORM invest_utils.create_close_prices_partition(v_date);
    END LOOP;
    
    RAISE NOTICE 'Партиции для open_prices и close_prices созданы успешно';
END $$;

-- Пример 33: Комплексная подготовка партиций для всех таблиц invest_prices
-- Создает партиции для open_prices, close_prices и close_prices_evening_session на год вперед,
-- а также дневные партиции для last_prices на месяц вперед
DO $$
DECLARE
    v_date date;
    v_day date;
BEGIN
    -- Создаем месячные партиции для open_prices, close_prices и close_prices_evening_session
    FOR v_date IN 
        SELECT generate_series(CURRENT_DATE, CURRENT_DATE + INTERVAL '12 months', INTERVAL '1 month')::date
    LOOP
        PERFORM invest_utils.create_open_prices_partition(v_date);
        PERFORM invest_utils.create_close_prices_partition(v_date);
        PERFORM invest_utils.create_close_prices_evening_session_partition(v_date);
    END LOOP;
    
    -- Создаем дневные партиции для last_prices на месяц вперед
    FOR v_day IN 
        SELECT generate_series(CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', INTERVAL '1 day')::date
    LOOP
        PERFORM invest_utils.create_last_prices_partition(v_day);
    END LOOP;
    
    RAISE NOTICE 'Все партиции для invest_prices созданы успешно';
END $$;

-- ============================================================================
-- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ ФУНКЦИЙ ДЛЯ СОЗДАНИЯ ПАРТИЦИЙ invest_prices.trades
-- ============================================================================

-- Пример 34: Создание дневной партиции для trades на конкретную дату
-- Создает партицию trades_2024_12_01 для данных за 1 декабря 2024 года
SELECT invest_utils.create_trades_partition('2024-12-01'::date);

-- Пример 35: Создание дневной партиции для текущей даты
-- Создает партицию для сегодняшнего дня
SELECT invest_utils.create_trades_partition(CURRENT_DATE);

-- Пример 36: Создание дневной партиции для завтрашнего дня
-- Полезно для подготовки партиций заранее
SELECT invest_utils.create_trades_partition(CURRENT_DATE + INTERVAL '1 day');

-- Пример 37: Массовое создание дневных партиций для периода
-- Создает партиции для всех дней в декабре 2024 года
DO $$
DECLARE
    v_date date;
BEGIN
    FOR v_date IN 
        SELECT generate_series('2024-12-01'::date, '2024-12-31'::date, INTERVAL '1 day')::date
    LOOP
        PERFORM invest_utils.create_trades_partition(v_date);
    END LOOP;
END $$;

-- Пример 38: Создание партиций на неделю вперед
-- Подготовка партиций для следующей недели
DO $$
DECLARE
    v_date date;
BEGIN
    FOR v_date IN 
        SELECT generate_series(CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', INTERVAL '1 day')::date
    LOOP
        PERFORM invest_utils.create_trades_partition(v_date);
    END LOOP;
    
    RAISE NOTICE 'Партиции для trades созданы успешно';
END $$;

-- Пример 39: Массовое создание партиций для всего периода (2024-01-01 до 2026-12-31)
-- Создает партиции для всех дней с 1 января 2024 года по 31 декабря 2026 года (1096 дней)
DO $$
DECLARE
    v_date date;
    v_start_date date := '2024-01-01'::date;
    v_end_date date := '2026-12-31'::date;
    v_counter integer := 0;
BEGIN
    FOR v_date IN 
        SELECT generate_series(v_start_date, v_end_date, INTERVAL '1 day')::date
    LOOP
        PERFORM invest_utils.create_trades_partition(v_date);
        v_counter := v_counter + 1;
        
        -- Выводим прогресс каждые 100 дней
        IF v_counter % 100 = 0 THEN
            RAISE NOTICE 'Создано % партиций из %', v_counter, (v_end_date - v_start_date + 1);
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Все партиции для trades созданы успешно. Всего создано: %', v_counter;
END $$;

-- Пример 40: Создание партиций для конкретного месяца
-- Создает партиции для всех дней января 2025 года
DO $$
DECLARE
    v_date date;
BEGIN
    FOR v_date IN 
        SELECT generate_series('2025-01-01'::date, '2025-01-31'::date, INTERVAL '1 day')::date
    LOOP
        PERFORM invest_utils.create_trades_partition(v_date);
    END LOOP;
    
    RAISE NOTICE 'Партиции для января 2025 созданы успешно';
END $$;

-- Пример 41: Создание партиций для конкретного года
-- Создает партиции для всех дней 2025 года
DO $$
DECLARE
    v_date date;
    v_counter integer := 0;
BEGIN
    FOR v_date IN 
        SELECT generate_series('2025-01-01'::date, '2025-12-31'::date, INTERVAL '1 day')::date
    LOOP
        PERFORM invest_utils.create_trades_partition(v_date);
        v_counter := v_counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Партиции для 2025 года созданы успешно. Всего: %', v_counter;
END $$;

-- Пример 42: Проверка существования партиции trades
-- Функция автоматически проверяет существование и возвращает сообщение:
-- Если партиция существует: "invest_prices.trades_2024_12_01 уже существует"
-- Если партиция создана: "invest_prices.trades_2024_12_01 создана успешно"
SELECT invest_utils.create_trades_partition('2024-12-01'::date);
-- Повторный вызов для той же даты вернет сообщение о том, что партиция уже существует

-- Пример 43: Создание партиций для trades и last_prices одновременно
-- Подготовка партиций для обеих таблиц на месяц вперед
DO $$
DECLARE
    v_date date;
BEGIN
    FOR v_date IN 
        SELECT generate_series(CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', INTERVAL '1 day')::date
    LOOP
        PERFORM invest_utils.create_trades_partition(v_date);
        PERFORM invest_utils.create_last_prices_partition(v_date);
    END LOOP;
    
    RAISE NOTICE 'Партиции для trades и last_prices созданы успешно';
END $$;

-- Пример 44: Комплексная подготовка партиций для всех дневных таблиц
-- Создает партиции для trades и last_prices на месяц вперед
DO $$
DECLARE
    v_date date;
BEGIN
    FOR v_date IN 
        SELECT generate_series(CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', INTERVAL '1 day')::date
    LOOP
        PERFORM invest_utils.create_trades_partition(v_date);
        PERFORM invest_utils.create_last_prices_partition(v_date);
    END LOOP;
    
    RAISE NOTICE 'Все дневные партиции созданы успешно';
END $$;

-- ============================================================================
-- ПОЛЕЗНЫЕ ЗАПРОСЫ
-- ============================================================================

--Проверка последних логов
select * from invest.system_logs sl
order by sl.start_time desc 