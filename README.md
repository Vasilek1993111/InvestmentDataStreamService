# Investment Data Stream Service

Высокопроизводительный сервис для потоковой обработки финансовых данных от Tinkoff Invest API с поддержкой Telegram бота.

## 🚀 Быстрый старт

### 1. Настройка окружения

```bash
# Скопируйте примеры конфигурации
cp env.test.example .env.test
cp env.prod.example .env.prod

# Заполните переменные окружения
# .env.test
T_INVEST_TEST_TOKEN=your_test_token
SPRING_DATASOURCE_TEST_PASSWORD=your_db_password
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_BOT_USERNAME=your_bot_username
```

### 2. Запуск сервиса

#### Запуск с Docker (рекомендуется)

```bash
# Подготовка переменных окружения
cp env.prod.example .env
# Отредактируйте .env и заполните необходимые значения

# Windows
docker-start.bat

# Linux/Mac
chmod +x docker-start.sh
./docker-start.sh
```

Или вручную:

```bash
# Создать Docker сеть
docker network create investment-network

# Подключить существующую PostgreSQL БД к сети
docker network connect investment-network investment-postgres

# Сборка и запуск
docker-compose up -d
```

#### Запуск без Docker

```bash
# Сборка
mvn clean package -DskipTests

# Запуск (тестовое окружение)
java -jar target/investment-data-stream-service-*.jar

# Запуск (продакшн)
java -jar target/investment-data-stream-service-*.jar --spring.profiles.active=prod
```

### 3. Проверка работы

```bash
# Запуск стрима минутных свечей
curl -X POST http://localhost:8084/api/stream/minute-candles/start

# Запуск стрима цен последних сделок
curl -X POST http://localhost:8084/api/stream/last-price/start

# Запуск стрима мониторинга лимитов
curl -X POST http://localhost:8084/api/stream/limits/start

# Получение всех акций
curl http://localhost:8084/api/instruments/shares

# Telegram бот
# Найдите вашего бота в Telegram и отправьте /start
```

## 📚 Документация

### 🚀 Быстрый старт
- **[Быстрый старт Docker](QUICK_START_DOCKER.md)** - ⚡ Запуск за 5 минут
- **[Подробная настройка Docker](DOCKER_SETUP.md)** - 🐳 Полное руководство

### 📖 Основная документация
- **[Полная документация](docs/README.md)** - Подробное руководство
- **[API Reference](docs/API_REFERENCE.md)** - Описание REST API
- **[Telegram Bot](docs/TELEGRAM_BOT.md)** - Руководство по боту
- **[Архитектура](docs/ARCHITECTURE_DIAGRAM.md)** - Диаграммы системы
- **[Мониторинг](docs/MONITORING_GUIDE.md)** - Настройка мониторинга
- **[Docker Guide](docs/DOCKER.md)** - Детальное руководство по Docker

## 🎯 Основные возможности

- **📡 Потоковые данные**: 
  - Trade Stream - обезличенные сделки (`/api/stream/trades`)
  - MinuteCandle Stream - минутные свечи (`/api/stream/minute-candles`)
  - LastPrice Stream - цены последних сделок (`/api/stream/last-price`)
  - Limit Monitoring Stream - мониторинг лимитов (`/api/stream/limits`)
- **🤖 Telegram Bot**: Мониторинг и уведомления
- **💾 Кэширование**: Быстрый доступ к инструментам (`/api/cache`)
- **📊 Мониторинг**: Детальная статистика и метрики для каждого стрима
- **🔧 Надежность**: Независимые стримы, автоматическое восстановление

## 🏗️ Архитектура

Сервис использует модульную архитектуру с независимыми стримами:

```
Tinkoff API (gRPC Streams)
    ↓
Investment Data Stream Service
    ├── Trade Stream → invest.trades
    ├── MinuteCandle Stream → invest.minute_candles
    ├── LastPrice Stream → invest.last_prices
    └── Limit Monitoring Stream → Telegram Notifications
    ↓
REST API + Telegram Bot
    ├── /api/stream/* - управление стримами
    ├── /api/cache/* - управление кэшем
    └── /api/instruments/* - работа с инструментами
```

