# Docker Guide для Investment Data Stream Service

## Обзор

Это руководство описывает, как собрать и запустить Investment Data Stream Service в Docker контейнерах.

## Требования

- Docker Engine 20.10+
- Docker Compose 2.0+
- Минимум 2GB свободной RAM
- Минимум 1GB свободного места на диске

## Быстрый старт

### 1. Подготовка переменных окружения

Создайте файл `.env` в корне проекта на основе примеров:

```bash
# Скопируйте пример для продакшна
cp env.prod.example .env

# Или для тестового окружения
cp env.test.example .env
```

Заполните необходимые переменные в `.env`:

```bash
# Tinkoff Invest API
T_INVEST_PROD_TOKEN=your-token-here

# Database
SPRING_DATASOURCE_PROD_PASSWORD=your-db-password
POSTGRES_PASSWORD=your-postgres-password

# Telegram Bot
TELEGRAM_BOT_TOKEN=your-bot-token
TELEGRAM_BOT_USERNAME=your-bot-username
TELEGRAM_LIMIT_CHANNEL_ID=your-channel-id
```

### 2. Сборка образа

```bash
# Сборка образа
docker build -t investment-data-stream-service:latest .

# Или используя docker-compose
docker-compose build
```

### 3. Запуск сервиса

#### Продакшн окружение

```bash
# Запуск с docker-compose (включает PostgreSQL)
docker-compose up -d

# Или только приложение (если БД уже запущена)
docker run -d \
  --name investment-data-stream-service \
  -p 8084:8084 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e T_INVEST_PROD_TOKEN=your-token \
  -e SPRING_DATASOURCE_PROD_PASSWORD=your-password \
  -e TELEGRAM_BOT_TOKEN=your-bot-token \
  -e TELEGRAM_BOT_USERNAME=your-bot-username \
  -v $(pwd)/logs:/app/logs \
  investment-data-stream-service:latest
```

#### Тестовое окружение

```bash
# Запуск тестового окружения
docker-compose -f docker-compose.test.yml up -d
```

### 4. Проверка работы

```bash
# Проверка статуса контейнера
docker ps

# Просмотр логов
docker logs -f investment-data-stream-service

# Проверка здоровья
curl http://localhost:8084/actuator/health

# Статистика сервиса
curl http://localhost:8084/api/streaming-service/stats
```

## Структура Dockerfile

Dockerfile использует multi-stage build для оптимизации размера образа:

1. **Build stage**: Использует Maven образ для сборки приложения
2. **Runtime stage**: Использует минимальный JRE образ Alpine Linux

### Особенности

- ✅ Минимальный размер образа (Alpine Linux)
- ✅ Непривилегированный пользователь для безопасности
- ✅ Health check для мониторинга
- ✅ Оптимизированные JVM настройки
- ✅ Персистентность логов через volumes

## Переменные окружения

### Обязательные

| Переменная | Описание | Пример |
|------------|----------|--------|
| `SPRING_PROFILES_ACTIVE` | Spring профиль | `prod` или `test` |
| `T_INVEST_PROD_TOKEN` | Токен Tinkoff API (продакшн) | `t.1234567890abcdef` |
| `T_INVEST_TEST_TOKEN` | Токен Tinkoff API (тест) | `t.1234567890abcdef` |
| `SPRING_DATASOURCE_PROD_PASSWORD` | Пароль БД (продакшн) | `your-password` |
| `SPRING_DATASOURCE_TEST_PASSWORD` | Пароль БД (тест) | `your-password` |
| `TELEGRAM_BOT_TOKEN` | Токен Telegram бота | `1234567890:ABC...` |
| `TELEGRAM_BOT_USERNAME` | Username бота | `your_bot_username` |

### Опциональные

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `TELEGRAM_LIMIT_CHANNEL_ID` | ID канала для уведомлений о лимитах | - |
| `LIMIT_MONITOR_APPROACH_THRESHOLD` | Порог приближения к лимиту | `0.01` (1%) |
| `JAVA_OPTS` | JVM опции | `-Xms512m -Xmx1024m -XX:+UseG1GC` |
| `SPRING_DATASOURCE_PROD_URL` | URL БД (продакшн) | `jdbc:postgresql://postgres:5432/...` |
| `SPRING_DATASOURCE_TEST_URL` | URL БД (тест) | `jdbc:postgresql://postgres:5432/...` |

