# 🚀 Быстрые примеры тестирования

## 📋 Готовые команды для копирования

### 1. Проверка здоровья системы

```bash
# Проверка состояния приложения
curl -X GET "http://localhost:8084/actuator/health"

# Информация о приложении
curl -X GET "http://localhost:8084/actuator/info"
```

### 2. Управление кэшем

```bash
# Прогрев кэша
curl -X POST "http://localhost:8084/api/cache/warmup"

# Статистика кэша
curl -X GET "http://localhost:8084/api/cache/stats"

# Содержимое кэша
curl -X GET "http://localhost:8084/api/cache/content"

# Очистка кэша
curl -X DELETE "http://localhost:8084/api/cache/clear"
```

### 3. Работа с инструментами

```bash
# Все акции
curl -X GET "http://localhost:8084/api/instruments/shares"

# Конкретная акция
curl -X GET "http://localhost:8084/api/instruments/shares/BBG004S68758"

# Все фьючерсы
curl -X GET "http://localhost:8084/api/instruments/futures"

# Конкретный фьючерс
curl -X GET "http://localhost:8084/api/instruments/futures/FUTSBER03260"

# Все индикативные инструменты
curl -X GET "http://localhost:8084/api/instruments/indicatives"

# Поиск инструментов
curl -X GET "http://localhost:8084/api/instruments/search?q=SBER"

# Сводка по инструментам
curl -X GET "http://localhost:8084/api/instruments/summary"
```

### 4. Работа с лимитами

```bash
# Лимиты конкретного инструмента
curl -X GET "http://localhost:8084/api/instruments/limits/BBG004S68758"

# Лимиты всех акций
curl -X GET "http://localhost:8084/api/instruments/limits/shares"

# Лимиты всех фьючерсов
curl -X GET "http://localhost:8084/api/instruments/limits/futures"

# Сводка по лимитам
curl -X GET "http://localhost:8084/api/instruments/limits/summary"

# Статистика кэша лимитов
curl -X GET "http://localhost:8084/api/instruments/limits/cache-stats"
```

### 5. Потоковые сервисы

```bash
# Статус потокового сервиса
curl -X GET "http://localhost:8084/api/streaming-service/status"

# Статистика потокового сервиса
curl -X GET "http://localhost:8084/api/streaming-service/stats"

# Здоровье потокового сервиса
curl -X GET "http://localhost:8084/api/streaming-service/health"

# Запуск потокового сервиса
curl -X POST "http://localhost:8084/api/streaming-service/start"

# Остановка потокового сервиса
curl -X POST "http://localhost:8084/api/streaming-service/stop"
```

### 6. Подписка на свечи

```bash
# Статус подписки на свечи
curl -X GET "http://localhost:8084/api/candles/subscription/status"

# Статистика подписки на свечи
curl -X GET "http://localhost:8084/api/candles/subscription/stats"

# Запуск подписки на свечи
curl -X POST "http://localhost:8084/api/candles/subscription/start"

# Остановка подписки на свечи
curl -X POST "http://localhost:8084/api/candles/subscription/stop"
```

---

## 🧪 PowerShell команды для Windows

### Проверка системы

```powershell
# Проверка здоровья
Invoke-WebRequest -Uri "http://localhost:8084/actuator/health" | Select-Object -ExpandProperty Content | ConvertFrom-Json

# Информация о приложении
Invoke-WebRequest -Uri "http://localhost:8084/actuator/info" | Select-Object -ExpandProperty Content | ConvertFrom-Json
```

### Управление кэшем

```powershell
# Прогрев кэша
Invoke-WebRequest -Uri "http://localhost:8084/api/cache/warmup" -Method POST | Select-Object -ExpandProperty Content | ConvertFrom-Json

# Статистика кэша
Invoke-WebRequest -Uri "http://localhost:8084/api/cache/stats" | Select-Object -ExpandProperty Content | ConvertFrom-Json
```

### Работа с инструментами

```powershell
# Все акции
Invoke-WebRequest -Uri "http://localhost:8084/api/instruments/shares" | Select-Object -ExpandProperty Content | ConvertFrom-Json

# Поиск SBER
Invoke-WebRequest -Uri "http://localhost:8084/api/instruments/search?q=SBER" | Select-Object -ExpandProperty Content | ConvertFrom-Json

# Сводка по инструментам
Invoke-WebRequest -Uri "http://localhost:8084/api/instruments/summary" | Select-Object -ExpandProperty Content | ConvertFrom-Json
```

### Работа с лимитами

```powershell
# Статистика кэша лимитов
Invoke-WebRequest -Uri "http://localhost:8084/api/instruments/limits/cache-stats" | Select-Object -ExpandProperty Content | ConvertFrom-Json

# Сводка по лимитам
Invoke-WebRequest -Uri "http://localhost:8084/api/instruments/limits/summary" | Select-Object -ExpandProperty Content | ConvertFrom-Json
```

---

## 🔍 Проверка конкретных значений

### Проверка количества инструментов

```bash
# Количество акций
curl -s "http://localhost:8084/api/instruments/shares" | jq '.count'

# Количество фьючерсов
curl -s "http://localhost:8084/api/instruments/futures" | jq '.count'

# Общее количество инструментов
curl -s "http://localhost:8084/api/instruments/summary" | jq '.total'
```

### Проверка кэша лимитов

