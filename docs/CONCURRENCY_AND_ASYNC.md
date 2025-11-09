# Многопоточность и асинхронность в проекте

## 📋 Обзор

Проект `InvestmentDataStreamService` использует современные подходы к многопоточности и асинхронной обработке для обеспечения высокой производительности при работе с потоковыми данными от T-Invest API.

## 🏗️ Архитектура многопоточности

### Основные компоненты

1. **ExecutorService** - управление пулами потоков для параллельной обработки
2. **CompletableFuture** - асинхронное выполнение операций
3. **Semaphore** - контроль конкурентности и ограничение нагрузки
4. **Atomic типы** - thread-safe счетчики и флаги
5. **Volatile переменные** - гарантия видимости изменений между потоками

---

## 🔧 ExecutorService и пулы потоков

### 1. TradeProcessor

**Назначение**: Обработка обезличенных сделок (Trade)

**Конфигурация пула потоков**:
```java
private static final int INSERT_THREADS = Runtime.getRuntime().availableProcessors() * 6;
private final ExecutorService insertExecutor = Executors.newFixedThreadPool(INSERT_THREADS);
```

**Характеристики**:
- **Количество потоков**: `CPU cores * 6`
  - Для 8-ядерного процессора = 48 потоков
  - Оптимизировано для высокочастотных данных Trade
- **Тип пула**: FixedThreadPool (фиксированное количество потоков)
- **Daemon потоки**: Да (завершаются при остановке приложения)
- **Имена потоков**: `trade-insert-{timestamp}`

**Использование**:
```java
insertExecutor.submit(() -> {
    // Асинхронная вставка в БД
    streamJdbcTemplate.update(sql, params);
});
```

### 2. LastPriceProcessor

**Назначение**: Обработка цен последних сделок (LastPrice)

**Конфигурация пула потоков**:
```java
private static final int INSERT_THREADS = Runtime.getRuntime().availableProcessors() * 4;
private final ExecutorService insertExecutor = Executors.newFixedThreadPool(INSERT_THREADS);
```

**Характеристики**:
- **Количество потоков**: `CPU cores * 4`
  - Для 8-ядерного процессора = 32 потока
  - Меньше, чем Trade, так как LastPrice обновляется реже
- **Имена потоков**: `lastprice-insert-{timestamp}`

### 3. CandleStreamingService

**Назначение**: Обработка минутных свечей

**Конфигурация пула потоков**:
```java
private final ExecutorService insertExecutor = 
    Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors() * 4);
```

**Характеристики**:
- **Количество потоков**: `CPU cores * 4`
- Для обработки свечей (ниже частота, чем Trade)

### 4. GrpcConnectionManager

**Назначение**: Управление подключениями к gRPC API

**Конфигурация пулов**:
```java
// Планировщик для переподключений
private final ScheduledExecutorService reconnectScheduler = 
    Executors.newSingleThreadScheduledExecutor(r -> {
        Thread t = new Thread(r, "grpc-reconnect-scheduler");
        t.setDaemon(true);
        return t;
    });

// Пул для операций подключения
private final ExecutorService connectionExecutor = 
    Executors.newCachedThreadPool(r -> {
        Thread t = new Thread(r, "grpc-connection-worker");
        t.setDaemon(true);
        return t;
    });
```

**Характеристики**:
- **reconnectScheduler**: SingleThreadScheduledExecutor (1 поток для планирования)
- **connectionExecutor**: CachedThreadPool (динамический размер, переиспользует потоки)

---

## ⚡ CompletableFuture для асинхронности

### Основные сценарии использования

#### 1. Асинхронное выполнение операций

```java
@Override
public CompletableFuture<Void> start() {
    return CompletableFuture.runAsync(() -> {
        // Код выполняется асинхронно в ForkJoinPool
        if (isRunning.get()) {
            return;
        }
        // Логика запуска сервиса
    });
}
```

#### 2. Цепочка асинхронных операций

```java
// Подключение → Отправка запроса → Обработка результата
connectionManager.connect()
    .thenCompose(v -> connectionManager.sendRequest(marketDataRequest))
    .whenComplete((result, throwable) -> {
        if (throwable != null) {
            log.error("Failed to start", throwable);
            scheduleReconnect();
        } else {
            log.info("Started successfully");
        }
    });
```

