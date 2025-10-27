# ⚡ Быстрый старт - API минутных свечей

## 🎯 Основные endpoints

```bash
# Управление подпиской
POST   /api/candles/subscription/start    # Запустить
POST   /api/candles/subscription/stop     # Остановить

# Мониторинг
GET    /api/candles/subscription/status   # Статус
GET    /api/candles/subscription/stats    # Статистика
```

## 🤖 Telegram Bot

Для удобного мониторинга также доступен Telegram бот:

```bash
# Команды бота
/start   # Запуск бота
/help    # Список команд
/status  # Статус сервиса
```

**Настройка:** Добавьте в `.env` файл:
```bash
TELEGRAM_BOT_TOKEN=your_bot_token_here
TELEGRAM_BOT_USERNAME=your_bot_username
```

---

## 📖 Примеры cURL

### 1. Запустить подписку

```bash
curl -X POST http://localhost:8080/api/candles/subscription/start
```

**Ответ:**
```json
{
  "success": true,
  "message": "Подписка на свечи успешно запущена",
  "timestamp": "2024-10-21T12:30:00"
}
```

### 2. Проверить статус

```bash
curl http://localhost:8080/api/candles/subscription/status
```

**Ответ:**
```json
{
  "success": true,
  "isRunning": true,
  "isConnected": true,
  "timestamp": "2024-10-21T12:32:00"
}
```

### 3. Получить статистику

```bash
curl http://localhost:8080/api/candles/subscription/stats
```

**Ответ:**
```json
{
  "success": true,
  "isRunning": true,
  "isConnected": true,
  "totalReceived": 15420,
  "totalInserted": 15418,
  "totalErrors": 2,
  "availableInserts": 185,
  "maxConcurrentInserts": 200,
  "insertUtilization": 0.075,
  "errorRate": 0.00013,
  "timestamp": "2024-10-21T12:33:00"
}
```

### 4. Остановить подписку

```bash
curl -X POST http://localhost:8080/api/candles/subscription/stop
```

**Ответ:**
```json
{
  "success": true,
  "message": "Подписка на свечи успешно остановлена",
  "timestamp": "2024-10-21T12:35:00"
}
```

---

## 🐍 Примеры Python

```python
import requests

BASE_URL = "http://localhost:8080/api/candles"

# 1. Запустить подписку
response = requests.post(f"{BASE_URL}/subscription/start")
print(response.json())

# 2. Проверить статус
response = requests.get(f"{BASE_URL}/subscription/status")
status = response.json()
print(f"Running: {status['isRunning']}, Connected: {status['isConnected']}")

# 3. Получить статистику
response = requests.get(f"{BASE_URL}/subscription/stats")
stats = response.json()
print(f"Received: {stats['totalReceived']}, Inserted: {stats['totalInserted']}")
print(f"Error rate: {stats['errorRate']:.2%}")

# 4. Остановить подписку
response = requests.post(f"{BASE_URL}/subscription/stop")
print(response.json())
```

### Мониторинг с периодическим опросом

```python
import requests
import time

def monitor_candles(interval=10, duration=300):
    """
    Мониторинг подписки на свечи
    
    Args:
        interval: интервал опроса в секундах
        duration: общая длительность мониторинга в секундах
    """
    url = "http://localhost:8080/api/candles/subscription/stats"
    
    start_time = time.time()
    while time.time() - start_time < duration:
        response = requests.get(url)
        stats = response.json()
        
        print(f"\n=== {time.strftime('%H:%M:%S')} ===")
        print(f"Status: {'🟢 Running' if stats['isRunning'] else '🔴 Stopped'}")
        print(f"Connection: {'✅ Connected' if stats['isConnected'] else '❌ Disconnected'}")
        print(f"Received: {stats['totalReceived']:,}")
        print(f"Inserted: {stats['totalInserted']:,}")
        print(f"Errors: {stats['totalErrors']}")
        print(f"Utilization: {stats['insertUtilization']:.1%}")
        print(f"Error Rate: {stats['errorRate']:.2%}")
        
        time.sleep(interval)

# Использование
monitor_candles(interval=5, duration=60)  # Мониторинг каждые 5 сек в течение 1 мин
```

