# API кэширования инструментов

## Обзор

Система кэширования автоматически загружает все финансовые инструменты (акции, фьючерсы, индикативные инструменты) в память при запуске приложения и предоставляет REST API для управления кэшем.

## Типы кэшей

| Кэш | Описание | Содержимое |
|-----|----------|------------|
| `sharesCache` | Кэш акций | Все акции из таблицы shares |
| `futuresCache` | Кэш фьючерсов | Все фьючерсы из таблицы futures |
| `indicativesCache` | Кэш индикативных инструментов | Все индикативные инструменты из таблицы indicatives |

## Конфигурация кэша

Настройки кэша (по умолчанию):
- **Максимальный размер**: 10,000 записей на кэш
- **Время жизни после записи**: 24 часа
- **Время жизни после доступа**: 12 часов
- **Реализация**: Caffeine Cache

## API Endpoints

### 1. Прогрев кэша

Принудительно загружает все инструменты в кэш.

**Endpoint:** `POST /api/cache/warmup`

**Пример запроса:**
```bash
curl -X POST http://localhost:8080/api/cache/warmup
```

**Пример ответа:**
```json
{
  "success": true,
  "message": "Кэш успешно прогрет",
  "timestamp": "2024-10-21T10:30:00.123"
}
```

**Использование:**
- Принудительное обновление кэша без перезапуска
- Восстановление кэша после очистки
- Тестирование производительности

---

### 2. Просмотр содержимого кэша

Возвращает информацию о содержимом кэшей.

**Endpoint:** `GET /api/cache/content`

**Параметры запроса:**
- `cacheName` (опционально) - имя конкретного кэша
- `limit` (опционально, по умолчанию 100) - максимальное количество записей для отображения

**Примеры запросов:**

1. Просмотр всех кэшей:
```bash
curl http://localhost:8080/api/cache/content
```

2. Просмотр конкретного кэша:
```bash
curl http://localhost:8080/api/cache/content?cacheName=sharesCache
```

3. Ограничение количества записей:
```bash
curl http://localhost:8080/api/cache/content?cacheName=futuresCache&limit=50
```

**Пример ответа:**
```json
{
  "timestamp": "2024-10-21T10:30:00.123",
  "caches": {
    "sharesCache": {
      "name": "sharesCache",
      "nativeCache": "BoundedLocalCache",
      "entryCount": 1000,
      "sampleLimit": 100,
      "statistics": {
        "hitCount": 15000,
        "missCount": 100,
        "hitRate": 0.9934,
        "evictionCount": 0,
        "loadSuccessCount": 100,
        "loadFailureCount": 0
      },
      "sampleEntries": [
        {
          "key": "all",
          "valueType": "ArrayList",
          "valueSize": 1000
        }
      ]
    },
    "futuresCache": {
      "name": "futuresCache",
      "nativeCache": "BoundedLocalCache",
      "entryCount": 300,
      "sampleLimit": 100,
      "statistics": {
        "hitCount": 5000,
        "missCount": 50,
        "hitRate": 0.9901,
        "evictionCount": 0,
        "loadSuccessCount": 50,
        "loadFailureCount": 0
      },
      "sampleEntries": [
        {
          "key": "all",
          "valueType": "ArrayList",
          "valueSize": 300
        }
      ]
    },
    "indicativesCache": {
      "name": "indicativesCache",
      "nativeCache": "BoundedLocalCache",
      "entryCount": 200,
      "sampleLimit": 100,
      "statistics": {
        "hitCount": 3000,
        "missCount": 30,
        "hitRate": 0.9901,
        "evictionCount": 0,
        "loadSuccessCount": 30,
        "loadFailureCount": 0
      },
      "sampleEntries": [
        {
          "key": "all",
          "valueType": "ArrayList",
          "valueSize": 200
        }
      ]
    }
  }
}
```

---

### 3. Статистика кэша

Возвращает сводную статистику по всем кэшам.

**Endpoint:** `GET /api/cache/stats`

**Пример запроса:**
```bash
curl http://localhost:8080/api/cache/stats
```

**Пример ответа:**
```json
{
  "timestamp": "2024-10-21T10:30:00.123",
  "totalCaches": 3,
  "activeCaches": 3,
  "totalEntries": 1500,
  "cacheDetails": {
    "sharesCache": {
      "name": "sharesCache",
      "entryCount": 1000,
      "statistics": {
        "hitCount": 15000,
        "missCount": 100,
        "hitRate": 0.9934,
        "evictionCount": 0
      }
    },
    "futuresCache": {
      "name": "futuresCache",
      "entryCount": 300,
      "statistics": {
        "hitCount": 5000,
        "missCount": 50,
        "hitRate": 0.9901,
        "evictionCount": 0
      }
    },
    "indicativesCache": {
      "name": "indicativesCache",
      "entryCount": 200,
      "statistics": {
        "hitCount": 3000,
        "missCount": 30,
        "hitRate": 0.9901,
        "evictionCount": 0
      }
    }
  }
}
```

**Метрики:**
- `hitCount` - количество успешных обращений к кэшу
- `missCount` - количество промахов кэша
- `hitRate` - процент попаданий (hitCount / (hitCount + missCount))
- `evictionCount` - количество вытесненных записей
- `loadSuccessCount` - количество успешных загрузок из БД
- `loadFailureCount` - количество неудачных загрузок

---

### 4. Очистка кэша

Очищает содержимое одного или всех кэшей.

**Endpoint:** `DELETE /api/cache/clear`

**Параметры запроса:**
- `cacheName` (опционально) - имя кэша для очистки

**Примеры запросов:**