#### 3. Параллельное выполнение нескольких операций

```java
// Запуск всех сервисов параллельно
public CompletableFuture<Void> startAllServices() {
    return CompletableFuture.allOf(
        lastPriceService.start().thenRun(() -> {
            metricsManager.incrementServicesStarted();
            log.info("LastPrice service started");
        }),
        tradeService.start().thenRun(() -> {
            metricsManager.incrementServicesStarted();
            log.info("Trade service started");
        }),
        limitMonitoringService.start().thenRun(() -> {
            metricsManager.incrementServicesStarted();
            log.info("Limit monitoring service started");
        })
    ).whenComplete((result, throwable) -> {
        if (throwable != null) {
            log.error("Error starting services", throwable);
        } else {
            log.info("All services started successfully");
        }
    });
}
```

#### 4. Асинхронная обработка данных

```java
// Обработка Trade данных
private void handleTradeData(Trade trade) {
    processor.process(trade)
        .whenComplete((result, throwable) -> {
            if (throwable != null) {
                processor.handleError(throwable);
            }
        });
}
```

---

## 🔒 Semaphore для контроля конкурентности

### Назначение

Semaphore ограничивает количество одновременных операций вставки в БД, предотвращая перегрузку пула соединений и обеспечивая стабильную работу.

### Реализация

#### LastPriceProcessor

```java
private static final int MAX_CONCURRENT_INSERTS = 100;
private final Semaphore insertSemaphore = new Semaphore(MAX_CONCURRENT_INSERTS);
```

**Характеристики**:
- **LastPrice**: 100 одновременных вставок
- **Candle**: 200 одновременных вставок

### Преимущества использования Semaphore

1. **Защита от перегрузки**: Ограничение нагрузки на БД
2. **Backpressure**: Автоматическое отбрасывание при перегрузке
3. **Мониторинг**: Доступные слоты видны в метриках
4. **Стабильность**: Предотвращение OutOfMemoryError

---

## 🧮 Atomic типы для thread-safety

### AtomicBoolean

**Использование**: Флаги состояния сервисов

```java
private final AtomicBoolean isRunning = new AtomicBoolean(false);

// Безопасная проверка и установка
if (isRunning.compareAndSet(false, true)) {
    // Запускаем сервис
}

// Безопасная проверка
if (isRunning.get()) {
    // Сервис работает
}
```

**Где используется**:
- `LastPriceStreamingService.isRunning`
- `MinuteCandleStreamingService.isRunning`
- `LimitMonitoringStreamingService.isRunning`
- `GrpcConnectionManager.isConnected`

### AtomicLong

**Использование**: Счетчики метрик

```java
private final AtomicLong totalReceived = new AtomicLong(0);
private final AtomicLong totalProcessed = new AtomicLong(0);
private final AtomicLong totalErrors = new AtomicLong(0);

// Инкремент без блокировок
totalReceived.incrementAndGet();
totalProcessed.addAndGet(100);
```

**Где используется**:
- `StreamingMetrics` - основные метрики
- `LastPriceProcessor` - счетчики по типам инструментов
- `CandleProcessor` - счетчики обработанных свечей
- `LimitMonitorService` - счетчики алертов и уведомлений

### AtomicReference

**Использование**: Thread-safe ссылки на объекты

```java
private final AtomicReference<StreamObserver<MarketDataRequest>> requestObserver = 
    new AtomicReference<>();

// Безопасная установка
requestObserver.set(newObserver);

// Безопасное получение и замена
StreamObserver<MarketDataRequest> old = requestObserver.getAndSet(newObserver);
```

**Где используется**:
- `GrpcConnectionManager.requestObserver`
- `GrpcConnectionManager.responseObserver`

---

## 🔄 Volatile переменные

### Назначение

Volatile обеспечивает видимость изменений переменной для всех потоков и предотвращает оптимизации компилятора.

### Использование

```java
// В GrpcConnectionManager
private volatile int currentReconnectDelay = INITIAL_RECONNECT_DELAY_MS;

// В CandleStreamingService
private volatile StreamObserver<MarketDataRequest> requestObserver;

// В TgBotService
private volatile boolean isInitialized = false;
```

**Применение**:
- Переменные, которые читаются и пишутся из разных потоков
- Флаги состояния, обновляемые редко, но читаемые часто
- Таймеры и задержки

