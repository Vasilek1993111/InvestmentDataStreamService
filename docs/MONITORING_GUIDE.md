# Руководство по мониторингу сервиса

## Обзор

Данное руководство описывает методы мониторинга и диагностики сервиса `InvestmentDataStreamService` для обеспечения стабильной работы системы потоковых данных.

## Ключевые метрики

### 1. Доступность сервиса

#### Критические метрики

- **`running`** - Статус работы сервиса
- **`connected`** - Подключение к Tinkoff API

#### Мониторинг

```bash
# Проверка статуса каждые 30 секунд
while true; do
  curl -s http://localhost:8084/api/streaming-service/stats | jq '.running, .connected'
  sleep 30
done
```

#### Алерты

- `running: false` → **КРИТИЧЕСКИЙ** - Сервис остановлен
- `connected: false` → **ПРЕДУПРЕЖДЕНИЕ** - Потеряно подключение к API

### 2. Производительность

#### Ключевые показатели

- **`overallProcessingRate`** - Общая скорость обработки (записей/сек)
- **`tradeProcessingRate`** - Скорость обработки сделок
- **`tradeInsertUtilization`** - Утилизация буфера вставок

#### Мониторинг

```bash
# Мониторинг производительности
curl -s http://localhost:8084/api/streaming-service/stats | jq '{
  processing_rate: .overallProcessingRate,
  trade_rate: .tradeProcessingRate,
  utilization: .tradeInsertUtilization
}'
```

#### Алерты

- `overallProcessingRate < 1.0` → **ПРЕДУПРЕЖДЕНИЕ** - Низкая производительность
- `tradeInsertUtilization > 0.9` → **ПРЕДУПРЕЖДЕНИЕ** - Переполнение буфера

### 3. Качество данных

#### Ключевые показатели

- **`overallErrorRate`** - Общий процент ошибок
- **`tradeErrorRate`** - Процент ошибок сделок
- **Соотношение полученных/вставленных данных**

#### Мониторинг

```bash
# Проверка качества данных
curl -s http://localhost:8084/api/streaming-service/stats | jq '{
  error_rate: .overallErrorRate,
  trade_error_rate: .tradeErrorRate,
  candle_ratio: (.totalCandleInserted / .totalCandleReceived),
  trade_ratio: (.totalTradeInserted / .totalTradeProcessed)
}'
```

#### Алерты

- `overallErrorRate > 0.05` → **ПРЕДУПРЕЖДЕНИЕ** - Повышенный уровень ошибок
- `overallErrorRate > 0.1` → **КРИТИЧЕСКИЙ** - Высокий уровень ошибок
- `candle_ratio < 0.95` → **КРИТИЧЕСКИЙ** - Потеря данных свечей
- `trade_ratio < 0.95` → **КРИТИЧЕСКИЙ** - Потеря данных сделок

## Настройка мониторинга

### 1. Prometheus + Grafana

#### Конфигурация Prometheus

```yaml
# prometheus.yml
scrape_configs:
  - job_name: "investment-stream-service"
    static_configs:
      - targets: ["localhost:8084"]
    metrics_path: "/api/streaming-service/stats"
    scrape_interval: 30s
```

#### Дашборд Grafana

```json
{
  "dashboard": {
    "title": "Investment Stream Service",
    "panels": [
      {
        "title": "Service Status",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"investment-stream-service\"}"
          }
        ]
      },
      {
        "title": "Processing Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(overallProcessingRate[5m])"
          }
        ]
      }
    ]
  }
}
```

### 2. Zabbix

#### Шаблон мониторинга

```xml
<template>
  <name>Investment Stream Service</name>
  <items>
    <item>
      <name>Service Running</name>
      <key>service.running</key>
      <type>0</type>
    </item>
    <item>
      <name>API Connected</name>
      <key>api.connected</key>
      <type>0</type>
    </item>
    <item>
      <name>Processing Rate</name>
      <key>processing.rate</key>
      <type>0</type>
    </item>
  </items>
  <triggers>
    <trigger>
      <name>Service Down</name>
      <expression>{template:service.running.last()}=0</expression>
      <priority>5</priority>
    </trigger>
  </triggers>
</template>
```

### 3. Nagios/Icinga

#### Конфигурация проверок

