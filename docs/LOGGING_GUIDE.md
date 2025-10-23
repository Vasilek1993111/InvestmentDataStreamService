# 📝 Руководство по логированию

## 🎯 Обзор системы логирования

Система логирования централизована в одном файле `logback-spring.xml` с условной логикой для разных окружений и архивной системой. Это обеспечивает:

- **Единую конфигурацию** для всех окружений
- **Автоматическое переключение** настроек в зависимости от профиля
- **Архивную систему** с папками `current` и `archive`
- **Автоматическую очистку** старых логов
- **Оптимизированную производительность** для каждого окружения

## 🏗️ Архитектура логирования

### Структура файлов логов с архивной системой

```
logs/
├── test/                                    # Тестовое окружение
│   ├── current/                             # Текущие логи
│   │   ├── investment-data-stream-service-test.log
│   │   └── errors-test.log
│   └── archive/                             # Архивные логи (7 дней)
│       ├── investment-data-stream-service-test.2024-01-15.0.log
│       └── errors-test.2024-01-15.0.log
├── prod/                                    # Продакшн окружение
│   ├── current/                             # Текущие логи
│   │   ├── investment-data-stream-service-prod.log
│   │   ├── errors-prod.log
│   │   └── metrics-prod.log
│   └── archive/                             # Архивные логи (30 дней)
│       ├── investment-data-stream-service-prod.2024-01-15.0.log
│       ├── errors-prod.2024-01-15.0.log
│       └── metrics-prod.2024-01-15.0.log
├── current/                                 # По умолчанию (dev)
│   ├── investment-data-stream-service.log
│   └── errors.log
└── archive/                                 # Архивные логи (15 дней)
    ├── investment-data-stream-service.2024-01-15.0.log
    └── errors.2024-01-15.0.log
```

### Типы логов

1. **Основные логи** - общая информация о работе приложения
2. **Логи ошибок** - только ERROR уровень
3. **Логи метрик** - только для продакшна, INFO уровень
4. **Консольные логи** - вывод в терминал

## ⚙️ Конфигурация по окружениям

### 🧪 TEST окружение

**Особенности:**
- **Детальное логирование** (DEBUG уровень)
- **Меньше ресурсов** (queueSize: 1024)
- **Короткое хранение** (7 дней)
- **Малые файлы** (50MB)

**Уровни логирования:**
```xml
com.example.investmentdatastreamservice: DEBUG
com.example.investmentdatastreamservice.service: DEBUG
com.example.investmentdatastreamservice.controller: DEBUG
org.springframework.web: DEBUG
org.hibernate.SQL: DEBUG
org.hibernate.type.descriptor.sql.BasicBinder: TRACE
```

**Файлы:**
- `logs/test/current/investment-data-stream-service-test.log` (текущий)
- `logs/test/current/errors-test.log` (текущий)
- `logs/test/archive/` (архивные, 7 дней)

### 🏭 PROD окружение

**Особенности:**
- **Минимальное логирование** (WARN уровень)
- **Больше ресурсов** (queueSize: 2048)
- **Долгое хранение** (30 дней)
- **Большие файлы** (500MB)

**Уровни логирования:**
```xml
com.example.investmentdatastreamservice: INFO
com.example.investmentdatastreamservice.service: INFO
com.example.investmentdatastreamservice.controller: WARN
org.springframework: WARN
org.hibernate.SQL: WARN
```

**Файлы:**
- `logs/prod/current/investment-data-stream-service-prod.log` (текущий)
- `logs/prod/current/errors-prod.log` (текущий)
- `logs/prod/current/metrics-prod.log` (текущий)
- `logs/prod/archive/` (архивные, 30 дней)

## 📊 Форматы логов

### Консольный вывод
```
2024-01-15 10:30:45.123 [http-nio-8084-exec-1] INFO  [TEST] c.e.i.s.MarketDataStreamingService - Processing trade data
```

### Файловый вывод
```
2024-01-15 10:30:45.123 [http-nio-8084-exec-1] INFO  [PROD] c.e.i.s.MarketDataStreamingService - Processing trade data
```

### Компоненты формата:
- `%d{yyyy-MM-dd HH:mm:ss.SSS}` - дата и время
- `[%thread]` - имя потока
- `%-5level` - уровень логирования
- `[%X{profile:-DEFAULT}]` - профиль окружения
- `%logger{36}` - имя логгера (максимум 36 символов)
- `%msg` - сообщение
- `%n` - перенос строки

## 🔧 Настройка логирования

### Изменение уровня логирования

Для изменения уровня логирования в runtime используйте JMX или Actuator:

```bash
# Через Actuator (только для test окружения)
curl -X POST http://localhost:8084/actuator/loggers/com.example.investmentdatastreamservice \
  -H "Content-Type: application/json" \
  -d '{"configuredLevel": "DEBUG"}'
```

### Программное изменение уровня

```java
// В коде приложения
Logger logger = LoggerFactory.getLogger(YourClass.class);
logger.setLevel(Level.DEBUG);
```

## 📁 Архивная система

### Автоматическое архивирование

- **Ротация по размеру**: файлы перемещаются в `archive/` при достижении лимита
- **Ротация по времени**: ежедневно в полночь
- **Автоматическая очистка**: файлы старше установленного периода удаляются
- **Формат архивных файлов**: `filename.YYYY-MM-DD.index.log`

