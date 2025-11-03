--Схема invest_candles - схема для хранения свечей
CREATE SCHEMA IF NOT EXISTS invest_candles;

--Проверки:
--1. Проверяем объем торгов минутных свечей за день и дневных свечей по акциям и фьючерсам за день с помощью run_daily_vs_minute_check,
--неудачные проверки сохраняются в таблице data_quality_issues.
--2. С помощью функции analyze_candle_patterns анализируем инструменты, которые падали 5 и более дней подряд, исключая праздники и выходные. 
--Результат логируем в таблицу candle_pattern_analysis. По таким инструментам работает стратегия на продолжение движения:
--Если акция падает, то шортим ее. Если акция растет, то лонгируем ее.

-- Таблица хранения минутных свечей
create table invest_candles.minute_candles
(
    figi                 varchar(255)                              not null,
    time                 timestamp(6) with time zone               not null,
    close                numeric(18, 9)                            not null,
    created_at           timestamp(6) with time zone default now() not null,
    high                 numeric(18, 9)                            not null,
    is_complete          boolean                                   not null,
    low                  numeric(18, 9)                            not null,
    open                 numeric(18, 9)                            not null,
    updated_at           timestamp(6) with time zone default now() not null,
    volume               bigint                                    not null,
    price_change         numeric(18, 9),
    price_change_percent numeric(18, 4),
    candle_type          varchar(20),
    body_size            numeric(18, 9),
    upper_shadow         numeric(18, 9),
    lower_shadow         numeric(18, 9),
    high_low_range       numeric(18, 9),
    average_price        numeric(18, 2),
    primary key (figi, time)
)
    partition by RANGE ("time");

comment on table minute_candles is 'Таблица минутных свечей финансовых инструментов с ежедневным партиционированием';

comment on column minute_candles.figi is 'Уникальный идентификатор инструмента (Financial Instrument Global Identifier)';

comment on column minute_candles.time is 'Время начала минутной свечи в московской таймзоне';

comment on column minute_candles.close is 'Цена закрытия за минуту с точностью до 9 знаков после запятой';

comment on column minute_candles.created_at is 'Время создания записи в московской таймзоне';

comment on column minute_candles.high is 'Максимальная цена за минуту с точностью до 9 знаков после запятой';

comment on column minute_candles.is_complete is 'Флаг завершенности свечи (true - свеча завершена, false - формируется)';

comment on column minute_candles.low is 'Минимальная цена за минуту с точностью до 9 знаков после запятой';

comment on column minute_candles.open is 'Цена открытия за минуту с точностью до 9 знаков после запятой';

comment on column minute_candles.updated_at is 'Время последнего обновления записи в московской таймзоне';

comment on column minute_candles.volume is 'Объем торгов за минуту (количество лотов)';

comment on column minute_candles.price_change is 'Изменение цены (close - open)';

comment on column minute_candles.price_change_percent is 'Процентное изменение цены';

comment on column minute_candles.candle_type is 'Тип свечи: BULLISH, BEARISH, DOJI';

comment on column minute_candles.body_size is 'Размер тела свечи (абсолютное значение изменения цены)';

comment on column minute_candles.upper_shadow is 'Верхняя тень свечи';

comment on column minute_candles.lower_shadow is 'Нижняя тень свечи';

comment on column minute_candles.high_low_range is 'Диапазон цен (high - low)';

comment on column minute_candles.average_price is 'Средняя цена (high + low + open + close) / 4';

alter table minute_candles
    owner to postgres;

create index idx_minute_candles_time
    on minute_candles (time);

create index idx_minute_candles_figi_time
    on minute_candles (figi, time);

-- Создание синонима в схеме invest для удобства использования
create or replace view invest.minute_candles as
select 
    figi,
    time,
    close,
    created_at,
    high,
    is_complete,
    low,
    open,
    updated_at,
    volume,
    price_change,
    price_change_percent,
    candle_type,
    body_size,
    upper_shadow,
    lower_shadow,
    high_low_range,
    average_price
from invest_candles.minute_candles;

comment on view invest.minute_candles is 'Синоним для таблицы minute_candles из схемы invest_candles';

-- Права доступа на представление
alter view invest.minute_candles owner to postgres;

create table minute_candles_2024_06_01
    partition of minute_candles
        FOR VALUES FROM ('2024-05-31 21:00:00+00') TO ('2024-06-01 21:00:00+00');

alter table minute_candles_2024_06_01
    owner to postgres;

grant select on minute_candles_2024_06_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_01 to admin;

create table minute_candles_2024_06_02
    partition of minute_candles
        FOR VALUES FROM ('2024-06-01 21:00:00+00') TO ('2024-06-02 21:00:00+00');

alter table minute_candles_2024_06_02
    owner to postgres;

grant select on minute_candles_2024_06_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_02 to admin;

create table minute_candles_2024_06_03
    partition of minute_candles
        FOR VALUES FROM ('2024-06-02 21:00:00+00') TO ('2024-06-03 21:00:00+00');

alter table minute_candles_2024_06_03
    owner to postgres;

grant select on minute_candles_2024_06_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_03 to admin;

create table minute_candles_2024_06_04
    partition of minute_candles
        FOR VALUES FROM ('2024-06-03 21:00:00+00') TO ('2024-06-04 21:00:00+00');

alter table minute_candles_2024_06_04
    owner to postgres;

grant select on minute_candles_2024_06_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_04 to admin;

create table minute_candles_2024_06_05
    partition of minute_candles
        FOR VALUES FROM ('2024-06-04 21:00:00+00') TO ('2024-06-05 21:00:00+00');

alter table minute_candles_2024_06_05
    owner to postgres;

grant select on minute_candles_2024_06_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_05 to admin;

create table minute_candles_2024_06_06
    partition of minute_candles
        FOR VALUES FROM ('2024-06-05 21:00:00+00') TO ('2024-06-06 21:00:00+00');

alter table minute_candles_2024_06_06
    owner to postgres;

grant select on minute_candles_2024_06_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_06 to admin;

create table minute_candles_2024_06_07
    partition of minute_candles
        FOR VALUES FROM ('2024-06-06 21:00:00+00') TO ('2024-06-07 21:00:00+00');

alter table minute_candles_2024_06_07
    owner to postgres;

grant select on minute_candles_2024_06_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_07 to admin;

create table minute_candles_2024_06_08
    partition of minute_candles
        FOR VALUES FROM ('2024-06-07 21:00:00+00') TO ('2024-06-08 21:00:00+00');

alter table minute_candles_2024_06_08
    owner to postgres;

grant select on minute_candles_2024_06_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_08 to admin;

create table minute_candles_2024_06_09
    partition of minute_candles
        FOR VALUES FROM ('2024-06-08 21:00:00+00') TO ('2024-06-09 21:00:00+00');

alter table minute_candles_2024_06_09
    owner to postgres;

grant select on minute_candles_2024_06_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_09 to admin;

create table minute_candles_2024_06_10
    partition of minute_candles
        FOR VALUES FROM ('2024-06-09 21:00:00+00') TO ('2024-06-10 21:00:00+00');

alter table minute_candles_2024_06_10
    owner to postgres;

grant select on minute_candles_2024_06_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_10 to admin;

create table minute_candles_2024_06_11
    partition of minute_candles
        FOR VALUES FROM ('2024-06-10 21:00:00+00') TO ('2024-06-11 21:00:00+00');

alter table minute_candles_2024_06_11
    owner to postgres;

grant select on minute_candles_2024_06_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_11 to admin;

create table minute_candles_2024_06_12
    partition of minute_candles
        FOR VALUES FROM ('2024-06-11 21:00:00+00') TO ('2024-06-12 21:00:00+00');

alter table minute_candles_2024_06_12
    owner to postgres;

grant select on minute_candles_2024_06_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_12 to admin;

create table minute_candles_2024_06_13
    partition of minute_candles
        FOR VALUES FROM ('2024-06-12 21:00:00+00') TO ('2024-06-13 21:00:00+00');

alter table minute_candles_2024_06_13
    owner to postgres;

grant select on minute_candles_2024_06_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_13 to admin;

create table minute_candles_2024_06_14
    partition of minute_candles
        FOR VALUES FROM ('2024-06-13 21:00:00+00') TO ('2024-06-14 21:00:00+00');

alter table minute_candles_2024_06_14
    owner to postgres;

grant select on minute_candles_2024_06_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_14 to admin;

create table minute_candles_2024_06_15
    partition of minute_candles
        FOR VALUES FROM ('2024-06-14 21:00:00+00') TO ('2024-06-15 21:00:00+00');

alter table minute_candles_2024_06_15
    owner to postgres;

grant select on minute_candles_2024_06_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_15 to admin;

create table minute_candles_2024_06_16
    partition of minute_candles
        FOR VALUES FROM ('2024-06-15 21:00:00+00') TO ('2024-06-16 21:00:00+00');

alter table minute_candles_2024_06_16
    owner to postgres;

grant select on minute_candles_2024_06_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_16 to admin;

create table minute_candles_2024_06_17
    partition of minute_candles
        FOR VALUES FROM ('2024-06-16 21:00:00+00') TO ('2024-06-17 21:00:00+00');

alter table minute_candles_2024_06_17
    owner to postgres;

grant select on minute_candles_2024_06_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_17 to admin;

create table minute_candles_2024_06_18
    partition of minute_candles
        FOR VALUES FROM ('2024-06-17 21:00:00+00') TO ('2024-06-18 21:00:00+00');

alter table minute_candles_2024_06_18
    owner to postgres;

grant select on minute_candles_2024_06_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_18 to admin;

create table minute_candles_2024_06_19
    partition of minute_candles
        FOR VALUES FROM ('2024-06-18 21:00:00+00') TO ('2024-06-19 21:00:00+00');

alter table minute_candles_2024_06_19
    owner to postgres;

grant select on minute_candles_2024_06_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_19 to admin;

create table minute_candles_2024_06_20
    partition of minute_candles
        FOR VALUES FROM ('2024-06-19 21:00:00+00') TO ('2024-06-20 21:00:00+00');

alter table minute_candles_2024_06_20
    owner to postgres;

grant select on minute_candles_2024_06_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_20 to admin;

create table minute_candles_2024_06_21
    partition of minute_candles
        FOR VALUES FROM ('2024-06-20 21:00:00+00') TO ('2024-06-21 21:00:00+00');

alter table minute_candles_2024_06_21
    owner to postgres;

grant select on minute_candles_2024_06_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_21 to admin;

create table minute_candles_2024_06_22
    partition of minute_candles
        FOR VALUES FROM ('2024-06-21 21:00:00+00') TO ('2024-06-22 21:00:00+00');

alter table minute_candles_2024_06_22
    owner to postgres;

grant select on minute_candles_2024_06_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_22 to admin;

create table minute_candles_2024_06_23
    partition of minute_candles
        FOR VALUES FROM ('2024-06-22 21:00:00+00') TO ('2024-06-23 21:00:00+00');

alter table minute_candles_2024_06_23
    owner to postgres;

grant select on minute_candles_2024_06_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_23 to admin;

create table minute_candles_2024_06_24
    partition of minute_candles
        FOR VALUES FROM ('2024-06-23 21:00:00+00') TO ('2024-06-24 21:00:00+00');

alter table minute_candles_2024_06_24
    owner to postgres;

grant select on minute_candles_2024_06_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_24 to admin;

create table minute_candles_2024_06_25
    partition of minute_candles
        FOR VALUES FROM ('2024-06-24 21:00:00+00') TO ('2024-06-25 21:00:00+00');

alter table minute_candles_2024_06_25
    owner to postgres;

grant select on minute_candles_2024_06_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_25 to admin;

create table minute_candles_2024_06_26
    partition of minute_candles
        FOR VALUES FROM ('2024-06-25 21:00:00+00') TO ('2024-06-26 21:00:00+00');

alter table minute_candles_2024_06_26
    owner to postgres;

grant select on minute_candles_2024_06_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_26 to admin;

create table minute_candles_2024_06_27
    partition of minute_candles
        FOR VALUES FROM ('2024-06-26 21:00:00+00') TO ('2024-06-27 21:00:00+00');

alter table minute_candles_2024_06_27
    owner to postgres;

grant select on minute_candles_2024_06_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_27 to admin;

create table minute_candles_2024_06_28
    partition of minute_candles
        FOR VALUES FROM ('2024-06-27 21:00:00+00') TO ('2024-06-28 21:00:00+00');

alter table minute_candles_2024_06_28
    owner to postgres;

grant select on minute_candles_2024_06_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_28 to admin;

create table minute_candles_2024_06_29
    partition of minute_candles
        FOR VALUES FROM ('2024-06-28 21:00:00+00') TO ('2024-06-29 21:00:00+00');

alter table minute_candles_2024_06_29
    owner to postgres;

grant select on minute_candles_2024_06_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_29 to admin;

create table minute_candles_2024_06_30
    partition of minute_candles
        FOR VALUES FROM ('2024-06-29 21:00:00+00') TO ('2024-06-30 21:00:00+00');

alter table minute_candles_2024_06_30
    owner to postgres;

grant select on minute_candles_2024_06_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_06_30 to admin;

create table minute_candles_2024_07_01
    partition of minute_candles
        FOR VALUES FROM ('2024-06-30 21:00:00+00') TO ('2024-07-01 21:00:00+00');

alter table minute_candles_2024_07_01
    owner to postgres;

grant select on minute_candles_2024_07_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_01 to admin;

create table minute_candles_2024_07_02
    partition of minute_candles
        FOR VALUES FROM ('2024-07-01 21:00:00+00') TO ('2024-07-02 21:00:00+00');

alter table minute_candles_2024_07_02
    owner to postgres;

grant select on minute_candles_2024_07_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_02 to admin;

create table minute_candles_2024_07_03
    partition of minute_candles
        FOR VALUES FROM ('2024-07-02 21:00:00+00') TO ('2024-07-03 21:00:00+00');

alter table minute_candles_2024_07_03
    owner to postgres;

grant select on minute_candles_2024_07_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_03 to admin;

create table minute_candles_2024_07_04
    partition of minute_candles
        FOR VALUES FROM ('2024-07-03 21:00:00+00') TO ('2024-07-04 21:00:00+00');

alter table minute_candles_2024_07_04
    owner to postgres;

grant select on minute_candles_2024_07_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_04 to admin;

create table minute_candles_2024_07_05
    partition of minute_candles
        FOR VALUES FROM ('2024-07-04 21:00:00+00') TO ('2024-07-05 21:00:00+00');

alter table minute_candles_2024_07_05
    owner to postgres;

grant select on minute_candles_2024_07_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_05 to admin;

create table minute_candles_2024_07_06
    partition of minute_candles
        FOR VALUES FROM ('2024-07-05 21:00:00+00') TO ('2024-07-06 21:00:00+00');

alter table minute_candles_2024_07_06
    owner to postgres;

grant select on minute_candles_2024_07_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_06 to admin;

create table minute_candles_2024_07_07
    partition of minute_candles
        FOR VALUES FROM ('2024-07-06 21:00:00+00') TO ('2024-07-07 21:00:00+00');

alter table minute_candles_2024_07_07
    owner to postgres;

grant select on minute_candles_2024_07_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_07 to admin;

create table minute_candles_2024_07_08
    partition of minute_candles
        FOR VALUES FROM ('2024-07-07 21:00:00+00') TO ('2024-07-08 21:00:00+00');

alter table minute_candles_2024_07_08
    owner to postgres;

grant select on minute_candles_2024_07_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_08 to admin;

create table minute_candles_2024_07_09
    partition of minute_candles
        FOR VALUES FROM ('2024-07-08 21:00:00+00') TO ('2024-07-09 21:00:00+00');

alter table minute_candles_2024_07_09
    owner to postgres;

grant select on minute_candles_2024_07_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_09 to admin;

create table minute_candles_2024_07_10
    partition of minute_candles
        FOR VALUES FROM ('2024-07-09 21:00:00+00') TO ('2024-07-10 21:00:00+00');

alter table minute_candles_2024_07_10
    owner to postgres;

grant select on minute_candles_2024_07_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_10 to admin;

create table minute_candles_2024_07_11
    partition of minute_candles
        FOR VALUES FROM ('2024-07-10 21:00:00+00') TO ('2024-07-11 21:00:00+00');

alter table minute_candles_2024_07_11
    owner to postgres;

grant select on minute_candles_2024_07_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_11 to admin;

create table minute_candles_2024_07_12
    partition of minute_candles
        FOR VALUES FROM ('2024-07-11 21:00:00+00') TO ('2024-07-12 21:00:00+00');

alter table minute_candles_2024_07_12
    owner to postgres;

grant select on minute_candles_2024_07_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_12 to admin;

create table minute_candles_2024_07_13
    partition of minute_candles
        FOR VALUES FROM ('2024-07-12 21:00:00+00') TO ('2024-07-13 21:00:00+00');

alter table minute_candles_2024_07_13
    owner to postgres;

grant select on minute_candles_2024_07_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_13 to admin;

create table minute_candles_2024_07_14
    partition of minute_candles
        FOR VALUES FROM ('2024-07-13 21:00:00+00') TO ('2024-07-14 21:00:00+00');

alter table minute_candles_2024_07_14
    owner to postgres;

grant select on minute_candles_2024_07_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_14 to admin;

create table minute_candles_2024_07_15
    partition of minute_candles
        FOR VALUES FROM ('2024-07-14 21:00:00+00') TO ('2024-07-15 21:00:00+00');

alter table minute_candles_2024_07_15
    owner to postgres;

grant select on minute_candles_2024_07_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_15 to admin;

create table minute_candles_2024_07_16
    partition of minute_candles
        FOR VALUES FROM ('2024-07-15 21:00:00+00') TO ('2024-07-16 21:00:00+00');

alter table minute_candles_2024_07_16
    owner to postgres;

grant select on minute_candles_2024_07_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_16 to admin;

create table minute_candles_2024_07_17
    partition of minute_candles
        FOR VALUES FROM ('2024-07-16 21:00:00+00') TO ('2024-07-17 21:00:00+00');

alter table minute_candles_2024_07_17
    owner to postgres;

grant select on minute_candles_2024_07_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_17 to admin;

create table minute_candles_2024_07_18
    partition of minute_candles
        FOR VALUES FROM ('2024-07-17 21:00:00+00') TO ('2024-07-18 21:00:00+00');

alter table minute_candles_2024_07_18
    owner to postgres;

grant select on minute_candles_2024_07_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_18 to admin;

create table minute_candles_2024_07_19
    partition of minute_candles
        FOR VALUES FROM ('2024-07-18 21:00:00+00') TO ('2024-07-19 21:00:00+00');

alter table minute_candles_2024_07_19
    owner to postgres;

grant select on minute_candles_2024_07_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_19 to admin;

create table minute_candles_2024_07_20
    partition of minute_candles
        FOR VALUES FROM ('2024-07-19 21:00:00+00') TO ('2024-07-20 21:00:00+00');

alter table minute_candles_2024_07_20
    owner to postgres;

grant select on minute_candles_2024_07_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_20 to admin;

create table minute_candles_2024_07_21
    partition of minute_candles
        FOR VALUES FROM ('2024-07-20 21:00:00+00') TO ('2024-07-21 21:00:00+00');

alter table minute_candles_2024_07_21
    owner to postgres;

grant select on minute_candles_2024_07_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_21 to admin;

create table minute_candles_2024_07_22
    partition of minute_candles
        FOR VALUES FROM ('2024-07-21 21:00:00+00') TO ('2024-07-22 21:00:00+00');

alter table minute_candles_2024_07_22
    owner to postgres;

grant select on minute_candles_2024_07_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_22 to admin;

create table minute_candles_2024_07_23
    partition of minute_candles
        FOR VALUES FROM ('2024-07-22 21:00:00+00') TO ('2024-07-23 21:00:00+00');

alter table minute_candles_2024_07_23
    owner to postgres;

grant select on minute_candles_2024_07_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_23 to admin;

create table minute_candles_2024_07_24
    partition of minute_candles
        FOR VALUES FROM ('2024-07-23 21:00:00+00') TO ('2024-07-24 21:00:00+00');

alter table minute_candles_2024_07_24
    owner to postgres;

grant select on minute_candles_2024_07_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_24 to admin;

create table minute_candles_2024_07_25
    partition of minute_candles
        FOR VALUES FROM ('2024-07-24 21:00:00+00') TO ('2024-07-25 21:00:00+00');

alter table minute_candles_2024_07_25
    owner to postgres;

grant select on minute_candles_2024_07_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_25 to admin;

create table minute_candles_2024_07_26
    partition of minute_candles
        FOR VALUES FROM ('2024-07-25 21:00:00+00') TO ('2024-07-26 21:00:00+00');

alter table minute_candles_2024_07_26
    owner to postgres;

grant select on minute_candles_2024_07_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_26 to admin;

create table minute_candles_2024_07_27
    partition of minute_candles
        FOR VALUES FROM ('2024-07-26 21:00:00+00') TO ('2024-07-27 21:00:00+00');

alter table minute_candles_2024_07_27
    owner to postgres;

grant select on minute_candles_2024_07_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_27 to admin;

create table minute_candles_2024_07_28
    partition of minute_candles
        FOR VALUES FROM ('2024-07-27 21:00:00+00') TO ('2024-07-28 21:00:00+00');

alter table minute_candles_2024_07_28
    owner to postgres;

grant select on minute_candles_2024_07_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_28 to admin;

create table minute_candles_2024_07_29
    partition of minute_candles
        FOR VALUES FROM ('2024-07-28 21:00:00+00') TO ('2024-07-29 21:00:00+00');

alter table minute_candles_2024_07_29
    owner to postgres;

grant select on minute_candles_2024_07_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_29 to admin;

create table minute_candles_2024_07_30
    partition of minute_candles
        FOR VALUES FROM ('2024-07-29 21:00:00+00') TO ('2024-07-30 21:00:00+00');

alter table minute_candles_2024_07_30
    owner to postgres;

grant select on minute_candles_2024_07_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_30 to admin;

create table minute_candles_2024_07_31
    partition of minute_candles
        FOR VALUES FROM ('2024-07-30 21:00:00+00') TO ('2024-07-31 21:00:00+00');

alter table minute_candles_2024_07_31
    owner to postgres;

grant select on minute_candles_2024_07_31 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_07_31 to admin;

create table minute_candles_2024_08_01
    partition of minute_candles
        FOR VALUES FROM ('2024-07-31 21:00:00+00') TO ('2024-08-01 21:00:00+00');

alter table minute_candles_2024_08_01
    owner to postgres;

grant select on minute_candles_2024_08_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_01 to admin;

create table minute_candles_2024_08_02
    partition of minute_candles
        FOR VALUES FROM ('2024-08-01 21:00:00+00') TO ('2024-08-02 21:00:00+00');

alter table minute_candles_2024_08_02
    owner to postgres;

grant select on minute_candles_2024_08_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_02 to admin;

create table minute_candles_2024_08_03
    partition of minute_candles
        FOR VALUES FROM ('2024-08-02 21:00:00+00') TO ('2024-08-03 21:00:00+00');

alter table minute_candles_2024_08_03
    owner to postgres;

grant select on minute_candles_2024_08_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_03 to admin;

create table minute_candles_2024_08_04
    partition of minute_candles
        FOR VALUES FROM ('2024-08-03 21:00:00+00') TO ('2024-08-04 21:00:00+00');

alter table minute_candles_2024_08_04
    owner to postgres;

grant select on minute_candles_2024_08_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_04 to admin;

create table minute_candles_2024_08_05
    partition of minute_candles
        FOR VALUES FROM ('2024-08-04 21:00:00+00') TO ('2024-08-05 21:00:00+00');

alter table minute_candles_2024_08_05
    owner to postgres;

grant select on minute_candles_2024_08_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_05 to admin;

create table minute_candles_2024_08_06
    partition of minute_candles
        FOR VALUES FROM ('2024-08-05 21:00:00+00') TO ('2024-08-06 21:00:00+00');

alter table minute_candles_2024_08_06
    owner to postgres;

grant select on minute_candles_2024_08_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_06 to admin;

create table minute_candles_2024_08_07
    partition of minute_candles
        FOR VALUES FROM ('2024-08-06 21:00:00+00') TO ('2024-08-07 21:00:00+00');

alter table minute_candles_2024_08_07
    owner to postgres;

grant select on minute_candles_2024_08_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_07 to admin;

create table minute_candles_2024_08_08
    partition of minute_candles
        FOR VALUES FROM ('2024-08-07 21:00:00+00') TO ('2024-08-08 21:00:00+00');

alter table minute_candles_2024_08_08
    owner to postgres;

grant select on minute_candles_2024_08_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_08 to admin;

create table minute_candles_2024_08_09
    partition of minute_candles
        FOR VALUES FROM ('2024-08-08 21:00:00+00') TO ('2024-08-09 21:00:00+00');

alter table minute_candles_2024_08_09
    owner to postgres;

grant select on minute_candles_2024_08_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_09 to admin;

create table minute_candles_2024_08_10
    partition of minute_candles
        FOR VALUES FROM ('2024-08-09 21:00:00+00') TO ('2024-08-10 21:00:00+00');

alter table minute_candles_2024_08_10
    owner to postgres;

grant select on minute_candles_2024_08_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_10 to admin;

create table minute_candles_2024_08_11
    partition of minute_candles
        FOR VALUES FROM ('2024-08-10 21:00:00+00') TO ('2024-08-11 21:00:00+00');

alter table minute_candles_2024_08_11
    owner to postgres;

grant select on minute_candles_2024_08_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_11 to admin;

create table minute_candles_2024_08_12
    partition of minute_candles
        FOR VALUES FROM ('2024-08-11 21:00:00+00') TO ('2024-08-12 21:00:00+00');

alter table minute_candles_2024_08_12
    owner to postgres;

grant select on minute_candles_2024_08_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_12 to admin;

create table minute_candles_2024_08_13
    partition of minute_candles
        FOR VALUES FROM ('2024-08-12 21:00:00+00') TO ('2024-08-13 21:00:00+00');

alter table minute_candles_2024_08_13
    owner to postgres;

grant select on minute_candles_2024_08_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_13 to admin;

create table minute_candles_2024_08_14
    partition of minute_candles
        FOR VALUES FROM ('2024-08-13 21:00:00+00') TO ('2024-08-14 21:00:00+00');

alter table minute_candles_2024_08_14
    owner to postgres;

grant select on minute_candles_2024_08_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_14 to admin;

create table minute_candles_2024_08_15
    partition of minute_candles
        FOR VALUES FROM ('2024-08-14 21:00:00+00') TO ('2024-08-15 21:00:00+00');

alter table minute_candles_2024_08_15
    owner to postgres;

grant select on minute_candles_2024_08_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_15 to admin;

create table minute_candles_2024_08_16
    partition of minute_candles
        FOR VALUES FROM ('2024-08-15 21:00:00+00') TO ('2024-08-16 21:00:00+00');

alter table minute_candles_2024_08_16
    owner to postgres;

grant select on minute_candles_2024_08_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_16 to admin;

create table minute_candles_2024_08_17
    partition of minute_candles
        FOR VALUES FROM ('2024-08-16 21:00:00+00') TO ('2024-08-17 21:00:00+00');

alter table minute_candles_2024_08_17
    owner to postgres;

grant select on minute_candles_2024_08_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_17 to admin;

create table minute_candles_2024_08_18
    partition of minute_candles
        FOR VALUES FROM ('2024-08-17 21:00:00+00') TO ('2024-08-18 21:00:00+00');

alter table minute_candles_2024_08_18
    owner to postgres;

grant select on minute_candles_2024_08_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_18 to admin;

create table minute_candles_2024_08_19
    partition of minute_candles
        FOR VALUES FROM ('2024-08-18 21:00:00+00') TO ('2024-08-19 21:00:00+00');

alter table minute_candles_2024_08_19
    owner to postgres;

grant select on minute_candles_2024_08_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_19 to admin;

create table minute_candles_2024_08_20
    partition of minute_candles
        FOR VALUES FROM ('2024-08-19 21:00:00+00') TO ('2024-08-20 21:00:00+00');

alter table minute_candles_2024_08_20
    owner to postgres;

grant select on minute_candles_2024_08_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_20 to admin;

create table minute_candles_2024_08_21
    partition of minute_candles
        FOR VALUES FROM ('2024-08-20 21:00:00+00') TO ('2024-08-21 21:00:00+00');

alter table minute_candles_2024_08_21
    owner to postgres;

grant select on minute_candles_2024_08_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_21 to admin;

create table minute_candles_2024_08_22
    partition of minute_candles
        FOR VALUES FROM ('2024-08-21 21:00:00+00') TO ('2024-08-22 21:00:00+00');

alter table minute_candles_2024_08_22
    owner to postgres;

grant select on minute_candles_2024_08_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_22 to admin;

create table minute_candles_2024_08_23
    partition of minute_candles
        FOR VALUES FROM ('2024-08-22 21:00:00+00') TO ('2024-08-23 21:00:00+00');

alter table minute_candles_2024_08_23
    owner to postgres;

grant select on minute_candles_2024_08_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_23 to admin;

create table minute_candles_2024_08_24
    partition of minute_candles
        FOR VALUES FROM ('2024-08-23 21:00:00+00') TO ('2024-08-24 21:00:00+00');

alter table minute_candles_2024_08_24
    owner to postgres;

grant select on minute_candles_2024_08_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_24 to admin;

create table minute_candles_2024_08_25
    partition of minute_candles
        FOR VALUES FROM ('2024-08-24 21:00:00+00') TO ('2024-08-25 21:00:00+00');

alter table minute_candles_2024_08_25
    owner to postgres;

grant select on minute_candles_2024_08_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_25 to admin;

create table minute_candles_2024_08_26
    partition of minute_candles
        FOR VALUES FROM ('2024-08-25 21:00:00+00') TO ('2024-08-26 21:00:00+00');

alter table minute_candles_2024_08_26
    owner to postgres;

grant select on minute_candles_2024_08_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_26 to admin;

create table minute_candles_2024_08_27
    partition of minute_candles
        FOR VALUES FROM ('2024-08-26 21:00:00+00') TO ('2024-08-27 21:00:00+00');

alter table minute_candles_2024_08_27
    owner to postgres;

grant select on minute_candles_2024_08_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_27 to admin;

create table minute_candles_2024_08_28
    partition of minute_candles
        FOR VALUES FROM ('2024-08-27 21:00:00+00') TO ('2024-08-28 21:00:00+00');

alter table minute_candles_2024_08_28
    owner to postgres;

grant select on minute_candles_2024_08_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_28 to admin;

create table minute_candles_2024_08_29
    partition of minute_candles
        FOR VALUES FROM ('2024-08-28 21:00:00+00') TO ('2024-08-29 21:00:00+00');

alter table minute_candles_2024_08_29
    owner to postgres;

grant select on minute_candles_2024_08_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_29 to admin;

create table minute_candles_2024_08_30
    partition of minute_candles
        FOR VALUES FROM ('2024-08-29 21:00:00+00') TO ('2024-08-30 21:00:00+00');

alter table minute_candles_2024_08_30
    owner to postgres;

grant select on minute_candles_2024_08_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_30 to admin;

create table minute_candles_2024_08_31
    partition of minute_candles
        FOR VALUES FROM ('2024-08-30 21:00:00+00') TO ('2024-08-31 21:00:00+00');

alter table minute_candles_2024_08_31
    owner to postgres;

grant select on minute_candles_2024_08_31 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_08_31 to admin;

create table minute_candles_2024_09_01
    partition of minute_candles
        FOR VALUES FROM ('2024-08-31 21:00:00+00') TO ('2024-09-01 21:00:00+00');

alter table minute_candles_2024_09_01
    owner to postgres;

grant select on minute_candles_2024_09_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_01 to admin;

create table minute_candles_2024_09_02
    partition of minute_candles
        FOR VALUES FROM ('2024-09-01 21:00:00+00') TO ('2024-09-02 21:00:00+00');

alter table minute_candles_2024_09_02
    owner to postgres;

grant select on minute_candles_2024_09_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_02 to admin;

create table minute_candles_2024_09_03
    partition of minute_candles
        FOR VALUES FROM ('2024-09-02 21:00:00+00') TO ('2024-09-03 21:00:00+00');

alter table minute_candles_2024_09_03
    owner to postgres;

grant select on minute_candles_2024_09_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_03 to admin;

create table minute_candles_2024_09_04
    partition of minute_candles
        FOR VALUES FROM ('2024-09-03 21:00:00+00') TO ('2024-09-04 21:00:00+00');

alter table minute_candles_2024_09_04
    owner to postgres;

grant select on minute_candles_2024_09_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_04 to admin;

create table minute_candles_2024_09_05
    partition of minute_candles
        FOR VALUES FROM ('2024-09-04 21:00:00+00') TO ('2024-09-05 21:00:00+00');

alter table minute_candles_2024_09_05
    owner to postgres;

grant select on minute_candles_2024_09_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_05 to admin;

create table minute_candles_2024_09_06
    partition of minute_candles
        FOR VALUES FROM ('2024-09-05 21:00:00+00') TO ('2024-09-06 21:00:00+00');

alter table minute_candles_2024_09_06
    owner to postgres;

grant select on minute_candles_2024_09_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_06 to admin;

create table minute_candles_2024_09_07
    partition of minute_candles
        FOR VALUES FROM ('2024-09-06 21:00:00+00') TO ('2024-09-07 21:00:00+00');

alter table minute_candles_2024_09_07
    owner to postgres;

grant select on minute_candles_2024_09_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_07 to admin;

create table minute_candles_2024_09_08
    partition of minute_candles
        FOR VALUES FROM ('2024-09-07 21:00:00+00') TO ('2024-09-08 21:00:00+00');

alter table minute_candles_2024_09_08
    owner to postgres;

grant select on minute_candles_2024_09_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_08 to admin;

