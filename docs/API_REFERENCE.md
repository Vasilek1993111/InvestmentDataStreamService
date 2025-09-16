# API Reference - Investment Data Stream Service

## Базовый URL

```
http://localhost:8084
```

## Endpoints

### 1. Статистика сервиса

**GET** `/api/streaming-service/stats`

Возвращает детальную статистику работы сервиса потоковых данных.

#### Ответ

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

#### Коды ответов

- `200 OK` - Статистика успешно получена
- `500 Internal Server Error` - Ошибка сервера

### 2. Управление сервисом

**POST** `/api/streaming-service/start`

Запускает сервис потоковых данных.

#### Ответ

```json
{
  "message": "Streaming service started successfully",
  "status": "success"
}
```

#### Коды ответов

- `200 OK` - Сервис успешно запущен
- `409 Conflict` - Сервис уже запущен
- `500 Internal Server Error` - Ошибка запуска

**POST** `/api/streaming-service/stop`

Останавливает сервис потоковых данных.

#### Ответ

```json
{
  "message": "Streaming service stopped successfully",
  "status": "success"
}
```

#### Коды ответов

- `200 OK` - Сервис успешно остановлен
- `409 Conflict` - Сервис уже остановлен
- `500 Internal Server Error` - Ошибка остановки

### 3. Проверка здоровья

**GET** `/api/streaming-service/health`

Проверяет состояние сервиса.

#### Ответ

```json
{
  "status": "UP",
  "details": {
    "streamingService": {
      "status": "UP",
      "details": {
        "running": true,
        "connected": true,
        "lastUpdate": "2024-01-15T10:30:00Z"
      }
    }
  }
}
```

#### Коды ответов

- `200 OK` - Сервис работает нормально
- `503 Service Unavailable` - Сервис недоступен

## Примеры использования

### cURL

```bash
# Получить статистику
curl -X GET http://localhost:8084/api/streaming-service/stats

# Запустить сервис
curl -X POST http://localhost:8084/api/streaming-service/start

# Остановить сервис
curl -X POST http://localhost:8084/api/streaming-service/stop

# Проверить здоровье
curl -X GET http://localhost:8084/api/streaming-service/health
```

### PowerShell

```powershell
# Получить статистику
Invoke-RestMethod -Uri "http://localhost:8084/api/streaming-service/stats" -Method GET

# Запустить сервис
Invoke-RestMethod -Uri "http://localhost:8084/api/streaming-service/start" -Method POST

# Остановить сервис
Invoke-RestMethod -Uri "http://localhost:8084/api/streaming-service/stop" -Method POST
```

### JavaScript (Node.js)

```javascript
const axios = require("axios");

// Получить статистику
async function getStats() {
  try {
    const response = await axios.get(
      "http://localhost:8084/api/streaming-service/stats"
    );
    console.log(response.data);
  } catch (error) {
    console.error("Error:", error.message);
  }
}

// Запустить сервис
async function startService() {
  try {
    const response = await axios.post(
      "http://localhost:8084/api/streaming-service/start"
    );
    console.log(response.data);
  } catch (error) {
    console.error("Error:", error.message);
  }
}
```

### Python

```python
import requests

# Получить статистику
def get_stats():
    try:
        response = requests.get('http://localhost:8084/api/streaming-service/stats')
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None

# Запустить сервис
def start_service():
    try:
        response = requests.post('http://localhost:8084/api/streaming-service/start')
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        return None

# Использование
stats = get_stats()
if stats:
    print(f"Service running: {stats['running']}")
    print(f"Total trades processed: {stats['totalTradeProcessed']}")
```

## Обработка ошибок

### Стандартные HTTP коды

- `200 OK` - Успешный запрос
- `400 Bad Request` - Некорректный запрос
- `404 Not Found` - Ресурс не найден
- `409 Conflict` - Конфликт состояния (например, попытка запустить уже запущенный сервис)
- `500 Internal Server Error` - Внутренняя ошибка сервера
- `503 Service Unavailable` - Сервис временно недоступен

### Формат ошибок

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "status": 500,
  "error": "Internal Server Error",
  "message": "Failed to start streaming service",
  "path": "/api/streaming-service/start"
}
```

## Мониторинг и логирование

### Логирование

Сервис ведет подробные логи:

- Запуск/остановка сервиса
- Подключение к Tinkoff API
- Ошибки обработки данных
- Агрегированная статистика каждые 1000 событий

### Метрики

Все метрики доступны через `/api/streaming-service/stats`:

- Счетчики событий в реальном времени
- Производительность обработки
- Статус подключений
- Использование ресурсов

## Безопасность

### Аутентификация

В текущей версии аутентификация не реализована. Для продакшена рекомендуется:

- Добавить API ключи
- Использовать HTTPS
- Настроить CORS политики

### Ограничения

- Нет ограничений на частоту запросов
- Нет валидации входных параметров (не требуется для текущих endpoints)
