--Материализованное представление daily_volume_aggregation
create materialized view daily_volume_aggregation as
SELECT minute_candles.figi,
       CASE
           WHEN s.figi IS NOT NULL THEN 'share'::text
           WHEN f.figi IS NOT NULL THEN 'future'::text
           ELSE 'unknown'::text
           END                                                         AS instrument_type,
       sum(minute_candles.volume)                                      AS total_volume,
       count(*)                                                        AS total_candles,
       round(avg(minute_candles.volume), 2)                            AS avg_volume_per_candle,
       sum(
               CASE
                   WHEN EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >= 1::numeric AND
                        EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 5::numeric AND
                        (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = 6::numeric AND
                         EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                         59::numeric AND
                         EXTRACT(second FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                         59::numeric OR
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >= 7::numeric AND
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 8::numeric OR
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = 9::numeric AND
                         EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 59::numeric)
                       THEN minute_candles.volume
                   ELSE 0::bigint
                   END)                                                AS morning_session_volume,
       count(
               CASE
                   WHEN EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >= 1::numeric AND
                        EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 5::numeric AND
                        (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = 6::numeric AND
                         EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                         59::numeric AND
                         EXTRACT(second FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                         59::numeric OR
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >= 7::numeric AND
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 8::numeric OR
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = 9::numeric AND
                         EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 59::numeric)
                       THEN 1
                   ELSE NULL::integer
                   END)                                                AS morning_session_candles,
       CASE
           WHEN count(
                        CASE
                            WHEN EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                 1::numeric AND
                                 EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                 5::numeric AND
                                 (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                  6::numeric AND
                                  EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                  59::numeric AND
                                  EXTRACT(second FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                  59::numeric OR
                                  EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                  7::numeric AND
                                  EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                  8::numeric OR
                                  EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                  9::numeric AND
                                  EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                  59::numeric) THEN 1
                            ELSE NULL::integer
                            END) > 0 THEN round(sum(
                                                        CASE
                                                            WHEN EXTRACT(dow FROM
                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                 1::numeric AND EXTRACT(dow FROM
                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                5::numeric AND (EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                                6::numeric AND
                                                                                                EXTRACT(minute FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                                59::numeric AND
                                                                                                EXTRACT(second FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                                                59::numeric OR
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                                                7::numeric AND
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                8::numeric OR
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                                9::numeric AND
                                                                                                EXTRACT(minute FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                59::numeric)
                                                                THEN minute_candles.volume
                                                            ELSE 0::bigint
                                                            END) / count(
                                                        CASE
                                                            WHEN EXTRACT(dow FROM
                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                 1::numeric AND EXTRACT(dow FROM
                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                5::numeric AND (EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                                6::numeric AND
                                                                                                EXTRACT(minute FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                                59::numeric AND
                                                                                                EXTRACT(second FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                                                59::numeric OR
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                                                7::numeric AND
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                8::numeric OR
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                                9::numeric AND
                                                                                                EXTRACT(minute FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                59::numeric) THEN 1
                                                            ELSE NULL::integer
                                                            END)::numeric, 2)
           ELSE 0::numeric
           END                                                         AS morning_avg_volume_per_candle,
       sum(
               CASE
                   WHEN EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >= 1::numeric AND
                        EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 5::numeric AND
                        (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                         10::numeric AND
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 17::numeric OR
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = 18::numeric AND
                         EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 59::numeric)
                       THEN minute_candles.volume
                   ELSE 0::bigint
                   END)                                                AS main_session_volume,
       count(
               CASE
                   WHEN EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >= 1::numeric AND
                        EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 5::numeric AND
                        (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                         10::numeric AND
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 17::numeric OR
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = 18::numeric AND
                         EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 59::numeric)
                       THEN 1
                   ELSE NULL::integer
                   END)                                                AS main_session_candles,
       CASE
           WHEN count(
                        CASE
                            WHEN EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                 1::numeric AND
                                 EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                 5::numeric AND
                                 (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                  10::numeric AND
                                  EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                  17::numeric OR
                                  EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                  18::numeric AND
                                  EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                  59::numeric) THEN 1
                            ELSE NULL::integer
                            END) > 0 THEN round(sum(
                                                        CASE
                                                            WHEN EXTRACT(dow FROM
                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                 1::numeric AND EXTRACT(dow FROM
                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                5::numeric AND (EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                                                10::numeric AND
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                17::numeric OR
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                                18::numeric AND
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                59::numeric)
                                                                THEN minute_candles.volume
                                                            ELSE 0::bigint
                                                            END) / count(
                                                        CASE
                                                            WHEN EXTRACT(dow FROM
                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                 1::numeric AND EXTRACT(dow FROM
                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                5::numeric AND (EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                                                10::numeric AND
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                17::numeric OR
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                                18::numeric AND
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                59::numeric) THEN 1
                                                            ELSE NULL::integer
                                                            END)::numeric, 2)
           ELSE 0::numeric
           END                                                         AS main_avg_volume_per_candle,
       sum(
               CASE
                   WHEN EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >= 1::numeric AND
                        EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 5::numeric AND
                        (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                         19::numeric AND
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 22::numeric OR
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = 23::numeric AND
                         EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 50::numeric)
                       THEN minute_candles.volume
                   ELSE 0::bigint
                   END)                                                AS evening_session_volume,
       count(
               CASE
                   WHEN EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >= 1::numeric AND
                        EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 5::numeric AND
                        (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                         19::numeric AND
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 22::numeric OR
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = 23::numeric AND
                         EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 50::numeric)
                       THEN 1
                   ELSE NULL::integer
                   END)                                                AS evening_session_candles,
       CASE
           WHEN count(
                        CASE
                            WHEN EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                 1::numeric AND
                                 EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                 5::numeric AND
                                 (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                  19::numeric AND
                                  EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                  22::numeric OR
                                  EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                  23::numeric AND
                                  EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                  50::numeric) THEN 1
                            ELSE NULL::integer
                            END) > 0 THEN round(sum(
                                                        CASE
                                                            WHEN EXTRACT(dow FROM
                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                 1::numeric AND EXTRACT(dow FROM
                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                5::numeric AND (EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                                                19::numeric AND
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                22::numeric OR
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                                23::numeric AND
                                                                                                EXTRACT(minute FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                50::numeric)
                                                                THEN minute_candles.volume
                                                            ELSE 0::bigint
                                                            END) / count(
                                                        CASE
                                                            WHEN EXTRACT(dow FROM
                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                 1::numeric AND EXTRACT(dow FROM
                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                5::numeric AND (EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                                                19::numeric AND
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                22::numeric OR
                                                                                                EXTRACT(hour FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                                23::numeric AND
                                                                                                EXTRACT(minute FROM
                                                                                                        (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                50::numeric) THEN 1
                                                            ELSE NULL::integer
                                                            END)::numeric, 2)
           ELSE 0::numeric
           END                                                         AS evening_avg_volume_per_candle,
       sum(
               CASE
                   WHEN (EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = ANY
                         (ARRAY [0::numeric, 6::numeric])) AND
                        (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                         10::numeric AND
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 17::numeric OR
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = 18::numeric AND
                         EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 59::numeric)
                       THEN minute_candles.volume
                   ELSE 0::bigint
                   END)                                                AS weekend_exchange_session_volume,
       count(
               CASE
                   WHEN (EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = ANY
                         (ARRAY [0::numeric, 6::numeric])) AND
                        (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                         10::numeric AND
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 17::numeric OR
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = 18::numeric AND
                         EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 59::numeric)
                       THEN 1
                   ELSE NULL::integer
                   END)                                                AS weekend_exchange_session_candles,
       CASE
           WHEN count(
                        CASE
                            WHEN (EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = ANY
                                  (ARRAY [0::numeric, 6::numeric])) AND
                                 (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                  10::numeric AND
                                  EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                  17::numeric OR
                                  EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                  18::numeric AND
                                  EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                  59::numeric) THEN 1
                            ELSE NULL::integer
                            END) > 0 THEN round(sum(
                                                        CASE
                                                            WHEN (EXTRACT(dow FROM
                                                                          (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = ANY
                                                                  (ARRAY [0::numeric, 6::numeric])) AND
                                                                 (EXTRACT(hour FROM
                                                                          (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                  10::numeric AND EXTRACT(hour FROM
                                                                                          (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                  17::numeric OR EXTRACT(hour FROM
                                                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                                 18::numeric AND
                                                                                                 EXTRACT(minute FROM
                                                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                 59::numeric)
                                                                THEN minute_candles.volume
                                                            ELSE 0::bigint
                                                            END) / count(
                                                        CASE
                                                            WHEN (EXTRACT(dow FROM
                                                                          (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = ANY
                                                                  (ARRAY [0::numeric, 6::numeric])) AND
                                                                 (EXTRACT(hour FROM
                                                                          (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                  10::numeric AND EXTRACT(hour FROM
                                                                                          (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                  17::numeric OR EXTRACT(hour FROM
                                                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                                 18::numeric AND
                                                                                                 EXTRACT(minute FROM
                                                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                 59::numeric) THEN 1
                                                            ELSE NULL::integer
                                                            END)::numeric, 2)
           ELSE 0::numeric
           END                                                         AS weekend_exchange_avg_volume_per_candle,
       sum(
               CASE
                   WHEN (EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = ANY
                         (ARRAY [0::numeric, 6::numeric])) AND
                        (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >= 2::numeric AND
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 8::numeric OR
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = 9::numeric AND
                         EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                         59::numeric OR EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                        19::numeric AND
                                        EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                        22::numeric OR
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = 23::numeric AND
                         EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 50::numeric)
                       THEN minute_candles.volume
                   ELSE 0::bigint
                   END)                                                AS weekend_otc_session_volume,
       count(
               CASE
                   WHEN (EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = ANY
                         (ARRAY [0::numeric, 6::numeric])) AND
                        (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >= 2::numeric AND
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 8::numeric OR
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = 9::numeric AND
                         EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                         59::numeric OR EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                        19::numeric AND
                                        EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                        22::numeric OR
                         EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = 23::numeric AND
                         EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <= 50::numeric)
                       THEN 1
                   ELSE NULL::integer
                   END)                                                AS weekend_otc_session_candles,
       CASE
           WHEN count(
                        CASE
                            WHEN (EXTRACT(dow FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = ANY
                                  (ARRAY [0::numeric, 6::numeric])) AND
                                 (EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                  2::numeric AND
                                  EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                  8::numeric OR
                                  EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                  9::numeric AND
                                  EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                  59::numeric OR
                                  EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                  19::numeric AND
                                  EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                  22::numeric OR
                                  EXTRACT(hour FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                  23::numeric AND
                                  EXTRACT(minute FROM (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                  50::numeric) THEN 1
                            ELSE NULL::integer
                            END) > 0 THEN round(sum(
                                                        CASE
                                                            WHEN (EXTRACT(dow FROM
                                                                          (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = ANY
                                                                  (ARRAY [0::numeric, 6::numeric])) AND
                                                                 (EXTRACT(hour FROM
                                                                          (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                  2::numeric AND EXTRACT(hour FROM
                                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                 8::numeric OR EXTRACT(hour FROM
                                                                                                       (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                               9::numeric AND
                                                                                               EXTRACT(minute FROM
                                                                                                       (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                               59::numeric OR
                                                                  EXTRACT(hour FROM
                                                                          (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                  19::numeric AND EXTRACT(hour FROM
                                                                                          (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                  22::numeric OR EXTRACT(hour FROM
                                                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                                 23::numeric AND
                                                                                                 EXTRACT(minute FROM
                                                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                 50::numeric)
                                                                THEN minute_candles.volume
                                                            ELSE 0::bigint
                                                            END) / count(
                                                        CASE
                                                            WHEN (EXTRACT(dow FROM
                                                                          (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) = ANY
                                                                  (ARRAY [0::numeric, 6::numeric])) AND
                                                                 (EXTRACT(hour FROM
                                                                          (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                  2::numeric AND EXTRACT(hour FROM
                                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                 8::numeric OR EXTRACT(hour FROM
                                                                                                       (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                               9::numeric AND
                                                                                               EXTRACT(minute FROM
                                                                                                       (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                               59::numeric OR
                                                                  EXTRACT(hour FROM
                                                                          (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) >=
                                                                  19::numeric AND EXTRACT(hour FROM
                                                                                          (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                  22::numeric OR EXTRACT(hour FROM
                                                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) =
                                                                                                 23::numeric AND
                                                                                                 EXTRACT(minute FROM
                                                                                                         (minute_candles."time" AT TIME ZONE 'Europe/Moscow'::text)) <=
                                                                                                 50::numeric) THEN 1
                                                            ELSE NULL::integer
                                                            END)::numeric, 2)
           ELSE 0::numeric
           END                                                         AS weekend_otc_avg_volume_per_candle,
       (min(minute_candles."time") AT TIME ZONE 'Europe/Moscow'::text) AS first_candle_time,
       (max(minute_candles."time") AT TIME ZONE 'Europe/Moscow'::text) AS last_candle_time,
       (now() AT TIME ZONE 'Europe/Moscow'::text)                      AS last_updated
FROM minute_candles
         LEFT JOIN shares s ON minute_candles.figi::text = s.figi::text
         LEFT JOIN futures f ON minute_candles.figi::text = f.figi::text
GROUP BY minute_candles.figi, s.figi, f.figi
ORDER BY minute_candles.figi;

--Создание схемы invest_views для материализованных представлений
CREATE SCHEMA IF NOT EXISTS invest_views;

--Материализованное представление для исторических максимумов и минимумов по дневным свечам
CREATE MATERIALIZED VIEW invest_views.historical_price_extremes AS
WITH candle_extremes AS (
    SELECT 
        dc.figi,
        dc.time,
        dc.high + COALESCE(dc.upper_shadow, 0) AS historical_high,
        dc.low - COALESCE(dc.lower_shadow, 0) AS historical_low
    FROM invest_candles.daily_candles dc
    WHERE dc.upper_shadow IS NOT NULL 
       OR dc.lower_shadow IS NOT NULL
),
instrument_type AS (
    SELECT 
        ce.figi,
        CASE
            WHEN s.figi IS NOT NULL THEN 'share'::text
            WHEN f.figi IS NOT NULL THEN 'future'::text
            WHEN ind.figi IS NOT NULL THEN 'indicative'::text
            ELSE 'unknown'::text
        END AS instrument_type,
        COALESCE(s.ticker, f.ticker, ind.ticker) AS ticker,
        MAX(ce.historical_high) AS max_historical_high,
        MIN(ce.historical_low) AS min_historical_low
    FROM candle_extremes ce
    LEFT JOIN invest_ref.shares s ON ce.figi::text = s.figi::text
    LEFT JOIN invest_ref.futures f ON ce.figi::text = f.figi::text
    LEFT JOIN invest_ref.indicatives ind ON ce.figi::text = ind.figi::text
    GROUP BY ce.figi, s.figi, f.figi, ind.figi, s.ticker, f.ticker, ind.ticker
),
high_dates AS (
    SELECT 
        ce.figi,
        ce.time AS high_date,
        ce.historical_high,
        ROW_NUMBER() OVER (PARTITION BY ce.figi ORDER BY ce.historical_high DESC, ce.time DESC) AS rn
    FROM candle_extremes ce
    INNER JOIN instrument_type it ON ce.figi = it.figi 
        AND ce.historical_high = it.max_historical_high
),
low_dates AS (
    SELECT 
        ce.figi,
        ce.time AS low_date,
        ce.historical_low,
        ROW_NUMBER() OVER (PARTITION BY ce.figi ORDER BY ce.historical_low ASC, ce.time ASC) AS rn
    FROM candle_extremes ce
    INNER JOIN instrument_type it ON ce.figi = it.figi 
        AND ce.historical_low = it.min_historical_low
)
SELECT 
    it.figi,
    it.ticker,
    it.instrument_type,
    it.max_historical_high AS historical_high,
    hd.high_date AS historical_high_date,
    it.min_historical_low AS historical_low,
    ld.low_date AS historical_low_date
FROM instrument_type it
LEFT JOIN high_dates hd ON it.figi = hd.figi AND hd.rn = 1
LEFT JOIN low_dates ld ON it.figi = ld.figi AND ld.rn = 1
ORDER BY it.figi;

COMMENT ON MATERIALIZED VIEW invest_views.historical_price_extremes IS 'Исторические максимумы и минимумы цен для каждого инструмента на основе дневных свечей. Исторический максимум = high + upper_shadow, исторический минимум = low - lower_shadow';

COMMENT ON COLUMN invest_views.historical_price_extremes.figi IS 'Уникальный идентификатор инструмента (Financial Instrument Global Identifier)';
COMMENT ON COLUMN invest_views.historical_price_extremes.ticker IS 'Тикер инструмента';
COMMENT ON COLUMN invest_views.historical_price_extremes.instrument_type IS 'Тип инструмента: share (акция), future (фьючерс), indicative (индикатив), unknown (неизвестный)';
COMMENT ON COLUMN invest_views.historical_price_extremes.historical_high IS 'Исторический максимум цены (high + upper_shadow)';
COMMENT ON COLUMN invest_views.historical_price_extremes.historical_high_date IS 'Дата исторического максимума';
COMMENT ON COLUMN invest_views.historical_price_extremes.historical_low IS 'Исторический минимум цены (low - lower_shadow)';
COMMENT ON COLUMN invest_views.historical_price_extremes.historical_low_date IS 'Дата исторического минимума';

-- Создание индекса для оптимизации запросов
CREATE INDEX idx_historical_price_extremes_figi ON invest_views.historical_price_extremes (figi);
CREATE INDEX idx_historical_price_extremes_type ON invest_views.historical_price_extremes (instrument_type);

-- ============================================================================
-- СИНОНИМ В СХЕМЕ INVEST
-- ============================================================================

-- View для historical_price_extremes в схеме invest
CREATE OR REPLACE VIEW invest.historical_price_extremes AS
SELECT 
    figi,
    ticker,
    instrument_type,
    historical_high,
    historical_high_date,
    historical_low,
    historical_low_date
FROM invest_views.historical_price_extremes;

COMMENT ON VIEW invest.historical_price_extremes IS 'Синоним для материализованного представления historical_price_extremes из схемы invest_views';

ALTER VIEW invest.historical_price_extremes OWNER TO postgres;

-- ============================================================================
-- АВТОМАТИЧЕСКОЕ ОБНОВЛЕНИЕ МАТЕРИАЛИЗОВАННОГО ПРЕДСТАВЛЕНИЯ
-- ============================================================================

-- Проверка и создание расширения pg_cron (если не установлено)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Настройка автоматического обновления материализованного представления
-- Каждый день в 01:50 по времени сервера PostgreSQL
SELECT cron.schedule(
    'refresh-historical-price-extremes',
    '50 1 * * *',  -- cron выражение: минута 50, час 1, каждый день
    'REFRESH MATERIALIZED VIEW invest_views.historical_price_extremes;'
);

COMMENT ON FUNCTION cron.schedule IS 'Настроено автоматическое обновление материализованного представления invest_views.historical_price_extremes каждый день в 01:50';

-- Проверка настроенных задач (для отладки)
-- SELECT * FROM cron.job WHERE jobname = 'refresh-historical-price-extremes';

-- Удаление задачи (если нужно):
-- SELECT cron.unschedule('refresh-historical-price-extremes');