create table minute_candles_2024_09_09
    partition of minute_candles
        FOR VALUES FROM ('2024-09-08 21:00:00+00') TO ('2024-09-09 21:00:00+00');

alter table minute_candles_2024_09_09
    owner to postgres;

grant select on minute_candles_2024_09_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_09 to admin;

create table minute_candles_2024_09_10
    partition of minute_candles
        FOR VALUES FROM ('2024-09-09 21:00:00+00') TO ('2024-09-10 21:00:00+00');

alter table minute_candles_2024_09_10
    owner to postgres;

grant select on minute_candles_2024_09_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_10 to admin;

create table minute_candles_2024_09_11
    partition of minute_candles
        FOR VALUES FROM ('2024-09-10 21:00:00+00') TO ('2024-09-11 21:00:00+00');

alter table minute_candles_2024_09_11
    owner to postgres;

grant select on minute_candles_2024_09_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_11 to admin;

create table minute_candles_2024_09_12
    partition of minute_candles
        FOR VALUES FROM ('2024-09-11 21:00:00+00') TO ('2024-09-12 21:00:00+00');

alter table minute_candles_2024_09_12
    owner to postgres;

grant select on minute_candles_2024_09_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_12 to admin;

create table minute_candles_2024_09_13
    partition of minute_candles
        FOR VALUES FROM ('2024-09-12 21:00:00+00') TO ('2024-09-13 21:00:00+00');

alter table minute_candles_2024_09_13
    owner to postgres;

grant select on minute_candles_2024_09_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_13 to admin;

create table minute_candles_2024_09_14
    partition of minute_candles
        FOR VALUES FROM ('2024-09-13 21:00:00+00') TO ('2024-09-14 21:00:00+00');

alter table minute_candles_2024_09_14
    owner to postgres;

grant select on minute_candles_2024_09_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_14 to admin;

create table minute_candles_2024_09_15
    partition of minute_candles
        FOR VALUES FROM ('2024-09-14 21:00:00+00') TO ('2024-09-15 21:00:00+00');

alter table minute_candles_2024_09_15
    owner to postgres;

grant select on minute_candles_2024_09_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_15 to admin;

create table minute_candles_2024_09_16
    partition of minute_candles
        FOR VALUES FROM ('2024-09-15 21:00:00+00') TO ('2024-09-16 21:00:00+00');

alter table minute_candles_2024_09_16
    owner to postgres;

grant select on minute_candles_2024_09_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_16 to admin;

create table minute_candles_2024_09_17
    partition of minute_candles
        FOR VALUES FROM ('2024-09-16 21:00:00+00') TO ('2024-09-17 21:00:00+00');

alter table minute_candles_2024_09_17
    owner to postgres;

grant select on minute_candles_2024_09_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_17 to admin;

create table minute_candles_2024_09_18
    partition of minute_candles
        FOR VALUES FROM ('2024-09-17 21:00:00+00') TO ('2024-09-18 21:00:00+00');

alter table minute_candles_2024_09_18
    owner to postgres;

grant select on minute_candles_2024_09_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_18 to admin;

create table minute_candles_2024_09_19
    partition of minute_candles
        FOR VALUES FROM ('2024-09-18 21:00:00+00') TO ('2024-09-19 21:00:00+00');

alter table minute_candles_2024_09_19
    owner to postgres;

grant select on minute_candles_2024_09_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_19 to admin;

create table minute_candles_2024_09_20
    partition of minute_candles
        FOR VALUES FROM ('2024-09-19 21:00:00+00') TO ('2024-09-20 21:00:00+00');

alter table minute_candles_2024_09_20
    owner to postgres;

grant select on minute_candles_2024_09_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_20 to admin;

create table minute_candles_2024_09_21
    partition of minute_candles
        FOR VALUES FROM ('2024-09-20 21:00:00+00') TO ('2024-09-21 21:00:00+00');

alter table minute_candles_2024_09_21
    owner to postgres;

grant select on minute_candles_2024_09_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_21 to admin;

create table minute_candles_2024_09_22
    partition of minute_candles
        FOR VALUES FROM ('2024-09-21 21:00:00+00') TO ('2024-09-22 21:00:00+00');

alter table minute_candles_2024_09_22
    owner to postgres;

grant select on minute_candles_2024_09_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_22 to admin;

create table minute_candles_2024_09_23
    partition of minute_candles
        FOR VALUES FROM ('2024-09-22 21:00:00+00') TO ('2024-09-23 21:00:00+00');

alter table minute_candles_2024_09_23
    owner to postgres;

grant select on minute_candles_2024_09_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_23 to admin;

create table minute_candles_2024_09_24
    partition of minute_candles
        FOR VALUES FROM ('2024-09-23 21:00:00+00') TO ('2024-09-24 21:00:00+00');

alter table minute_candles_2024_09_24
    owner to postgres;

grant select on minute_candles_2024_09_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_24 to admin;

create table minute_candles_2024_09_25
    partition of minute_candles
        FOR VALUES FROM ('2024-09-24 21:00:00+00') TO ('2024-09-25 21:00:00+00');

alter table minute_candles_2024_09_25
    owner to postgres;

grant select on minute_candles_2024_09_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_25 to admin;

create table minute_candles_2024_09_26
    partition of minute_candles
        FOR VALUES FROM ('2024-09-25 21:00:00+00') TO ('2024-09-26 21:00:00+00');

alter table minute_candles_2024_09_26
    owner to postgres;

grant select on minute_candles_2024_09_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_26 to admin;

create table minute_candles_2024_09_27
    partition of minute_candles
        FOR VALUES FROM ('2024-09-26 21:00:00+00') TO ('2024-09-27 21:00:00+00');

alter table minute_candles_2024_09_27
    owner to postgres;

grant select on minute_candles_2024_09_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_27 to admin;

create table minute_candles_2024_09_28
    partition of minute_candles
        FOR VALUES FROM ('2024-09-27 21:00:00+00') TO ('2024-09-28 21:00:00+00');

alter table minute_candles_2024_09_28
    owner to postgres;

grant select on minute_candles_2024_09_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_28 to admin;

create table minute_candles_2024_09_29
    partition of minute_candles
        FOR VALUES FROM ('2024-09-28 21:00:00+00') TO ('2024-09-29 21:00:00+00');

alter table minute_candles_2024_09_29
    owner to postgres;

grant select on minute_candles_2024_09_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_29 to admin;

create table minute_candles_2024_09_30
    partition of minute_candles
        FOR VALUES FROM ('2024-09-29 21:00:00+00') TO ('2024-09-30 21:00:00+00');

alter table minute_candles_2024_09_30
    owner to postgres;

grant select on minute_candles_2024_09_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_09_30 to admin;

create table minute_candles_2024_10_01
    partition of minute_candles
        FOR VALUES FROM ('2024-09-30 21:00:00+00') TO ('2024-10-01 21:00:00+00');

alter table minute_candles_2024_10_01
    owner to postgres;

grant select on minute_candles_2024_10_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_01 to admin;

create table minute_candles_2024_10_02
    partition of minute_candles
        FOR VALUES FROM ('2024-10-01 21:00:00+00') TO ('2024-10-02 21:00:00+00');

alter table minute_candles_2024_10_02
    owner to postgres;

grant select on minute_candles_2024_10_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_02 to admin;

create table minute_candles_2024_10_03
    partition of minute_candles
        FOR VALUES FROM ('2024-10-02 21:00:00+00') TO ('2024-10-03 21:00:00+00');

alter table minute_candles_2024_10_03
    owner to postgres;

grant select on minute_candles_2024_10_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_03 to admin;

create table minute_candles_2024_10_04
    partition of minute_candles
        FOR VALUES FROM ('2024-10-03 21:00:00+00') TO ('2024-10-04 21:00:00+00');

alter table minute_candles_2024_10_04
    owner to postgres;

grant select on minute_candles_2024_10_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_04 to admin;

create table minute_candles_2024_10_05
    partition of minute_candles
        FOR VALUES FROM ('2024-10-04 21:00:00+00') TO ('2024-10-05 21:00:00+00');

alter table minute_candles_2024_10_05
    owner to postgres;

grant select on minute_candles_2024_10_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_05 to admin;

create table minute_candles_2024_10_06
    partition of minute_candles
        FOR VALUES FROM ('2024-10-05 21:00:00+00') TO ('2024-10-06 21:00:00+00');

alter table minute_candles_2024_10_06
    owner to postgres;

grant select on minute_candles_2024_10_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_06 to admin;

create table minute_candles_2024_10_07
    partition of minute_candles
        FOR VALUES FROM ('2024-10-06 21:00:00+00') TO ('2024-10-07 21:00:00+00');

alter table minute_candles_2024_10_07
    owner to postgres;

grant select on minute_candles_2024_10_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_07 to admin;

create table minute_candles_2024_10_08
    partition of minute_candles
        FOR VALUES FROM ('2024-10-07 21:00:00+00') TO ('2024-10-08 21:00:00+00');

alter table minute_candles_2024_10_08
    owner to postgres;

grant select on minute_candles_2024_10_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_08 to admin;

create table minute_candles_2024_10_09
    partition of minute_candles
        FOR VALUES FROM ('2024-10-08 21:00:00+00') TO ('2024-10-09 21:00:00+00');

alter table minute_candles_2024_10_09
    owner to postgres;

grant select on minute_candles_2024_10_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_09 to admin;

create table minute_candles_2024_10_10
    partition of minute_candles
        FOR VALUES FROM ('2024-10-09 21:00:00+00') TO ('2024-10-10 21:00:00+00');

alter table minute_candles_2024_10_10
    owner to postgres;

grant select on minute_candles_2024_10_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_10 to admin;

create table minute_candles_2024_10_11
    partition of minute_candles
        FOR VALUES FROM ('2024-10-10 21:00:00+00') TO ('2024-10-11 21:00:00+00');

alter table minute_candles_2024_10_11
    owner to postgres;

grant select on minute_candles_2024_10_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_11 to admin;

create table minute_candles_2024_10_12
    partition of minute_candles
        FOR VALUES FROM ('2024-10-11 21:00:00+00') TO ('2024-10-12 21:00:00+00');

alter table minute_candles_2024_10_12
    owner to postgres;

grant select on minute_candles_2024_10_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_12 to admin;

create table minute_candles_2024_10_13
    partition of minute_candles
        FOR VALUES FROM ('2024-10-12 21:00:00+00') TO ('2024-10-13 21:00:00+00');

alter table minute_candles_2024_10_13
    owner to postgres;

grant select on minute_candles_2024_10_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_13 to admin;

create table minute_candles_2024_10_14
    partition of minute_candles
        FOR VALUES FROM ('2024-10-13 21:00:00+00') TO ('2024-10-14 21:00:00+00');

alter table minute_candles_2024_10_14
    owner to postgres;

grant select on minute_candles_2024_10_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_14 to admin;

create table minute_candles_2024_10_15
    partition of minute_candles
        FOR VALUES FROM ('2024-10-14 21:00:00+00') TO ('2024-10-15 21:00:00+00');

alter table minute_candles_2024_10_15
    owner to postgres;

grant select on minute_candles_2024_10_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_15 to admin;

create table minute_candles_2024_10_16
    partition of minute_candles
        FOR VALUES FROM ('2024-10-15 21:00:00+00') TO ('2024-10-16 21:00:00+00');

alter table minute_candles_2024_10_16
    owner to postgres;

grant select on minute_candles_2024_10_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_16 to admin;

create table minute_candles_2024_10_17
    partition of minute_candles
        FOR VALUES FROM ('2024-10-16 21:00:00+00') TO ('2024-10-17 21:00:00+00');

alter table minute_candles_2024_10_17
    owner to postgres;

grant select on minute_candles_2024_10_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_17 to admin;

create table minute_candles_2024_10_18
    partition of minute_candles
        FOR VALUES FROM ('2024-10-17 21:00:00+00') TO ('2024-10-18 21:00:00+00');

alter table minute_candles_2024_10_18
    owner to postgres;

grant select on minute_candles_2024_10_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_18 to admin;

create table minute_candles_2024_10_19
    partition of minute_candles
        FOR VALUES FROM ('2024-10-18 21:00:00+00') TO ('2024-10-19 21:00:00+00');

alter table minute_candles_2024_10_19
    owner to postgres;

grant select on minute_candles_2024_10_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_19 to admin;

create table minute_candles_2024_10_20
    partition of minute_candles
        FOR VALUES FROM ('2024-10-19 21:00:00+00') TO ('2024-10-20 21:00:00+00');

alter table minute_candles_2024_10_20
    owner to postgres;

grant select on minute_candles_2024_10_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_20 to admin;

create table minute_candles_2024_10_21
    partition of minute_candles
        FOR VALUES FROM ('2024-10-20 21:00:00+00') TO ('2024-10-21 21:00:00+00');

alter table minute_candles_2024_10_21
    owner to postgres;

grant select on minute_candles_2024_10_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_21 to admin;

create table minute_candles_2024_10_22
    partition of minute_candles
        FOR VALUES FROM ('2024-10-21 21:00:00+00') TO ('2024-10-22 21:00:00+00');

alter table minute_candles_2024_10_22
    owner to postgres;

grant select on minute_candles_2024_10_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_22 to admin;

create table minute_candles_2024_10_23
    partition of minute_candles
        FOR VALUES FROM ('2024-10-22 21:00:00+00') TO ('2024-10-23 21:00:00+00');

alter table minute_candles_2024_10_23
    owner to postgres;

grant select on minute_candles_2024_10_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_23 to admin;

create table minute_candles_2024_10_24
    partition of minute_candles
        FOR VALUES FROM ('2024-10-23 21:00:00+00') TO ('2024-10-24 21:00:00+00');

alter table minute_candles_2024_10_24
    owner to postgres;

grant select on minute_candles_2024_10_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_24 to admin;

create table minute_candles_2024_10_25
    partition of minute_candles
        FOR VALUES FROM ('2024-10-24 21:00:00+00') TO ('2024-10-25 21:00:00+00');

alter table minute_candles_2024_10_25
    owner to postgres;

grant select on minute_candles_2024_10_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_25 to admin;

create table minute_candles_2024_10_26
    partition of minute_candles
        FOR VALUES FROM ('2024-10-25 21:00:00+00') TO ('2024-10-26 21:00:00+00');

alter table minute_candles_2024_10_26
    owner to postgres;

grant select on minute_candles_2024_10_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_26 to admin;

create table minute_candles_2024_10_27
    partition of minute_candles
        FOR VALUES FROM ('2024-10-26 21:00:00+00') TO ('2024-10-27 21:00:00+00');

alter table minute_candles_2024_10_27
    owner to postgres;

grant select on minute_candles_2024_10_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_27 to admin;

create table minute_candles_2024_10_28
    partition of minute_candles
        FOR VALUES FROM ('2024-10-27 21:00:00+00') TO ('2024-10-28 21:00:00+00');

alter table minute_candles_2024_10_28
    owner to postgres;

grant select on minute_candles_2024_10_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_28 to admin;

create table minute_candles_2024_10_29
    partition of minute_candles
        FOR VALUES FROM ('2024-10-28 21:00:00+00') TO ('2024-10-29 21:00:00+00');

alter table minute_candles_2024_10_29
    owner to postgres;

grant select on minute_candles_2024_10_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_29 to admin;

create table minute_candles_2024_10_30
    partition of minute_candles
        FOR VALUES FROM ('2024-10-29 21:00:00+00') TO ('2024-10-30 21:00:00+00');

alter table minute_candles_2024_10_30
    owner to postgres;

grant select on minute_candles_2024_10_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_30 to admin;

create table minute_candles_2024_10_31
    partition of minute_candles
        FOR VALUES FROM ('2024-10-30 21:00:00+00') TO ('2024-10-31 21:00:00+00');

alter table minute_candles_2024_10_31
    owner to postgres;

grant select on minute_candles_2024_10_31 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_10_31 to admin;

create table minute_candles_2024_11_01
    partition of minute_candles
        FOR VALUES FROM ('2024-10-31 21:00:00+00') TO ('2024-11-01 21:00:00+00');

alter table minute_candles_2024_11_01
    owner to postgres;

grant select on minute_candles_2024_11_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_01 to admin;

create table minute_candles_2024_11_02
    partition of minute_candles
        FOR VALUES FROM ('2024-11-01 21:00:00+00') TO ('2024-11-02 21:00:00+00');

alter table minute_candles_2024_11_02
    owner to postgres;

grant select on minute_candles_2024_11_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_02 to admin;

create table minute_candles_2024_11_03
    partition of minute_candles
        FOR VALUES FROM ('2024-11-02 21:00:00+00') TO ('2024-11-03 21:00:00+00');

alter table minute_candles_2024_11_03
    owner to postgres;

grant select on minute_candles_2024_11_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_03 to admin;

create table minute_candles_2024_11_04
    partition of minute_candles
        FOR VALUES FROM ('2024-11-03 21:00:00+00') TO ('2024-11-04 21:00:00+00');

alter table minute_candles_2024_11_04
    owner to postgres;

grant select on minute_candles_2024_11_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_04 to admin;

create table minute_candles_2024_11_05
    partition of minute_candles
        FOR VALUES FROM ('2024-11-04 21:00:00+00') TO ('2024-11-05 21:00:00+00');

alter table minute_candles_2024_11_05
    owner to postgres;

grant select on minute_candles_2024_11_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_05 to admin;

create table minute_candles_2024_11_06
    partition of minute_candles
        FOR VALUES FROM ('2024-11-05 21:00:00+00') TO ('2024-11-06 21:00:00+00');

alter table minute_candles_2024_11_06
    owner to postgres;

grant select on minute_candles_2024_11_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_06 to admin;

create table minute_candles_2024_11_07
    partition of minute_candles
        FOR VALUES FROM ('2024-11-06 21:00:00+00') TO ('2024-11-07 21:00:00+00');

alter table minute_candles_2024_11_07
    owner to postgres;

grant select on minute_candles_2024_11_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_07 to admin;

create table minute_candles_2024_11_08
    partition of minute_candles
        FOR VALUES FROM ('2024-11-07 21:00:00+00') TO ('2024-11-08 21:00:00+00');

alter table minute_candles_2024_11_08
    owner to postgres;

grant select on minute_candles_2024_11_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_08 to admin;

create table minute_candles_2024_11_09
    partition of minute_candles
        FOR VALUES FROM ('2024-11-08 21:00:00+00') TO ('2024-11-09 21:00:00+00');

alter table minute_candles_2024_11_09
    owner to postgres;

grant select on minute_candles_2024_11_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_09 to admin;

create table minute_candles_2024_11_10
    partition of minute_candles
        FOR VALUES FROM ('2024-11-09 21:00:00+00') TO ('2024-11-10 21:00:00+00');

alter table minute_candles_2024_11_10
    owner to postgres;

grant select on minute_candles_2024_11_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_10 to admin;

create table minute_candles_2024_11_11
    partition of minute_candles
        FOR VALUES FROM ('2024-11-10 21:00:00+00') TO ('2024-11-11 21:00:00+00');

alter table minute_candles_2024_11_11
    owner to postgres;

grant select on minute_candles_2024_11_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_11 to admin;

create table minute_candles_2024_11_12
    partition of minute_candles
        FOR VALUES FROM ('2024-11-11 21:00:00+00') TO ('2024-11-12 21:00:00+00');

alter table minute_candles_2024_11_12
    owner to postgres;

grant select on minute_candles_2024_11_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_12 to admin;

create table minute_candles_2024_11_13
    partition of minute_candles
        FOR VALUES FROM ('2024-11-12 21:00:00+00') TO ('2024-11-13 21:00:00+00');

alter table minute_candles_2024_11_13
    owner to postgres;

grant select on minute_candles_2024_11_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_13 to admin;

create table minute_candles_2024_11_14
    partition of minute_candles
        FOR VALUES FROM ('2024-11-13 21:00:00+00') TO ('2024-11-14 21:00:00+00');

alter table minute_candles_2024_11_14
    owner to postgres;

grant select on minute_candles_2024_11_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_14 to admin;

create table minute_candles_2024_11_15
    partition of minute_candles
        FOR VALUES FROM ('2024-11-14 21:00:00+00') TO ('2024-11-15 21:00:00+00');

alter table minute_candles_2024_11_15
    owner to postgres;

grant select on minute_candles_2024_11_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_15 to admin;

create table minute_candles_2024_11_16
    partition of minute_candles
        FOR VALUES FROM ('2024-11-15 21:00:00+00') TO ('2024-11-16 21:00:00+00');

alter table minute_candles_2024_11_16
    owner to postgres;

grant select on minute_candles_2024_11_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_16 to admin;

create table minute_candles_2024_11_17
    partition of minute_candles
        FOR VALUES FROM ('2024-11-16 21:00:00+00') TO ('2024-11-17 21:00:00+00');

alter table minute_candles_2024_11_17
    owner to postgres;

grant select on minute_candles_2024_11_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_17 to admin;

create table minute_candles_2024_11_18
    partition of minute_candles
        FOR VALUES FROM ('2024-11-17 21:00:00+00') TO ('2024-11-18 21:00:00+00');

alter table minute_candles_2024_11_18
    owner to postgres;

grant select on minute_candles_2024_11_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_18 to admin;

create table minute_candles_2024_11_19
    partition of minute_candles
        FOR VALUES FROM ('2024-11-18 21:00:00+00') TO ('2024-11-19 21:00:00+00');

alter table minute_candles_2024_11_19
    owner to postgres;

grant select on minute_candles_2024_11_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_19 to admin;

create table minute_candles_2024_11_20
    partition of minute_candles
        FOR VALUES FROM ('2024-11-19 21:00:00+00') TO ('2024-11-20 21:00:00+00');

alter table minute_candles_2024_11_20
    owner to postgres;

grant select on minute_candles_2024_11_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_20 to admin;

create table minute_candles_2024_11_21
    partition of minute_candles
        FOR VALUES FROM ('2024-11-20 21:00:00+00') TO ('2024-11-21 21:00:00+00');

alter table minute_candles_2024_11_21
    owner to postgres;

grant select on minute_candles_2024_11_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_21 to admin;

create table minute_candles_2024_11_22
    partition of minute_candles
        FOR VALUES FROM ('2024-11-21 21:00:00+00') TO ('2024-11-22 21:00:00+00');

alter table minute_candles_2024_11_22
    owner to postgres;

grant select on minute_candles_2024_11_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_22 to admin;

create table minute_candles_2024_11_23
    partition of minute_candles
        FOR VALUES FROM ('2024-11-22 21:00:00+00') TO ('2024-11-23 21:00:00+00');

alter table minute_candles_2024_11_23
    owner to postgres;

grant select on minute_candles_2024_11_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_23 to admin;

create table minute_candles_2024_11_24
    partition of minute_candles
        FOR VALUES FROM ('2024-11-23 21:00:00+00') TO ('2024-11-24 21:00:00+00');

alter table minute_candles_2024_11_24
    owner to postgres;

grant select on minute_candles_2024_11_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_24 to admin;

create table minute_candles_2024_11_25
    partition of minute_candles
        FOR VALUES FROM ('2024-11-24 21:00:00+00') TO ('2024-11-25 21:00:00+00');

alter table minute_candles_2024_11_25
    owner to postgres;

grant select on minute_candles_2024_11_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_25 to admin;

create table minute_candles_2024_11_26
    partition of minute_candles
        FOR VALUES FROM ('2024-11-25 21:00:00+00') TO ('2024-11-26 21:00:00+00');

alter table minute_candles_2024_11_26
    owner to postgres;

grant select on minute_candles_2024_11_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_26 to admin;

create table minute_candles_2024_11_27
    partition of minute_candles
        FOR VALUES FROM ('2024-11-26 21:00:00+00') TO ('2024-11-27 21:00:00+00');

alter table minute_candles_2024_11_27
    owner to postgres;

grant select on minute_candles_2024_11_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_27 to admin;

create table minute_candles_2024_11_28
    partition of minute_candles
        FOR VALUES FROM ('2024-11-27 21:00:00+00') TO ('2024-11-28 21:00:00+00');

alter table minute_candles_2024_11_28
    owner to postgres;

grant select on minute_candles_2024_11_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_28 to admin;

create table minute_candles_2024_11_29
    partition of minute_candles
        FOR VALUES FROM ('2024-11-28 21:00:00+00') TO ('2024-11-29 21:00:00+00');

alter table minute_candles_2024_11_29
    owner to postgres;

grant select on minute_candles_2024_11_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_29 to admin;

create table minute_candles_2024_11_30
    partition of minute_candles
        FOR VALUES FROM ('2024-11-29 21:00:00+00') TO ('2024-11-30 21:00:00+00');

alter table minute_candles_2024_11_30
    owner to postgres;

grant select on minute_candles_2024_11_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_11_30 to admin;

create table minute_candles_2024_12_01
    partition of minute_candles
        FOR VALUES FROM ('2024-11-30 21:00:00+00') TO ('2024-12-01 21:00:00+00');

alter table minute_candles_2024_12_01
    owner to postgres;

grant select on minute_candles_2024_12_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_01 to admin;

create table minute_candles_2024_12_02
    partition of minute_candles
        FOR VALUES FROM ('2024-12-01 21:00:00+00') TO ('2024-12-02 21:00:00+00');

alter table minute_candles_2024_12_02
    owner to postgres;

grant select on minute_candles_2024_12_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_02 to admin;

create table minute_candles_2024_12_03
    partition of minute_candles
        FOR VALUES FROM ('2024-12-02 21:00:00+00') TO ('2024-12-03 21:00:00+00');

alter table minute_candles_2024_12_03
    owner to postgres;

grant select on minute_candles_2024_12_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_03 to admin;

create table minute_candles_2024_12_04
    partition of minute_candles
        FOR VALUES FROM ('2024-12-03 21:00:00+00') TO ('2024-12-04 21:00:00+00');

alter table minute_candles_2024_12_04
    owner to postgres;

grant select on minute_candles_2024_12_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_04 to admin;

create table minute_candles_2024_12_05
    partition of minute_candles
        FOR VALUES FROM ('2024-12-04 21:00:00+00') TO ('2024-12-05 21:00:00+00');

alter table minute_candles_2024_12_05
    owner to postgres;

grant select on minute_candles_2024_12_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_05 to admin;

create table minute_candles_2024_12_06
    partition of minute_candles
        FOR VALUES FROM ('2024-12-05 21:00:00+00') TO ('2024-12-06 21:00:00+00');

alter table minute_candles_2024_12_06
    owner to postgres;

grant select on minute_candles_2024_12_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_06 to admin;

create table minute_candles_2024_12_07
    partition of minute_candles
        FOR VALUES FROM ('2024-12-06 21:00:00+00') TO ('2024-12-07 21:00:00+00');

alter table minute_candles_2024_12_07
    owner to postgres;

grant select on minute_candles_2024_12_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_07 to admin;

create table minute_candles_2024_12_08
    partition of minute_candles
        FOR VALUES FROM ('2024-12-07 21:00:00+00') TO ('2024-12-08 21:00:00+00');

alter table minute_candles_2024_12_08
    owner to postgres;

grant select on minute_candles_2024_12_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_08 to admin;

create table minute_candles_2024_12_09
    partition of minute_candles
        FOR VALUES FROM ('2024-12-08 21:00:00+00') TO ('2024-12-09 21:00:00+00');

alter table minute_candles_2024_12_09
    owner to postgres;

grant select on minute_candles_2024_12_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_09 to admin;

create table minute_candles_2024_12_10
    partition of minute_candles
        FOR VALUES FROM ('2024-12-09 21:00:00+00') TO ('2024-12-10 21:00:00+00');

alter table minute_candles_2024_12_10
    owner to postgres;

grant select on minute_candles_2024_12_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_10 to admin;

create table minute_candles_2024_12_11
    partition of minute_candles
        FOR VALUES FROM ('2024-12-10 21:00:00+00') TO ('2024-12-11 21:00:00+00');

alter table minute_candles_2024_12_11
    owner to postgres;

grant select on minute_candles_2024_12_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_11 to admin;

create table minute_candles_2024_12_12
    partition of minute_candles
        FOR VALUES FROM ('2024-12-11 21:00:00+00') TO ('2024-12-12 21:00:00+00');

alter table minute_candles_2024_12_12
    owner to postgres;

grant select on minute_candles_2024_12_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_12 to admin;

create table minute_candles_2024_12_13
    partition of minute_candles
        FOR VALUES FROM ('2024-12-12 21:00:00+00') TO ('2024-12-13 21:00:00+00');

alter table minute_candles_2024_12_13
    owner to postgres;

grant select on minute_candles_2024_12_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_13 to admin;

create table minute_candles_2024_12_14
    partition of minute_candles
        FOR VALUES FROM ('2024-12-13 21:00:00+00') TO ('2024-12-14 21:00:00+00');

alter table minute_candles_2024_12_14
    owner to postgres;

grant select on minute_candles_2024_12_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_14 to admin;

create table minute_candles_2024_12_15
    partition of minute_candles
        FOR VALUES FROM ('2024-12-14 21:00:00+00') TO ('2024-12-15 21:00:00+00');

alter table minute_candles_2024_12_15
    owner to postgres;

grant select on minute_candles_2024_12_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_15 to admin;

create table minute_candles_2024_12_16
    partition of minute_candles
        FOR VALUES FROM ('2024-12-15 21:00:00+00') TO ('2024-12-16 21:00:00+00');

alter table minute_candles_2024_12_16
    owner to postgres;

grant select on minute_candles_2024_12_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_16 to admin;

create table minute_candles_2024_12_17
    partition of minute_candles
        FOR VALUES FROM ('2024-12-16 21:00:00+00') TO ('2024-12-17 21:00:00+00');

alter table minute_candles_2024_12_17
    owner to postgres;

grant select on minute_candles_2024_12_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_17 to admin;

create table minute_candles_2024_12_18
    partition of minute_candles
        FOR VALUES FROM ('2024-12-17 21:00:00+00') TO ('2024-12-18 21:00:00+00');

alter table minute_candles_2024_12_18
    owner to postgres;

grant select on minute_candles_2024_12_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_18 to admin;

create table minute_candles_2024_12_19
    partition of minute_candles
        FOR VALUES FROM ('2024-12-18 21:00:00+00') TO ('2024-12-19 21:00:00+00');

alter table minute_candles_2024_12_19
    owner to postgres;

grant select on minute_candles_2024_12_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_19 to admin;

create table minute_candles_2024_12_20
    partition of minute_candles
        FOR VALUES FROM ('2024-12-19 21:00:00+00') TO ('2024-12-20 21:00:00+00');

alter table minute_candles_2024_12_20
    owner to postgres;

grant select on minute_candles_2024_12_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_20 to admin;

create table minute_candles_2024_12_21
    partition of minute_candles
        FOR VALUES FROM ('2024-12-20 21:00:00+00') TO ('2024-12-21 21:00:00+00');

alter table minute_candles_2024_12_21
    owner to postgres;

grant select on minute_candles_2024_12_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_21 to admin;

create table minute_candles_2024_12_22
    partition of minute_candles
        FOR VALUES FROM ('2024-12-21 21:00:00+00') TO ('2024-12-22 21:00:00+00');

alter table minute_candles_2024_12_22
    owner to postgres;

grant select on minute_candles_2024_12_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_22 to admin;

create table minute_candles_2024_12_23
    partition of minute_candles
        FOR VALUES FROM ('2024-12-22 21:00:00+00') TO ('2024-12-23 21:00:00+00');

alter table minute_candles_2024_12_23
    owner to postgres;

grant select on minute_candles_2024_12_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_23 to admin;

create table minute_candles_2024_12_24
    partition of minute_candles
        FOR VALUES FROM ('2024-12-23 21:00:00+00') TO ('2024-12-24 21:00:00+00');

alter table minute_candles_2024_12_24
    owner to postgres;

grant select on minute_candles_2024_12_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_24 to admin;

create table minute_candles_2024_12_25
    partition of minute_candles
        FOR VALUES FROM ('2024-12-24 21:00:00+00') TO ('2024-12-25 21:00:00+00');

alter table minute_candles_2024_12_25
    owner to postgres;

grant select on minute_candles_2024_12_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_25 to admin;

create table minute_candles_2024_12_26
    partition of minute_candles
        FOR VALUES FROM ('2024-12-25 21:00:00+00') TO ('2024-12-26 21:00:00+00');

alter table minute_candles_2024_12_26
    owner to postgres;

grant select on minute_candles_2024_12_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_26 to admin;

create table minute_candles_2024_12_27
    partition of minute_candles
        FOR VALUES FROM ('2024-12-26 21:00:00+00') TO ('2024-12-27 21:00:00+00');

alter table minute_candles_2024_12_27
    owner to postgres;

grant select on minute_candles_2024_12_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_27 to admin;

create table minute_candles_2024_12_28
    partition of minute_candles
        FOR VALUES FROM ('2024-12-27 21:00:00+00') TO ('2024-12-28 21:00:00+00');

alter table minute_candles_2024_12_28
    owner to postgres;

grant select on minute_candles_2024_12_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_28 to admin;

create table minute_candles_2024_12_29
    partition of minute_candles
        FOR VALUES FROM ('2024-12-28 21:00:00+00') TO ('2024-12-29 21:00:00+00');

alter table minute_candles_2024_12_29
    owner to postgres;

grant select on minute_candles_2024_12_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_29 to admin;

create table minute_candles_2024_12_30
    partition of minute_candles
        FOR VALUES FROM ('2024-12-29 21:00:00+00') TO ('2024-12-30 21:00:00+00');

alter table minute_candles_2024_12_30
    owner to postgres;

grant select on minute_candles_2024_12_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_30 to admin;

create table minute_candles_2024_12_31
    partition of minute_candles
        FOR VALUES FROM ('2024-12-30 21:00:00+00') TO ('2024-12-31 21:00:00+00');

alter table minute_candles_2024_12_31
    owner to postgres;

grant select on minute_candles_2024_12_31 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2024_12_31 to admin;

