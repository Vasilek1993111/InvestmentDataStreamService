--Цены закрытия основной сессии
create table invest_prices.close_prices
(
    figi            varchar(255)                              not null,
    price_date      date                                      not null,
    close_price     numeric(18, 9)                            not null,
    created_at      timestamp(6) with time zone default now() not null,
    currency        varchar(255)                              not null,
    exchange        varchar(255)                              not null,
    instrument_type varchar(255)                              not null,
    updated_at      timestamp(6) with time zone default now() not null,
    primary key (figi, price_date)
)
    partition by RANGE (price_date);

comment on table invest_prices.close_prices is 'Таблица цен закрытия финансовых инструментов с партиционированием по месяцам';

comment on column invest_prices.close_prices.figi is 'Уникальный идентификатор инструмента (Financial Instrument Global Identifier)';

comment on column invest_prices.close_prices.price_date is 'Дата торгов, за которую зафиксирована цена закрытия';

comment on column invest_prices.close_prices.close_price is 'Цена закрытия инструмента с точностью до 9 знаков после запятой';

comment on column invest_prices.close_prices.created_at is 'Время создания записи в московской таймзоне';

comment on column invest_prices.close_prices.currency is 'Валюта, в которой выражена цена (RUB, USD, EUR и др.)';

comment on column invest_prices.close_prices.exchange is 'Биржа, на которой торгуется инструмент (MOEX, SPB, NASDAQ и др.)';

comment on column invest_prices.close_prices.instrument_type is 'Тип финансового инструмента (share, bond, etf, futures и др.)';

comment on column invest_prices.close_prices.updated_at is 'Время последнего обновления записи в московской таймзоне';

alter table invest_prices.close_prices
    owner to postgres;

create index idx_close_prices_date
    on invest_prices.close_prices (price_date);

create index idx_close_prices_figi_date
    on invest_prices.close_prices (figi, price_date);

-- Создание синонима в схеме invest для удобства использования
create or replace view invest.close_prices as
select 
    figi,
    price_date,
    close_price,
    created_at,
    currency,
    exchange,
    instrument_type,
    updated_at
from invest_prices.close_prices;

comment on view invest.close_prices is 'Синоним для таблицы close_prices из схемы invest_prices';

-- Права доступа на представление
alter view invest.close_prices owner to postgres;

create table invest_prices.close_prices_2024_01
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

alter table invest_prices.close_prices_2024_01
    owner to postgres;

create table invest_prices.close_prices_2024_02
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

alter table invest_prices.close_prices_2024_02
    owner to postgres;


create table invest_prices.close_prices_2024_03
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

alter table invest_prices.close_prices_2024_03
    owner to postgres;


create table invest_prices.close_prices_2024_04
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');

alter table invest_prices.close_prices_2024_04
    owner to postgres;


create table invest_prices.close_prices_2024_05
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');

alter table invest_prices.close_prices_2024_05
    owner to postgres;

create table invest_prices.close_prices_2024_06
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');

alter table invest_prices.close_prices_2024_06
    owner to postgres;

create table invest_prices.close_prices_2024_07
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');

alter table invest_prices.close_prices_2024_07
    owner to postgres;

create table invest_prices.close_prices_2024_08
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');

alter table invest_prices.close_prices_2024_08
    owner to postgres;


create table invest_prices.close_prices_2024_09
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');

alter table invest_prices.close_prices_2024_09
    owner to postgres;


create table invest_prices.close_prices_2024_10
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');

alter table invest_prices.close_prices_2024_10
    owner to postgres;

create table invest_prices.close_prices_2024_11
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');

alter table invest_prices.close_prices_2024_11
    owner to postgres;

create table invest_prices.close_prices_2024_12
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

alter table invest_prices.close_prices_2024_12
    owner to postgres;


create table invest_prices.close_prices_2025_01
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

alter table invest_prices.close_prices_2025_01
    owner to postgres;


create table invest_prices.close_prices_2025_02
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

alter table invest_prices.close_prices_2025_02
    owner to postgres;


create table invest_prices.close_prices_2025_03
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

alter table invest_prices.close_prices_2025_03
    owner to postgres;

create table invest_prices.close_prices_2025_04
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

alter table invest_prices.close_prices_2025_04
    owner to postgres;

create table invest_prices.close_prices_2025_05
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');

alter table invest_prices.close_prices_2025_05
    owner to postgres;

create table invest_prices.close_prices_2025_06
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');

alter table invest_prices.close_prices_2025_06
    owner to postgres;

create table invest_prices.close_prices_2025_07
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');

alter table invest_prices.close_prices_2025_07
    owner to postgres;


create table invest_prices.close_prices_2025_08
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

alter table invest_prices.close_prices_2025_08
    owner to postgres;

create table invest_prices.close_prices_2025_09
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

alter table invest_prices.close_prices_2025_09
    owner to postgres;

create table invest_prices.close_prices_2025_10
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

alter table invest_prices.close_prices_2025_10
    owner to postgres;

create table invest_prices.close_prices_2025_11
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

alter table invest_prices.close_prices_2025_11
    owner to postgres;

create table invest_prices.close_prices_2025_12
    partition of invest_prices.close_prices
        FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

alter table invest_prices.close_prices_2025_12
    owner to postgres;


-- Цена закрытия вечерней сессии
create table invest_prices.close_prices_evening_session
(
    figi            varchar(255)                              not null,
    price_date      date                                      not null,
    close_price     numeric(18, 9)                            not null,
    created_at      timestamp(6) with time zone default now() not null,
    currency        varchar(255),
    exchange        varchar(255),
    instrument_type varchar(255),
    primary key (figi, price_date)
)
    partition by RANGE (price_date);

comment on table invest_prices.close_prices_evening_session is 'Таблица цен закрытия вечерней торговой сессии финансовых инструментов с партиционированием по месяцам';

comment on column invest_prices.close_prices_evening_session.figi is 'Уникальный идентификатор инструмента (Financial Instrument Global Identifier)';

comment on column invest_prices.close_prices_evening_session.price_date is 'Дата торгов, за которую зафиксирована цена закрытия вечерней сессии';

comment on column invest_prices.close_prices_evening_session.close_price is 'Цена закрытия вечерней сессии с точностью до 9 знаков после запятой';

comment on column invest_prices.close_prices_evening_session.created_at is 'Время создания записи в московской таймзоне';

comment on column invest_prices.close_prices_evening_session.currency is 'Валюта, в которой выражена цена (RUB, USD, EUR и др.)';

comment on column invest_prices.close_prices_evening_session.exchange is 'Биржа, на которой торгуется инструмент (MOEX, SPB, NASDAQ и др.)';

comment on column invest_prices.close_prices_evening_session.instrument_type is 'Тип финансового инструмента (share, bond, etf, futures и др.)';

alter table invest_prices.close_prices_evening_session
    owner to postgres;

create index idx_close_prices_evening_date
    on invest_prices.close_prices_evening_session (price_date);

create index idx_close_prices_evening_figi_date
    on invest_prices.close_prices_evening_session (figi, price_date);

create table invest_prices.close_prices_evening_session_2024_01
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

alter table invest_prices.close_prices_evening_session_2024_01
    owner to postgres;


create table invest_prices.close_prices_evening_session_2024_02
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

alter table invest_prices.close_prices_evening_session_2024_02
    owner to postgres;


create table invest_prices.close_prices_evening_session_2024_03
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

alter table invest_prices.close_prices_evening_session_2024_03
    owner to postgres;


create table invest_prices.close_prices_evening_session_2024_04
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');

alter table invest_prices.close_prices_evening_session_2024_04
    owner to postgres;


create table invest_prices.close_prices_evening_session_2024_05
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');

alter table invest_prices.close_prices_evening_session_2024_05
    owner to postgres;


create table invest_prices.close_prices_evening_session_2024_06
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');

alter table invest_prices.close_prices_evening_session_2024_06
    owner to postgres;


create table invest_prices.close_prices_evening_session_2024_07
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');

alter table invest_prices.close_prices_evening_session_2024_07
    owner to postgres;


create table invest_prices.close_prices_evening_session_2024_08
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');

alter table invest_prices.close_prices_evening_session_2024_08
    owner to postgres;

create table invest_prices.close_prices_evening_session_2024_09
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');

alter table invest_prices.close_prices_evening_session_2024_09
    owner to postgres;

create table invest_prices.close_prices_evening_session_2024_10
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');

alter table invest_prices.close_prices_evening_session_2024_10
    owner to postgres;

create table invest_prices.close_prices_evening_session_2024_11
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');

alter table invest_prices.close_prices_evening_session_2024_11
    owner to postgres;

create table invest_prices.close_prices_evening_session_2024_12
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

alter table invest_prices.close_prices_evening_session_2024_12
    owner to postgres;

create table invest_prices.close_prices_evening_session_2025_01
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

alter table invest_prices.close_prices_evening_session_2025_01
    owner to postgres;


create table invest_prices.close_prices_evening_session_2025_02
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

alter table invest_prices.close_prices_evening_session_2025_02
    owner to postgres;

create table invest_prices.close_prices_evening_session_2025_03
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

alter table invest_prices.close_prices_evening_session_2025_03
    owner to postgres;


create table invest_prices.close_prices_evening_session_2025_04
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

alter table invest_prices.close_prices_evening_session_2025_04
    owner to postgres;

create table invest_prices.close_prices_evening_session_2025_05
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');

alter table invest_prices.close_prices_evening_session_2025_05
    owner to postgres;


create table invest_prices.close_prices_evening_session_2025_06
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');

alter table invest_prices.close_prices_evening_session_2025_06
    owner to postgres;


create table invest_prices.close_prices_evening_session_2025_07
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');

alter table invest_prices.close_prices_evening_session_2025_07
    owner to postgres;


create table invest_prices.close_prices_evening_session_2025_08
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

alter table invest_prices.close_prices_evening_session_2025_08
    owner to postgres;


create table invest_prices.close_prices_evening_session_2025_09
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

alter table invest_prices.close_prices_evening_session_2025_09
    owner to postgres;

create table invest_prices.close_prices_evening_session_2025_10
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

alter table invest_prices.close_prices_evening_session_2025_10
    owner to postgres;


create table invest_prices.close_prices_evening_session_2025_11
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

alter table invest_prices.close_prices_evening_session_2025_11
    owner to postgres;


create table invest_prices.close_prices_evening_session_2025_12
    partition of invest_prices.close_prices_evening_session
        FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

alter table invest_prices.close_prices_evening_session_2025_12
    owner to postgres;

-- Создание синонима в схеме invest для удобства использования
create or replace view invest.close_prices_evening_session as
select 
    figi,
    price_date,
    close_price,
    created_at,
    currency,
    exchange,
    instrument_type
from invest_prices.close_prices_evening_session;

comment on view invest.close_prices_evening_session is 'Синоним для таблицы close_prices_evening_session из схемы invest_prices';

-- Права доступа на представление
alter view invest.close_prices_evening_session owner to postgres;

-- Цены открытия
create table invest_prices.open_prices
(
    figi            varchar(255)                not null,
    price_date      date                        not null,
    created_at      timestamp(6) with time zone not null,
    currency        varchar(255)                not null,
    exchange        varchar(255)                not null,
    instrument_type varchar(255)                not null,
    open_price      numeric(18, 9)              not null,
    updated_at      timestamp(6) with time zone not null,
    primary key (figi, price_date)
)
    partition by RANGE (price_date);

comment on table invest_prices.open_prices is 'Открытые цены по инструментам, секционирование по месяцу (price_date)';

comment on column invest_prices.open_prices.figi is 'FIGI инструмента';

comment on column invest_prices.open_prices.price_date is 'Дата (ключ секционирования, границы по месяцам)';

comment on column invest_prices.open_prices.created_at is 'Дата/время создания записи (UTC)';

comment on column invest_prices.open_prices.currency is 'Валюта котировки (например, RUB, USD)';

comment on column invest_prices.open_prices.exchange is 'Биржа (например, MOEX, SPB)';

comment on column invest_prices.open_prices.instrument_type is 'Тип инструмента (SHARE, FUTURE и т.п.)';

comment on column invest_prices.open_prices.open_price is 'Цена открытия за день';

comment on column invest_prices.open_prices.updated_at is 'Дата/время последнего обновления записи (UTC)';

alter table invest_prices.open_prices
    owner to postgres;

create table invest_prices.open_prices_2024_01
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

comment on table invest_prices.open_prices_2024_01 is 'Партиция для 2024-01-01 — 2024-01-31';

alter table invest_prices.open_prices_2024_01
    owner to postgres;


create table invest_prices.open_prices_2024_02
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

comment on table invest_prices.open_prices_2024_02 is 'Партиция для 2024-02-01 — 2024-02-29';

alter table invest_prices.open_prices_2024_02
    owner to postgres;


create table invest_prices.open_prices_2024_03
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

comment on table invest_prices.open_prices_2024_03 is 'Партиция для 2024-03-01 — 2024-03-31';

alter table invest_prices.open_prices_2024_03
    owner to postgres;


create table invest_prices.open_prices_2024_04
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');

comment on table invest_prices.open_prices_2024_04 is 'Партиция для 2024-04-01 — 2024-04-30';

alter table invest_prices.open_prices_2024_04
    owner to postgres;

create table invest_prices.open_prices_2024_05
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');

comment on table invest_prices.open_prices_2024_05 is 'Партиция для 2024-05-01 — 2024-05-31';

alter table invest_prices.open_prices_2024_05
    owner to postgres;

create table invest_prices.open_prices_2024_06
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');

comment on table invest_prices.open_prices_2024_06 is 'Партиция для 2024-06-01 — 2024-06-30';

alter table invest_prices.open_prices_2024_06
    owner to postgres;

create table invest_prices.open_prices_2024_07
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');

comment on table invest_prices.open_prices_2024_07 is 'Партиция для 2024-07-01 — 2024-07-31';

alter table invest_prices.open_prices_2024_07
    owner to postgres;

create table invest_prices.open_prices_2024_08
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');

comment on table invest_prices.open_prices_2024_08 is 'Партиция для 2024-08-01 — 2024-08-31';

alter table invest_prices.open_prices_2024_08
    owner to postgres;

create table invest_prices.open_prices_2024_09
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');

comment on table invest_prices.open_prices_2024_09 is 'Партиция для 2024-09-01 — 2024-09-30';

alter table invest_prices.open_prices_2024_09
    owner to postgres;

create table invest_prices.open_prices_2024_10
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');

comment on table invest_prices.open_prices_2024_10 is 'Партиция для 2024-10-01 — 2024-10-31';

alter table invest_prices.open_prices_2024_10
    owner to postgres;

create table invest_prices.open_prices_2024_11
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');

comment on table invest_prices.open_prices_2024_11 is 'Партиция для 2024-11-01 — 2024-11-30';

alter table invest_prices.open_prices_2024_11
    owner to postgres;

create table invest_prices.open_prices_2024_12
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

comment on table invest_prices.open_prices_2024_12 is 'Партиция для 2024-12-01 — 2024-12-31';

alter table invest_prices.open_prices_2024_12
    owner to postgres;

create table invest_prices.open_prices_2025_01
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

comment on table invest_prices.open_prices_2025_01 is 'Партиция для 2025-01-01 — 2025-01-31';

alter table invest_prices.open_prices_2025_01
    owner to postgres;

create table invest_prices.open_prices_2025_02
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

comment on table invest_prices.open_prices_2025_02 is 'Партиция для 2025-02-01 — 2025-02-28';

alter table invest_prices.open_prices_2025_02
    owner to postgres;

create table invest_prices.open_prices_2025_03
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

comment on table invest_prices.open_prices_2025_03 is 'Партиция для 2025-03-01 — 2025-03-31';

alter table invest_prices.open_prices_2025_03
    owner to postgres;


create table invest_prices.open_prices_2025_04
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

comment on table invest_prices.open_prices_2025_04 is 'Партиция для 2025-04-01 — 2025-04-30';

alter table invest_prices.open_prices_2025_04
    owner to postgres;


create table invest_prices.open_prices_2025_05
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');

comment on table invest_prices.open_prices_2025_05 is 'Партиция для 2025-05-01 — 2025-05-31';

alter table invest_prices.open_prices_2025_05
    owner to postgres;

create table invest_prices.open_prices_2025_06
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');

comment on table invest_prices.open_prices_2025_06 is 'Партиция для 2025-06-01 — 2025-06-30';

alter table invest_prices.open_prices_2025_06
    owner to postgres;


create table invest_prices.open_prices_2025_07
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');

comment on table invest_prices.open_prices_2025_07 is 'Партиция для 2025-07-01 — 2025-07-31';

alter table invest_prices.open_prices_2025_07
    owner to postgres;


create table invest_prices.open_prices_2025_08
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

comment on table invest_prices.open_prices_2025_08 is 'Партиция для 2025-08-01 — 2025-08-31';

alter table invest_prices.open_prices_2025_08
    owner to postgres;


create table invest_prices.open_prices_2025_09
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

comment on table invest_prices.open_prices_2025_09 is 'Партиция для 2025-09-01 — 2025-09-30';

alter table invest_prices.open_prices_2025_09
    owner to postgres;

create table invest_prices.open_prices_2025_10
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

comment on table invest_prices.open_prices_2025_10 is 'Партиция для 2025-10-01 — 2025-10-31';

alter table invest_prices.open_prices_2025_10
    owner to postgres;

create table invest_prices.open_prices_2025_11
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

comment on table invest_prices.open_prices_2025_11 is 'Партиция для 2025-11-01 — 2025-11-30';

alter table invest_prices.open_prices_2025_11
    owner to postgres;

create table invest_prices.open_prices_2025_12
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

comment on table invest_prices.open_prices_2025_12 is 'Партиция для 2025-12-01 — 2025-12-31';

alter table invest_prices.open_prices_2025_12
    owner to postgres;

create table invest_prices.open_prices_2026_01
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

comment on table invest_prices.open_prices_2026_01 is 'Партиция для 2026-01-01 — 2026-01-31';

alter table invest_prices.open_prices_2026_01
    owner to postgres;

create table invest_prices.open_prices_2026_02
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

comment on table invest_prices.open_prices_2026_02 is 'Партиция для 2026-02-01 — 2026-02-28';

alter table invest_prices.open_prices_2026_02
    owner to postgres;

create table invest_prices.open_prices_2026_03
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

comment on table invest_prices.open_prices_2026_03 is 'Партиция для 2026-03-01 — 2026-03-31';

alter table invest_prices.open_prices_2026_03
    owner to postgres;


create table invest_prices.open_prices_2026_04
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

comment on table invest_prices.open_prices_2026_04 is 'Партиция для 2026-04-01 — 2026-04-30';

alter table invest_prices.open_prices_2026_04
    owner to postgres;

create table invest_prices.open_prices_2026_05
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

comment on table invest_prices.open_prices_2026_05 is 'Партиция для 2026-05-01 — 2026-05-31';

alter table invest_prices.open_prices_2026_05
    owner to postgres;

create table invest_prices.open_prices_2026_06
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

comment on table invest_prices.open_prices_2026_06 is 'Партиция для 2026-06-01 — 2026-06-30';

alter table invest_prices.open_prices_2026_06
    owner to postgres;

create table invest_prices.open_prices_2026_07
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');

comment on table invest_prices.open_prices_2026_07 is 'Партиция для 2026-07-01 — 2026-07-31';

alter table invest_prices.open_prices_2026_07
    owner to postgres;

create table invest_prices.open_prices_2026_08
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

comment on table invest_prices.open_prices_2026_08 is 'Партиция для 2026-08-01 — 2026-08-31';

alter table invest_prices.open_prices_2026_08
    owner to postgres;

create table invest_prices.open_prices_2026_09
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');

comment on table invest_prices.open_prices_2026_09 is 'Партиция для 2026-09-01 — 2026-09-30';

alter table invest_prices.open_prices_2026_09
    owner to postgres;


create table invest_prices.open_prices_2026_10
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');

comment on table invest_prices.open_prices_2026_10 is 'Партиция для 2026-10-01 — 2026-10-31';

alter table invest_prices.open_prices_2026_10
    owner to postgres;

create table invest_prices.open_prices_2026_11
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');

comment on table invest_prices.open_prices_2026_11 is 'Партиция для 2026-11-01 — 2026-11-30';

alter table invest_prices.open_prices_2026_11
    owner to postgres;

create table invest_prices.open_prices_2026_12
    partition of invest_prices.open_prices
        FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

comment on table invest_prices.open_prices_2026_12 is 'Партиция для 2026-12-01 — 2026-12-31';

alter table invest_prices.open_prices_2026_12
    owner to postgres;

-- Создание синонима в схеме invest для удобства использования
create or replace view invest.open_prices as
select 
    figi,
    price_date,
    created_at,
    currency,
    exchange,
    instrument_type,
    open_price,
    updated_at
from invest_prices.open_prices;

comment on view invest.open_prices is 'Синоним для таблицы open_prices из схемы invest_prices';

-- Права доступа на представление
alter view invest.open_prices owner to postgres;

-- Цены последних сделок
create table invest_prices.last_prices
(
    figi     varchar(255)   not null,
    time     timestamp(6)   not null,
    currency varchar(255),
    exchange varchar(255),
    price    numeric(18, 9) not null,
    primary key (figi, time)
)
    partition by RANGE ("time");

comment on table invest_prices.last_prices is 'Таблица обезличенных сделок с дневным партиционированием для оптимизации производительности';