Подробнее: [docs/ARCHITECTURE_DIAGRAM.md](docs/ARCHITECTURE_DIAGRAM.md) | [docs/NEW_STREAMING_ARCHITECTURE.md](docs/NEW_STREAMING_ARCHITECTURE.md)

## ⚙️ Конфигурация

### Переменные окружения

| Переменная | Описание | Пример |
|------------|----------|--------|
| `T_INVEST_TEST_TOKEN` | Токен Tinkoff API (тест) | `t.1234567890abcdef` |
| `T_INVEST_PROD_TOKEN` | Токен Tinkoff API (прод) | `t.1234567890abcdef` |
| `SPRING_DATASOURCE_*_PASSWORD` | Пароль БД | `your_password` |
| `TELEGRAM_BOT_TOKEN` | Токен Telegram бота | `1234567890:ABC...` |
| `TELEGRAM_BOT_USERNAME` | Username бота | `your_bot_username` |

### Профили

- **test** (по умолчанию) - Тестовое окружение
- **prod** - Продакшн окружение

## 📊 Мониторинг

### REST API

```bash
# Управление стримами
POST /api/stream/trades/start          # Запуск стрима trades
POST /api/stream/trades/stop           # Остановка стрима trades
GET  /api/stream/trades/metrics        # Метрики стрима trades

POST /api/stream/minute-candles/start  # Запуск стрима свечей
POST /api/stream/last-price/start      # Запуск стрима цен
POST /api/stream/limits/start          # Запуск мониторинга лимитов

# Управление кэшем
POST /api/cache/warmup                 # Прогрев кэша
GET  /api/cache/stats                   # Статистика кэша

# Работа с инструментами
GET  /api/instruments/shares            # Все акции
GET  /api/instruments/search?q=SBER     # Поиск инструментов
GET  /api/instruments/limits/{figi}     # Лимиты инструмента

# Управление мониторингом лимитов
GET  /api/limit-monitor/thresholds      # Получить пороги мониторинга
POST /api/limit-monitor/thresholds/approach  # Обновить порог приближения
GET  /api/limit-monitor/statistics     # Статистика мониторинга
```

### Telegram Bot

```bash
/start   # Запуск бота
/help    # Список команд
/status  # Статус сервиса
```

## 🔧 Разработка

### Требования

- Java 21+
- Maven 3.9+
- PostgreSQL 15+
- Docker & Docker Compose (для контейнеризации)
- Telegram Bot Token
- Tinkoff Invest API Token

### Сборка

```bash
# Сборка проекта
mvn clean package

# Запуск тестов
mvn test

# Запуск с профилем
mvn spring-boot:run -Dspring-boot.run.profiles=test
```

## 📝 Логирование

```bash
# Основные логи
logs/current/investment-data-stream-service.log

# Логи Telegram бота
logs/current/telegram-bot.log

# Логи по окружениям
logs/test/current/
logs/prod/current/
```

## 🆘 Поддержка

При возникновении проблем:

1. Проверьте логи сервиса
2. Убедитесь в правильности конфигурации
3. Проверьте подключение к Tinkoff API
4. Обратитесь к [документации](docs/README.md)

## 📄 Лицензия

Проект разработан для внутреннего использования.

---

**Версия**: 2.1  
**Последнее обновление**: 2025-11-10

### 🔄 Последние обновления

- ✅ Новая модульная архитектура с независимыми стримами
- ✅ Отдельные контроллеры для каждого типа стрима
- ✅ Каждый стрим имеет свой процессор и таблицу в БД
- ✅ Добавлен API для управления настройками мониторинга лимитов (`/api/limit-monitor`)
- ✅ Обновлена документация API
