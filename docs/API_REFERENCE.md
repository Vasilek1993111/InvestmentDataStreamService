# API Reference - Investment Data Stream Service

## Базовый URL

```
http://localhost:8084
```

## Telegram Bot

Сервис также предоставляет Telegram бота для мониторинга и управления. Бот автоматически запускается при старте сервиса.

### Настройка бота

1. Создайте бота через [@BotFather](https://t.me/botfather)
2. Добавьте токен в переменные окружения:
   ```bash
   TELEGRAM_BOT_TOKEN=your_bot_token_here
   TELEGRAM_BOT_USERNAME=your_bot_username
   ```

### Команды бота

| Команда | Описание |
|---------|----------|
| `/start` | Запуск бота и получение приветствия |
| `/help` | Список всех доступных команд |
| `/status` | Проверка статуса сервиса |

Подробная документация: [TELEGRAM_BOT.md](TELEGRAM_BOT.md)

## Архитектура API

Сервис использует модульную архитектуру с независимыми стримами для каждого типа данных:

- **Trade Stream** - обезличенные сделки (`/api/stream/trades`)
- **MinuteCandle Stream** - минутные свечи (`/api/stream/minute-candles`)
- **LastPrice Stream** - цены последних сделок (`/api/stream/last-price`)
- **Limit Monitoring Stream** - мониторинг лимитов (`/api/stream/limits`)
- **Limit Monitor Management** - управление настройками мониторинга (`/api/limit-monitor`)
- **Cache Management** - управление кэшем (`/api/cache`)
- **Instruments** - работа с инструментами (`/api/instruments`)

## Endpoints

### Stream Endpoints

Каждый стрим имеет стандартный набор endpoints:

#### Trade Stream (`/api/stream/trades`)

**POST** `/api/stream/trades/start`

Запускает стрим обезличенных сделок. Данные сохраняются в таблицу `invest.trades`.

**Ответ:**
```json
{
  "success": true,
  "message": "Trade streaming started successfully",
  "service": "TradeStreamingService",
  "timestamp": "2025-11-03T10:00:00"
}
```

**POST** `/api/stream/trades/stop`

Останавливает стрим обезличенных сделок.

**POST** `/api/stream/trades/reconnect`

Инициирует переподключение стрима.

**GET** `/api/stream/trades/status`

Возвращает текущее состояние стрима.

**Ответ:**
```json
{
  "service": "TradeStreamingService",
  "running": true,
  "connected": true,
  "timestamp": "2025-11-03T10:05:00"
}
```

**GET** `/api/stream/trades/metrics`

Возвращает метрики производительности стрима.

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

#### MinuteCandle Stream (`/api/stream/minute-candles`)

**POST** `/api/stream/minute-candles/start`

Запускает стрим минутных свечей. Данные сохраняются в таблицу `invest.minute_candles`.

**Ответ:**
```json
{
  "success": true,
  "message": "MinuteCandle streaming started successfully",
  "service": "MinuteCandleStreamingService",
  "timestamp": "2025-11-03T10:00:00"
}
```

**POST** `/api/stream/minute-candles/stop`

Останавливает стрим минутных свечей.

**POST** `/api/stream/minute-candles/reconnect`

Инициирует переподключение стрима.

**GET** `/api/stream/minute-candles/status`

Возвращает текущее состояние стрима.

**GET** `/api/stream/minute-candles/metrics`

Возвращает метрики производительности стрима.

#### LastPrice Stream (`/api/stream/last-price`)

**POST** `/api/stream/last-price/start`

Запускает стрим цен последних сделок. Данные сохраняются в таблицу `invest.last_prices`.

**Ответ:**
```json
{
  "success": true,
  "message": "LastPrice streaming started successfully",
  "service": "LastPriceStreamingService",
  "timestamp": "2025-11-03T10:00:00"
}
```

**POST** `/api/stream/last-price/stop`

Останавливает стрим цен последних сделок.

**POST** `/api/stream/last-price/reconnect`

Инициирует переподключение стрима.

**GET** `/api/stream/last-price/status`

Возвращает текущее состояние стрима.

**GET** `/api/stream/last-price/metrics`

Возвращает метрики производительности стрима.

#### Limit Monitoring Stream (`/api/stream/limits`)

**POST** `/api/stream/limits/start`

Запускает стрим мониторинга лимитов. Использует LastPrice для отслеживания приближения к лимитам и отправки уведомлений в Telegram.

**Ответ:**
```json
{
  "success": true,
  "message": "Limit monitoring streaming started successfully",
  "service": "LimitMonitoringStreamingService",
  "timestamp": "2025-11-03T10:00:00"
}
```

**POST** `/api/stream/limits/stop`

Останавливает стрим мониторинга лимитов.

**POST** `/api/stream/limits/reconnect`

Инициирует переподключение стрима.

**GET** `/api/stream/limits/status`

Возвращает текущее состояние стрима.

**GET** `/api/stream/limits/metrics`

Возвращает метрики производительности стрима.

### Cache Management (`/api/cache`)

**POST** `/api/cache/warmup`

Принудительно прогревает все кэши инструментов (акции, фьючерсы, индикативы).

**Ответ:**
```json
{
  "success": true,
  "message": "Кэш успешно прогрет",
  "timestamp": "2025-11-03T10:30:00"
}
```

**GET** `/api/cache/content`

Возвращает содержимое кэша.

**Параметры запроса:**
- `cacheName` (опционально) - имя конкретного кэша (`sharesCache`, `futuresCache`, `indicativesCache`)
- `limit` (опционально, по умолчанию 100) - максимальное количество записей для отображения

**Примеры:**
```
GET /api/cache/content
GET /api/cache/content?cacheName=sharesCache
GET /api/cache/content?limit=50
```

**GET** `/api/cache/stats`

Возвращает статистику по всем кэшам.

**Ответ:**
```json
{
  "timestamp": "2025-11-03T10:30:00",
  "totalCaches": 3,
  "activeCaches": 3,
  "totalEntries": 1500,
  "cacheDetails": {
    "sharesCache": {
      "entryCount": 1000,
      "statistics": {
        "hitCount": 5000,
        "missCount": 100,
        "hitRate": 0.98,
        "evictionCount": 0
      }
    }
  }
}
```

**DELETE** `/api/cache/clear`

Очищает кэш.

**Параметры запроса:**
- `cacheName` (опционально) - имя конкретного кэша для очистки

**Примеры:**
```
DELETE /api/cache/clear
DELETE /api/cache/clear?cacheName=sharesCache
```

### Instruments (`/api/instruments`)

**GET** `/api/instruments/shares`

Возвращает все акции из кэша.

**Ответ:**
```json
{
  "success": true,
  "count": 150,
  "data": [
    {
      "figi": "BBG004730N88",
      "ticker": "SBER",
      "name": "Сбербанк",
      ...
    }
  ],
  "timestamp": "2025-11-03T10:30:00"
}
```

**GET** `/api/instruments/shares/{figi}`

Возвращает акцию по FIGI.

**GET** `/api/instruments/futures`

Возвращает все фьючерсы из кэша.

**GET** `/api/instruments/futures/{figi}`

Возвращает фьючерс по FIGI.

**GET** `/api/instruments/indicatives`

Возвращает все индикативные инструменты из кэша.

**GET** `/api/instruments/indicatives/{figi}`

Возвращает индикативный инструмент по FIGI.

**GET** `/api/instruments/search?q={query}`

Поиск инструментов по тикеру или названию.

**Ответ:**
```json
{
  "success": true,
  "query": "SBER",
  "results": {
    "shares": [...],
    "futures": [...],
    "indicatives": [...]
  },
  "totalCount": 5,
  "timestamp": "2025-11-03T10:30:00"
}
```

**GET** `/api/instruments/summary`

Возвращает статистику по инструментам.

**Ответ:**
```json
{
  "success": true,
  "shares": 150,
  "futures": 50,
  "indicatives": 10,
  "total": 210,
  "timestamp": "2025-11-03T10:30:00"
}
```

**GET** `/api/instruments/limits/{figi}`

Возвращает лимиты для инструмента по FIGI из кэша.

**Ответ:**
```json
{
  "success": true,
  "figi": "BBG004730N88",
  "data": {
    "limitDown": 250.0,
    "limitUp": 350.0
  },
  "fromCache": true,
  "timestamp": "2025-11-03T10:30:00"
}
```

**GET** `/api/instruments/limits/shares`

Возвращает лимиты для всех акций из кэша.

**GET** `/api/instruments/limits/futures`

Возвращает лимиты для всех фьючерсов из кэша.

**GET** `/api/instruments/limits/summary`

Возвращает статистику по лимитам из кэша.

**GET** `/api/instruments/limits/cache-stats`

Возвращает статистику кэша лимитов.

### Limit Monitor Management (`/api/limit-monitor`)

**GET** `/api/limit-monitor/thresholds`

Возвращает текущие пороги мониторинга лимитов.

**Ответ:**
```json
{
  "success": true,
  "approachThreshold": 1.0,
  "historicalApproachThreshold": 1.0,
  "timestamp": "2025-11-03T10:30:00"
}
```

**POST** `/api/limit-monitor/thresholds/approach`

Обновляет порог приближения к биржевым лимитам.

**Тело запроса:**
```json
{
  "threshold": 2.0
}
```

**Ответ:**
```json
{
  "success": true,
  "message": "Порог приближения к биржевым лимитам успешно обновлен и синхронизирован",
  "threshold": 2.0,
  "timestamp": "2025-11-03T10:30:00"
}
```

**POST** `/api/limit-monitor/thresholds/historical`

Обновляет порог приближения к историческим экстремумам.

**Тело запроса:**
```json
{
  "threshold": 1.5
}
```

**Ответ:**
```json
{
  "success": true,
  "message": "Порог приближения к историческим экстремумам успешно обновлен и синхронизирован",
  "threshold": 1.5,
  "timestamp": "2025-11-03T10:30:00"
}
```

**POST** `/api/limit-monitor/thresholds`

Обновляет оба порога одновременно.

**Тело запроса:**
```json
{
  "approachThreshold": 2.0,
  "historicalApproachThreshold": 1.5
}
```

**Ответ:**
```json
{
  "success": true,
  "message": "Пороги успешно обновлены и синхронизированы",
  "updated": {
    "approachThreshold": 2.0,
    "historicalApproachThreshold": 1.5
  },
  "timestamp": "2025-11-03T10:30:00"
}
```

**GET** `/api/limit-monitor/statistics`

Возвращает статистику мониторинга лимитов.

**Ответ:**
```json
{
  "success": true,
  "data": {
    "totalAlerts": 150,
    "limitUpAlerts": 80,
    "limitDownAlerts": 70,
    "historicalExtremesAlerts": 30
  },
  "timestamp": "2025-11-03T10:30:00"
}
```

## Примеры использования

### cURL

```bash
# Запуск стрима trades
curl -X POST http://localhost:8084/api/stream/trades/start

# Получение метрик стрима trades
curl http://localhost:8084/api/stream/trades/metrics

# Получение всех акций
curl http://localhost:8084/api/instruments/shares

# Поиск инструментов
curl "http://localhost:8084/api/instruments/search?q=SBER"

# Прогрев кэша
curl -X POST http://localhost:8084/api/cache/warmup

# Статистика кэша
curl http://localhost:8084/api/cache/stats

# Получение порогов мониторинга лимитов
curl http://localhost:8084/api/limit-monitor/thresholds

# Обновление порога приближения к лимитам
curl -X POST http://localhost:8084/api/limit-monitor/thresholds/approach \
  -H "Content-Type: application/json" \
  -d '{"threshold": 2.0}'

# Статистика мониторинга лимитов
curl http://localhost:8084/api/limit-monitor/statistics
```

### PowerShell

```powershell
# Запуск стрима trades
Invoke-RestMethod -Uri "http://localhost:8084/api/stream/trades/start" -Method POST

# Получение метрик стрима trades
Invoke-RestMethod -Uri "http://localhost:8084/api/stream/trades/metrics" -Method GET

# Получение всех акций
Invoke-RestMethod -Uri "http://localhost:8084/api/instruments/shares" -Method GET

# Поиск инструментов
Invoke-RestMethod -Uri "http://localhost:8084/api/instruments/search?q=SBER" -Method GET

# Получение порогов мониторинга лимитов
Invoke-RestMethod -Uri "http://localhost:8084/api/limit-monitor/thresholds" -Method GET

# Обновление порога приближения к лимитам
$body = @{ threshold = 2.0 } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:8084/api/limit-monitor/thresholds/approach" -Method POST -Body $body -ContentType "application/json"

# Статистика мониторинга лимитов
Invoke-RestMethod -Uri "http://localhost:8084/api/limit-monitor/statistics" -Method GET
```
<｜tool▁calls▁begin｜><｜tool▁call▁begin｜>
read_file

### JavaScript (Node.js)

```javascript
const axios = require("axios");

const BASE_URL = "http://localhost:8084";

// Запуск стрима trades
async function startTradeStream() {
  try {
    const response = await axios.post(`${BASE_URL}/api/stream/trades/start`);
    console.log(response.data);
  } catch (error) {
    console.error("Error:", error.message);
  }
}

// Получение метрик стрима trades
async function getTradeMetrics() {
  try {
    const response = await axios.get(`${BASE_URL}/api/stream/trades/metrics`);
    console.log(`Total received: ${response.data.totalReceived}`);
    console.log(`Total processed: ${response.data.totalProcessed}`);
    console.log(`Total errors: ${response.data.totalErrors}`);
  } catch (error) {
    console.error("Error:", error.message);
  }
}

// Получение всех акций
async function getAllShares() {
  try {
    const response = await axios.get(`${BASE_URL}/api/instruments/shares`);
    console.log(`Total shares: ${response.data.count}`);
    console.log(response.data.data);
  } catch (error) {
    console.error("Error:", error.message);
  }
}

// Поиск инструментов
async function searchInstruments(query) {
  try {
    const response = await axios.get(`${BASE_URL}/api/instruments/search?q=${query}`);
    console.log(`Found ${response.data.totalCount} instruments`);
    console.log(response.data.results);
  } catch (error) {
    console.error("Error:", error.message);
  }
}

// Получение порогов мониторинга лимитов
async function getLimitMonitorThresholds() {
  try {
    const response = await axios.get(`${BASE_URL}/api/limit-monitor/thresholds`);
    console.log(`Approach threshold: ${response.data.approachThreshold}%`);
    console.log(`Historical threshold: ${response.data.historicalApproachThreshold}%`);
    return response.data;
  } catch (error) {
    console.error("Error:", error.message);
  }
}

// Обновление порога приближения к лимитам
async function updateApproachThreshold(threshold) {
  try {
    const response = await axios.post(`${BASE_URL}/api/limit-monitor/thresholds/approach`, {
      threshold: threshold
    });
    console.log(response.data.message);
    return response.data;
  } catch (error) {
    console.error("Error:", error.message);
  }
}

// Статистика мониторинга лимитов
async function getLimitMonitorStatistics() {
  try {
    const response = await axios.get(`${BASE_URL}/api/limit-monitor/statistics`);
    console.log(`Total alerts: ${response.data.data.totalAlerts}`);
    return response.data;
  } catch (error) {
    console.error("Error:", error.message);
  }
}
```
<｜tool▁calls▁begin｜><｜tool▁call▁begin｜>
read_file

### Python

```python
import requests

BASE_URL = "http://localhost:8084"

# Запуск стрима trades
def start_trade_stream():
    try:
        response = requests.post(f"{BASE_URL}/api/stream/trades/start")
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None

# Получение метрик стрима trades
def get_trade_metrics():
    try:
        response = requests.get(f"{BASE_URL}/api/stream/trades/metrics")
        response.raise_for_status()
        data = response.json()
        print(f"Total received: {data['totalReceived']}")
        print(f"Total processed: {data['totalProcessed']}")
        print(f"Total errors: {data['totalErrors']}")
        return data
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None

# Получение всех акций
def get_all_shares():
    try:
        response = requests.get(f"{BASE_URL}/api/instruments/shares")
        response.raise_for_status()
        data = response.json()
        print(f"Total shares: {data['count']}")
        return data
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None

# Поиск инструментов
def search_instruments(query):
    try:
        response = requests.get(f"{BASE_URL}/api/instruments/search?q={query}")
        response.raise_for_status()
        data = response.json()
        print(f"Found {data['totalCount']} instruments")
        return data
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None

# Получение порогов мониторинга лимитов
def get_limit_monitor_thresholds():
    try:
        response = requests.get(f"{BASE_URL}/api/limit-monitor/thresholds")
        response.raise_for_status()
        data = response.json()
        print(f"Approach threshold: {data['approachThreshold']}%")
        print(f"Historical threshold: {data['historicalApproachThreshold']}%")
        return data
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None

# Обновление порога приближения к лимитам
def update_approach_threshold(threshold):
    try:
        response = requests.post(
            f"{BASE_URL}/api/limit-monitor/thresholds/approach",
            json={"threshold": threshold}
        )
        response.raise_for_status()
        data = response.json()
        print(data['message'])
        return data
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None

# Статистика мониторинга лимитов
def get_limit_monitor_statistics():
    try:
        response = requests.get(f"{BASE_URL}/api/limit-monitor/statistics")
        response.raise_for_status()
        data = response.json()
        print(f"Total alerts: {data['data']['totalAlerts']}")
        return data
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None
```

## Обработка ошибок

### Стандартные HTTP коды

- `200 OK` - Успешный запрос
- `400 Bad Request` - Некорректный запрос
- `404 Not Found` - Ресурс не найден
- `500 Internal Server Error` - Внутренняя ошибка сервера
- `503 Service Unavailable` - Сервис временно недоступен

### Формат ошибок

```json
{
  "success": false,
  "message": "Error starting trade streaming: Connection failed",
  "timestamp": "2025-11-03T10:30:00"
}
```

## Рекомендации по использованию

### Запуск стримов

1. **Последовательный запуск**: Запускайте стримы последовательно с интервалом 2-3 секунды
2. **Порядок запуска**: 
   - Сначала запустите `last-price` (используется для мониторинга лимитов)
   - Затем `trades` и `minute-candles`
   - В последнюю очередь `limits` (требует `last-price`)

### Мониторинг

- Регулярно проверяйте метрики через `/metrics` endpoints
- Настройте алерты на высокий процент ошибок (>1%)
- Используйте `/status` для проверки состояния стримов

### Кэширование

- Кэш автоматически прогревается при старте приложения
- Используйте `/api/cache/warmup` для принудительного обновления
- Проверяйте статистику кэша через `/api/cache/stats`

### Производительность

- Каждый стрим работает независимо
- Падение одного стрима не влияет на другие
- Используйте `/reconnect` при проблемах с соединением

## Безопасность

### Аутентификация

В текущей версии аутентификация не реализована. Для продакшена рекомендуется:

- Добавить API ключи
- Использовать HTTPS
- Настроить CORS политики
- Ограничить частоту запросов (rate limiting)

### Ограничения

- Нет ограничений на частоту запросов
- Нет валидации входных параметров (для большинства endpoints)

---

**Версия документации**: 2.1  
**Последнее обновление**: 2025-11-10  
**Автор**: Investment Data Stream Service Team