comment on column invest_prices.last_prices.figi is 'Уникальный идентификатор финансового инструмента (FIGI)';

comment on column invest_prices.last_prices.time is 'Время совершения сделки (в московском времени)';

comment on column invest_prices.last_prices.currency is 'Валюта инструмента (RUB, USD, EUR и т.д.)';

comment on column invest_prices.last_prices.exchange is 'Биржа, на которой совершена сделка (MOEX, FORTS и т.д.)';

comment on column invest_prices.last_prices.price is 'Цена сделки с точностью до 9 знаков после запятой';

alter table invest_prices.last_prices
    owner to postgres;

-- Создание синонима в схеме invest для удобства использования
create or replace view invest.last_prices as
select 
    figi,
    time,
    currency,
    exchange,
    price
from invest_prices.last_prices;

comment on view invest.last_prices is 'Синоним для таблицы last_prices из схемы invest_prices';

-- Права доступа на представление
alter view invest.last_prices owner to postgres;

create table last_prices_2024_01_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-24 00:00:00') TO ('2024-09-25 00:00:00');

comment on table last_prices_2024_01_14 is 'Партиция сделок за 24.09.2025';

alter table last_prices_2024_01_14
    owner to postgres;


create table last_prices_2024_06_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-01 00:00:00') TO ('2024-06-02 00:00:00');

comment on table last_prices_2024_06_01 is 'Партиция сделок за 01.06.2024';

alter table last_prices_2024_06_01
    owner to postgres;

create table last_prices_2024_06_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-02 00:00:00') TO ('2024-06-03 00:00:00');

comment on table last_prices_2024_06_02 is 'Партиция сделок за 02.06.2024';

alter table last_prices_2024_06_02
    owner to postgres;

create table last_prices_2024_06_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-03 00:00:00') TO ('2024-06-04 00:00:00');

comment on table last_prices_2024_06_03 is 'Партиция сделок за 03.06.2024';

alter table last_prices_2024_06_03
    owner to postgres;


create table last_prices_2024_06_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-04 00:00:00') TO ('2024-06-05 00:00:00');

comment on table last_prices_2024_06_04 is 'Партиция сделок за 04.06.2024';

alter table last_prices_2024_06_04
    owner to postgres;


create table last_prices_2024_06_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-05 00:00:00') TO ('2024-06-06 00:00:00');

comment on table last_prices_2024_06_05 is 'Партиция сделок за 05.06.2024';

alter table last_prices_2024_06_05
    owner to postgres;


create table last_prices_2024_06_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-06 00:00:00') TO ('2024-06-07 00:00:00');

comment on table last_prices_2024_06_06 is 'Партиция сделок за 06.06.2024';

alter table last_prices_2024_06_06
    owner to postgres;


create table last_prices_2024_06_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-07 00:00:00') TO ('2024-06-08 00:00:00');

comment on table last_prices_2024_06_07 is 'Партиция сделок за 07.06.2024';

alter table last_prices_2024_06_07
    owner to postgres;


create table last_prices_2024_06_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-08 00:00:00') TO ('2024-06-09 00:00:00');

comment on table last_prices_2024_06_08 is 'Партиция сделок за 08.06.2024';

alter table last_prices_2024_06_08
    owner to postgres;


create table last_prices_2024_06_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-09 00:00:00') TO ('2024-06-10 00:00:00');

comment on table last_prices_2024_06_09 is 'Партиция сделок за 09.06.2024';

alter table last_prices_2024_06_09
    owner to postgres;

create table last_prices_2024_06_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-10 00:00:00') TO ('2024-06-11 00:00:00');

comment on table last_prices_2024_06_10 is 'Партиция сделок за 10.06.2024';

alter table last_prices_2024_06_10
    owner to postgres;


create table last_prices_2024_06_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-11 00:00:00') TO ('2024-06-12 00:00:00');

comment on table last_prices_2024_06_11 is 'Партиция сделок за 11.06.2024';

alter table last_prices_2024_06_11
    owner to postgres;


create table last_prices_2024_06_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-12 00:00:00') TO ('2024-06-13 00:00:00');

comment on table last_prices_2024_06_12 is 'Партиция сделок за 12.06.2024';

alter table last_prices_2024_06_12
    owner to postgres;


create table last_prices_2024_06_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-13 00:00:00') TO ('2024-06-14 00:00:00');

comment on table last_prices_2024_06_13 is 'Партиция сделок за 13.06.2024';

alter table last_prices_2024_06_13
    owner to postgres;


create table last_prices_2024_06_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-14 00:00:00') TO ('2024-06-15 00:00:00');

comment on table last_prices_2024_06_14 is 'Партиция сделок за 14.06.2024';

alter table last_prices_2024_06_14
    owner to postgres;


create table last_prices_2024_06_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-15 00:00:00') TO ('2024-06-16 00:00:00');

comment on table last_prices_2024_06_15 is 'Партиция сделок за 15.06.2024';

alter table last_prices_2024_06_15
    owner to postgres;


create table last_prices_2024_06_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-16 00:00:00') TO ('2024-06-17 00:00:00');

comment on table last_prices_2024_06_16 is 'Партиция сделок за 16.06.2024';

alter table last_prices_2024_06_16
    owner to postgres;


create table last_prices_2024_06_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-17 00:00:00') TO ('2024-06-18 00:00:00');

comment on table last_prices_2024_06_17 is 'Партиция сделок за 17.06.2024';

alter table last_prices_2024_06_17
    owner to postgres;


create table last_prices_2024_06_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-18 00:00:00') TO ('2024-06-19 00:00:00');

comment on table last_prices_2024_06_18 is 'Партиция сделок за 18.06.2024';

alter table last_prices_2024_06_18
    owner to postgres;


create table last_prices_2024_06_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-19 00:00:00') TO ('2024-06-20 00:00:00');

comment on table last_prices_2024_06_19 is 'Партиция сделок за 19.06.2024';

alter table last_prices_2024_06_19
    owner to postgres;

create table last_prices_2024_06_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-20 00:00:00') TO ('2024-06-21 00:00:00');

comment on table last_prices_2024_06_20 is 'Партиция сделок за 20.06.2024';

alter table last_prices_2024_06_20
    owner to postgres;


create table last_prices_2024_06_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-21 00:00:00') TO ('2024-06-22 00:00:00');

comment on table last_prices_2024_06_21 is 'Партиция сделок за 21.06.2024';

alter table last_prices_2024_06_21
    owner to postgres;


create table last_prices_2024_06_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-22 00:00:00') TO ('2024-06-23 00:00:00');

comment on table last_prices_2024_06_22 is 'Партиция сделок за 22.06.2024';

alter table last_prices_2024_06_22
    owner to postgres;


create table last_prices_2024_06_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-23 00:00:00') TO ('2024-06-24 00:00:00');

comment on table last_prices_2024_06_23 is 'Партиция сделок за 23.06.2024';

alter table last_prices_2024_06_23
    owner to postgres;


create table last_prices_2024_06_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-24 00:00:00') TO ('2024-06-25 00:00:00');

comment on table last_prices_2024_06_24 is 'Партиция сделок за 24.06.2024';

alter table last_prices_2024_06_24
    owner to postgres;


create table last_prices_2024_06_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-25 00:00:00') TO ('2024-06-26 00:00:00');

comment on table last_prices_2024_06_25 is 'Партиция сделок за 25.06.2024';

alter table last_prices_2024_06_25
    owner to postgres;


create table last_prices_2024_06_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-26 00:00:00') TO ('2024-06-27 00:00:00');

comment on table last_prices_2024_06_26 is 'Партиция сделок за 26.06.2024';

alter table last_prices_2024_06_26
    owner to postgres;


create table last_prices_2024_06_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-27 00:00:00') TO ('2024-06-28 00:00:00');

comment on table last_prices_2024_06_27 is 'Партиция сделок за 27.06.2024';

alter table last_prices_2024_06_27
    owner to postgres;


create table last_prices_2024_06_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-28 00:00:00') TO ('2024-06-29 00:00:00');

comment on table last_prices_2024_06_28 is 'Партиция сделок за 28.06.2024';

alter table last_prices_2024_06_28
    owner to postgres;

create table last_prices_2024_06_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-29 00:00:00') TO ('2024-06-30 00:00:00');

comment on table last_prices_2024_06_29 is 'Партиция сделок за 29.06.2024';

alter table last_prices_2024_06_29
    owner to postgres;


create table last_prices_2024_06_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-06-30 00:00:00') TO ('2024-07-01 00:00:00');

comment on table last_prices_2024_06_30 is 'Партиция сделок за 30.06.2024';

alter table last_prices_2024_06_30
    owner to postgres;


create table last_prices_2024_02_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-02-01 00:00:00') TO ('2024-02-02 00:00:00');

comment on table last_prices_2024_02_01 is 'Партиция сделок за 01.02.2024';

alter table last_prices_2024_02_01
    owner to postgres;


create table last_prices_2024_07_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-01 00:00:00') TO ('2024-07-02 00:00:00');

comment on table last_prices_2024_07_01 is 'Партиция сделок за 01.07.2024';

alter table last_prices_2024_07_01
    owner to postgres;


create table last_prices_2024_07_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-02 00:00:00') TO ('2024-07-03 00:00:00');

comment on table last_prices_2024_07_02 is 'Партиция сделок за 02.07.2024';

alter table last_prices_2024_07_02
    owner to postgres;

 

 create table last_prices_2024_07_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-03 00:00:00') TO ('2024-07-04 00:00:00');

comment on table last_prices_2024_07_03 is 'Партиция сделок за 03.07.2024';

alter table last_prices_2024_07_03
    owner to postgres;

 

 create table last_prices_2024_07_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-04 00:00:00') TO ('2024-07-05 00:00:00');

comment on table last_prices_2024_07_04 is 'Партиция сделок за 04.07.2024';

alter table last_prices_2024_07_04
    owner to postgres;

 

 create table last_prices_2024_07_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-05 00:00:00') TO ('2024-07-06 00:00:00');

comment on table last_prices_2024_07_05 is 'Партиция сделок за 05.07.2024';

alter table last_prices_2024_07_05
    owner to postgres;

 

 create table last_prices_2024_07_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-06 00:00:00') TO ('2024-07-07 00:00:00');

comment on table last_prices_2024_07_06 is 'Партиция сделок за 06.07.2024';

alter table last_prices_2024_07_06
    owner to postgres;

 create table last_prices_2024_07_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-07 00:00:00') TO ('2024-07-08 00:00:00');

comment on table last_prices_2024_07_07 is 'Партиция сделок за 07.07.2024';

alter table last_prices_2024_07_07
    owner to postgres;


 create table last_prices_2024_07_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-08 00:00:00') TO ('2024-07-09 00:00:00');

comment on table last_prices_2024_07_08 is 'Партиция сделок за 08.07.2024';

alter table last_prices_2024_07_08
    owner to postgres;


 create table last_prices_2024_07_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-09 00:00:00') TO ('2024-07-10 00:00:00');

comment on table last_prices_2024_07_09 is 'Партиция сделок за 09.07.2024';

alter table last_prices_2024_07_09
    owner to postgres;


 create table last_prices_2024_07_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-10 00:00:00') TO ('2024-07-11 00:00:00');

comment on table last_prices_2024_07_10 is 'Партиция сделок за 10.07.2024';

alter table last_prices_2024_07_10
    owner to postgres;

 create table last_prices_2024_07_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-11 00:00:00') TO ('2024-07-12 00:00:00');

comment on table last_prices_2024_07_11 is 'Партиция сделок за 11.07.2024';

alter table last_prices_2024_07_11
    owner to postgres;

 create table last_prices_2024_07_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-12 00:00:00') TO ('2024-07-13 00:00:00');

comment on table last_prices_2024_07_12 is 'Партиция сделок за 12.07.2024';

alter table last_prices_2024_07_12
    owner to postgres;


 create table last_prices_2024_07_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-13 00:00:00') TO ('2024-07-14 00:00:00');

comment on table last_prices_2024_07_13 is 'Партиция сделок за 13.07.2024';

alter table last_prices_2024_07_13
    owner to postgres;

 create table last_prices_2024_07_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-14 00:00:00') TO ('2024-07-15 00:00:00');

comment on table last_prices_2024_07_14 is 'Партиция сделок за 14.07.2024';

alter table last_prices_2024_07_14
    owner to postgres;

 create table last_prices_2024_07_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-15 00:00:00') TO ('2024-07-16 00:00:00');

comment on table last_prices_2024_07_15 is 'Партиция сделок за 15.07.2024';

alter table last_prices_2024_07_15
    owner to postgres;

 create table last_prices_2024_07_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-16 00:00:00') TO ('2024-07-17 00:00:00');

comment on table last_prices_2024_07_16 is 'Партиция сделок за 16.07.2024';

alter table last_prices_2024_07_16
    owner to postgres;

 

 create table last_prices_2024_07_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-17 00:00:00') TO ('2024-07-18 00:00:00');

comment on table last_prices_2024_07_17 is 'Партиция сделок за 17.07.2024';

alter table last_prices_2024_07_17
    owner to postgres;

 

 create table last_prices_2024_07_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-18 00:00:00') TO ('2024-07-19 00:00:00');

comment on table last_prices_2024_07_18 is 'Партиция сделок за 18.07.2024';

alter table last_prices_2024_07_18
    owner to postgres;

 

 create table last_prices_2024_07_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-19 00:00:00') TO ('2024-07-20 00:00:00');

comment on table last_prices_2024_07_19 is 'Партиция сделок за 19.07.2024';

alter table last_prices_2024_07_19
    owner to postgres;

 

 create table last_prices_2024_07_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-20 00:00:00') TO ('2024-07-21 00:00:00');

comment on table last_prices_2024_07_20 is 'Партиция сделок за 20.07.2024';

alter table last_prices_2024_07_20
    owner to postgres;

 

 create table last_prices_2024_07_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-21 00:00:00') TO ('2024-07-22 00:00:00');

comment on table last_prices_2024_07_21 is 'Партиция сделок за 21.07.2024';

alter table last_prices_2024_07_21
    owner to postgres;

 

 create table last_prices_2024_07_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-22 00:00:00') TO ('2024-07-23 00:00:00');

comment on table last_prices_2024_07_22 is 'Партиция сделок за 22.07.2024';

alter table last_prices_2024_07_22
    owner to postgres;

 

 create table last_prices_2024_07_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-23 00:00:00') TO ('2024-07-24 00:00:00');

comment on table last_prices_2024_07_23 is 'Партиция сделок за 23.07.2024';

alter table last_prices_2024_07_23
    owner to postgres;

 

 create table last_prices_2024_07_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-24 00:00:00') TO ('2024-07-25 00:00:00');

comment on table last_prices_2024_07_24 is 'Партиция сделок за 24.07.2024';

alter table last_prices_2024_07_24
    owner to postgres;

 

 create table last_prices_2024_07_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-25 00:00:00') TO ('2024-07-26 00:00:00');

comment on table last_prices_2024_07_25 is 'Партиция сделок за 25.07.2024';

alter table last_prices_2024_07_25
    owner to postgres;

 

 create table last_prices_2024_07_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-26 00:00:00') TO ('2024-07-27 00:00:00');

comment on table last_prices_2024_07_26 is 'Партиция сделок за 26.07.2024';

alter table last_prices_2024_07_26
    owner to postgres;

 

 create table last_prices_2024_07_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-27 00:00:00') TO ('2024-07-28 00:00:00');

comment on table last_prices_2024_07_27 is 'Партиция сделок за 27.07.2024';

alter table last_prices_2024_07_27
    owner to postgres;

 

 create table last_prices_2024_07_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-28 00:00:00') TO ('2024-07-29 00:00:00');

comment on table last_prices_2024_07_28 is 'Партиция сделок за 28.07.2024';

alter table last_prices_2024_07_28
    owner to postgres;

 

 create table last_prices_2024_07_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-29 00:00:00') TO ('2024-07-30 00:00:00');

comment on table last_prices_2024_07_29 is 'Партиция сделок за 29.07.2024';

alter table last_prices_2024_07_29
    owner to postgres;

 

 create table last_prices_2024_07_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-30 00:00:00') TO ('2024-07-31 00:00:00');

comment on table last_prices_2024_07_30 is 'Партиция сделок за 30.07.2024';

alter table last_prices_2024_07_30
    owner to postgres;

 

 create table last_prices_2024_07_31
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-07-31 00:00:00') TO ('2024-08-01 00:00:00');

comment on table last_prices_2024_07_31 is 'Партиция сделок за 31.07.2024';

alter table last_prices_2024_07_31
    owner to postgres;

 

 create table last_prices_2024_08_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-01 00:00:00') TO ('2024-08-02 00:00:00');

comment on table last_prices_2024_08_01 is 'Партиция сделок за 01.08.2024';

alter table last_prices_2024_08_01
    owner to postgres;

 

 create table last_prices_2024_08_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-02 00:00:00') TO ('2024-08-03 00:00:00');

comment on table last_prices_2024_08_02 is 'Партиция сделок за 02.08.2024';

alter table last_prices_2024_08_02
    owner to postgres;

 

 create table last_prices_2024_08_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-03 00:00:00') TO ('2024-08-04 00:00:00');

comment on table last_prices_2024_08_03 is 'Партиция сделок за 03.08.2024';

alter table last_prices_2024_08_03
    owner to postgres;

 

 create table last_prices_2024_08_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-04 00:00:00') TO ('2024-08-05 00:00:00');

comment on table last_prices_2024_08_04 is 'Партиция сделок за 04.08.2024';

alter table last_prices_2024_08_04
    owner to postgres;

 

 create table last_prices_2024_08_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-05 00:00:00') TO ('2024-08-06 00:00:00');

comment on table last_prices_2024_08_05 is 'Партиция сделок за 05.08.2024';

alter table last_prices_2024_08_05
    owner to postgres;

 

 create table last_prices_2024_08_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-06 00:00:00') TO ('2024-08-07 00:00:00');

comment on table last_prices_2024_08_06 is 'Партиция сделок за 06.08.2024';

alter table last_prices_2024_08_06
    owner to postgres;

 

 create table last_prices_2024_08_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-07 00:00:00') TO ('2024-08-08 00:00:00');

comment on table last_prices_2024_08_07 is 'Партиция сделок за 07.08.2024';

alter table last_prices_2024_08_07
    owner to postgres;

 

 create table last_prices_2024_08_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-08 00:00:00') TO ('2024-08-09 00:00:00');

comment on table last_prices_2024_08_08 is 'Партиция сделок за 08.08.2024';

alter table last_prices_2024_08_08
    owner to postgres;

 

 create table last_prices_2024_08_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-09 00:00:00') TO ('2024-08-10 00:00:00');

comment on table last_prices_2024_08_09 is 'Партиция сделок за 09.08.2024';

alter table last_prices_2024_08_09
    owner to postgres;

 

 create table last_prices_2024_08_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-10 00:00:00') TO ('2024-08-11 00:00:00');

comment on table last_prices_2024_08_10 is 'Партиция сделок за 10.08.2024';

alter table last_prices_2024_08_10
    owner to postgres;

 

 create table last_prices_2024_08_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-11 00:00:00') TO ('2024-08-12 00:00:00');

comment on table last_prices_2024_08_11 is 'Партиция сделок за 11.08.2024';

alter table last_prices_2024_08_11
    owner to postgres;

 

 create table last_prices_2024_08_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-12 00:00:00') TO ('2024-08-13 00:00:00');

comment on table last_prices_2024_08_12 is 'Партиция сделок за 12.08.2024';

alter table last_prices_2024_08_12
    owner to postgres;

 

 create table last_prices_2024_08_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-13 00:00:00') TO ('2024-08-14 00:00:00');

comment on table last_prices_2024_08_13 is 'Партиция сделок за 13.08.2024';

alter table last_prices_2024_08_13
    owner to postgres;

 

 create table last_prices_2024_08_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-14 00:00:00') TO ('2024-08-15 00:00:00');

comment on table last_prices_2024_08_14 is 'Партиция сделок за 14.08.2024';

alter table last_prices_2024_08_14
    owner to postgres;

 

 create table last_prices_2024_08_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-15 00:00:00') TO ('2024-08-16 00:00:00');

comment on table last_prices_2024_08_15 is 'Партиция сделок за 15.08.2024';

alter table last_prices_2024_08_15
    owner to postgres;

 

 create table last_prices_2024_08_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-16 00:00:00') TO ('2024-08-17 00:00:00');

comment on table last_prices_2024_08_16 is 'Партиция сделок за 16.08.2024';

alter table last_prices_2024_08_16
    owner to postgres;

 

 create table last_prices_2024_08_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-17 00:00:00') TO ('2024-08-18 00:00:00');

comment on table last_prices_2024_08_17 is 'Партиция сделок за 17.08.2024';

alter table last_prices_2024_08_17
    owner to postgres;

 

 create table last_prices_2024_08_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-18 00:00:00') TO ('2024-08-19 00:00:00');

comment on table last_prices_2024_08_18 is 'Партиция сделок за 18.08.2024';

alter table last_prices_2024_08_18
    owner to postgres;

 

 create table last_prices_2024_08_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-19 00:00:00') TO ('2024-08-20 00:00:00');

comment on table last_prices_2024_08_19 is 'Партиция сделок за 19.08.2024';

alter table last_prices_2024_08_19
    owner to postgres;

 

 create table last_prices_2024_08_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-20 00:00:00') TO ('2024-08-21 00:00:00');

