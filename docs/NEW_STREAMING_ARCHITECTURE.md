# Новая архитектура стриминга данных

## Обзор

Сервис полностью переработан для обеспечения независимости подписок и чистой архитектуры. Каждый тип данных имеет свой независимый стрим с собственным контроллером, процессором и таблицей в БД.

## Архитектура

### 1. Четыре независимых стрима

#### 1.1 Trade Stream (Обезличенные сделки)
- **Контроллер**: `TradeStreamController` (`/api/stream/trades`)
- **Сервис**: `TradeStreamingService`
- **Процессор**: `TradeProcessor`
- **Entity**: `TradeEntity` + `TradeKey`
- **DTO**: `TradeDto`
- **Repository**: `TradeRepository`
- **Mapper**: `TradeMapper`
- **Таблица БД**: `invest.trades`

**Поля таблицы trades:**
- `figi` (PK)
- `time` (PK)
- `direction` (PK) - направление сделки (BUY/SELL)
- `price` - цена сделки
- `quantity` - количество
- `currency` - валюта
- `exchange` - биржа
- `trade_source` - источник сделки
- `trade_direction` - направление

#### 1.2 MinuteCandle Stream (Минутные свечи)
- **Контроллер**: `MinuteCandleStreamController` (`/api/stream/minute-candles`)
- **Сервис**: `MinuteCandleStreamingService`
- **Процессор**: `CandleProcessor`
- **Entity**: `MinuteCandleEntity` + `MinuteCandleKey`
- **DTO**: `MinuteCandleDto`
- **Repository**: `CandleRepository`
- **Mapper**: `MinuteCandleMapper`
- **Таблица БД**: `invest.minute_candles`

**Поля таблицы minute_candles:**
- `figi` (PK)
- `time` (PK)
- `open` - цена открытия
- `high` - максимальная цена
- `low` - минимальная цена
- `close` - цена закрытия
- `volume` - объем
- `is_complete` - свеча завершена
- Технические показатели: `price_change`, `price_change_percent`, `candle_type`, `body_size`, `upper_shadow`, `lower_shadow`, `high_low_range`, `average_price`
- `created_at`, `updated_at`

#### 1.3 LastPrice Stream (Цены последних сделок)
- **Контроллер**: `LastPriceStreamController` (`/api/stream/last-price`)
- **Сервис**: `LastPriceStreamingService`
- **Процессор**: `LastPriceProcessor`
- **Entity**: `LastPriceEntity` + `LastPriceKey`
- **DTO**: `LastPriceDto`
- **Repository**: `LastPriceRepository`
- **Mapper**: `LastPriceMapper`
- **Таблица БД**: `invest.last_prices`

**Поля таблицы last_prices:**
- `figi` (PK)
- `time` (PK)
- `price` - цена последней сделки
- `currency` - валюта
- `exchange` - биржа

#### 1.4 Limit Monitoring Stream (Мониторинг лимитов)
- **Контроллер**: `LimitStreamController` (`/api/stream/limits`)
- **Сервис**: `LimitMonitoringStreamingService`
- **Логика**: `LimitMonitorService`
- **Таблица БД**: Не записывает в БД, отправляет уведомления в Telegram

Использует поток LastPrice для отслеживания приближения к лимитам и отправки уведомлений.

### 2. Общие компоненты

#### 2.1 GrpcConnectionManager
Управляет соединением с T-Invest API:
- Установка и поддержка соединения
- Автоматическое переподключение
- Отправка запросов
- Обработка ошибок

#### 2.2 DataProcessor Interface
Общий интерфейс для всех процессоров:
```java
public interface DataProcessor<T> {
    CompletableFuture<Void> process(T data);
    void handleError(Throwable error);
}
```

#### 2.3 StreamingService Interface
Общий интерфейс для всех стриминговых сервисов:
```java
public interface StreamingService<T> {
    CompletableFuture<Void> start();
    CompletableFuture<Void> stop();
    CompletableFuture<Void> reconnect();
    boolean isRunning();
    boolean isConnected();
    StreamingMetrics getMetrics();
    String getServiceName();
    Class<T> getDataType();
}
```

#### 2.4 StreamingMetrics
Метрики для каждого стрима:
- `totalReceived` - всего получено
- `totalProcessed` - всего обработано
- `totalErrors` - всего ошибок
- `totalDropped` - всего пропущено
- `isRunning` - запущен ли стрим
- `isConnected` - подключен ли к API

## API Endpoints

### Trade Stream
```
POST /api/stream/trades/start        - Запустить стрим
POST /api/stream/trades/stop         - Остановить стрим
POST /api/stream/trades/reconnect    - Переподключить
GET  /api/stream/trades/status       - Состояние стрима
GET  /api/stream/trades/metrics      - Метрики стрима
```

### MinuteCandle Stream
```
POST /api/stream/minute-candles/start        - Запустить стрим
POST /api/stream/minute-candles/stop         - Остановить стрим
POST /api/stream/minute-candles/reconnect    - Переподключить
GET  /api/stream/minute-candles/status       - Состояние стрима
GET  /api/stream/minute-candles/metrics      - Метрики стрима
```