---

## 🚀 Потоковая обработка данных

### Архитектура потока данных

```
T-Invest API (gRPC Stream)
    ↓
StreamObserver.onNext()
    ↓
StreamingService.handle{Data}()
    ↓
DataProcessor.process() → CompletableFuture
    ↓
ExecutorService.submit()
    ↓
Semaphore.tryAcquire()
    ↓
JdbcTemplate.update() (асинхронно)
    ↓
Semaphore.release()
```

### Пример обработки Trade

```java
// 1. Получение данных от API
@Override
public void onNext(MarketDataResponse response) {
    if (response.hasTrade()) {
        handleTradeData(response.getTrade());
    }
}

// 2. Обработка данных
private void handleTradeData(Trade trade) {
    processor.process(trade)
        .whenComplete((result, throwable) -> {
            if (throwable != null) {
                processor.handleError(throwable);
            }
        });
}

// 3. Асинхронная обработка в процессоре
@Override
public CompletableFuture<Void> process(Trade trade) {
    return CompletableFuture.runAsync(() -> {
        metrics.incrementReceived();
        TradeEntity entity = createTradeEntity(trade);
        insertTradeDataAsync(entity); // Неблокирующая вставка
        updateCounters(trade);
    });
}

// 4. Контролируемая вставка в БД
    if (!insertSemaphore.tryAcquire()) {
        metrics.incrementDropped();
        return; // Отбрасываем при перегрузке
    }
    
    insertExecutor.submit(() -> {
        try {
            streamJdbcTemplate.update(sql, params);
            metrics.incrementProcessed();
        } finally {
            insertSemaphore.release();
        }
    });
}
```

---

## 🎯 Координация сервисов

### MarketDataStreamingOrchestrator

**Назначение**: Координация всех потоковых сервисов

**Параллельный запуск**:
```java
public CompletableFuture<Void> startAllServices() {
    return CompletableFuture.allOf(
        lastPriceService.start(),
        tradeService.start(),
        limitMonitoringService.start()
    ).whenComplete((result, throwable) -> {
        if (throwable != null) {
            log.error("Error starting services", throwable);
        } else {
            log.info("All services started successfully");
        }
    });
}
```

**Последовательная остановка**:
```java
public CompletableFuture<Void> stopAllServices() {
    return CompletableFuture.allOf(
        lastPriceService.stop(),
        tradeService.stop(),
        limitMonitoringService.stop()
    );
}
```

**Graceful shutdown**:
```java
@PreDestroy
public void shutdown() {
    log.info("Shutting down...");
    try {
        stopAllServices().get(30, TimeUnit.SECONDS);
    } catch (Exception e) {
        log.error("Error during shutdown", e);
    }
}
```

---

## 📊 Метрики и мониторинг

### Thread-safe счетчики

Все метрики используют Atomic типы для безопасного обновления из разных потоков:

```java
public class StreamingMetrics {
    private final AtomicLong totalReceived = new AtomicLong(0);
    private final AtomicLong totalProcessed = new AtomicLong(0);
    private final AtomicLong totalErrors = new AtomicLong(0);
    private final AtomicLong totalDropped = new AtomicLong(0);
    private final AtomicBoolean isRunning = new AtomicBoolean(false);
    private final AtomicBoolean isConnected = new AtomicBoolean(false);
}
```

### Мониторинг конкурентности

```java
// Доступные слоты Semaphore
int availableInserts = insertSemaphore.availablePermits();
int maxConcurrentInserts = MAX_CONCURRENT_INSERTS;
double utilization = (double)(maxConcurrentInserts - availableInserts) / maxConcurrentInserts;
```

---

## ⚙️ Конфигурация производительности

### Расчет размеров пулов

```java
// Для высокочастотных данных (Trade)
int threads = Runtime.getRuntime().availableProcessors() * 6;

// Для среднечастотных данных (LastPrice, Candle)
int threads = Runtime.getRuntime().availableProcessors() * 4;
```

**Рекомендации**:
- **Trade**: `CPU cores * 6` (высокая частота данных)
- **LastPrice**: `CPU cores * 4` (средняя частота)
- **Candle**: `CPU cores * 4` (низкая частота)

### Ограничение конкурентности

```java
// Для Trade
private static final int MAX_CONCURRENT_INSERTS = 200;

// Для LastPrice
private static final int MAX_CONCURRENT_INSERTS = 100;
```

