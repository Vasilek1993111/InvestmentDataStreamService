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

```bash
# Сборка
mvn clean package -DskipTests

# Запуск (тестовое окружение)
java -jar target/investment-data-stream-service-1.0.0.jar

# Запуск (продакшн)
java -jar target/investment-data-stream-service-1.0.0.jar --spring.profiles.active=prod
```

### 3. Проверка работы

```bash
# Статистика сервиса
curl http://localhost:8084/api/streaming-service/stats

# Запуск потоков данных
curl -X POST http://localhost:8084/api/streaming-service/start

# Telegram бот
# Найдите вашего бота в Telegram и отправьте /start
```

## 📚 Документация

- **[Полная документация](docs/README.md)** - Подробное руководство
- **[API Reference](docs/API_REFERENCE.md)** - Описание REST API
- **[Telegram Bot](docs/TELEGRAM_BOT.md)** - Руководство по боту
- **[Архитектура](docs/ARCHITECTURE_DIAGRAM.md)** - Диаграммы системы
- **[Мониторинг](docs/MONITORING_GUIDE.md)** - Настройка мониторинга

## 🎯 Основные возможности

- **📡 Потоковые данные**: Сделки и свечи в реальном времени
- **🤖 Telegram Bot**: Мониторинг и уведомления
- **💾 Кэширование**: Быстрый доступ к инструментам
- **📊 Мониторинг**: Детальная статистика и метрики
- **🔧 Надежность**: Автоматическое восстановление

## 🏗️ Архитектура

```
Tinkoff API → Stream Service → PostgreSQL
                    ↓
              REST API + Telegram Bot
```

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
# Статистика сервиса
GET /api/streaming-service/stats

# Управление потоками
POST /api/streaming-service/start
POST /api/streaming-service/stop

# Статистика свечей
GET /api/candles/subscription/stats
```

### Telegram Bot

```bash
/start   # Запуск бота
/help    # Список команд
/status  # Статус сервиса
```

## 🔧 Разработка

### Требования

- Java 17+
- Maven 3.6+
- PostgreSQL 12+
- Telegram Bot Token

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

**Версия**: 1.1  
**Последнее обновление**: 2024-01-15