create table minute_candles_2025_01_01
    partition of minute_candles
        FOR VALUES FROM ('2024-12-31 21:00:00+00') TO ('2025-01-01 21:00:00+00');

alter table minute_candles_2025_01_01
    owner to postgres;

grant select on minute_candles_2025_01_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_01 to admin;

create table minute_candles_2025_01_02
    partition of minute_candles
        FOR VALUES FROM ('2025-01-01 21:00:00+00') TO ('2025-01-02 21:00:00+00');

alter table minute_candles_2025_01_02
    owner to postgres;

grant select on minute_candles_2025_01_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_02 to admin;

create table minute_candles_2025_01_03
    partition of minute_candles
        FOR VALUES FROM ('2025-01-02 21:00:00+00') TO ('2025-01-03 21:00:00+00');

alter table minute_candles_2025_01_03
    owner to postgres;

grant select on minute_candles_2025_01_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_03 to admin;

create table minute_candles_2025_01_04
    partition of minute_candles
        FOR VALUES FROM ('2025-01-03 21:00:00+00') TO ('2025-01-04 21:00:00+00');

alter table minute_candles_2025_01_04
    owner to postgres;

grant select on minute_candles_2025_01_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_04 to admin;

create table minute_candles_2025_01_05
    partition of minute_candles
        FOR VALUES FROM ('2025-01-04 21:00:00+00') TO ('2025-01-05 21:00:00+00');

alter table minute_candles_2025_01_05
    owner to postgres;

grant select on minute_candles_2025_01_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_05 to admin;

create table minute_candles_2025_01_06
    partition of minute_candles
        FOR VALUES FROM ('2025-01-05 21:00:00+00') TO ('2025-01-06 21:00:00+00');

alter table minute_candles_2025_01_06
    owner to postgres;

grant select on minute_candles_2025_01_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_06 to admin;

create table minute_candles_2025_01_07
    partition of minute_candles
        FOR VALUES FROM ('2025-01-06 21:00:00+00') TO ('2025-01-07 21:00:00+00');

alter table minute_candles_2025_01_07
    owner to postgres;

grant select on minute_candles_2025_01_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_07 to admin;

create table minute_candles_2025_01_08
    partition of minute_candles
        FOR VALUES FROM ('2025-01-07 21:00:00+00') TO ('2025-01-08 21:00:00+00');

alter table minute_candles_2025_01_08
    owner to postgres;

grant select on minute_candles_2025_01_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_08 to admin;

create table minute_candles_2025_01_09
    partition of minute_candles
        FOR VALUES FROM ('2025-01-08 21:00:00+00') TO ('2025-01-09 21:00:00+00');

alter table minute_candles_2025_01_09
    owner to postgres;

grant select on minute_candles_2025_01_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_09 to admin;

create table minute_candles_2025_01_10
    partition of minute_candles
        FOR VALUES FROM ('2025-01-09 21:00:00+00') TO ('2025-01-10 21:00:00+00');

alter table minute_candles_2025_01_10
    owner to postgres;

grant select on minute_candles_2025_01_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_10 to admin;

create table minute_candles_2025_01_11
    partition of minute_candles
        FOR VALUES FROM ('2025-01-10 21:00:00+00') TO ('2025-01-11 21:00:00+00');

alter table minute_candles_2025_01_11
    owner to postgres;

grant select on minute_candles_2025_01_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_11 to admin;

create table minute_candles_2025_01_12
    partition of minute_candles
        FOR VALUES FROM ('2025-01-11 21:00:00+00') TO ('2025-01-12 21:00:00+00');

alter table minute_candles_2025_01_12
    owner to postgres;

grant select on minute_candles_2025_01_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_12 to admin;

create table minute_candles_2025_01_13
    partition of minute_candles
        FOR VALUES FROM ('2025-01-12 21:00:00+00') TO ('2025-01-13 21:00:00+00');

alter table minute_candles_2025_01_13
    owner to postgres;

grant select on minute_candles_2025_01_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_13 to admin;

create table minute_candles_2025_01_14
    partition of minute_candles
        FOR VALUES FROM ('2025-01-13 21:00:00+00') TO ('2025-01-14 21:00:00+00');

alter table minute_candles_2025_01_14
    owner to postgres;

grant select on minute_candles_2025_01_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_14 to admin;

create table minute_candles_2025_01_15
    partition of minute_candles
        FOR VALUES FROM ('2025-01-14 21:00:00+00') TO ('2025-01-15 21:00:00+00');

alter table minute_candles_2025_01_15
    owner to postgres;

grant select on minute_candles_2025_01_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_15 to admin;

create table minute_candles_2025_01_16
    partition of minute_candles
        FOR VALUES FROM ('2025-01-15 21:00:00+00') TO ('2025-01-16 21:00:00+00');

alter table minute_candles_2025_01_16
    owner to postgres;

grant select on minute_candles_2025_01_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_16 to admin;

create table minute_candles_2025_01_17
    partition of minute_candles
        FOR VALUES FROM ('2025-01-16 21:00:00+00') TO ('2025-01-17 21:00:00+00');

alter table minute_candles_2025_01_17
    owner to postgres;

grant select on minute_candles_2025_01_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_17 to admin;

create table minute_candles_2025_01_18
    partition of minute_candles
        FOR VALUES FROM ('2025-01-17 21:00:00+00') TO ('2025-01-18 21:00:00+00');

alter table minute_candles_2025_01_18
    owner to postgres;

grant select on minute_candles_2025_01_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_18 to admin;

create table minute_candles_2025_01_19
    partition of minute_candles
        FOR VALUES FROM ('2025-01-18 21:00:00+00') TO ('2025-01-19 21:00:00+00');

alter table minute_candles_2025_01_19
    owner to postgres;

grant select on minute_candles_2025_01_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_19 to admin;

create table minute_candles_2025_01_20
    partition of minute_candles
        FOR VALUES FROM ('2025-01-19 21:00:00+00') TO ('2025-01-20 21:00:00+00');

alter table minute_candles_2025_01_20
    owner to postgres;

grant select on minute_candles_2025_01_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_20 to admin;

create table minute_candles_2025_01_21
    partition of minute_candles
        FOR VALUES FROM ('2025-01-20 21:00:00+00') TO ('2025-01-21 21:00:00+00');

alter table minute_candles_2025_01_21
    owner to postgres;

grant select on minute_candles_2025_01_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_21 to admin;

create table minute_candles_2025_01_22
    partition of minute_candles
        FOR VALUES FROM ('2025-01-21 21:00:00+00') TO ('2025-01-22 21:00:00+00');

alter table minute_candles_2025_01_22
    owner to postgres;

grant select on minute_candles_2025_01_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_22 to admin;

create table minute_candles_2025_01_23
    partition of minute_candles
        FOR VALUES FROM ('2025-01-22 21:00:00+00') TO ('2025-01-23 21:00:00+00');

alter table minute_candles_2025_01_23
    owner to postgres;

grant select on minute_candles_2025_01_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_23 to admin;

create table minute_candles_2025_01_24
    partition of minute_candles
        FOR VALUES FROM ('2025-01-23 21:00:00+00') TO ('2025-01-24 21:00:00+00');

alter table minute_candles_2025_01_24
    owner to postgres;

grant select on minute_candles_2025_01_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_24 to admin;

create table minute_candles_2025_01_25
    partition of minute_candles
        FOR VALUES FROM ('2025-01-24 21:00:00+00') TO ('2025-01-25 21:00:00+00');

alter table minute_candles_2025_01_25
    owner to postgres;

grant select on minute_candles_2025_01_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_25 to admin;

create table minute_candles_2025_01_26
    partition of minute_candles
        FOR VALUES FROM ('2025-01-25 21:00:00+00') TO ('2025-01-26 21:00:00+00');

alter table minute_candles_2025_01_26
    owner to postgres;

grant select on minute_candles_2025_01_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_26 to admin;

create table minute_candles_2025_01_27
    partition of minute_candles
        FOR VALUES FROM ('2025-01-26 21:00:00+00') TO ('2025-01-27 21:00:00+00');

alter table minute_candles_2025_01_27
    owner to postgres;

grant select on minute_candles_2025_01_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_27 to admin;

create table minute_candles_2025_01_28
    partition of minute_candles
        FOR VALUES FROM ('2025-01-27 21:00:00+00') TO ('2025-01-28 21:00:00+00');

alter table minute_candles_2025_01_28
    owner to postgres;

grant select on minute_candles_2025_01_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_28 to admin;

create table minute_candles_2025_01_29
    partition of minute_candles
        FOR VALUES FROM ('2025-01-28 21:00:00+00') TO ('2025-01-29 21:00:00+00');

alter table minute_candles_2025_01_29
    owner to postgres;

grant select on minute_candles_2025_01_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_29 to admin;

create table minute_candles_2025_01_30
    partition of minute_candles
        FOR VALUES FROM ('2025-01-29 21:00:00+00') TO ('2025-01-30 21:00:00+00');

alter table minute_candles_2025_01_30
    owner to postgres;

grant select on minute_candles_2025_01_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_30 to admin;

create table minute_candles_2025_01_31
    partition of minute_candles
        FOR VALUES FROM ('2025-01-30 21:00:00+00') TO ('2025-01-31 21:00:00+00');

alter table minute_candles_2025_01_31
    owner to postgres;

grant select on minute_candles_2025_01_31 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_01_31 to admin;

create table minute_candles_2025_02_01
    partition of minute_candles
        FOR VALUES FROM ('2025-01-31 21:00:00+00') TO ('2025-02-01 21:00:00+00');

alter table minute_candles_2025_02_01
    owner to postgres;

grant select on minute_candles_2025_02_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_01 to admin;

create table minute_candles_2025_02_02
    partition of minute_candles
        FOR VALUES FROM ('2025-02-01 21:00:00+00') TO ('2025-02-02 21:00:00+00');

alter table minute_candles_2025_02_02
    owner to postgres;

grant select on minute_candles_2025_02_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_02 to admin;

create table minute_candles_2025_02_03
    partition of minute_candles
        FOR VALUES FROM ('2025-02-02 21:00:00+00') TO ('2025-02-03 21:00:00+00');

alter table minute_candles_2025_02_03
    owner to postgres;

grant select on minute_candles_2025_02_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_03 to admin;

create table minute_candles_2025_02_04
    partition of minute_candles
        FOR VALUES FROM ('2025-02-03 21:00:00+00') TO ('2025-02-04 21:00:00+00');

alter table minute_candles_2025_02_04
    owner to postgres;

grant select on minute_candles_2025_02_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_04 to admin;

create table minute_candles_2025_02_05
    partition of minute_candles
        FOR VALUES FROM ('2025-02-04 21:00:00+00') TO ('2025-02-05 21:00:00+00');

alter table minute_candles_2025_02_05
    owner to postgres;

grant select on minute_candles_2025_02_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_05 to admin;

create table minute_candles_2025_02_06
    partition of minute_candles
        FOR VALUES FROM ('2025-02-05 21:00:00+00') TO ('2025-02-06 21:00:00+00');

alter table minute_candles_2025_02_06
    owner to postgres;

grant select on minute_candles_2025_02_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_06 to admin;

create table minute_candles_2025_02_07
    partition of minute_candles
        FOR VALUES FROM ('2025-02-06 21:00:00+00') TO ('2025-02-07 21:00:00+00');

alter table minute_candles_2025_02_07
    owner to postgres;

grant select on minute_candles_2025_02_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_07 to admin;

create table minute_candles_2025_02_08
    partition of minute_candles
        FOR VALUES FROM ('2025-02-07 21:00:00+00') TO ('2025-02-08 21:00:00+00');

alter table minute_candles_2025_02_08
    owner to postgres;

grant select on minute_candles_2025_02_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_08 to admin;

create table minute_candles_2025_02_09
    partition of minute_candles
        FOR VALUES FROM ('2025-02-08 21:00:00+00') TO ('2025-02-09 21:00:00+00');

alter table minute_candles_2025_02_09
    owner to postgres;

grant select on minute_candles_2025_02_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_09 to admin;

create table minute_candles_2025_02_10
    partition of minute_candles
        FOR VALUES FROM ('2025-02-09 21:00:00+00') TO ('2025-02-10 21:00:00+00');

alter table minute_candles_2025_02_10
    owner to postgres;

grant select on minute_candles_2025_02_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_10 to admin;

create table minute_candles_2025_02_11
    partition of minute_candles
        FOR VALUES FROM ('2025-02-10 21:00:00+00') TO ('2025-02-11 21:00:00+00');

alter table minute_candles_2025_02_11
    owner to postgres;

grant select on minute_candles_2025_02_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_11 to admin;

create table minute_candles_2025_02_12
    partition of minute_candles
        FOR VALUES FROM ('2025-02-11 21:00:00+00') TO ('2025-02-12 21:00:00+00');

alter table minute_candles_2025_02_12
    owner to postgres;

grant select on minute_candles_2025_02_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_12 to admin;

create table minute_candles_2025_02_13
    partition of minute_candles
        FOR VALUES FROM ('2025-02-12 21:00:00+00') TO ('2025-02-13 21:00:00+00');

alter table minute_candles_2025_02_13
    owner to postgres;

grant select on minute_candles_2025_02_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_13 to admin;

create table minute_candles_2025_02_14
    partition of minute_candles
        FOR VALUES FROM ('2025-02-13 21:00:00+00') TO ('2025-02-14 21:00:00+00');

alter table minute_candles_2025_02_14
    owner to postgres;

grant select on minute_candles_2025_02_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_14 to admin;

create table minute_candles_2025_02_15
    partition of minute_candles
        FOR VALUES FROM ('2025-02-14 21:00:00+00') TO ('2025-02-15 21:00:00+00');

alter table minute_candles_2025_02_15
    owner to postgres;

grant select on minute_candles_2025_02_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_15 to admin;

create table minute_candles_2025_02_16
    partition of minute_candles
        FOR VALUES FROM ('2025-02-15 21:00:00+00') TO ('2025-02-16 21:00:00+00');

alter table minute_candles_2025_02_16
    owner to postgres;

grant select on minute_candles_2025_02_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_16 to admin;

create table minute_candles_2025_02_17
    partition of minute_candles
        FOR VALUES FROM ('2025-02-16 21:00:00+00') TO ('2025-02-17 21:00:00+00');

alter table minute_candles_2025_02_17
    owner to postgres;

grant select on minute_candles_2025_02_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_17 to admin;

create table minute_candles_2025_02_18
    partition of minute_candles
        FOR VALUES FROM ('2025-02-17 21:00:00+00') TO ('2025-02-18 21:00:00+00');

alter table minute_candles_2025_02_18
    owner to postgres;

grant select on minute_candles_2025_02_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_18 to admin;

create table minute_candles_2025_02_19
    partition of minute_candles
        FOR VALUES FROM ('2025-02-18 21:00:00+00') TO ('2025-02-19 21:00:00+00');

alter table minute_candles_2025_02_19
    owner to postgres;

grant select on minute_candles_2025_02_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_19 to admin;

create table minute_candles_2025_02_20
    partition of minute_candles
        FOR VALUES FROM ('2025-02-19 21:00:00+00') TO ('2025-02-20 21:00:00+00');

alter table minute_candles_2025_02_20
    owner to postgres;

grant select on minute_candles_2025_02_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_20 to admin;

create table minute_candles_2025_02_21
    partition of minute_candles
        FOR VALUES FROM ('2025-02-20 21:00:00+00') TO ('2025-02-21 21:00:00+00');

alter table minute_candles_2025_02_21
    owner to postgres;

grant select on minute_candles_2025_02_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_21 to admin;

create table minute_candles_2025_02_22
    partition of minute_candles
        FOR VALUES FROM ('2025-02-21 21:00:00+00') TO ('2025-02-22 21:00:00+00');

alter table minute_candles_2025_02_22
    owner to postgres;

grant select on minute_candles_2025_02_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_22 to admin;

create table minute_candles_2025_02_23
    partition of minute_candles
        FOR VALUES FROM ('2025-02-22 21:00:00+00') TO ('2025-02-23 21:00:00+00');

alter table minute_candles_2025_02_23
    owner to postgres;

grant select on minute_candles_2025_02_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_23 to admin;

create table minute_candles_2025_02_24
    partition of minute_candles
        FOR VALUES FROM ('2025-02-23 21:00:00+00') TO ('2025-02-24 21:00:00+00');

alter table minute_candles_2025_02_24
    owner to postgres;

grant select on minute_candles_2025_02_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_24 to admin;

create table minute_candles_2025_02_25
    partition of minute_candles
        FOR VALUES FROM ('2025-02-24 21:00:00+00') TO ('2025-02-25 21:00:00+00');

alter table minute_candles_2025_02_25
    owner to postgres;

grant select on minute_candles_2025_02_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_25 to admin;

create table minute_candles_2025_02_26
    partition of minute_candles
        FOR VALUES FROM ('2025-02-25 21:00:00+00') TO ('2025-02-26 21:00:00+00');

alter table minute_candles_2025_02_26
    owner to postgres;

grant select on minute_candles_2025_02_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_26 to admin;

create table minute_candles_2025_02_27
    partition of minute_candles
        FOR VALUES FROM ('2025-02-26 21:00:00+00') TO ('2025-02-27 21:00:00+00');

alter table minute_candles_2025_02_27
    owner to postgres;

grant select on minute_candles_2025_02_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_27 to admin;

create table minute_candles_2025_02_28
    partition of minute_candles
        FOR VALUES FROM ('2025-02-27 21:00:00+00') TO ('2025-02-28 21:00:00+00');

alter table minute_candles_2025_02_28
    owner to postgres;

grant select on minute_candles_2025_02_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_02_28 to admin;

create table minute_candles_2025_03_01
    partition of minute_candles
        FOR VALUES FROM ('2025-02-28 21:00:00+00') TO ('2025-03-01 21:00:00+00');

alter table minute_candles_2025_03_01
    owner to postgres;

grant select on minute_candles_2025_03_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_01 to admin;

create table minute_candles_2025_03_02
    partition of minute_candles
        FOR VALUES FROM ('2025-03-01 21:00:00+00') TO ('2025-03-02 21:00:00+00');

alter table minute_candles_2025_03_02
    owner to postgres;

grant select on minute_candles_2025_03_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_02 to admin;

create table minute_candles_2025_03_03
    partition of minute_candles
        FOR VALUES FROM ('2025-03-02 21:00:00+00') TO ('2025-03-03 21:00:00+00');

alter table minute_candles_2025_03_03
    owner to postgres;

grant select on minute_candles_2025_03_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_03 to admin;

create table minute_candles_2025_03_04
    partition of minute_candles
        FOR VALUES FROM ('2025-03-03 21:00:00+00') TO ('2025-03-04 21:00:00+00');

alter table minute_candles_2025_03_04
    owner to postgres;

grant select on minute_candles_2025_03_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_04 to admin;

create table minute_candles_2025_03_05
    partition of minute_candles
        FOR VALUES FROM ('2025-03-04 21:00:00+00') TO ('2025-03-05 21:00:00+00');

alter table minute_candles_2025_03_05
    owner to postgres;

grant select on minute_candles_2025_03_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_05 to admin;

create table minute_candles_2025_03_06
    partition of minute_candles
        FOR VALUES FROM ('2025-03-05 21:00:00+00') TO ('2025-03-06 21:00:00+00');

alter table minute_candles_2025_03_06
    owner to postgres;

grant select on minute_candles_2025_03_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_06 to admin;

create table minute_candles_2025_03_07
    partition of minute_candles
        FOR VALUES FROM ('2025-03-06 21:00:00+00') TO ('2025-03-07 21:00:00+00');

alter table minute_candles_2025_03_07
    owner to postgres;

grant select on minute_candles_2025_03_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_07 to admin;

create table minute_candles_2025_03_08
    partition of minute_candles
        FOR VALUES FROM ('2025-03-07 21:00:00+00') TO ('2025-03-08 21:00:00+00');

alter table minute_candles_2025_03_08
    owner to postgres;

grant select on minute_candles_2025_03_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_08 to admin;

create table minute_candles_2025_03_09
    partition of minute_candles
        FOR VALUES FROM ('2025-03-08 21:00:00+00') TO ('2025-03-09 21:00:00+00');

alter table minute_candles_2025_03_09
    owner to postgres;

grant select on minute_candles_2025_03_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_09 to admin;

create table minute_candles_2025_03_10
    partition of minute_candles
        FOR VALUES FROM ('2025-03-09 21:00:00+00') TO ('2025-03-10 21:00:00+00');

alter table minute_candles_2025_03_10
    owner to postgres;

grant select on minute_candles_2025_03_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_10 to admin;

create table minute_candles_2025_03_11
    partition of minute_candles
        FOR VALUES FROM ('2025-03-10 21:00:00+00') TO ('2025-03-11 21:00:00+00');

alter table minute_candles_2025_03_11
    owner to postgres;

grant select on minute_candles_2025_03_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_11 to admin;

create table minute_candles_2025_03_12
    partition of minute_candles
        FOR VALUES FROM ('2025-03-11 21:00:00+00') TO ('2025-03-12 21:00:00+00');

alter table minute_candles_2025_03_12
    owner to postgres;

grant select on minute_candles_2025_03_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_12 to admin;

create table minute_candles_2025_03_13
    partition of minute_candles
        FOR VALUES FROM ('2025-03-12 21:00:00+00') TO ('2025-03-13 21:00:00+00');

alter table minute_candles_2025_03_13
    owner to postgres;

grant select on minute_candles_2025_03_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_13 to admin;

create table minute_candles_2025_03_14
    partition of minute_candles
        FOR VALUES FROM ('2025-03-13 21:00:00+00') TO ('2025-03-14 21:00:00+00');

alter table minute_candles_2025_03_14
    owner to postgres;

grant select on minute_candles_2025_03_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_14 to admin;

create table minute_candles_2025_03_15
    partition of minute_candles
        FOR VALUES FROM ('2025-03-14 21:00:00+00') TO ('2025-03-15 21:00:00+00');

alter table minute_candles_2025_03_15
    owner to postgres;

grant select on minute_candles_2025_03_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_15 to admin;

create table minute_candles_2025_03_16
    partition of minute_candles
        FOR VALUES FROM ('2025-03-15 21:00:00+00') TO ('2025-03-16 21:00:00+00');

alter table minute_candles_2025_03_16
    owner to postgres;

grant select on minute_candles_2025_03_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_16 to admin;

create table minute_candles_2025_03_17
    partition of minute_candles
        FOR VALUES FROM ('2025-03-16 21:00:00+00') TO ('2025-03-17 21:00:00+00');

alter table minute_candles_2025_03_17
    owner to postgres;

grant select on minute_candles_2025_03_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_17 to admin;

create table minute_candles_2025_03_18
    partition of minute_candles
        FOR VALUES FROM ('2025-03-17 21:00:00+00') TO ('2025-03-18 21:00:00+00');

alter table minute_candles_2025_03_18
    owner to postgres;

grant select on minute_candles_2025_03_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_18 to admin;

create table minute_candles_2025_03_19
    partition of minute_candles
        FOR VALUES FROM ('2025-03-18 21:00:00+00') TO ('2025-03-19 21:00:00+00');

alter table minute_candles_2025_03_19
    owner to postgres;

grant select on minute_candles_2025_03_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_19 to admin;

create table minute_candles_2025_03_20
    partition of minute_candles
        FOR VALUES FROM ('2025-03-19 21:00:00+00') TO ('2025-03-20 21:00:00+00');

alter table minute_candles_2025_03_20
    owner to postgres;

grant select on minute_candles_2025_03_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_20 to admin;

create table minute_candles_2025_03_21
    partition of minute_candles
        FOR VALUES FROM ('2025-03-20 21:00:00+00') TO ('2025-03-21 21:00:00+00');

alter table minute_candles_2025_03_21
    owner to postgres;

grant select on minute_candles_2025_03_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_21 to admin;

create table minute_candles_2025_03_22
    partition of minute_candles
        FOR VALUES FROM ('2025-03-21 21:00:00+00') TO ('2025-03-22 21:00:00+00');

alter table minute_candles_2025_03_22
    owner to postgres;

grant select on minute_candles_2025_03_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_22 to admin;

create table minute_candles_2025_03_23
    partition of minute_candles
        FOR VALUES FROM ('2025-03-22 21:00:00+00') TO ('2025-03-23 21:00:00+00');

alter table minute_candles_2025_03_23
    owner to postgres;

grant select on minute_candles_2025_03_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_23 to admin;

create table minute_candles_2025_03_24
    partition of minute_candles
        FOR VALUES FROM ('2025-03-23 21:00:00+00') TO ('2025-03-24 21:00:00+00');

alter table minute_candles_2025_03_24
    owner to postgres;

grant select on minute_candles_2025_03_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_24 to admin;

create table minute_candles_2025_03_25
    partition of minute_candles
        FOR VALUES FROM ('2025-03-24 21:00:00+00') TO ('2025-03-25 21:00:00+00');

alter table minute_candles_2025_03_25
    owner to postgres;

grant select on minute_candles_2025_03_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_25 to admin;

create table minute_candles_2025_03_26
    partition of minute_candles
        FOR VALUES FROM ('2025-03-25 21:00:00+00') TO ('2025-03-26 21:00:00+00');

alter table minute_candles_2025_03_26
    owner to postgres;

grant select on minute_candles_2025_03_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_26 to admin;

create table minute_candles_2025_03_27
    partition of minute_candles
        FOR VALUES FROM ('2025-03-26 21:00:00+00') TO ('2025-03-27 21:00:00+00');

alter table minute_candles_2025_03_27
    owner to postgres;

grant select on minute_candles_2025_03_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_27 to admin;

create table minute_candles_2025_03_28
    partition of minute_candles
        FOR VALUES FROM ('2025-03-27 21:00:00+00') TO ('2025-03-28 21:00:00+00');

alter table minute_candles_2025_03_28
    owner to postgres;

grant select on minute_candles_2025_03_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_28 to admin;

create table minute_candles_2025_03_29
    partition of minute_candles
        FOR VALUES FROM ('2025-03-28 21:00:00+00') TO ('2025-03-29 21:00:00+00');

alter table minute_candles_2025_03_29
    owner to postgres;

grant select on minute_candles_2025_03_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_29 to admin;

create table minute_candles_2025_03_30
    partition of minute_candles
        FOR VALUES FROM ('2025-03-29 21:00:00+00') TO ('2025-03-30 21:00:00+00');

alter table minute_candles_2025_03_30
    owner to postgres;

grant select on minute_candles_2025_03_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_30 to admin;

create table minute_candles_2025_03_31
    partition of minute_candles
        FOR VALUES FROM ('2025-03-30 21:00:00+00') TO ('2025-03-31 21:00:00+00');

alter table minute_candles_2025_03_31
    owner to postgres;

grant select on minute_candles_2025_03_31 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_03_31 to admin;

create table minute_candles_2025_04_01
    partition of minute_candles
        FOR VALUES FROM ('2025-03-31 21:00:00+00') TO ('2025-04-01 21:00:00+00');

alter table minute_candles_2025_04_01
    owner to postgres;

grant select on minute_candles_2025_04_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_01 to admin;

create table minute_candles_2025_04_02
    partition of minute_candles
        FOR VALUES FROM ('2025-04-01 21:00:00+00') TO ('2025-04-02 21:00:00+00');

alter table minute_candles_2025_04_02
    owner to postgres;

grant select on minute_candles_2025_04_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_02 to admin;

create table minute_candles_2025_04_03
    partition of minute_candles
        FOR VALUES FROM ('2025-04-02 21:00:00+00') TO ('2025-04-03 21:00:00+00');

alter table minute_candles_2025_04_03
    owner to postgres;

grant select on minute_candles_2025_04_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_03 to admin;

create table minute_candles_2025_04_04
    partition of minute_candles
        FOR VALUES FROM ('2025-04-03 21:00:00+00') TO ('2025-04-04 21:00:00+00');

alter table minute_candles_2025_04_04
    owner to postgres;

grant select on minute_candles_2025_04_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_04 to admin;

create table minute_candles_2025_04_05
    partition of minute_candles
        FOR VALUES FROM ('2025-04-04 21:00:00+00') TO ('2025-04-05 21:00:00+00');

alter table minute_candles_2025_04_05
    owner to postgres;

grant select on minute_candles_2025_04_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_05 to admin;

create table minute_candles_2025_04_06
    partition of minute_candles
        FOR VALUES FROM ('2025-04-05 21:00:00+00') TO ('2025-04-06 21:00:00+00');

alter table minute_candles_2025_04_06
    owner to postgres;

grant select on minute_candles_2025_04_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_06 to admin;

create table minute_candles_2025_04_07
    partition of minute_candles
        FOR VALUES FROM ('2025-04-06 21:00:00+00') TO ('2025-04-07 21:00:00+00');

alter table minute_candles_2025_04_07
    owner to postgres;

grant select on minute_candles_2025_04_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_07 to admin;

create table minute_candles_2025_04_08
    partition of minute_candles
        FOR VALUES FROM ('2025-04-07 21:00:00+00') TO ('2025-04-08 21:00:00+00');

alter table minute_candles_2025_04_08
    owner to postgres;

grant select on minute_candles_2025_04_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_08 to admin;

create table minute_candles_2025_04_09
    partition of minute_candles
        FOR VALUES FROM ('2025-04-08 21:00:00+00') TO ('2025-04-09 21:00:00+00');

alter table minute_candles_2025_04_09
    owner to postgres;

grant select on minute_candles_2025_04_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_09 to admin;

create table minute_candles_2025_04_10
    partition of minute_candles
        FOR VALUES FROM ('2025-04-09 21:00:00+00') TO ('2025-04-10 21:00:00+00');

alter table minute_candles_2025_04_10
    owner to postgres;

grant select on minute_candles_2025_04_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_10 to admin;

create table minute_candles_2025_04_11
    partition of minute_candles
        FOR VALUES FROM ('2025-04-10 21:00:00+00') TO ('2025-04-11 21:00:00+00');

alter table minute_candles_2025_04_11
    owner to postgres;

grant select on minute_candles_2025_04_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_11 to admin;

create table minute_candles_2025_04_12
    partition of minute_candles
        FOR VALUES FROM ('2025-04-11 21:00:00+00') TO ('2025-04-12 21:00:00+00');

alter table minute_candles_2025_04_12
    owner to postgres;

grant select on minute_candles_2025_04_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_12 to admin;

create table minute_candles_2025_04_13
    partition of minute_candles
        FOR VALUES FROM ('2025-04-12 21:00:00+00') TO ('2025-04-13 21:00:00+00');

alter table minute_candles_2025_04_13
    owner to postgres;

grant select on minute_candles_2025_04_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_13 to admin;

create table minute_candles_2025_04_14
    partition of minute_candles
        FOR VALUES FROM ('2025-04-13 21:00:00+00') TO ('2025-04-14 21:00:00+00');

alter table minute_candles_2025_04_14
    owner to postgres;

grant select on minute_candles_2025_04_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_14 to admin;

create table minute_candles_2025_04_15
    partition of minute_candles
        FOR VALUES FROM ('2025-04-14 21:00:00+00') TO ('2025-04-15 21:00:00+00');

alter table minute_candles_2025_04_15
    owner to postgres;

grant select on minute_candles_2025_04_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_15 to admin;

create table minute_candles_2025_04_16
    partition of minute_candles
        FOR VALUES FROM ('2025-04-15 21:00:00+00') TO ('2025-04-16 21:00:00+00');

alter table minute_candles_2025_04_16
    owner to postgres;

grant select on minute_candles_2025_04_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_16 to admin;

create table minute_candles_2025_04_17
    partition of minute_candles
        FOR VALUES FROM ('2025-04-16 21:00:00+00') TO ('2025-04-17 21:00:00+00');

alter table minute_candles_2025_04_17
    owner to postgres;

grant select on minute_candles_2025_04_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_17 to admin;

create table minute_candles_2025_04_18
    partition of minute_candles
        FOR VALUES FROM ('2025-04-17 21:00:00+00') TO ('2025-04-18 21:00:00+00');

alter table minute_candles_2025_04_18
    owner to postgres;

grant select on minute_candles_2025_04_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_18 to admin;

create table minute_candles_2025_04_19
    partition of minute_candles
        FOR VALUES FROM ('2025-04-18 21:00:00+00') TO ('2025-04-19 21:00:00+00');

alter table minute_candles_2025_04_19
    owner to postgres;

grant select on minute_candles_2025_04_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_19 to admin;

create table minute_candles_2025_04_20
    partition of minute_candles
        FOR VALUES FROM ('2025-04-19 21:00:00+00') TO ('2025-04-20 21:00:00+00');

alter table minute_candles_2025_04_20
    owner to postgres;

grant select on minute_candles_2025_04_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_20 to admin;

create table minute_candles_2025_04_21
    partition of minute_candles
        FOR VALUES FROM ('2025-04-20 21:00:00+00') TO ('2025-04-21 21:00:00+00');

alter table minute_candles_2025_04_21
    owner to postgres;

grant select on minute_candles_2025_04_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_21 to admin;

create table minute_candles_2025_04_22
    partition of minute_candles
        FOR VALUES FROM ('2025-04-21 21:00:00+00') TO ('2025-04-22 21:00:00+00');

alter table minute_candles_2025_04_22
    owner to postgres;

grant select on minute_candles_2025_04_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_22 to admin;

create table minute_candles_2025_04_23
    partition of minute_candles
        FOR VALUES FROM ('2025-04-22 21:00:00+00') TO ('2025-04-23 21:00:00+00');

alter table minute_candles_2025_04_23
    owner to postgres;

grant select on minute_candles_2025_04_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_23 to admin;

create table minute_candles_2025_04_24
    partition of minute_candles
        FOR VALUES FROM ('2025-04-23 21:00:00+00') TO ('2025-04-24 21:00:00+00');

alter table minute_candles_2025_04_24
    owner to postgres;

grant select on minute_candles_2025_04_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_24 to admin;