---

## 🔄 Типичный workflow

### Базовый сценарий

```bash
# Шаг 1: Запустить подписку
curl -X POST http://localhost:8080/api/candles/subscription/start

# Шаг 2: Подождать несколько секунд
sleep 5

# Шаг 3: Проверить что работает
curl http://localhost:8080/api/candles/subscription/status

# Шаг 4: Посмотреть статистику
curl http://localhost:8080/api/candles/subscription/stats

# Шаг 5: Остановить когда нужно
curl -X POST http://localhost:8080/api/candles/subscription/stop
```

### Автоматизированный мониторинг (Bash)

```bash
#!/bin/bash

# Запуск подписки
echo "🚀 Запуск подписки на свечи..."
curl -s -X POST http://localhost:8080/api/candles/subscription/start | jq

# Мониторинг каждые 10 секунд
echo -e "\n📊 Мониторинг статистики (нажмите Ctrl+C для остановки)..."
while true; do
    sleep 10
    echo -e "\n=== $(date '+%H:%M:%S') ==="
    curl -s http://localhost:8080/api/candles/subscription/stats | jq '{
        isRunning,
        isConnected,
        totalReceived,
        totalInserted,
        totalErrors,
        insertUtilization,
        errorRate
    }'
done
```

---

## 📊 Что происходит при подписке?

```
1. Запрос подписки
   ↓
2. Загрузка акций и фьючерсов из кэша
   ↓
3. Подписка на минутные свечи (T-Invest API)
   ↓
4. Получение свечей в реальном времени
   ↓
5. Для каждой свечи:
   ├─ Вычисление технических показателей
   │  ├─ Тип: BULLISH/BEARISH/DOJI
   │  ├─ Изменение цены и %
   │  ├─ Размер тела
   │  ├─ Верхняя/нижняя тени
   │  └─ Диапазон и средняя цена
   ↓
6. Асинхронное сохранение в БД (minute_candles)
```

---

## 🎨 Структура данных свечи в БД

```sql
CREATE TABLE invest.minute_candles (
    figi                 VARCHAR(255),
    time                 TIMESTAMP,
    open                 NUMERIC(18, 9),
    high                 NUMERIC(18, 9),
    low                  NUMERIC(18, 9),
    close                NUMERIC(18, 9),
    volume               BIGINT,
    is_complete          BOOLEAN,
    
    -- Технические показатели (вычисляются автоматически)
    price_change         NUMERIC(18, 9),     -- close - open
    price_change_percent NUMERIC(18, 4),     -- изменение в %
    candle_type          VARCHAR(20),        -- BULLISH/BEARISH/DOJI
    body_size            NUMERIC(18, 9),     -- размер тела
    upper_shadow         NUMERIC(18, 9),     -- верхняя тень
    lower_shadow         NUMERIC(18, 9),     -- нижняя тень
    high_low_range       NUMERIC(18, 9),     -- high - low
    average_price        NUMERIC(18, 2),     -- (high+low+open+close)/4
    
    created_at           TIMESTAMP,
    updated_at           TIMESTAMP,
    
    PRIMARY KEY (figi, time)
);
```

---

## 🚨 Обработка ошибок

### Подписка уже запущена

```bash
curl -X POST http://localhost:8080/api/candles/subscription/start
```

**Ответ (400 Bad Request):**
```json
{
  "success": false,
  "error": "Подписка на свечи уже активна",
  "timestamp": "2024-10-21T12:30:00"
}
```

**Решение:** Сначала остановите существующую подписку

---

### Подписка не запущена

```bash
curl -X POST http://localhost:8080/api/candles/subscription/stop
```

**Ответ (400 Bad Request):**
```json
{
  "success": false,
  "error": "Подписка на свечи не активна",
  "timestamp": "2024-10-21T12:30:00"
}
```

**Решение:** Подписка уже остановлена, ничего делать не нужно

---

### Нет инструментов для подписки

```bash
curl -X POST http://localhost:8080/api/candles/subscription/start
```