comment on table last_prices_2024_08_20 is 'Партиция сделок за 20.08.2024';

alter table last_prices_2024_08_20
    owner to postgres;

 

 create table last_prices_2024_08_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-21 00:00:00') TO ('2024-08-22 00:00:00');

comment on table last_prices_2024_08_21 is 'Партиция сделок за 21.08.2024';

alter table last_prices_2024_08_21
    owner to postgres;

 

 create table last_prices_2024_08_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-22 00:00:00') TO ('2024-08-23 00:00:00');

comment on table last_prices_2024_08_22 is 'Партиция сделок за 22.08.2024';

alter table last_prices_2024_08_22
    owner to postgres;

 

 create table last_prices_2024_08_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-23 00:00:00') TO ('2024-08-24 00:00:00');

comment on table last_prices_2024_08_23 is 'Партиция сделок за 23.08.2024';

alter table last_prices_2024_08_23
    owner to postgres;

 

 create table last_prices_2024_08_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-24 00:00:00') TO ('2024-08-25 00:00:00');

comment on table last_prices_2024_08_24 is 'Партиция сделок за 24.08.2024';

alter table last_prices_2024_08_24
    owner to postgres;

 

 create table last_prices_2024_08_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-25 00:00:00') TO ('2024-08-26 00:00:00');

comment on table last_prices_2024_08_25 is 'Партиция сделок за 25.08.2024';

alter table last_prices_2024_08_25
    owner to postgres;

 

 create table last_prices_2024_08_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-26 00:00:00') TO ('2024-08-27 00:00:00');

comment on table last_prices_2024_08_26 is 'Партиция сделок за 26.08.2024';

alter table last_prices_2024_08_26
    owner to postgres;

 

 create table last_prices_2024_08_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-27 00:00:00') TO ('2024-08-28 00:00:00');

comment on table last_prices_2024_08_27 is 'Партиция сделок за 27.08.2024';

alter table last_prices_2024_08_27
    owner to postgres;

 

 create table last_prices_2024_08_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-28 00:00:00') TO ('2024-08-29 00:00:00');

comment on table last_prices_2024_08_28 is 'Партиция сделок за 28.08.2024';

alter table last_prices_2024_08_28
    owner to postgres;

 

 create table last_prices_2024_08_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-29 00:00:00') TO ('2024-08-30 00:00:00');

comment on table last_prices_2024_08_29 is 'Партиция сделок за 29.08.2024';

alter table last_prices_2024_08_29
    owner to postgres;

 

 create table last_prices_2024_08_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-30 00:00:00') TO ('2024-08-31 00:00:00');

comment on table last_prices_2024_08_30 is 'Партиция сделок за 30.08.2024';

alter table last_prices_2024_08_30
    owner to postgres;

 

 create table last_prices_2024_08_31
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-08-31 00:00:00') TO ('2024-09-01 00:00:00');

comment on table last_prices_2024_08_31 is 'Партиция сделок за 31.08.2024';

alter table last_prices_2024_08_31
    owner to postgres;

 

 create table last_prices_2024_09_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-01 00:00:00') TO ('2024-09-02 00:00:00');

comment on table last_prices_2024_09_01 is 'Партиция сделок за 01.09.2024';

alter table last_prices_2024_09_01
    owner to postgres;

 

 create table last_prices_2024_09_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-02 00:00:00') TO ('2024-09-03 00:00:00');

comment on table last_prices_2024_09_02 is 'Партиция сделок за 02.09.2024';

alter table last_prices_2024_09_02
    owner to postgres;

 

 create table last_prices_2024_09_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-03 00:00:00') TO ('2024-09-04 00:00:00');

comment on table last_prices_2024_09_03 is 'Партиция сделок за 03.09.2024';

alter table last_prices_2024_09_03
    owner to postgres;

 

 create table last_prices_2024_09_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-04 00:00:00') TO ('2024-09-05 00:00:00');

comment on table last_prices_2024_09_04 is 'Партиция сделок за 04.09.2024';

alter table last_prices_2024_09_04
    owner to postgres;

 

 create table last_prices_2024_09_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-05 00:00:00') TO ('2024-09-06 00:00:00');

comment on table last_prices_2024_09_05 is 'Партиция сделок за 05.09.2024';

alter table last_prices_2024_09_05
    owner to postgres;

 

 create table last_prices_2024_09_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-06 00:00:00') TO ('2024-09-07 00:00:00');

comment on table last_prices_2024_09_06 is 'Партиция сделок за 06.09.2024';

alter table last_prices_2024_09_06
    owner to postgres;

 

 create table last_prices_2024_09_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-07 00:00:00') TO ('2024-09-08 00:00:00');

comment on table last_prices_2024_09_07 is 'Партиция сделок за 07.09.2024';

alter table last_prices_2024_09_07
    owner to postgres;

 

 create table last_prices_2024_09_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-08 00:00:00') TO ('2024-09-09 00:00:00');

comment on table last_prices_2024_09_08 is 'Партиция сделок за 08.09.2024';

alter table last_prices_2024_09_08
    owner to postgres;

 

 create table last_prices_2024_09_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-09 00:00:00') TO ('2024-09-10 00:00:00');

comment on table last_prices_2024_09_09 is 'Партиция сделок за 09.09.2024';

alter table last_prices_2024_09_09
    owner to postgres;

 

 create table last_prices_2024_09_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-10 00:00:00') TO ('2024-09-11 00:00:00');

comment on table last_prices_2024_09_10 is 'Партиция сделок за 10.09.2024';

alter table last_prices_2024_09_10
    owner to postgres;

 

 create table last_prices_2024_09_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-11 00:00:00') TO ('2024-09-12 00:00:00');

comment on table last_prices_2024_09_11 is 'Партиция сделок за 11.09.2024';

alter table last_prices_2024_09_11
    owner to postgres;

 

 create table last_prices_2024_09_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-12 00:00:00') TO ('2024-09-13 00:00:00');

comment on table last_prices_2024_09_12 is 'Партиция сделок за 12.09.2024';

alter table last_prices_2024_09_12
    owner to postgres;

 

 create table last_prices_2024_09_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-13 00:00:00') TO ('2024-09-14 00:00:00');

comment on table last_prices_2024_09_13 is 'Партиция сделок за 13.09.2024';

alter table last_prices_2024_09_13
    owner to postgres;

 

 create table last_prices_2024_09_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-14 00:00:00') TO ('2024-09-15 00:00:00');

comment on table last_prices_2024_09_14 is 'Партиция сделок за 14.09.2024';

alter table last_prices_2024_09_14
    owner to postgres;

 

 create table last_prices_2024_09_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-15 00:00:00') TO ('2024-09-16 00:00:00');

comment on table last_prices_2024_09_15 is 'Партиция сделок за 15.09.2024';

alter table last_prices_2024_09_15
    owner to postgres;

 

 create table last_prices_2024_09_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-16 00:00:00') TO ('2024-09-17 00:00:00');

comment on table last_prices_2024_09_16 is 'Партиция сделок за 16.09.2024';

alter table last_prices_2024_09_16
    owner to postgres;

 

 create table last_prices_2024_09_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-17 00:00:00') TO ('2024-09-18 00:00:00');

comment on table last_prices_2024_09_17 is 'Партиция сделок за 17.09.2024';

alter table last_prices_2024_09_17
    owner to postgres;

 

 create table last_prices_2024_09_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-18 00:00:00') TO ('2024-09-19 00:00:00');

comment on table last_prices_2024_09_18 is 'Партиция сделок за 18.09.2024';

alter table last_prices_2024_09_18
    owner to postgres;

 

 create table last_prices_2024_09_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-19 00:00:00') TO ('2024-09-20 00:00:00');

comment on table last_prices_2024_09_19 is 'Партиция сделок за 19.09.2024';

alter table last_prices_2024_09_19
    owner to postgres;

 

 create table last_prices_2024_09_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-20 00:00:00') TO ('2024-09-21 00:00:00');

comment on table last_prices_2024_09_20 is 'Партиция сделок за 20.09.2024';

alter table last_prices_2024_09_20
    owner to postgres;

 

 create table last_prices_2024_09_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-21 00:00:00') TO ('2024-09-22 00:00:00');

comment on table last_prices_2024_09_21 is 'Партиция сделок за 21.09.2024';

alter table last_prices_2024_09_21
    owner to postgres;

 

 create table last_prices_2024_09_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-22 00:00:00') TO ('2024-09-23 00:00:00');

comment on table last_prices_2024_09_22 is 'Партиция сделок за 22.09.2024';

alter table last_prices_2024_09_22
    owner to postgres;

 

 create table last_prices_2024_09_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-23 00:00:00') TO ('2024-09-24 00:00:00');

comment on table last_prices_2024_09_23 is 'Партиция сделок за 23.09.2024';

alter table last_prices_2024_09_23
    owner to postgres;

 

 create table last_prices_2024_09_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-25 00:00:00') TO ('2024-09-26 00:00:00');

comment on table last_prices_2024_09_25 is 'Партиция сделок за 25.09.2024';

alter table last_prices_2024_09_25
    owner to postgres;

 

 create table last_prices_2024_09_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-26 00:00:00') TO ('2024-09-27 00:00:00');

comment on table last_prices_2024_09_26 is 'Партиция сделок за 26.09.2024';

alter table last_prices_2024_09_26
    owner to postgres;

 

 create table last_prices_2024_09_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-27 00:00:00') TO ('2024-09-28 00:00:00');

comment on table last_prices_2024_09_27 is 'Партиция сделок за 27.09.2024';

alter table last_prices_2024_09_27
    owner to postgres;

 

 create table last_prices_2024_09_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-28 00:00:00') TO ('2024-09-29 00:00:00');

comment on table last_prices_2024_09_28 is 'Партиция сделок за 28.09.2024';

alter table last_prices_2024_09_28
    owner to postgres;

 

 create table last_prices_2024_09_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-29 00:00:00') TO ('2024-09-30 00:00:00');

comment on table last_prices_2024_09_29 is 'Партиция сделок за 29.09.2024';

alter table last_prices_2024_09_29
    owner to postgres;

 

 create table last_prices_2024_09_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-09-30 00:00:00') TO ('2024-10-01 00:00:00');

comment on table last_prices_2024_09_30 is 'Партиция сделок за 30.09.2024';

alter table last_prices_2024_09_30
    owner to postgres;

 

 create table last_prices_2024_10_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-01 00:00:00') TO ('2024-10-02 00:00:00');

comment on table last_prices_2024_10_01 is 'Партиция сделок за 01.10.2024';

alter table last_prices_2024_10_01
    owner to postgres;

 

 create table last_prices_2024_10_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-02 00:00:00') TO ('2024-10-03 00:00:00');

comment on table last_prices_2024_10_02 is 'Партиция сделок за 02.10.2024';

alter table last_prices_2024_10_02
    owner to postgres;

 

 create table last_prices_2024_10_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-03 00:00:00') TO ('2024-10-04 00:00:00');

comment on table last_prices_2024_10_03 is 'Партиция сделок за 03.10.2024';

alter table last_prices_2024_10_03
    owner to postgres;

 

 create table last_prices_2024_10_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-04 00:00:00') TO ('2024-10-05 00:00:00');

comment on table last_prices_2024_10_04 is 'Партиция сделок за 04.10.2024';

alter table last_prices_2024_10_04
    owner to postgres;

 

 create table last_prices_2024_10_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-05 00:00:00') TO ('2024-10-06 00:00:00');

comment on table last_prices_2024_10_05 is 'Партиция сделок за 05.10.2024';

alter table last_prices_2024_10_05
    owner to postgres;

 

 create table last_prices_2024_10_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-06 00:00:00') TO ('2024-10-07 00:00:00');

comment on table last_prices_2024_10_06 is 'Партиция сделок за 06.10.2024';

alter table last_prices_2024_10_06
    owner to postgres;

 

 create table last_prices_2024_10_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-07 00:00:00') TO ('2024-10-08 00:00:00');

comment on table last_prices_2024_10_07 is 'Партиция сделок за 07.10.2024';

alter table last_prices_2024_10_07
    owner to postgres;

 

 create table last_prices_2024_10_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-08 00:00:00') TO ('2024-10-09 00:00:00');

comment on table last_prices_2024_10_08 is 'Партиция сделок за 08.10.2024';

alter table last_prices_2024_10_08
    owner to postgres;

 

 create table last_prices_2024_10_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-09 00:00:00') TO ('2024-10-10 00:00:00');

comment on table last_prices_2024_10_09 is 'Партиция сделок за 09.10.2024';

alter table last_prices_2024_10_09
    owner to postgres;

 

 create table last_prices_2024_10_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-10 00:00:00') TO ('2024-10-11 00:00:00');

comment on table last_prices_2024_10_10 is 'Партиция сделок за 10.10.2024';

alter table last_prices_2024_10_10
    owner to postgres;

 

 create table last_prices_2024_10_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-11 00:00:00') TO ('2024-10-12 00:00:00');

comment on table last_prices_2024_10_11 is 'Партиция сделок за 11.10.2024';

alter table last_prices_2024_10_11
    owner to postgres;

 

 create table last_prices_2024_10_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-12 00:00:00') TO ('2024-10-13 00:00:00');

comment on table last_prices_2024_10_12 is 'Партиция сделок за 12.10.2024';

alter table last_prices_2024_10_12
    owner to postgres;

 

 create table last_prices_2024_10_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-13 00:00:00') TO ('2024-10-14 00:00:00');

comment on table last_prices_2024_10_13 is 'Партиция сделок за 13.10.2024';

alter table last_prices_2024_10_13
    owner to postgres;

 

 create table last_prices_2024_10_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-14 00:00:00') TO ('2024-10-15 00:00:00');

comment on table last_prices_2024_10_14 is 'Партиция сделок за 14.10.2024';

alter table last_prices_2024_10_14
    owner to postgres;

 

 create table last_prices_2024_10_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-15 00:00:00') TO ('2024-10-16 00:00:00');

comment on table last_prices_2024_10_15 is 'Партиция сделок за 15.10.2024';

alter table last_prices_2024_10_15
    owner to postgres;

 

 create table last_prices_2024_10_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-16 00:00:00') TO ('2024-10-17 00:00:00');

comment on table last_prices_2024_10_16 is 'Партиция сделок за 16.10.2024';

alter table last_prices_2024_10_16
    owner to postgres;

 

 create table last_prices_2024_10_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-17 00:00:00') TO ('2024-10-18 00:00:00');

comment on table last_prices_2024_10_17 is 'Партиция сделок за 17.10.2024';

alter table last_prices_2024_10_17
    owner to postgres;

 

 create table last_prices_2024_10_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-18 00:00:00') TO ('2024-10-19 00:00:00');

comment on table last_prices_2024_10_18 is 'Партиция сделок за 18.10.2024';

alter table last_prices_2024_10_18
    owner to postgres;

 

 create table last_prices_2024_10_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-19 00:00:00') TO ('2024-10-20 00:00:00');

comment on table last_prices_2024_10_19 is 'Партиция сделок за 19.10.2024';

alter table last_prices_2024_10_19
    owner to postgres;

 

 create table last_prices_2024_10_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-20 00:00:00') TO ('2024-10-21 00:00:00');

comment on table last_prices_2024_10_20 is 'Партиция сделок за 20.10.2024';

alter table last_prices_2024_10_20
    owner to postgres;

 

 create table last_prices_2024_10_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-21 00:00:00') TO ('2024-10-22 00:00:00');

comment on table last_prices_2024_10_21 is 'Партиция сделок за 21.10.2024';

alter table last_prices_2024_10_21
    owner to postgres;

 

 create table last_prices_2024_10_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-22 00:00:00') TO ('2024-10-23 00:00:00');

comment on table last_prices_2024_10_22 is 'Партиция сделок за 22.10.2024';

alter table last_prices_2024_10_22
    owner to postgres;

 

 create table last_prices_2024_10_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-23 00:00:00') TO ('2024-10-24 00:00:00');

comment on table last_prices_2024_10_23 is 'Партиция сделок за 23.10.2024';

alter table last_prices_2024_10_23
    owner to postgres;

 

 create table last_prices_2024_10_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-24 00:00:00') TO ('2024-10-25 00:00:00');

comment on table last_prices_2024_10_24 is 'Партиция сделок за 24.10.2024';

alter table last_prices_2024_10_24
    owner to postgres;

 

 create table last_prices_2024_10_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-25 00:00:00') TO ('2024-10-26 00:00:00');

comment on table last_prices_2024_10_25 is 'Партиция сделок за 25.10.2024';

alter table last_prices_2024_10_25
    owner to postgres;

 

 create table last_prices_2024_10_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-26 00:00:00') TO ('2024-10-27 00:00:00');

comment on table last_prices_2024_10_26 is 'Партиция сделок за 26.10.2024';

alter table last_prices_2024_10_26
    owner to postgres;

 

 create table last_prices_2024_10_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-27 00:00:00') TO ('2024-10-28 00:00:00');

comment on table last_prices_2024_10_27 is 'Партиция сделок за 27.10.2024';

alter table last_prices_2024_10_27
    owner to postgres;

 

 create table last_prices_2024_10_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-28 00:00:00') TO ('2024-10-29 00:00:00');

comment on table last_prices_2024_10_28 is 'Партиция сделок за 28.10.2024';

alter table last_prices_2024_10_28
    owner to postgres;

 

 create table last_prices_2024_10_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-29 00:00:00') TO ('2024-10-30 00:00:00');

comment on table last_prices_2024_10_29 is 'Партиция сделок за 29.10.2024';

alter table last_prices_2024_10_29
    owner to postgres;

 

 create table last_prices_2024_10_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-30 00:00:00') TO ('2024-10-31 00:00:00');

comment on table last_prices_2024_10_30 is 'Партиция сделок за 30.10.2024';

alter table last_prices_2024_10_30
    owner to postgres;

 

 create table last_prices_2024_10_31
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-10-31 00:00:00') TO ('2024-11-01 00:00:00');

comment on table last_prices_2024_10_31 is 'Партиция сделок за 31.10.2024';

alter table last_prices_2024_10_31
    owner to postgres;

 

 create table last_prices_2024_11_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-01 00:00:00') TO ('2024-11-02 00:00:00');

comment on table last_prices_2024_11_01 is 'Партиция сделок за 01.11.2024';

alter table last_prices_2024_11_01
    owner to postgres;

 

 create table last_prices_2024_11_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-02 00:00:00') TO ('2024-11-03 00:00:00');

comment on table last_prices_2024_11_02 is 'Партиция сделок за 02.11.2024';

alter table last_prices_2024_11_02
    owner to postgres;

 

 create table last_prices_2024_11_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-03 00:00:00') TO ('2024-11-04 00:00:00');

comment on table last_prices_2024_11_03 is 'Партиция сделок за 03.11.2024';

alter table last_prices_2024_11_03
    owner to postgres;

 

 create table last_prices_2024_11_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-04 00:00:00') TO ('2024-11-05 00:00:00');

comment on table last_prices_2024_11_04 is 'Партиция сделок за 04.11.2024';

alter table last_prices_2024_11_04
    owner to postgres;

 

 create table last_prices_2024_11_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-05 00:00:00') TO ('2024-11-06 00:00:00');

comment on table last_prices_2024_11_05 is 'Партиция сделок за 05.11.2024';

alter table last_prices_2024_11_05
    owner to postgres;

 

 create table last_prices_2024_11_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-06 00:00:00') TO ('2024-11-07 00:00:00');

comment on table last_prices_2024_11_06 is 'Партиция сделок за 06.11.2024';

alter table last_prices_2024_11_06
    owner to postgres;

 

 create table last_prices_2024_11_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-07 00:00:00') TO ('2024-11-08 00:00:00');

comment on table last_prices_2024_11_07 is 'Партиция сделок за 07.11.2024';

alter table last_prices_2024_11_07
    owner to postgres;

 

 create table last_prices_2024_11_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-08 00:00:00') TO ('2024-11-09 00:00:00');

comment on table last_prices_2024_11_08 is 'Партиция сделок за 08.11.2024';

alter table last_prices_2024_11_08
    owner to postgres;

 

 create table last_prices_2024_11_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-09 00:00:00') TO ('2024-11-10 00:00:00');

comment on table last_prices_2024_11_09 is 'Партиция сделок за 09.11.2024';

alter table last_prices_2024_11_09
    owner to postgres;

 

 create table last_prices_2024_11_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-10 00:00:00') TO ('2024-11-11 00:00:00');

comment on table last_prices_2024_11_10 is 'Партиция сделок за 10.11.2024';

alter table last_prices_2024_11_10
    owner to postgres;

 

 create table last_prices_2024_11_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-11 00:00:00') TO ('2024-11-12 00:00:00');

comment on table last_prices_2024_11_11 is 'Партиция сделок за 11.11.2024';

alter table last_prices_2024_11_11
    owner to postgres;

 

 create table last_prices_2024_11_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-12 00:00:00') TO ('2024-11-13 00:00:00');

comment on table last_prices_2024_11_12 is 'Партиция сделок за 12.11.2024';

alter table last_prices_2024_11_12
    owner to postgres;

 

 create table last_prices_2024_11_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-13 00:00:00') TO ('2024-11-14 00:00:00');

comment on table last_prices_2024_11_13 is 'Партиция сделок за 13.11.2024';

alter table last_prices_2024_11_13
    owner to postgres;

 

 create table last_prices_2024_11_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-14 00:00:00') TO ('2024-11-15 00:00:00');