create table minute_candles_2025_04_25
    partition of minute_candles
        FOR VALUES FROM ('2025-04-24 21:00:00+00') TO ('2025-04-25 21:00:00+00');

alter table minute_candles_2025_04_25
    owner to postgres;

grant select on minute_candles_2025_04_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_25 to admin;

create table minute_candles_2025_04_26
    partition of minute_candles
        FOR VALUES FROM ('2025-04-25 21:00:00+00') TO ('2025-04-26 21:00:00+00');

alter table minute_candles_2025_04_26
    owner to postgres;

grant select on minute_candles_2025_04_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_26 to admin;

create table minute_candles_2025_04_27
    partition of minute_candles
        FOR VALUES FROM ('2025-04-26 21:00:00+00') TO ('2025-04-27 21:00:00+00');

alter table minute_candles_2025_04_27
    owner to postgres;

grant select on minute_candles_2025_04_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_27 to admin;

create table minute_candles_2025_04_28
    partition of minute_candles
        FOR VALUES FROM ('2025-04-27 21:00:00+00') TO ('2025-04-28 21:00:00+00');

alter table minute_candles_2025_04_28
    owner to postgres;

grant select on minute_candles_2025_04_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_28 to admin;

create table minute_candles_2025_04_29
    partition of minute_candles
        FOR VALUES FROM ('2025-04-28 21:00:00+00') TO ('2025-04-29 21:00:00+00');

alter table minute_candles_2025_04_29
    owner to postgres;

grant select on minute_candles_2025_04_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_29 to admin;

create table minute_candles_2025_04_30
    partition of minute_candles
        FOR VALUES FROM ('2025-04-29 21:00:00+00') TO ('2025-04-30 21:00:00+00');

alter table minute_candles_2025_04_30
    owner to postgres;

grant select on minute_candles_2025_04_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_04_30 to admin;

create table minute_candles_2025_05_01
    partition of minute_candles
        FOR VALUES FROM ('2025-04-30 21:00:00+00') TO ('2025-05-01 21:00:00+00');

alter table minute_candles_2025_05_01
    owner to postgres;

grant select on minute_candles_2025_05_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_01 to admin;

create table minute_candles_2025_05_02
    partition of minute_candles
        FOR VALUES FROM ('2025-05-01 21:00:00+00') TO ('2025-05-02 21:00:00+00');

alter table minute_candles_2025_05_02
    owner to postgres;

grant select on minute_candles_2025_05_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_02 to admin;

create table minute_candles_2025_05_03
    partition of minute_candles
        FOR VALUES FROM ('2025-05-02 21:00:00+00') TO ('2025-05-03 21:00:00+00');

alter table minute_candles_2025_05_03
    owner to postgres;

grant select on minute_candles_2025_05_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_03 to admin;

create table minute_candles_2025_05_04
    partition of minute_candles
        FOR VALUES FROM ('2025-05-03 21:00:00+00') TO ('2025-05-04 21:00:00+00');

alter table minute_candles_2025_05_04
    owner to postgres;

grant select on minute_candles_2025_05_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_04 to admin;

create table minute_candles_2025_05_05
    partition of minute_candles
        FOR VALUES FROM ('2025-05-04 21:00:00+00') TO ('2025-05-05 21:00:00+00');

alter table minute_candles_2025_05_05
    owner to postgres;

grant select on minute_candles_2025_05_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_05 to admin;

create table minute_candles_2025_05_06
    partition of minute_candles
        FOR VALUES FROM ('2025-05-05 21:00:00+00') TO ('2025-05-06 21:00:00+00');

alter table minute_candles_2025_05_06
    owner to postgres;

grant select on minute_candles_2025_05_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_06 to admin;

create table minute_candles_2025_05_07
    partition of minute_candles
        FOR VALUES FROM ('2025-05-06 21:00:00+00') TO ('2025-05-07 21:00:00+00');

alter table minute_candles_2025_05_07
    owner to postgres;

grant select on minute_candles_2025_05_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_07 to admin;

create table minute_candles_2025_05_08
    partition of minute_candles
        FOR VALUES FROM ('2025-05-07 21:00:00+00') TO ('2025-05-08 21:00:00+00');

alter table minute_candles_2025_05_08
    owner to postgres;

grant select on minute_candles_2025_05_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_08 to admin;

create table minute_candles_2025_05_09
    partition of minute_candles
        FOR VALUES FROM ('2025-05-08 21:00:00+00') TO ('2025-05-09 21:00:00+00');

alter table minute_candles_2025_05_09
    owner to postgres;

grant select on minute_candles_2025_05_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_09 to admin;

create table minute_candles_2025_05_10
    partition of minute_candles
        FOR VALUES FROM ('2025-05-09 21:00:00+00') TO ('2025-05-10 21:00:00+00');

alter table minute_candles_2025_05_10
    owner to postgres;

grant select on minute_candles_2025_05_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_10 to admin;

create table minute_candles_2025_05_11
    partition of minute_candles
        FOR VALUES FROM ('2025-05-10 21:00:00+00') TO ('2025-05-11 21:00:00+00');

alter table minute_candles_2025_05_11
    owner to postgres;

grant select on minute_candles_2025_05_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_11 to admin;

create table minute_candles_2025_05_12
    partition of minute_candles
        FOR VALUES FROM ('2025-05-11 21:00:00+00') TO ('2025-05-12 21:00:00+00');

alter table minute_candles_2025_05_12
    owner to postgres;

grant select on minute_candles_2025_05_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_12 to admin;

create table minute_candles_2025_05_13
    partition of minute_candles
        FOR VALUES FROM ('2025-05-12 21:00:00+00') TO ('2025-05-13 21:00:00+00');

alter table minute_candles_2025_05_13
    owner to postgres;

grant select on minute_candles_2025_05_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_13 to admin;

create table minute_candles_2025_05_14
    partition of minute_candles
        FOR VALUES FROM ('2025-05-13 21:00:00+00') TO ('2025-05-14 21:00:00+00');

alter table minute_candles_2025_05_14
    owner to postgres;

grant select on minute_candles_2025_05_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_14 to admin;

create table minute_candles_2025_05_15
    partition of minute_candles
        FOR VALUES FROM ('2025-05-14 21:00:00+00') TO ('2025-05-15 21:00:00+00');

alter table minute_candles_2025_05_15
    owner to postgres;

grant select on minute_candles_2025_05_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_15 to admin;

create table minute_candles_2025_05_16
    partition of minute_candles
        FOR VALUES FROM ('2025-05-15 21:00:00+00') TO ('2025-05-16 21:00:00+00');

alter table minute_candles_2025_05_16
    owner to postgres;

grant select on minute_candles_2025_05_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_16 to admin;

create table minute_candles_2025_05_17
    partition of minute_candles
        FOR VALUES FROM ('2025-05-16 21:00:00+00') TO ('2025-05-17 21:00:00+00');

alter table minute_candles_2025_05_17
    owner to postgres;

grant select on minute_candles_2025_05_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_17 to admin;

create table minute_candles_2025_05_18
    partition of minute_candles
        FOR VALUES FROM ('2025-05-17 21:00:00+00') TO ('2025-05-18 21:00:00+00');

alter table minute_candles_2025_05_18
    owner to postgres;

grant select on minute_candles_2025_05_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_18 to admin;

create table minute_candles_2025_05_19
    partition of minute_candles
        FOR VALUES FROM ('2025-05-18 21:00:00+00') TO ('2025-05-19 21:00:00+00');

alter table minute_candles_2025_05_19
    owner to postgres;

grant select on minute_candles_2025_05_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_19 to admin;

create table minute_candles_2025_05_20
    partition of minute_candles
        FOR VALUES FROM ('2025-05-19 21:00:00+00') TO ('2025-05-20 21:00:00+00');

alter table minute_candles_2025_05_20
    owner to postgres;

grant select on minute_candles_2025_05_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_20 to admin;

create table minute_candles_2025_05_21
    partition of minute_candles
        FOR VALUES FROM ('2025-05-20 21:00:00+00') TO ('2025-05-21 21:00:00+00');

alter table minute_candles_2025_05_21
    owner to postgres;

grant select on minute_candles_2025_05_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_21 to admin;

create table minute_candles_2025_05_22
    partition of minute_candles
        FOR VALUES FROM ('2025-05-21 21:00:00+00') TO ('2025-05-22 21:00:00+00');

alter table minute_candles_2025_05_22
    owner to postgres;

grant select on minute_candles_2025_05_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_22 to admin;

create table minute_candles_2025_05_23
    partition of minute_candles
        FOR VALUES FROM ('2025-05-22 21:00:00+00') TO ('2025-05-23 21:00:00+00');

alter table minute_candles_2025_05_23
    owner to postgres;

grant select on minute_candles_2025_05_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_23 to admin;

create table minute_candles_2025_05_24
    partition of minute_candles
        FOR VALUES FROM ('2025-05-23 21:00:00+00') TO ('2025-05-24 21:00:00+00');

alter table minute_candles_2025_05_24
    owner to postgres;

grant select on minute_candles_2025_05_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_24 to admin;

create table minute_candles_2025_05_25
    partition of minute_candles
        FOR VALUES FROM ('2025-05-24 21:00:00+00') TO ('2025-05-25 21:00:00+00');

alter table minute_candles_2025_05_25
    owner to postgres;

grant select on minute_candles_2025_05_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_25 to admin;

create table minute_candles_2025_05_26
    partition of minute_candles
        FOR VALUES FROM ('2025-05-25 21:00:00+00') TO ('2025-05-26 21:00:00+00');

alter table minute_candles_2025_05_26
    owner to postgres;

grant select on minute_candles_2025_05_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_26 to admin;

create table minute_candles_2025_05_27
    partition of minute_candles
        FOR VALUES FROM ('2025-05-26 21:00:00+00') TO ('2025-05-27 21:00:00+00');

alter table minute_candles_2025_05_27
    owner to postgres;

grant select on minute_candles_2025_05_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_27 to admin;

create table minute_candles_2025_05_28
    partition of minute_candles
        FOR VALUES FROM ('2025-05-27 21:00:00+00') TO ('2025-05-28 21:00:00+00');

alter table minute_candles_2025_05_28
    owner to postgres;

grant select on minute_candles_2025_05_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_28 to admin;

create table minute_candles_2025_05_29
    partition of minute_candles
        FOR VALUES FROM ('2025-05-28 21:00:00+00') TO ('2025-05-29 21:00:00+00');

alter table minute_candles_2025_05_29
    owner to postgres;

grant select on minute_candles_2025_05_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_29 to admin;

create table minute_candles_2025_05_30
    partition of minute_candles
        FOR VALUES FROM ('2025-05-29 21:00:00+00') TO ('2025-05-30 21:00:00+00');

alter table minute_candles_2025_05_30
    owner to postgres;

grant select on minute_candles_2025_05_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_30 to admin;

create table minute_candles_2025_05_31
    partition of minute_candles
        FOR VALUES FROM ('2025-05-30 21:00:00+00') TO ('2025-05-31 21:00:00+00');

alter table minute_candles_2025_05_31
    owner to postgres;

grant select on minute_candles_2025_05_31 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_05_31 to admin;

create table minute_candles_2025_06_01
    partition of minute_candles
        FOR VALUES FROM ('2025-05-31 21:00:00+00') TO ('2025-06-01 21:00:00+00');

alter table minute_candles_2025_06_01
    owner to postgres;

grant select on minute_candles_2025_06_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_01 to admin;

create table minute_candles_2025_06_02
    partition of minute_candles
        FOR VALUES FROM ('2025-06-01 21:00:00+00') TO ('2025-06-02 21:00:00+00');

alter table minute_candles_2025_06_02
    owner to postgres;

grant select on minute_candles_2025_06_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_02 to admin;

create table minute_candles_2025_06_03
    partition of minute_candles
        FOR VALUES FROM ('2025-06-02 21:00:00+00') TO ('2025-06-03 21:00:00+00');

alter table minute_candles_2025_06_03
    owner to postgres;

grant select on minute_candles_2025_06_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_03 to admin;

create table minute_candles_2025_06_04
    partition of minute_candles
        FOR VALUES FROM ('2025-06-03 21:00:00+00') TO ('2025-06-04 21:00:00+00');

alter table minute_candles_2025_06_04
    owner to postgres;

grant select on minute_candles_2025_06_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_04 to admin;

create table minute_candles_2025_06_05
    partition of minute_candles
        FOR VALUES FROM ('2025-06-04 21:00:00+00') TO ('2025-06-05 21:00:00+00');

alter table minute_candles_2025_06_05
    owner to postgres;

grant select on minute_candles_2025_06_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_05 to admin;

create table minute_candles_2025_06_06
    partition of minute_candles
        FOR VALUES FROM ('2025-06-05 21:00:00+00') TO ('2025-06-06 21:00:00+00');

alter table minute_candles_2025_06_06
    owner to postgres;

grant select on minute_candles_2025_06_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_06 to admin;

create table minute_candles_2025_06_07
    partition of minute_candles
        FOR VALUES FROM ('2025-06-06 21:00:00+00') TO ('2025-06-07 21:00:00+00');

alter table minute_candles_2025_06_07
    owner to postgres;

grant select on minute_candles_2025_06_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_07 to admin;

create table minute_candles_2025_06_08
    partition of minute_candles
        FOR VALUES FROM ('2025-06-07 21:00:00+00') TO ('2025-06-08 21:00:00+00');

alter table minute_candles_2025_06_08
    owner to postgres;

grant select on minute_candles_2025_06_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_08 to admin;

create table minute_candles_2025_06_09
    partition of minute_candles
        FOR VALUES FROM ('2025-06-08 21:00:00+00') TO ('2025-06-09 21:00:00+00');

alter table minute_candles_2025_06_09
    owner to postgres;

grant select on minute_candles_2025_06_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_09 to admin;

create table minute_candles_2025_06_10
    partition of minute_candles
        FOR VALUES FROM ('2025-06-09 21:00:00+00') TO ('2025-06-10 21:00:00+00');

alter table minute_candles_2025_06_10
    owner to postgres;

grant select on minute_candles_2025_06_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_10 to admin;

create table minute_candles_2025_06_11
    partition of minute_candles
        FOR VALUES FROM ('2025-06-10 21:00:00+00') TO ('2025-06-11 21:00:00+00');

alter table minute_candles_2025_06_11
    owner to postgres;

grant select on minute_candles_2025_06_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_11 to admin;

create table minute_candles_2025_06_12
    partition of minute_candles
        FOR VALUES FROM ('2025-06-11 21:00:00+00') TO ('2025-06-12 21:00:00+00');

alter table minute_candles_2025_06_12
    owner to postgres;

grant select on minute_candles_2025_06_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_12 to admin;

create table minute_candles_2025_06_13
    partition of minute_candles
        FOR VALUES FROM ('2025-06-12 21:00:00+00') TO ('2025-06-13 21:00:00+00');

alter table minute_candles_2025_06_13
    owner to postgres;

grant select on minute_candles_2025_06_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_13 to admin;

create table minute_candles_2025_06_14
    partition of minute_candles
        FOR VALUES FROM ('2025-06-13 21:00:00+00') TO ('2025-06-14 21:00:00+00');

alter table minute_candles_2025_06_14
    owner to postgres;

grant select on minute_candles_2025_06_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_14 to admin;

create table minute_candles_2025_06_15
    partition of minute_candles
        FOR VALUES FROM ('2025-06-14 21:00:00+00') TO ('2025-06-15 21:00:00+00');

alter table minute_candles_2025_06_15
    owner to postgres;

grant select on minute_candles_2025_06_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_15 to admin;

create table minute_candles_2025_06_16
    partition of minute_candles
        FOR VALUES FROM ('2025-06-15 21:00:00+00') TO ('2025-06-16 21:00:00+00');

alter table minute_candles_2025_06_16
    owner to postgres;

grant select on minute_candles_2025_06_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_16 to admin;

create table minute_candles_2025_06_17
    partition of minute_candles
        FOR VALUES FROM ('2025-06-16 21:00:00+00') TO ('2025-06-17 21:00:00+00');

alter table minute_candles_2025_06_17
    owner to postgres;

grant select on minute_candles_2025_06_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_17 to admin;

create table minute_candles_2025_06_18
    partition of minute_candles
        FOR VALUES FROM ('2025-06-17 21:00:00+00') TO ('2025-06-18 21:00:00+00');

alter table minute_candles_2025_06_18
    owner to postgres;

grant select on minute_candles_2025_06_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_18 to admin;

create table minute_candles_2025_06_19
    partition of minute_candles
        FOR VALUES FROM ('2025-06-18 21:00:00+00') TO ('2025-06-19 21:00:00+00');

alter table minute_candles_2025_06_19
    owner to postgres;

grant select on minute_candles_2025_06_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_19 to admin;

create table minute_candles_2025_06_20
    partition of minute_candles
        FOR VALUES FROM ('2025-06-19 21:00:00+00') TO ('2025-06-20 21:00:00+00');

alter table minute_candles_2025_06_20
    owner to postgres;

grant select on minute_candles_2025_06_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_20 to admin;

create table minute_candles_2025_06_21
    partition of minute_candles
        FOR VALUES FROM ('2025-06-20 21:00:00+00') TO ('2025-06-21 21:00:00+00');

alter table minute_candles_2025_06_21
    owner to postgres;

grant select on minute_candles_2025_06_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_21 to admin;

create table minute_candles_2025_06_22
    partition of minute_candles
        FOR VALUES FROM ('2025-06-21 21:00:00+00') TO ('2025-06-22 21:00:00+00');

alter table minute_candles_2025_06_22
    owner to postgres;

grant select on minute_candles_2025_06_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_22 to admin;

create table minute_candles_2025_06_23
    partition of minute_candles
        FOR VALUES FROM ('2025-06-22 21:00:00+00') TO ('2025-06-23 21:00:00+00');

alter table minute_candles_2025_06_23
    owner to postgres;

grant select on minute_candles_2025_06_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_23 to admin;

create table minute_candles_2025_06_24
    partition of minute_candles
        FOR VALUES FROM ('2025-06-23 21:00:00+00') TO ('2025-06-24 21:00:00+00');

alter table minute_candles_2025_06_24
    owner to postgres;

grant select on minute_candles_2025_06_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_24 to admin;

create table minute_candles_2025_06_25
    partition of minute_candles
        FOR VALUES FROM ('2025-06-24 21:00:00+00') TO ('2025-06-25 21:00:00+00');

alter table minute_candles_2025_06_25
    owner to postgres;

grant select on minute_candles_2025_06_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_25 to admin;

create table minute_candles_2025_06_26
    partition of minute_candles
        FOR VALUES FROM ('2025-06-25 21:00:00+00') TO ('2025-06-26 21:00:00+00');

alter table minute_candles_2025_06_26
    owner to postgres;

grant select on minute_candles_2025_06_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_26 to admin;

create table minute_candles_2025_06_27
    partition of minute_candles
        FOR VALUES FROM ('2025-06-26 21:00:00+00') TO ('2025-06-27 21:00:00+00');

alter table minute_candles_2025_06_27
    owner to postgres;

grant select on minute_candles_2025_06_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_27 to admin;

create table minute_candles_2025_06_28
    partition of minute_candles
        FOR VALUES FROM ('2025-06-27 21:00:00+00') TO ('2025-06-28 21:00:00+00');

alter table minute_candles_2025_06_28
    owner to postgres;

grant select on minute_candles_2025_06_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_28 to admin;

create table minute_candles_2025_06_29
    partition of minute_candles
        FOR VALUES FROM ('2025-06-28 21:00:00+00') TO ('2025-06-29 21:00:00+00');

alter table minute_candles_2025_06_29
    owner to postgres;

grant select on minute_candles_2025_06_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_29 to admin;

create table minute_candles_2025_06_30
    partition of minute_candles
        FOR VALUES FROM ('2025-06-29 21:00:00+00') TO ('2025-06-30 21:00:00+00');

alter table minute_candles_2025_06_30
    owner to postgres;

grant select on minute_candles_2025_06_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_06_30 to admin;

create table minute_candles_2025_07_01
    partition of minute_candles
        FOR VALUES FROM ('2025-06-30 21:00:00+00') TO ('2025-07-01 21:00:00+00');

alter table minute_candles_2025_07_01
    owner to postgres;

grant select on minute_candles_2025_07_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_01 to admin;

create table minute_candles_2025_07_02
    partition of minute_candles
        FOR VALUES FROM ('2025-07-01 21:00:00+00') TO ('2025-07-02 21:00:00+00');

alter table minute_candles_2025_07_02
    owner to postgres;

grant select on minute_candles_2025_07_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_02 to admin;

create table minute_candles_2025_07_03
    partition of minute_candles
        FOR VALUES FROM ('2025-07-02 21:00:00+00') TO ('2025-07-03 21:00:00+00');

alter table minute_candles_2025_07_03
    owner to postgres;

grant select on minute_candles_2025_07_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_03 to admin;

create table minute_candles_2025_07_04
    partition of minute_candles
        FOR VALUES FROM ('2025-07-03 21:00:00+00') TO ('2025-07-04 21:00:00+00');

alter table minute_candles_2025_07_04
    owner to postgres;

grant select on minute_candles_2025_07_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_04 to admin;

create table minute_candles_2025_07_05
    partition of minute_candles
        FOR VALUES FROM ('2025-07-04 21:00:00+00') TO ('2025-07-05 21:00:00+00');

alter table minute_candles_2025_07_05
    owner to postgres;

grant select on minute_candles_2025_07_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_05 to admin;

create table minute_candles_2025_07_06
    partition of minute_candles
        FOR VALUES FROM ('2025-07-05 21:00:00+00') TO ('2025-07-06 21:00:00+00');

alter table minute_candles_2025_07_06
    owner to postgres;

grant select on minute_candles_2025_07_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_06 to admin;

create table minute_candles_2025_07_07
    partition of minute_candles
        FOR VALUES FROM ('2025-07-06 21:00:00+00') TO ('2025-07-07 21:00:00+00');

alter table minute_candles_2025_07_07
    owner to postgres;

grant select on minute_candles_2025_07_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_07 to admin;

create table minute_candles_2025_07_08
    partition of minute_candles
        FOR VALUES FROM ('2025-07-07 21:00:00+00') TO ('2025-07-08 21:00:00+00');

alter table minute_candles_2025_07_08
    owner to postgres;

grant select on minute_candles_2025_07_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_08 to admin;

create table minute_candles_2025_07_09
    partition of minute_candles
        FOR VALUES FROM ('2025-07-08 21:00:00+00') TO ('2025-07-09 21:00:00+00');

alter table minute_candles_2025_07_09
    owner to postgres;

grant select on minute_candles_2025_07_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_09 to admin;

create table minute_candles_2025_07_10
    partition of minute_candles
        FOR VALUES FROM ('2025-07-09 21:00:00+00') TO ('2025-07-10 21:00:00+00');

alter table minute_candles_2025_07_10
    owner to postgres;

grant select on minute_candles_2025_07_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_10 to admin;

create table minute_candles_2025_07_11
    partition of minute_candles
        FOR VALUES FROM ('2025-07-10 21:00:00+00') TO ('2025-07-11 21:00:00+00');

alter table minute_candles_2025_07_11
    owner to postgres;

grant select on minute_candles_2025_07_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_11 to admin;

create table minute_candles_2025_07_12
    partition of minute_candles
        FOR VALUES FROM ('2025-07-11 21:00:00+00') TO ('2025-07-12 21:00:00+00');

alter table minute_candles_2025_07_12
    owner to postgres;

grant select on minute_candles_2025_07_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_12 to admin;

create table minute_candles_2025_07_13
    partition of minute_candles
        FOR VALUES FROM ('2025-07-12 21:00:00+00') TO ('2025-07-13 21:00:00+00');

alter table minute_candles_2025_07_13
    owner to postgres;

grant select on minute_candles_2025_07_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_13 to admin;

create table minute_candles_2025_07_14
    partition of minute_candles
        FOR VALUES FROM ('2025-07-13 21:00:00+00') TO ('2025-07-14 21:00:00+00');

alter table minute_candles_2025_07_14
    owner to postgres;

grant select on minute_candles_2025_07_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_14 to admin;

create table minute_candles_2025_07_15
    partition of minute_candles
        FOR VALUES FROM ('2025-07-14 21:00:00+00') TO ('2025-07-15 21:00:00+00');

alter table minute_candles_2025_07_15
    owner to postgres;

grant select on minute_candles_2025_07_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_15 to admin;

create table minute_candles_2025_07_16
    partition of minute_candles
        FOR VALUES FROM ('2025-07-15 21:00:00+00') TO ('2025-07-16 21:00:00+00');

alter table minute_candles_2025_07_16
    owner to postgres;

grant select on minute_candles_2025_07_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_16 to admin;

create table minute_candles_2025_07_17
    partition of minute_candles
        FOR VALUES FROM ('2025-07-16 21:00:00+00') TO ('2025-07-17 21:00:00+00');

alter table minute_candles_2025_07_17
    owner to postgres;

grant select on minute_candles_2025_07_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_17 to admin;

create table minute_candles_2025_07_18
    partition of minute_candles
        FOR VALUES FROM ('2025-07-17 21:00:00+00') TO ('2025-07-18 21:00:00+00');

alter table minute_candles_2025_07_18
    owner to postgres;

grant select on minute_candles_2025_07_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_18 to admin;

create table minute_candles_2025_07_19
    partition of minute_candles
        FOR VALUES FROM ('2025-07-18 21:00:00+00') TO ('2025-07-19 21:00:00+00');

alter table minute_candles_2025_07_19
    owner to postgres;

grant select on minute_candles_2025_07_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_19 to admin;

create table minute_candles_2025_07_20
    partition of minute_candles
        FOR VALUES FROM ('2025-07-19 21:00:00+00') TO ('2025-07-20 21:00:00+00');

alter table minute_candles_2025_07_20
    owner to postgres;

grant select on minute_candles_2025_07_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_20 to admin;

create table minute_candles_2025_07_21
    partition of minute_candles
        FOR VALUES FROM ('2025-07-20 21:00:00+00') TO ('2025-07-21 21:00:00+00');

alter table minute_candles_2025_07_21
    owner to postgres;

grant select on minute_candles_2025_07_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_21 to admin;

create table minute_candles_2025_07_22
    partition of minute_candles
        FOR VALUES FROM ('2025-07-21 21:00:00+00') TO ('2025-07-22 21:00:00+00');

alter table minute_candles_2025_07_22
    owner to postgres;

grant select on minute_candles_2025_07_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_22 to admin;

create table minute_candles_2025_07_23
    partition of minute_candles
        FOR VALUES FROM ('2025-07-22 21:00:00+00') TO ('2025-07-23 21:00:00+00');

alter table minute_candles_2025_07_23
    owner to postgres;

grant select on minute_candles_2025_07_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_23 to admin;

create table minute_candles_2025_07_24
    partition of minute_candles
        FOR VALUES FROM ('2025-07-23 21:00:00+00') TO ('2025-07-24 21:00:00+00');

alter table minute_candles_2025_07_24
    owner to postgres;

grant select on minute_candles_2025_07_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_24 to admin;

create table minute_candles_2025_07_25
    partition of minute_candles
        FOR VALUES FROM ('2025-07-24 21:00:00+00') TO ('2025-07-25 21:00:00+00');

alter table minute_candles_2025_07_25
    owner to postgres;

grant select on minute_candles_2025_07_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_25 to admin;

create table minute_candles_2025_07_26
    partition of minute_candles
        FOR VALUES FROM ('2025-07-25 21:00:00+00') TO ('2025-07-26 21:00:00+00');

alter table minute_candles_2025_07_26
    owner to postgres;

grant select on minute_candles_2025_07_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_26 to admin;

create table minute_candles_2025_07_27
    partition of minute_candles
        FOR VALUES FROM ('2025-07-26 21:00:00+00') TO ('2025-07-27 21:00:00+00');

alter table minute_candles_2025_07_27
    owner to postgres;

grant select on minute_candles_2025_07_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_27 to admin;

create table minute_candles_2025_07_28
    partition of minute_candles
        FOR VALUES FROM ('2025-07-27 21:00:00+00') TO ('2025-07-28 21:00:00+00');

alter table minute_candles_2025_07_28
    owner to postgres;

grant select on minute_candles_2025_07_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_28 to admin;

create table minute_candles_2025_07_29
    partition of minute_candles
        FOR VALUES FROM ('2025-07-28 21:00:00+00') TO ('2025-07-29 21:00:00+00');

alter table minute_candles_2025_07_29
    owner to postgres;

grant select on minute_candles_2025_07_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_29 to admin;

create table minute_candles_2025_07_30
    partition of minute_candles
        FOR VALUES FROM ('2025-07-29 21:00:00+00') TO ('2025-07-30 21:00:00+00');

alter table minute_candles_2025_07_30
    owner to postgres;

grant select on minute_candles_2025_07_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_30 to admin;

create table minute_candles_2025_07_31
    partition of minute_candles
        FOR VALUES FROM ('2025-07-30 21:00:00+00') TO ('2025-07-31 21:00:00+00');

alter table minute_candles_2025_07_31
    owner to postgres;

grant select on minute_candles_2025_07_31 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_07_31 to admin;

create table minute_candles_2025_08_01
    partition of minute_candles
        FOR VALUES FROM ('2025-07-31 21:00:00+00') TO ('2025-08-01 21:00:00+00');

alter table minute_candles_2025_08_01
    owner to postgres;

grant select on minute_candles_2025_08_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_01 to admin;

create table minute_candles_2025_08_02
    partition of minute_candles
        FOR VALUES FROM ('2025-08-01 21:00:00+00') TO ('2025-08-02 21:00:00+00');

alter table minute_candles_2025_08_02
    owner to postgres;

grant select on minute_candles_2025_08_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_02 to admin;

create table minute_candles_2025_08_03
    partition of minute_candles
        FOR VALUES FROM ('2025-08-02 21:00:00+00') TO ('2025-08-03 21:00:00+00');

alter table minute_candles_2025_08_03
    owner to postgres;

grant select on minute_candles_2025_08_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_03 to admin;

create table minute_candles_2025_08_04
    partition of minute_candles
        FOR VALUES FROM ('2025-08-03 21:00:00+00') TO ('2025-08-04 21:00:00+00');

alter table minute_candles_2025_08_04
    owner to postgres;

grant select on minute_candles_2025_08_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_04 to admin;

create table minute_candles_2025_08_05
    partition of minute_candles
        FOR VALUES FROM ('2025-08-04 21:00:00+00') TO ('2025-08-05 21:00:00+00');

alter table minute_candles_2025_08_05
    owner to postgres;

grant select on minute_candles_2025_08_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_05 to admin;

create table minute_candles_2025_08_06
    partition of minute_candles
        FOR VALUES FROM ('2025-08-05 21:00:00+00') TO ('2025-08-06 21:00:00+00');

alter table minute_candles_2025_08_06
    owner to postgres;

grant select on minute_candles_2025_08_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_06 to admin;

create table minute_candles_2025_08_07
    partition of minute_candles
        FOR VALUES FROM ('2025-08-06 21:00:00+00') TO ('2025-08-07 21:00:00+00');

alter table minute_candles_2025_08_07
    owner to postgres;

grant select on minute_candles_2025_08_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_07 to admin;

create table minute_candles_2025_08_08
    partition of minute_candles
        FOR VALUES FROM ('2025-08-07 21:00:00+00') TO ('2025-08-08 21:00:00+00');

alter table minute_candles_2025_08_08
    owner to postgres;

grant select on minute_candles_2025_08_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_08 to admin;

create table minute_candles_2025_08_09
    partition of minute_candles
        FOR VALUES FROM ('2025-08-08 21:00:00+00') TO ('2025-08-09 21:00:00+00');

alter table minute_candles_2025_08_09
    owner to postgres;

grant select on minute_candles_2025_08_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_09 to admin;

create table minute_candles_2025_08_10
    partition of minute_candles
        FOR VALUES FROM ('2025-08-09 21:00:00+00') TO ('2025-08-10 21:00:00+00');

alter table minute_candles_2025_08_10
    owner to postgres;

grant select on minute_candles_2025_08_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_10 to admin;

create table minute_candles_2025_08_11
    partition of minute_candles
        FOR VALUES FROM ('2025-08-10 21:00:00+00') TO ('2025-08-11 21:00:00+00');

alter table minute_candles_2025_08_11
    owner to postgres;

grant select on minute_candles_2025_08_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_11 to admin;

create table minute_candles_2025_08_12
    partition of minute_candles
        FOR VALUES FROM ('2025-08-11 21:00:00+00') TO ('2025-08-12 21:00:00+00');

alter table minute_candles_2025_08_12
    owner to postgres;

grant select on minute_candles_2025_08_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_12 to admin;

create table minute_candles_2025_08_13
    partition of minute_candles
        FOR VALUES FROM ('2025-08-12 21:00:00+00') TO ('2025-08-13 21:00:00+00');

alter table minute_candles_2025_08_13
    owner to postgres;

grant select on minute_candles_2025_08_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_13 to admin;

create table minute_candles_2025_08_14
    partition of minute_candles
        FOR VALUES FROM ('2025-08-13 21:00:00+00') TO ('2025-08-14 21:00:00+00');

alter table minute_candles_2025_08_14
    owner to postgres;

grant select on minute_candles_2025_08_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_14 to admin;

create table minute_candles_2025_08_15
    partition of minute_candles
        FOR VALUES FROM ('2025-08-14 21:00:00+00') TO ('2025-08-15 21:00:00+00');

alter table minute_candles_2025_08_15
    owner to postgres;

grant select on minute_candles_2025_08_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_15 to admin;

create table minute_candles_2025_08_16
    partition of minute_candles
        FOR VALUES FROM ('2025-08-15 21:00:00+00') TO ('2025-08-16 21:00:00+00');

alter table minute_candles_2025_08_16
    owner to postgres;