## Управление контейнерами

### Остановка

```bash
# Остановка всех сервисов
docker-compose down

# Остановка с удалением volumes
docker-compose down -v
```

### Перезапуск

```bash
# Перезапуск сервиса
docker-compose restart investment-data-stream-service

# Или полный перезапуск
docker-compose down && docker-compose up -d
```

### Обновление

```bash
# Пересборка и перезапуск
docker-compose build --no-cache
docker-compose up -d
```

### Просмотр логов

```bash
# Все логи
docker-compose logs -f

# Только приложение
docker-compose logs -f investment-data-stream-service

# Последние 100 строк
docker-compose logs --tail=100 investment-data-stream-service
```

## Volumes

### Логи

Логи монтируются в директорию `./logs` на хосте:

```
./logs/
├── current/
│   ├── investment-data-stream-service.log
│   ├── errors.log
│   └── telegram-bot.log
└── archive/
    └── ...
```

### База данных

PostgreSQL данные сохраняются в Docker volume `postgres_data`:

```bash
# Просмотр volumes
docker volume ls

# Удаление volume (удалит все данные БД!)
docker volume rm investment-data-stream-service_postgres_data
```

## Оптимизация

### Настройка JVM для продакшна

Отредактируйте `JAVA_OPTS` в `docker-compose.yml`:

```yaml
environment:
  - JAVA_OPTS=-Xms1g -Xmx2g -XX:+UseG1GC -XX:MaxGCPauseMillis=200
```

### Ресурсы контейнера

Ограничьте ресурсы в `docker-compose.yml`:

```yaml
services:
  investment-data-stream-service:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

## Мониторинг

### Health Check

Docker автоматически проверяет здоровье контейнера:

```bash
# Статус health check
docker inspect --format='{{.State.Health.Status}}' investment-data-stream-service
```

### Метрики

Приложение предоставляет метрики через Actuator:

```bash
# Health endpoint
curl http://localhost:8084/actuator/health

# Metrics
curl http://localhost:8084/actuator/metrics
```

## Troubleshooting

### Контейнер не запускается

```bash
# Проверьте логи
docker logs investment-data-stream-service

# Проверьте переменные окружения
docker exec investment-data-stream-service env

# Проверьте конфигурацию
docker exec investment-data-stream-service cat /app/application.properties
```

### Проблемы с подключением к БД

```bash
# Проверьте доступность PostgreSQL
docker exec investment-postgres pg_isready

# Проверьте подключение из контейнера приложения
docker exec investment-data-stream-service ping postgres
```

### Высокое использование памяти

```bash
# Увеличьте лимиты памяти в docker-compose.yml
# Или уменьшите JAVA_OPTS
environment:
  - JAVA_OPTS=-Xms256m -Xmx512m
```

## Безопасность

### Рекомендации

1. ✅ Используйте secrets для паролей и токенов
2. ✅ Регулярно обновляйте базовые образы
3. ✅ Используйте non-root пользователя (уже настроено)
4. ✅ Ограничьте сетевой доступ
5. ✅ Не коммитьте `.env` файлы в Git

### Использование Docker Secrets

```yaml
services:
  investment-data-stream-service:
    secrets:
      - db_password
      - api_token

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_token:
    file: ./secrets/api_token.txt
```

## Примеры использования

### Разработка

```bash
# Запуск с hot-reload (требует настроить volume для source)
docker-compose -f docker-compose.dev.yml up
```

### Продакшн

```bash
# Сборка с тегами версий
docker build -t investment-data-stream-service:v0.0.1 .
docker tag investment-data-stream-service:v0.0.1 registry.example.com/investment-service:v0.0.1
docker push registry.example.com/investment-service:v0.0.1
```

## CI/CD интеграция

### GitHub Actions пример

```yaml
- name: Build Docker image
  run: docker build -t investment-service:${{ github.sha }} .

- name: Push to registry
  run: docker push registry.example.com/investment-service:${{ github.sha }}
```

## Дополнительные ресурсы

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Spring Boot Docker Guide](https://spring.io/guides/gs/spring-boot-docker/)

