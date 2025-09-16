# Статистика сервиса потоковых данных

## Обзор

Сервис `InvestmentDataStreamService` предоставляет детальную статистику работы через REST API endpoint `/api/streaming-service/stats`. Статистика включает метрики по обработке торговых данных (trades) и свечей (candles) в реальном времени.

## Структура ответа

```json
{
  "running": true,
  "connected": true,
  "totalTradeProcessed": 331,
  "totalTradeErrors": 0,
  "totalReceived": 35,
  "totalTradeReceived": 136,
  "totalCandleReceived": 160,
  "totalCandleInserted": 331,
  "totalTradeInserted": 0,
  "totalCandleReceivedShares": 122,
  "totalCandleReceivedFutures": 38,
  "totalCandleReceivedIndicatives": 0,
  "totalErrorsAll": 0,
  "totalProcessedAll": 331,
  "totalReceivedAll": 171,
  "tradeQueueSize": 0,
  "tradeBufferCapacity": 200,
  "availableTradeInserts": 200,
  "tradeInsertUtilization": 0.0,
  "overallErrorRate": 0.0,
  "overallProcessingRate": 1.935672514619883,
  "tradeProcessingRate": 2.4338235294117645,
  "tradeErrorRate": 0.0,
  "maxConcurrentTradeInserts": 200
}
```

## Описание метрик

### Основные статусы

| Поле        | Тип     | Описание                                                   |
| ----------- | ------- | ---------------------------------------------------------- |
| `running`   | boolean | Статус работы сервиса (true = активен)                     |
| `connected` | boolean | Статус подключения к Tinkoff Invest API (true = подключен) |

### Общие счетчики

| Поле                | Тип  | Описание                                        |
| ------------------- | ---- | ----------------------------------------------- |
| `totalReceived`     | long | Общее количество полученных сообщений от API    |
| `totalReceivedAll`  | long | Сумма всех полученных данных (trades + candles) |
| `totalProcessedAll` | long | Общее количество обработанных записей           |
| `totalErrorsAll`    | long | Общее количество ошибок                         |

### Статистика по сделкам (Trades)

| Поле                  | Тип    | Описание                                      |
| --------------------- | ------ | --------------------------------------------- |
| `totalTradeReceived`  | long   | Количество полученных сделок от API           |
| `totalTradeProcessed` | long   | Количество обработанных сделок                |
| `totalTradeInserted`  | long   | Количество успешно вставленных сделок в БД    |
| `totalTradeErrors`    | long   | Количество ошибок при обработке сделок        |
| `tradeErrorRate`      | double | Процент ошибок при обработке сделок (0.0-1.0) |
| `tradeProcessingRate` | double | Скорость обработки сделок (записей/сек)       |

### Статистика по свечам (Candles)

| Поле                             | Тип  | Описание                                       |
| -------------------------------- | ---- | ---------------------------------------------- |
| `totalCandleReceived`            | long | Общее количество полученных свечей от API      |
| `totalCandleInserted`            | long | Количество успешно вставленных свечей в БД     |
| `totalCandleReceivedShares`      | long | Количество свечей по акциям                    |
| `totalCandleReceivedFutures`     | long | Количество свечей по фьючерсам                 |
| `totalCandleReceivedIndicatives` | long | Количество свечей по индикативным инструментам |

### Управление ресурсами

| Поле                        | Тип    | Описание                                      |
| --------------------------- | ------ | --------------------------------------------- |
| `tradeQueueSize`            | int    | Текущий размер очереди обработки сделок       |
| `tradeBufferCapacity`       | int    | Максимальная емкость буфера очереди           |
| `availableTradeInserts`     | int    | Доступные слоты для вставки в БД              |
| `maxConcurrentTradeInserts` | int    | Максимальное количество одновременных вставок |
| `tradeInsertUtilization`    | double | Утилизация слотов вставки (0.0-1.0)           |

### Производительность

| Поле                    | Тип    | Описание                               |
| ----------------------- | ------ | -------------------------------------- |
| `overallProcessingRate` | double | Общая скорость обработки (записей/сек) |
| `overallErrorRate`      | double | Общий процент ошибок (0.0-1.0)         |

## Интерпретация данных

### Нормальная работа

- `running: true` и `connected: true` - сервис работает корректно
- `totalTradeInserted` ≈ `totalTradeProcessed` - сделки успешно сохраняются
- `totalCandleInserted` ≈ `totalCandleReceived` - свечи успешно сохраняются
- `overallErrorRate` близок к 0 - минимум ошибок
- `tradeInsertUtilization` < 0.8 - буфер не переполнен

### Проблемные ситуации

#### Высокий процент ошибок

```json
{
  "overallErrorRate": 0.15,
  "tradeErrorRate": 0.12
}
```

**Действие**: Проверить логи, состояние БД, сетевое подключение

#### Переполнение буфера

```json
{
  "tradeInsertUtilization": 0.95,
  "availableTradeInserts": 10
}
```

**Действие**: Увеличить `maxConcurrentTradeInserts` или оптимизировать БД

#### Отсутствие данных

```json
{
  "totalReceived": 0,
  "connected": false
}
```

**Действие**: Проверить подключение к Tinkoff API, токен авторизации

#### Несоответствие счетчиков

```json
{
  "totalCandleReceived": 100,
  "totalCandleInserted": 50
}
```

**Действие**: Проверить логи ошибок вставки, состояние БД

## Мониторинг

### Ключевые метрики для алертов

1. **Доступность сервиса**

   - `running: false` → Критический алерт
   - `connected: false` → Предупреждение

2. **Производительность**

   - `overallProcessingRate < 1.0` → Предупреждение
   - `tradeInsertUtilization > 0.9` → Предупреждение

3. **Качество данных**

   - `overallErrorRate > 0.05` → Предупреждение
   - `overallErrorRate > 0.1` → Критический алерт

4. **Потеря данных**
   - `totalCandleInserted < totalCandleReceived * 0.95` → Критический алерт
   - `totalTradeInserted < totalTradeProcessed * 0.95` → Критический алерт

### Рекомендуемые дашборды

1. **Общий статус**: running, connected, error rates
2. **Поток данных**: received/processed/inserted по типам
3. **Производительность**: processing rates, utilization
4. **Распределение по инструментам**: shares/futures/indicatives

## Технические детали

### Обновление статистики

- Счетчики обновляются в реальном времени
- Статистика доступна через REST API без кэширования
- Метрики сбрасываются при перезапуске сервиса

### Производительность

- Счетчики используют `AtomicLong` для thread-safety
- Минимальное влияние на производительность основного потока
- Логирование агрегированных данных каждые 1000 событий

### Масштабирование

При росте нагрузки рекомендуется:

- Увеличить `maxConcurrentTradeInserts`
- Настроить пул соединений БД
- Рассмотреть горизонтальное масштабирование