1. Очистить все кэши:
```bash
curl -X DELETE http://localhost:8080/api/cache/clear
```

2. Очистить конкретный кэш:
```bash
curl -X DELETE http://localhost:8080/api/cache/clear?cacheName=sharesCache
```

**Пример ответа (все кэши):**
```json
{
  "success": true,
  "message": "Все кэши успешно очищены",
  "timestamp": "2024-10-21T10:30:00.123",
  "clearedCaches": [
    "sharesCache",
    "futuresCache",
    "indicativesCache"
  ]
}
```

**Пример ответа (один кэш):**
```json
{
  "success": true,
  "message": "Кэш 'sharesCache' успешно очищен",
  "timestamp": "2024-10-21T10:30:00.123",
  "clearedCache": "sharesCache"
}
```

---

## Автоматический прогрев кэша

Кэш автоматически прогревается при запуске приложения:

1. Приложение стартует
2. `CacheWarmupService` инициализируется
3. Метод `@PostConstruct warmupCacheOnStartup()` автоматически вызывается
4. Загружаются все инструменты:
   - Акции
   - Фьючерсы
   - Индикативные инструменты
5. Данные сохраняются в соответствующих кэшах
6. В логах отображается информация о загрузке

**Пример логов при запуске:**
```
INFO  CacheWarmupService - Начинается автоматический прогрев кэша инструментов...
INFO  CacheWarmupService - Загружено 1000 акций в кэш
INFO  CacheWarmupService - Загружено 300 фьючерсов в кэш
INFO  CacheWarmupService - Загружено 200 индикативных инструментов в кэш
INFO  CacheWarmupService - Прогрев кэша завершен за 1234 мс. Всего инструментов: 1500
```

---

## Использование кэша в коде

### Получение данных из кэша

```java
@Service
public class MyService {
    
    @Autowired
    private CacheWarmupService cacheWarmupService;
    
    public List<ShareEntity> getShares() {
        // Данные берутся из кэша, если доступны
        // Иначе загружаются из БД и кэшируются
        return cacheWarmupService.getAllShares();
    }
    
    public List<FutureEntity> getFutures() {
        return cacheWarmupService.getAllFutures();
    }
    
    public List<IndicativeEntity> getIndicatives() {
        return cacheWarmupService.getAllIndicatives();
    }
}
```

### Очистка кэша программно

```java
@Service
public class MyService {
    
    @Autowired
    private CacheWarmupService cacheWarmupService;
    
    public void clearAllCaches() {
        cacheWarmupService.evictAllCaches();
    }
    
    public void clearSharesCache() {
        cacheWarmupService.evictSharesCache();
    }
    
    public void clearFuturesCache() {
        cacheWarmupService.evictFuturesCache();
    }
    
    public void clearIndicativesCache() {
        cacheWarmupService.evictIndicativesCache();
    }
}
```

---

## Мониторинг производительности

### Проверка эффективности кэша

1. Получить статистику:
```bash
curl http://localhost:8080/api/cache/stats
```

2. Обратить внимание на метрики:
   - **hitRate** должен быть > 0.95 (95%+) для хорошей производительности
   - **evictionCount** должен быть минимальным
   - **missCount** должен быть низким

3. Если hitRate низкий:
   - Увеличить время жизни кэша в `CacheConfig`
   - Увеличить максимальный размер кэша
   - Проверить логику очистки кэша

### Лучшие практики

1. **Не очищайте кэш без необходимости** - кэш прогревается автоматически при старте
2. **Мониторьте hitRate** - должен быть высоким (>95%)
3. **Используйте ручной прогрев** только при обновлении данных в БД
4. **Настройте размер кэша** в соответствии с объемом данных
5. **Логируйте операции** с кэшем для отладки

---

## Настройка конфигурации

Для изменения параметров кэша отредактируйте `CacheConfig.java`:

```java
@Bean
public CacheManager cacheManager() {
    CaffeineCacheManager cacheManager = new CaffeineCacheManager(
        "sharesCache", 
        "futuresCache", 
        "indicativesCache"
    );
    
    cacheManager.setCaffeine(Caffeine.newBuilder()
        .maximumSize(10_000)                    // Максимальный размер
        .expireAfterWrite(24, TimeUnit.HOURS)   // Время жизни после записи
        .expireAfterAccess(12, TimeUnit.HOURS)  // Время жизни после доступа
        .recordStats()                          // Запись статистики
    );
    
    return cacheManager;
}
```

---

## Troubleshooting

### Кэш не прогревается при старте

**Проблема:** Логи не показывают загрузку данных при старте.

**Решение:**
1. Проверьте, что `@EnableCaching` присутствует в `CacheConfig`
2. Убедитесь, что `CacheWarmupService` имеет аннотацию `@Service`
3. Проверьте подключение к БД

### Низкий hitRate

**Проблема:** hitRate < 0.90

**Решение:**
1. Увеличьте `expireAfterAccess` в `CacheConfig`
2. Увеличьте `maximumSize`
3. Проверьте, не очищается ли кэш слишком часто

### OutOfMemoryError

**Проблема:** Приложение падает с ошибкой памяти.

**Решение:**
1. Уменьшите `maximumSize` в `CacheConfig`
2. Уменьшите `expireAfterWrite` и `expireAfterAccess`
3. Увеличьте heap memory для JVM: `-Xmx2g`

---

## Ссылки

- [Caffeine Cache Documentation](https://github.com/ben-manes/caffeine)
- [Spring Cache Abstraction](https://docs.spring.io/spring-framework/docs/current/reference/html/integration.html#cache)
- [Мониторинг сервиса](MONITORING_GUIDE.md)