grant select on minute_candles_2025_08_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_16 to admin;

create table minute_candles_2025_08_17
    partition of minute_candles
        FOR VALUES FROM ('2025-08-16 21:00:00+00') TO ('2025-08-17 21:00:00+00');

alter table minute_candles_2025_08_17
    owner to postgres;

grant select on minute_candles_2025_08_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_17 to admin;

create table minute_candles_2025_08_18
    partition of minute_candles
        FOR VALUES FROM ('2025-08-17 21:00:00+00') TO ('2025-08-18 21:00:00+00');

alter table minute_candles_2025_08_18
    owner to postgres;

grant select on minute_candles_2025_08_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_18 to admin;

create table minute_candles_2025_08_19
    partition of minute_candles
        FOR VALUES FROM ('2025-08-18 21:00:00+00') TO ('2025-08-19 21:00:00+00');

alter table minute_candles_2025_08_19
    owner to postgres;

grant select on minute_candles_2025_08_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_19 to admin;

create table minute_candles_2025_08_20
    partition of minute_candles
        FOR VALUES FROM ('2025-08-19 21:00:00+00') TO ('2025-08-20 21:00:00+00');

alter table minute_candles_2025_08_20
    owner to postgres;

grant select on minute_candles_2025_08_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_20 to admin;

create table minute_candles_2025_08_21
    partition of minute_candles
        FOR VALUES FROM ('2025-08-20 21:00:00+00') TO ('2025-08-21 21:00:00+00');

alter table minute_candles_2025_08_21
    owner to postgres;

grant select on minute_candles_2025_08_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_21 to admin;

create table minute_candles_2025_08_22
    partition of minute_candles
        FOR VALUES FROM ('2025-08-21 21:00:00+00') TO ('2025-08-22 21:00:00+00');

alter table minute_candles_2025_08_22
    owner to postgres;

grant select on minute_candles_2025_08_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_22 to admin;

create table minute_candles_2025_08_23
    partition of minute_candles
        FOR VALUES FROM ('2025-08-22 21:00:00+00') TO ('2025-08-23 21:00:00+00');

alter table minute_candles_2025_08_23
    owner to postgres;

grant select on minute_candles_2025_08_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_23 to admin;

create table minute_candles_2025_08_24
    partition of minute_candles
        FOR VALUES FROM ('2025-08-23 21:00:00+00') TO ('2025-08-24 21:00:00+00');

alter table minute_candles_2025_08_24
    owner to postgres;

grant select on minute_candles_2025_08_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_24 to admin;

create table minute_candles_2025_08_25
    partition of minute_candles
        FOR VALUES FROM ('2025-08-24 21:00:00+00') TO ('2025-08-25 21:00:00+00');

alter table minute_candles_2025_08_25
    owner to postgres;

grant select on minute_candles_2025_08_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_25 to admin;

create table minute_candles_2025_08_26
    partition of minute_candles
        FOR VALUES FROM ('2025-08-25 21:00:00+00') TO ('2025-08-26 21:00:00+00');

alter table minute_candles_2025_08_26
    owner to postgres;

grant select on minute_candles_2025_08_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_26 to admin;

create table minute_candles_2025_08_27
    partition of minute_candles
        FOR VALUES FROM ('2025-08-26 21:00:00+00') TO ('2025-08-27 21:00:00+00');

alter table minute_candles_2025_08_27
    owner to postgres;

grant select on minute_candles_2025_08_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_27 to admin;

create table minute_candles_2025_08_28
    partition of minute_candles
        FOR VALUES FROM ('2025-08-27 21:00:00+00') TO ('2025-08-28 21:00:00+00');

alter table minute_candles_2025_08_28
    owner to postgres;

grant select on minute_candles_2025_08_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_28 to admin;

create table minute_candles_2025_08_29
    partition of minute_candles
        FOR VALUES FROM ('2025-08-28 21:00:00+00') TO ('2025-08-29 21:00:00+00');

alter table minute_candles_2025_08_29
    owner to postgres;

grant select on minute_candles_2025_08_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_29 to admin;

create table minute_candles_2025_08_30
    partition of minute_candles
        FOR VALUES FROM ('2025-08-29 21:00:00+00') TO ('2025-08-30 21:00:00+00');

alter table minute_candles_2025_08_30
    owner to postgres;

grant select on minute_candles_2025_08_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_30 to admin;

create table minute_candles_2025_08_31
    partition of minute_candles
        FOR VALUES FROM ('2025-08-30 21:00:00+00') TO ('2025-08-31 21:00:00+00');

alter table minute_candles_2025_08_31
    owner to postgres;

grant select on minute_candles_2025_08_31 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_08_31 to admin;

create table minute_candles_2025_09_01
    partition of minute_candles
        FOR VALUES FROM ('2025-08-31 21:00:00+00') TO ('2025-09-01 21:00:00+00');

alter table minute_candles_2025_09_01
    owner to postgres;

grant select on minute_candles_2025_09_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_01 to admin;

create table minute_candles_2025_09_02
    partition of minute_candles
        FOR VALUES FROM ('2025-09-01 21:00:00+00') TO ('2025-09-02 21:00:00+00');

alter table minute_candles_2025_09_02
    owner to postgres;

grant select on minute_candles_2025_09_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_02 to admin;

create table minute_candles_2025_09_03
    partition of minute_candles
        FOR VALUES FROM ('2025-09-02 21:00:00+00') TO ('2025-09-03 21:00:00+00');

alter table minute_candles_2025_09_03
    owner to postgres;

grant select on minute_candles_2025_09_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_03 to admin;

create table minute_candles_2025_09_04
    partition of minute_candles
        FOR VALUES FROM ('2025-09-03 21:00:00+00') TO ('2025-09-04 21:00:00+00');

alter table minute_candles_2025_09_04
    owner to postgres;

grant select on minute_candles_2025_09_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_04 to admin;

create table minute_candles_2025_09_05
    partition of minute_candles
        FOR VALUES FROM ('2025-09-04 21:00:00+00') TO ('2025-09-05 21:00:00+00');

alter table minute_candles_2025_09_05
    owner to postgres;

grant select on minute_candles_2025_09_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_05 to admin;

create table minute_candles_2025_09_06
    partition of minute_candles
        FOR VALUES FROM ('2025-09-05 21:00:00+00') TO ('2025-09-06 21:00:00+00');

alter table minute_candles_2025_09_06
    owner to postgres;

grant select on minute_candles_2025_09_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_06 to admin;

create table minute_candles_2025_09_07
    partition of minute_candles
        FOR VALUES FROM ('2025-09-06 21:00:00+00') TO ('2025-09-07 21:00:00+00');

alter table minute_candles_2025_09_07
    owner to postgres;

grant select on minute_candles_2025_09_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_07 to admin;

create table minute_candles_2025_09_08
    partition of minute_candles
        FOR VALUES FROM ('2025-09-07 21:00:00+00') TO ('2025-09-08 21:00:00+00');

alter table minute_candles_2025_09_08
    owner to postgres;

grant select on minute_candles_2025_09_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_08 to admin;

create table minute_candles_2025_09_09
    partition of minute_candles
        FOR VALUES FROM ('2025-09-08 21:00:00+00') TO ('2025-09-09 21:00:00+00');

alter table minute_candles_2025_09_09
    owner to postgres;

grant select on minute_candles_2025_09_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_09 to admin;

create table minute_candles_2025_09_10
    partition of minute_candles
        FOR VALUES FROM ('2025-09-09 21:00:00+00') TO ('2025-09-10 21:00:00+00');

alter table minute_candles_2025_09_10
    owner to postgres;

grant select on minute_candles_2025_09_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_10 to admin;

create table minute_candles_2025_09_11
    partition of minute_candles
        FOR VALUES FROM ('2025-09-10 21:00:00+00') TO ('2025-09-11 21:00:00+00');

alter table minute_candles_2025_09_11
    owner to postgres;

grant select on minute_candles_2025_09_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_11 to admin;

create table minute_candles_2025_09_12
    partition of minute_candles
        FOR VALUES FROM ('2025-09-11 21:00:00+00') TO ('2025-09-12 21:00:00+00');

alter table minute_candles_2025_09_12
    owner to postgres;

grant select on minute_candles_2025_09_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_12 to admin;

create table minute_candles_2025_09_13
    partition of minute_candles
        FOR VALUES FROM ('2025-09-12 21:00:00+00') TO ('2025-09-13 21:00:00+00');

alter table minute_candles_2025_09_13
    owner to postgres;

grant select on minute_candles_2025_09_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_13 to admin;

create table minute_candles_2025_09_14
    partition of minute_candles
        FOR VALUES FROM ('2025-09-13 21:00:00+00') TO ('2025-09-14 21:00:00+00');

alter table minute_candles_2025_09_14
    owner to postgres;

grant select on minute_candles_2025_09_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_14 to admin;

create table minute_candles_2025_09_15
    partition of minute_candles
        FOR VALUES FROM ('2025-09-14 21:00:00+00') TO ('2025-09-15 21:00:00+00');

alter table minute_candles_2025_09_15
    owner to postgres;

grant select on minute_candles_2025_09_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_15 to admin;

create table minute_candles_2025_09_16
    partition of minute_candles
        FOR VALUES FROM ('2025-09-15 21:00:00+00') TO ('2025-09-16 21:00:00+00');

alter table minute_candles_2025_09_16
    owner to postgres;

grant select on minute_candles_2025_09_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_16 to admin;

create table minute_candles_2025_09_17
    partition of minute_candles
        FOR VALUES FROM ('2025-09-16 21:00:00+00') TO ('2025-09-17 21:00:00+00');

alter table minute_candles_2025_09_17
    owner to postgres;

grant select on minute_candles_2025_09_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_17 to admin;

create table minute_candles_2025_09_18
    partition of minute_candles
        FOR VALUES FROM ('2025-09-17 21:00:00+00') TO ('2025-09-18 21:00:00+00');

alter table minute_candles_2025_09_18
    owner to postgres;

grant select on minute_candles_2025_09_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_18 to admin;

create table minute_candles_2025_09_19
    partition of minute_candles
        FOR VALUES FROM ('2025-09-18 21:00:00+00') TO ('2025-09-19 21:00:00+00');

alter table minute_candles_2025_09_19
    owner to postgres;

grant select on minute_candles_2025_09_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_19 to admin;

create table minute_candles_2025_09_20
    partition of minute_candles
        FOR VALUES FROM ('2025-09-19 21:00:00+00') TO ('2025-09-20 21:00:00+00');

alter table minute_candles_2025_09_20
    owner to postgres;

grant select on minute_candles_2025_09_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_20 to admin;

create table minute_candles_2025_09_21
    partition of minute_candles
        FOR VALUES FROM ('2025-09-20 21:00:00+00') TO ('2025-09-21 21:00:00+00');

alter table minute_candles_2025_09_21
    owner to postgres;

grant select on minute_candles_2025_09_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_21 to admin;

create table minute_candles_2025_09_22
    partition of minute_candles
        FOR VALUES FROM ('2025-09-21 21:00:00+00') TO ('2025-09-22 21:00:00+00');

alter table minute_candles_2025_09_22
    owner to postgres;

grant select on minute_candles_2025_09_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_22 to admin;

create table minute_candles_2025_09_23
    partition of minute_candles
        FOR VALUES FROM ('2025-09-22 21:00:00+00') TO ('2025-09-23 21:00:00+00');

alter table minute_candles_2025_09_23
    owner to postgres;

grant select on minute_candles_2025_09_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_23 to admin;

create table minute_candles_2025_09_24
    partition of minute_candles
        FOR VALUES FROM ('2025-09-23 21:00:00+00') TO ('2025-09-24 21:00:00+00');

alter table minute_candles_2025_09_24
    owner to postgres;

grant select on minute_candles_2025_09_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_24 to admin;

create table minute_candles_2025_09_25
    partition of minute_candles
        FOR VALUES FROM ('2025-09-24 21:00:00+00') TO ('2025-09-25 21:00:00+00');

alter table minute_candles_2025_09_25
    owner to postgres;

grant select on minute_candles_2025_09_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_25 to admin;

create table minute_candles_2025_09_26
    partition of minute_candles
        FOR VALUES FROM ('2025-09-25 21:00:00+00') TO ('2025-09-26 21:00:00+00');

alter table minute_candles_2025_09_26
    owner to postgres;

grant select on minute_candles_2025_09_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_26 to admin;

create table minute_candles_2025_09_27
    partition of minute_candles
        FOR VALUES FROM ('2025-09-26 21:00:00+00') TO ('2025-09-27 21:00:00+00');

alter table minute_candles_2025_09_27
    owner to postgres;

grant select on minute_candles_2025_09_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_27 to admin;

create table minute_candles_2025_09_28
    partition of minute_candles
        FOR VALUES FROM ('2025-09-27 21:00:00+00') TO ('2025-09-28 21:00:00+00');

alter table minute_candles_2025_09_28
    owner to postgres;

grant select on minute_candles_2025_09_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_28 to admin;

create table minute_candles_2025_09_29
    partition of minute_candles
        FOR VALUES FROM ('2025-09-28 21:00:00+00') TO ('2025-09-29 21:00:00+00');

alter table minute_candles_2025_09_29
    owner to postgres;

grant select on minute_candles_2025_09_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_29 to admin;

create table minute_candles_2025_09_30
    partition of minute_candles
        FOR VALUES FROM ('2025-09-29 21:00:00+00') TO ('2025-09-30 21:00:00+00');

alter table minute_candles_2025_09_30
    owner to postgres;

grant select on minute_candles_2025_09_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_09_30 to admin;

create table minute_candles_2025_10_01
    partition of minute_candles
        FOR VALUES FROM ('2025-09-30 21:00:00+00') TO ('2025-10-01 21:00:00+00');

alter table minute_candles_2025_10_01
    owner to postgres;

grant select on minute_candles_2025_10_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_01 to admin;

create table minute_candles_2025_10_02
    partition of minute_candles
        FOR VALUES FROM ('2025-10-01 21:00:00+00') TO ('2025-10-02 21:00:00+00');

alter table minute_candles_2025_10_02
    owner to postgres;

grant select on minute_candles_2025_10_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_02 to admin;

create table minute_candles_2025_10_03
    partition of minute_candles
        FOR VALUES FROM ('2025-10-02 21:00:00+00') TO ('2025-10-03 21:00:00+00');

alter table minute_candles_2025_10_03
    owner to postgres;

grant select on minute_candles_2025_10_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_03 to admin;

create table minute_candles_2025_10_04
    partition of minute_candles
        FOR VALUES FROM ('2025-10-03 21:00:00+00') TO ('2025-10-04 21:00:00+00');

alter table minute_candles_2025_10_04
    owner to postgres;

grant select on minute_candles_2025_10_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_04 to admin;

create table minute_candles_2025_10_05
    partition of minute_candles
        FOR VALUES FROM ('2025-10-04 21:00:00+00') TO ('2025-10-05 21:00:00+00');

alter table minute_candles_2025_10_05
    owner to postgres;

grant select on minute_candles_2025_10_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_05 to admin;

create table minute_candles_2025_10_06
    partition of minute_candles
        FOR VALUES FROM ('2025-10-05 21:00:00+00') TO ('2025-10-06 21:00:00+00');

alter table minute_candles_2025_10_06
    owner to postgres;

grant select on minute_candles_2025_10_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_06 to admin;

create table minute_candles_2025_10_07
    partition of minute_candles
        FOR VALUES FROM ('2025-10-06 21:00:00+00') TO ('2025-10-07 21:00:00+00');

alter table minute_candles_2025_10_07
    owner to postgres;

grant select on minute_candles_2025_10_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_07 to admin;

create table minute_candles_2025_10_08
    partition of minute_candles
        FOR VALUES FROM ('2025-10-07 21:00:00+00') TO ('2025-10-08 21:00:00+00');

alter table minute_candles_2025_10_08
    owner to postgres;

grant select on minute_candles_2025_10_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_08 to admin;

create table minute_candles_2025_10_09
    partition of minute_candles
        FOR VALUES FROM ('2025-10-08 21:00:00+00') TO ('2025-10-09 21:00:00+00');

alter table minute_candles_2025_10_09
    owner to postgres;

grant select on minute_candles_2025_10_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_09 to admin;

create table minute_candles_2025_10_10
    partition of minute_candles
        FOR VALUES FROM ('2025-10-09 21:00:00+00') TO ('2025-10-10 21:00:00+00');

alter table minute_candles_2025_10_10
    owner to postgres;

grant select on minute_candles_2025_10_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_10 to admin;

create table minute_candles_2025_10_11
    partition of minute_candles
        FOR VALUES FROM ('2025-10-10 21:00:00+00') TO ('2025-10-11 21:00:00+00');

alter table minute_candles_2025_10_11
    owner to postgres;

grant select on minute_candles_2025_10_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_11 to admin;

create table minute_candles_2025_10_12
    partition of minute_candles
        FOR VALUES FROM ('2025-10-11 21:00:00+00') TO ('2025-10-12 21:00:00+00');

alter table minute_candles_2025_10_12
    owner to postgres;

grant select on minute_candles_2025_10_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_12 to admin;

create table minute_candles_2025_10_13
    partition of minute_candles
        FOR VALUES FROM ('2025-10-12 21:00:00+00') TO ('2025-10-13 21:00:00+00');

alter table minute_candles_2025_10_13
    owner to postgres;

grant select on minute_candles_2025_10_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_13 to admin;

create table minute_candles_2025_10_14
    partition of minute_candles
        FOR VALUES FROM ('2025-10-13 21:00:00+00') TO ('2025-10-14 21:00:00+00');

alter table minute_candles_2025_10_14
    owner to postgres;

grant select on minute_candles_2025_10_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_14 to admin;

create table minute_candles_2025_10_15
    partition of minute_candles
        FOR VALUES FROM ('2025-10-14 21:00:00+00') TO ('2025-10-15 21:00:00+00');

alter table minute_candles_2025_10_15
    owner to postgres;

grant select on minute_candles_2025_10_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_15 to admin;

create table minute_candles_2025_10_16
    partition of minute_candles
        FOR VALUES FROM ('2025-10-15 21:00:00+00') TO ('2025-10-16 21:00:00+00');

alter table minute_candles_2025_10_16
    owner to postgres;

grant select on minute_candles_2025_10_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_16 to admin;

create table minute_candles_2025_10_17
    partition of minute_candles
        FOR VALUES FROM ('2025-10-16 21:00:00+00') TO ('2025-10-17 21:00:00+00');

alter table minute_candles_2025_10_17
    owner to postgres;

grant select on minute_candles_2025_10_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_17 to admin;

create table minute_candles_2025_10_18
    partition of minute_candles
        FOR VALUES FROM ('2025-10-17 21:00:00+00') TO ('2025-10-18 21:00:00+00');

alter table minute_candles_2025_10_18
    owner to postgres;

grant select on minute_candles_2025_10_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_18 to admin;

create table minute_candles_2025_10_19
    partition of minute_candles
        FOR VALUES FROM ('2025-10-18 21:00:00+00') TO ('2025-10-19 21:00:00+00');

alter table minute_candles_2025_10_19
    owner to postgres;

grant select on minute_candles_2025_10_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_19 to admin;

create table minute_candles_2025_10_20
    partition of minute_candles
        FOR VALUES FROM ('2025-10-19 21:00:00+00') TO ('2025-10-20 21:00:00+00');

alter table minute_candles_2025_10_20
    owner to postgres;

grant select on minute_candles_2025_10_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_20 to admin;

create table minute_candles_2025_10_21
    partition of minute_candles
        FOR VALUES FROM ('2025-10-20 21:00:00+00') TO ('2025-10-21 21:00:00+00');

alter table minute_candles_2025_10_21
    owner to postgres;

grant select on minute_candles_2025_10_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_21 to admin;

create table minute_candles_2025_10_22
    partition of minute_candles
        FOR VALUES FROM ('2025-10-21 21:00:00+00') TO ('2025-10-22 21:00:00+00');

alter table minute_candles_2025_10_22
    owner to postgres;

grant select on minute_candles_2025_10_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_22 to admin;

create table minute_candles_2025_10_23
    partition of minute_candles
        FOR VALUES FROM ('2025-10-22 21:00:00+00') TO ('2025-10-23 21:00:00+00');

alter table minute_candles_2025_10_23
    owner to postgres;

grant select on minute_candles_2025_10_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_23 to admin;

create table minute_candles_2025_10_24
    partition of minute_candles
        FOR VALUES FROM ('2025-10-23 21:00:00+00') TO ('2025-10-24 21:00:00+00');

alter table minute_candles_2025_10_24
    owner to postgres;

grant select on minute_candles_2025_10_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_24 to admin;

create table minute_candles_2025_10_25
    partition of minute_candles
        FOR VALUES FROM ('2025-10-24 21:00:00+00') TO ('2025-10-25 21:00:00+00');

alter table minute_candles_2025_10_25
    owner to postgres;

grant select on minute_candles_2025_10_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_25 to admin;

create table minute_candles_2025_10_26
    partition of minute_candles
        FOR VALUES FROM ('2025-10-25 21:00:00+00') TO ('2025-10-26 21:00:00+00');

alter table minute_candles_2025_10_26
    owner to postgres;

grant select on minute_candles_2025_10_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_26 to admin;

create table minute_candles_2025_10_27
    partition of minute_candles
        FOR VALUES FROM ('2025-10-26 21:00:00+00') TO ('2025-10-27 21:00:00+00');

alter table minute_candles_2025_10_27
    owner to postgres;

grant select on minute_candles_2025_10_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_27 to admin;

create table minute_candles_2025_10_28
    partition of minute_candles
        FOR VALUES FROM ('2025-10-27 21:00:00+00') TO ('2025-10-28 21:00:00+00');

alter table minute_candles_2025_10_28
    owner to postgres;

grant select on minute_candles_2025_10_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_28 to admin;

create table minute_candles_2025_10_29
    partition of minute_candles
        FOR VALUES FROM ('2025-10-28 21:00:00+00') TO ('2025-10-29 21:00:00+00');

alter table minute_candles_2025_10_29
    owner to postgres;

grant select on minute_candles_2025_10_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_29 to admin;

create table minute_candles_2025_10_30
    partition of minute_candles
        FOR VALUES FROM ('2025-10-29 21:00:00+00') TO ('2025-10-30 21:00:00+00');

alter table minute_candles_2025_10_30
    owner to postgres;

grant select on minute_candles_2025_10_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_30 to admin;

create table minute_candles_2025_10_31
    partition of minute_candles
        FOR VALUES FROM ('2025-10-30 21:00:00+00') TO ('2025-10-31 21:00:00+00');

alter table minute_candles_2025_10_31
    owner to postgres;

grant select on minute_candles_2025_10_31 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_10_31 to admin;

create table minute_candles_2025_11_01
    partition of minute_candles
        FOR VALUES FROM ('2025-10-31 21:00:00+00') TO ('2025-11-01 21:00:00+00');

alter table minute_candles_2025_11_01
    owner to postgres;

grant select on minute_candles_2025_11_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_01 to admin;

create table minute_candles_2025_11_02
    partition of minute_candles
        FOR VALUES FROM ('2025-11-01 21:00:00+00') TO ('2025-11-02 21:00:00+00');

alter table minute_candles_2025_11_02
    owner to postgres;

grant select on minute_candles_2025_11_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_02 to admin;

create table minute_candles_2025_11_03
    partition of minute_candles
        FOR VALUES FROM ('2025-11-02 21:00:00+00') TO ('2025-11-03 21:00:00+00');

alter table minute_candles_2025_11_03
    owner to postgres;

grant select on minute_candles_2025_11_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_03 to admin;

create table minute_candles_2025_11_04
    partition of minute_candles
        FOR VALUES FROM ('2025-11-03 21:00:00+00') TO ('2025-11-04 21:00:00+00');

alter table minute_candles_2025_11_04
    owner to postgres;

grant select on minute_candles_2025_11_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_04 to admin;

create table minute_candles_2025_11_05
    partition of minute_candles
        FOR VALUES FROM ('2025-11-04 21:00:00+00') TO ('2025-11-05 21:00:00+00');

alter table minute_candles_2025_11_05
    owner to postgres;

grant select on minute_candles_2025_11_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_05 to admin;

create table minute_candles_2025_11_06
    partition of minute_candles
        FOR VALUES FROM ('2025-11-05 21:00:00+00') TO ('2025-11-06 21:00:00+00');

alter table minute_candles_2025_11_06
    owner to postgres;

grant select on minute_candles_2025_11_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_06 to admin;

create table minute_candles_2025_11_07
    partition of minute_candles
        FOR VALUES FROM ('2025-11-06 21:00:00+00') TO ('2025-11-07 21:00:00+00');

alter table minute_candles_2025_11_07
    owner to postgres;

grant select on minute_candles_2025_11_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_07 to admin;

create table minute_candles_2025_11_08
    partition of minute_candles
        FOR VALUES FROM ('2025-11-07 21:00:00+00') TO ('2025-11-08 21:00:00+00');

alter table minute_candles_2025_11_08
    owner to postgres;

grant select on minute_candles_2025_11_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_08 to admin;

create table minute_candles_2025_11_09
    partition of minute_candles
        FOR VALUES FROM ('2025-11-08 21:00:00+00') TO ('2025-11-09 21:00:00+00');

alter table minute_candles_2025_11_09
    owner to postgres;

grant select on minute_candles_2025_11_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_09 to admin;

create table minute_candles_2025_11_10
    partition of minute_candles
        FOR VALUES FROM ('2025-11-09 21:00:00+00') TO ('2025-11-10 21:00:00+00');

alter table minute_candles_2025_11_10
    owner to postgres;

grant select on minute_candles_2025_11_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_10 to admin;

create table minute_candles_2025_11_11
    partition of minute_candles
        FOR VALUES FROM ('2025-11-10 21:00:00+00') TO ('2025-11-11 21:00:00+00');

alter table minute_candles_2025_11_11
    owner to postgres;

grant select on minute_candles_2025_11_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_11 to admin;

create table minute_candles_2025_11_12
    partition of minute_candles
        FOR VALUES FROM ('2025-11-11 21:00:00+00') TO ('2025-11-12 21:00:00+00');

alter table minute_candles_2025_11_12
    owner to postgres;

grant select on minute_candles_2025_11_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_12 to admin;

create table minute_candles_2025_11_13
    partition of minute_candles
        FOR VALUES FROM ('2025-11-12 21:00:00+00') TO ('2025-11-13 21:00:00+00');

alter table minute_candles_2025_11_13
    owner to postgres;

grant select on minute_candles_2025_11_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_13 to admin;

create table minute_candles_2025_11_14
    partition of minute_candles
        FOR VALUES FROM ('2025-11-13 21:00:00+00') TO ('2025-11-14 21:00:00+00');

alter table minute_candles_2025_11_14
    owner to postgres;

grant select on minute_candles_2025_11_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_14 to admin;

create table minute_candles_2025_11_15
    partition of minute_candles
        FOR VALUES FROM ('2025-11-14 21:00:00+00') TO ('2025-11-15 21:00:00+00');

alter table minute_candles_2025_11_15
    owner to postgres;

grant select on minute_candles_2025_11_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_15 to admin;

create table minute_candles_2025_11_16
    partition of minute_candles
        FOR VALUES FROM ('2025-11-15 21:00:00+00') TO ('2025-11-16 21:00:00+00');

alter table minute_candles_2025_11_16
    owner to postgres;

grant select on minute_candles_2025_11_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_16 to admin;

create table minute_candles_2025_11_17
    partition of minute_candles
        FOR VALUES FROM ('2025-11-16 21:00:00+00') TO ('2025-11-17 21:00:00+00');

alter table minute_candles_2025_11_17
    owner to postgres;

grant select on minute_candles_2025_11_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_17 to admin;

create table minute_candles_2025_11_18
    partition of minute_candles
        FOR VALUES FROM ('2025-11-17 21:00:00+00') TO ('2025-11-18 21:00:00+00');

alter table minute_candles_2025_11_18
    owner to postgres;

grant select on minute_candles_2025_11_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_18 to admin;

create table minute_candles_2025_11_19
    partition of minute_candles
        FOR VALUES FROM ('2025-11-18 21:00:00+00') TO ('2025-11-19 21:00:00+00');

alter table minute_candles_2025_11_19
    owner to postgres;

grant select on minute_candles_2025_11_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_19 to admin;

create table minute_candles_2025_11_20
    partition of minute_candles
        FOR VALUES FROM ('2025-11-19 21:00:00+00') TO ('2025-11-20 21:00:00+00');

alter table minute_candles_2025_11_20
    owner to postgres;

grant select on minute_candles_2025_11_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_20 to admin;

create table minute_candles_2025_11_21
    partition of minute_candles
        FOR VALUES FROM ('2025-11-20 21:00:00+00') TO ('2025-11-21 21:00:00+00');

alter table minute_candles_2025_11_21
    owner to postgres;

grant select on minute_candles_2025_11_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_21 to admin;

create table minute_candles_2025_11_22
    partition of minute_candles
        FOR VALUES FROM ('2025-11-21 21:00:00+00') TO ('2025-11-22 21:00:00+00');

alter table minute_candles_2025_11_22
    owner to postgres;

grant select on minute_candles_2025_11_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_22 to admin;

create table minute_candles_2025_11_23
    partition of minute_candles
        FOR VALUES FROM ('2025-11-22 21:00:00+00') TO ('2025-11-23 21:00:00+00');

alter table minute_candles_2025_11_23
    owner to postgres;

grant select on minute_candles_2025_11_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_23 to admin;

create table minute_candles_2025_11_24
    partition of minute_candles
        FOR VALUES FROM ('2025-11-23 21:00:00+00') TO ('2025-11-24 21:00:00+00');

alter table minute_candles_2025_11_24
    owner to postgres;

grant select on minute_candles_2025_11_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_24 to admin;

create table minute_candles_2025_11_25
    partition of minute_candles
        FOR VALUES FROM ('2025-11-24 21:00:00+00') TO ('2025-11-25 21:00:00+00');

alter table minute_candles_2025_11_25
    owner to postgres;

grant select on minute_candles_2025_11_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_25 to admin;

create table minute_candles_2025_11_26
    partition of minute_candles
        FOR VALUES FROM ('2025-11-25 21:00:00+00') TO ('2025-11-26 21:00:00+00');

alter table minute_candles_2025_11_26
    owner to postgres;

grant select on minute_candles_2025_11_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_26 to admin;

create table minute_candles_2025_11_27
    partition of minute_candles
        FOR VALUES FROM ('2025-11-26 21:00:00+00') TO ('2025-11-27 21:00:00+00');

alter table minute_candles_2025_11_27
    owner to postgres;

grant select on minute_candles_2025_11_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_27 to admin;

create table minute_candles_2025_11_28
    partition of minute_candles
        FOR VALUES FROM ('2025-11-27 21:00:00+00') TO ('2025-11-28 21:00:00+00');

alter table minute_candles_2025_11_28
    owner to postgres;

grant select on minute_candles_2025_11_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_28 to admin;

create table minute_candles_2025_11_29
    partition of minute_candles
        FOR VALUES FROM ('2025-11-28 21:00:00+00') TO ('2025-11-29 21:00:00+00');

alter table minute_candles_2025_11_29
    owner to postgres;

grant select on minute_candles_2025_11_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_29 to admin;

create table minute_candles_2025_11_30
    partition of minute_candles
        FOR VALUES FROM ('2025-11-29 21:00:00+00') TO ('2025-11-30 21:00:00+00');

alter table minute_candles_2025_11_30
    owner to postgres;

grant select on minute_candles_2025_11_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_11_30 to admin;

create table minute_candles_2025_12_01
    partition of minute_candles
        FOR VALUES FROM ('2025-11-30 21:00:00+00') TO ('2025-12-01 21:00:00+00');

alter table minute_candles_2025_12_01
    owner to postgres;

grant select on minute_candles_2025_12_01 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_01 to admin;

create table minute_candles_2025_12_02
    partition of minute_candles
        FOR VALUES FROM ('2025-12-01 21:00:00+00') TO ('2025-12-02 21:00:00+00');

alter table minute_candles_2025_12_02
    owner to postgres;

grant select on minute_candles_2025_12_02 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_02 to admin;

create table minute_candles_2025_12_03
    partition of minute_candles
        FOR VALUES FROM ('2025-12-02 21:00:00+00') TO ('2025-12-03 21:00:00+00');

alter table minute_candles_2025_12_03
    owner to postgres;

grant select on minute_candles_2025_12_03 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_03 to admin;

create table minute_candles_2025_12_04
    partition of minute_candles
        FOR VALUES FROM ('2025-12-03 21:00:00+00') TO ('2025-12-04 21:00:00+00');

alter table minute_candles_2025_12_04
    owner to postgres;

grant select on minute_candles_2025_12_04 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_04 to admin;

create table minute_candles_2025_12_05
    partition of minute_candles
        FOR VALUES FROM ('2025-12-04 21:00:00+00') TO ('2025-12-05 21:00:00+00');

alter table minute_candles_2025_12_05
    owner to postgres;

grant select on minute_candles_2025_12_05 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_05 to admin;

create table minute_candles_2025_12_06
    partition of minute_candles
        FOR VALUES FROM ('2025-12-05 21:00:00+00') TO ('2025-12-06 21:00:00+00');

alter table minute_candles_2025_12_06
    owner to postgres;

grant select on minute_candles_2025_12_06 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_06 to admin;

create table minute_candles_2025_12_07
    partition of minute_candles
        FOR VALUES FROM ('2025-12-06 21:00:00+00') TO ('2025-12-07 21:00:00+00');

alter table minute_candles_2025_12_07
    owner to postgres;

grant select on minute_candles_2025_12_07 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_07 to admin;

create table minute_candles_2025_12_08
    partition of minute_candles
        FOR VALUES FROM ('2025-12-07 21:00:00+00') TO ('2025-12-08 21:00:00+00');

