# Архитектура Множественных Stream-Соединений

## Обзор

Сервис поддерживает множественные gRPC stream-соединения для обхода API лимита в 300 подписок на один stream. Это позволяет подписываться на неограниченное количество инструментов, автоматически разделяя их на батчи.

## API Ограничения

### Лимиты T-Invest API

1. **Лимит подписок на stream**: 300 одновременных подписок на свечи, стаканы и ленту обезличенных сделок (считается суммарно)
2. **Rate limit**: Максимум 100 запросов подписки в минуту
3. **Подписки Info**: Нет лимитов на торговые статусы инструментов

## Компоненты Архитектуры

### 1. SubscriptionBatcher

**Местоположение**: `com.example.investmentdatastreamservice.service.streaming.SubscriptionBatcher`

**Назначение**: Разделение инструментов на батчи для подписки

**Параметры**:
- `DEFAULT_BATCH_SIZE`: 250 инструментов (безопасный размер меньше лимита)
- `MAX_REQUESTS_PER_MINUTE`: 100 запросов
- `BATCH_DELAY_MS`: 1000 мс (1 секунда между батчами)

**Пример использования**:
```java
SubscriptionBatcher batcher = new SubscriptionBatcher();
List<List<String>> batches = batcher.createBatches(instruments);
// Результат: [250 инструментов], [250 инструментов], [75 инструментов]
```

### 2. MultiStreamManager

**Местоположение**: `com.example.investmentdatastreamservice.service.streaming.MultiStreamManager`

**Назначение**: Управление множественными gRPC соединениями

**Функционал**:
- Создание отдельного channel и stub для каждого батча
- Управление lifecycle всех stream'ов
- Общий response observer для всех соединений
- Автоматическое переподключение при сбоях

**Архитектура**:
```
MultiStreamManager
├── GrpcConnectionManager #1 (Batch 1: инструменты 1-250)
│   ├── ManagedChannel #1
│   └── MarketDataStreamServiceStub #1
├── GrpcConnectionManager #2 (Batch 2: инструменты 251-500)
│   ├── ManagedChannel #2
│   └── MarketDataStreamServiceStub #2
└── GrpcConnectionManager #3 (Batch 3: инструменты 501-575)
    ├── ManagedChannel #3
    └── MarketDataStreamServiceStub #3
```

**Методы**:
- `createStreamForBatch(int batchIndex)` - создает новый stream для батча
- `connectAll()` - подключает все stream'ы параллельно
- `sendBatchSubscription(int batchIndex, MarketDataRequest request, long delayMs)` - отправляет подписку с задержкой
- `disconnectAll()` - отключает все stream'ы
- `forceReconnectAll()` - переподключает все stream'ы

### 3. LastPriceStreamingService (обновленный)

**Обновления**:
- Использует `MultiStreamManager` вместо одного `GrpcConnectionManager`
- Автоматически разделяет инструменты на батчи через `SubscriptionBatcher`
- Соблюдает rate limiting между запросами подписки
- Подсчитывает успешные и неуспешные подписки

## Процесс Подписки

### Шаг 1: Загрузка Инструментов
```java
List<String> instruments = getAllInstruments(); // Например, 575 инструментов
```

### Шаг 2: Создание Батчей
```java
List<List<String>> batches = batcher.createBatches(instruments);
// Результат: 3 батча по 250, 250, 75 инструментов
```

### Шаг 3: Создание Stream-Соединений
```java
MultiStreamManager multiStreamManager = new MultiStreamManager(apiToken, 3);
for (int i = 0; i < 3; i++) {
    multiStreamManager.createStreamForBatch(i);
}
```

### Шаг 4: Подключение
```java
multiStreamManager.connectAll()
    .thenCompose(v -> subscribeAllBatches(batches))
```

### Шаг 5: Подписка с Rate Limiting
```java
// Batch 1: delay = 0ms
// Batch 2: delay = 1000ms
// Batch 3: delay = 2000ms

for (int i = 0; i < batches.size(); i++) {
    long delayMs = i * SubscriptionBatcher.BATCH_DELAY_MS;
    multiStreamManager.sendBatchSubscription(i, request, delayMs);
}
```

## Логи Работы Сервиса

### Успешный Запуск

