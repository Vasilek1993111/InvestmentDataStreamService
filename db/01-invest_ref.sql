--Схема invest_ref - схема для хранения справочников (акции, фьючерсы, дивиденты и другие)
--Все таблицы дублируются через view в схеме invest
CREATE SCHEMA IF NOT EXISTS invest_ref;

--Справочник акций
create table shares
(
    figi           varchar(255) not null primary key,
    ticker         varchar(255),
    name           varchar(255),
    currency       varchar(255),
    exchange       varchar(255),
    sector         varchar(255),
    trading_status varchar(255),
    short_enabled  boolean,
    asset_uid      varchar(255),
    created_at     timestamp with time zone default (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Moscow'::text),
    updated_at     timestamp with time zone default (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Moscow'::text),
    short_enabled boolean,
    asset_uid character varying(255),
    min_price_increment numeric,
    lot integer,
    CONSTRAINT shares_pkey PRIMARY KEY (figi)
);

comment on table shares is 'Справочник акций';

comment on column invest_ref.   shares.figi is 'Уникальный идентификатор инструмента (Financial Instrument Global Identifier)';

comment on column invest_ref.shares.ticker is 'Тикер акции';

comment on column invest_ref.shares.name is 'Название компании';

comment on column invest_ref.shares.currency is 'Валюта торговли';

comment on column invest_ref.shares.exchange is 'Биржа, на которой торгуется акция';

comment on column invest_ref.shares.sector is 'Сектор экономики';

comment on column invest_ref.shares.trading_status is 'Статус торговли';

comment on column invest_ref.shares.short_enabled is 'Флаг возможности коротких продаж';

comment on column invest_ref.shares.asset_uid is 'Уникальный идентификатор актива';

comment on column invest_ref.shares.created_at is 'Дата и время создания записи (московское время)';

comment on column invest_ref.shares.updated_at is 'Дата и время последнего обновления записи (московское время)';

-- Добавляем комментарии для новых колонок
comment on column shares.short_enabled is 'Флаг доступности для коротких продаж (short)';

comment on column shares.asset_uid is 'Уникальный идентификатор актива';

comment on column shares.min_price_increment is 'Минимальный шаг цены инструмента';

comment on column shares.lot is 'Лотность инструмента';

alter table shares
    owner to postgres;


--Справочник фьючерсов
create table futures
(
    figi        varchar(255) not null primary key,
    asset_type  varchar(255),
    basic_asset varchar(255),
    currency    varchar(255),
    exchange    varchar(255),
    ticker      varchar(255),
    created_at  timestamp(6) not null,
    updated_at  timestamp(6) not null,
    short_enabled boolean,
    expiration_date timestamp without time zone,
    min_price_increment numeric,
    lot integer,
    basic_asset_size numeric(18,9)
);

comment on table invest_ref.futures is 'Справочник фьючерсов';

comment on column invest_ref.futures.figi is 'Уникальный идентификатор инструмента';

comment on column invest_ref.futures.asset_type is 'Тип базового актива (TYPE_SECURITY, TYPE_COMMODITY, TYPE_CURRENCY, TYPE_INDEX)';

comment on column invest_ref.futures.basic_asset is 'Базовый актив фьючерса';

comment on column invest_ref.futures.currency is 'Валюта инструмента';

comment on column invest_ref.futures.exchange is 'Биржа, на которой торгуется инструмент';

comment on column invest_ref.futures.ticker is 'Тикер инструмента';

comment on column invest_ref.futures.created_at is 'Дата и время создания записи';

comment on column invest_ref.futures.updated_at is 'Дата и время последнего обновления записи';
-- Добавляем комментарии для новых колонок
comment on column invest_ref.futures.short_enabled is 'Флаг доступности для коротких продаж (short)';

comment on column invest_ref.futures.expiration_date is 'Дата экспирации фьючерса';

comment on column invest_ref.futures.min_price_increment is 'Минимальный шаг цены инструмента';

comment on column invest_ref.futures.lot is 'Лотность инструмента';

comment on column invest_ref.futures.basic_asset_size is 'Размер базового актива фьючерса (basicAssetSize из T-Invest API)';



alter table futures
    owner to postgres;


--Справочник индикативов
create table indicatives
(
    figi                varchar(255) not null
        primary key,
    ticker              varchar(255) not null,
    name                varchar(255) not null,
    currency            varchar(255) not null,
    exchange            varchar(255) not null,
    class_code          varchar(255),
    uid                 varchar(255),
    sell_available_flag boolean                  default false,
    buy_available_flag  boolean                  default false,
    created_at          timestamp with time zone default (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Moscow'::text),
    updated_at          timestamp with time zone default (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Moscow'::text)
);

comment on table invest_ref.indicatives is 'Справочник индикативов';

comment on column invest_ref.indicatives.figi is 'FIGI инструмента (уникальный идентификатор)';

comment on column invest_ref.indicatives.ticker is 'Тикер инструмента';

comment on column invest_ref.indicatives.name is 'Название инструмента';

comment on column invest_ref.indicatives.currency is 'Валюта инструмента';

comment on column invest_ref.indicatives.exchange is 'Биржа/площадка';

comment on column invest_ref.indicatives.class_code is 'Код класса инструмента';

comment on column invest_ref.indicatives.uid is 'Уникальный идентификатор';

comment on column invest_ref.indicatives.sell_available_flag is 'Флаг доступности для продажи';

comment on column invest_ref.indicatives.buy_available_flag is 'Флаг доступности для покупки';

comment on column invest_ref.indicatives.created_at is 'Дата создания записи (UTC+3)';

comment on column invest_ref.indicatives.updated_at is 'Дата последнего обновления записи (UTC+3)';

alter table indicatives
    owner to postgres;


--Справочник дивидендных событий
create table invest_ref.dividends
(
    id              bigserial primary key,
    figi            varchar(255) not null,
    declared_date   date,
    record_date     date not null,
    payment_date    date,
    dividend_value  numeric(18, 9),
    currency        varchar(10) not null,
    dividend_type   varchar(50),
    created_at      timestamp with time zone default (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Moscow'::text),
    updated_at      timestamp with time zone default (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Moscow'::text)
);

comment on table invest_ref.dividends is 'Справочник дивидендных событий';

comment on column invest_ref.dividends.id is 'Уникальный идентификатор записи';
comment on column invest_ref.dividends.figi is 'Уникальный идентификатор инструмента (FIGI)';
comment on column invest_ref.dividends.declared_date is 'Дата объявления дивидендов';
comment on column invest_ref.dividends.record_date is 'Дата фиксации реестра';
comment on column invest_ref.dividends.payment_date is 'Дата выплаты дивидендов';
comment on column invest_ref.dividends.dividend_value is 'Размер дивиденда на одну акцию';
comment on column invest_ref.dividends.currency is 'Валюта дивиденда';
comment on column invest_ref.dividends.dividend_type is 'Тип дивиденда (обычный, специальный и т.д.)';
comment on column invest_ref.dividends.created_at is 'Дата и время создания записи (московское время)';
comment on column invest_ref.dividends.updated_at is 'Дата и время последнего обновления записи (московское время)';

alter table invest_ref.dividends
    owner to postgres;


--Справочник фундаментальных показателей

create table invest_ref.fundamentals
(
    id                              bigserial primary key,
    figi                            varchar(255) not null,
    asset_uid                       varchar(255),
    domicile_indicator_code         varchar(10),
    currency                        varchar(10),
    
    -- Финансовые показатели
    dividend_yield_daily_ttm        decimal(18, 9),
    dividend_rate_ttm               decimal(18, 9),
    dividend_payout_ratio_fy        decimal(18, 9),
    forward_annual_dividend_yield   decimal(18, 9),
    five_years_average_dividend_yield decimal(18, 9),
    dividends_per_share             decimal(18, 9),
    five_year_annual_dividend_growth_rate decimal(18, 9),
    
    -- Показатели оценки
    price_to_sales_ttm              decimal(18, 9),
    price_to_book_ttm               decimal(18, 9),
    price_to_free_cash_flow_ttm     decimal(18, 9),
    pe_ratio_ttm                    decimal(18, 9),
    ev_to_sales                     decimal(18, 9),
    ev_to_ebitda_mrq                decimal(18, 9),
    
    -- Показатели прибыльности
    eps_ttm                         decimal(18, 9),
    diluted_eps_ttm                 decimal(18, 9),
    net_income_ttm                  decimal(18, 9),
    ebitda_ttm                      decimal(18, 9),
    free_cash_flow_ttm              decimal(18, 9),
    revenue_ttm                     decimal(18, 9),
    net_margin_mrq                  decimal(18, 9),
    
    -- Показатели рентабельности
    roe                             decimal(18, 9),
    roa                             decimal(18, 9),
    roic                            decimal(18, 9),
    
    -- Показатели роста
    revenue_change_five_years       decimal(18, 9),
    five_year_annual_revenue_growth_rate decimal(18, 9),
    one_year_annual_revenue_growth_rate decimal(18, 9),
    three_year_annual_revenue_growth_rate decimal(18, 9),
    eps_change_five_years           decimal(18, 9),
    ebitda_change_five_years        decimal(18, 9),
    
    -- Показатели долга
    total_debt_mrq                  decimal(18, 9),
    total_debt_to_equity_mrq        decimal(18, 9),
    total_debt_to_ebitda_mrq        decimal(18, 9),
    net_debt_to_ebitda              decimal(18, 9),
    total_debt_change_five_years    decimal(18, 9),
    
    -- Показатели ликвидности
    current_ratio_mrq               decimal(18, 9),
    fixed_charge_coverage_ratio_fy  decimal(18, 9),
    net_interest_margin_mrq         decimal(18, 9),
    
    -- Рыночные показатели
    market_capitalization           decimal(18, 9),
    total_enterprise_value_mrq      decimal(18, 9),
    shares_outstanding              decimal(18, 9),
    free_float                      decimal(18, 9),
    beta                            decimal(18, 9),
    
    -- Ценовые показатели
    high_price_last_52_weeks        decimal(18, 9),
    low_price_last_52_weeks         decimal(18, 9),
    
    -- Объемы торгов
    average_daily_volume_last_4_weeks decimal(18, 9),
    average_daily_volume_last_10_days decimal(18, 9),
    
    -- Показатели компании
    number_of_employees             decimal(18, 9),
    adr_to_common_share_ratio       decimal(18, 9),
    buy_back_ttm                    decimal(18, 9),
    free_cash_flow_to_price         decimal(18, 9),
    
    -- Даты
    fiscal_period_start_date        timestamp with time zone,
    fiscal_period_end_date          timestamp with time zone,
    ex_dividend_date                timestamp with time zone,
    
    -- Служебные поля
    created_at                      timestamp with time zone default (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Moscow'::text),
    updated_at                      timestamp with time zone default (CURRENT_TIMESTAMP AT TIME ZONE 'Europe/Moscow'::text)
);



comment on table invest_ref.fundamentals is 'Таблица для хранения фундаментальных показателей инструментов';

comment on column invest_ref.fundamentals.id is 'Уникальный идентификатор записи';
comment on column invest_ref.fundamentals.figi is 'Уникальный идентификатор инструмента (FIGI)';
comment on column invest_ref.fundamentals.asset_uid is 'Уникальный идентификатор актива';
comment on column invest_ref.fundamentals.domicile_indicator_code is 'Код страны регистрации';
comment on column invest_ref.fundamentals.currency is 'Валюта показателей';

-- Комментарии для дивидендных показателей
comment on column invest_ref.fundamentals.dividend_yield_daily_ttm is 'Дневная дивидендная доходность за последние 12 месяцев';
comment on column invest_ref.fundamentals.dividend_rate_ttm is 'Ставка дивиденда за последние 12 месяцев';
comment on column invest_ref.fundamentals.dividend_payout_ratio_fy is 'Коэффициент выплаты дивидендов за финансовый год';
comment on column invest_ref.fundamentals.forward_annual_dividend_yield is 'Прогнозируемая годовая дивидендная доходность';
comment on column invest_ref.fundamentals.five_years_average_dividend_yield is 'Средняя дивидендная доходность за 5 лет';
comment on column invest_ref.fundamentals.dividends_per_share is 'Дивиденды на акцию';
comment on column invest_ref.fundamentals.five_year_annual_dividend_growth_rate is 'Годовой темп роста дивидендов за 5 лет';

-- Комментарии для показателей оценки
comment on column invest_ref.fundamentals.price_to_sales_ttm is 'Отношение цены к выручке за последние 12 месяцев';
comment on column invest_ref.fundamentals.price_to_book_ttm is 'Отношение цены к балансовой стоимости за последние 12 месяцев';
comment on column invest_ref.fundamentals.price_to_free_cash_flow_ttm is 'Отношение цены к свободному денежному потоку за последние 12 месяцев';
comment on column invest_ref.fundamentals.pe_ratio_ttm is 'Отношение цены к прибыли на акцию за последние 12 месяцев';
comment on column invest_ref.fundamentals.ev_to_sales is 'Отношение стоимости предприятия к выручке';
comment on column invest_ref.fundamentals.ev_to_ebitda_mrq is 'Отношение стоимости предприятия к EBITDA на последнюю отчетную дату';

-- Комментарии для показателей прибыльности
comment on column invest_ref.fundamentals.eps_ttm is 'Прибыль на акцию за последние 12 месяцев';
comment on column invest_ref.fundamentals.diluted_eps_ttm is 'Разводненная прибыль на акцию за последние 12 месяцев';
comment on column invest_ref.fundamentals.net_income_ttm is 'Чистая прибыль за последние 12 месяцев';
comment on column invest_ref.fundamentals.ebitda_ttm is 'EBITDA за последние 12 месяцев';
comment on column invest_ref.fundamentals.free_cash_flow_ttm is 'Свободный денежный поток за последние 12 месяцев';
comment on column invest_ref.fundamentals.revenue_ttm is 'Выручка за последние 12 месяцев';
comment on column invest_ref.fundamentals.net_margin_mrq is 'Чистая маржа на последнюю отчетную дату';

-- Комментарии для показателей рентабельности
comment on column invest_ref.fundamentals.roe is 'Рентабельность собственного капитала';
comment on column invest_ref.fundamentals.roa is 'Рентабельность активов';
comment on column invest_ref.fundamentals.roic is 'Рентабельность инвестированного капитала';

-- Комментарии для показателей роста
comment on column invest_ref.fundamentals.revenue_change_five_years is 'Изменение выручки за 5 лет';
comment on column invest_ref.fundamentals.five_year_annual_revenue_growth_rate is 'Годовой темп роста выручки за 5 лет';
comment on column invest_ref.fundamentals.one_year_annual_revenue_growth_rate is 'Годовой темп роста выручки за 1 год';
comment on column invest_ref.fundamentals.three_year_annual_revenue_growth_rate is 'Годовой темп роста выручки за 3 года';
comment on column invest_ref.fundamentals.eps_change_five_years is 'Изменение прибыли на акцию за 5 лет';
comment on column invest_ref.fundamentals.ebitda_change_five_years is 'Изменение EBITDA за 5 лет';

-- Комментарии для показателей долга
comment on column invest_ref.fundamentals.total_debt_mrq is 'Общий долг на последнюю отчетную дату';
comment on column invest_ref.fundamentals.total_debt_to_equity_mrq is 'Отношение общего долга к собственному капиталу на последнюю отчетную дату';
comment on column invest_ref.fundamentals.total_debt_to_ebitda_mrq is 'Отношение общего долга к EBITDA на последнюю отчетную дату';
comment on column invest_ref.fundamentals.net_debt_to_ebitda is 'Отношение чистого долга к EBITDA';
comment on column invest_ref.fundamentals.total_debt_change_five_years is 'Изменение общего долга за 5 лет';

-- Комментарии для показателей ликвидности
comment on column invest_ref.fundamentals.current_ratio_mrq is 'Коэффициент текущей ликвидности на последнюю отчетную дату';
comment on column invest_ref.fundamentals.fixed_charge_coverage_ratio_fy is 'Коэффициент покрытия фиксированных платежей за финансовый год';
comment on column invest_ref.fundamentals.net_interest_margin_mrq is 'Чистая процентная маржа на последнюю отчетную дату';

-- Комментарии для рыночных показателей
comment on column invest_ref.fundamentals.market_capitalization is 'Рыночная капитализация';
comment on column invest_ref.fundamentals.total_enterprise_value_mrq is 'Общая стоимость предприятия на последнюю отчетную дату';
comment on column invest_ref.fundamentals.shares_outstanding is 'Количество акций в обращении';
comment on column invest_ref.fundamentals.free_float is 'Свободно обращающиеся акции';
comment on column invest_ref.fundamentals.beta is 'Бета-коэффициент';

-- Комментарии для ценовых показателей
comment on column invest_ref.fundamentals.high_price_last_52_weeks is 'Максимальная цена за последние 52 недели';
comment on column invest_ref.fundamentals.low_price_last_52_weeks is 'Минимальная цена за последние 52 недели';

-- Комментарии для объемов торгов
comment on column invest_ref.fundamentals.average_daily_volume_last_4_weeks is 'Средний дневной объем торгов за последние 4 недели';
comment on column invest_ref.fundamentals.average_daily_volume_last_10_days is 'Средний дневной объем торгов за последние 10 дней';

-- Комментарии для показателей компании
comment on column invest_ref.fundamentals.number_of_employees is 'Количество сотрудников';
comment on column invest_ref.fundamentals.adr_to_common_share_ratio is 'Соотношение ADR к обыкновенным акциям';
comment on column invest_ref.fundamentals.buy_back_ttm is 'Выкуп акций за последние 12 месяцев';
comment on column invest_ref.fundamentals.free_cash_flow_to_price is 'Отношение свободного денежного потока к цене';

-- Комментарии для дат
comment on column invest_ref.fundamentals.fiscal_period_start_date is 'Дата начала финансового периода';
comment on column invest_ref.fundamentals.fiscal_period_end_date is 'Дата окончания финансового периода';
comment on column invest_ref.fundamentals.ex_dividend_date is 'Дата отсечки дивидендов';

-- Индексы для оптимизации запросов
create index idx_fundamentals_figi on invest_ref.fundamentals (figi);


-- ============================================================================
-- СИНОНИМЫ (VIEWS) В СХЕМЕ INVEST
-- ============================================================================

-- View для акций в схеме invest
create or replace view invest.shares as
select * from invest_ref.shares;

comment on view invest.shares is 'Синоним для таблицы shares из схемы invest_ref';

alter view invest.shares owner to postgres;

-- View для фьючерсов в схеме invest
create or replace view invest.futures as
select * from invest_ref.futures;

comment on view invest.futures is 'Синоним для таблицы futures из схемы invest_ref';

alter view invest.futures owner to postgres;

-- View для индикативов в схеме invest
create or replace view invest.indicatives as
select * from invest_ref.indicatives;

comment on view invest.indicatives is 'Синоним для таблицы indicatives из схемы invest_ref';

alter view invest.indicatives owner to postgres;

-- View для дивидендов в схеме invest
create or replace view invest.dividends as
select * from invest_ref.dividends;

comment on view invest.dividends is 'Синоним для таблицы dividends из схемы invest_ref';

alter view invest.dividends owner to postgres;

-- View для фундаментальных показателей в схеме invest
create or replace view invest.fundamentals as
select * from invest_ref.fundamentals;

comment on view invest.fundamentals is 'Синоним для таблицы fundamentals из схемы invest_ref';

alter view invest.fundamentals owner to postgres;