comment on table last_prices_2024_11_14 is 'Партиция сделок за 14.11.2024';

alter table last_prices_2024_11_14
    owner to postgres;

 

 create table last_prices_2024_11_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-15 00:00:00') TO ('2024-11-16 00:00:00');

comment on table last_prices_2024_11_15 is 'Партиция сделок за 15.11.2024';

alter table last_prices_2024_11_15
    owner to postgres;

 

 create table last_prices_2024_11_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-16 00:00:00') TO ('2024-11-17 00:00:00');

comment on table last_prices_2024_11_16 is 'Партиция сделок за 16.11.2024';

alter table last_prices_2024_11_16
    owner to postgres;

 

 create table last_prices_2024_11_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-17 00:00:00') TO ('2024-11-18 00:00:00');

comment on table last_prices_2024_11_17 is 'Партиция сделок за 17.11.2024';

alter table last_prices_2024_11_17
    owner to postgres;

 

 create table last_prices_2024_11_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-18 00:00:00') TO ('2024-11-19 00:00:00');

comment on table last_prices_2024_11_18 is 'Партиция сделок за 18.11.2024';

alter table last_prices_2024_11_18
    owner to postgres;

 

 create table last_prices_2024_11_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-19 00:00:00') TO ('2024-11-20 00:00:00');

comment on table last_prices_2024_11_19 is 'Партиция сделок за 19.11.2024';

alter table last_prices_2024_11_19
    owner to postgres;

 

 create table last_prices_2024_11_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-20 00:00:00') TO ('2024-11-21 00:00:00');

comment on table last_prices_2024_11_20 is 'Партиция сделок за 20.11.2024';

alter table last_prices_2024_11_20
    owner to postgres;

 

 create table last_prices_2024_11_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-21 00:00:00') TO ('2024-11-22 00:00:00');

comment on table last_prices_2024_11_21 is 'Партиция сделок за 21.11.2024';

alter table last_prices_2024_11_21
    owner to postgres;

 

 create table last_prices_2024_11_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-22 00:00:00') TO ('2024-11-23 00:00:00');

comment on table last_prices_2024_11_22 is 'Партиция сделок за 22.11.2024';

alter table last_prices_2024_11_22
    owner to postgres;

 

 create table last_prices_2024_11_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-23 00:00:00') TO ('2024-11-24 00:00:00');

comment on table last_prices_2024_11_23 is 'Партиция сделок за 23.11.2024';

alter table last_prices_2024_11_23
    owner to postgres;

 

 create table last_prices_2024_11_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-24 00:00:00') TO ('2024-11-25 00:00:00');

comment on table last_prices_2024_11_24 is 'Партиция сделок за 24.11.2024';

alter table last_prices_2024_11_24
    owner to postgres;

 

 create table last_prices_2024_11_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-25 00:00:00') TO ('2024-11-26 00:00:00');

comment on table last_prices_2024_11_25 is 'Партиция сделок за 25.11.2024';

alter table last_prices_2024_11_25
    owner to postgres;

 

 create table last_prices_2024_11_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-26 00:00:00') TO ('2024-11-27 00:00:00');

comment on table last_prices_2024_11_26 is 'Партиция сделок за 26.11.2024';

alter table last_prices_2024_11_26
    owner to postgres;

 

 create table last_prices_2024_11_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-27 00:00:00') TO ('2024-11-28 00:00:00');

comment on table last_prices_2024_11_27 is 'Партиция сделок за 27.11.2024';

alter table last_prices_2024_11_27
    owner to postgres;

 

 create table last_prices_2024_11_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-28 00:00:00') TO ('2024-11-29 00:00:00');

comment on table last_prices_2024_11_28 is 'Партиция сделок за 28.11.2024';

alter table last_prices_2024_11_28
    owner to postgres;

 

 create table last_prices_2024_11_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-29 00:00:00') TO ('2024-11-30 00:00:00');

comment on table last_prices_2024_11_29 is 'Партиция сделок за 29.11.2024';

alter table last_prices_2024_11_29
    owner to postgres;

 

 create table last_prices_2024_11_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-11-30 00:00:00') TO ('2024-12-01 00:00:00');

comment on table last_prices_2024_11_30 is 'Партиция сделок за 30.11.2024';

alter table last_prices_2024_11_30
    owner to postgres;

 

 create table last_prices_2024_12_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-01 00:00:00') TO ('2024-12-02 00:00:00');

comment on table last_prices_2024_12_01 is 'Партиция сделок за 01.12.2024';

alter table last_prices_2024_12_01
    owner to postgres;

 

 create table last_prices_2024_12_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-02 00:00:00') TO ('2024-12-03 00:00:00');

comment on table last_prices_2024_12_02 is 'Партиция сделок за 02.12.2024';

alter table last_prices_2024_12_02
    owner to postgres;

 

 create table last_prices_2024_12_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-03 00:00:00') TO ('2024-12-04 00:00:00');

comment on table last_prices_2024_12_03 is 'Партиция сделок за 03.12.2024';

alter table last_prices_2024_12_03
    owner to postgres;

 

 create table last_prices_2024_12_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-04 00:00:00') TO ('2024-12-05 00:00:00');

comment on table last_prices_2024_12_04 is 'Партиция сделок за 04.12.2024';

alter table last_prices_2024_12_04
    owner to postgres;

 

 create table last_prices_2024_12_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-05 00:00:00') TO ('2024-12-06 00:00:00');

comment on table last_prices_2024_12_05 is 'Партиция сделок за 05.12.2024';

alter table last_prices_2024_12_05
    owner to postgres;

 

 create table last_prices_2024_12_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-06 00:00:00') TO ('2024-12-07 00:00:00');

comment on table last_prices_2024_12_06 is 'Партиция сделок за 06.12.2024';

alter table last_prices_2024_12_06
    owner to postgres;

 

 create table last_prices_2024_12_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-07 00:00:00') TO ('2024-12-08 00:00:00');

comment on table last_prices_2024_12_07 is 'Партиция сделок за 07.12.2024';

alter table last_prices_2024_12_07
    owner to postgres;

 

 create table last_prices_2024_12_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-08 00:00:00') TO ('2024-12-09 00:00:00');

comment on table last_prices_2024_12_08 is 'Партиция сделок за 08.12.2024';

alter table last_prices_2024_12_08
    owner to postgres;

 

 create table last_prices_2024_12_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-09 00:00:00') TO ('2024-12-10 00:00:00');

comment on table last_prices_2024_12_09 is 'Партиция сделок за 09.12.2024';

alter table last_prices_2024_12_09
    owner to postgres;

 

 create table last_prices_2024_12_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-10 00:00:00') TO ('2024-12-11 00:00:00');

comment on table last_prices_2024_12_10 is 'Партиция сделок за 10.12.2024';

alter table last_prices_2024_12_10
    owner to postgres;

 

 create table last_prices_2024_12_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-11 00:00:00') TO ('2024-12-12 00:00:00');

comment on table last_prices_2024_12_11 is 'Партиция сделок за 11.12.2024';

alter table last_prices_2024_12_11
    owner to postgres;

 

 create table last_prices_2024_12_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-12 00:00:00') TO ('2024-12-13 00:00:00');

comment on table last_prices_2024_12_12 is 'Партиция сделок за 12.12.2024';

alter table last_prices_2024_12_12
    owner to postgres;

 

 create table last_prices_2024_12_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-13 00:00:00') TO ('2024-12-14 00:00:00');

comment on table last_prices_2024_12_13 is 'Партиция сделок за 13.12.2024';

alter table last_prices_2024_12_13
    owner to postgres;

 

 create table last_prices_2024_12_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-14 00:00:00') TO ('2024-12-15 00:00:00');

comment on table last_prices_2024_12_14 is 'Партиция сделок за 14.12.2024';

alter table last_prices_2024_12_14
    owner to postgres;

 

 create table last_prices_2024_12_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-15 00:00:00') TO ('2024-12-16 00:00:00');

comment on table last_prices_2024_12_15 is 'Партиция сделок за 15.12.2024';

alter table last_prices_2024_12_15
    owner to postgres;

 

 create table last_prices_2024_12_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-16 00:00:00') TO ('2024-12-17 00:00:00');

comment on table last_prices_2024_12_16 is 'Партиция сделок за 16.12.2024';

alter table last_prices_2024_12_16
    owner to postgres;

 

 create table last_prices_2024_12_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-17 00:00:00') TO ('2024-12-18 00:00:00');

comment on table last_prices_2024_12_17 is 'Партиция сделок за 17.12.2024';

alter table last_prices_2024_12_17
    owner to postgres;

 

 create table last_prices_2024_12_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-18 00:00:00') TO ('2024-12-19 00:00:00');

comment on table last_prices_2024_12_18 is 'Партиция сделок за 18.12.2024';

alter table last_prices_2024_12_18
    owner to postgres;

 

 create table last_prices_2024_12_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-19 00:00:00') TO ('2024-12-20 00:00:00');

comment on table last_prices_2024_12_19 is 'Партиция сделок за 19.12.2024';

alter table last_prices_2024_12_19
    owner to postgres;

 

 create table last_prices_2024_12_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-20 00:00:00') TO ('2024-12-21 00:00:00');

comment on table last_prices_2024_12_20 is 'Партиция сделок за 20.12.2024';

alter table last_prices_2024_12_20
    owner to postgres;

 

 create table last_prices_2024_12_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-21 00:00:00') TO ('2024-12-22 00:00:00');

comment on table last_prices_2024_12_21 is 'Партиция сделок за 21.12.2024';

alter table last_prices_2024_12_21
    owner to postgres;

 

 create table last_prices_2024_12_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-22 00:00:00') TO ('2024-12-23 00:00:00');

comment on table last_prices_2024_12_22 is 'Партиция сделок за 22.12.2024';

alter table last_prices_2024_12_22
    owner to postgres;

 

 create table last_prices_2024_12_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-23 00:00:00') TO ('2024-12-24 00:00:00');

comment on table last_prices_2024_12_23 is 'Партиция сделок за 23.12.2024';

alter table last_prices_2024_12_23
    owner to postgres;

 

 create table last_prices_2024_12_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-24 00:00:00') TO ('2024-12-25 00:00:00');

comment on table last_prices_2024_12_24 is 'Партиция сделок за 24.12.2024';

alter table last_prices_2024_12_24
    owner to postgres;

 

 create table last_prices_2024_12_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-25 00:00:00') TO ('2024-12-26 00:00:00');

comment on table last_prices_2024_12_25 is 'Партиция сделок за 25.12.2024';

alter table last_prices_2024_12_25
    owner to postgres;

 

 create table last_prices_2024_12_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-26 00:00:00') TO ('2024-12-27 00:00:00');

comment on table last_prices_2024_12_26 is 'Партиция сделок за 26.12.2024';

alter table last_prices_2024_12_26
    owner to postgres;

 

 create table last_prices_2024_12_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-27 00:00:00') TO ('2024-12-28 00:00:00');

comment on table last_prices_2024_12_27 is 'Партиция сделок за 27.12.2024';

alter table last_prices_2024_12_27
    owner to postgres;

 

 create table last_prices_2024_12_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-28 00:00:00') TO ('2024-12-29 00:00:00');

comment on table last_prices_2024_12_28 is 'Партиция сделок за 28.12.2024';

alter table last_prices_2024_12_28
    owner to postgres;

 

 create table last_prices_2024_12_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-29 00:00:00') TO ('2024-12-30 00:00:00');

comment on table last_prices_2024_12_29 is 'Партиция сделок за 29.12.2024';

alter table last_prices_2024_12_29
    owner to postgres;

 

 create table last_prices_2024_12_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-30 00:00:00') TO ('2024-12-31 00:00:00');

comment on table last_prices_2024_12_30 is 'Партиция сделок за 30.12.2024';

alter table last_prices_2024_12_30
    owner to postgres;

 

 create table last_prices_2024_12_31
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2024-12-31 00:00:00') TO ('2025-01-01 00:00:00');

comment on table last_prices_2024_12_31 is 'Партиция сделок за 31.12.2024';

alter table last_prices_2024_12_31
    owner to postgres;

 

 create table last_prices_2025_01_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-01 00:00:00') TO ('2025-01-02 00:00:00');

comment on table last_prices_2025_01_01 is 'Партиция сделок за 01.01.2025';

alter table last_prices_2025_01_01
    owner to postgres;

 

 create table last_prices_2025_01_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-02 00:00:00') TO ('2025-01-03 00:00:00');

comment on table last_prices_2025_01_02 is 'Партиция сделок за 02.01.2025';

alter table last_prices_2025_01_02
    owner to postgres;

 

 create table last_prices_2025_01_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-03 00:00:00') TO ('2025-01-04 00:00:00');

comment on table last_prices_2025_01_03 is 'Партиция сделок за 03.01.2025';

alter table last_prices_2025_01_03
    owner to postgres;

 

 create table last_prices_2025_01_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-04 00:00:00') TO ('2025-01-05 00:00:00');

comment on table last_prices_2025_01_04 is 'Партиция сделок за 04.01.2025';

alter table last_prices_2025_01_04
    owner to postgres;

 

 create table last_prices_2025_01_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-05 00:00:00') TO ('2025-01-06 00:00:00');

comment on table last_prices_2025_01_05 is 'Партиция сделок за 05.01.2025';

alter table last_prices_2025_01_05
    owner to postgres;

 

 create table last_prices_2025_01_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-06 00:00:00') TO ('2025-01-07 00:00:00');

comment on table last_prices_2025_01_06 is 'Партиция сделок за 06.01.2025';

alter table last_prices_2025_01_06
    owner to postgres;

 

 create table last_prices_2025_01_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-07 00:00:00') TO ('2025-01-08 00:00:00');

comment on table last_prices_2025_01_07 is 'Партиция сделок за 07.01.2025';

alter table last_prices_2025_01_07
    owner to postgres;

 

 create table last_prices_2025_01_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-08 00:00:00') TO ('2025-01-09 00:00:00');

comment on table last_prices_2025_01_08 is 'Партиция сделок за 08.01.2025';

alter table last_prices_2025_01_08
    owner to postgres;

 

 create table last_prices_2025_01_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-09 00:00:00') TO ('2025-01-10 00:00:00');

comment on table last_prices_2025_01_09 is 'Партиция сделок за 09.01.2025';

alter table last_prices_2025_01_09
    owner to postgres;

 

 create table last_prices_2025_01_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-10 00:00:00') TO ('2025-01-11 00:00:00');

comment on table last_prices_2025_01_10 is 'Партиция сделок за 10.01.2025';

alter table last_prices_2025_01_10
    owner to postgres;

 

 create table last_prices_2025_01_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-11 00:00:00') TO ('2025-01-12 00:00:00');

comment on table last_prices_2025_01_11 is 'Партиция сделок за 11.01.2025';

alter table last_prices_2025_01_11
    owner to postgres;

 

 create table last_prices_2025_01_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-12 00:00:00') TO ('2025-01-13 00:00:00');

comment on table last_prices_2025_01_12 is 'Партиция сделок за 12.01.2025';

alter table last_prices_2025_01_12
    owner to postgres;

 

 create table last_prices_2025_01_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-13 00:00:00') TO ('2025-01-14 00:00:00');

comment on table last_prices_2025_01_13 is 'Партиция сделок за 13.01.2025';

alter table last_prices_2025_01_13
    owner to postgres;

 

 create table last_prices_2025_01_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-14 00:00:00') TO ('2025-01-15 00:00:00');

comment on table last_prices_2025_01_14 is 'Партиция сделок за 14.01.2025';

alter table last_prices_2025_01_14
    owner to postgres;

 

 create table last_prices_2025_01_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-15 00:00:00') TO ('2025-01-16 00:00:00');

comment on table last_prices_2025_01_15 is 'Партиция сделок за 15.01.2025';

alter table last_prices_2025_01_15
    owner to postgres;

 

 create table last_prices_2025_01_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-16 00:00:00') TO ('2025-01-17 00:00:00');

comment on table last_prices_2025_01_16 is 'Партиция сделок за 16.01.2025';

alter table last_prices_2025_01_16
    owner to postgres;

 

 create table last_prices_2025_01_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-17 00:00:00') TO ('2025-01-18 00:00:00');

comment on table last_prices_2025_01_17 is 'Партиция сделок за 17.01.2025';

alter table last_prices_2025_01_17
    owner to postgres;

 

 create table last_prices_2025_01_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-18 00:00:00') TO ('2025-01-19 00:00:00');

comment on table last_prices_2025_01_18 is 'Партиция сделок за 18.01.2025';

alter table last_prices_2025_01_18
    owner to postgres;

 

 create table last_prices_2025_01_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-19 00:00:00') TO ('2025-01-20 00:00:00');

comment on table last_prices_2025_01_19 is 'Партиция сделок за 19.01.2025';

alter table last_prices_2025_01_19
    owner to postgres;

 

 create table last_prices_2025_01_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-20 00:00:00') TO ('2025-01-21 00:00:00');

comment on table last_prices_2025_01_20 is 'Партиция сделок за 20.01.2025';

alter table last_prices_2025_01_20
    owner to postgres;

 

 create table last_prices_2025_01_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-21 00:00:00') TO ('2025-01-22 00:00:00');

comment on table last_prices_2025_01_21 is 'Партиция сделок за 21.01.2025';

alter table last_prices_2025_01_21
    owner to postgres;

 

 create table last_prices_2025_01_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-22 00:00:00') TO ('2025-01-23 00:00:00');

comment on table last_prices_2025_01_22 is 'Партиция сделок за 22.01.2025';

alter table last_prices_2025_01_22
    owner to postgres;

 

 create table last_prices_2025_01_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-23 00:00:00') TO ('2025-01-24 00:00:00');

comment on table last_prices_2025_01_23 is 'Партиция сделок за 23.01.2025';

alter table last_prices_2025_01_23
    owner to postgres;

 

 create table last_prices_2025_01_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-24 00:00:00') TO ('2025-01-25 00:00:00');

comment on table last_prices_2025_01_24 is 'Партиция сделок за 24.01.2025';

alter table last_prices_2025_01_24
    owner to postgres;

 

 create table last_prices_2025_01_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-25 00:00:00') TO ('2025-01-26 00:00:00');

comment on table last_prices_2025_01_25 is 'Партиция сделок за 25.01.2025';

alter table last_prices_2025_01_25
    owner to postgres;

 

 create table last_prices_2025_01_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-26 00:00:00') TO ('2025-01-27 00:00:00');

comment on table last_prices_2025_01_26 is 'Партиция сделок за 26.01.2025';

alter table last_prices_2025_01_26
    owner to postgres;

 

 create table last_prices_2025_01_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-27 00:00:00') TO ('2025-01-28 00:00:00');

comment on table last_prices_2025_01_27 is 'Партиция сделок за 27.01.2025';

alter table last_prices_2025_01_27
    owner to postgres;

 

 create table last_prices_2025_01_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-28 00:00:00') TO ('2025-01-29 00:00:00');

comment on table last_prices_2025_01_28 is 'Партиция сделок за 28.01.2025';

alter table last_prices_2025_01_28
    owner to postgres;

 

 create table last_prices_2025_01_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-29 00:00:00') TO ('2025-01-30 00:00:00');

comment on table last_prices_2025_01_29 is 'Партиция сделок за 29.01.2025';

alter table last_prices_2025_01_29
    owner to postgres;

 

 create table last_prices_2025_01_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-30 00:00:00') TO ('2025-01-31 00:00:00');

comment on table last_prices_2025_01_30 is 'Партиция сделок за 30.01.2025';

alter table last_prices_2025_01_30
    owner to postgres;

 

 create table last_prices_2025_01_31
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-01-31 00:00:00') TO ('2025-02-01 00:00:00');

comment on table last_prices_2025_01_31 is 'Партиция сделок за 31.01.2025';

alter table last_prices_2025_01_31
    owner to postgres;

 

 create table last_prices_2025_02_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-01 00:00:00') TO ('2025-02-02 00:00:00');

comment on table last_prices_2025_02_01 is 'Партиция сделок за 01.02.2025';

alter table last_prices_2025_02_01
    owner to postgres;

 

 create table last_prices_2025_02_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-02 00:00:00') TO ('2025-02-03 00:00:00');

comment on table last_prices_2025_02_02 is 'Партиция сделок за 02.02.2025';

alter table last_prices_2025_02_02
    owner to postgres;

 

 create table last_prices_2025_02_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-03 00:00:00') TO ('2025-02-04 00:00:00');

comment on table last_prices_2025_02_03 is 'Партиция сделок за 03.02.2025';

alter table last_prices_2025_02_03
    owner to postgres;

 

 create table last_prices_2025_02_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-04 00:00:00') TO ('2025-02-05 00:00:00');

comment on table last_prices_2025_02_04 is 'Партиция сделок за 04.02.2025';

alter table last_prices_2025_02_04
    owner to postgres;

 

 create table last_prices_2025_02_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-05 00:00:00') TO ('2025-02-06 00:00:00');

comment on table last_prices_2025_02_05 is 'Партиция сделок за 05.02.2025';

alter table last_prices_2025_02_05
    owner to postgres;

 

 create table last_prices_2025_02_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-06 00:00:00') TO ('2025-02-07 00:00:00');

comment on table last_prices_2025_02_06 is 'Партиция сделок за 06.02.2025';

alter table last_prices_2025_02_06
    owner to postgres;

 

 create table last_prices_2025_02_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-07 00:00:00') TO ('2025-02-08 00:00:00');

