# 📁 Структура логов Investment Data Stream Service

## 🏗️ Полная структура директорий

```
logs/
├── current/                                    # DEFAULT (dev) - текущие логи
│   ├── investment-data-stream-service.log     # Основные логи
│   └── errors.log                             # Только ошибки
├── archive/                                    # DEFAULT (dev) - архивные логи (15 дней)
│   ├── investment-data-stream-service.2024-01-15.0.log
│   └── errors.2024-01-15.0.log
├── test/                                       # TEST окружение
│   ├── current/                                # Текущие логи
│   │   ├── investment-data-stream-service-test.log
│   │   └── errors-test.log
│   └── archive/                                # Архивные логи (7 дней)
│       ├── investment-data-stream-service-test.2024-01-15.0.log
│       └── errors-test.2024-01-15.0.log
└── prod/                                       # PROD окружение
    ├── current/                                # Текущие логи
    │   ├── investment-data-stream-service-prod.log
    │   ├── errors-prod.log
    │   └── metrics-prod.log
    └── archive/                                # Архивные логи (30 дней)
        ├── investment-data-stream-service-prod.2024-01-15.0.log
        ├── errors-prod.2024-01-15.0.log
        └── metrics-prod.2024-01-15.0.log
```

## 📊 Настройки по окружениям

| Окружение | Текущие файлы | Архивные файлы | Период хранения | Размер файла | Очередь |
|-----------|---------------|----------------|-----------------|--------------|---------|
| **DEFAULT** | `current/` | `archive/` | 15 дней | 100MB | 1024 |
| **TEST** | `test/current/` | `test/archive/` | 7 дней | 50MB | 1024 |
| **PROD** | `prod/current/` | `prod/archive/` | 30 дней | 500MB | 2048 |

## 🎯 Типы логов

### DEFAULT (dev)
- **Основные логи**: `logs/current/investment-data-stream-service.log`
- **Ошибки**: `logs/current/errors.log`
- **Архив**: `logs/archive/` (15 дней)

### TEST
- **Основные логи**: `logs/test/current/investment-data-stream-service-test.log`
- **Ошибки**: `logs/test/current/errors-test.log`
- **Архив**: `logs/test/archive/` (7 дней)

### PROD
- **Основные логи**: `logs/prod/current/investment-data-stream-service-prod.log`
- **Ошибки**: `logs/prod/current/errors-prod.log`
- **Метрики**: `logs/prod/current/metrics-prod.log`
- **Архив**: `logs/prod/archive/` (30 дней)

## 🔧 Конфигурация

**Файл конфигурации**: `src/main/resources/logback-spring.xml`

**Ключевые особенности**:
- ✅ Уникальные appenders для каждого профиля
- ✅ Асинхронное логирование для производительности
- ✅ Автоматическая ротация файлов
- ✅ Фильтрация по уровням логирования
- ✅ Поддержка всех окружений

## 📈 Мониторинг

### Проверка структуры
```bash
# Просмотр структуры логов
tree logs/

# Размер директорий
du -sh logs/*/

# Количество файлов в архивах
find logs -path "*/archive/*" -name "*.log" | wc -l
```

### Очистка архивов
```bash
# Очистка архивов старше 7 дней
find logs -path "*/archive/*" -name "*.log" -mtime +7 -delete

# Очистка архивов старше 30 дней (только для prod)
find logs/prod/archive -name "*.log" -mtime +30 -delete
```

---
**Версия**: 1.1  
**Обновлено**: 2025-10-24  
**Статус**: ✅ Все директории созданы, конфигурация исправлена