### Настройки хранения

| Окружение | Текущие файлы | Архивные файлы | Период хранения | Размер файла |
|-----------|---------------|----------------|-----------------|--------------|
| TEST      | `current/`    | `archive/`     | 7 дней         | 50MB         |
| PROD      | `current/`    | `archive/`     | 30 дней        | 500MB        |
| Default   | `current/`    | `archive/`     | 15 дней        | 100MB        |

### Управление архивами

```bash
# Ручная очистка старых логов (старше 7 дней)
find logs -name "*.log" -type f -mtime +7 -delete

# Проверка размера архивов
du -sh logs/*/archive/

# Подсчет файлов в архивах
find logs -path "*/archive/*" -name "*.log" | wc -l
```

## 📈 Мониторинг логов

### Ключевые метрики для мониторинга

1. **Размер файлов логов**
   ```bash
   # Проверка размера логов
   du -sh logs/*/
   
   # Размер архивов
   du -sh logs/*/archive/
   ```

2. **Количество ошибок**
   ```bash
   # Подсчет ошибок в текущих файлах
   grep -c "ERROR" logs/*/current/errors-*.log
   
   # Подсчет ошибок в архивах
   grep -c "ERROR" logs/*/archive/errors-*.log
   ```

3. **Производительность логирования**
   ```bash
   # Проверка очереди асинхронных логов
   jstat -gc <pid>
   ```

### Алерты

**Критические:**
- Размер файла логов > 1GB
- Размер архива > 5GB
- Количество ошибок > 100/час
- Очередь асинхронных логов > 80%

**Предупреждения:**
- Размер файла логов > 500MB
- Размер архива > 2GB
- Количество ошибок > 50/час
- Очередь асинхронных логов > 60%

## 🚀 Производительность

### Асинхронное логирование

Все файловые логи используют асинхронные appenders для максимальной производительности:

```xml
<appender name="ASYNC_FILE" class="ch.qos.logback.classic.AsyncAppender">
    <appender-ref ref="FILE"/>
    <queueSize>2048</queueSize>  <!-- Размер очереди -->
    <discardingThreshold>0</discardingThreshold>  <!-- Не отбрасывать логи -->
    <includeCallerData>false</includeCallerData>  <!-- Не включать данные о вызове -->
</appender>
```

### Оптимизация для продакшна

- **Большая очередь** (2048 элементов)
- **Отключены данные о вызове** (includeCallerData=false)
- **Минимальный уровень** (WARN)
- **Ротация файлов** (500MB, 30 дней)

### Оптимизация для тестов

- **Меньшая очередь** (1024 элемента)
- **Включены данные о вызове** (includeCallerData=true)
- **Детальный уровень** (DEBUG)
- **Быстрая ротация** (50MB, 7 дней)

## 🔍 Диагностика проблем

### Проблема: Медленное логирование

**Симптомы:**
- Высокая загрузка CPU
- Медленная работа приложения
- Большие файлы логов

**Решения:**
1. Увеличить размер очереди асинхронных логов
2. Отключить данные о вызове (includeCallerData=false)
3. Повысить уровень логирования (DEBUG → INFO → WARN)

### Проблема: Переполнение диска

**Симптомы:**
- Ошибки записи в файлы
- Медленная работа системы
- Недостаток места на диске
- Большой размер папки `archive/`

**Решения:**
1. Уменьшить размер файлов логов
2. Сократить время хранения (maxHistory)
3. Включить очистку при старте (cleanHistoryOnStart=true)
4. Ручная очистка архивов: `find logs -path "*/archive/*" -mtime +7 -delete`

### Проблема: Потеря логов

**Симптомы:**
- Отсутствие важных сообщений
- Неполная информация об ошибках

**Решения:**
1. Проверить уровень логирования
2. Убедиться в правильности фильтров
3. Проверить права доступа к файлам

## 📋 Рекомендации

### Для разработки
- Используйте TEST профиль с DEBUG логированием
- Включите SQL логирование для отладки
- Мониторьте размер файлов логов

### Для продакшна
- Используйте PROD профиль с WARN логированием
- Настройте мониторинг размера логов и архивов
- Автоматическая очистка архивов через 30 дней
- Мониторинг размера папки `archive/`

### Для отладки
- Временно включите DEBUG уровень
- Используйте отдельные файлы для разных компонентов
- Настройте алерты на критические ошибки

## 🛠️ Настройка кастомных логгеров

### Добавление нового логгера

```xml
<logger name="com.example.custom" additivity="false">
    <springProfile name="test">
        <level value="DEBUG"/>
    </springProfile>
    <springProfile name="prod">
        <level value="INFO"/>
    </springProfile>
    
    <appender-ref ref="CONSOLE"/>
    <appender-ref ref="ASYNC_FILE"/>
    <appender-ref ref="ASYNC_ERROR"/>
</logger>
```

### Создание отдельного файла для компонента

```xml
<appender name="CUSTOM_FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>logs/custom-component.log</file>
    <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
        <fileNamePattern>logs/custom-component.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
        <maxFileSize>100MB</maxFileSize>
        <maxHistory>30</maxHistory>
    </rollingPolicy>
    <encoder>
        <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
</appender>
```

---

**Версия:** 1.0  
**Последнее обновление:** 2024-01-15  
**Автор:** Investment Data Stream Service Team