comment on table last_prices_2025_02_07 is 'Партиция сделок за 07.02.2025';

alter table last_prices_2025_02_07
    owner to postgres;

 

 create table last_prices_2025_02_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-08 00:00:00') TO ('2025-02-09 00:00:00');

comment on table last_prices_2025_02_08 is 'Партиция сделок за 08.02.2025';

alter table last_prices_2025_02_08
    owner to postgres;

 

 create table last_prices_2025_02_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-09 00:00:00') TO ('2025-02-10 00:00:00');

comment on table last_prices_2025_02_09 is 'Партиция сделок за 09.02.2025';

alter table last_prices_2025_02_09
    owner to postgres;

 

 create table last_prices_2025_02_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-10 00:00:00') TO ('2025-02-11 00:00:00');

comment on table last_prices_2025_02_10 is 'Партиция сделок за 10.02.2025';

alter table last_prices_2025_02_10
    owner to postgres;

 

 create table last_prices_2025_02_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-11 00:00:00') TO ('2025-02-12 00:00:00');

comment on table last_prices_2025_02_11 is 'Партиция сделок за 11.02.2025';

alter table last_prices_2025_02_11
    owner to postgres;

 

 create table last_prices_2025_02_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-12 00:00:00') TO ('2025-02-13 00:00:00');

comment on table last_prices_2025_02_12 is 'Партиция сделок за 12.02.2025';

alter table last_prices_2025_02_12
    owner to postgres;

 

 create table last_prices_2025_02_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-13 00:00:00') TO ('2025-02-14 00:00:00');

comment on table last_prices_2025_02_13 is 'Партиция сделок за 13.02.2025';

alter table last_prices_2025_02_13
    owner to postgres;

 

 create table last_prices_2025_02_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-14 00:00:00') TO ('2025-02-15 00:00:00');

comment on table last_prices_2025_02_14 is 'Партиция сделок за 14.02.2025';

alter table last_prices_2025_02_14
    owner to postgres;

 

 create table last_prices_2025_02_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-15 00:00:00') TO ('2025-02-16 00:00:00');

comment on table last_prices_2025_02_15 is 'Партиция сделок за 15.02.2025';

alter table last_prices_2025_02_15
    owner to postgres;

 

 create table last_prices_2025_02_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-16 00:00:00') TO ('2025-02-17 00:00:00');

comment on table last_prices_2025_02_16 is 'Партиция сделок за 16.02.2025';

alter table last_prices_2025_02_16
    owner to postgres;

 

 create table last_prices_2025_02_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-17 00:00:00') TO ('2025-02-18 00:00:00');

comment on table last_prices_2025_02_17 is 'Партиция сделок за 17.02.2025';

alter table last_prices_2025_02_17
    owner to postgres;

 

 create table last_prices_2025_02_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-18 00:00:00') TO ('2025-02-19 00:00:00');

comment on table last_prices_2025_02_18 is 'Партиция сделок за 18.02.2025';

alter table last_prices_2025_02_18
    owner to postgres;

 

 create table last_prices_2025_02_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-19 00:00:00') TO ('2025-02-20 00:00:00');

comment on table last_prices_2025_02_19 is 'Партиция сделок за 19.02.2025';

alter table last_prices_2025_02_19
    owner to postgres;

 

 create table last_prices_2025_02_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-20 00:00:00') TO ('2025-02-21 00:00:00');

comment on table last_prices_2025_02_20 is 'Партиция сделок за 20.02.2025';

alter table last_prices_2025_02_20
    owner to postgres;

 

 create table last_prices_2025_02_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-21 00:00:00') TO ('2025-02-22 00:00:00');

comment on table last_prices_2025_02_21 is 'Партиция сделок за 21.02.2025';

alter table last_prices_2025_02_21
    owner to postgres;

 

 create table last_prices_2025_02_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-22 00:00:00') TO ('2025-02-23 00:00:00');

comment on table last_prices_2025_02_22 is 'Партиция сделок за 22.02.2025';

alter table last_prices_2025_02_22
    owner to postgres;

 

 create table last_prices_2025_02_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-23 00:00:00') TO ('2025-02-24 00:00:00');

comment on table last_prices_2025_02_23 is 'Партиция сделок за 23.02.2025';

alter table last_prices_2025_02_23
    owner to postgres;

 

 create table last_prices_2025_02_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-24 00:00:00') TO ('2025-02-25 00:00:00');

comment on table last_prices_2025_02_24 is 'Партиция сделок за 24.02.2025';

alter table last_prices_2025_02_24
    owner to postgres;

 

 create table last_prices_2025_02_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-25 00:00:00') TO ('2025-02-26 00:00:00');

comment on table last_prices_2025_02_25 is 'Партиция сделок за 25.02.2025';

alter table last_prices_2025_02_25
    owner to postgres;

 

 create table last_prices_2025_02_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-26 00:00:00') TO ('2025-02-27 00:00:00');

comment on table last_prices_2025_02_26 is 'Партиция сделок за 26.02.2025';

alter table last_prices_2025_02_26
    owner to postgres;

 

 create table last_prices_2025_02_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-27 00:00:00') TO ('2025-02-28 00:00:00');

comment on table last_prices_2025_02_27 is 'Партиция сделок за 27.02.2025';

alter table last_prices_2025_02_27
    owner to postgres;

 

 create table last_prices_2025_02_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-02-28 00:00:00') TO ('2025-03-01 00:00:00');

comment on table last_prices_2025_02_28 is 'Партиция сделок за 28.02.2025';

alter table last_prices_2025_02_28
    owner to postgres;

 

 create table last_prices_2025_03_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-01 00:00:00') TO ('2025-03-02 00:00:00');

comment on table last_prices_2025_03_01 is 'Партиция сделок за 01.03.2025';

alter table last_prices_2025_03_01
    owner to postgres;

 

 create table last_prices_2025_03_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-02 00:00:00') TO ('2025-03-03 00:00:00');

comment on table last_prices_2025_03_02 is 'Партиция сделок за 02.03.2025';

alter table last_prices_2025_03_02
    owner to postgres;

 

 create table last_prices_2025_03_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-03 00:00:00') TO ('2025-03-04 00:00:00');

comment on table last_prices_2025_03_03 is 'Партиция сделок за 03.03.2025';

alter table last_prices_2025_03_03
    owner to postgres;

 

 create table last_prices_2025_03_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-04 00:00:00') TO ('2025-03-05 00:00:00');

comment on table last_prices_2025_03_04 is 'Партиция сделок за 04.03.2025';

alter table last_prices_2025_03_04
    owner to postgres;

 

 create table last_prices_2025_03_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-05 00:00:00') TO ('2025-03-06 00:00:00');

comment on table last_prices_2025_03_05 is 'Партиция сделок за 05.03.2025';

alter table last_prices_2025_03_05
    owner to postgres;

 

 create table last_prices_2025_03_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-06 00:00:00') TO ('2025-03-07 00:00:00');

comment on table last_prices_2025_03_06 is 'Партиция сделок за 06.03.2025';

alter table last_prices_2025_03_06
    owner to postgres;

 

 create table last_prices_2025_03_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-07 00:00:00') TO ('2025-03-08 00:00:00');

comment on table last_prices_2025_03_07 is 'Партиция сделок за 07.03.2025';

alter table last_prices_2025_03_07
    owner to postgres;

 

 create table last_prices_2025_03_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-08 00:00:00') TO ('2025-03-09 00:00:00');

comment on table last_prices_2025_03_08 is 'Партиция сделок за 08.03.2025';

alter table last_prices_2025_03_08
    owner to postgres;

 

 create table last_prices_2025_03_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-09 00:00:00') TO ('2025-03-10 00:00:00');

comment on table last_prices_2025_03_09 is 'Партиция сделок за 09.03.2025';

alter table last_prices_2025_03_09
    owner to postgres;

 

 create table last_prices_2025_03_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-10 00:00:00') TO ('2025-03-11 00:00:00');

comment on table last_prices_2025_03_10 is 'Партиция сделок за 10.03.2025';

alter table last_prices_2025_03_10
    owner to postgres;

 

 create table last_prices_2025_03_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-11 00:00:00') TO ('2025-03-12 00:00:00');

comment on table last_prices_2025_03_11 is 'Партиция сделок за 11.03.2025';

alter table last_prices_2025_03_11
    owner to postgres;

 

 create table last_prices_2025_03_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-12 00:00:00') TO ('2025-03-13 00:00:00');

comment on table last_prices_2025_03_12 is 'Партиция сделок за 12.03.2025';

alter table last_prices_2025_03_12
    owner to postgres;

 

 create table last_prices_2025_03_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-13 00:00:00') TO ('2025-03-14 00:00:00');

comment on table last_prices_2025_03_13 is 'Партиция сделок за 13.03.2025';

alter table last_prices_2025_03_13
    owner to postgres;

 

 create table last_prices_2025_03_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-14 00:00:00') TO ('2025-03-15 00:00:00');

comment on table last_prices_2025_03_14 is 'Партиция сделок за 14.03.2025';

alter table last_prices_2025_03_14
    owner to postgres;

 

 create table last_prices_2025_03_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-15 00:00:00') TO ('2025-03-16 00:00:00');

comment on table last_prices_2025_03_15 is 'Партиция сделок за 15.03.2025';

alter table last_prices_2025_03_15
    owner to postgres;

 

 create table last_prices_2025_03_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-16 00:00:00') TO ('2025-03-17 00:00:00');

comment on table last_prices_2025_03_16 is 'Партиция сделок за 16.03.2025';

alter table last_prices_2025_03_16
    owner to postgres;

 

 create table last_prices_2025_03_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-17 00:00:00') TO ('2025-03-18 00:00:00');

comment on table last_prices_2025_03_17 is 'Партиция сделок за 17.03.2025';

alter table last_prices_2025_03_17
    owner to postgres;

 

 create table last_prices_2025_03_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-18 00:00:00') TO ('2025-03-19 00:00:00');

comment on table last_prices_2025_03_18 is 'Партиция сделок за 18.03.2025';

alter table last_prices_2025_03_18
    owner to postgres;

 

 create table last_prices_2025_03_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-19 00:00:00') TO ('2025-03-20 00:00:00');

comment on table last_prices_2025_03_19 is 'Партиция сделок за 19.03.2025';

alter table last_prices_2025_03_19
    owner to postgres;

 

 create table last_prices_2025_03_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-20 00:00:00') TO ('2025-03-21 00:00:00');

comment on table last_prices_2025_03_20 is 'Партиция сделок за 20.03.2025';

alter table last_prices_2025_03_20
    owner to postgres;

 

 create table last_prices_2025_03_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-21 00:00:00') TO ('2025-03-22 00:00:00');

comment on table last_prices_2025_03_21 is 'Партиция сделок за 21.03.2025';

alter table last_prices_2025_03_21
    owner to postgres;

 

 create table last_prices_2025_03_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-22 00:00:00') TO ('2025-03-23 00:00:00');

comment on table last_prices_2025_03_22 is 'Партиция сделок за 22.03.2025';

alter table last_prices_2025_03_22
    owner to postgres;

 

 create table last_prices_2025_03_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-23 00:00:00') TO ('2025-03-24 00:00:00');

comment on table last_prices_2025_03_23 is 'Партиция сделок за 23.03.2025';

alter table last_prices_2025_03_23
    owner to postgres;

 

 create table last_prices_2025_03_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-24 00:00:00') TO ('2025-03-25 00:00:00');

comment on table last_prices_2025_03_24 is 'Партиция сделок за 24.03.2025';

alter table last_prices_2025_03_24
    owner to postgres;

 

 create table last_prices_2025_03_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-25 00:00:00') TO ('2025-03-26 00:00:00');

comment on table last_prices_2025_03_25 is 'Партиция сделок за 25.03.2025';

alter table last_prices_2025_03_25
    owner to postgres;

 

 create table last_prices_2025_03_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-26 00:00:00') TO ('2025-03-27 00:00:00');

comment on table last_prices_2025_03_26 is 'Партиция сделок за 26.03.2025';

alter table last_prices_2025_03_26
    owner to postgres;

 

 create table last_prices_2025_03_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-27 00:00:00') TO ('2025-03-28 00:00:00');

comment on table last_prices_2025_03_27 is 'Партиция сделок за 27.03.2025';

alter table last_prices_2025_03_27
    owner to postgres;

 

 create table last_prices_2025_03_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-28 00:00:00') TO ('2025-03-29 00:00:00');

comment on table last_prices_2025_03_28 is 'Партиция сделок за 28.03.2025';

alter table last_prices_2025_03_28
    owner to postgres;

 

 create table last_prices_2025_03_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-29 00:00:00') TO ('2025-03-30 00:00:00');

comment on table last_prices_2025_03_29 is 'Партиция сделок за 29.03.2025';

alter table last_prices_2025_03_29
    owner to postgres;

 

 create table last_prices_2025_03_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-30 00:00:00') TO ('2025-03-31 00:00:00');

comment on table last_prices_2025_03_30 is 'Партиция сделок за 30.03.2025';

alter table last_prices_2025_03_30
    owner to postgres;

 

 create table last_prices_2025_03_31
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-03-31 00:00:00') TO ('2025-04-01 00:00:00');

comment on table last_prices_2025_03_31 is 'Партиция сделок за 31.03.2025';

alter table last_prices_2025_03_31
    owner to postgres;

 

 create table last_prices_2025_04_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-01 00:00:00') TO ('2025-04-02 00:00:00');

comment on table last_prices_2025_04_01 is 'Партиция сделок за 01.04.2025';

alter table last_prices_2025_04_01
    owner to postgres;

 

 create table last_prices_2025_04_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-02 00:00:00') TO ('2025-04-03 00:00:00');

comment on table last_prices_2025_04_02 is 'Партиция сделок за 02.04.2025';

alter table last_prices_2025_04_02
    owner to postgres;

 

 create table last_prices_2025_04_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-03 00:00:00') TO ('2025-04-04 00:00:00');

comment on table last_prices_2025_04_03 is 'Партиция сделок за 03.04.2025';

alter table last_prices_2025_04_03
    owner to postgres;

 

 create table last_prices_2025_04_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-04 00:00:00') TO ('2025-04-05 00:00:00');

comment on table last_prices_2025_04_04 is 'Партиция сделок за 04.04.2025';

alter table last_prices_2025_04_04
    owner to postgres;

 

 create table last_prices_2025_04_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-05 00:00:00') TO ('2025-04-06 00:00:00');

comment on table last_prices_2025_04_05 is 'Партиция сделок за 05.04.2025';

alter table last_prices_2025_04_05
    owner to postgres;

 

 create table last_prices_2025_04_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-06 00:00:00') TO ('2025-04-07 00:00:00');

comment on table last_prices_2025_04_06 is 'Партиция сделок за 06.04.2025';

alter table last_prices_2025_04_06
    owner to postgres;

 

 create table last_prices_2025_04_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-07 00:00:00') TO ('2025-04-08 00:00:00');

comment on table last_prices_2025_04_07 is 'Партиция сделок за 07.04.2025';

alter table last_prices_2025_04_07
    owner to postgres;

 

 create table last_prices_2025_04_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-08 00:00:00') TO ('2025-04-09 00:00:00');

comment on table last_prices_2025_04_08 is 'Партиция сделок за 08.04.2025';

alter table last_prices_2025_04_08
    owner to postgres;

 

 create table last_prices_2025_04_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-09 00:00:00') TO ('2025-04-10 00:00:00');

comment on table last_prices_2025_04_09 is 'Партиция сделок за 09.04.2025';

alter table last_prices_2025_04_09
    owner to postgres;

 

 create table last_prices_2025_04_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-10 00:00:00') TO ('2025-04-11 00:00:00');

comment on table last_prices_2025_04_10 is 'Партиция сделок за 10.04.2025';

alter table last_prices_2025_04_10
    owner to postgres;

 

 create table last_prices_2025_04_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-11 00:00:00') TO ('2025-04-12 00:00:00');

comment on table last_prices_2025_04_11 is 'Партиция сделок за 11.04.2025';

alter table last_prices_2025_04_11
    owner to postgres;

 

 create table last_prices_2025_04_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-12 00:00:00') TO ('2025-04-13 00:00:00');

comment on table last_prices_2025_04_12 is 'Партиция сделок за 12.04.2025';

alter table last_prices_2025_04_12
    owner to postgres;

 

 create table last_prices_2025_04_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-13 00:00:00') TO ('2025-04-14 00:00:00');

comment on table last_prices_2025_04_13 is 'Партиция сделок за 13.04.2025';

alter table last_prices_2025_04_13
    owner to postgres;

 

 create table last_prices_2025_04_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-14 00:00:00') TO ('2025-04-15 00:00:00');

comment on table last_prices_2025_04_14 is 'Партиция сделок за 14.04.2025';

alter table last_prices_2025_04_14
    owner to postgres;

 

 create table last_prices_2025_04_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-15 00:00:00') TO ('2025-04-16 00:00:00');

comment on table last_prices_2025_04_15 is 'Партиция сделок за 15.04.2025';

alter table last_prices_2025_04_15
    owner to postgres;

 

 create table last_prices_2025_04_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-16 00:00:00') TO ('2025-04-17 00:00:00');

comment on table last_prices_2025_04_16 is 'Партиция сделок за 16.04.2025';

alter table last_prices_2025_04_16
    owner to postgres;

 

 create table last_prices_2025_04_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-17 00:00:00') TO ('2025-04-18 00:00:00');

comment on table last_prices_2025_04_17 is 'Партиция сделок за 17.04.2025';

alter table last_prices_2025_04_17
    owner to postgres;

 

 create table last_prices_2025_04_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-18 00:00:00') TO ('2025-04-19 00:00:00');

comment on table last_prices_2025_04_18 is 'Партиция сделок за 18.04.2025';

alter table last_prices_2025_04_18
    owner to postgres;

 

 create table last_prices_2025_04_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-19 00:00:00') TO ('2025-04-20 00:00:00');

comment on table last_prices_2025_04_19 is 'Партиция сделок за 19.04.2025';

alter table last_prices_2025_04_19
    owner to postgres;

 

 create table last_prices_2025_04_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-20 00:00:00') TO ('2025-04-21 00:00:00');

comment on table last_prices_2025_04_20 is 'Партиция сделок за 20.04.2025';

alter table last_prices_2025_04_20
    owner to postgres;

 

 create table last_prices_2025_04_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-21 00:00:00') TO ('2025-04-22 00:00:00');

comment on table last_prices_2025_04_21 is 'Партиция сделок за 21.04.2025';

alter table last_prices_2025_04_21
    owner to postgres;

 

 create table last_prices_2025_04_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-22 00:00:00') TO ('2025-04-23 00:00:00');

comment on table last_prices_2025_04_22 is 'Партиция сделок за 22.04.2025';

alter table last_prices_2025_04_22
    owner to postgres;

 

 create table last_prices_2025_04_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-23 00:00:00') TO ('2025-04-24 00:00:00');

comment on table last_prices_2025_04_23 is 'Партиция сделок за 23.04.2025';

alter table last_prices_2025_04_23
    owner to postgres;

 

 create table last_prices_2025_04_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-24 00:00:00') TO ('2025-04-25 00:00:00');

comment on table last_prices_2025_04_24 is 'Партиция сделок за 24.04.2025';

alter table last_prices_2025_04_24
    owner to postgres;

 

 create table last_prices_2025_04_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-25 00:00:00') TO ('2025-04-26 00:00:00');

comment on table last_prices_2025_04_25 is 'Партиция сделок за 25.04.2025';

alter table last_prices_2025_04_25
    owner to postgres;

 

 create table last_prices_2025_04_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-26 00:00:00') TO ('2025-04-27 00:00:00');

comment on table last_prices_2025_04_26 is 'Партиция сделок за 26.04.2025';

alter table last_prices_2025_04_26
    owner to postgres;

 

 create table last_prices_2025_04_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-27 00:00:00') TO ('2025-04-28 00:00:00');

comment on table last_prices_2025_04_27 is 'Партиция сделок за 27.04.2025';

alter table last_prices_2025_04_27
    owner to postgres;

 

 create table last_prices_2025_04_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-28 00:00:00') TO ('2025-04-29 00:00:00');

comment on table last_prices_2025_04_28 is 'Партиция сделок за 28.04.2025';

alter table last_prices_2025_04_28
    owner to postgres;

 

 create table last_prices_2025_04_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-29 00:00:00') TO ('2025-04-30 00:00:00');

comment on table last_prices_2025_04_29 is 'Партиция сделок за 29.04.2025';

alter table last_prices_2025_04_29
    owner to postgres;

 

 create table last_prices_2025_04_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-04-30 00:00:00') TO ('2025-05-01 00:00:00');

comment on table last_prices_2025_04_30 is 'Партиция сделок за 30.04.2025';

alter table last_prices_2025_04_30
    owner to postgres;

 

 create table last_prices_2025_05_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-01 00:00:00') TO ('2025-05-02 00:00:00');

comment on table last_prices_2025_05_01 is 'Партиция сделок за 01.05.2025';

alter table last_prices_2025_05_01
    owner to postgres;

 

 create table last_prices_2025_05_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-02 00:00:00') TO ('2025-05-03 00:00:00');

comment on table last_prices_2025_05_02 is 'Партиция сделок за 02.05.2025';

