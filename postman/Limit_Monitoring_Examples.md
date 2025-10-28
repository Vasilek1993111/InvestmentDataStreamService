# Примеры API для мониторинга лимитов

## Переменные окружения

Добавьте в Postman Environment:

```json
{
  "base_url": "http://localhost:8084",
  "api_base": "{{base_url}}/api/limit-monitoring"
}
```

## Запросы

### 1. Получение статистики мониторинга лимитов

**GET** `{{api_base}}/statistics`

**Описание:** Получает статистику работы сервиса мониторинга лимитов

**Ответ:**
```json
{
  "success": true,
  "data": {
    "totalAlertsProcessed": 1500,
    "approachingLimitAlerts": 25,
    "limitReachedAlerts": 5,
    "notificationsSent": 30,
    "dailyNotificationsCount": 15,
    "telegramChannelConfigured": true
  },
  "timestamp": "2024-01-15T13:30:00"
}
```

### 2. Запуск сервиса мониторинга лимитов

**POST** `{{api_base}}/start`

**Описание:** Запускает сервис мониторинга лимитов

**Ответ:**
```json
{
  "success": true,
  "message": "Сервис мониторинга лимитов запущен",
  "timestamp": "2024-01-15T13:30:00"
}
```

### 3. Остановка сервиса мониторинга лимитов

**POST** `{{api_base}}/stop`

**Описание:** Останавливает сервис мониторинга лимитов

**Ответ:**
```json
{
  "success": true,
  "message": "Сервис мониторинга лимитов остановлен",
  "timestamp": "2024-01-15T13:30:00"
}
```

### 4. Переподключение сервиса мониторинга лимитов

**POST** `{{api_base}}/reconnect`

**Описание:** Переподключает сервис мониторинга лимитов

**Ответ:**
```json
{
  "success": true,
  "message": "Сервис мониторинга лимитов переподключен",
  "timestamp": "2024-01-15T13:30:00"
}
```

### 5. Получение статуса сервиса мониторинга лимитов

**GET** `{{api_base}}/status`

**Описание:** Получает статус сервиса мониторинга лимитов

**Ответ:**
```json
{
  "success": true,
  "data": {
    "isRunning": true,
    "isConnected": true,
    "totalReceived": 1500,
    "totalProcessed": 1500,
    "totalErrors": 0,
    "serviceName": "LimitMonitoringStreamingService"
  },
  "timestamp": "2024-01-15T13:30:00"
}
```

### 6. Очистка кэша уведомлений

**POST** `{{api_base}}/clear-cache`

**Описание:** Очищает кэш уведомлений за предыдущие дни

**Ответ:**
```json
{
  "success": true,
  "message": "Кэш уведомлений очищен",
  "timestamp": "2024-01-15T13:30:00"
}
```

## Тестовые сценарии

### Сценарий 1: Проверка работы сервиса

1. Запустите сервис: `POST {{api_base}}/start`
2. Проверьте статус: `GET {{api_base}}/status`
3. Получите статистику: `GET {{api_base}}/statistics`
4. Остановите сервис: `POST {{api_base}}/stop`

### Сценарий 2: Управление сервисом

1. Запустите сервис: `POST {{api_base}}/start`
2. Переподключите сервис: `POST {{api_base}}/reconnect`
3. Очистите кэш: `POST {{api_base}}/clear-cache`
4. Остановите сервис: `POST {{api_base}}/stop`

### Сценарий 3: Мониторинг производительности

1. Запустите сервис: `POST {{api_base}}/start`
2. Подождите несколько минут
3. Получите статистику: `GET {{api_base}}/statistics`
4. Проверьте статус: `GET {{api_base}}/status`

## Обработка ошибок

### Ошибка 500 - Внутренняя ошибка сервера

```json
{
  "success": false,
  "error": "Ошибка при запуске сервиса: Connection timeout",
  "timestamp": "2024-01-15T13:30:00"
}
```

### Ошибка 400 - Неверный запрос

```json
{
  "success": false,
  "error": "Service not found: InvalidServiceName",
  "timestamp": "2024-01-15T13:30:00"
}
```

## Автоматизация

### Newman тесты

```bash
# Запуск тестов для мониторинга лимитов
newman run Investment_Data_Stream_Service_API.postman_collection.json \
  --environment Test_Environment.postman_environment.json \
  --folder "Limit Monitoring"
```

### Скрипт мониторинга

```bash
#!/bin/bash
# Скрипт для мониторинга состояния сервиса

BASE_URL="http://localhost:8084"
API_BASE="$BASE_URL/api/limit-monitoring"

echo "Проверка статуса сервиса мониторинга лимитов..."
curl -s "$API_BASE/status" | jq '.data.isRunning'

echo "Получение статистики..."
curl -s "$API_BASE/statistics" | jq '.data'
```