alter table minute_candles_2025_12_08
    owner to postgres;

grant select on minute_candles_2025_12_08 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_08 to admin;

create table minute_candles_2025_12_09
    partition of minute_candles
        FOR VALUES FROM ('2025-12-08 21:00:00+00') TO ('2025-12-09 21:00:00+00');

alter table minute_candles_2025_12_09
    owner to postgres;

grant select on minute_candles_2025_12_09 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_09 to admin;

create table minute_candles_2025_12_10
    partition of minute_candles
        FOR VALUES FROM ('2025-12-09 21:00:00+00') TO ('2025-12-10 21:00:00+00');

alter table minute_candles_2025_12_10
    owner to postgres;

grant select on minute_candles_2025_12_10 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_10 to admin;

create table minute_candles_2025_12_11
    partition of minute_candles
        FOR VALUES FROM ('2025-12-10 21:00:00+00') TO ('2025-12-11 21:00:00+00');

alter table minute_candles_2025_12_11
    owner to postgres;

grant select on minute_candles_2025_12_11 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_11 to admin;

create table minute_candles_2025_12_12
    partition of minute_candles
        FOR VALUES FROM ('2025-12-11 21:00:00+00') TO ('2025-12-12 21:00:00+00');

alter table minute_candles_2025_12_12
    owner to postgres;

grant select on minute_candles_2025_12_12 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_12 to admin;

create table minute_candles_2025_12_13
    partition of minute_candles
        FOR VALUES FROM ('2025-12-12 21:00:00+00') TO ('2025-12-13 21:00:00+00');

alter table minute_candles_2025_12_13
    owner to postgres;

grant select on minute_candles_2025_12_13 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_13 to admin;

create table minute_candles_2025_12_14
    partition of minute_candles
        FOR VALUES FROM ('2025-12-13 21:00:00+00') TO ('2025-12-14 21:00:00+00');

alter table minute_candles_2025_12_14
    owner to postgres;

grant select on minute_candles_2025_12_14 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_14 to admin;

create table minute_candles_2025_12_15
    partition of minute_candles
        FOR VALUES FROM ('2025-12-14 21:00:00+00') TO ('2025-12-15 21:00:00+00');

alter table minute_candles_2025_12_15
    owner to postgres;

grant select on minute_candles_2025_12_15 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_15 to admin;

create table minute_candles_2025_12_16
    partition of minute_candles
        FOR VALUES FROM ('2025-12-15 21:00:00+00') TO ('2025-12-16 21:00:00+00');

alter table minute_candles_2025_12_16
    owner to postgres;

grant select on minute_candles_2025_12_16 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_16 to admin;

create table minute_candles_2025_12_17
    partition of minute_candles
        FOR VALUES FROM ('2025-12-16 21:00:00+00') TO ('2025-12-17 21:00:00+00');

alter table minute_candles_2025_12_17
    owner to postgres;

grant select on minute_candles_2025_12_17 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_17 to admin;

create table minute_candles_2025_12_18
    partition of minute_candles
        FOR VALUES FROM ('2025-12-17 21:00:00+00') TO ('2025-12-18 21:00:00+00');

alter table minute_candles_2025_12_18
    owner to postgres;

grant select on minute_candles_2025_12_18 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_18 to admin;

create table minute_candles_2025_12_19
    partition of minute_candles
        FOR VALUES FROM ('2025-12-18 21:00:00+00') TO ('2025-12-19 21:00:00+00');

alter table minute_candles_2025_12_19
    owner to postgres;

grant select on minute_candles_2025_12_19 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_19 to admin;

create table minute_candles_2025_12_20
    partition of minute_candles
        FOR VALUES FROM ('2025-12-19 21:00:00+00') TO ('2025-12-20 21:00:00+00');

alter table minute_candles_2025_12_20
    owner to postgres;

grant select on minute_candles_2025_12_20 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_20 to admin;

create table minute_candles_2025_12_21
    partition of minute_candles
        FOR VALUES FROM ('2025-12-20 21:00:00+00') TO ('2025-12-21 21:00:00+00');

alter table minute_candles_2025_12_21
    owner to postgres;

grant select on minute_candles_2025_12_21 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_21 to admin;

create table minute_candles_2025_12_22
    partition of minute_candles
        FOR VALUES FROM ('2025-12-21 21:00:00+00') TO ('2025-12-22 21:00:00+00');

alter table minute_candles_2025_12_22
    owner to postgres;

grant select on minute_candles_2025_12_22 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_22 to admin;

create table minute_candles_2025_12_23
    partition of minute_candles
        FOR VALUES FROM ('2025-12-22 21:00:00+00') TO ('2025-12-23 21:00:00+00');

alter table minute_candles_2025_12_23
    owner to postgres;

grant select on minute_candles_2025_12_23 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_23 to admin;

create table minute_candles_2025_12_24
    partition of minute_candles
        FOR VALUES FROM ('2025-12-23 21:00:00+00') TO ('2025-12-24 21:00:00+00');

alter table minute_candles_2025_12_24
    owner to postgres;

grant select on minute_candles_2025_12_24 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_24 to admin;

create table minute_candles_2025_12_25
    partition of minute_candles
        FOR VALUES FROM ('2025-12-24 21:00:00+00') TO ('2025-12-25 21:00:00+00');

alter table minute_candles_2025_12_25
    owner to postgres;

grant select on minute_candles_2025_12_25 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_25 to admin;

create table minute_candles_2025_12_26
    partition of minute_candles
        FOR VALUES FROM ('2025-12-25 21:00:00+00') TO ('2025-12-26 21:00:00+00');

alter table minute_candles_2025_12_26
    owner to postgres;

grant select on minute_candles_2025_12_26 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_26 to admin;

create table minute_candles_2025_12_27
    partition of minute_candles
        FOR VALUES FROM ('2025-12-26 21:00:00+00') TO ('2025-12-27 21:00:00+00');

alter table minute_candles_2025_12_27
    owner to postgres;

grant select on minute_candles_2025_12_27 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_27 to admin;

create table minute_candles_2025_12_28
    partition of minute_candles
        FOR VALUES FROM ('2025-12-27 21:00:00+00') TO ('2025-12-28 21:00:00+00');

alter table minute_candles_2025_12_28
    owner to postgres;

grant select on minute_candles_2025_12_28 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_28 to admin;

create table minute_candles_2025_12_29
    partition of minute_candles
        FOR VALUES FROM ('2025-12-28 21:00:00+00') TO ('2025-12-29 21:00:00+00');

alter table minute_candles_2025_12_29
    owner to postgres;

grant select on minute_candles_2025_12_29 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_29 to admin;

create table minute_candles_2025_12_30
    partition of minute_candles
        FOR VALUES FROM ('2025-12-29 21:00:00+00') TO ('2025-12-30 21:00:00+00');

alter table minute_candles_2025_12_30
    owner to postgres;

grant select on minute_candles_2025_12_30 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_30 to admin;

create table minute_candles_2025_12_31
    partition of minute_candles
        FOR VALUES FROM ('2025-12-30 21:00:00+00') TO ('2025-12-31 21:00:00+00');

alter table minute_candles_2025_12_31
    owner to postgres;

grant select on minute_candles_2025_12_31 to tester;

grant delete, insert, references, select, trigger, truncate, update on minute_candles_2025_12_31 to admin;

--Таблица хранения дневных свечей
create table invest_candles.daily_candles
(
    figi                 varchar(255)                              not null,
    time                 timestamp(6) with time zone               not null,
    close                numeric(18, 9)                            not null,
    created_at           timestamp(6) with time zone default now() not null,
    high                 numeric(18, 9)                            not null,
    is_complete          boolean                                   not null,
    low                  numeric(18, 9)                            not null,
    open                 numeric(18, 9)                            not null,
    updated_at           timestamp(6) with time zone default now() not null,
    volume               bigint                                    not null,
    price_change         numeric(18, 9),
    price_change_percent numeric(18, 9),
    candle_type          varchar(20),
    body_size            numeric(18, 9),
    upper_shadow         numeric(18, 9),
    lower_shadow         numeric(18, 9),
    high_low_range       numeric(18, 9),
    average_price        numeric(18, 9),
    primary key (figi, time)
)
    partition by RANGE ("time");

comment on table invest_candles.daily_candles is 'Таблица дневных свечей финансовых инструментов с месячным партиционированием';

comment on column invest_candles.daily_candles.figi is 'Уникальный идентификатор инструмента (Financial Instrument Global Identifier)';

comment on column invest_candles.daily_candles.time is 'Время начала дневной свечи в московской таймзоне';

comment on column invest_candles.daily_candles.close is 'Цена закрытия за день с точностью до 9 знаков после запятой';

comment on column invest_candles.daily_candles.created_at is 'Время создания записи в московской таймзоне';

comment on column invest_candles.daily_candles.high is 'Максимальная цена за день с точностью до 9 знаков после запятой';

comment on column invest_candles.daily_candles.is_complete is 'Флаг завершенности свечи (true - свеча завершена, false - формируется)';

comment on column invest_candles.daily_candles.low is 'Минимальная цена за день с точностью до 9 знаков после запятой';

comment on column invest_candles.daily_candles.open is 'Цена открытия за день с точностью до 9 знаков после запятой';

comment on column invest_candles.daily_candles.updated_at is 'Время последнего обновления записи в московской таймзоне';

comment on column invest_candles.daily_candles.volume is 'Объем торгов за день (количество лотов)';

comment on column invest_candles.daily_candles.price_change is 'Изменение цены за день (close - open) с точностью до 9 знаков после запятой';

comment on column invest_candles.daily_candles.price_change_percent is 'Процентное изменение цены за день с точностью до 4 знаков после запятой';

comment on column invest_candles.daily_candles.candle_type is 'Тип свечи: BULLISH (бычья), BEARISH (медвежья), DOJI (доджи)';

comment on column invest_candles.daily_candles.body_size is 'Размер тела свечи (абсолютное значение изменения цены) с точностью до 9 знаков после запятой';

comment on column invest_candles.daily_candles.upper_shadow is 'Верхняя тень свечи (high - max(open, close)) с точностью до 9 знаков после запятой';

comment on column invest_candles.daily_candles.lower_shadow is 'Нижняя тень свечи (min(open, close) - low) с точностью до 9 знаков после запятой';

comment on column invest_candles.daily_candles.high_low_range is 'Диапазон цен за день (high - low) с точностью до 9 знаков после запятой';

comment on column invest_candles.daily_candles.average_price is 'Средняя цена за день ((high + low + close) / 3) с точностью до 2 знаков после запятой';

alter table invest_candles.daily_candles
    owner to postgres;

create index idx_daily_candles_time
    on invest_candles.daily_candles (time);

create index idx_daily_candles_figi_time
    on invest_candles.daily_candles (figi, time);

-- Создание синонима в схеме invest для удобства использования
create or replace view invest.daily_candles as
select 
    figi,
    time,
    close,
    created_at,
    high,
    is_complete,
    low,
    open,
    updated_at,
    volume,
    price_change,
    price_change_percent,
    candle_type,
    body_size,
    upper_shadow,
    lower_shadow,
    high_low_range,
    average_price
from invest_candles.daily_candles;

comment on view invest.daily_candles is 'Синоним для таблицы daily_candles из схемы invest_candles';

-- Права доступа на представление
alter view invest.daily_candles owner to postgres;

create table daily_candles_2024_06
    partition of daily_candles
        FOR VALUES FROM ('2024-05-31 21:00:00+00') TO ('2024-06-30 21:00:00+00');

alter table daily_candles_2024_06
    owner to postgres;

create table daily_candles_2024_07
    partition of daily_candles
        FOR VALUES FROM ('2024-06-30 21:00:00+00') TO ('2024-07-31 21:00:00+00');

alter table daily_candles_2024_07
    owner to postgres;

create table daily_candles_2024_08
    partition of daily_candles
        FOR VALUES FROM ('2024-07-31 21:00:00+00') TO ('2024-08-31 21:00:00+00');

alter table daily_candles_2024_08
    owner to postgres;

create table daily_candles_2024_09
    partition of daily_candles
        FOR VALUES FROM ('2024-08-31 21:00:00+00') TO ('2024-09-30 21:00:00+00');

alter table daily_candles_2024_09
    owner to postgres;

create table daily_candles_2024_10
    partition of daily_candles
        FOR VALUES FROM ('2024-09-30 21:00:00+00') TO ('2024-10-31 21:00:00+00');

alter table daily_candles_2024_10
    owner to postgres;

create table daily_candles_2024_11
    partition of daily_candles
        FOR VALUES FROM ('2024-10-31 21:00:00+00') TO ('2024-11-30 21:00:00+00');

alter table daily_candles_2024_11
    owner to postgres;

create table daily_candles_2024_12
    partition of daily_candles
        FOR VALUES FROM ('2024-11-30 21:00:00+00') TO ('2024-12-31 21:00:00+00');

alter table daily_candles_2024_12
    owner to postgres;

create table daily_candles_2025_01
    partition of daily_candles
        FOR VALUES FROM ('2024-12-31 21:00:00+00') TO ('2025-01-31 21:00:00+00');

alter table daily_candles_2025_01
    owner to postgres;

create table daily_candles_2025_02
    partition of daily_candles
        FOR VALUES FROM ('2025-01-31 21:00:00+00') TO ('2025-02-28 21:00:00+00');

alter table daily_candles_2025_02
    owner to postgres;

create table daily_candles_2025_03
    partition of daily_candles
        FOR VALUES FROM ('2025-02-28 21:00:00+00') TO ('2025-03-31 21:00:00+00');

alter table daily_candles_2025_03
    owner to postgres;

create table daily_candles_2025_04
    partition of daily_candles
        FOR VALUES FROM ('2025-03-31 21:00:00+00') TO ('2025-04-30 21:00:00+00');

alter table daily_candles_2025_04
    owner to postgres;

create table daily_candles_2025_05
    partition of daily_candles
        FOR VALUES FROM ('2025-04-30 21:00:00+00') TO ('2025-05-31 21:00:00+00');

alter table daily_candles_2025_05
    owner to postgres;

create table daily_candles_2025_06
    partition of daily_candles
        FOR VALUES FROM ('2025-05-31 21:00:00+00') TO ('2025-06-30 21:00:00+00');

alter table daily_candles_2025_06
    owner to postgres;

create table daily_candles_2025_07
    partition of daily_candles
        FOR VALUES FROM ('2025-06-30 21:00:00+00') TO ('2025-07-31 21:00:00+00');

alter table daily_candles_2025_07
    owner to postgres;


create table daily_candles_2025_08
    partition of daily_candles
        FOR VALUES FROM ('2025-07-31 21:00:00+00') TO ('2025-08-31 21:00:00+00');

alter table daily_candles_2025_08
    owner to postgres;


create table daily_candles_2025_09
    partition of daily_candles
        FOR VALUES FROM ('2025-08-31 21:00:00+00') TO ('2025-09-30 21:00:00+00');

alter table daily_candles_2025_09
    owner to postgres;


create table daily_candles_2025_10
    partition of daily_candles
        FOR VALUES FROM ('2025-09-30 21:00:00+00') TO ('2025-10-31 21:00:00+00');

alter table daily_candles_2025_10
    owner to postgres;

create table daily_candles_2025_11
    partition of daily_candles
        FOR VALUES FROM ('2025-10-31 21:00:00+00') TO ('2025-11-30 21:00:00+00');

alter table daily_candles_2025_11
    owner to postgres;

create table daily_candles_2025_12
    partition of daily_candles
        FOR VALUES FROM ('2025-11-30 21:00:00+00') TO ('2025-12-31 21:00:00+00');

alter table daily_candles_2025_12
    owner to postgres;


-- Таблица для хранения специальных торговых часов инструментов
create table invest_candles.special_trading_hours
(
    id                    bigserial                                 primary key,
    figi                  varchar(255)                              not null,
    instrument_type       varchar(20)                               not null,
    day_type              varchar(20)                               not null,
    start_hour            integer                                   not null,
    start_minute          integer                                   not null,
    end_hour              integer                                   not null,
    end_minute            integer                                   not null,
    description           text,
    is_active             boolean                  default true     not null,
    created_at            timestamp with time zone default now()   not null,
    updated_at            timestamp with time zone default now()   not null,
    created_by            varchar(255),
    constraint chk_instrument_type check (instrument_type in ('shares', 'futures', 'indicatives')),
    constraint chk_day_type check (day_type in ('weekday', 'weekend', 'all')),
    constraint chk_start_hour check (start_hour >= 0 and start_hour <= 23),
    constraint chk_start_minute check (start_minute >= 0 and start_minute <= 59),
    constraint chk_end_hour check (end_hour >= 0 and end_hour <= 23),
    constraint chk_end_minute check (end_minute >= 0 and end_minute <= 59),
    constraint chk_time_order check (
        (start_hour < end_hour) or 
        (start_hour = end_hour and start_minute <= end_minute)
    )
);

-- Устанавливаем владельца
alter table invest_candles.special_trading_hours owner to postgres;

-- Таблица для хранения проблем качества данных по свечам
create table invest_candles.data_quality_issues
(
    id                    bigserial                                 primary key,
    task_id               varchar(255)                              not null,
    check_name            varchar(255)                              not null,
    entity_type           varchar(50),
    entity_id             varchar(255),
    trade_date            date,
    metric                varchar(255),
    status                varchar(20)                               not null,
    message               text                                      not null,
    expected_numeric      numeric(18, 9),
    actual_numeric        numeric(18, 9),
    diff_numeric          numeric(18, 9),
    details               jsonb,
    created_at            timestamp with time zone default now()   not null,
    constraint chk_status check (status in ('ERROR', 'WARNING', 'INFO'))
);

comment on table invest_candles.data_quality_issues is 'Таблица для хранения проблем качества данных по свечам';

comment on column invest_candles.data_quality_issues.id is 'Уникальный идентификатор записи';
comment on column invest_candles.data_quality_issues.task_id is 'ID задачи, которая выявила проблему';
comment on column invest_candles.data_quality_issues.check_name is 'Название проверки';
comment on column invest_candles.data_quality_issues.entity_type is 'Тип сущности (shares, futures, etc.)';
comment on column invest_candles.data_quality_issues.entity_id is 'ID сущности (обычно FIGI)';
comment on column invest_candles.data_quality_issues.trade_date is 'Дата торгов, к которой относится проблема';
comment on column invest_candles.data_quality_issues.metric is 'Название метрики';
comment on column invest_candles.data_quality_issues.status is 'Статус проблемы: ERROR, WARNING, INFO';
comment on column invest_candles.data_quality_issues.message is 'Описание проблемы';
comment on column invest_candles.data_quality_issues.expected_numeric is 'Ожидаемое числовое значение';
comment on column invest_candles.data_quality_issues.actual_numeric is 'Фактическое числовое значение';
comment on column invest_candles.data_quality_issues.diff_numeric is 'Разность между ожидаемым и фактическим значением';
comment on column invest_candles.data_quality_issues.details is 'Дополнительные детали в формате JSON';
comment on column invest_candles.data_quality_issues.created_at is 'Дата и время создания записи';

-- Устанавливаем владельца
alter table invest_candles.data_quality_issues owner to postgres;

-- Создание синонима в схеме invest для удобства использования
create or replace view invest.data_quality_issues as
select 
    id,
    task_id,
    check_name,
    entity_type,
    entity_id,
    trade_date,
    metric,
    status,
    message,
    expected_numeric,
    actual_numeric,
    diff_numeric,
    details,
    created_at
from invest_candles.data_quality_issues;

comment on view invest.data_quality_issues is 'Синоним для таблицы data_quality_issues из схемы invest_candles';

-- Права доступа на представление
alter view invest.data_quality_issues owner to postgres;

-- Таблица для хранения результатов анализа свечей с одинаковым типом за 6 дней подряд
create table invest_candles.candle_pattern_analysis
(
    id                   bigserial                                 not null,
    figi                 varchar(255)                              not null,
    analysis_date        date                                      not null,
    pattern_start_date   date                                      not null,
    pattern_end_date     date                                      not null,
    candle_type          varchar(20)                               not null,
    consecutive_days     integer                                   not null,
    avg_volume           bigint,
    avg_price_change     numeric(18, 9),
    total_price_change   numeric(18, 9),
    strategy_applicable  char(1) default null,
    created_at           timestamp(6) with time zone default now() not null,
    constraint pk_candle_pattern_analysis primary key (id),
    constraint chk_candle_type check (candle_type in ('BULLISH', 'BEARISH')),
    constraint chk_consecutive_days check (consecutive_days >= 2),
    constraint chk_strategy_applicable check (strategy_applicable in ('Y', 'N') or strategy_applicable is null)
);

comment on table invest_candles.candle_pattern_analysis is 'Таблица для хранения результатов анализа паттернов свечей с одинаковым типом за N дней подряд (минимум 2 дня)';

comment on column invest_candles.candle_pattern_analysis.id is 'Уникальный идентификатор записи';
comment on column invest_candles.candle_pattern_analysis.figi is 'Уникальный идентификатор инструмента (FIGI)';
comment on column invest_candles.candle_pattern_analysis.analysis_date is 'Дата проведения анализа';
comment on column invest_candles.candle_pattern_analysis.pattern_start_date is 'Дата начала паттерна (первый день одинакового типа свечи)';
comment on column invest_candles.candle_pattern_analysis.pattern_end_date is 'Дата окончания паттерна (последний день одинакового типа свечи)';
comment on column invest_candles.candle_pattern_analysis.candle_type is 'Тип свечи в паттерне (BULLISH или BEARISH)';
comment on column invest_candles.candle_pattern_analysis.consecutive_days is 'Количество дней подряд с одинаковым типом свечи';
comment on column invest_candles.candle_pattern_analysis.avg_volume is 'Средний объем торгов за период паттерна';
comment on column invest_candles.candle_pattern_analysis.avg_price_change is 'Среднее изменение цены за день в период паттерна';
comment on column invest_candles.candle_pattern_analysis.total_price_change is 'Общее изменение цены за весь период паттерна';
comment on column invest_candles.candle_pattern_analysis.strategy_applicable is 'Флаг применимости стратегии: Y - применима, N - не применима, NULL - не оценена';
comment on column invest_candles.candle_pattern_analysis.created_at is 'Время создания записи';

-- Права доступа
alter table invest_candles.candle_pattern_analysis owner to postgres;

-- Функция для добавления специальных торговых часов
create or replace function invest_candles.add_special_trading_hours(
    p_figi varchar(255),
    p_instrument_type varchar(20),
    p_day_type varchar(20),
    p_start_hour integer,
    p_start_minute integer,
    p_end_hour integer,
    p_end_minute integer,
    p_description text default null,
    p_created_by varchar(255) default null
)
returns bigint
language plpgsql
as
$$
declare
    v_id bigint;
begin
    -- Проверяем входные параметры
    if p_figi is null or p_instrument_type is null or p_day_type is null then
        raise exception 'FIGI, instrument_type и day_type не могут быть NULL';
    end if;
    
    if p_instrument_type not in ('shares', 'futures', 'indicatives') then
        raise exception 'instrument_type должен быть: shares, futures или indicatives';
    end if;
    
    if p_day_type not in ('weekday', 'weekend', 'all') then
        raise exception 'day_type должен быть: weekday, weekend или all';
    end if;
    
    -- Деактивируем существующие записи для этого инструмента и типа дня
    update invest_candles.special_trading_hours 
    set is_active = false, updated_at = now()
    where figi = p_figi 
    and day_type = p_day_type 
    and instrument_type = p_instrument_type
    and is_active = true;
    
    -- Добавляем новую запись
    insert into invest_candles.special_trading_hours (
        figi, instrument_type, day_type, start_hour, start_minute, 
        end_hour, end_minute, description, created_by
    ) values (
        p_figi, p_instrument_type, p_day_type, p_start_hour, p_start_minute,
        p_end_hour, p_end_minute, p_description, p_created_by
    ) returning id into v_id;
    
    return v_id;
end;
$$;

comment on function invest_candles.add_special_trading_hours(varchar, varchar, varchar, integer, integer, integer, integer, text, varchar) is 'Добавляет специальные торговые часы для инструмента';

-- Функция для получения торговых часов инструмента
create or replace function invest_candles.get_trading_hours(
    p_figi varchar(255)
)
returns table(
    start_hour integer,
    start_minute integer,
    end_hour integer,
    end_minute integer,
    is_special boolean,
    day_type varchar(20),
    created_at timestamp with time zone
)
language plpgsql
as
$$
begin
    -- Возвращаем все активные записи специальных торговых часов для данного FIGI
    return query
    select 
        sth.start_hour,
        sth.start_minute,
        sth.end_hour,
        sth.end_minute,
        true as is_special,
        sth.day_type,
        sth.created_at
    from invest_candles.special_trading_hours sth
    where sth.figi = p_figi
    and sth.is_active = true
    order by sth.day_type desc, sth.created_at desc;
    
    -- Если ничего не найдено, функция возвращает пустой результат
end;
$$;

comment on function invest_candles.get_trading_hours(varchar) is 'Возвращает специальные торговые часы для инструмента по FIGI, или пустой результат если не найдено';


-- Функция для удаления специальных торговых часов
create or replace function invest_candles.remove_special_trading_hours(
    p_figi varchar(255),
    p_instrument_type varchar(20) default null,
    p_day_type varchar(20) default null
)
returns integer
language plpgsql
as
$$
declare
    v_count integer;
begin
    -- Деактивируем записи
    update invest_candles.special_trading_hours 
    set is_active = false, updated_at = now()
    where figi = p_figi 
    and (p_instrument_type is null or instrument_type = p_instrument_type)
    and (p_day_type is null or day_type = p_day_type)
    and is_active = true;
    
    get diagnostics v_count = row_count;
    return v_count;
end;
$$;

comment on function invest_candles.remove_special_trading_hours(varchar, varchar, varchar) is 'Удаляет специальные торговые часы для инструмента';


-- Таблица для хранения результатов бектестов
create table invest_candles.backtest_results
(
    id                      bigserial                                 primary key,
    pattern_analysis_id     bigint                                    not null,
    figi                    varchar(255)                              not null,
    analysis_date           date                                      not null,
    entry_type              varchar(20)                               not null,
    entry_price             numeric(18, 9)                            not null,
    amount                  numeric(18, 2)                            not null,
    stop_loss_percent       numeric(5, 2)                             not null,
    take_profit_percent     numeric(5, 2)                             not null,
    stop_loss_price         numeric(18, 9)                            not null,
    take_profit_price       numeric(18, 9)                            not null,
    exit_type               varchar(30)                               not null,
    result                  varchar(20)                               not null,
    exit_price              numeric(18, 9)                            not null,
    exit_time               timestamp(6) with time zone               not null,
    profit_loss             numeric(18, 2)                            not null,
    profit_loss_percent     numeric(8, 4)                             not null,
    duration_minutes        integer                                   not null,
    created_at              timestamp(6) with time zone default now() not null,
    constraint fk_backtest_pattern_analysis foreign key (pattern_analysis_id) 
        references invest_candles.candle_pattern_analysis (id) on delete cascade,
    constraint chk_entry_type check (entry_type in ('OPEN', 'CLOSE')),
    constraint chk_exit_type check (exit_type in ('STOP_LOSS', 'TAKE_PROFIT', 'MAIN_SESSION_CLOSE', 'EVENING_SESSION_CLOSE')),
    constraint chk_result check (result in ('STOP_LOSS', 'TAKE_PROFIT', 'NO_EXIT', 'MAIN_SESSION_CLOSE', 'EVENING_SESSION_CLOSE')),
    constraint chk_stop_loss_percent check (stop_loss_percent > 0 and stop_loss_percent <= 100),
    constraint chk_take_profit_percent check (take_profit_percent > 0 and take_profit_percent <= 1000)
);

comment on table invest_candles.backtest_results is 'Таблица для хранения результатов бектестов торговых стратегий';

comment on column invest_candles.backtest_results.id is 'Уникальный идентификатор результата бектеста';
comment on column invest_candles.backtest_results.pattern_analysis_id is 'ID записи из таблицы candle_pattern_analysis';
comment on column invest_candles.backtest_results.figi is 'Уникальный идентификатор инструмента (FIGI)';
comment on column invest_candles.backtest_results.analysis_date is 'Дата анализа паттерна';
comment on column invest_candles.backtest_results.entry_type is 'Тип входа в позицию: OPEN - по цене открытия, CLOSE - по цене закрытия';
comment on column invest_candles.backtest_results.entry_price is 'Цена входа в позицию';
comment on column invest_candles.backtest_results.exit_type is 'Тип выхода из позиции: STOP_LOSS - по стоп-лоссу, TAKE_PROFIT - по тейк-профиту, MAIN_SESSION_CLOSE - по закрытию основной сессии (18:40-18:59), EVENING_SESSION_CLOSE - по закрытию вечерней сессии (последняя свеча)';
comment on column invest_candles.backtest_results.amount is 'Сумма сделки';
comment on column invest_candles.backtest_results.stop_loss_percent is 'Стоп-лосс в процентах';
comment on column invest_candles.backtest_results.take_profit_percent is 'Тейк-профит в процентах';
comment on column invest_candles.backtest_results.stop_loss_price is 'Цена стоп-лосса';
comment on column invest_candles.backtest_results.take_profit_price is 'Цена тейк-профита';
comment on column invest_candles.backtest_results.result is 'Результат сделки: STOP_LOSS - сработал стоп-лосс, TAKE_PROFIT - сработал тейк-профит, NO_EXIT - не закрыта по уровням, MAIN_SESSION_CLOSE - закрыта по основной сессии, EVENING_SESSION_CLOSE - закрыта по вечерней сессии';
comment on column invest_candles.backtest_results.exit_price is 'Цена выхода из позицииы';
comment on column invest_candles.backtest_results.exit_time is 'Время выхода из позиции';
comment on column invest_candles.backtest_results.profit_loss is 'Прибыль/убыток в абсолютных значениях';
comment on column invest_candles.backtest_results.profit_loss_percent is 'Прибыль/убыток в процентах';
comment on column invest_candles.backtest_results.duration_minutes is 'Длительность сделки в минутах';
comment on column invest_candles.backtest_results.created_at is 'Время создания записи';

alter table invest_candles.backtest_results owner to postgres;

-- Функция для выполнения бектеста по ID из candle_pattern_analysis
create or replace function invest_candles.run_backtest(
    p_pattern_analysis_id bigint,
    p_entry_type varchar(20),
    p_amount numeric(18, 2),
    p_stop_loss_percent numeric(5, 2),
    p_take_profit_percent numeric(5, 2),
    p_exit_type varchar(30) default 'STOP_LOSS'
)
returns bigint
language plpgsql
as $$
declare
    v_pattern_record record;
    v_entry_price numeric(18, 9);
    v_stop_loss_price numeric(18, 9);
    v_take_profit_price numeric(18, 9);
    v_candle_record record;
    v_result varchar(20) := 'NO_EXIT';
    v_exit_price numeric(18, 9);
    v_exit_time timestamp with time zone;
    v_profit_loss numeric(18, 2);
    v_profit_loss_percent numeric(8, 4);
    v_duration_minutes integer;
    v_backtest_id bigint;
    v_task_id varchar(255);
    v_start_time timestamp with time zone;
    v_end_time timestamp with time zone;
    v_candles_analyzed integer := 0;
    v_trading_day_start timestamp with time zone;
    v_trading_day_end timestamp with time zone;