alter table last_prices_2025_05_02
    owner to postgres;

 

 create table last_prices_2025_05_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-03 00:00:00') TO ('2025-05-04 00:00:00');

comment on table last_prices_2025_05_03 is 'Партиция сделок за 03.05.2025';

alter table last_prices_2025_05_03
    owner to postgres;

 

 create table last_prices_2025_05_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-04 00:00:00') TO ('2025-05-05 00:00:00');

comment on table last_prices_2025_05_04 is 'Партиция сделок за 04.05.2025';

alter table last_prices_2025_05_04
    owner to postgres;

 

 create table last_prices_2025_05_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-05 00:00:00') TO ('2025-05-06 00:00:00');

comment on table last_prices_2025_05_05 is 'Партиция сделок за 05.05.2025';

alter table last_prices_2025_05_05
    owner to postgres;

 

 create table last_prices_2025_05_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-06 00:00:00') TO ('2025-05-07 00:00:00');

comment on table last_prices_2025_05_06 is 'Партиция сделок за 06.05.2025';

alter table last_prices_2025_05_06
    owner to postgres;

 

 create table last_prices_2025_05_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-07 00:00:00') TO ('2025-05-08 00:00:00');

comment on table last_prices_2025_05_07 is 'Партиция сделок за 07.05.2025';

alter table last_prices_2025_05_07
    owner to postgres;

 

 create table last_prices_2025_05_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-08 00:00:00') TO ('2025-05-09 00:00:00');

comment on table last_prices_2025_05_08 is 'Партиция сделок за 08.05.2025';

alter table last_prices_2025_05_08
    owner to postgres;

 

 create table last_prices_2025_05_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-09 00:00:00') TO ('2025-05-10 00:00:00');

comment on table last_prices_2025_05_09 is 'Партиция сделок за 09.05.2025';

alter table last_prices_2025_05_09
    owner to postgres;

 

 create table last_prices_2025_05_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-10 00:00:00') TO ('2025-05-11 00:00:00');

comment on table last_prices_2025_05_10 is 'Партиция сделок за 10.05.2025';

alter table last_prices_2025_05_10
    owner to postgres;

 

 create table last_prices_2025_05_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-11 00:00:00') TO ('2025-05-12 00:00:00');

comment on table last_prices_2025_05_11 is 'Партиция сделок за 11.05.2025';

alter table last_prices_2025_05_11
    owner to postgres;

 

 create table last_prices_2025_05_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-12 00:00:00') TO ('2025-05-13 00:00:00');

comment on table last_prices_2025_05_12 is 'Партиция сделок за 12.05.2025';

alter table last_prices_2025_05_12
    owner to postgres;

 

 create table last_prices_2025_05_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-13 00:00:00') TO ('2025-05-14 00:00:00');

comment on table last_prices_2025_05_13 is 'Партиция сделок за 13.05.2025';

alter table last_prices_2025_05_13
    owner to postgres;

 

 create table last_prices_2025_05_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-14 00:00:00') TO ('2025-05-15 00:00:00');

comment on table last_prices_2025_05_14 is 'Партиция сделок за 14.05.2025';

alter table last_prices_2025_05_14
    owner to postgres;

 

 create table last_prices_2025_05_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-15 00:00:00') TO ('2025-05-16 00:00:00');

comment on table last_prices_2025_05_15 is 'Партиция сделок за 15.05.2025';

alter table last_prices_2025_05_15
    owner to postgres;

 

 create table last_prices_2025_05_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-16 00:00:00') TO ('2025-05-17 00:00:00');

comment on table last_prices_2025_05_16 is 'Партиция сделок за 16.05.2025';

alter table last_prices_2025_05_16
    owner to postgres;

 

 create table last_prices_2025_05_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-17 00:00:00') TO ('2025-05-18 00:00:00');

comment on table last_prices_2025_05_17 is 'Партиция сделок за 17.05.2025';

alter table last_prices_2025_05_17
    owner to postgres;

 

 create table last_prices_2025_05_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-18 00:00:00') TO ('2025-05-19 00:00:00');

comment on table last_prices_2025_05_18 is 'Партиция сделок за 18.05.2025';

alter table last_prices_2025_05_18
    owner to postgres;

 

 create table last_prices_2025_05_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-19 00:00:00') TO ('2025-05-20 00:00:00');

comment on table last_prices_2025_05_19 is 'Партиция сделок за 19.05.2025';

alter table last_prices_2025_05_19
    owner to postgres;

 

 create table last_prices_2025_05_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-20 00:00:00') TO ('2025-05-21 00:00:00');

comment on table last_prices_2025_05_20 is 'Партиция сделок за 20.05.2025';

alter table last_prices_2025_05_20
    owner to postgres;

 

 create table last_prices_2025_05_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-21 00:00:00') TO ('2025-05-22 00:00:00');

comment on table last_prices_2025_05_21 is 'Партиция сделок за 21.05.2025';

alter table last_prices_2025_05_21
    owner to postgres;

 

 create table last_prices_2025_05_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-22 00:00:00') TO ('2025-05-23 00:00:00');

comment on table last_prices_2025_05_22 is 'Партиция сделок за 22.05.2025';

alter table last_prices_2025_05_22
    owner to postgres;

 

 create table last_prices_2025_05_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-23 00:00:00') TO ('2025-05-24 00:00:00');

comment on table last_prices_2025_05_23 is 'Партиция сделок за 23.05.2025';

alter table last_prices_2025_05_23
    owner to postgres;

 

 create table last_prices_2025_05_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-24 00:00:00') TO ('2025-05-25 00:00:00');

comment on table last_prices_2025_05_24 is 'Партиция сделок за 24.05.2025';

alter table last_prices_2025_05_24
    owner to postgres;

 

 create table last_prices_2025_05_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-25 00:00:00') TO ('2025-05-26 00:00:00');

comment on table last_prices_2025_05_25 is 'Партиция сделок за 25.05.2025';

alter table last_prices_2025_05_25
    owner to postgres;

 

 create table last_prices_2025_05_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-26 00:00:00') TO ('2025-05-27 00:00:00');

comment on table last_prices_2025_05_26 is 'Партиция сделок за 26.05.2025';

alter table last_prices_2025_05_26
    owner to postgres;

 

 create table last_prices_2025_05_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-27 00:00:00') TO ('2025-05-28 00:00:00');

comment on table last_prices_2025_05_27 is 'Партиция сделок за 27.05.2025';

alter table last_prices_2025_05_27
    owner to postgres;

 

 create table last_prices_2025_05_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-28 00:00:00') TO ('2025-05-29 00:00:00');

comment on table last_prices_2025_05_28 is 'Партиция сделок за 28.05.2025';

alter table last_prices_2025_05_28
    owner to postgres;

 

 create table last_prices_2025_05_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-29 00:00:00') TO ('2025-05-30 00:00:00');

comment on table last_prices_2025_05_29 is 'Партиция сделок за 29.05.2025';

alter table last_prices_2025_05_29
    owner to postgres;

 

 create table last_prices_2025_05_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-30 00:00:00') TO ('2025-05-31 00:00:00');

comment on table last_prices_2025_05_30 is 'Партиция сделок за 30.05.2025';

alter table last_prices_2025_05_30
    owner to postgres;

 

 create table last_prices_2025_05_31
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-05-31 00:00:00') TO ('2025-06-01 00:00:00');

comment on table last_prices_2025_05_31 is 'Партиция сделок за 31.05.2025';

alter table last_prices_2025_05_31
    owner to postgres;

 

 create table last_prices_2025_06_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-01 00:00:00') TO ('2025-06-02 00:00:00');

comment on table last_prices_2025_06_01 is 'Партиция сделок за 01.06.2025';

alter table last_prices_2025_06_01
    owner to postgres;

 

 create table last_prices_2025_06_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-02 00:00:00') TO ('2025-06-03 00:00:00');

comment on table last_prices_2025_06_02 is 'Партиция сделок за 02.06.2025';

alter table last_prices_2025_06_02
    owner to postgres;

 

 create table last_prices_2025_06_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-03 00:00:00') TO ('2025-06-04 00:00:00');

comment on table last_prices_2025_06_03 is 'Партиция сделок за 03.06.2025';

alter table last_prices_2025_06_03
    owner to postgres;

 

 create table last_prices_2025_06_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-04 00:00:00') TO ('2025-06-05 00:00:00');

comment on table last_prices_2025_06_04 is 'Партиция сделок за 04.06.2025';

alter table last_prices_2025_06_04
    owner to postgres;

 

 create table last_prices_2025_06_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-05 00:00:00') TO ('2025-06-06 00:00:00');

comment on table last_prices_2025_06_05 is 'Партиция сделок за 05.06.2025';

alter table last_prices_2025_06_05
    owner to postgres;

 

 create table last_prices_2025_06_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-06 00:00:00') TO ('2025-06-07 00:00:00');

comment on table last_prices_2025_06_06 is 'Партиция сделок за 06.06.2025';

alter table last_prices_2025_06_06
    owner to postgres;

 

 create table last_prices_2025_06_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-07 00:00:00') TO ('2025-06-08 00:00:00');

comment on table last_prices_2025_06_07 is 'Партиция сделок за 07.06.2025';

alter table last_prices_2025_06_07
    owner to postgres;

 

 create table last_prices_2025_06_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-08 00:00:00') TO ('2025-06-09 00:00:00');

comment on table last_prices_2025_06_08 is 'Партиция сделок за 08.06.2025';

alter table last_prices_2025_06_08
    owner to postgres;

 

 create table last_prices_2025_06_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-09 00:00:00') TO ('2025-06-10 00:00:00');

comment on table last_prices_2025_06_09 is 'Партиция сделок за 09.06.2025';

alter table last_prices_2025_06_09
    owner to postgres;

 

 create table last_prices_2025_06_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-10 00:00:00') TO ('2025-06-11 00:00:00');

comment on table last_prices_2025_06_10 is 'Партиция сделок за 10.06.2025';

alter table last_prices_2025_06_10
    owner to postgres;

 

 create table last_prices_2025_06_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-11 00:00:00') TO ('2025-06-12 00:00:00');

comment on table last_prices_2025_06_11 is 'Партиция сделок за 11.06.2025';

alter table last_prices_2025_06_11
    owner to postgres;

 

 create table last_prices_2025_06_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-12 00:00:00') TO ('2025-06-13 00:00:00');

comment on table last_prices_2025_06_12 is 'Партиция сделок за 12.06.2025';

alter table last_prices_2025_06_12
    owner to postgres;

 

 create table last_prices_2025_06_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-13 00:00:00') TO ('2025-06-14 00:00:00');

comment on table last_prices_2025_06_13 is 'Партиция сделок за 13.06.2025';

alter table last_prices_2025_06_13
    owner to postgres;

 

 create table last_prices_2025_06_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-14 00:00:00') TO ('2025-06-15 00:00:00');

comment on table last_prices_2025_06_14 is 'Партиция сделок за 14.06.2025';

alter table last_prices_2025_06_14
    owner to postgres;

 

 create table last_prices_2025_06_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-15 00:00:00') TO ('2025-06-16 00:00:00');

comment on table last_prices_2025_06_15 is 'Партиция сделок за 15.06.2025';

alter table last_prices_2025_06_15
    owner to postgres;

 

 create table last_prices_2025_06_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-16 00:00:00') TO ('2025-06-17 00:00:00');

comment on table last_prices_2025_06_16 is 'Партиция сделок за 16.06.2025';

alter table last_prices_2025_06_16
    owner to postgres;

 

 create table last_prices_2025_06_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-17 00:00:00') TO ('2025-06-18 00:00:00');

comment on table last_prices_2025_06_17 is 'Партиция сделок за 17.06.2025';

alter table last_prices_2025_06_17
    owner to postgres;

 

 create table last_prices_2025_06_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-18 00:00:00') TO ('2025-06-19 00:00:00');

comment on table last_prices_2025_06_18 is 'Партиция сделок за 18.06.2025';

alter table last_prices_2025_06_18
    owner to postgres;

 

 create table last_prices_2025_06_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-19 00:00:00') TO ('2025-06-20 00:00:00');

comment on table last_prices_2025_06_19 is 'Партиция сделок за 19.06.2025';

alter table last_prices_2025_06_19
    owner to postgres;

 

 create table last_prices_2025_06_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-20 00:00:00') TO ('2025-06-21 00:00:00');

comment on table last_prices_2025_06_20 is 'Партиция сделок за 20.06.2025';

alter table last_prices_2025_06_20
    owner to postgres;

 

 create table last_prices_2025_06_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-21 00:00:00') TO ('2025-06-22 00:00:00');

comment on table last_prices_2025_06_21 is 'Партиция сделок за 21.06.2025';

alter table last_prices_2025_06_21
    owner to postgres;

 

 create table last_prices_2025_06_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-22 00:00:00') TO ('2025-06-23 00:00:00');

comment on table last_prices_2025_06_22 is 'Партиция сделок за 22.06.2025';

alter table last_prices_2025_06_22
    owner to postgres;

 

 create table last_prices_2025_06_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-23 00:00:00') TO ('2025-06-24 00:00:00');

comment on table last_prices_2025_06_23 is 'Партиция сделок за 23.06.2025';

alter table last_prices_2025_06_23
    owner to postgres;

 

 create table last_prices_2025_06_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-24 00:00:00') TO ('2025-06-25 00:00:00');

comment on table last_prices_2025_06_24 is 'Партиция сделок за 24.06.2025';

alter table last_prices_2025_06_24
    owner to postgres;

 

 create table last_prices_2025_06_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-25 00:00:00') TO ('2025-06-26 00:00:00');

comment on table last_prices_2025_06_25 is 'Партиция сделок за 25.06.2025';

alter table last_prices_2025_06_25
    owner to postgres;

 

 create table last_prices_2025_06_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-26 00:00:00') TO ('2025-06-27 00:00:00');

comment on table last_prices_2025_06_26 is 'Партиция сделок за 26.06.2025';

alter table last_prices_2025_06_26
    owner to postgres;

 

 create table last_prices_2025_06_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-27 00:00:00') TO ('2025-06-28 00:00:00');

comment on table last_prices_2025_06_27 is 'Партиция сделок за 27.06.2025';

alter table last_prices_2025_06_27
    owner to postgres;

 

 create table last_prices_2025_06_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-28 00:00:00') TO ('2025-06-29 00:00:00');

comment on table last_prices_2025_06_28 is 'Партиция сделок за 28.06.2025';

alter table last_prices_2025_06_28
    owner to postgres;

 

 create table last_prices_2025_06_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-29 00:00:00') TO ('2025-06-30 00:00:00');

comment on table last_prices_2025_06_29 is 'Партиция сделок за 29.06.2025';

alter table last_prices_2025_06_29
    owner to postgres;

 

 create table last_prices_2025_06_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-06-30 00:00:00') TO ('2025-07-01 00:00:00');

comment on table last_prices_2025_06_30 is 'Партиция сделок за 30.06.2025';

alter table last_prices_2025_06_30
    owner to postgres;

 

 create table last_prices_2025_07_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-01 00:00:00') TO ('2025-07-02 00:00:00');

comment on table last_prices_2025_07_01 is 'Партиция сделок за 01.07.2025';

alter table last_prices_2025_07_01
    owner to postgres;

 

 create table last_prices_2025_07_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-02 00:00:00') TO ('2025-07-03 00:00:00');

comment on table last_prices_2025_07_02 is 'Партиция сделок за 02.07.2025';

alter table last_prices_2025_07_02
    owner to postgres;

 

 create table last_prices_2025_07_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-03 00:00:00') TO ('2025-07-04 00:00:00');

comment on table last_prices_2025_07_03 is 'Партиция сделок за 03.07.2025';

alter table last_prices_2025_07_03
    owner to postgres;

 

 create table last_prices_2025_07_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-04 00:00:00') TO ('2025-07-05 00:00:00');

comment on table last_prices_2025_07_04 is 'Партиция сделок за 04.07.2025';

alter table last_prices_2025_07_04
    owner to postgres;

 

 create table last_prices_2025_07_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-05 00:00:00') TO ('2025-07-06 00:00:00');

comment on table last_prices_2025_07_05 is 'Партиция сделок за 05.07.2025';

alter table last_prices_2025_07_05
    owner to postgres;

 

 create table last_prices_2025_07_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-06 00:00:00') TO ('2025-07-07 00:00:00');

comment on table last_prices_2025_07_06 is 'Партиция сделок за 06.07.2025';

alter table last_prices_2025_07_06
    owner to postgres;

 

 create table last_prices_2025_07_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-07 00:00:00') TO ('2025-07-08 00:00:00');

comment on table last_prices_2025_07_07 is 'Партиция сделок за 07.07.2025';

alter table last_prices_2025_07_07
    owner to postgres;

 

 create table last_prices_2025_07_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-08 00:00:00') TO ('2025-07-09 00:00:00');

comment on table last_prices_2025_07_08 is 'Партиция сделок за 08.07.2025';

alter table last_prices_2025_07_08
    owner to postgres;

 

 create table last_prices_2025_07_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-09 00:00:00') TO ('2025-07-10 00:00:00');

comment on table last_prices_2025_07_09 is 'Партиция сделок за 09.07.2025';

alter table last_prices_2025_07_09
    owner to postgres;

 

 create table last_prices_2025_07_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-10 00:00:00') TO ('2025-07-11 00:00:00');

comment on table last_prices_2025_07_10 is 'Партиция сделок за 10.07.2025';

alter table last_prices_2025_07_10
    owner to postgres;

 

 create table last_prices_2025_07_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-11 00:00:00') TO ('2025-07-12 00:00:00');

comment on table last_prices_2025_07_11 is 'Партиция сделок за 11.07.2025';

alter table last_prices_2025_07_11
    owner to postgres;

 

 create table last_prices_2025_07_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-12 00:00:00') TO ('2025-07-13 00:00:00');

comment on table last_prices_2025_07_12 is 'Партиция сделок за 12.07.2025';

alter table last_prices_2025_07_12
    owner to postgres;

 

 create table last_prices_2025_07_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-13 00:00:00') TO ('2025-07-14 00:00:00');

comment on table last_prices_2025_07_13 is 'Партиция сделок за 13.07.2025';

alter table last_prices_2025_07_13
    owner to postgres;

 

 create table last_prices_2025_07_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-14 00:00:00') TO ('2025-07-15 00:00:00');

comment on table last_prices_2025_07_14 is 'Партиция сделок за 14.07.2025';

alter table last_prices_2025_07_14
    owner to postgres;

 

 create table last_prices_2025_07_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-15 00:00:00') TO ('2025-07-16 00:00:00');

comment on table last_prices_2025_07_15 is 'Партиция сделок за 15.07.2025';

alter table last_prices_2025_07_15
    owner to postgres;

 

 create table last_prices_2025_07_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-16 00:00:00') TO ('2025-07-17 00:00:00');

comment on table last_prices_2025_07_16 is 'Партиция сделок за 16.07.2025';

alter table last_prices_2025_07_16
    owner to postgres;

 

 create table last_prices_2025_07_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-17 00:00:00') TO ('2025-07-18 00:00:00');

comment on table last_prices_2025_07_17 is 'Партиция сделок за 17.07.2025';

alter table last_prices_2025_07_17
    owner to postgres;

 

 create table last_prices_2025_07_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-18 00:00:00') TO ('2025-07-19 00:00:00');

comment on table last_prices_2025_07_18 is 'Партиция сделок за 18.07.2025';

alter table last_prices_2025_07_18
    owner to postgres;

 

 create table last_prices_2025_07_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-19 00:00:00') TO ('2025-07-20 00:00:00');

comment on table last_prices_2025_07_19 is 'Партиция сделок за 19.07.2025';

alter table last_prices_2025_07_19
    owner to postgres;

 

 create table last_prices_2025_07_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-20 00:00:00') TO ('2025-07-21 00:00:00');

comment on table last_prices_2025_07_20 is 'Партиция сделок за 20.07.2025';

alter table last_prices_2025_07_20
    owner to postgres;

 

 create table last_prices_2025_07_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-21 00:00:00') TO ('2025-07-22 00:00:00');

comment on table last_prices_2025_07_21 is 'Партиция сделок за 21.07.2025';

alter table last_prices_2025_07_21
    owner to postgres;

 

 create table last_prices_2025_07_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-22 00:00:00') TO ('2025-07-23 00:00:00');

comment on table last_prices_2025_07_22 is 'Партиция сделок за 22.07.2025';

alter table last_prices_2025_07_22
    owner to postgres;

 

 create table last_prices_2025_07_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-23 00:00:00') TO ('2025-07-24 00:00:00');

comment on table last_prices_2025_07_23 is 'Партиция сделок за 23.07.2025';

alter table last_prices_2025_07_23
    owner to postgres;

 

 create table last_prices_2025_07_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-24 00:00:00') TO ('2025-07-25 00:00:00');

comment on table last_prices_2025_07_24 is 'Партиция сделок за 24.07.2025';

alter table last_prices_2025_07_24
    owner to postgres;

 

 create table last_prices_2025_07_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-25 00:00:00') TO ('2025-07-26 00:00:00');

comment on table last_prices_2025_07_25 is 'Партиция сделок за 25.07.2025';

alter table last_prices_2025_07_25
    owner to postgres;

 

 create table last_prices_2025_07_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-26 00:00:00') TO ('2025-07-27 00:00:00');

comment on table last_prices_2025_07_26 is 'Партиция сделок за 26.07.2025';