**Ответ (500 Internal Server Error):**
```json
{
  "success": false,
  "error": "Нет инструментов для подписки на свечи",
  "timestamp": "2024-10-21T12:30:00"
}
```

**Решение:** Прогрейте кэш инструментов
```bash
curl -X POST http://localhost:8080/api/cache/warmup
```

---

## 📈 Интерпретация метрик

### insertUtilization (Утилизация)

| Значение | Состояние | Действие |
|----------|-----------|----------|
| < 0.3 (30%) | 🟢 Отлично | Система не нагружена |
| 0.3 - 0.7 | 🟡 Нормально | Средняя нагрузка |
| 0.7 - 0.9 | 🟠 Высокая нагрузка | Рассмотреть увеличение потоков |
| > 0.9 (90%) | 🔴 Перегрузка | Увеличить потоки или разделить нагрузку |

### errorRate (Процент ошибок)

| Значение | Состояние | Действие |
|----------|-----------|----------|
| < 0.01 (1%) | 🟢 Отлично | Нормальная работа |
| 0.01 - 0.05 | 🟡 Внимание | Проверить логи |
| 0.05 - 0.10 | 🟠 Проблема | Исследовать причину |
| > 0.10 (10%) | 🔴 Критично | Остановить и исправить |

---

## 🔧 Полный пример интеграции

```python
import requests
import time
from datetime import datetime

class CandleSubscriptionManager:
    def __init__(self, base_url="http://localhost:8080"):
        self.base_url = f"{base_url}/api/candles"
    
    def start(self):
        """Запустить подписку"""
        response = requests.post(f"{self.base_url}/subscription/start")
        return response.json()
    
    def stop(self):
        """Остановить подписку"""
        response = requests.post(f"{self.base_url}/subscription/stop")
        return response.json()
    
    def status(self):
        """Получить статус"""
        response = requests.get(f"{self.base_url}/subscription/status")
        return response.json()
    
    def stats(self):
        """Получить статистику"""
        response = requests.get(f"{self.base_url}/subscription/stats")
        return response.json()
    
    def is_healthy(self):
        """Проверить здоровье системы"""
        stats = self.stats()
        return (
            stats['isRunning'] and 
            stats['isConnected'] and 
            stats['insertUtilization'] < 0.9 and 
            stats['errorRate'] < 0.05
        )
    
    def run_with_monitoring(self, duration=300, check_interval=10):
        """
        Запустить подписку с мониторингом
        
        Args:
            duration: длительность работы в секундах
            check_interval: интервал проверки в секундах
        """
        print(f"🚀 Запуск подписки на свечи...")
        result = self.start()
        print(f"✅ {result['message']}")
        
        start_time = time.time()
        try:
            while time.time() - start_time < duration:
                time.sleep(check_interval)
                
                stats = self.stats()
                timestamp = datetime.now().strftime("%H:%M:%S")
                
                print(f"\n📊 [{timestamp}] Статистика:")
                print(f"  Получено: {stats['totalReceived']:,}")
                print(f"  Сохранено: {stats['totalInserted']:,}")
                print(f"  Ошибок: {stats['totalErrors']}")
                print(f"  Утилизация: {stats['insertUtilization']:.1%}")
                print(f"  Процент ошибок: {stats['errorRate']:.2%}")
                
                if not self.is_healthy():
                    print("⚠️  ВНИМАНИЕ: Обнаружены проблемы!")
                    if stats['insertUtilization'] > 0.9:
                        print("  - Высокая утилизация потоков")
                    if stats['errorRate'] > 0.05:
                        print("  - Высокий процент ошибок")
                    if not stats['isConnected']:
                        print("  - Потеряно соединение с API")
        
        finally:
            print(f"\n🛑 Остановка подписки...")
            result = self.stop()
            print(f"✅ {result['message']}")

# Использование
if __name__ == "__main__":
    manager = CandleSubscriptionManager()
    
    # Запуск с мониторингом на 5 минут
    manager.run_with_monitoring(duration=300, check_interval=10)
```

---

**Версия:** 1.0  
**Дата:** 2024-10-21

