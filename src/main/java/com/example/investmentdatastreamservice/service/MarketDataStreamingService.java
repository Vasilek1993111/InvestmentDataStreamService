package com.example.investmentdatastreamservice.service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import com.example.investmentdatastreamservice.entity.TradeEntity;
import com.example.investmentdatastreamservice.repository.FutureRepository;
import com.example.investmentdatastreamservice.repository.ShareRepository;
import com.example.investmentdatastreamservice.repository.TradeBatchRepository;
import io.grpc.stub.StreamObserver;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import ru.tinkoff.piapi.contract.v1.LastPrice;
import ru.tinkoff.piapi.contract.v1.LastPriceInstrument;
import ru.tinkoff.piapi.contract.v1.MarketDataRequest;
import ru.tinkoff.piapi.contract.v1.MarketDataResponse;
import ru.tinkoff.piapi.contract.v1.MarketDataStreamServiceGrpc;
import ru.tinkoff.piapi.contract.v1.SubscribeLastPriceRequest;
import ru.tinkoff.piapi.contract.v1.SubscribeLastPriceResponse;
import ru.tinkoff.piapi.contract.v1.SubscribeTradesRequest;
import ru.tinkoff.piapi.contract.v1.SubscribeTradesResponse;
import ru.tinkoff.piapi.contract.v1.SubscriptionAction;
import ru.tinkoff.piapi.contract.v1.Trade;
import ru.tinkoff.piapi.contract.v1.TradeDirection;

/**
 * Высокопроизводительный сервис для потоковой обработки рыночных данных
 * 
 * Обеспечивает получение данных в реальном времени от T-Invest API с минимальными задержками,
 * асинхронную обработку, автоматическое переподключение и максимальную производительность.
 */
@Service
public class MarketDataStreamingService {

    private static final Logger log = LoggerFactory.getLogger(MarketDataStreamingService.class);

    // Конфигурация производительности для неблокирующих вставок
    private static final int TRADE_INSERT_THREADS = Runtime.getRuntime().availableProcessors() * 6; // Еще
                                                                                                    // больше
                                                                                                    // потоков
                                                                                                    // для
                                                                                                    // Trade
    private static final int RECONNECT_DELAY_MS = 1000;
    private static final int MAX_CONCURRENT_TRADE_INSERTS = 200; // Максимум одновременных Trade
                                                                 // вставок

    private final MarketDataStreamServiceGrpc.MarketDataStreamServiceStub streamStub;
    private final TradeBatchRepository tradeBatchRepository;
    private final ShareRepository shareRepository;
    private final FutureRepository futureRepository;

    // Неблокирующие структуры данных для прямых вставок
    private final ExecutorService tradeInsertExecutor =
            Executors.newFixedThreadPool(TRADE_INSERT_THREADS);
    private final ScheduledExecutorService reconnectScheduler =
            Executors.newSingleThreadScheduledExecutor();
    private final Semaphore tradeInsertSemaphore = new Semaphore(MAX_CONCURRENT_TRADE_INSERTS);

    // Состояние сервиса
    private final AtomicBoolean isRunning = new AtomicBoolean(false);
    private final AtomicBoolean isConnected = new AtomicBoolean(false);
    private final AtomicLong totalTradeProcessed = new AtomicLong(0);
    private final AtomicLong totalTradeErrors = new AtomicLong(0);
    private final AtomicLong totalReceived = new AtomicLong(0);
    private final AtomicLong totalTradeReceived = new AtomicLong(0);
    private volatile StreamObserver<MarketDataRequest> requestObserver;

    public MarketDataStreamingService(
            MarketDataStreamServiceGrpc.MarketDataStreamServiceStub streamStub,
            TradeBatchRepository tradeBatchRepository, ShareRepository shareRepository,
            FutureRepository futureRepository) {
        this.streamStub = streamStub;
        this.tradeBatchRepository = tradeBatchRepository;
        this.shareRepository = shareRepository;
        this.futureRepository = futureRepository;
    }

    /**
     * Инициализация высокопроизводительного сервиса с неблокирующими вставками
     */
    @PostConstruct
    public void init() {
        log.info("=== MARKET DATA STREAMING SERVICE INITIALIZATION ===");
        log.info(
                "Initializing non-blocking MarketDataStreamingService with {} trade insert threads",
                TRADE_INSERT_THREADS);
        log.info("Max concurrent trade inserts: {}", MAX_CONCURRENT_TRADE_INSERTS);

        isRunning.set(true);

        // Запуск потока данных
        log.info("Starting initial market data stream...");
        startLastPriceStream();

        log.info("MarketDataStreamingService initialized successfully with non-blocking inserts");
        log.info("================================================================");
    }