**Рекомендации**:
- Ограничение должно быть меньше размера пула соединений БД
- Учитывать производительность БД
- Мониторить dropped записи

---

## 🛡️ Защита от ошибок

### Обработка исключений

```java
processor.process(trade)
    .whenComplete((result, throwable) -> {
        if (throwable != null) {
            processor.handleError(throwable);
        }
    });
```

### Backpressure механизм

```java
if (!insertSemaphore.tryAcquire()) {
    metrics.incrementDropped();
    log.warn("Too many concurrent inserts, dropping Trade");
    return; // Отбрасываем запись вместо блокировки
}
```

### Graceful degradation

При перегрузке система:
1. Отбрасывает избыточные записи
2. Логирует предупреждения
3. Увеличивает счетчик dropped
4. Продолжает обработку оставшихся записей

---

## 🔍 Лучшие практики

### 1. Использование CompletableFuture

✅ **Правильно**:
```java
CompletableFuture.runAsync(() -> {
    // Асинхронная операция
}).whenComplete((result, throwable) -> {
    // Обработка результата или ошибки
});
```

❌ **Неправильно**:
```java
CompletableFuture.runAsync(() -> {
    // Асинхронная операция
}).join(); // Блокирует поток!
```

### 2. Управление ресурсами

✅ **Правильно**:
```java
@PreDestroy
public void shutdown() {
    insertExecutor.shutdown();
    try {
        if (!insertExecutor.awaitTermination(30, TimeUnit.SECONDS)) {
            insertExecutor.shutdownNow();
        }
    } catch (InterruptedException e) {
        insertExecutor.shutdownNow();
    }
}
```

### 3. Thread-safety

✅ **Использовать Atomic типы**:
```java
private final AtomicLong counter = new AtomicLong(0);
counter.incrementAndGet(); // Thread-safe
```

❌ **Избегать обычных типов**:
```java
private long counter = 0;
counter++; // НЕ thread-safe!
```

### 4. Контроль конкурентности

✅ **Использовать Semaphore**:
```java
if (!semaphore.tryAcquire()) {
    // Отбрасываем запись
    return;
}
try {
    // Выполняем операцию
} finally {
    semaphore.release();
}
```

---

## 📈 Производительность

### Ожидаемые характеристики

| Операция | Пропускная способность | Задержка |
|----------|----------------------|----------|
| Обработка Trade | 10,000+ сообщений/сек | < 1 мс |
| Обработка LastPrice | 5,000+ сообщений/сек | < 1 мс |
| Вставка в БД | 200 одновременных | 5-50 мс |
| Координация сервисов | Параллельно | < 100 мс |

### Оптимизации

1. **Неблокирующие операции**: Все вставки в БД асинхронные
2. **Параллельная обработка**: Несколько сервисов работают одновременно
3. **Контроль нагрузки**: Semaphore предотвращает перегрузку
4. **Эффективное использование ресурсов**: Динамические пулы потоков

---

## 🔧 Настройка под нагрузку

### Увеличение пропускной способности

1. **Увеличить размер пула потоков**:
```java
int threads = Runtime.getRuntime().availableProcessors() * 8; // было * 6
```

2. **Увеличить лимит Semaphore**:
```java
private static final int MAX_CONCURRENT_INSERTS = 300; // было 200
```

3. **Увеличить пул соединений БД**:
```properties
spring.datasource.stream.hikari.maximum-pool-size=100
```

### Мониторинг

- **Следить за dropped записями**: Высокое значение = нужна оптимизация
- **Мониторить утилизацию Semaphore**: Должна быть < 90%
- **Проверять размер пула потоков**: Не должен быть перегружен
- **Отслеживать ошибки БД**: Могут указывать на перегрузку

---

## 📚 Дополнительные ресурсы

- [Java Concurrency in Practice](https://www.amazon.com/Java-Concurrency-Practice-Brian-Goetz/dp/0321349601)
- [CompletableFuture Documentation](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/CompletableFuture.html)
- [ExecutorService Guide](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ExecutorService.html)
- [Semaphore Documentation](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/Semaphore.html)

---

**Версия документа**: 1.0  
**Последнее обновление**: 2024-01-27  
**Автор**: Investment Data Stream Service Team

