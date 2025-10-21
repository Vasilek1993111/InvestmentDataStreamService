# Примеры использования кэша инструментов

## 📋 Оглавление

1. [Базовое использование](#базовое-использование)
2. [Использование в сервисах](#использование-в-сервисах)
3. [REST API примеры](#rest-api-примеры)
4. [Интеграция с другими компонентами](#интеграция-с-другими-компонентами)
5. [Продвинутые сценарии](#продвинутые-сценарии)

---

## Базовое использование

### Получение всех акций из кэша

```java
@Service
public class InstrumentService {
    
    @Autowired
    private CacheWarmupService cacheWarmupService;
    
    public List<ShareEntity> getShares() {
        // Данные берутся из кэша (очень быстро!)
        return cacheWarmupService.getAllShares();
    }
}
```

### Получение всех фьючерсов

```java
@Service
public class FutureService {
    
    @Autowired
    private CacheWarmupService cacheWarmupService;
    
    public List<FutureEntity> getFutures() {
        return cacheWarmupService.getAllFutures();
    }
    
    public List<String> getFutureTickers() {
        return cacheWarmupService.getAllFutures()
            .stream()
            .map(FutureEntity::getTicker)
            .collect(Collectors.toList());
    }
}
```

### Фильтрация инструментов

```java
@Service
public class InstrumentFilterService {
    
    @Autowired
    private CacheWarmupService cacheWarmupService;
    
    public List<ShareEntity> getSharesByExchange(String exchange) {
        return cacheWarmupService.getAllShares()
            .stream()
            .filter(share -> share.getExchange().equals(exchange))
            .collect(Collectors.toList());
    }
    
    public List<ShareEntity> getMoexShares() {
        return getSharesByExchange("MOEX");
    }
    
    public List<FutureEntity> getFuturesByAssetType(String assetType) {
        return cacheWarmupService.getAllFutures()
            .stream()
            .filter(future -> future.getAssetType().equals(assetType))
            .collect(Collectors.toList());
    }
}
```

---

## Использование в сервисах

### Валидация инструментов

```java
@Service
public class InstrumentValidationService {
    
    @Autowired
    private CacheWarmupService cacheWarmupService;
    
    /**
     * Проверяет, существует ли акция с данным FIGI
     */
    public boolean isValidShareFigi(String figi) {
        return cacheWarmupService.getAllShares()
            .stream()
            .anyMatch(share -> share.getFigi().equals(figi));
    }
    
    /**
     * Проверяет, существует ли фьючерс с данным тикером
     */
    public boolean isValidFutureTicker(String ticker) {
        return cacheWarmupService.getAllFutures()
            .stream()
            .anyMatch(future -> future.getTicker().equals(ticker));
    }
    
    /**
     * Получает инструмент по FIGI из кэша
     */
    public Optional<ShareEntity> getShareByFigi(String figi) {
        return cacheWarmupService.getAllShares()
            .stream()
            .filter(share -> share.getFigi().equals(figi))
            .findFirst();
    }
}
```

### Обогащение данных из кэша

```java
@Service
public class TradeEnrichmentService {
    
    @Autowired
    private CacheWarmupService cacheWarmupService;
    
    /**
     * Обогащает сделку информацией об инструменте
     */
    public EnrichedTrade enrichTrade(TradeEntity trade) {
        // Быстрый поиск в кэше вместо запроса к БД
        Optional<ShareEntity> share = cacheWarmupService.getAllShares()
            .stream()
            .filter(s -> s.getFigi().equals(trade.getFigi()))
            .findFirst();
        
        return EnrichedTrade.builder()
            .trade(trade)
            .instrumentName(share.map(ShareEntity::getName).orElse("Unknown"))
            .ticker(share.map(ShareEntity::getTicker).orElse("Unknown"))
            .exchange(share.map(ShareEntity::getExchange).orElse("Unknown"))
            .build();
    }
}
```

### Группировка инструментов

```java
@Service
public class InstrumentGroupingService {
    
    @Autowired
    private CacheWarmupService cacheWarmupService;
    
    /**
     * Группирует акции по биржам
     */
    public Map<String, List<ShareEntity>> groupSharesByExchange() {
        return cacheWarmupService.getAllShares()
            .stream()
            .collect(Collectors.groupingBy(ShareEntity::getExchange));
    }
    
    /**
     * Группирует фьючерсы по типу актива
     */
    public Map<String, List<FutureEntity>> groupFuturesByAssetType() {
        return cacheWarmupService.getAllFutures()
            .stream()
            .collect(Collectors.groupingBy(FutureEntity::getAssetType));
    }
    
    /**
     * Подсчитывает количество инструментов по биржам
     */
    public Map<String, Long> countInstrumentsByExchange() {
        Map<String, Long> result = new HashMap<>();
        
        // Акции
        cacheWarmupService.getAllShares()
            .stream()
            .collect(Collectors.groupingBy(ShareEntity::getExchange, Collectors.counting()))
            .forEach((exchange, count) -> 
                result.merge(exchange, count, Long::sum));
        
        // Фьючерсы
        cacheWarmupService.getAllFutures()
            .stream()
            .collect(Collectors.groupingBy(FutureEntity::getExchange, Collectors.counting()))
            .forEach((exchange, count) -> 
                result.merge(exchange, count, Long::sum));
        
        return result;
    }
}
```

---

## REST API примеры

### Curl примеры

```bash
# Получить статистику кэша
curl http://localhost:8080/api/cache/stats | jq

# Получить содержимое кэша акций
curl "http://localhost:8080/api/cache/content?cacheName=sharesCache" | jq

# Получить содержимое всех кэшей с ограничением в 50 записей
curl "http://localhost:8080/api/cache/content?limit=50" | jq

# Прогреть кэш вручную
curl -X POST http://localhost:8080/api/cache/warmup | jq

# Очистить кэш акций
curl -X DELETE "http://localhost:8080/api/cache/clear?cacheName=sharesCache" | jq

# Очистить все кэши
curl -X DELETE http://localhost:8080/api/cache/clear | jq
```

### Python примеры

```python
import requests
import json

BASE_URL = "http://localhost:8080/api/cache"

# Получить статистику
def get_cache_stats():
    response = requests.get(f"{BASE_URL}/stats")
    return response.json()

# Получить содержимое кэша
def get_cache_content(cache_name=None, limit=100):
    params = {}
    if cache_name:
        params['cacheName'] = cache_name
    params['limit'] = limit
    
    response = requests.get(f"{BASE_URL}/content", params=params)
    return response.json()

# Прогреть кэш
def warmup_cache():
    response = requests.post(f"{BASE_URL}/warmup")
    return response.json()

# Очистить кэш
def clear_cache(cache_name=None):
    params = {}
    if cache_name:
        params['cacheName'] = cache_name
    
    response = requests.delete(f"{BASE_URL}/clear", params=params)
    return response.json()

# Использование
if __name__ == "__main__":
    # Получить статистику
    stats = get_cache_stats()
    print(f"Всего инструментов в кэше: {stats['totalEntries']}")
    
    # Получить содержимое кэша акций
    shares_cache = get_cache_content('sharesCache')
    print(f"Акций в кэше: {shares_cache['entryCount']}")
    
    # Прогреть кэш
    result = warmup_cache()
    print(f"Результат прогрева: {result['message']}")
```

### JavaScript/Node.js примеры

```javascript
const axios = require('axios');

const BASE_URL = 'http://localhost:8080/api/cache';

// Получить статистику
async function getCacheStats() {
    const response = await axios.get(`${BASE_URL}/stats`);
    return response.data;
}

// Получить содержимое кэша
async function getCacheContent(cacheName = null, limit = 100) {
    const params = { limit };
    if (cacheName) {
        params.cacheName = cacheName;
    }
    
    const response = await axios.get(`${BASE_URL}/content`, { params });
    return response.data;
}

// Прогреть кэш
async function warmupCache() {
    const response = await axios.post(`${BASE_URL}/warmup`);
    return response.data;
}

// Очистить кэш
async function clearCache(cacheName = null) {
    const params = cacheName ? { cacheName } : {};
    const response = await axios.delete(`${BASE_URL}/clear`, { params });
    return response.data;
}

// Использование
(async () => {
    try {
        // Получить статистику
        const stats = await getCacheStats();
        console.log(`Всего инструментов в кэше: ${stats.totalEntries}`);
        
        // Получить содержимое кэша акций
        const sharesCache = await getCacheContent('sharesCache');
        console.log(`Акций в кэше: ${sharesCache.entryCount}`);
        
        // Прогреть кэш
        const result = await warmupCache();
        console.log(`Результат прогрева: ${result.message}`);
    } catch (error) {
        console.error('Ошибка:', error.message);
    }
})();
```

---

## Интеграция с другими компонентами

### Использование в контроллерах

```java
@RestController
@RequestMapping("/api/instruments")
public class InstrumentController {
    
    @Autowired
    private CacheWarmupService cacheWarmupService;
    
    @GetMapping("/shares")
    public ResponseEntity<List<ShareEntity>> getAllShares() {
        List<ShareEntity> shares = cacheWarmupService.getAllShares();
        return ResponseEntity.ok(shares);
    }
    
    @GetMapping("/shares/{figi}")
    public ResponseEntity<ShareEntity> getShareByFigi(@PathVariable String figi) {
        Optional<ShareEntity> share = cacheWarmupService.getAllShares()
            .stream()
            .filter(s -> s.getFigi().equals(figi))
            .findFirst();
        
        return share
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/futures/by-asset-type/{assetType}")
    public ResponseEntity<List<FutureEntity>> getFuturesByAssetType(
            @PathVariable String assetType) {
        List<FutureEntity> futures = cacheWarmupService.getAllFutures()
            .stream()
            .filter(f -> f.getAssetType().equals(assetType))
            .collect(Collectors.toList());
        
        return ResponseEntity.ok(futures);
    }
}
```

### Использование в scheduled задачах

```java
@Component
public class CacheMaintenanceScheduler {
    
    @Autowired
    private CacheWarmupService cacheWarmupService;
    
    @Autowired
    private CacheManager cacheManager;
    
    private static final Logger logger = LoggerFactory.getLogger(CacheMaintenanceScheduler.class);
    
    /**
     * Автоматическое обновление кэша каждые 24 часа
     */
    @Scheduled(cron = "0 0 2 * * ?") // Каждый день в 2:00
    public void refreshCache() {
        logger.info("Запуск автоматического обновления кэша...");
        try {
            cacheWarmupService.manualWarmupCache();
            logger.info("Кэш успешно обновлен");
        } catch (Exception e) {
            logger.error("Ошибка при обновлении кэша: {}", e.getMessage(), e);
        }
    }
    
    /**
     * Проверка здоровья кэша каждые 5 минут
     */
    @Scheduled(fixedRate = 300000) // Каждые 5 минут
    public void checkCacheHealth() {
        String[] cacheNames = {"sharesCache", "futuresCache", "indicativesCache"};
        
        for (String cacheName : cacheNames) {
            Cache cache = cacheManager.getCache(cacheName);
            if (cache != null && cache.getNativeCache() instanceof 
                    com.github.benmanes.caffeine.cache.Cache) {
                
                com.github.benmanes.caffeine.cache.Cache<?, ?> caffeineCache = 
                    (com.github.benmanes.caffeine.cache.Cache<?, ?>) cache.getNativeCache();
                
                long size = caffeineCache.estimatedSize();
                
                if (size == 0) {
                    logger.warn("Кэш {} пуст! Запуск прогрева...", cacheName);
                    try {
                        cacheWarmupService.manualWarmupCache();
                    } catch (Exception e) {
                        logger.error("Ошибка при прогреве кэша: {}", e.getMessage(), e);
                    }
                }
            }
        }
    }
}
```

---

## Продвинутые сценарии

### Поиск с автодополнением

```java
@Service
public class InstrumentSearchService {
    
    @Autowired
    private CacheWarmupService cacheWarmupService;
    
    /**
     * Поиск акций по частичному совпадению тикера или названия
     */
    public List<ShareEntity> searchShares(String query) {
        String lowerQuery = query.toLowerCase();
        
        return cacheWarmupService.getAllShares()
            .stream()
            .filter(share -> 
                share.getTicker().toLowerCase().contains(lowerQuery) ||
                share.getName().toLowerCase().contains(lowerQuery))
            .limit(10)
            .collect(Collectors.toList());
    }
    
    /**
     * Автодополнение для тикеров
     */
    public List<String> autocompleteTickers(String prefix) {
        String lowerPrefix = prefix.toLowerCase();
        
        List<String> allTickers = new ArrayList<>();
        
        // Акции
        cacheWarmupService.getAllShares()
            .stream()
            .map(ShareEntity::getTicker)
            .filter(ticker -> ticker.toLowerCase().startsWith(lowerPrefix))
            .forEach(allTickers::add);
        
        // Фьючерсы
        cacheWarmupService.getAllFutures()
            .stream()
            .map(FutureEntity::getTicker)
            .filter(ticker -> ticker.toLowerCase().startsWith(lowerPrefix))
            .forEach(allTickers::add);
        
        return allTickers.stream()
            .sorted()
            .limit(20)
            .collect(Collectors.toList());
    }
}
```

### Сравнение производительности

```java
@Service
public class PerformanceComparisonService {
    
    @Autowired
    private CacheWarmupService cacheWarmupService;
    
    @Autowired
    private ShareRepository shareRepository;
    
    /**
     * Сравнивает скорость получения данных из кэша и БД
     */
    public Map<String, Long> comparePerformance(int iterations) {
        Map<String, Long> results = new HashMap<>();
        
        // Тест кэша
        long cacheStart = System.currentTimeMillis();
        for (int i = 0; i < iterations; i++) {
            cacheWarmupService.getAllShares();
        }
        long cacheDuration = System.currentTimeMillis() - cacheStart;
        results.put("cache_ms", cacheDuration);
        results.put("cache_avg_ms", cacheDuration / iterations);
        
        // Тест БД
        long dbStart = System.currentTimeMillis();
        for (int i = 0; i < iterations; i++) {
            shareRepository.findAll();
        }
        long dbDuration = System.currentTimeMillis() - dbStart;
        results.put("db_ms", dbDuration);
        results.put("db_avg_ms", dbDuration / iterations);
        
        // Ускорение
        results.put("speedup", dbDuration / cacheDuration);
        
        return results;
    }
}
```

### Экспорт инструментов в различные форматы

```java
@Service
public class InstrumentExportService {
    
    @Autowired
    private CacheWarmupService cacheWarmupService;
    
    /**
     * Экспорт акций в CSV
     */
    public String exportSharesToCsv() {
        StringBuilder csv = new StringBuilder();
        csv.append("FIGI,Ticker,Name,Currency,Exchange\n");
        
        cacheWarmupService.getAllShares().forEach(share -> {
            csv.append(String.format("%s,%s,%s,%s,%s\n",
                share.getFigi(),
                share.getTicker(),
                share.getName(),
                share.getCurrency(),
                share.getExchange()));
        });
        
        return csv.toString();
    }
    
    /**
     * Экспорт в JSON
     */
    public String exportToJson() throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        
        Map<String, Object> data = new HashMap<>();
        data.put("shares", cacheWarmupService.getAllShares());
        data.put("futures", cacheWarmupService.getAllFutures());
        data.put("indicatives", cacheWarmupService.getAllIndicatives());
        data.put("exportDate", LocalDateTime.now());
        
        return mapper.writerWithDefaultPrettyPrinter().writeValueAsString(data);
    }
}
```

---

## Мониторинг и метрики

### Сбор метрик кэша

```java
@Service
public class CacheMetricsService {
    
    @Autowired
    private CacheManager cacheManager;
    
    /**
     * Собирает детальные метрики по всем кэшам
     */
    public Map<String, CacheMetrics> collectMetrics() {
        Map<String, CacheMetrics> metrics = new HashMap<>();
        String[] cacheNames = {"sharesCache", "futuresCache", "indicativesCache"};
        
        for (String cacheName : cacheNames) {
            Cache cache = cacheManager.getCache(cacheName);
            if (cache != null && cache.getNativeCache() instanceof 
                    com.github.benmanes.caffeine.cache.Cache) {
                
                com.github.benmanes.caffeine.cache.Cache<?, ?> caffeineCache = 
                    (com.github.benmanes.caffeine.cache.Cache<?, ?>) cache.getNativeCache();
                
                com.github.benmanes.caffeine.cache.stats.CacheStats stats = 
                    caffeineCache.stats();
                
                metrics.put(cacheName, CacheMetrics.builder()
                    .size(caffeineCache.estimatedSize())
                    .hitCount(stats.hitCount())
                    .missCount(stats.missCount())
                    .hitRate(stats.hitRate())
                    .evictionCount(stats.evictionCount())
                    .build());
            }
        }
        
        return metrics;
    }
    
    @Data
    @Builder
    public static class CacheMetrics {
        private long size;
        private long hitCount;
        private long missCount;
        private double hitRate;
        private long evictionCount;
    }
}
```

---

## Заключение

Эти примеры демонстрируют различные способы использования системы кэширования в реальных сценариях. Кэш значительно ускоряет доступ к данным и снижает нагрузку на базу данных.

Для получения дополнительной информации см.:
- [Полное API Reference](CACHE_API.md)
- [Быстрый старт](CACHE_QUICK_START.md)

