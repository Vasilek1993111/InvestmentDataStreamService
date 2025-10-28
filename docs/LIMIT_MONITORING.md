# Мониторинг лимитов инструментов

## Обзор

Система мониторинга лимитов предназначена для отслеживания приближения цен инструментов к лимитам (верхнему и нижнему) и отправки уведомлений в Telegram канал при достижении пороговых значений.

## Архитектура

### Компоненты системы

1. **LimitMonitoringStreamingService** - потоковый сервис для получения данных LAST_PRICE
2. **LimitMonitorService** - основной сервис для анализа данных и отправки уведомлений
3. **LimitMonitoringController** - REST API для управления сервисом
4. **LimitMonitoringScheduler** - планировщик для периодических задач
5. **LimitAlertDto** - DTO для данных о приближении к лимитам

### Поток данных

```
T-Invest API → LimitMonitoringStreamingService → LimitMonitorService → Telegram Bot
```

## Функциональность

### Мониторинг лимитов

- **Приближение к лимиту**: уведомление при достижении 1% от лимита
- **Достижение лимита**: уведомление при достижении лимита
- **Типы лимитов**: UP (верхний) и DOWN (нижний)

### Логика работы

1. Получение данных LAST_PRICE из T-Invest API
2. Получение лимитов инструмента из кэша
3. Вычисление расстояния до лимита в процентах
4. Проверка условий для отправки уведомления
5. Формирование и отправка сообщения в Telegram

### Ограничения

- **Одно уведомление в день**: для каждого инструмента и типа лимита
- **Автоматическая очистка**: кэш уведомлений очищается ежедневно в 00:01

## Конфигурация

### Переменные окружения

```bash
# Telegram Bot
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_BOT_USERNAME=your_bot_username
TELEGRAM_LIMIT_CHANNEL_ID=your_channel_id
```

### Настройки в application.properties

```properties
# Telegram Bot Configuration
telegram.bot.token=${TELEGRAM_BOT_TOKEN:your-bot-token-here}
telegram.bot.username=${TELEGRAM_BOT_USERNAME:your-bot-username}
telegram.limit.channel.id=${TELEGRAM_LIMIT_CHANNEL_ID:your-channel-id-here}

# Spring Scheduler Configuration
spring.task.scheduling.enabled=true
spring.task.scheduling.pool.size=2
```

## API Endpoints

### Управление сервисом

#### Запуск сервиса
```http
POST /api/limit-monitoring/start
```

#### Остановка сервиса
```http
POST /api/limit-monitoring/stop
```

#### Переподключение сервиса
```http
POST /api/limit-monitoring/reconnect
```

#### Статус сервиса
```http
GET /api/limit-monitoring/status
```

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

### Статистика

#### Получение статистики
```http
GET /api/limit-monitoring/statistics
```

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

#### Очистка кэша уведомлений
```http
POST /api/limit-monitoring/clear-cache
```

## Формат уведомлений

### Сообщение в Telegram

```
🚨 ПРИБЛИЖЕНИЕ К ЛИМИТУ

📊 Тикер: SBER
🔗 FIGI: BBG004730N88
📅 Дата и время: 15.01.2024 13:30:15
💰 Текущая цена: 250.50 ₽
📈 Цена закрытия ОС: 248.75 ₽
🌙 Цена закрытия вечерней: 249.20 ₽
🎯 Тип лимита: UP
📊 Цена лимита: 255.00 ₽
⚠️ Расстояние до лимита: 1.80%
```

## Планировщик задач

### Ежедневная очистка кэша
- **Время**: 00:01 (московское время)
- **Задача**: Очистка кэша уведомлений за предыдущие дни

### Еженедельная статистика
- **Время**: 09:00 по понедельникам (московское время)
- **Задача**: Вывод статистики работы за неделю

## Мониторинг и логирование

### Логи

Все события записываются в лог-файлы:
- `logs/current/investment-data-stream-service.log` - основные события
- `logs/current/errors.log` - ошибки

### Метрики

- `totalAlertsProcessed` - всего обработано алертов
- `approachingLimitAlerts` - приближение к лимиту
- `limitReachedAlerts` - лимит достигнут
- `notificationsSent` - уведомлений отправлено

## Примеры использования

### Запуск мониторинга

1. Настройте переменные окружения
2. Запустите приложение
3. Сервис автоматически запустится с основными сервисами

### Ручное управление

```bash
# Запуск сервиса
curl -X POST http://localhost:8084/api/limit-monitoring/start

# Проверка статуса
curl http://localhost:8084/api/limit-monitoring/status

# Получение статистики
curl http://localhost:8084/api/limit-monitoring/statistics
```

## Устранение неполадок

### Проблемы с Telegram

1. Проверьте правильность токена бота
2. Убедитесь, что бот добавлен в канал
3. Проверьте права бота на отправку сообщений

### Проблемы с лимитами

1. Убедитесь, что лимиты загружены в кэш
2. Проверьте подключение к T-Invest API
3. Проверьте логи на наличие ошибок

### Проблемы с производительностью

1. Мониторьте использование памяти
2. Проверьте количество обрабатываемых сообщений
3. При необходимости увеличьте размер пула потоков