alter table last_prices_2025_07_26
    owner to postgres;

 

 create table last_prices_2025_07_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-27 00:00:00') TO ('2025-07-28 00:00:00');

comment on table last_prices_2025_07_27 is 'Партиция сделок за 27.07.2025';

alter table last_prices_2025_07_27
    owner to postgres;

 

 create table last_prices_2025_07_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-28 00:00:00') TO ('2025-07-29 00:00:00');

comment on table last_prices_2025_07_28 is 'Партиция сделок за 28.07.2025';

alter table last_prices_2025_07_28
    owner to postgres;

 

 create table last_prices_2025_07_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-29 00:00:00') TO ('2025-07-30 00:00:00');

comment on table last_prices_2025_07_29 is 'Партиция сделок за 29.07.2025';

alter table last_prices_2025_07_29
    owner to postgres;

 

 create table last_prices_2025_07_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-30 00:00:00') TO ('2025-07-31 00:00:00');

comment on table last_prices_2025_07_30 is 'Партиция сделок за 30.07.2025';

alter table last_prices_2025_07_30
    owner to postgres;

 

 create table last_prices_2025_07_31
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-07-31 00:00:00') TO ('2025-08-01 00:00:00');

comment on table last_prices_2025_07_31 is 'Партиция сделок за 31.07.2025';

alter table last_prices_2025_07_31
    owner to postgres;

 

 create table last_prices_2025_08_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-01 00:00:00') TO ('2025-08-02 00:00:00');

comment on table last_prices_2025_08_01 is 'Партиция сделок за 01.08.2025';

alter table last_prices_2025_08_01
    owner to postgres;

 

 create table last_prices_2025_08_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-02 00:00:00') TO ('2025-08-03 00:00:00');

comment on table last_prices_2025_08_02 is 'Партиция сделок за 02.08.2025';

alter table last_prices_2025_08_02
    owner to postgres;

 

 create table last_prices_2025_08_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-03 00:00:00') TO ('2025-08-04 00:00:00');

comment on table last_prices_2025_08_03 is 'Партиция сделок за 03.08.2025';

alter table last_prices_2025_08_03
    owner to postgres;

 

 create table last_prices_2025_08_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-04 00:00:00') TO ('2025-08-05 00:00:00');

comment on table last_prices_2025_08_04 is 'Партиция сделок за 04.08.2025';

alter table last_prices_2025_08_04
    owner to postgres;

 

 create table last_prices_2025_08_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-05 00:00:00') TO ('2025-08-06 00:00:00');

comment on table last_prices_2025_08_05 is 'Партиция сделок за 05.08.2025';

alter table last_prices_2025_08_05
    owner to postgres;

 

 create table last_prices_2025_08_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-06 00:00:00') TO ('2025-08-07 00:00:00');

comment on table last_prices_2025_08_06 is 'Партиция сделок за 06.08.2025';

alter table last_prices_2025_08_06
    owner to postgres;

 

 create table last_prices_2025_08_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-07 00:00:00') TO ('2025-08-08 00:00:00');

comment on table last_prices_2025_08_07 is 'Партиция сделок за 07.08.2025';

alter table last_prices_2025_08_07
    owner to postgres;

 

 create table last_prices_2025_08_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-08 00:00:00') TO ('2025-08-09 00:00:00');

comment on table last_prices_2025_08_08 is 'Партиция сделок за 08.08.2025';

alter table last_prices_2025_08_08
    owner to postgres;

 

 create table last_prices_2025_08_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-09 00:00:00') TO ('2025-08-10 00:00:00');

comment on table last_prices_2025_08_09 is 'Партиция сделок за 09.08.2025';

alter table last_prices_2025_08_09
    owner to postgres;

 

 create table last_prices_2025_08_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-10 00:00:00') TO ('2025-08-11 00:00:00');

comment on table last_prices_2025_08_10 is 'Партиция сделок за 10.08.2025';

alter table last_prices_2025_08_10
    owner to postgres;

 

 create table last_prices_2025_08_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-11 00:00:00') TO ('2025-08-12 00:00:00');

comment on table last_prices_2025_08_11 is 'Партиция сделок за 11.08.2025';

alter table last_prices_2025_08_11
    owner to postgres;

 

 create table last_prices_2025_08_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-12 00:00:00') TO ('2025-08-13 00:00:00');

comment on table last_prices_2025_08_12 is 'Партиция сделок за 12.08.2025';

alter table last_prices_2025_08_12
    owner to postgres;

 

 create table last_prices_2025_08_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-13 00:00:00') TO ('2025-08-14 00:00:00');

comment on table last_prices_2025_08_13 is 'Партиция сделок за 13.08.2025';

alter table last_prices_2025_08_13
    owner to postgres;

 

 create table last_prices_2025_08_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-14 00:00:00') TO ('2025-08-15 00:00:00');

comment on table last_prices_2025_08_14 is 'Партиция сделок за 14.08.2025';

alter table last_prices_2025_08_14
    owner to postgres;

 

 create table last_prices_2025_08_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-15 00:00:00') TO ('2025-08-16 00:00:00');

comment on table last_prices_2025_08_15 is 'Партиция сделок за 15.08.2025';

alter table last_prices_2025_08_15
    owner to postgres;

 

 create table last_prices_2025_08_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-16 00:00:00') TO ('2025-08-17 00:00:00');

comment on table last_prices_2025_08_16 is 'Партиция сделок за 16.08.2025';

alter table last_prices_2025_08_16
    owner to postgres;

 

 create table last_prices_2025_08_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-17 00:00:00') TO ('2025-08-18 00:00:00');

comment on table last_prices_2025_08_17 is 'Партиция сделок за 17.08.2025';

alter table last_prices_2025_08_17
    owner to postgres;

 

 create table last_prices_2025_08_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-18 00:00:00') TO ('2025-08-19 00:00:00');

comment on table last_prices_2025_08_18 is 'Партиция сделок за 18.08.2025';

alter table last_prices_2025_08_18
    owner to postgres;

 

 create table last_prices_2025_08_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-19 00:00:00') TO ('2025-08-20 00:00:00');

comment on table last_prices_2025_08_19 is 'Партиция сделок за 19.08.2025';

alter table last_prices_2025_08_19
    owner to postgres;

 

 create table last_prices_2025_08_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-20 00:00:00') TO ('2025-08-21 00:00:00');

comment on table last_prices_2025_08_20 is 'Партиция сделок за 20.08.2025';

alter table last_prices_2025_08_20
    owner to postgres;

 

 create table last_prices_2025_08_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-21 00:00:00') TO ('2025-08-22 00:00:00');

comment on table last_prices_2025_08_21 is 'Партиция сделок за 21.08.2025';

alter table last_prices_2025_08_21
    owner to postgres;

 

 create table last_prices_2025_08_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-22 00:00:00') TO ('2025-08-23 00:00:00');

comment on table last_prices_2025_08_22 is 'Партиция сделок за 22.08.2025';

alter table last_prices_2025_08_22
    owner to postgres;

 

 create table last_prices_2025_08_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-23 00:00:00') TO ('2025-08-24 00:00:00');

comment on table last_prices_2025_08_23 is 'Партиция сделок за 23.08.2025';

alter table last_prices_2025_08_23
    owner to postgres;

 

 create table last_prices_2025_08_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-24 00:00:00') TO ('2025-08-25 00:00:00');

comment on table last_prices_2025_08_24 is 'Партиция сделок за 24.08.2025';

alter table last_prices_2025_08_24
    owner to postgres;

 

 create table last_prices_2025_08_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-25 00:00:00') TO ('2025-08-26 00:00:00');

comment on table last_prices_2025_08_25 is 'Партиция сделок за 25.08.2025';

alter table last_prices_2025_08_25
    owner to postgres;

 

 create table last_prices_2025_08_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-26 00:00:00') TO ('2025-08-27 00:00:00');

comment on table last_prices_2025_08_26 is 'Партиция сделок за 26.08.2025';

alter table last_prices_2025_08_26
    owner to postgres;

 

 create table last_prices_2025_08_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-27 00:00:00') TO ('2025-08-28 00:00:00');

comment on table last_prices_2025_08_27 is 'Партиция сделок за 27.08.2025';

alter table last_prices_2025_08_27
    owner to postgres;

 

 create table last_prices_2025_08_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-28 00:00:00') TO ('2025-08-29 00:00:00');

comment on table last_prices_2025_08_28 is 'Партиция сделок за 28.08.2025';

alter table last_prices_2025_08_28
    owner to postgres;

 

 create table last_prices_2025_08_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-29 00:00:00') TO ('2025-08-30 00:00:00');

comment on table last_prices_2025_08_29 is 'Партиция сделок за 29.08.2025';

alter table last_prices_2025_08_29
    owner to postgres;

 

 create table last_prices_2025_08_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-30 00:00:00') TO ('2025-08-31 00:00:00');

comment on table last_prices_2025_08_30 is 'Партиция сделок за 30.08.2025';

alter table last_prices_2025_08_30
    owner to postgres;

 

 create table last_prices_2025_08_31
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-08-31 00:00:00') TO ('2025-09-01 00:00:00');

comment on table last_prices_2025_08_31 is 'Партиция сделок за 31.08.2025';

alter table last_prices_2025_08_31
    owner to postgres;

 

 create table last_prices_2025_09_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-01 00:00:00') TO ('2025-09-02 00:00:00');

comment on table last_prices_2025_09_01 is 'Партиция сделок за 01.09.2025';

alter table last_prices_2025_09_01
    owner to postgres;

 

 create table last_prices_2025_09_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-02 00:00:00') TO ('2025-09-03 00:00:00');

comment on table last_prices_2025_09_02 is 'Партиция сделок за 02.09.2025';

alter table last_prices_2025_09_02
    owner to postgres;

 

 create table last_prices_2025_09_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-03 00:00:00') TO ('2025-09-04 00:00:00');

comment on table last_prices_2025_09_03 is 'Партиция сделок за 03.09.2025';

alter table last_prices_2025_09_03
    owner to postgres;

 

 create table last_prices_2025_09_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-04 00:00:00') TO ('2025-09-05 00:00:00');

comment on table last_prices_2025_09_04 is 'Партиция сделок за 04.09.2025';

alter table last_prices_2025_09_04
    owner to postgres;

 

 create table last_prices_2025_09_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-05 00:00:00') TO ('2025-09-06 00:00:00');

comment on table last_prices_2025_09_05 is 'Партиция сделок за 05.09.2025';

alter table last_prices_2025_09_05
    owner to postgres;

 

 create table last_prices_2025_09_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-06 00:00:00') TO ('2025-09-07 00:00:00');

comment on table last_prices_2025_09_06 is 'Партиция сделок за 06.09.2025';

alter table last_prices_2025_09_06
    owner to postgres;

 

 create table last_prices_2025_09_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-07 00:00:00') TO ('2025-09-08 00:00:00');

comment on table last_prices_2025_09_07 is 'Партиция сделок за 07.09.2025';

alter table last_prices_2025_09_07
    owner to postgres;

 

 create table last_prices_2025_09_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-08 00:00:00') TO ('2025-09-09 00:00:00');

comment on table last_prices_2025_09_08 is 'Партиция сделок за 08.09.2025';

alter table last_prices_2025_09_08
    owner to postgres;

 

 create table last_prices_2025_09_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-09 00:00:00') TO ('2025-09-10 00:00:00');

comment on table last_prices_2025_09_09 is 'Партиция сделок за 09.09.2025';

alter table last_prices_2025_09_09
    owner to postgres;

 

 create table last_prices_2025_09_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-10 00:00:00') TO ('2025-09-11 00:00:00');

comment on table last_prices_2025_09_10 is 'Партиция сделок за 10.09.2025';

alter table last_prices_2025_09_10
    owner to postgres;

 

 create table last_prices_2025_09_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-11 00:00:00') TO ('2025-09-12 00:00:00');

comment on table last_prices_2025_09_11 is 'Партиция сделок за 11.09.2025';

alter table last_prices_2025_09_11
    owner to postgres;

 

 create table last_prices_2025_09_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-12 00:00:00') TO ('2025-09-13 00:00:00');

comment on table last_prices_2025_09_12 is 'Партиция сделок за 12.09.2025';

alter table last_prices_2025_09_12
    owner to postgres;

 

 create table last_prices_2025_09_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-13 00:00:00') TO ('2025-09-14 00:00:00');

comment on table last_prices_2025_09_13 is 'Партиция сделок за 13.09.2025';

alter table last_prices_2025_09_13
    owner to postgres;

 

 create table last_prices_2025_09_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-14 00:00:00') TO ('2025-09-15 00:00:00');

comment on table last_prices_2025_09_14 is 'Партиция сделок за 14.09.2025';

alter table last_prices_2025_09_14
    owner to postgres;

 

 create table last_prices_2025_09_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-15 00:00:00') TO ('2025-09-16 00:00:00');

comment on table last_prices_2025_09_15 is 'Партиция сделок за 15.09.2025';

alter table last_prices_2025_09_15
    owner to postgres;

 

 create table last_prices_2025_09_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-16 00:00:00') TO ('2025-09-17 00:00:00');

comment on table last_prices_2025_09_16 is 'Партиция сделок за 16.09.2025';

alter table last_prices_2025_09_16
    owner to postgres;

 

 create table last_prices_2025_09_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-17 00:00:00') TO ('2025-09-18 00:00:00');

comment on table last_prices_2025_09_17 is 'Партиция сделок за 17.09.2025';

alter table last_prices_2025_09_17
    owner to postgres;

 

 create table last_prices_2025_09_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-18 00:00:00') TO ('2025-09-19 00:00:00');

comment on table last_prices_2025_09_18 is 'Партиция сделок за 18.09.2025';

alter table last_prices_2025_09_18
    owner to postgres;

 

 create table last_prices_2025_09_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-19 00:00:00') TO ('2025-09-20 00:00:00');

comment on table last_prices_2025_09_19 is 'Партиция сделок за 19.09.2025';

alter table last_prices_2025_09_19
    owner to postgres;

 

 create table last_prices_2025_09_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-20 00:00:00') TO ('2025-09-21 00:00:00');

comment on table last_prices_2025_09_20 is 'Партиция сделок за 20.09.2025';

alter table last_prices_2025_09_20
    owner to postgres;

 

 create table last_prices_2025_09_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-21 00:00:00') TO ('2025-09-22 00:00:00');

comment on table last_prices_2025_09_21 is 'Партиция сделок за 21.09.2025';

alter table last_prices_2025_09_21
    owner to postgres;

 

 create table last_prices_2025_09_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-22 00:00:00') TO ('2025-09-23 00:00:00');

comment on table last_prices_2025_09_22 is 'Партиция сделок за 22.09.2025';

alter table last_prices_2025_09_22
    owner to postgres;

 

 create table last_prices_2025_09_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-23 00:00:00') TO ('2025-09-24 00:00:00');

comment on table last_prices_2025_09_23 is 'Партиция сделок за 23.09.2025';

alter table last_prices_2025_09_23
    owner to postgres;

 

 create table last_prices_2025_09_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-24 00:00:00') TO ('2025-09-25 00:00:00');

comment on table last_prices_2025_09_24 is 'Партиция сделок за 24.09.2025';

alter table last_prices_2025_09_24
    owner to postgres;

 

 create table last_prices_2025_09_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-25 00:00:00') TO ('2025-09-26 00:00:00');

comment on table last_prices_2025_09_25 is 'Партиция сделок за 25.09.2025';

alter table last_prices_2025_09_25
    owner to postgres;

 

 create table last_prices_2025_09_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-26 00:00:00') TO ('2025-09-27 00:00:00');

comment on table last_prices_2025_09_26 is 'Партиция сделок за 26.09.2025';

alter table last_prices_2025_09_26
    owner to postgres;

 

 create table last_prices_2025_09_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-27 00:00:00') TO ('2025-09-28 00:00:00');

comment on table last_prices_2025_09_27 is 'Партиция сделок за 27.09.2025';

alter table last_prices_2025_09_27
    owner to postgres;

 

 create table last_prices_2025_09_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-28 00:00:00') TO ('2025-09-29 00:00:00');

comment on table last_prices_2025_09_28 is 'Партиция сделок за 28.09.2025';

alter table last_prices_2025_09_28
    owner to postgres;

 

 create table last_prices_2025_09_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-29 00:00:00') TO ('2025-09-30 00:00:00');

comment on table last_prices_2025_09_29 is 'Партиция сделок за 29.09.2025';

alter table last_prices_2025_09_29
    owner to postgres;

 

 create table last_prices_2025_09_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-09-30 00:00:00') TO ('2025-10-01 00:00:00');

comment on table last_prices_2025_09_30 is 'Партиция сделок за 30.09.2025';

alter table last_prices_2025_09_30
    owner to postgres;

 

 create table last_prices_2025_10_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-01 00:00:00') TO ('2025-10-02 00:00:00');

comment on table last_prices_2025_10_01 is 'Партиция сделок за 01.10.2025';

alter table last_prices_2025_10_01
    owner to postgres;

 

 create table last_prices_2025_10_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-02 00:00:00') TO ('2025-10-03 00:00:00');

comment on table last_prices_2025_10_02 is 'Партиция сделок за 02.10.2025';

alter table last_prices_2025_10_02
    owner to postgres;

 

 create table last_prices_2025_10_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-03 00:00:00') TO ('2025-10-04 00:00:00');

comment on table last_prices_2025_10_03 is 'Партиция сделок за 03.10.2025';

alter table last_prices_2025_10_03
    owner to postgres;

 

 create table last_prices_2025_10_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-04 00:00:00') TO ('2025-10-05 00:00:00');

comment on table last_prices_2025_10_04 is 'Партиция сделок за 04.10.2025';

alter table last_prices_2025_10_04
    owner to postgres;

 

 create table last_prices_2025_10_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-05 00:00:00') TO ('2025-10-06 00:00:00');

comment on table last_prices_2025_10_05 is 'Партиция сделок за 05.10.2025';

alter table last_prices_2025_10_05
    owner to postgres;

 

 create table last_prices_2025_10_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-06 00:00:00') TO ('2025-10-07 00:00:00');

comment on table last_prices_2025_10_06 is 'Партиция сделок за 06.10.2025';

alter table last_prices_2025_10_06
    owner to postgres;

 

 create table last_prices_2025_10_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-07 00:00:00') TO ('2025-10-08 00:00:00');

comment on table last_prices_2025_10_07 is 'Партиция сделок за 07.10.2025';

alter table last_prices_2025_10_07
    owner to postgres;

 

 create table last_prices_2025_10_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-08 00:00:00') TO ('2025-10-09 00:00:00');

comment on table last_prices_2025_10_08 is 'Партиция сделок за 08.10.2025';

alter table last_prices_2025_10_08
    owner to postgres;

 

 create table last_prices_2025_10_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-09 00:00:00') TO ('2025-10-10 00:00:00');

comment on table last_prices_2025_10_09 is 'Партиция сделок за 09.10.2025';

alter table last_prices_2025_10_09
    owner to postgres;

 

 create table last_prices_2025_10_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-10 00:00:00') TO ('2025-10-11 00:00:00');

comment on table last_prices_2025_10_10 is 'Партиция сделок за 10.10.2025';

alter table last_prices_2025_10_10
    owner to postgres;

 

 create table last_prices_2025_10_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-11 00:00:00') TO ('2025-10-12 00:00:00');

comment on table last_prices_2025_10_11 is 'Партиция сделок за 11.10.2025';

alter table last_prices_2025_10_11
    owner to postgres;

 

 create table last_prices_2025_10_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-12 00:00:00') TO ('2025-10-13 00:00:00');

comment on table last_prices_2025_10_12 is 'Партиция сделок за 12.10.2025';

alter table last_prices_2025_10_12
    owner to postgres;

 

 create table last_prices_2025_10_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-13 00:00:00') TO ('2025-10-14 00:00:00');

comment on table last_prices_2025_10_13 is 'Партиция сделок за 13.10.2025';

alter table last_prices_2025_10_13
    owner to postgres;

 

 create table last_prices_2025_10_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-14 00:00:00') TO ('2025-10-15 00:00:00');

comment on table last_prices_2025_10_14 is 'Партиция сделок за 14.10.2025';

alter table last_prices_2025_10_14
    owner to postgres;

 

 create table last_prices_2025_10_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-15 00:00:00') TO ('2025-10-16 00:00:00');

comment on table last_prices_2025_10_15 is 'Партиция сделок за 15.10.2025';

alter table last_prices_2025_10_15
    owner to postgres;

 

 create table last_prices_2025_10_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-16 00:00:00') TO ('2025-10-17 00:00:00');

comment on table last_prices_2025_10_16 is 'Партиция сделок за 16.10.2025';

alter table last_prices_2025_10_16
    owner to postgres;

 

 create table last_prices_2025_10_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-17 00:00:00') TO ('2025-10-18 00:00:00');

comment on table last_prices_2025_10_17 is 'Партиция сделок за 17.10.2025';

alter table last_prices_2025_10_17
    owner to postgres;

 

 create table last_prices_2025_10_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-18 00:00:00') TO ('2025-10-19 00:00:00');

comment on table last_prices_2025_10_18 is 'Партиция сделок за 18.10.2025';

alter table last_prices_2025_10_18
    owner to postgres;

 

 create table last_prices_2025_10_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-19 00:00:00') TO ('2025-10-20 00:00:00');

comment on table last_prices_2025_10_19 is 'Партиция сделок за 19.10.2025';