```bash
# check_service_status.sh
#!/bin/bash
STATS=$(curl -s http://localhost:8084/api/streaming-service/stats)
RUNNING=$(echo $STATS | jq -r '.running')
CONNECTED=$(echo $STATS | jq -r '.connected')

if [ "$RUNNING" = "true" ] && [ "$CONNECTED" = "true" ]; then
  echo "OK - Service is running and connected"
  exit 0
elif [ "$RUNNING" = "false" ]; then
  echo "CRITICAL - Service is not running"
  exit 2
else
  echo "WARNING - Service running but not connected to API"
  exit 1
fi
```

## Диагностика проблем

### 1. Сервис не запускается

#### Проверки

```bash
# Проверка логов
tail -f logs/application.log | grep ERROR

# Проверка портов
netstat -tlnp | grep 8084

# Проверка конфигурации
curl -s http://localhost:8084/api/streaming-service/stats
```

#### Возможные причины

- Порт 8084 занят
- Ошибка конфигурации БД
- Неверный токен Tinkoff API
- Проблемы с зависимостями

### 2. Высокий уровень ошибок

#### Диагностика

```bash
# Анализ ошибок
curl -s http://localhost:8084/api/streaming-service/stats | jq '{
  total_errors: .totalErrorsAll,
  trade_errors: .totalTradeErrors,
  error_rate: .overallErrorRate
}'

# Проверка логов
grep "ERROR" logs/application.log | tail -20
```

#### Возможные причины

- Проблемы с БД (недоступность, блокировки)
- Сетевые проблемы с Tinkoff API
- Переполнение буферов
- Недостаток ресурсов

### 3. Низкая производительность

#### Диагностика

```bash
# Анализ производительности
curl -s http://localhost:8084/api/streaming-service/stats | jq '{
  processing_rate: .overallProcessingRate,
  trade_rate: .tradeProcessingRate,
  utilization: .tradeInsertUtilization,
  available_slots: .availableTradeInserts
}'
```

#### Возможные причины

- Недостаток CPU/памяти
- Медленная БД
- Неоптимальная конфигурация пулов
- Блокировки в БД

## Автоматизация

### 1. Скрипт мониторинга

```bash
#!/bin/bash
# monitor_service.sh

ENDPOINT="http://localhost:8084/api/streaming-service/stats"
LOG_FILE="/var/log/service_monitor.log"

while true; do
  STATS=$(curl -s $ENDPOINT)

  if [ $? -ne 0 ]; then
    echo "$(date): Service unreachable" >> $LOG_FILE
    # Отправить алерт
    continue
  fi

  RUNNING=$(echo $STATS | jq -r '.running')
  CONNECTED=$(echo $STATS | jq -r '.connected')
  ERROR_RATE=$(echo $STATS | jq -r '.overallErrorRate')

  if [ "$RUNNING" = "false" ]; then
    echo "$(date): Service stopped" >> $LOG_FILE
    # Перезапустить сервис
    curl -X POST http://localhost:8084/api/streaming-service/start
  fi

  if (( $(echo "$ERROR_RATE > 0.1" | bc -l) )); then
    echo "$(date): High error rate: $ERROR_RATE" >> $LOG_FILE
    # Отправить алерт
  fi

  sleep 30
done
```

### 2. Cron задачи

```bash
# /etc/crontab
# Проверка каждые 5 минут
*/5 * * * * /opt/monitor_service.sh

# Ежедневный отчет
0 9 * * * /opt/daily_report.sh
```

### 3. Уведомления

#### Email уведомления

```bash
# send_alert.sh
#!/bin/bash
SUBJECT="Investment Stream Service Alert"
BODY="Service status: $1"
echo "$BODY" | mail -s "$SUBJECT" admin@company.com
```

#### Slack уведомления

```bash
# slack_alert.sh
#!/bin/bash
WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
MESSAGE="Investment Stream Service Alert: $1"
curl -X POST -H 'Content-type: application/json' \
  --data "{\"text\":\"$MESSAGE\"}" \
  $WEBHOOK_URL
```

## Рекомендации

### 1. Настройка алертов

- Используйте многоуровневую систему алертов
- Настройте эскалацию для критических проблем
- Регулярно тестируйте систему уведомлений

### 2. Логирование

- Настройте ротацию логов
- Используйте структурированное логирование
- Мониторьте размер логов

### 3. Резервное копирование

- Регулярно создавайте бэкапы конфигурации
- Тестируйте процедуры восстановления
- Документируйте процедуры восстановления

### 4. Производительность

- Регулярно анализируйте метрики производительности
- Планируйте масштабирование заранее
- Оптимизируйте конфигурацию БД
