# Investment Data Stream Service API v2 - Postman Collection

## 📦 Полная коллекция в одном файле

Вся коллекция API теперь объединена в один файл с переменными окружения:

**`Investment_Data_Stream_Service_Complete_API.postman_collection.json`**

## 🚀 Быстрый старт

### 1. Импорт коллекции в Postman

1. Откройте Postman
2. Нажмите **Import**
3. Выберите файл `Investment_Data_Stream_Service_Complete_API.postman_collection.json`
4. Коллекция готова к использованию!

### 2. Настройка переменных

Коллекция уже содержит базовые переменные:
- `base_url` = `http://localhost:8084`
- `share_figi` = `BBG004S68758` (SBER)
- `future_figi` = `FUTSBER03260`
- `indicative_figi` = `TCS00A0JR514`

Вы можете изменить их в настройках коллекции (Collection Variables).

## 📚 Структура коллекции

### 🏠 Health & Status
- **Application Health** - проверка состояния приложения
- **Application Info** - информация о приложении

### 🎯 Trade Stream
Управление потоком обезличенных сделок (→ `invest.trades`)
- **Start Trade Stream** - запустить стрим
- **Stop Trade Stream** - остановить стрим
- **Reconnect Trade Stream** - переподключить
- **Get Trade Stream Status** - статус стрима
- **Get Trade Stream Metrics** - метрики производительности

### 📈 Minute Candles Stream
Управление потоком минутных свечей (→ `invest.minute_candles`)
- **Start Candles Stream** - запустить стрим
- **Stop Candles Stream** - остановить стрим
- **Reconnect Candles Stream** - переподключить
- **Get Candles Stream Status** - статус стрима
- **Get Candles Stream Metrics** - метрики производительности

### 💰 Last Price Stream
Управление потоком цен последних сделок (→ `invest.last_prices`)
- **Start LastPrice Stream** - запустить стрим
- **Stop LastPrice Stream** - остановить стрим
- **Reconnect LastPrice Stream** - переподключить
- **Get LastPrice Stream Status** - статус стрима
- **Get LastPrice Stream Metrics** - метрики производительности

### 🚨 Limits Monitoring Stream
Управление потоком мониторинга лимитов (→ Telegram уведомления)
- **Start Limits Stream** - запустить стрим
- **Stop Limits Stream** - остановить стрим
- **Reconnect Limits Stream** - переподключить
- **Get Limits Stream Status** - статус стрима
- **Get Limits Stream Metrics** - метрики производительности

### 📊 Instruments API
- **Shares** - работа с акциями (получить все, по FIGI, поиск)
- **Futures** - работа с фьючерсами
- **Indicatives** - работа с индикативными инструментами

### 🔄 Cache Management
- **Warm Up All Caches** - прогреть все кэши
- **Get Cache Statistics** - статистика по кэшам
- **Clear All Caches** - очистить все кэши
- **Clear Shares Cache** - очистить кэш акций

### 📉 Candles API
- **Get Candles by FIGI** - получить свечи по инструменту
- **Get Candles by FIGI and Time Range** - свечи за период

### 📌 Limit Monitoring API
- **Get All Limits** - все лимиты
- **Get Limit by FIGI** - лимит по инструменту
- **Create or Update Limit** - создать/обновить лимит
- **Delete Limit** - удалить лимит

## 🎬 Готовые сценарии

### Сценарий 1: Полный запуск системы

Выполните запросы по порядку:

```
1.1 Health Check          - проверка приложения
1.2 Warm Up Caches        - загрузка инструментов
1.3 Start Trade Stream    - запуск стрима trades
1.4 Start Candles Stream  - запуск стрима candles
1.5 Start LastPrice Stream - запуск стрима last_price
1.6 Start Limits Stream   - запуск стрима limits
```

### Сценарий 2: Мониторинг всех стримов

```
2.1 Trade Stream Metrics
2.2 Candles Stream Metrics
2.3 LastPrice Stream Metrics
2.4 Limits Stream Metrics
```

### Сценарий 3: Остановка всех стримов

```
3.1 Stop Trade Stream
3.2 Stop Candles Stream
3.3 Stop LastPrice Stream
3.4 Stop Limits Stream
```

## 🔧 Примеры использования

### Запуск стрима trades

```bash
POST http://localhost:8084/api/stream/trades/start
```

**Ответ:**
```json
{
  "success": true,
  "message": "Trade streaming started successfully",
  "service": "TradeStreamingService",
  "timestamp": "2025-11-03T10:00:00"
}
```

### Получение метрик

```bash
GET http://localhost:8084/api/stream/trades/metrics
```

**Ответ:**
```json
{
  "service": "TradeStreamingService",
  "running": true,
  "connected": true,
  "totalReceived": 15000,
  "totalProcessed": 14950,
  "totalErrors": 5,
  "totalDropped": 45,
  "timestamp": "2025-11-03T10:05:00"
}
```

### Создание лимита