```bash
# Количество лимитов в кэше
curl -s "http://localhost:8084/api/instruments/limits/cache-stats" | jq '.cachedLimitsCount'

# Размер кэша
curl -s "http://localhost:8084/api/instruments/limits/cache-stats" | jq '.cacheStats.size'

# Hit rate кэша
curl -s "http://localhost:8084/api/instruments/limits/cache-stats" | jq '.cacheStats.hitRate'
```

### Проверка производительности

```bash
# Время ответа для акций
time curl -s "http://localhost:8084/api/instruments/shares" > /dev/null

# Время ответа для лимитов
time curl -s "http://localhost:8084/api/instruments/limits/summary" > /dev/null
```

---

## 🎯 Тестовые сценарии

### Сценарий 1: Полная проверка после запуска

```bash
#!/bin/bash
echo "=== Проверка здоровья системы ==="
curl -s "http://localhost:8084/actuator/health" | jq '.status'

echo "=== Прогрев кэша ==="
curl -s -X POST "http://localhost:8084/api/cache/warmup" | jq '.success'

echo "=== Проверка инструментов ==="
curl -s "http://localhost:8084/api/instruments/summary" | jq '.total'

echo "=== Проверка лимитов ==="
curl -s "http://localhost:8084/api/instruments/limits/cache-stats" | jq '.cachedLimitsCount'

echo "=== Тест поиска ==="
curl -s "http://localhost:8084/api/instruments/search?q=SBER" | jq '.totalCount'
```

### Сценарий 2: Проверка производительности

```bash
#!/bin/bash
echo "=== Тест производительности ==="

echo "Акции:"
time curl -s "http://localhost:8084/api/instruments/shares" > /dev/null

echo "Фьючерсы:"
time curl -s "http://localhost:8084/api/instruments/futures" > /dev/null

echo "Лимиты:"
time curl -s "http://localhost:8084/api/instruments/limits/summary" > /dev/null

echo "Поиск:"
time curl -s "http://localhost:8084/api/instruments/search?q=SBER" > /dev/null
```

### Сценарий 3: Проверка кэша

```bash
#!/bin/bash
echo "=== Проверка кэша ==="

echo "Статистика кэша:"
curl -s "http://localhost:8084/api/cache/stats" | jq '.'

echo "Очистка кэша:"
curl -s -X DELETE "http://localhost:8084/api/cache/clear" | jq '.success'

echo "Прогрев кэша:"
curl -s -X POST "http://localhost:8084/api/cache/warmup" | jq '.success'

echo "Проверка после прогрева:"
curl -s "http://localhost:8084/api/cache/stats" | jq '.'
```

---

## 📊 Мониторинг в реальном времени

### Bash скрипт для мониторинга

```bash
#!/bin/bash
while true; do
    clear
    echo "=== Investment Data Stream Service Monitor ==="
    echo "Время: $(date)"
    echo ""
    
    echo "Здоровье системы:"
    curl -s "http://localhost:8084/actuator/health" | jq '.status'
    
    echo ""
    echo "Статистика кэша лимитов:"
    curl -s "http://localhost:8084/api/instruments/limits/cache-stats" | jq '.cachedLimitsCount, .cacheStats.hitRate'
    
    echo ""
    echo "Сводка по инструментам:"
    curl -s "http://localhost:8084/api/instruments/summary" | jq '.total'
    
    sleep 5
done
```

### PowerShell скрипт для мониторинга

```powershell
while ($true) {
    Clear-Host
    Write-Host "=== Investment Data Stream Service Monitor ===" -ForegroundColor Green
    Write-Host "Время: $(Get-Date)" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Здоровье системы:" -ForegroundColor Cyan
    $health = Invoke-WebRequest -Uri "http://localhost:8084/actuator/health" | Select-Object -ExpandProperty Content | ConvertFrom-Json
    Write-Host $health.status -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Статистика кэша лимитов:" -ForegroundColor Cyan
    $limits = Invoke-WebRequest -Uri "http://localhost:8084/api/instruments/limits/cache-stats" | Select-Object -ExpandProperty Content | ConvertFrom-Json
    Write-Host "Количество лимитов: $($limits.cachedLimitsCount)" -ForegroundColor Green
    Write-Host "Hit Rate: $($limits.cacheStats.hitRate)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Сводка по инструментам:" -ForegroundColor Cyan
    $summary = Invoke-WebRequest -Uri "http://localhost:8084/api/instruments/summary" | Select-Object -ExpandProperty Content | ConvertFrom-Json
    Write-Host "Всего инструментов: $($summary.total)" -ForegroundColor Green
    
    Start-Sleep -Seconds 5
}
```

---

## 🚨 Диагностика проблем

### Проверка доступности сервиса

```bash
# Проверка порта
netstat -an | grep :8084

# Проверка процесса
ps aux | grep java

# Проверка логов
tail -f logs/current/investment-data-stream-service.log
```

### Проверка кэша

```bash
# Пустой кэш лимитов
curl -s "http://localhost:8084/api/instruments/limits/cache-stats" | jq '.cachedLimitsCount'

# Если 0, то прогреть кэш
curl -s -X POST "http://localhost:8084/api/cache/warmup"
```

### Проверка производительности

```bash
# Медленные запросы
curl -w "@curl-format.txt" -s "http://localhost:8084/api/instruments/shares" -o /dev/null
```

Создайте файл `curl-format.txt`:
```
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
```

---

**Версия:** 1.0  
**Дата:** 2024-10-26  
**Автор:** Investment Data Stream Service Team