### LastPrice Stream
```
POST /api/stream/last-price/start        - Запустить стрим
POST /api/stream/last-price/stop         - Остановить стрим
POST /api/stream/last-price/reconnect    - Переподключить
GET  /api/stream/last-price/status       - Состояние стрима
GET  /api/stream/last-price/metrics      - Метрики стрима
```

### Limit Monitoring Stream
```
POST /api/stream/limits/start        - Запустить стрим
POST /api/stream/limits/stop         - Остановить стрим
POST /api/stream/limits/reconnect    - Переподключить
GET  /api/stream/limits/status       - Состояние стрима
GET  /api/stream/limits/metrics      - Метрики стрима
```

## Примеры использования

### Запуск стрима trades
```bash
curl -X POST http://localhost:8080/api/stream/trades/start
```

Ответ:
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
curl http://localhost:8080/api/stream/trades/metrics
```

Ответ:
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

### Запуск всех стримов последовательно
```bash
# Запускаем trades
curl -X POST http://localhost:8080/api/stream/trades/start

# Запускаем minute candles
curl -X POST http://localhost:8080/api/stream/minute-candles/start

# Запускаем last price
curl -X POST http://localhost:8080/api/stream/last-price/start

# Запускаем limit monitoring
curl -X POST http://localhost:8080/api/stream/limits/start
```

## Преимущества новой архитектуры

1. **Независимость стримов**: Каждый стрим работает независимо, падение одного не влияет на другие
2. **Чистая архитектура**: Четкое разделение ответственности между слоями
3. **Легкая масштабируемость**: Просто добавить новый стрим
4. **Простота управления**: Отдельный контроллер для каждого стрима
5. **Гибкость**: Можно запускать/останавливать любой стрим независимо
6. **Мониторинг**: Детальные метрики для каждого стрима
7. **Производительность**: Асинхронная обработка и запись в БД

## Миграция со старой архитектуры

### Удаленные компоненты
- ❌ `StreamingServiceController` (старый единый контроллер)
- ❌ `MarketDataStreamingServiceAdapter`
- ❌ `MarketDataStreamingOrchestrator`
- ❌ `StreamingMetricsManager`
- ❌ `CandleStreamingService` (старый)

### Новые компоненты
- ✅ `MinuteCandleStreamController`
- ✅ `LastPriceStreamController`
- ✅ `LimitStreamController`
- ✅ `MinuteCandleStreamingService`
- ✅ `LastPriceStreamingService`
- ✅ `CandleProcessor`
- ✅ `LastPriceRepository`
- ✅ `LastPriceDto`
- ✅ `LastPriceMapper`

### Изменения в API
Старый API `/api/streaming-service/*` больше не поддерживается.
Используйте новые endpoints:
- `/api/stream/minute-candles/*`
- `/api/stream/last-price/*`
- `/api/stream/limits/*`

## Производительность

### Конфигурация потоков
- **TradeProcessor**: 
  - Потоков вставки: `CPU cores * 6`
  - Макс. одновременных вставок: 200
  
- **CandleProcessor**: 
  - Потоков вставки: `CPU cores * 4`
  - Макс. одновременных вставок: 200
  
- **LastPriceProcessor**: 
  - Потоков вставки: `CPU cores * 4`
  - Макс. одновременных вставок: 100

### Оптимизации БД
- Используется `ON CONFLICT DO UPDATE` для upsert операций
- Асинхронная запись через ExecutorService
- Семафоры для контроля нагрузки
- Batch операции где возможно

## Мониторинг

Каждый стрим предоставляет следующие метрики:
- Количество полученных сообщений
- Количество обработанных сообщений
- Количество ошибок
- Количество пропущенных сообщений (из-за перегрузки)
- Статус подключения
- Статус работы

Метрики можно получить через endpoint `/metrics` каждого стрима.

## Логирование

Каждый стрим логирует:
- Запуск/остановку
- Подключение/отключение
- Ошибки обработки
- Периодическую статистику (каждые N сообщений)
- Критические события (перегрузка, большое количество ошибок)

## Рекомендации

1. **Запускайте стримы последовательно** с интервалом 2-3 секунды
2. **Мониторьте метрики** через endpoint `/metrics`
3. **Настройте алерты** на высокий процент ошибок (>1%)
4. **Используйте reconnect** при проблемах с соединением
5. **Проверяйте логи** при возникновении проблем

## Troubleshooting

### Стрим не запускается
1. Проверьте статус через `/status`
2. Проверьте логи на ошибки
3. Убедитесь что инструменты загружены в кэш
4. Проверьте подключение к БД

### Высокий процент ошибок
1. Проверьте метрики через `/metrics`
2. Проверьте нагрузку на БД
3. Увеличьте количество потоков вставки
4. Проверьте наличие дубликатов

### Стрим отключается
1. Проверьте логи на ошибки gRPC
2. Используйте `/reconnect` для переподключения
3. Проверьте стабильность сети
4. Проверьте токен T-Invest API

## Заключение

Новая архитектура обеспечивает:
- ✅ Полную независимость стримов
- ✅ Чистую архитектуру
- ✅ Простоту управления
- ✅ Высокую производительность
- ✅ Легкую масштабируемость
- ✅ Детальный мониторинг

Все подписки теперь управляются через контроллеры, каждый стрим работает независимо и пишет в свою таблицу БД.