alter table last_prices_2025_10_19
    owner to postgres;

 

 create table last_prices_2025_10_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-20 00:00:00') TO ('2025-10-21 00:00:00');

comment on table last_prices_2025_10_20 is 'Партиция сделок за 20.10.2025';

alter table last_prices_2025_10_20
    owner to postgres;

 

 create table last_prices_2025_10_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-21 00:00:00') TO ('2025-10-22 00:00:00');

comment on table last_prices_2025_10_21 is 'Партиция сделок за 21.10.2025';

alter table last_prices_2025_10_21
    owner to postgres;

 

 create table last_prices_2025_10_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-22 00:00:00') TO ('2025-10-23 00:00:00');

comment on table last_prices_2025_10_22 is 'Партиция сделок за 22.10.2025';

alter table last_prices_2025_10_22
    owner to postgres;

 

 create table last_prices_2025_10_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-23 00:00:00') TO ('2025-10-24 00:00:00');

comment on table last_prices_2025_10_23 is 'Партиция сделок за 23.10.2025';

alter table last_prices_2025_10_23
    owner to postgres;

 

 create table last_prices_2025_10_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-24 00:00:00') TO ('2025-10-25 00:00:00');

comment on table last_prices_2025_10_24 is 'Партиция сделок за 24.10.2025';

alter table last_prices_2025_10_24
    owner to postgres;

 

 create table last_prices_2025_10_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-25 00:00:00') TO ('2025-10-26 00:00:00');

comment on table last_prices_2025_10_25 is 'Партиция сделок за 25.10.2025';

alter table last_prices_2025_10_25
    owner to postgres;

 

 create table last_prices_2025_10_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-26 00:00:00') TO ('2025-10-27 00:00:00');

comment on table last_prices_2025_10_26 is 'Партиция сделок за 26.10.2025';

alter table last_prices_2025_10_26
    owner to postgres;

 

 create table last_prices_2025_10_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-27 00:00:00') TO ('2025-10-28 00:00:00');

comment on table last_prices_2025_10_27 is 'Партиция сделок за 27.10.2025';

alter table last_prices_2025_10_27
    owner to postgres;

 

 create table last_prices_2025_10_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-28 00:00:00') TO ('2025-10-29 00:00:00');

comment on table last_prices_2025_10_28 is 'Партиция сделок за 28.10.2025';

alter table last_prices_2025_10_28
    owner to postgres;

 

 create table last_prices_2025_10_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-29 00:00:00') TO ('2025-10-30 00:00:00');

comment on table last_prices_2025_10_29 is 'Партиция сделок за 29.10.2025';

alter table last_prices_2025_10_29
    owner to postgres;

 

 create table last_prices_2025_10_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-30 00:00:00') TO ('2025-10-31 00:00:00');

comment on table last_prices_2025_10_30 is 'Партиция сделок за 30.10.2025';

alter table last_prices_2025_10_30
    owner to postgres;

 

 create table last_prices_2025_10_31
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-10-31 00:00:00') TO ('2025-11-01 00:00:00');

comment on table last_prices_2025_10_31 is 'Партиция сделок за 31.10.2025';

alter table last_prices_2025_10_31
    owner to postgres;

 

 create table last_prices_2025_11_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-01 00:00:00') TO ('2025-11-02 00:00:00');

comment on table last_prices_2025_11_01 is 'Партиция сделок за 01.11.2025';

alter table last_prices_2025_11_01
    owner to postgres;

 

 create table last_prices_2025_11_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-02 00:00:00') TO ('2025-11-03 00:00:00');

comment on table last_prices_2025_11_02 is 'Партиция сделок за 02.11.2025';

alter table last_prices_2025_11_02
    owner to postgres;

 

 create table last_prices_2025_11_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-03 00:00:00') TO ('2025-11-04 00:00:00');

comment on table last_prices_2025_11_03 is 'Партиция сделок за 03.11.2025';

alter table last_prices_2025_11_03
    owner to postgres;

 

 create table last_prices_2025_11_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-04 00:00:00') TO ('2025-11-05 00:00:00');

comment on table last_prices_2025_11_04 is 'Партиция сделок за 04.11.2025';

alter table last_prices_2025_11_04
    owner to postgres;

 

 create table last_prices_2025_11_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-05 00:00:00') TO ('2025-11-06 00:00:00');

comment on table last_prices_2025_11_05 is 'Партиция сделок за 05.11.2025';

alter table last_prices_2025_11_05
    owner to postgres;

 

 create table last_prices_2025_11_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-06 00:00:00') TO ('2025-11-07 00:00:00');

comment on table last_prices_2025_11_06 is 'Партиция сделок за 06.11.2025';

alter table last_prices_2025_11_06
    owner to postgres;

 

 create table last_prices_2025_11_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-07 00:00:00') TO ('2025-11-08 00:00:00');

comment on table last_prices_2025_11_07 is 'Партиция сделок за 07.11.2025';

alter table last_prices_2025_11_07
    owner to postgres;

 

 create table last_prices_2025_11_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-08 00:00:00') TO ('2025-11-09 00:00:00');

comment on table last_prices_2025_11_08 is 'Партиция сделок за 08.11.2025';

alter table last_prices_2025_11_08
    owner to postgres;

 

 create table last_prices_2025_11_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-09 00:00:00') TO ('2025-11-10 00:00:00');

comment on table last_prices_2025_11_09 is 'Партиция сделок за 09.11.2025';

alter table last_prices_2025_11_09
    owner to postgres;

 

 create table last_prices_2025_11_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-10 00:00:00') TO ('2025-11-11 00:00:00');

comment on table last_prices_2025_11_10 is 'Партиция сделок за 10.11.2025';

alter table last_prices_2025_11_10
    owner to postgres;

 

 create table last_prices_2025_11_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-11 00:00:00') TO ('2025-11-12 00:00:00');

comment on table last_prices_2025_11_11 is 'Партиция сделок за 11.11.2025';

alter table last_prices_2025_11_11
    owner to postgres;

 

 create table last_prices_2025_11_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-12 00:00:00') TO ('2025-11-13 00:00:00');

comment on table last_prices_2025_11_12 is 'Партиция сделок за 12.11.2025';

alter table last_prices_2025_11_12
    owner to postgres;

 

 create table last_prices_2025_11_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-13 00:00:00') TO ('2025-11-14 00:00:00');

comment on table last_prices_2025_11_13 is 'Партиция сделок за 13.11.2025';

alter table last_prices_2025_11_13
    owner to postgres;

 

 create table last_prices_2025_11_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-14 00:00:00') TO ('2025-11-15 00:00:00');

comment on table last_prices_2025_11_14 is 'Партиция сделок за 14.11.2025';

alter table last_prices_2025_11_14
    owner to postgres;

 

 create table last_prices_2025_11_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-15 00:00:00') TO ('2025-11-16 00:00:00');

comment on table last_prices_2025_11_15 is 'Партиция сделок за 15.11.2025';

alter table last_prices_2025_11_15
    owner to postgres;

 

 create table last_prices_2025_11_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-16 00:00:00') TO ('2025-11-17 00:00:00');

comment on table last_prices_2025_11_16 is 'Партиция сделок за 16.11.2025';

alter table last_prices_2025_11_16
    owner to postgres;

 

 create table last_prices_2025_11_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-17 00:00:00') TO ('2025-11-18 00:00:00');

comment on table last_prices_2025_11_17 is 'Партиция сделок за 17.11.2025';

alter table last_prices_2025_11_17
    owner to postgres;

 

 create table last_prices_2025_11_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-18 00:00:00') TO ('2025-11-19 00:00:00');

comment on table last_prices_2025_11_18 is 'Партиция сделок за 18.11.2025';

alter table last_prices_2025_11_18
    owner to postgres;

 

 create table last_prices_2025_11_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-19 00:00:00') TO ('2025-11-20 00:00:00');

comment on table last_prices_2025_11_19 is 'Партиция сделок за 19.11.2025';

alter table last_prices_2025_11_19
    owner to postgres;

 

 create table last_prices_2025_11_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-20 00:00:00') TO ('2025-11-21 00:00:00');

comment on table last_prices_2025_11_20 is 'Партиция сделок за 20.11.2025';

alter table last_prices_2025_11_20
    owner to postgres;

 

 create table last_prices_2025_11_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-21 00:00:00') TO ('2025-11-22 00:00:00');

comment on table last_prices_2025_11_21 is 'Партиция сделок за 21.11.2025';

alter table last_prices_2025_11_21
    owner to postgres;

 

 create table last_prices_2025_11_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-22 00:00:00') TO ('2025-11-23 00:00:00');

comment on table last_prices_2025_11_22 is 'Партиция сделок за 22.11.2025';

alter table last_prices_2025_11_22
    owner to postgres;

 

 create table last_prices_2025_11_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-23 00:00:00') TO ('2025-11-24 00:00:00');

comment on table last_prices_2025_11_23 is 'Партиция сделок за 23.11.2025';

alter table last_prices_2025_11_23
    owner to postgres;

 

 create table last_prices_2025_11_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-24 00:00:00') TO ('2025-11-25 00:00:00');

comment on table last_prices_2025_11_24 is 'Партиция сделок за 24.11.2025';

alter table last_prices_2025_11_24
    owner to postgres;

 

 create table last_prices_2025_11_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-25 00:00:00') TO ('2025-11-26 00:00:00');

comment on table last_prices_2025_11_25 is 'Партиция сделок за 25.11.2025';

alter table last_prices_2025_11_25
    owner to postgres;

 

 create table last_prices_2025_11_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-26 00:00:00') TO ('2025-11-27 00:00:00');

comment on table last_prices_2025_11_26 is 'Партиция сделок за 26.11.2025';

alter table last_prices_2025_11_26
    owner to postgres;

 

 create table last_prices_2025_11_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-27 00:00:00') TO ('2025-11-28 00:00:00');

comment on table last_prices_2025_11_27 is 'Партиция сделок за 27.11.2025';

alter table last_prices_2025_11_27
    owner to postgres;

 

 create table last_prices_2025_11_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-28 00:00:00') TO ('2025-11-29 00:00:00');

comment on table last_prices_2025_11_28 is 'Партиция сделок за 28.11.2025';

alter table last_prices_2025_11_28
    owner to postgres;

 

 create table last_prices_2025_11_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-29 00:00:00') TO ('2025-11-30 00:00:00');

comment on table last_prices_2025_11_29 is 'Партиция сделок за 29.11.2025';

alter table last_prices_2025_11_29
    owner to postgres;

 

 create table last_prices_2025_11_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-11-30 00:00:00') TO ('2025-12-01 00:00:00');

comment on table last_prices_2025_11_30 is 'Партиция сделок за 30.11.2025';

alter table last_prices_2025_11_30
    owner to postgres;

 

 create table last_prices_2025_12_01
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-01 00:00:00') TO ('2025-12-02 00:00:00');

comment on table last_prices_2025_12_01 is 'Партиция сделок за 01.12.2025';

alter table last_prices_2025_12_01
    owner to postgres;

 

 create table last_prices_2025_12_02
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-02 00:00:00') TO ('2025-12-03 00:00:00');

comment on table last_prices_2025_12_02 is 'Партиция сделок за 02.12.2025';

alter table last_prices_2025_12_02
    owner to postgres;

 

 create table last_prices_2025_12_03
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-03 00:00:00') TO ('2025-12-04 00:00:00');

comment on table last_prices_2025_12_03 is 'Партиция сделок за 03.12.2025';

alter table last_prices_2025_12_03
    owner to postgres;

 

 create table last_prices_2025_12_04
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-04 00:00:00') TO ('2025-12-05 00:00:00');

comment on table last_prices_2025_12_04 is 'Партиция сделок за 04.12.2025';

alter table last_prices_2025_12_04
    owner to postgres;

 

 create table last_prices_2025_12_05
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-05 00:00:00') TO ('2025-12-06 00:00:00');

comment on table last_prices_2025_12_05 is 'Партиция сделок за 05.12.2025';

alter table last_prices_2025_12_05
    owner to postgres;

 

 create table last_prices_2025_12_06
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-06 00:00:00') TO ('2025-12-07 00:00:00');

comment on table last_prices_2025_12_06 is 'Партиция сделок за 06.12.2025';

alter table last_prices_2025_12_06
    owner to postgres;

 

 create table last_prices_2025_12_07
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-07 00:00:00') TO ('2025-12-08 00:00:00');

comment on table last_prices_2025_12_07 is 'Партиция сделок за 07.12.2025';

alter table last_prices_2025_12_07
    owner to postgres;

 

 create table last_prices_2025_12_08
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-08 00:00:00') TO ('2025-12-09 00:00:00');

comment on table last_prices_2025_12_08 is 'Партиция сделок за 08.12.2025';

alter table last_prices_2025_12_08
    owner to postgres;

 

 create table last_prices_2025_12_09
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-09 00:00:00') TO ('2025-12-10 00:00:00');

comment on table last_prices_2025_12_09 is 'Партиция сделок за 09.12.2025';

alter table last_prices_2025_12_09
    owner to postgres;

 

 create table last_prices_2025_12_10
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-10 00:00:00') TO ('2025-12-11 00:00:00');

comment on table last_prices_2025_12_10 is 'Партиция сделок за 10.12.2025';

alter table last_prices_2025_12_10
    owner to postgres;

 

 create table last_prices_2025_12_11
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-11 00:00:00') TO ('2025-12-12 00:00:00');

comment on table last_prices_2025_12_11 is 'Партиция сделок за 11.12.2025';

alter table last_prices_2025_12_11
    owner to postgres;

 

 create table last_prices_2025_12_12
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-12 00:00:00') TO ('2025-12-13 00:00:00');

comment on table last_prices_2025_12_12 is 'Партиция сделок за 12.12.2025';

alter table last_prices_2025_12_12
    owner to postgres;

 

 create table last_prices_2025_12_13
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-13 00:00:00') TO ('2025-12-14 00:00:00');

comment on table last_prices_2025_12_13 is 'Партиция сделок за 13.12.2025';

alter table last_prices_2025_12_13
    owner to postgres;

 

 create table last_prices_2025_12_14
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-14 00:00:00') TO ('2025-12-15 00:00:00');

comment on table last_prices_2025_12_14 is 'Партиция сделок за 14.12.2025';

alter table last_prices_2025_12_14
    owner to postgres;

 

 create table last_prices_2025_12_15
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-15 00:00:00') TO ('2025-12-16 00:00:00');

comment on table last_prices_2025_12_15 is 'Партиция сделок за 15.12.2025';

alter table last_prices_2025_12_15
    owner to postgres;

 

 create table last_prices_2025_12_16
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-16 00:00:00') TO ('2025-12-17 00:00:00');

comment on table last_prices_2025_12_16 is 'Партиция сделок за 16.12.2025';

alter table last_prices_2025_12_16
    owner to postgres;

 

 create table last_prices_2025_12_17
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-17 00:00:00') TO ('2025-12-18 00:00:00');

comment on table last_prices_2025_12_17 is 'Партиция сделок за 17.12.2025';

alter table last_prices_2025_12_17
    owner to postgres;

 

 create table last_prices_2025_12_18
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-18 00:00:00') TO ('2025-12-19 00:00:00');

comment on table last_prices_2025_12_18 is 'Партиция сделок за 18.12.2025';

alter table last_prices_2025_12_18
    owner to postgres;

 

 create table last_prices_2025_12_19
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-19 00:00:00') TO ('2025-12-20 00:00:00');

comment on table last_prices_2025_12_19 is 'Партиция сделок за 19.12.2025';

alter table last_prices_2025_12_19
    owner to postgres;

 

 create table last_prices_2025_12_20
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-20 00:00:00') TO ('2025-12-21 00:00:00');

comment on table last_prices_2025_12_20 is 'Партиция сделок за 20.12.2025';

alter table last_prices_2025_12_20
    owner to postgres;

 

 create table last_prices_2025_12_21
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-21 00:00:00') TO ('2025-12-22 00:00:00');

comment on table last_prices_2025_12_21 is 'Партиция сделок за 21.12.2025';

alter table last_prices_2025_12_21
    owner to postgres;

 

 create table last_prices_2025_12_22
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-22 00:00:00') TO ('2025-12-23 00:00:00');

comment on table last_prices_2025_12_22 is 'Партиция сделок за 22.12.2025';

alter table last_prices_2025_12_22
    owner to postgres;

 

 create table last_prices_2025_12_23
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-23 00:00:00') TO ('2025-12-24 00:00:00');

comment on table last_prices_2025_12_23 is 'Партиция сделок за 23.12.2025';

alter table last_prices_2025_12_23
    owner to postgres;

 

 create table last_prices_2025_12_24
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-24 00:00:00') TO ('2025-12-25 00:00:00');

comment on table last_prices_2025_12_24 is 'Партиция сделок за 24.12.2025';

alter table last_prices_2025_12_24
    owner to postgres;

 

 create table last_prices_2025_12_25
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-25 00:00:00') TO ('2025-12-26 00:00:00');

comment on table last_prices_2025_12_25 is 'Партиция сделок за 25.12.2025';

alter table last_prices_2025_12_25
    owner to postgres;

 

 create table last_prices_2025_12_26
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-26 00:00:00') TO ('2025-12-27 00:00:00');

comment on table last_prices_2025_12_26 is 'Партиция сделок за 26.12.2025';

alter table last_prices_2025_12_26
    owner to postgres;

 

 create table last_prices_2025_12_27
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-27 00:00:00') TO ('2025-12-28 00:00:00');

comment on table last_prices_2025_12_27 is 'Партиция сделок за 27.12.2025';

alter table last_prices_2025_12_27
    owner to postgres;

 

 create table last_prices_2025_12_28
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-28 00:00:00') TO ('2025-12-29 00:00:00');

comment on table last_prices_2025_12_28 is 'Партиция сделок за 28.12.2025';

alter table last_prices_2025_12_28
    owner to postgres;

 

 create table last_prices_2025_12_29
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-29 00:00:00') TO ('2025-12-30 00:00:00');

comment on table last_prices_2025_12_29 is 'Партиция сделок за 29.12.2025';

alter table last_prices_2025_12_29
    owner to postgres;

 create table last_prices_2025_12_30
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-30 00:00:00') TO ('2025-12-31 00:00:00');

comment on table last_prices_2025_12_30 is 'Партиция сделок за 30.12.2025';

alter table last_prices_2025_12_30
    owner to postgres;

 create table last_prices_2025_12_31
    partition of invest_prices.last_prices
        FOR VALUES FROM ('2025-12-31 00:00:00') TO ('2026-01-01 00:00:00');

comment on table last_prices_2025_12_31 is 'Партиция сделок за 31.12.2025';

alter table last_prices_2025_12_31
    owner to postgres;

-- Обезличенные сделки
create table invest_prices.trades
(
    direction      varchar(10)   not null,
    figi           varchar(50)   not null,
    time           timestamp(6)  not null,
    currency       varchar(10)   not null,
    exchange       varchar(50)   not null,
    price          numeric(18, 9) not null,
    quantity       bigint        not null,
    trade_direction varchar(20),
    trade_source   varchar(20),
    primary key (figi, time, direction)
)
    partition by RANGE ("time");

comment on table invest_prices.trades is 'Таблица обезличенных сделок с дневным партиционированием для оптимизации производительности';

comment on column invest_prices.trades.figi is 'Уникальный идентификатор финансового инструмента (FIGI)';

comment on column invest_prices.trades.time is 'Время совершения сделки (timestamp без timezone)';

comment on column invest_prices.trades.direction is 'Направление сделки (BUY/SELL/LAST_PRICE)';

comment on column invest_prices.trades.price is 'Цена сделки с точностью до 9 знаков после запятой';

comment on column invest_prices.trades.quantity is 'Количество в сделке';

comment on column invest_prices.trades.currency is 'Валюта инструмента (RUB, USD, EUR и т.д.)';

comment on column invest_prices.trades.exchange is 'Биржа, на которой совершена сделка (MOEX, FORTS и т.д.)';

comment on column invest_prices.trades.trade_direction is 'Направление сделки (дублирует direction)';

comment on column invest_prices.trades.trade_source is 'Источник сделки (EXCHANGE/LAST_PRICE и т.д.)';

alter table invest_prices.trades
    owner to postgres;

-- Создание синонима в схеме invest для удобства использования
create or replace view invest.trades as
select 
    direction,
    figi,
    time,
    currency,
    exchange,
    price,
    quantity,
    trade_direction,
    trade_source
from invest_prices.trades;

comment on view invest.trades is 'Синоним для таблицы trades из схемы invest_prices';

-- Права доступа на представление
alter view invest.trades owner to postgres;

-- ============================================================================
-- ПАРТИЦИИ ДЛЯ invest_prices.trades
-- ============================================================================
-- 
-- Для создания партиций используйте функцию:
-- SELECT invest_utils.create_trades_partition('YYYY-MM-DD'::date);
--
-- Или массовое создание для всего периода (2024-01-01 до 2026-12-31):
-- DO $$
-- DECLARE
--     v_date date;
--     v_start_date date := '2024-01-01'::date;
--     v_end_date date := '2026-12-31'::date;
-- BEGIN
--     FOR v_date IN 
--         SELECT generate_series(v_start_date, v_end_date, INTERVAL '1 day')::date
--     LOOP
--         PERFORM invest_utils.create_trades_partition(v_date);
--     END LOOP;
-- END $$;
--
-- Партиции создаются по дням в формате: trades_YYYY_MM_DD
-- ============================================================================