    /**
     * Корректное завершение работы сервиса
     */
    @PreDestroy
    public void shutdown() {
        log.info("Shutting down MarketDataStreamingService...");

        isRunning.set(false);

        // Завершение потоков
        tradeInsertExecutor.shutdown();
        reconnectScheduler.shutdown();

        try {
            if (!tradeInsertExecutor.awaitTermination(5, TimeUnit.SECONDS)) {
                tradeInsertExecutor.shutdownNow();
            }
            if (!reconnectScheduler.awaitTermination(2, TimeUnit.SECONDS)) {
                reconnectScheduler.shutdownNow();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("Interrupted during shutdown", e);
        }

        log.info(
                "MarketDataStreamingService shutdown completed. Total processed: {} trades. Total errors: {} trades",
                totalTradeProcessed.get(), totalTradeErrors.get());
    }


    /**
     * Высокопроизводительная неблокирующая асинхронная вставка Trade данных в базу
     */
    private void insertTradeDataAsync(TradeEntity entity) {
        // Проверяем, можем ли мы выполнить вставку
        if (!tradeInsertSemaphore.tryAcquire()) {
            log.warn("Too many concurrent trade inserts, dropping trade for {}",
                    entity.getId().getFigi());
            return;
        }

        tradeInsertExecutor.submit(() -> {
            try {
                // Выполняем вставку одной записи
                tradeBatchRepository.upsertBatch(List.of(entity));
                totalTradeProcessed.incrementAndGet();

                if (log.isDebugEnabled()) {
                    log.debug("Successfully inserted trade for {} at {}: {} {}",
                            entity.getId().getFigi(), entity.getId().getTime(), entity.getPrice(),
                            entity.getId().getDirection());
                }
            } catch (Exception e) {
                totalTradeErrors.incrementAndGet();
                log.error("Error inserting trade for {}", entity.getId().getFigi(), e);
            } finally {
                tradeInsertSemaphore.release();
            }
        });
    }



    /**
     * Получение списка FIGI всех акций и фьючерсов для подписки
     * 
     * @return список FIGI всех акций и фьючерсов разных типов
     */
    private List<String> getAllInstruments() {
        log.info("Starting to load FIGI instruments for subscription...");

        // Загружаем акции
        List<String> sharesFigis = shareRepository.findAllDistinctFigi();
        log.info("Loaded {} shares from shares table", sharesFigis.size());

        // Загружаем все фьючерсы
        List<String> allFuturesFigis = futureRepository.findAllFigis();
        log.info("Loaded {} total futures from futures table", allFuturesFigis.size());

        // Дополнительно загружаем фьючерсы по типам для детального логирования
        List<String> futuresSecurity = futureRepository.findFigisByAssetType("TYPE_SECURITY");
        List<String> futuresCurrency = futureRepository.findFigisByAssetType("TYPE_CURRENCY");
        List<String> futuresCommodity = futureRepository.findFigisByAssetType("TYPE_COMMODITY");
        List<String> futuresIndex = futureRepository.findFigisByAssetType("TYPE_INDEX");

        log.info("Futures breakdown by type:");
        log.info("  - TYPE_SECURITY: {} instruments", futuresSecurity.size());
        log.info("  - TYPE_CURRENCY: {} instruments", futuresCurrency.size());
        log.info("  - TYPE_COMMODITY: {} instruments", futuresCommodity.size());
        log.info("  - TYPE_INDEX: {} instruments", futuresIndex.size());

        // Объединяем акции и фьючерсы
        List<String> allFigis = new ArrayList<>();
        allFigis.addAll(sharesFigis);
        allFigis.addAll(allFuturesFigis);

        // Детальное логирование
        log.info("=== SUBSCRIPTION INSTRUMENTS SUMMARY ===");
        log.info("Total instruments loaded: {}", allFigis.size());
        log.info("Shares: {} instruments", sharesFigis.size());
        log.info("Futures total: {} instruments", allFuturesFigis.size());
        log.info("Futures breakdown by type:");
        log.info("  - TYPE_SECURITY: {} instruments", futuresSecurity.size());
        log.info("  - TYPE_CURRENCY: {} instruments", futuresCurrency.size());
        log.info("  - TYPE_COMMODITY: {} instruments", futuresCommodity.size());
        log.info("  - TYPE_INDEX: {} instruments", futuresIndex.size());
        log.info("=========================================");

        // Логируем первые несколько FIGI для отладки
        if (!sharesFigis.isEmpty()) {
            log.debug("Sample shares FIGIs: {}",
                    sharesFigis.subList(0, Math.min(5, sharesFigis.size())));
        }
        if (!allFuturesFigis.isEmpty()) {
            log.debug("Sample futures FIGIs: {}",
                    allFuturesFigis.subList(0, Math.min(5, allFuturesFigis.size())));
        }

        return allFigis;
    }

    /**
     * Запуск высокопроизводительного потока данных о последних ценах с автоматическим
     * переподключением
     */
    public void startLastPriceStream() {
        if (!isRunning.get()) {
            log.warn("Service is not running, skipping stream start");
            return;
        }

        log.info("Starting market data stream subscription...");
        List<String> allFigis = getAllInstruments();

        if (allFigis.isEmpty()) {
            log.warn("No FIGIs found for subscription, retrying in 30 seconds...");
            scheduleReconnect(30);
            return;
        }

        log.info("Preparing subscription requests for {} instruments", allFigis.size());

        try {
            // Подписываемся на цены последних сделок
            log.info("Creating LastPrice subscription request for {} instruments", allFigis.size());
            SubscribeLastPriceRequest lastPriceReq = SubscribeLastPriceRequest.newBuilder()
                    .setSubscriptionAction(SubscriptionAction.SUBSCRIPTION_ACTION_SUBSCRIBE)
                    .addAllInstruments(allFigis.stream()
                            .map(f -> LastPriceInstrument.newBuilder().setInstrumentId(f).build())
                            .toList())
                    .build();

            // Подписываемся на поток обезличенных сделок для максимального потока данных
            log.info("Creating Trades subscription request for {} instruments", allFigis.size());
            SubscribeTradesRequest tradesReq =
                    SubscribeTradesRequest.newBuilder()
                            .setSubscriptionAction(SubscriptionAction.SUBSCRIPTION_ACTION_SUBSCRIBE)
                            .addAllInstruments(allFigis.stream()
                                    .map(f -> ru.tinkoff.piapi.contract.v1.TradeInstrument
                                            .newBuilder().setInstrumentId(f).build())
                                    .toList())
                            .build();

            // Отправляем подписку на цены последних сделок
            log.info("Building LastPrice subscription request");
            MarketDataRequest lastPriceSubscribeReq = MarketDataRequest.newBuilder()
                    .setSubscribeLastPriceRequest(lastPriceReq).build();

            // Отправляем подписку на поток сделок
            log.info("Building Trades subscription request");
            MarketDataRequest tradesSubscribeReq =
                    MarketDataRequest.newBuilder().setSubscribeTradesRequest(tradesReq).build();

            StreamObserver<MarketDataResponse> responseObserver = new StreamObserver<>() {
                @Override
                public void onNext(MarketDataResponse resp) {
                    if (resp.hasSubscribeLastPriceResponse()) {
                        SubscribeLastPriceResponse sr = resp.getSubscribeLastPriceResponse();
                        isConnected.set(true);
                        log.info("=== LastPrice SUBSCRIPTION RESPONSE ===");
                        log.info("Total LastPrice subscriptions: {}",
                                sr.getLastPriceSubscriptionsList().size());
                        sr.getLastPriceSubscriptionsList().forEach(s -> log.info("  FIGI {} -> {}",
                                s.getFigi(), s.getSubscriptionStatus()));
                        log.info("=====================================");
                        return;
                    }

                    if (resp.hasSubscribeTradesResponse()) {
                        SubscribeTradesResponse sr = resp.getSubscribeTradesResponse();
                        isConnected.set(true);
                        log.info("=== TRADES SUBSCRIPTION RESPONSE ===");
                        log.info("Total Trades subscriptions: {}",
                                sr.getTradeSubscriptionsList().size());
                        sr.getTradeSubscriptionsList().forEach(s -> log.info("  FIGI {} -> {}",
                                s.getFigi(), s.getSubscriptionStatus()));
                        log.info("===================================");
                        return;
                    }

                    if (resp.hasLastPrice()) {
                        log.info("Received last price data from T-Invest API for FIGI: {}",
                                resp.getLastPrice().getFigi());
                        processLastPrice(resp.getLastPrice());
                    } else if (resp.hasTrade()) {
                        log.info("Received trade data from T-Invest API for FIGI: {}",
                                resp.getTrade().getFigi());
                        processTrade(resp.getTrade());
                    } else {
                        log.info("Received unknown response type from T-Invest API: {}", resp);
                    }
                }

                @Override
                public void onError(Throwable t) {
                    isConnected.set(false);
                    totalTradeErrors.incrementAndGet();
                    log.error("Market data stream error, attempting reconnection...", t);
                    scheduleReconnect(RECONNECT_DELAY_MS);
                }

                @Override
                public void onCompleted() {
                    isConnected.set(false);
                    log.info("Market data stream completed, restarting subscription...");
                    scheduleReconnect(RECONNECT_DELAY_MS);
                }
            };

            log.info("Connecting to T-Invest API with {} instruments...", allFigis.size());
            requestObserver = streamStub.marketDataStream(responseObserver);

            // Отправляем подписку на цены последних сделок
            log.info("Sending LastPrice subscription request to T-Invest API");
            requestObserver.onNext(lastPriceSubscribeReq);

            // Отправляем подписку на поток сделок
            log.info("Sending Trades subscription request to T-Invest API");
            requestObserver.onNext(tradesSubscribeReq);

            log.info("Successfully sent both subscription requests to T-Invest API");

        } catch (Exception e) {
            totalTradeErrors.incrementAndGet();
            log.error("Error starting market data stream", e);
            scheduleReconnect(RECONNECT_DELAY_MS);
        }
    }

    /**
     * Высокопроизводительная обработка данных о сделке с минимальной задержкой
     */
    private void processTrade(Trade trade) {
        try {
            totalTradeReceived.incrementAndGet();

            Instant eventInstant =
                    Instant.ofEpochSecond(trade.getTime().getSeconds(), trade.getTime().getNanos());
            // Конвертируем время в UTC+3 (московское время)
            LocalDateTime eventTime = LocalDateTime.ofInstant(eventInstant, ZoneOffset.of("+3"));

            BigDecimal priceValue = BigDecimal.valueOf(trade.getPrice().getUnits())
                    .add(BigDecimal.valueOf(trade.getPrice().getNano()).movePointLeft(9));

            // Определяем направление сделки
            String direction =
                    trade.getDirection() == TradeDirection.TRADE_DIRECTION_BUY ? "BUY" : "SELL";

            // Определяем источник сделки (по умолчанию EXCHANGE)
            String tradeSource = "EXCHANGE";

            // Создаем TradeEntity для обезличенной сделки в таблицу trades
            TradeEntity tradeEntity = new TradeEntity(trade.getFigi(), eventTime, direction,
                    priceValue, trade.getQuantity(), "RUB", "MOEX", tradeSource);

            // Выполняем неблокирующую асинхронную вставку Trade данных
            insertTradeDataAsync(tradeEntity);


            // Логируем каждую 100-ю запись для мониторинга частоты
            if (totalTradeReceived.get() % 100 == 0) {
                log.info("Received {} trades from T-Invest API", totalTradeReceived.get());
            }

            if (log.isDebugEnabled()) {
                log.debug("Processing trade for {} at {}: {} {} ({} lots)", trade.getFigi(),
                        eventTime, priceValue, direction, trade.getQuantity());
            }

            if (log.isTraceEnabled()) {
                log.trace("Processed trade for {} at {}: {} {} ({} lots) from {}", trade.getFigi(),
                        eventTime, priceValue, direction, trade.getQuantity(), tradeSource);
            }
        } catch (Exception e) {
            totalTradeErrors.incrementAndGet();
            log.error("Error processing trade for {}", trade.getFigi(), e);
        }
    }

    /**
     * Высокопроизводительная обработка данных о последней цене
     */
    private void processLastPrice(LastPrice price) {
        try {
            totalReceived.incrementAndGet();

            Instant eventInstant =
                    Instant.ofEpochSecond(price.getTime().getSeconds(), price.getTime().getNanos());
            // Конвертируем время в UTC+3 (московское время)
            LocalDateTime eventTime = LocalDateTime.ofInstant(eventInstant, ZoneOffset.of("+3"));

            BigDecimal priceValue = BigDecimal.valueOf(price.getPrice().getUnits())
                    .add(BigDecimal.valueOf(price.getPrice().getNano()).movePointLeft(9));

            log.info("Processing LastPrice: FIGI={}, Time={}, Price={}", price.getFigi(), eventTime,
                    priceValue);

            // Создаем TradeEntity для сохранения в таблицу trades
            TradeEntity tradeEntity = new TradeEntity(price.getFigi(), eventTime, "LAST_PRICE", // Направление
                                                                                                // для
                                                                                                // LastPrice
                    priceValue, 1L, // Количество = 1 для LastPrice
                    "RUB", "MOEX", "LAST_PRICE" // Источник = LAST_PRICE
            );

            // Выполняем неблокирующую асинхронную вставку в таблицу trades
            log.info("Sending LastPrice as Trade entity to async insert for FIGI: {}",
                    price.getFigi());
            insertTradeDataAsync(tradeEntity);

            // Логируем каждую 100-ю запись для мониторинга частоты
            if (totalReceived.get() % 100 == 0) {
                log.info("Received {} prices from T-Invest API", totalReceived.get());
            }

            if (log.isDebugEnabled()) {
                log.debug("Processing price for {} at {}: {}", price.getFigi(), eventTime,
                        priceValue);
            }

            if (log.isTraceEnabled()) {
                log.trace("Processed price for {} at {}: {}", price.getFigi(), eventTime,
                        priceValue);
            }
        } catch (Exception e) {
            totalTradeErrors.incrementAndGet();
            log.error("Error processing last price for {}", price.getFigi(), e);
        }
    }

    /**
     * Планирование переподключения с экспоненциальной задержкой
     */
    private void scheduleReconnect(long delayMs) {
        if (!isRunning.get()) {
            return;
        }

        reconnectScheduler.schedule(() -> {
            if (isRunning.get() && !isConnected.get()) {
                log.info("Attempting to reconnect to T-Invest API...");
                startLastPriceStream();
            }
        }, delayMs, TimeUnit.MILLISECONDS);
    }

    /**
     * Получить статистику производительности сервиса
     */
    public ServiceStats getServiceStats() {
        return new ServiceStats(isRunning.get(), isConnected.get(), totalTradeProcessed.get(),
                totalTradeErrors.get(), totalReceived.get(), totalTradeReceived.get(),
                tradeInsertSemaphore.availablePermits(), MAX_CONCURRENT_TRADE_INSERTS);
    }

    /**
     * Принудительное переподключение к T-Invest API
     */
    public void forceReconnect() {
        log.info("Force reconnection requested");
        isConnected.set(false);
        if (requestObserver != null) {
            try {
                requestObserver.onCompleted();
            } catch (Exception e) {
                log.warn("Error completing request observer", e);
            }
        }
        scheduleReconnect(100);
    }

    /**
     * Расширенная статистика сервиса с метриками Trade обработки
     */
    public static class ServiceStats {
        private final boolean isRunning;
        private final boolean isConnected;
        private final long totalTradeProcessed;
        private final long totalTradeErrors;
        private final long totalReceived;
        private final long totalTradeReceived;
        private final int tradeQueueSize;
        private final int tradeBufferCapacity;

        public ServiceStats(boolean isRunning, boolean isConnected, long totalTradeProcessed,
                long totalTradeErrors, long totalReceived, long totalTradeReceived,
                int tradeQueueSize, int tradeBufferCapacity) {
            this.isRunning = isRunning;
            this.isConnected = isConnected;
            this.totalTradeProcessed = totalTradeProcessed;
            this.totalTradeErrors = totalTradeErrors;
            this.totalReceived = totalReceived;
            this.totalTradeReceived = totalTradeReceived;
            this.tradeQueueSize = tradeQueueSize;
            this.tradeBufferCapacity = tradeBufferCapacity;
        }

        public boolean isRunning() {
            return isRunning;
        }

        public boolean isConnected() {
            return isConnected;
        }


        public long getTotalTradeProcessed() {
            return totalTradeProcessed;
        }


        public long getTotalTradeErrors() {
            return totalTradeErrors;
        }

        public long getTotalReceived() {
            return totalReceived;
        }

        public long getTotalTradeReceived() {
            return totalTradeReceived;
        }


        public int getAvailableTradeInserts() {
            return tradeQueueSize;
        }


        public int getMaxConcurrentTradeInserts() {
            return tradeBufferCapacity;
        }


        public double getTradeInsertUtilization() {
            return tradeBufferCapacity > 0
                    ? (double) (tradeBufferCapacity - tradeQueueSize) / tradeBufferCapacity
                    : 0.0;
        }


        public double getTradeErrorRate() {
            long total = totalTradeProcessed + totalTradeErrors;
            return total > 0 ? (double) totalTradeErrors / total : 0.0;
        }


        public double getTradeProcessingRate() {
            return totalTradeReceived > 0 ? (double) totalTradeProcessed / totalTradeReceived : 0.0;
        }

        public long getTotalProcessedAll() {
            return totalTradeProcessed;
        }

        public long getTotalErrorsAll() {
            return totalTradeErrors;
        }

        public long getTotalReceivedAll() {
            return totalReceived + totalTradeReceived;
        }

        public double getOverallErrorRate() {
            long total = getTotalProcessedAll() + getTotalErrorsAll();
            return total > 0 ? (double) getTotalErrorsAll() / total : 0.0;
        }

        public double getOverallProcessingRate() {
            return getTotalReceivedAll() > 0
                    ? (double) getTotalProcessedAll() / getTotalReceivedAll()
                    : 0.0;
        }
    }

}