begin
    -- Валидация входных параметров
    if p_entry_type not in ('OPEN', 'CLOSE') then
        raise exception 'Неверный тип входа: %. Допустимые значения: OPEN, CLOSE', p_entry_type;
    end if;
    
    if p_exit_type not in ('STOP_LOSS', 'TAKE_PROFIT', 'MAIN_SESSION_CLOSE', 'EVENING_SESSION_CLOSE') then
        raise exception 'Неверный тип выхода: %. Допустимые значения: STOP_LOSS, TAKE_PROFIT, MAIN_SESSION_CLOSE, EVENING_SESSION_CLOSE', p_exit_type;
    end if;
    
    if p_amount <= 0 then
        raise exception 'Сумма должна быть больше 0, получено: %', p_amount;
    end if;
    
    if p_stop_loss_percent <= 0 or p_stop_loss_percent > 100 then
        raise exception 'Стоп-лосс должен быть от 0 до 100%%, получено: %', p_stop_loss_percent;
    end if;
    
    if p_take_profit_percent <= 0 or p_take_profit_percent > 1000 then
        raise exception 'Тейк-профит должен быть от 0 до 1000%%, получено: %', p_take_profit_percent;
    end if;

    -- Генерируем уникальный ID задачи для логирования
    v_task_id := 'BACKTEST_' || p_pattern_analysis_id || '_' || extract(epoch from now())::bigint;
    v_start_time := now();
    
    -- Получаем данные из candle_pattern_analysis
    select * into v_pattern_record
    from invest_candles.candle_pattern_analysis
    where id = p_pattern_analysis_id;
    
    if not found then
        raise exception 'Запись с ID % не найдена в таблице candle_pattern_analysis', p_pattern_analysis_id;
    end if;
    
    -- Определяем рабочие дни для анализа
    declare
        v_analysis_workday date;
        v_previous_friday date;
        v_next_monday date;
    begin
        if extract(dow from v_pattern_record.analysis_date) in (0, 6) then
            -- Если analysis_date - выходной, определяем ближайшие рабочие дни
            if extract(dow from v_pattern_record.analysis_date) = 0 then -- Воскресенье
                v_previous_friday := v_pattern_record.analysis_date - interval '2 days';
                v_next_monday := v_pattern_record.analysis_date + interval '1 day';
            else -- Суббота
                v_previous_friday := v_pattern_record.analysis_date - interval '1 day';
                v_next_monday := v_pattern_record.analysis_date + interval '2 days';
            end if;
            v_analysis_workday := v_next_monday;
        else
            -- Если analysis_date - рабочий день, используем его
            v_analysis_workday := v_pattern_record.analysis_date;
            v_previous_friday := v_pattern_record.analysis_date - interval '1 day';
            v_next_monday := v_pattern_record.analysis_date;
        end if;
    
    -- Логируем начало работы
    insert into invest.system_logs (task_id, endpoint, method, status, message, start_time)
    values (v_task_id, 'run_backtest', 'FUNCTION', 'STARTED', 
            format('Начат бектест для паттерна ID %s, FIGI %s, дата анализа %s', 
                   p_pattern_analysis_id, v_pattern_record.figi, v_pattern_record.analysis_date), v_start_time);
    
        -- Определяем цену входа в зависимости от типа
        if p_entry_type = 'OPEN' then
            -- Для OPEN: ищем первую свечу в понедельнике (или analysis_date если рабочий день)
            v_trading_day_start := (v_next_monday + interval '7 hours')::timestamp with time zone;
            v_trading_day_end := (v_next_monday + interval '23 hours 50 minutes')::timestamp with time zone;
            
            select * into v_candle_record
            from invest_candles.minute_candles
            where figi = v_pattern_record.figi
              and time >= v_trading_day_start
              and time < v_trading_day_end
              and is_complete = true
            order by time
            limit 1;
            
            if not found then
                raise exception 'Не найдены минутные свечи для FIGI % на дату % (OPEN)', v_pattern_record.figi, v_next_monday;
            end if;
            
            v_entry_price := v_candle_record.open;
            
        else -- CLOSE
            -- Для CLOSE: ищем последнюю свечу в пятницу
            v_trading_day_start := (v_previous_friday + interval '7 hours')::timestamp with time zone;
            v_trading_day_end := (v_previous_friday + interval '23 hours 50 minutes')::timestamp with time zone;
            
            select * into v_candle_record
            from invest_candles.minute_candles
            where figi = v_pattern_record.figi
              and time >= v_trading_day_start
              and time < v_trading_day_end
              and is_complete = true
            order by time desc
            limit 1;
            
            if not found then
                raise exception 'Не найдены минутные свечи для FIGI % на дату % (CLOSE)', v_pattern_record.figi, v_previous_friday;
            end if;
            
            v_entry_price := v_candle_record.close;
        end if;
    
        -- Определяем торговый день для анализа (ближайший понедельник или analysis_date если рабочий день)
        v_trading_day_start := (v_analysis_workday + interval '7 hours')::timestamp with time zone;
        v_trading_day_end := (v_analysis_workday + interval '23 hours 50 minutes')::timestamp with time zone;
    
    -- Рассчитываем цены стоп-лосса и тейк-профита
    -- Для бычьего паттерна: покупаем, стоп-лосс ниже, тейк-профит выше
    -- Для медвежьего паттерна: продаем, стоп-лосс выше, тейк-профит ниже
    if v_pattern_record.candle_type = 'BULLISH' then
        -- Покупка: стоп-лосс ниже цены входа, тейк-профит выше
        v_stop_loss_price := v_entry_price * (1 - p_stop_loss_percent / 100);
        v_take_profit_price := v_entry_price * (1 + p_take_profit_percent / 100);
    else -- BEARISH
        -- Продажа: стоп-лосс выше цены входа, тейк-профит ниже
        v_stop_loss_price := v_entry_price * (1 + p_stop_loss_percent / 100);
        v_take_profit_price := v_entry_price * (1 - p_take_profit_percent / 100);
    end if;
    
    -- Инициализируем значения по умолчанию
    v_exit_price := v_entry_price;
    v_exit_time := v_candle_record.time;
    
        -- Анализируем минутные свечи в зависимости от типа выхода
        if p_exit_type in ('STOP_LOSS', 'TAKE_PROFIT') then
            -- Анализируем минутные свечи в течение торгового дня для стоп-лосса/тейк-профита
            for v_candle_record in
                select *
                from invest_candles.minute_candles
                where figi = v_pattern_record.figi
                  and time >= v_trading_day_start
                  and time < v_trading_day_end
                  and is_complete = true
                order by time
            loop
                v_candles_analyzed := v_candles_analyzed + 1;
                
                -- Проверяем условия выхода в зависимости от типа паттерна
                if v_pattern_record.candle_type = 'BULLISH' then
                    -- Для бычьего паттерна (покупка)
                    if v_candle_record.low <= v_stop_loss_price then
                        -- Сработал стоп-лосс
                        v_result := 'STOP_LOSS';
                        v_exit_price := v_stop_loss_price;
                        v_exit_time := v_candle_record.time;
                        exit;
                    elsif v_candle_record.high >= v_take_profit_price then
                        -- Сработал тейк-профит
                        v_result := 'TAKE_PROFIT';
                        v_exit_price := v_take_profit_price;
                        v_exit_time := v_candle_record.time;
                        exit;
                    end if;
                else -- BEARISH
                    -- Для медвежьего паттерна (продажа)
                    if v_candle_record.high >= v_stop_loss_price then
                        -- Сработал стоп-лосс
                        v_result := 'STOP_LOSS';
                        v_exit_price := v_stop_loss_price;
                        v_exit_time := v_candle_record.time;
                        exit;
                    elsif v_candle_record.low <= v_take_profit_price then
                        -- Сработал тейк-профит
                        v_result := 'TAKE_PROFIT';
                        v_exit_price := v_take_profit_price;
                        v_exit_time := v_candle_record.time;
                        exit;
                    end if;
                end if;
                
                -- Обновляем цену выхода на случай, если не сработают условия
                v_exit_price := v_candle_record.close;
                v_exit_time := v_candle_record.time;
            end loop;
            
            -- Если сделка не закрылась по стоп-лоссу или тейк-профиту, ищем соответствующую свечу закрытия сессии
            if v_result = 'NO_EXIT' then
                -- Определяем, какую свечу закрытия искать в зависимости от типа входа
                if p_entry_type = 'OPEN' then
                    -- Для OPEN ищем свечу закрытия основной сессии (18:40-18:59)
                    select * into v_candle_record
                    from invest_candles.minute_candles
                    where figi = v_pattern_record.figi
                      and time >= v_trading_day_start
                      and time < v_trading_day_end
                      and is_complete = true
                      -- Основная сессия: 18:40-18:59
                      and extract(hour from time) = 18
                      and extract(minute from time) between 40 and 59
                    order by time desc
                    limit 1;
                    
                    if found then
                        v_result := 'MAIN_SESSION_CLOSE';
                        v_exit_price := v_candle_record.close;
                        v_exit_time := v_candle_record.time;
                    else
                        -- Если не найдена свеча основной сессии, берем последнюю свечу
                        select * into v_candle_record
                        from invest_candles.minute_candles
                        where figi = v_pattern_record.figi
                          and time >= v_trading_day_start
                          and time < v_trading_day_end
                          and is_complete = true
                        order by time desc
                        limit 1;
                        
                        if found then
                            v_result := 'EVENING_SESSION_CLOSE';
                            v_exit_price := v_candle_record.close;
                            v_exit_time := v_candle_record.time;
                        end if;
                    end if;
                else -- CLOSE
                    -- Для CLOSE ищем последнюю свечу вечерней сессии
                    select * into v_candle_record
                    from invest_candles.minute_candles
                    where figi = v_pattern_record.figi
                      and time >= v_trading_day_start
                      and time < v_trading_day_end
                      and is_complete = true
                    order by time desc
                    limit 1;
                    
                    if found then
                        v_result := 'EVENING_SESSION_CLOSE';
                        v_exit_price := v_candle_record.close;
                        v_exit_time := v_candle_record.time;
                    end if;
                end if;
            end if;
            
        elsif p_exit_type = 'MAIN_SESSION_CLOSE' then
            -- Ищем свечу закрытия основной сессии (18:40-18:59)
            select * into v_candle_record
            from invest_candles.minute_candles
            where figi = v_pattern_record.figi
              and time >= v_trading_day_start
              and time < v_trading_day_end
              and is_complete = true
              -- Основная сессия: 18:40-18:59
              and extract(hour from time) = 18
              and extract(minute from time) between 40 and 59
            order by time desc
            limit 1;
            
            if found then
                v_result := 'MAIN_SESSION_CLOSE';
                v_exit_price := v_candle_record.close;
                v_exit_time := v_candle_record.time;
                v_candles_analyzed := 1;
            else
                raise exception 'Не найдены минутные свечи основной сессии для FIGI % на дату %', v_pattern_record.figi, v_analysis_workday;
            end if;
            
        else -- EVENING_SESSION_CLOSE
            -- Ищем последнюю свечу вечерней сессии
            select * into v_candle_record
            from invest_candles.minute_candles
            where figi = v_pattern_record.figi
              and time >= v_trading_day_start
              and time < v_trading_day_end
              and is_complete = true
            order by time desc
            limit 1;
            
            if found then
                v_result := 'EVENING_SESSION_CLOSE';
                v_exit_price := v_candle_record.close;
                v_exit_time := v_candle_record.time;
                v_candles_analyzed := 1;
            else
                raise exception 'Не найдены минутные свечи для FIGI % на дату %', v_pattern_record.figi, v_analysis_workday;
            end if;
        end if;
    end;
    
    -- Рассчитываем прибыль/убыток
    if v_pattern_record.candle_type = 'BULLISH' then
        -- Для покупки: прибыль = (цена выхода - цена входа) * количество
        v_profit_loss := (v_exit_price - v_entry_price) * (p_amount / v_entry_price);
        v_profit_loss_percent := ((v_exit_price - v_entry_price) / v_entry_price) * 100;
    else -- BEARISH
        -- Для продажи: прибыль = (цена входа - цена выхода) * количество
        v_profit_loss := (v_entry_price - v_exit_price) * (p_amount / v_entry_price);
        v_profit_loss_percent := ((v_entry_price - v_exit_price) / v_entry_price) * 100;
    end if;
    
    -- Рассчитываем длительность в минутах
    v_duration_minutes := extract(epoch from (v_exit_time - v_trading_day_start))::integer / 60;
    
    -- Сохраняем результат бектеста
    insert into invest_candles.backtest_results (
        pattern_analysis_id, figi, analysis_date, entry_type, entry_price, amount,
        stop_loss_percent, take_profit_percent, stop_loss_price, take_profit_price,
        exit_type, result, exit_price, exit_time, profit_loss, profit_loss_percent, duration_minutes
    ) values (
        p_pattern_analysis_id, v_pattern_record.figi, v_pattern_record.analysis_date, p_entry_type, v_entry_price, p_amount,
        p_stop_loss_percent, p_take_profit_percent, v_stop_loss_price, v_take_profit_price,
        p_exit_type, v_result, v_exit_price, v_exit_time, v_profit_loss, v_profit_loss_percent, v_duration_minutes
    ) returning id into v_backtest_id;
    
    v_end_time := now();
    
    -- Логируем успешное завершение
    insert into invest.system_logs (task_id, endpoint, method, status, message, start_time, end_time)
    values (v_task_id, 'run_backtest', 'FUNCTION', 'SUCCESS', 
            format('Бектест завершен успешно. ID результата: %s, результат: %s, P&L: %s%%, свечей проанализировано: %s', 
                   v_backtest_id, v_result, round(v_profit_loss_percent, 2), v_candles_analyzed), v_start_time, v_end_time);
    
    return v_backtest_id;
    
exception
    when others then
        v_end_time := now();
        
        -- Логируем ошибку
        insert into invest.system_logs (task_id, endpoint, method, status, message, start_time, end_time)
        values (v_task_id, 'run_backtest', 'FUNCTION', 'ERROR', 
                format('Ошибка при выполнении бектеста: %s', sqlerrm), v_start_time, v_end_time);
        
        raise;
end;
$$;

comment on function invest_candles.run_backtest(bigint, varchar, numeric, numeric, numeric, varchar) is 'Функция для выполнения бектеста торговой стратегии по ID из candle_pattern_analysis. entry_type: OPEN - первая свеча в понедельнике (цена open), CLOSE - последняя свеча в пятнице (цена close). exit_type: STOP_LOSS/TAKE_PROFIT - по уровням, если не сработали - закрытие по сессии (OPEN→основная сессия, CLOSE→вечерняя сессия), MAIN_SESSION_CLOSE - закрытие основной сессии (18:40-18:59), EVENING_SESSION_CLOSE - последняя свеча вечерней сессии. Если analysis_date - выходной, анализ происходит в ближайший понедельник. Торговый интервал: 07:00-23:50 МСК';

-- Права на функцию
alter function invest_candles.run_backtest(bigint, varchar, numeric, numeric, numeric, varchar) owner to postgres;

-- ============================================================================
-- СИНОНИМЫ (VIEWS И ФУНКЦИИ) В СХЕМЕ INVEST
-- ============================================================================

-- View для результатов бектестов в схеме invest
create or replace view invest.backtest_results as
select 
    br.id,
    br.pattern_analysis_id,
    br.figi,
    br.analysis_date,
    br.entry_type,
    br.entry_price,
    br.amount,
    br.stop_loss_percent,
    br.take_profit_percent,
    br.stop_loss_price,
    br.take_profit_price,
    br.exit_type,
    br.result,
    br.exit_price,
    br.exit_time,
    br.profit_loss,
    br.profit_loss_percent,
    br.duration_minutes,
    br.created_at,
    -- Добавляем информацию об инструменте
    CASE 
        WHEN s.figi IS NOT NULL THEN s.name
        WHEN f.figi IS NOT NULL THEN f.ticker
        WHEN i.figi IS NOT NULL THEN i.name
    END AS instrument_name,
    CASE 
        WHEN s.figi IS NOT NULL THEN s.ticker
        WHEN f.figi IS NOT NULL THEN f.ticker
        WHEN i.figi IS NOT NULL THEN i.ticker
    END AS instrument_ticker,
    CASE 
        WHEN s.figi IS NOT NULL THEN 'shares'
        WHEN f.figi IS NOT NULL THEN 'futures'
        WHEN i.figi IS NOT NULL THEN 'indicatives'
    END AS instrument_type
from invest_candles.backtest_results br
left join invest_ref.shares s on br.figi = s.figi
left join invest_ref.futures f on br.figi = f.figi
left join invest_ref.indicatives i on br.figi = i.figi;

comment on view invest.backtest_results is 'Синоним для таблицы backtest_results из схемы invest_candles с дополнительной информацией об инструментах';

-- Устанавливаем владельца view
alter view invest.backtest_results owner to postgres;

-- Синоним функции выполнения бектеста в схеме invest
create or replace function invest.run_backtest(
    p_pattern_analysis_id bigint,
    p_entry_type varchar(20),
    p_amount numeric(18, 2),
    p_stop_loss_percent numeric(5, 2),
    p_take_profit_percent numeric(5, 2),
    p_exit_type varchar(30) default 'STOP_LOSS'
)
returns bigint
language plpgsql
as $$
begin
    return invest_candles.run_backtest(
        p_pattern_analysis_id, p_entry_type, p_amount,
        p_stop_loss_percent, p_take_profit_percent, p_exit_type
    );
end;
$$;

comment on function invest.run_backtest(bigint, varchar, numeric, numeric, numeric, varchar) is 'Синоним для функции invest_candles.run_backtest - выполняет бектест торговой стратегии по ID из candle_pattern_analysis';

alter function invest.run_backtest(bigint, varchar, numeric, numeric, numeric, varchar) owner to postgres;

-- ============================================================================
-- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ ФУНКЦИИ RUN_BACKTEST И ТАБЛИЦЫ BACKTEST_RESULTS
-- ============================================================================

-- Пример 1: Выполнение бектеста для бычьего паттерна с входом по цене открытия
-- и выходом по стоп-лоссу или тейк-профиту (если не сработали - закрытие основной сессии)
-- SELECT invest.run_backtest(
--     p_pattern_analysis_id := 1,           -- ID из таблицы candle_pattern_analysis
--     p_entry_type := 'OPEN',               -- Вход по цене открытия первой свечи в понедельнике
--     p_amount := 100000.00,                -- Сумма сделки: 100 000 рублей
--     p_stop_loss_percent := 2.0,          -- Стоп-лосс: 2%
--     p_take_profit_percent := 5.0,        -- Тейк-профит: 5%
--     p_exit_type := 'STOP_LOSS'           -- Тип выхода: стоп-лосс/тейк-профит, если не сработали - закрытие основной сессии
-- );

-- Пример 2: Выполнение бектеста для медвежьего паттерна с входом по цене закрытия пятницы
-- и обязательным закрытием по основной сессии
-- SELECT invest.run_backtest(
--     p_pattern_analysis_id := 2,
--     p_entry_type := 'CLOSE',             -- Вход по цене закрытия последней свечи в пятницу
--     p_amount := 50000.00,
--     p_stop_loss_percent := 1.5,
--     p_take_profit_percent := 3.0,
--     p_exit_type := 'MAIN_SESSION_CLOSE'  -- Обязательное закрытие основной сессии (18:40-18:59)
-- );

-- Пример 3: Выполнение бектеста с закрытием по вечерней сессии
-- SELECT invest.run_backtest(
--     p_pattern_analysis_id := 3,
--     p_entry_type := 'OPEN',
--     p_amount := 200000.00,
--     p_stop_loss_percent := 3.0,
--     p_take_profit_percent := 7.0,
--     p_exit_type := 'EVENING_SESSION_CLOSE'  -- Закрытие по последней свече вечерней сессии
-- );

-- Пример 4: Получение всех результатов бектестов с информацией об инструментах
-- SELECT 
--     br.id,
--     br.instrument_name,
--     br.instrument_ticker,
--     br.instrument_type,
--     br.analysis_date,
--     br.entry_type,
--     br.entry_price,
--     br.exit_price,
--     br.result,
--     br.profit_loss,
--     br.profit_loss_percent,
--     br.duration_minutes,
--     br.created_at
-- FROM invest.backtest_results br
-- ORDER BY br.created_at DESC
-- LIMIT 100;

-- Пример 5: Получение результатов бектестов для конкретного инструмента
-- SELECT 
--     br.id,
--     br.analysis_date,
--     br.entry_type,
--     br.entry_price,
--     br.exit_price,
--     br.result,
--     br.profit_loss_percent,
--     br.duration_minutes
-- FROM invest.backtest_results br
-- WHERE br.figi = 'BBG004730N88'  -- Пример FIGI
-- ORDER BY br.analysis_date DESC;

-- Пример 6: Статистика по результатам бектестов
-- SELECT 
--     result,
--     count(*) as count,
--     round(avg(profit_loss_percent), 2) as avg_profit_loss_percent,
--     round(sum(profit_loss), 2) as total_profit_loss,
--     round(avg(duration_minutes), 0) as avg_duration_minutes
-- FROM invest.backtest_results
-- GROUP BY result
-- ORDER BY count DESC;

-- Пример 7: Поиск успешных бектестов с высокой прибылью
-- SELECT 
--     br.instrument_name,
--     br.instrument_ticker,
--     br.analysis_date,
--     br.entry_type,
--     br.profit_loss_percent,
--     br.duration_minutes,
--     br.created_at
-- FROM invest.backtest_results br
-- WHERE br.result = 'TAKE_PROFIT'
--   AND br.profit_loss_percent > 3.0
-- ORDER BY br.profit_loss_percent DESC
-- LIMIT 50;

-- Пример 8: Анализ убыточных сделок
-- SELECT 
--     br.instrument_name,
--     br.instrument_ticker,
--     br.analysis_date,
--     br.entry_type,
--     br.stop_loss_percent,
--     br.profit_loss_percent,
--     br.duration_minutes
-- FROM invest.backtest_results br
-- WHERE br.result = 'STOP_LOSS'
-- ORDER BY br.profit_loss_percent ASC
-- LIMIT 50;

-- Пример 9: Связь результатов бектестов с анализом паттернов свечей
-- SELECT 
--     cpa.instrument_name,
--     cpa.instrument_ticker,
--     cpa.candle_type,
--     cpa.consecutive_days,
--     cpa.analysis_date,
--     br.entry_type,
--     br.result,
--     br.profit_loss_percent,
--     br.duration_minutes
-- FROM invest.candle_pattern_analysis cpa
-- JOIN invest.backtest_results br ON cpa.id = br.pattern_analysis_id
-- WHERE cpa.strategy_applicable = true
-- ORDER BY br.profit_loss_percent DESC;

-- Пример 10: Выполнение бектеста для всех найденных паттернов за определенную дату
-- DO $$
-- DECLARE
--     v_pattern_id bigint;
--     v_backtest_id bigint;
-- BEGIN
--     FOR v_pattern_id IN 
--         SELECT id 
--         FROM invest.candle_pattern_analysis 
--         WHERE analysis_date = '2024-01-15'::date 
--           AND strategy_applicable = true
--     LOOP
--         BEGIN
--             SELECT invest.run_backtest(
--                 v_pattern_id,
--                 'OPEN',
--                 100000.00,
--                 2.0,
--                 5.0,
--                 'STOP_LOSS'
--             ) INTO v_backtest_id;
--             
--             RAISE NOTICE 'Бектест выполнен для паттерна ID: %, результат ID: %', v_pattern_id, v_backtest_id;
--         EXCEPTION WHEN OTHERS THEN
--             RAISE NOTICE 'Ошибка при выполнении бектеста для паттерна ID %: %', v_pattern_id, sqlerrm;
--         END;
--     END LOOP;
-- END;
-- $$;

-- Вспомогательная функция для получения статистики по бектестам
create or replace function invest_candles.get_backtest_stats(
    p_analysis_date_from date default null,
    p_analysis_date_to date default null,
    p_figi varchar(255) default null
)
returns table (
    total_backtests bigint,
    successful_backtests bigint,
    failed_backtests bigint,
    no_exit_backtests bigint,
    success_rate numeric(5, 2),
    avg_profit_loss_percent numeric(8, 4),
    total_profit_loss numeric(18, 2),
    avg_duration_minutes numeric(8, 2),
    best_trade_percent numeric(8, 4),
    worst_trade_percent numeric(8, 4)
)
language plpgsql
as $$
begin
    return query
    select 
        count(*) as total_backtests,
        count(*) filter (where result = 'TAKE_PROFIT') as successful_backtests,
        count(*) filter (where result = 'STOP_LOSS') as failed_backtests,
        count(*) filter (where result = 'NO_EXIT') as no_exit_backtests,
        round((count(*) filter (where result = 'TAKE_PROFIT')::numeric / nullif(count(*), 0)) * 100, 2) as success_rate,
        avg(br.profit_loss_percent) as avg_profit_loss_percent,
        sum(br.profit_loss) as total_profit_loss,
        avg(br.duration_minutes) as avg_duration_minutes,
        max(br.profit_loss_percent) as best_trade_percent,
        min(br.profit_loss_percent) as worst_trade_percent
    from invest_candles.backtest_results br
    where (p_analysis_date_from is null or br.analysis_date >= p_analysis_date_from)
      and (p_analysis_date_to is null or br.analysis_date <= p_analysis_date_to)
      and (p_figi is null or br.figi = p_figi);
end;
$$;

comment on function invest_candles.get_backtest_stats(date, date, varchar) is 'Функция для получения статистики по результатам бектестов';

-- Права на вспомогательную функцию
alter function invest_candles.get_backtest_stats(date, date, varchar) owner to postgres;

-- Создание синонима для функции статистики в схеме invest
create or replace function invest.get_backtest_stats(
    p_analysis_date_from date default null,
    p_analysis_date_to date default null,
    p_figi varchar(255) default null
)
returns table (
    total_backtests bigint,
    successful_backtests bigint,
    failed_backtests bigint,
    no_exit_backtests bigint,
    success_rate numeric(5, 2),
    avg_profit_loss_percent numeric(8, 4),
    total_profit_loss numeric(18, 2),
    avg_duration_minutes numeric(8, 2),
    best_trade_percent numeric(8, 4),
    worst_trade_percent numeric(8, 4)
)
language plpgsql
as $$
begin
    -- Вызываем оригинальную функцию из схемы invest_candles
    return query select * from invest_candles.get_backtest_stats(p_analysis_date_from, p_analysis_date_to, p_figi);
end;
$$;

comment on function invest.get_backtest_stats(date, date, varchar) is 'Синоним для функции invest_candles.get_backtest_stats - получение статистики по результатам бектестов';

-- Права на функцию-синоним статистики
alter function invest.get_backtest_stats(date, date, varchar) owner to postgres;

-- Функция для анализа свечей с одинаковым типом за N дней подряд
create or replace function invest_candles.analyze_candle_patterns(p_analysis_date date, p_consecutive_days integer default 5)
returns void
language plpgsql
as $$
declare
    v_start_date date;
    v_end_date date;
    v_task_id varchar(255);
    v_start_time timestamp with time zone;
    v_end_time timestamp with time zone;
    v_patterns_found integer := 0;
    v_instruments_analyzed integer := 0;
    rec record;
begin
    -- Проверяем корректность параметра количества дней
    if p_consecutive_days < 2 then
        raise exception 'Количество дней последовательности должно быть не менее 2, получено: %', p_consecutive_days;
    end if;
    
    -- Генерируем уникальный ID задачи
    v_task_id := 'CANDLE_PATTERN_ANALYSIS_' || to_char(p_analysis_date, 'YYYY_MM_DD') || '_' || p_consecutive_days || 'D_' || extract(epoch from now())::bigint;
    v_start_time := now();
    
    -- Определяем период анализа: N торговых дней назад от входной даты (не включая её, исключая выходные)
    v_end_date := p_analysis_date - interval '1 day';
    
    -- Расширяем период поиска, учитывая выходные дни (примерно в 1.4 раза больше для покрытия выходных)
    -- Для надежности берем период в 2 раза больше, чтобы гарантированно покрыть все торговые дни
    v_start_date := v_end_date - make_interval(days => p_consecutive_days * 2);
    
    -- Логируем начало работы
    insert into invest.system_logs (task_id, endpoint, method, status, message, start_time)
    values (v_task_id, 'analyze_candle_patterns', 'FUNCTION', 'STARTED', 
            format('Начат анализ паттернов свечей за период с %s по %s (анализ на дату %s, минимум %s торговых дней подряд, исключая выходные)', 
                   v_start_date, v_end_date, p_analysis_date, p_consecutive_days), v_start_time);
    
    -- Основной запрос для поиска паттернов (исключая выходные дни)
    for rec in
        with trading_days_sequence as (
            -- Получаем последние N торговых дней для каждого FIGI
            select 
                figi,
                time::date as candle_date,
                candle_type,
                volume,
                price_change,
                row_number() over (partition by figi order by time::date desc) as day_rank
            from invest.daily_candles
            where time::date <= v_end_date
              and candle_type in ('BULLISH', 'BEARISH')
              and is_complete = true
              -- Исключаем выходные дни: суббота (6) и воскресенье (0)
              and extract(dow from time::date) not in (0, 6)
        ),
        last_n_days as (
            -- Берем только последние N торговых дней
            select 
                figi,
                candle_date,
                candle_type,
                volume,
                price_change,
                day_rank
            from trading_days_sequence
            where day_rank <= p_consecutive_days
        ),
        consecutive_check as (
            -- Проверяем, все ли дни имеют одинаковый тип свечи
            select 
                figi,
                candle_type,
                count(*) as consecutive_days,
                min(candle_date) as pattern_start_date,
                max(candle_date) as pattern_end_date,
                avg(volume) as avg_volume,
                avg(price_change) as avg_price_change,
                sum(price_change) as total_price_change,
                count(distinct candle_type) as unique_candle_types
            from last_n_days
            group by figi, candle_type
        ),
        pattern_groups as (
            -- Оставляем только те группы, где все дни имеют одинаковый тип
            select 
                figi,
                candle_type,
                pattern_start_date,
                pattern_end_date,
                consecutive_days,
                avg_volume,
                avg_price_change,
                total_price_change
            from consecutive_check
            where consecutive_days = p_consecutive_days  -- Точно N дней
              and unique_candle_types = 1  -- Все дни одного типа
        )
        select * from pattern_groups
        order by figi, pattern_start_date
    loop
        -- Проверяем, что паттерн не был уже записан для этой даты анализа
        if not exists (
            select 1 from invest_candles.candle_pattern_analysis 
            where figi = rec.figi 
              and analysis_date = p_analysis_date
              and pattern_start_date = rec.pattern_start_date
              and pattern_end_date = rec.pattern_end_date
              and candle_type = rec.candle_type
        ) then
            -- Вставляем найденный паттерн
            insert into invest_candles.candle_pattern_analysis (
                figi, analysis_date, pattern_start_date, pattern_end_date,
                candle_type, consecutive_days, avg_volume, avg_price_change, total_price_change
            ) values (
                rec.figi, p_analysis_date, rec.pattern_start_date, rec.pattern_end_date,
                rec.candle_type, rec.consecutive_days, rec.avg_volume, rec.avg_price_change, rec.total_price_change
            );
            
            v_patterns_found := v_patterns_found + 1;
        end if;
        
        v_instruments_analyzed := v_instruments_analyzed + 1;
    end loop;
    
    v_end_time := now();
    
    -- Логируем успешное завершение
    insert into invest.system_logs (task_id, endpoint, method, status, message, start_time, end_time)
    values (v_task_id, 'analyze_candle_patterns', 'FUNCTION', 'SUCCESS', 
            format('Анализ завершен успешно. Найдено паттернов: %s, проанализировано инструментов: %s', 
                   v_patterns_found, v_instruments_analyzed), v_start_time, v_end_time);
    
    -- Дополнительное логирование с деталями найденных паттернов
    if v_patterns_found > 0 then
        insert into invest.system_logs (task_id, endpoint, method, status, message, start_time, end_time)
        values (v_task_id || '_DETAILS', 'analyze_candle_patterns', 'FUNCTION', 'INFO', 
                format('Детали анализа: период %s - %s, найдено %s паттернов с %s+ торговыми днями одинакового типа свечи (исключая выходные)', 
                       v_start_date, v_end_date, v_patterns_found, p_consecutive_days), v_start_time, v_end_time);
    end if;
    
exception
    when others then
        v_end_time := now();
        
        -- Логируем ошибку
        insert into invest.system_logs (task_id, endpoint, method, status, message, start_time, end_time)
        values (v_task_id, 'analyze_candle_patterns', 'FUNCTION', 'ERROR', 
                format('Ошибка при анализе паттернов свечей: %s', sqlerrm), v_start_time, v_end_time);
        
        raise;
end;
$$;

comment on function invest_candles.analyze_candle_patterns(date, integer) is 'Функция для анализа паттернов свечей с одинаковым типом (BULLISH/BEARISH) за N торговых дней подряд (по умолчанию 5), исключая выходные';

-- Права на функцию
alter function invest_candles.analyze_candle_patterns(date, integer) owner to postgres;

-- Функция для проверки соответствия дневных и минутных свечей
create or replace function invest_candles.run_daily_vs_minute_check(
    p_date date
)
returns table(task_id text, total_rows bigint, mismatches bigint)
language plpgsql
cost 100
volatile parallel unsafe
rows 1000
as $$
declare
    v_task_id text;
    v_total_rows bigint := 0;
    v_mismatches bigint := 0;
    v_daily_record record;
    v_minute_record record;
    v_instrument_type text;
    v_diff_volume bigint;
    v_diff_high numeric;
    v_diff_low numeric;
    v_diff_open numeric;
    v_diff_close numeric;
    v_is_weekend boolean;
    v_trading_start_hour integer;
    v_trading_start_minute integer;
    v_trading_end_hour integer;
    v_trading_end_minute integer;
    v_log_message text;
    v_log_status text;
    v_start_time timestamp with time zone;
    v_trading_hours record;
    v_time_condition text;