```
🚀 Starting LastPrice streaming service with multi-stream support...
📊 Found 575 instruments for LastPrice subscription
📦 Created 3 batches: BatchInfo[total=575, batches=3, size=250]
🔗 Each batch will use separate gRPC stream connection

Created stream connection #1 (total connections: 1)
Created stream connection #2 (total connections: 2)
Created stream connection #3 (total connections: 3)

Stream connection #1 established (1/3)
Stream connection #2 established (2/3)
Stream connection #3 established (3/3)
✅ All stream connections established

📡 Starting batch subscriptions with rate limiting...
📤 Preparing batch 1/3: 250 instruments (delay: 0ms)
📤 Preparing batch 2/3: 250 instruments (delay: 1000ms)
📤 Preparing batch 3/3: 75 instruments (delay: 2000ms)

Subscribing batch 1/3 (250 instruments)
✅ Batch 1/3 subscription request sent

Waiting 1000ms before subscribing batch 2/3 (rate limiting)...
Subscribing batch 2/3 (250 instruments)
✅ Batch 2/3 subscription request sent

Waiting 2000ms before subscribing batch 3/3 (rate limiting)...
Subscribing batch 3/3 (75 instruments)
✅ Batch 3/3 subscription request sent

✅ All batch subscription requests completed

=== LASTPRICE SUBSCRIPTION RESPONSE ===
Total subscriptions in response: 250
  FIGI BBG004730RP0 -> SUBSCRIPTION_STATUS_SUCCESS
  ... (250 успешных подписок)
Batch result: 250 successful, 0 failed
Total result: 250 successful, 0 failed
=====================================

=== LASTPRICE SUBSCRIPTION RESPONSE ===
Total subscriptions in response: 250
  FIGI BBG004S68BH6 -> SUBSCRIPTION_STATUS_SUCCESS
  ... (250 успешных подписок)
Batch result: 250 successful, 0 failed
Total result: 500 successful, 0 failed
=====================================

=== LASTPRICE SUBSCRIPTION RESPONSE ===
Total subscriptions in response: 75
  FIGI TCS10A0JNAB6 -> SUBSCRIPTION_STATUS_SUCCESS
  ... (75 успешных подписок)
Batch result: 75 successful, 0 failed
Total result: 575 successful, 0 failed
=====================================

🎉 LastPrice streaming service started successfully
📈 Subscribed: 575 successful, 0 failed
```

## Масштабирование

### Текущая Конфигурация
- **Размер батча**: 250 инструментов
- **Задержка между батчами**: 1 секунда
- **Максимальная емкость**: ~15,000 инструментов в минуту (с учетом rate limit)

### Для Увеличения Количества Инструментов

1. **До 1000 инструментов**: Работает автоматически (4 батча)
2. **До 5000 инструментов**: Требуется увеличить задержку до 3-5 секунд
3. **Более 5000**: Рекомендуется использовать очереди и распределенную подписку

## Обработка Ошибок

### Ошибки Подключения
```java
@Override
public void onError(Throwable t) {
    log.error("❌ LastPrice stream error", t);
    metrics.incrementErrors();
    scheduleReconnect(); // Переподключение через 30 секунд
}
```

### Ошибки Подписки
```java
if (status.contains("LIMIT_IS_EXCEEDED")) {
    failedSubscriptions.incrementAndGet();
    log.warn("⚠️ Subscription limit exceeded for FIGI {}", figi);
}
```

### Автоматическое Переподключение
- **Задержка**: 30 секунд
- **Стратегия**: Переподключение всех stream'ов
- **Retry**: Бесконечный, пока сервис активен

## Мониторинг

### Метрики
- `successfulSubscriptions`: Количество успешных подписок
- `failedSubscriptions`: Количество неуспешных подписок
- `multiStreamManager.getActiveConnectionCount()`: Активные соединения
- `multiStreamManager.getTotalStreamCount()`: Всего stream'ов

### Health Check
```java
boolean isHealthy = 
    multiStreamManager != null && 
    multiStreamManager.isAllConnected() &&
    successfulSubscriptions.get() > 0;
```

## Производительность

### Потребление Ресурсов
- **Memory**: ~50MB на 1000 инструментов
- **CPU**: Минимальное (асинхронная обработка)
- **Network**: ~100 KB/s на stream при активной торговле

### Latency
- **Подключение**: 100-300ms на stream
- **Подписка**: 50-150ms на батч
- **Данные**: 10-50ms от биржи до обработки

## Конфигурация

### Настройка Размера Батча
```java
// По умолчанию: 250
SubscriptionBatcher batcher = new SubscriptionBatcher(200); // Более консервативно
```

### Настройка Задержки
```java
// В SubscriptionBatcher.java
public static final long BATCH_DELAY_MS = 2000; // 2 секунды для осторожности
```

### Настройка gRPC
```java
// В MultiStreamManager.createStreamForBatch()
.keepAliveTime(30, TimeUnit.SECONDS)
.keepAliveTimeout(5, TimeUnit.SECONDS)
.maxInboundMessageSize(4 * 1024 * 1024) // 4MB
```

## Тестирование

### Проверка с 575 Инструментами
```bash
# Запустить сервис
mvn spring-boot:run

# Проверить логи
tail -f logs/current/investment-data-stream-service.log | grep "📈 Subscribed"
```

### Ожидаемый Результат
```
📈 Subscribed: 575 successful, 0 failed
```

## Troubleshooting

### Проблема: LIMIT_IS_EXCEEDED
**Причина**: Размер батча слишком большой
**Решение**: Уменьшить `DEFAULT_BATCH_SIZE` до 200

### Проблема: Rate Limit Exceeded
**Причина**: Слишком быстрая подписка
**Решение**: Увеличить `BATCH_DELAY_MS` до 2000-3000ms

### Проблема: Connection Timeout
**Причина**: Слишком много одновременных подключений
**Решение**: Подключать stream'ы последовательно, а не параллельно

## Roadmap

### Ближайшее Будущее
- [ ] Динамическая настройка размера батча
- [ ] Умный rate limiting на основе ответов API
- [ ] Приоритизация инструментов

### Долгосрочные Планы
- [ ] Распределенная подписка через несколько инстансов
- [ ] Кэширование подписок
- [ ] WebSocket API для клиентов