```bash
POST http://localhost:8084/api/limits
Content-Type: application/json

{
  "figi": "BBG004S68758",
  "upperLimit": 300.0,
  "lowerLimit": 250.0
}
```

## 📊 Архитектура стримов

```
┌────────────────────────────────────┐
│         Postman Request            │
└────────────────┬───────────────────┘
                 │
┌────────────────▼───────────────────┐
│      Stream Controllers            │
│  • TradeStreamController           │
│  • MinuteCandleStreamController    │
│  • LastPriceStreamController       │
│  • LimitStreamController           │
└────────────────┬───────────────────┘
                 │
┌────────────────▼───────────────────┐
│     Streaming Services             │
│  • TradeStreamingService           │
│  • MinuteCandleStreamingService    │
│  • LastPriceStreamingService       │
│  • LimitMonitoringStreamingService │
└────────────────┬───────────────────┘
                 │
┌────────────────▼───────────────────┐
│         Processors                 │
│  • TradeProcessor                  │
│  • CandleProcessor                 │
│  • LastPriceProcessor              │
│  • LimitMonitorService             │
└────────────────┬───────────────────┘
                 │
┌────────────────▼───────────────────┐
│       PostgreSQL Database          │
│  • invest.trades                   │
│  • invest.minute_candles           │
│  • invest.last_prices              │
└────────────────────────────────────┘
```

## 🎯 Endpoints по категориям

### Trades Stream
```
POST /api/stream/trades/start
POST /api/stream/trades/stop
POST /api/stream/trades/reconnect
GET  /api/stream/trades/status
GET  /api/stream/trades/metrics
```

### Minute Candles Stream
```
POST /api/stream/minute-candles/start
POST /api/stream/minute-candles/stop
POST /api/stream/minute-candles/reconnect
GET  /api/stream/minute-candles/status
GET  /api/stream/minute-candles/metrics
```

### Last Price Stream
```
POST /api/stream/last-price/start
POST /api/stream/last-price/stop
POST /api/stream/last-price/reconnect
GET  /api/stream/last-price/status
GET  /api/stream/last-price/metrics
```

### Limits Stream
```
POST /api/stream/limits/start
POST /api/stream/limits/stop
POST /api/stream/limits/reconnect
GET  /api/stream/limits/status
GET  /api/stream/limits/metrics
```

## 💡 Советы по использованию

### 1. Последовательный запуск стримов

Запускайте стримы с интервалом 2-3 секунды:

1. Сначала Trade Stream
2. Затем Minute Candles Stream
3. Потом Last Price Stream
4. И наконец Limits Stream

### 2. Мониторинг производительности

Проверяйте метрики каждого стрима через `/metrics` endpoint:
- `totalReceived` - должно расти
- `totalProcessed` - должно быть близко к received
- `totalErrors` - должно быть минимальным (<1%)
- `totalDropped` - должно быть 0 или минимальным

### 3. Работа с лимитами

1. Сначала создайте лимиты через `/api/limits`
2. Затем запустите Limits Stream
3. Мониторьте уведомления в Telegram

### 4. Получение данных из БД

После работы стримов данные доступны через:
- Candles API - `/api/candles/{figi}`
- Прямые SQL запросы к таблицам

## 🔍 Troubleshooting

### Стрим не запускается

1. Проверьте health: `GET /actuator/health`
2. Убедитесь что кэши прогреты: `POST /api/cache/warmup`
3. Проверьте статус: `GET /api/stream/{type}/status`

### Высокий процент ошибок

1. Проверьте метрики: `GET /api/stream/{type}/metrics`
2. Если `totalErrors / totalReceived > 0.01` - есть проблема
3. Проверьте логи приложения
4. Используйте reconnect: `POST /api/stream/{type}/reconnect`

### Стрим отключился

1. Проверьте статус: `GET /api/stream/{type}/status`
2. Используйте reconnect: `POST /api/stream/{type}/reconnect`
3. Если не помогло - остановите и запустите заново

## 📝 Изменения в v2

### ✅ Что изменилось

- ❌ Удален старый endpoint `/api/streaming-service/*`
- ✅ Добавлены 4 независимых контроллера для каждого стрима
- ✅ Каждый стрим имеет свои endpoints
- ✅ Улучшена независимость стримов
- ✅ Добавлены детальные метрики для каждого стрима

### 🔄 Миграция со старой версии

**Старые endpoints:**
```
POST /api/streaming-service/start
POST /api/streaming-service/stop
GET  /api/streaming-service/status
```

**Новые endpoints (выберите нужный стрим):**
```
POST /api/stream/trades/start
POST /api/stream/minute-candles/start
POST /api/stream/last-price/start
POST /api/stream/limits/start
```

## 📚 Дополнительная документация

- [Архитектура стримов](../docs/NEW_STREAMING_ARCHITECTURE.md)
- [API Reference](../docs/API_REFERENCE.md)
- [Quick Start Guide](../docs/README.md)

## 🎉 Готово!

Коллекция полностью настроена и готова к использованию. Все 4 независимых стрима доступны через единую коллекцию Postman.

**Happy Testing! 🚀**