begin
    -- Засекаем время начала
    v_start_time := now();
    
    -- Генерируем уникальный task_id
    v_task_id := 'daily_vs_minute_check_' || to_char(p_date, 'YYYY_MM_DD') || '_' || extract(epoch from now())::text;
    
    -- Определяем, выходной ли день (суббота = 6, воскресенье = 0)
    v_is_weekend := extract(dow from p_date) in (0, 6);
    
    -- Получаем только дневные свечи для акций и фьючерсов за указанную дату
    for v_daily_record in
        select 
            dc.figi,
            dc.volume as daily_volume,
            dc.high as daily_high,
            dc.low as daily_low,
            dc.open as daily_open,
            dc.close as daily_close
        from invest.daily_candles dc
        where date(dc.time at time zone 'Europe/Moscow') = p_date
        and (
            exists (select 1 from invest.shares where figi = dc.figi) or
            exists (select 1 from invest.futures where figi = dc.figi)
        )
    loop
        v_total_rows := v_total_rows + 1;
        
        -- Определяем тип инструмента
        v_instrument_type := 'unknown';
        
        -- Проверяем, есть ли в таблице shares
        if exists (select 1 from invest.shares where figi = v_daily_record.figi) then
            v_instrument_type := 'shares';
        -- Проверяем, есть ли в таблице futures
        elsif exists (select 1 from invest.futures where figi = v_daily_record.figi) then
            v_instrument_type := 'futures';
        end if;
        
        -- Получаем торговые часы для данного инструмента
        select * into v_trading_hours
        from invest_candles.get_trading_hours(v_daily_record.figi)
        where (day_type = case when v_is_weekend then 'weekend' else 'weekday' end or day_type = 'all')
        order by day_type desc, created_at desc
        limit 1;
        
        -- Если специальных часов нет, используем стандартные
        if v_trading_hours.start_hour is null then
            if v_is_weekend then
                -- Выходные дни: с 09:59 до 18:59
                v_trading_hours.start_hour := 9;
                v_trading_hours.start_minute := 59;
                v_trading_hours.end_hour := 18;
                v_trading_hours.end_minute := 59;
                v_trading_hours.is_special := false;
            else
                -- Рабочие дни: без ограничений по времени
                v_trading_hours.start_hour := 0;
                v_trading_hours.start_minute := 0;
                v_trading_hours.end_hour := 23;
                v_trading_hours.end_minute := 59;
                v_trading_hours.is_special := false;
            end if;
        end if;
        
        -- Формируем условие для фильтрации по времени
        v_time_condition := format(
            'extract(hour from mc.time at time zone ''Europe/Moscow'') >= %s and ' ||
            '(extract(hour from mc.time at time zone ''Europe/Moscow'') > %s or ' ||
            ' extract(minute from mc.time at time zone ''Europe/Moscow'') >= %s) and ' ||
            'extract(hour from mc.time at time zone ''Europe/Moscow'') <= %s and ' ||
            '(extract(hour from mc.time at time zone ''Europe/Moscow'') < %s or ' ||
            ' extract(minute from mc.time at time zone ''Europe/Moscow'') <= %s)',
            v_trading_hours.start_hour::text, v_trading_hours.start_hour::text, v_trading_hours.start_minute::text,
            v_trading_hours.end_hour::text, v_trading_hours.end_hour::text, v_trading_hours.end_minute::text
        );
        
        -- Получаем агрегированные данные из минутных свечей для того же инструмента и даты
        -- с учетом специальных торговых часов
        execute format('
            with filtered_candles as (
                select mc.volume, mc.high, mc.low, mc.open, mc.close, mc.time
                from invest.minute_candles mc
                where mc.figi = %L
                and date(mc.time at time zone ''Europe/Moscow'') = %L
                and (%s)
            )
            select 
                sum(volume) as minute_volume,
                max(high) as minute_high,
                min(low) as minute_low,
                (select open from filtered_candles order by time asc limit 1) as minute_open,
                (select close from filtered_candles order by time desc limit 1) as minute_close
            from filtered_candles',
            v_daily_record.figi, p_date, v_time_condition
        ) into v_minute_record;
        
        -- Проверяем наличие данных из минутных свечей
        if v_minute_record.minute_volume is null then
            -- Нет данных из минутных свечей - записываем проблему
            insert into invest_candles.data_quality_issues (
                task_id, check_name, entity_type, entity_id, trade_date,
                metric, status, message, details
            ) values (
                v_task_id, 'daily_vs_minute_check', v_instrument_type, v_daily_record.figi, p_date,
                'missing_minute_data', 'ERROR', 
                'No minute candles found for daily candle within trading hours',
                jsonb_build_object(
                    'instrument_type', v_instrument_type,
                    'is_weekend', v_is_weekend,
                    'is_special_hours', coalesce(v_trading_hours.is_special, false),
                    'trading_hours', format('%02s:%02s-%02s:%02s', 
                        v_trading_hours.start_hour::text, v_trading_hours.start_minute::text,
                        v_trading_hours.end_hour::text, v_trading_hours.end_minute::text),
                    'daily_volume', v_daily_record.daily_volume,
                    'daily_high', v_daily_record.daily_high,
                    'daily_low', v_daily_record.daily_low,
                    'daily_open', v_daily_record.daily_open,
                    'daily_close', v_daily_record.daily_close
                )
            );
            v_mismatches := v_mismatches + 1;
        else
            -- Вычисляем разности
            v_diff_volume := coalesce(v_daily_record.daily_volume, 0) - coalesce(v_minute_record.minute_volume, 0);
            v_diff_high := coalesce(v_daily_record.daily_high, 0) - coalesce(v_minute_record.minute_high, 0);
            v_diff_low := coalesce(v_daily_record.daily_low, 0) - coalesce(v_minute_record.minute_low, 0);
            v_diff_open := coalesce(v_daily_record.daily_open, 0) - coalesce(v_minute_record.minute_open, 0);
            v_diff_close := coalesce(v_daily_record.daily_close, 0) - coalesce(v_minute_record.minute_close, 0);
            
            -- Проверяем на несоответствия (допускаем небольшие погрешности)
            if abs(v_diff_volume) > 1 or 
               abs(v_diff_high) > 0.01 or 
               abs(v_diff_low) > 0.01 or 
               abs(v_diff_open) > 0.01 or 
               abs(v_diff_close) > 0.01 then
                
                -- Записываем несоответствие
                insert into invest_candles.data_quality_issues (
                    task_id, check_name, entity_type, entity_id, trade_date,
                    metric, expected_numeric, actual_numeric, diff_numeric, status, message, details
                ) values (
                    v_task_id, 'daily_vs_minute_check', v_instrument_type, v_daily_record.figi, p_date,
                    'volume_mismatch', v_daily_record.daily_volume, v_minute_record.minute_volume, v_diff_volume,
                    case when abs(v_diff_volume) > 1 then 'ERROR' else 'WARNING' end,
                    'Volume mismatch between daily and minute candles within trading hours',
                    jsonb_build_object(
                        'instrument_type', v_instrument_type,
                        'is_weekend', v_is_weekend,
                        'is_special_hours', coalesce(v_trading_hours.is_special, false),
                        'trading_hours', format('%02s:%02s-%02s:%02s', 
                            v_trading_hours.start_hour::text, v_trading_hours.start_minute::text,
                            v_trading_hours.end_hour::text, v_trading_hours.end_minute::text),
                        'daily_volume', v_daily_record.daily_volume,
                        'minute_volume', v_minute_record.minute_volume,
                        'volume_diff', v_diff_volume,
                        'high_diff', v_diff_high,
                        'low_diff', v_diff_low,
                        'open_diff', v_diff_open,
                        'close_diff', v_diff_close
                    )
                );
                v_mismatches := v_mismatches + 1;
            end if;
        end if;
    end loop;
    
    -- Определяем статус и сообщение для логирования
    if v_mismatches = 0 then
        v_log_status := 'SUCCESS';
        v_log_message := 'Daily vs minute check completed successfully. Total rows: ' || v_total_rows || ', Mismatches: ' || v_mismatches;
    else
        v_log_status := 'ERROR';
        v_log_message := 'Daily vs minute check completed with issues. Total rows: ' || v_total_rows || ', Mismatches: ' || v_mismatches;
    end if;
    
    -- Логируем результат в system_logs
    insert into invest.system_logs (
        task_id, endpoint, method, status, message, start_time, end_time, duration_ms
    ) values (
        v_task_id, 
        'data_quality_check', 
        'run_daily_vs_minute_check', 
        v_log_status, 
        v_log_message,
        v_start_time,
        now(),
        extract(epoch from (now() - v_start_time)) * 1000
    );
    
    -- Возвращаем результаты
    return query select v_task_id, v_total_rows, v_mismatches;
end;
$$;

comment on function invest_candles.run_daily_vs_minute_check(date) is 'Проверяет соответствие дневных и минутных свечей с учетом специальных торговых часов, сохраняет результаты в data_quality_issues';

-- Права на функцию
alter function invest_candles.run_daily_vs_minute_check(date) owner to postgres;

-- Создание синонима для функции проверки соответствия дневных и минутных свечей в схеме invest
create or replace function invest.run_daily_vs_minute_check(
    p_date date
)
returns table(task_id text, total_rows bigint, mismatches bigint)
language plpgsql
cost 100
volatile parallel unsafe
rows 1000
as $$
begin
    -- Вызываем оригинальную функцию из схемы invest_candles
    return query select * from invest_candles.run_daily_vs_minute_check(p_date);
end;
$$;

comment on function invest.run_daily_vs_minute_check(date) is 'Синоним для функции invest_candles.run_daily_vs_minute_check - проверяет соответствие дневных и минутных свечей с учетом специальных торговых часов';

-- Права на функцию-синоним
alter function invest.run_daily_vs_minute_check(date) owner to postgres;

-- ============================================================================
-- СИНОНИМЫ И VIEWS В СХЕМЕ INVEST
-- ============================================================================

-- View для специальных торговых часов в схеме invest
create or replace view invest.special_trading_hours as
select 
    sth.id,
    sth.figi,
    sth.instrument_type,
    sth.day_type,
    sth.start_hour,
    sth.start_minute,
    sth.end_hour,
    sth.end_minute,
    sth.description,
    sth.created_by,
    sth.created_at,
    sth.updated_at,
    sth.is_active,
    -- Добавляем информацию об инструменте
    CASE 
        WHEN sth.instrument_type = 'shares' THEN s.name
        WHEN sth.instrument_type = 'futures' THEN f.ticker
        WHEN sth.instrument_type = 'indicatives' THEN i.name
    END AS instrument_name,
    CASE 
        WHEN sth.instrument_type = 'shares' THEN s.ticker
        WHEN sth.instrument_type = 'futures' THEN f.ticker
        WHEN sth.instrument_type = 'indicatives' THEN i.ticker
    END AS instrument_ticker
from invest_candles.special_trading_hours sth
left join invest_ref.shares s on sth.figi = s.figi and sth.instrument_type = 'shares'
left join invest_ref.futures f on sth.figi = f.figi and sth.instrument_type = 'futures'
left join invest_ref.indicatives i on sth.figi = i.figi and sth.instrument_type = 'indicatives';

comment on view invest.special_trading_hours is 'Синоним для таблицы special_trading_hours из схемы invest_candles с дополнительной информацией об инструментах';

-- Устанавливаем владельца view
alter view invest.special_trading_hours owner to postgres;

-- Предоставляем права доступа на view

-- Синоним функции добавления торговых часов в схеме invest
create or replace function invest.add_special_trading_hours(
    p_figi varchar(255),
    p_instrument_type varchar(20),
    p_day_type varchar(20),
    p_start_hour integer,
    p_start_minute integer,
    p_end_hour integer,
    p_end_minute integer,
    p_description text default null,
    p_created_by varchar(255) default null
)
returns bigint
language plpgsql
as $$
begin
    return invest_candles.add_special_trading_hours(
        p_figi, p_instrument_type, p_day_type,
        p_start_hour, p_start_minute, p_end_hour, p_end_minute,
        p_description, p_created_by
    );
end;
$$;

comment on function invest.add_special_trading_hours(varchar, varchar, varchar, integer, integer, integer, integer, text, varchar) is 'Синоним для функции invest_candles.add_special_trading_hours - добавляет специальные торговые часы для инструмента';

alter function invest.add_special_trading_hours(varchar, varchar, varchar, integer, integer, integer, integer, text, varchar) owner to postgres;

-- Синоним функции получения торговых часов в схеме invest
create or replace function invest.get_trading_hours(
    p_figi varchar(255)
)
returns table(
    start_hour integer,
    start_minute integer,
    end_hour integer,
    end_minute integer,
    is_special boolean,
    day_type varchar(20),
    created_at timestamp with time zone
)
language sql
as $$
    select * from invest_candles.get_trading_hours(p_figi);
$$;

comment on function invest.get_trading_hours(varchar) is 'Синоним для функции invest_candles.get_trading_hours - возвращает специальные торговые часы для инструмента по FIGI';

alter function invest.get_trading_hours(varchar) owner to postgres;

-- Синоним функции удаления торговых часов в схеме invest
create or replace function invest.remove_special_trading_hours(
    p_figi varchar(255),
    p_instrument_type varchar(20) default null,
    p_day_type varchar(20) default null
)
returns integer
language plpgsql
as $$
begin
    return invest_candles.remove_special_trading_hours(
        p_figi, p_instrument_type, p_day_type
    );
end;
$$;

comment on function invest.remove_special_trading_hours(varchar, varchar, varchar) is 'Синоним для функции invest_candles.remove_special_trading_hours - удаляет специальные торговые часы для инструмента';

alter function invest.remove_special_trading_hours(varchar, varchar, varchar) owner to postgres;

-- View для анализа паттернов свечей в схеме invest
create or replace view invest.candle_pattern_analysis as
select 
    cpa.id,
    cpa.figi,
    cpa.analysis_date,
    cpa.pattern_start_date,
    cpa.pattern_end_date,
    cpa.candle_type,
    cpa.consecutive_days,
    cpa.avg_volume,
    cpa.avg_price_change,
    cpa.total_price_change,
    cpa.strategy_applicable,
    cpa.created_at,
    -- Добавляем информацию об инструменте
    CASE 
        WHEN s.figi IS NOT NULL THEN s.name
        WHEN f.figi IS NOT NULL THEN f.ticker
        WHEN i.figi IS NOT NULL THEN i.name
    END AS instrument_name,
    CASE 
        WHEN s.figi IS NOT NULL THEN s.ticker
        WHEN f.figi IS NOT NULL THEN f.ticker
        WHEN i.figi IS NOT NULL THEN i.ticker
    END AS instrument_ticker,
    CASE 
        WHEN s.figi IS NOT NULL THEN 'shares'
        WHEN f.figi IS NOT NULL THEN 'futures'
        WHEN i.figi IS NOT NULL THEN 'indicatives'
    END AS instrument_type
from invest_candles.candle_pattern_analysis cpa
left join invest_ref.shares s on cpa.figi = s.figi
left join invest_ref.futures f on cpa.figi = f.figi
left join invest_ref.indicatives i on cpa.figi = i.figi;

comment on view invest.candle_pattern_analysis is 'Синоним для таблицы candle_pattern_analysis из схемы invest_candles с дополнительной информацией об инструментах';

-- Устанавливаем владельца view
alter view invest.candle_pattern_analysis owner to postgres;

-- Синоним функции анализа паттернов свечей в схеме invest
create or replace function invest.analyze_candle_patterns(
    p_analysis_date date, 
    p_consecutive_days integer default 5
)
returns void
language plpgsql
as $$
begin
    perform invest_candles.analyze_candle_patterns(p_analysis_date, p_consecutive_days);
end;
$$;

comment on function invest.analyze_candle_patterns(date, integer) is 'Синоним для функции invest_candles.analyze_candle_patterns - анализирует паттерны свечей с одинаковым типом за N торговых дней подряд, исключая выходные';

alter function invest.analyze_candle_patterns(date, integer) owner to postgres;


-- ============================================================================
-- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ ФУНКЦИЙ ДЛЯ РАБОТЫ СО СПЕЦИАЛЬНЫМИ ТОРГОВЫМИ ЧАСАМИ
-- ============================================================================

-- Пример 1: Добавление специальных торговых часов для акции в будние дни
-- Устанавливаем торговые часы с 10:00 до 18:45 для акции SBER
-- Использование через схему invest_candles:
SELECT invest_candles.add_special_trading_hours(
    p_figi => 'BBG004730N88',                    -- FIGI инструмента SBER
    p_instrument_type => 'shares',                -- Тип инструмента: акция
    p_day_type => 'weekday',                     -- Тип дня: будние дни
    p_start_hour => 10,                          -- Начало торгов: 10:00
    p_start_minute => 0,
    p_end_hour => 18,                            -- Конец торгов: 18:45
    p_end_minute => 45,
    p_description => 'Стандартные торговые часы для акций MOEX',  -- Описание
    p_created_by => 'admin'                      -- Кто создал запись
);

-- Использование через схему invest (синоним):
SELECT invest.add_special_trading_hours(
    'BBG004730N88', 'shares', 'weekday',
    10, 0, 18, 45,
    'Стандартные торговые часы для акций MOEX',
    'admin'
);

-- Пример 2: Добавление специальных торговых часов для фьючерса в выходные дни
-- Устанавливаем торговые часы с 10:00 до 23:50 для фьючерса Si
SELECT invest_candles.add_special_trading_hours(
    'BBG004730ZJ9',                              -- FIGI фьючерса
    'futures',                                   -- Тип: фьючерс
    'weekend',                                   -- Тип дня: выходные
    10,                                          -- Начало: 10:00
    0,
    23,                                          -- Конец: 23:50
    50,
    'Торговые часы для фьючерсов в выходные дни',
    'system'
);

-- Пример 3: Добавление торговых часов для всех дней недели
-- Устанавливаем торговые часы с 9:50 до 19:00 для всех дней
SELECT invest_candles.add_special_trading_hours(
    'BBG004730N88',                              -- FIGI инструмента
    'shares',                                    -- Тип: акция
    'all',                                       -- Тип дня: все дни недели
    9,                                           -- Начало: 9:50
    50,
    19,                                          -- Конец: 19:00
    0,
    'Расширенные торговые часы для всех дней',
    'user'
);

-- Пример 4: Получение всех активных торговых часов для инструмента
-- Возвращает все специальные торговые часы для указанного FIGI
-- Использование через схему invest_candles:
SELECT * FROM invest_candles.get_trading_hours('BBG004730N88');

-- Использование через схему invest (синоним):
SELECT * FROM invest.get_trading_hours('BBG004730N88');

-- Использование через view в схеме invest (с информацией об инструменте):
SELECT * FROM invest.special_trading_hours 
WHERE figi = 'BBG004730N88' AND is_active = true;

-- Пример 5: Получение торговых часов с фильтрацией по типу дня
-- Получаем только торговые часы для будних дней
SELECT * 
FROM invest_candles.get_trading_hours('BBG004730N88')
WHERE day_type = 'weekday';

-- Пример 6: Получение торговых часов с форматированием времени
-- Форматируем время в читаемый вид
SELECT 
    figi,
    instrument_type,
    day_type,
    start_hour || ':' || LPAD(start_minute::text, 2, '0') AS start_time,
    end_hour || ':' || LPAD(end_minute::text, 2, '0') AS end_time,
    description,
    is_active,
    created_at
FROM invest_candles.special_trading_hours
WHERE figi = 'BBG004730N88'
  AND is_active = true
ORDER BY day_type DESC, created_at DESC;

-- Пример 7: Удаление всех специальных торговых часов для инструмента
-- Деактивирует все записи для указанного FIGI независимо от типа инструмента и дня
SELECT invest_candles.remove_special_trading_hours(
    p_figi => 'BBG004730N88',                    -- FIGI инструмента
    p_instrument_type => NULL,                   -- NULL = все типы инструментов
    p_day_type => NULL                           -- NULL = все типы дней
);
-- Возвращает количество деактивированных записей

-- Пример 8: Удаление торговых часов только для акций (shares)
-- Деактивирует только записи для акций, оставляя другие типы инструментов
SELECT invest_candles.remove_special_trading_hours(
    'BBG004730N88',                              -- FIGI инструмента
    'shares',                                    -- Только для акций
    NULL                                         -- Все типы дней
);

-- Пример 9: Удаление торговых часов только для будних дней
-- Деактивирует только записи для будних дней, оставляя выходные
SELECT invest_candles.remove_special_trading_hours(
    'BBG004730N88',                              -- FIGI инструмента
    NULL,                                        -- Все типы инструментов
    'weekday'                                    -- Только будние дни
);

-- Пример 10: Удаление конкретной комбинации (акции + будние дни)
-- Деактивирует только записи для акций в будние дни
SELECT invest_candles.remove_special_trading_hours(
    'BBG004730N88',                              -- FIGI инструмента
    'shares',                                    -- Только акции
    'weekday'                                    -- Только будние дни
);

-- Пример 11: Проверка существования специальных торговых часов перед добавлением
-- Сначала проверяем, есть ли уже активные записи
DO $$
DECLARE
    v_count integer;
    v_id bigint;
BEGIN
    -- Проверяем наличие активных записей
    SELECT COUNT(*) INTO v_count
    FROM invest_candles.special_trading_hours
    WHERE figi = 'BBG004730N88'
      AND instrument_type = 'shares'
      AND day_type = 'weekday'
      AND is_active = true;
    
    IF v_count = 0 THEN
        -- Добавляем, если нет активных записей
        SELECT invest_candles.add_special_trading_hours(
            'BBG004730N88', 'shares', 'weekday',
            10, 0, 18, 45,
            'Первая запись торговых часов',
            'system'
        ) INTO v_id;
        
        RAISE NOTICE 'Добавлена запись с ID: %', v_id;
    ELSE
        RAISE NOTICE 'Уже существует % активных записей', v_count;
    END IF;
END $$;

-- Пример 12: Получение торговых часов с подробной информацией
-- Расширенный запрос с информацией об инструменте
SELECT 
    sth.figi,
    sth.instrument_type,
    sth.day_type,
    sth.start_hour,
    sth.start_minute,
    sth.end_hour,
    sth.end_minute,
    sth.description,
    sth.created_by,
    sth.created_at,
    sth.updated_at,
    sth.is_active,
    CASE 
        WHEN sth.instrument_type = 'shares' THEN s.name
        WHEN sth.instrument_type = 'futures' THEN f.ticker
        WHEN sth.instrument_type = 'indicatives' THEN i.name
    END AS instrument_name
FROM invest_candles.special_trading_hours sth
LEFT JOIN invest_ref.shares s ON sth.figi = s.figi AND sth.instrument_type = 'shares'
LEFT JOIN invest_ref.futures f ON sth.figi = f.figi AND sth.instrument_type = 'futures'
LEFT JOIN invest_ref.indicatives i ON sth.figi = i.figi AND sth.instrument_type = 'indicatives'
WHERE sth.figi = 'BBG004730N88'
  AND sth.is_active = true
ORDER BY sth.day_type DESC, sth.created_at DESC;

-- Пример 13: Массовое добавление торговых часов для нескольких инструментов
-- Используем цикл для добавления часов для списка FIGI
DO $$
DECLARE
    v_figi_list varchar(255)[] := ARRAY['BBG004730N88', 'BBG004730ZJ9', 'BBG0013HJJ31'];
    v_figi varchar(255);
    v_id bigint;
BEGIN
    FOREACH v_figi IN ARRAY v_figi_list
    LOOP
        SELECT invest_candles.add_special_trading_hours(
            v_figi,
            'shares',
            'weekday',
            10, 0, 18, 45,
            'Массовое добавление торговых часов',
            'batch_script'
        ) INTO v_id;
        
        RAISE NOTICE 'Добавлены торговые часы для % с ID: %', v_figi, v_id;
    END LOOP;
END $$;

-- Пример 14: Получение торговых часов только для акций через view в схеме invest
SELECT 
    figi,
    instrument_ticker,
    instrument_name,
    day_type,
    start_hour || ':' || LPAD(start_minute::text, 2, '0') AS start_time,
    end_hour || ':' || LPAD(end_minute::text, 2, '0') AS end_time,
    description,
    is_active
FROM invest.special_trading_hours
WHERE instrument_type = 'shares'
  AND is_active = true
ORDER BY instrument_ticker, day_type DESC;

-- Пример 15: Получение торговых часов только для фьючерсов через view в схеме invest
SELECT 
    figi,
    instrument_ticker,
    day_type,
    start_hour || ':' || LPAD(start_minute::text, 2, '0') AS start_time,
    end_hour || ':' || LPAD(end_minute::text, 2, '0') AS end_time,
    description,
    is_active
FROM invest.special_trading_hours
WHERE instrument_type = 'futures'
  AND is_active = true
ORDER BY instrument_ticker, day_type DESC;

-- Пример 16: Получение торговых часов для конкретной акции с информацией об инструменте
SELECT 
    sth.figi,
    sth.instrument_ticker,
    sth.instrument_name,
    sth.day_type,
    sth.start_hour,
    sth.start_minute,
    sth.end_hour,
    sth.end_minute,
    sth.description,
    sth.created_by,
    sth.created_at,
    s.currency,
    s.exchange
FROM invest.special_trading_hours sth
LEFT JOIN invest_ref.shares s ON sth.figi = s.figi
WHERE sth.figi = 'BBG004730N88'
  AND sth.instrument_type = 'shares'
  AND sth.is_active = true
ORDER BY sth.day_type DESC;

-- Пример 17: Получение торговых часов для конкретного фьючерса с информацией об инструменте
SELECT 
    sth.figi,
    sth.instrument_ticker,
    sth.day_type,
    sth.start_hour,
    sth.start_minute,
    sth.end_hour,
    sth.end_minute,
    sth.description,
    f.basic_asset,
    f.expiration_date,
    f.currency
FROM invest.special_trading_hours sth
LEFT JOIN invest_ref.futures f ON sth.figi = f.figi
WHERE sth.figi = 'BBG004730ZJ9'
  AND sth.instrument_type = 'futures'
  AND sth.is_active = true
ORDER BY sth.day_type DESC;


-- ============================================================================
-- ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ ФУНКЦИЙ ДЛЯ РАБОТЫ С АНАЛИЗОМ ПАТТЕРНОВ СВЕЧЕЙ
-- ============================================================================

-- Пример 1: Запуск анализа паттернов свечей для конкретной даты
-- Использование через схему invest_candles:
SELECT invest_candles.analyze_candle_patterns('2024-01-15'::date, 5);

-- Использование через схему invest (синоним):
SELECT invest.analyze_candle_patterns('2024-01-15'::date, 5);

-- Пример 2: Запуск анализа паттернов свечей с параметром по умолчанию (5 дней)
-- При вызове функции без указания второго параметра используется дефолтное значение p_consecutive_days = 5
-- ВАЖНО: Для избежания ошибки "function is not unique" используйте именованные параметры или явно указывайте тип
-- Анализ на текущую дату с дефолтным количеством дней (5 торговых дней подряд):
-- Вариант 1: Явное указание типа с использованием DEFAULT для второго параметра
SELECT invest.analyze_candle_patterns(p_analysis_date => CURRENT_DATE, p_consecutive_days => DEFAULT);

-- Вариант 2: Явное указание дефолтного значения
SELECT invest.analyze_candle_patterns(CURRENT_DATE, 5);

-- Использование через схему invest_candles с дефолтным значением:
-- ВАЖНО: Используйте именованный параметр для избежания ошибки "function is not unique"
SELECT invest_candles.analyze_candle_patterns(p_analysis_date => '2024-01-15'::date, p_consecutive_days => DEFAULT);

-- Или явно указывайте оба параметра с дефолтным значением:
SELECT invest_candles.analyze_candle_patterns('2024-01-15'::date, 5);

-- Анализ для конкретной даты через синоним invest с дефолтным значением (5 дней):
SELECT invest.analyze_candle_patterns(p_analysis_date => '2024-01-15'::date, p_consecutive_days => DEFAULT);

-- Пример 3: Запуск анализа паттернов свечей для другого количества дней подряд
-- Ищем паттерны с 6 торговыми днями подряд одинакового типа свечи
SELECT invest.analyze_candle_patterns('2024-01-15'::date, 6);

-- Пример 4: Получение всех найденных паттернов через view в схеме invest
-- Получаем все паттерны с информацией об инструментах
SELECT 
    id,
    figi,
    instrument_ticker,
    instrument_name,
    instrument_type,
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
FROM invest.candle_pattern_analysis
ORDER BY analysis_date DESC, created_at DESC;

-- Пример 5: Получение паттернов для конкретного инструмента
-- Получаем все паттерны для акции SBER
SELECT 
    figi,
    instrument_ticker,
    instrument_name,
    analysis_date,
    pattern_start_date,
    pattern_end_date,
    candle_type,
    consecutive_days,
    avg_volume,
    avg_price_change,
    total_price_change,
    strategy_applicable
FROM invest.candle_pattern_analysis
WHERE figi = 'BBG004730N88'
ORDER BY analysis_date DESC, pattern_start_date DESC;

-- Пример 6: Получение только бычьих паттернов (BULLISH)
-- Находим все паттерны с бычьими свечами
SELECT 
    figi,
    instrument_ticker,
    instrument_name,
    analysis_date,
    pattern_start_date,
    pattern_end_date,
    consecutive_days,
    total_price_change,
    strategy_applicable
FROM invest.candle_pattern_analysis
WHERE candle_type = 'BULLISH'
ORDER BY total_price_change DESC;

-- Пример 7: Получение только медвежьих паттернов (BEARISH)
-- Находим все паттерны с медвежьими свечами
SELECT 
    figi,
    instrument_ticker,
    instrument_name,
    analysis_date,
    pattern_start_date,
    pattern_end_date,
    consecutive_days,
    total_price_change,
    strategy_applicable
FROM invest.candle_pattern_analysis
WHERE candle_type = 'BEARISH'
ORDER BY total_price_change ASC;

-- Пример 8: Получение паттернов для конкретной даты анализа
-- Получаем все паттерны, найденные при анализе на определенную дату
SELECT 
    figi,
    instrument_ticker,
    instrument_name,
    pattern_start_date,
    pattern_end_date,
    candle_type,
    consecutive_days,
    avg_volume,
    total_price_change
FROM invest.candle_pattern_analysis
WHERE analysis_date = '2024-01-15'
ORDER BY figi, pattern_start_date;

-- Пример 9: Получение паттернов только для акций
SELECT 
    figi,
    instrument_ticker,
    instrument_name,
    analysis_date,
    pattern_start_date,
    pattern_end_date,
    candle_type,
    consecutive_days,
    total_price_change,
    strategy_applicable
FROM invest.candle_pattern_analysis
WHERE instrument_type = 'shares'
ORDER BY analysis_date DESC, total_price_change DESC;

-- Пример 10: Получение паттернов только для фьючерсов
SELECT 
    figi,
    instrument_ticker,
    analysis_date,
    pattern_start_date,
    pattern_end_date,
    candle_type,
    consecutive_days,
    total_price_change,
    strategy_applicable
FROM invest.candle_pattern_analysis
WHERE instrument_type = 'futures'
ORDER BY analysis_date DESC, total_price_change DESC;

-- Пример 11: Получение паттернов с фильтрацией по применимости стратегии
-- Получаем только те паттерны, для которых стратегия применима
SELECT 
    figi,
    instrument_ticker,
    instrument_name,
    analysis_date,
    pattern_start_date,
    pattern_end_date,
    candle_type,
    consecutive_days,
    total_price_change,
    strategy_applicable
FROM invest.candle_pattern_analysis
WHERE strategy_applicable = 'Y'
ORDER BY analysis_date DESC, total_price_change DESC;

-- Пример 12: Получение паттернов с наибольшим изменением цены
-- Топ-10 паттернов с наибольшим положительным изменением цены
SELECT 
    figi,
    instrument_ticker,
    instrument_name,
    candle_type,
    consecutive_days,
    pattern_start_date,
    pattern_end_date,
    total_price_change,
    avg_price_change,
    avg_volume,
    strategy_applicable
FROM invest.candle_pattern_analysis
WHERE candle_type = 'BULLISH'
ORDER BY total_price_change DESC
LIMIT 10;

-- Пример 13: Получение паттернов с наибольшим отрицательным изменением цены
-- Топ-10 паттернов с наибольшим отрицательным изменением цены
SELECT 
    figi,
    instrument_ticker,
    instrument_name,
    candle_type,
    consecutive_days,
    pattern_start_date,
    pattern_end_date,
    total_price_change,
    avg_price_change,
    avg_volume,
    strategy_applicable
FROM invest.candle_pattern_analysis
WHERE candle_type = 'BEARISH'
ORDER BY total_price_change ASC
LIMIT 10;

-- Пример 14: Получение статистики по паттернам для конкретного инструмента
-- Статистика по всем паттернам для инструмента
SELECT 
    figi,
    instrument_ticker,
    instrument_name,
    COUNT(*) as total_patterns,
    COUNT(*) FILTER (WHERE candle_type = 'BULLISH') as bullish_patterns,
    COUNT(*) FILTER (WHERE candle_type = 'BEARISH') as bearish_patterns,
    AVG(consecutive_days) as avg_consecutive_days,
    MAX(consecutive_days) as max_consecutive_days,
    AVG(total_price_change) as avg_total_price_change,
    SUM(total_price_change) FILTER (WHERE candle_type = 'BULLISH') as total_bullish_change,
    SUM(total_price_change) FILTER (WHERE candle_type = 'BEARISH') as total_bearish_change
FROM invest.candle_pattern_analysis
WHERE figi = 'BBG004730N88'
GROUP BY figi, instrument_ticker, instrument_name;

-- Пример 15: Получение паттернов с дополнительной информацией об инструменте
-- Расширенный запрос с JOIN к таблицам справочников
SELECT 
    cpa.figi,
    cpa.instrument_ticker,
    cpa.instrument_name,
    cpa.candle_type,
    cpa.consecutive_days,
    cpa.pattern_start_date,
    cpa.pattern_end_date,
    cpa.total_price_change,
    cpa.strategy_applicable,
    s.currency,
    s.exchange,
    s.sector
FROM invest.candle_pattern_analysis cpa
LEFT JOIN invest_ref.shares s ON cpa.figi = s.figi
WHERE cpa.instrument_type = 'shares'
  AND cpa.analysis_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY cpa.analysis_date DESC, cpa.total_price_change DESC;

-- Пример 16: Массовый запуск анализа паттернов для нескольких дат
-- Анализ паттернов за последние 7 дней
DO $$
DECLARE
    v_date date;
    v_patterns_count integer;
BEGIN
    FOR v_date IN 
        SELECT generate_series(
            CURRENT_DATE - INTERVAL '7 days',
            CURRENT_DATE - INTERVAL '1 day',
            INTERVAL '1 day'
        )::date
    LOOP
        -- Выполняем анализ только для торговых дней (исключаем выходные)
        IF EXTRACT(dow FROM v_date) NOT IN (0, 6) THEN
            PERFORM invest.analyze_candle_patterns(v_date, 5);
            
            -- Получаем количество найденных паттернов
            SELECT COUNT(*) INTO v_patterns_count
            FROM invest.candle_pattern_analysis
            WHERE analysis_date = v_date;
            
            RAISE NOTICE 'Анализ для даты % завершен. Найдено паттернов: %', v_date, v_patterns_count;
        END IF;
    END LOOP;
END $$;

--Полезные скрипты для проверок:

--Свечной паттерн для фьючерсов и акций
select f.ticker, pa.* from invest_candles.candle_pattern_analysis pa 
join invest_ref.futures f on f.figi = pa.figi;

select s.ticker, pa.* from invest_candles.candle_pattern_analysis pa 
join invest_ref.shares s on s.figi = pa.figi;

--Подсчет количества свечей за день для минутных и дневных свечей
SELECT count(*), date_trunc('day', TIME ) from invest_candles.minute_candles mc
GROUP by date_trunc('day', TIME )
ORDER by date_trunc('day', TIME ) desc

SELECT count(*), date_trunc('day', TIME ) from invest_candles.daily_candles mc
GROUP by date_trunc('day', TIME )
ORDER by date_trunc('day', TIME ) desc