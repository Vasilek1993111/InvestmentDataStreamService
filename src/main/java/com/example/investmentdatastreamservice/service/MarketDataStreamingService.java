package com.example.investmentdatastreamservice.service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import com.example.investmentdatastreamservice.entity.CandleEntity;
import com.example.investmentdatastreamservice.entity.TradeEntity;
// removed unused CandleRepository
import com.example.investmentdatastreamservice.repository.FutureRepository;
import com.example.investmentdatastreamservice.repository.IndicativeRepository;
import com.example.investmentdatastreamservice.repository.ShareRepository;
// removed unused TradeBatchRepository
import io.grpc.stub.StreamObserver;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import ru.tinkoff.piapi.contract.v1.Candle;
import ru.tinkoff.piapi.contract.v1.CandleInstrument;
import ru.tinkoff.piapi.contract.v1.LastPrice;
import ru.tinkoff.piapi.contract.v1.LastPriceInstrument;
import ru.tinkoff.piapi.contract.v1.MarketDataRequest;
import ru.tinkoff.piapi.contract.v1.MarketDataResponse;
import ru.tinkoff.piapi.contract.v1.MarketDataStreamServiceGrpc;
import ru.tinkoff.piapi.contract.v1.SubscribeCandlesRequest;
import ru.tinkoff.piapi.contract.v1.SubscribeLastPriceRequest;
import ru.tinkoff.piapi.contract.v1.SubscribeLastPriceResponse;
import ru.tinkoff.piapi.contract.v1.SubscribeTradesRequest;
import ru.tinkoff.piapi.contract.v1.SubscribeTradesResponse;
import ru.tinkoff.piapi.contract.v1.SubscriptionAction;
import ru.tinkoff.piapi.contract.v1.SubscriptionInterval;
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
    // removed: private final TradeBatchRepository tradeBatchRepository;
    private final ShareRepository shareRepository;
    private final FutureRepository futureRepository;
    private final IndicativeRepository indicativeRepository;
    // removed: private final CandleRepository candleRepository; // оставляем для чтения при
    // необходимости
    // removed: private final JdbcTemplate jdbcTemplate;
    private final JdbcTemplate streamJdbcTemplate;

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
    private final AtomicLong totalTradeInserted = new AtomicLong(0);
    private final AtomicLong totalCandleReceived = new AtomicLong(0);
    private final AtomicLong totalCandleInserted = new AtomicLong(0);
    private final AtomicLong totalCandleReceivedShares = new AtomicLong(0);
    private final AtomicLong totalCandleReceivedFutures = new AtomicLong(0);
    private final AtomicLong totalCandleReceivedIndicatives = new AtomicLong(0);

    // Отдельные счетчики для LastPrice
    private final AtomicLong totalLastPriceReceived = new AtomicLong(0);
    private final AtomicLong totalLastPriceProcessed = new AtomicLong(0);
    private final AtomicLong totalLastPriceInserted = new AtomicLong(0);

    // Детализированные счетчики LastPrice по типам инструментов
    private final AtomicLong totalLastPriceReceivedShares = new AtomicLong(0);
    private final AtomicLong totalLastPriceReceivedFutures = new AtomicLong(0);
    private final AtomicLong totalLastPriceReceivedIndicatives = new AtomicLong(0);

    // Детализированные счетчики Trades по типам инструментов
    private final AtomicLong totalTradeReceivedShares = new AtomicLong(0);
    private final AtomicLong totalTradeReceivedFutures = new AtomicLong(0);
    private final AtomicLong totalTradeReceivedIndicatives = new AtomicLong(0);

    private volatile Set<String> shareFigisCache = Collections.emptySet();
    private volatile Set<String> futureFigisCache = Collections.emptySet();
    private volatile Set<String> indicativeFigisCache = Collections.emptySet();
    private volatile StreamObserver<MarketDataRequest> requestObserver;

    public MarketDataStreamingService(
            MarketDataStreamServiceGrpc.MarketDataStreamServiceStub streamStub,
            ShareRepository shareRepository, FutureRepository futureRepository,
            IndicativeRepository indicativeRepository,
            @Qualifier("streamJdbcTemplate") JdbcTemplate streamJdbcTemplate) {
        this.streamStub = streamStub;
        this.shareRepository = shareRepository;
        this.futureRepository = futureRepository;
        this.indicativeRepository = indicativeRepository;
        this.streamJdbcTemplate = streamJdbcTemplate;
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
                final String sql = "INSERT INTO invest.trades "
                        + "(figi, time, direction, price, quantity, currency, exchange, trade_source, trade_direction) "
                        + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) "
                        + "ON CONFLICT (figi, time, direction) DO UPDATE SET "
                        + "price = EXCLUDED.price, quantity = EXCLUDED.quantity, "
                        + "currency = EXCLUDED.currency, exchange = EXCLUDED.exchange, "
                        + "trade_source = EXCLUDED.trade_source, trade_direction = EXCLUDED.trade_direction";

                java.sql.Timestamp ts = java.sql.Timestamp.valueOf(entity.getId().getTime());

                streamJdbcTemplate.update(sql, entity.getId().getFigi(), ts,
                        entity.getId().getDirection(), entity.getPrice(), entity.getQuantity(),
                        entity.getCurrency(), entity.getExchange(), entity.getTradeSource(),
                        entity.getTradeDirection());

                // Разделяем счетчики по типу данных
                if ("LAST_PRICE".equals(entity.getId().getDirection())) {
                    totalLastPriceProcessed.incrementAndGet();
                    totalLastPriceInserted.incrementAndGet();
                } else {
                    totalTradeProcessed.incrementAndGet();
                    totalTradeInserted.incrementAndGet();
                }

                if (log.isDebugEnabled()) {
                    log.debug("Upserted trade for {} at {}: {} {}", entity.getId().getFigi(),
                            entity.getId().getTime(), entity.getPrice(),
                            entity.getId().getDirection());
                }
            } catch (Exception e) {
                totalTradeErrors.incrementAndGet();
                log.error("Error upserting trade for {}", entity.getId().getFigi(), e);
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

        // Загружаем акции (исключаем пустые FIGI)
        List<String> sharesFigis = shareRepository.findAllDistinctFigi().stream()
                .filter(figi -> figi != null && !figi.trim().isEmpty()).toList();
        log.info("Loaded {} shares from shares table (filtered empty FIGI)", sharesFigis.size());

        // Загружаем все фьючерсы (исключаем пустые FIGI)
        List<String> allFuturesFigis = futureRepository.findAllFigis().stream()
                .filter(figi -> figi != null && !figi.trim().isEmpty()).toList();
        log.info("Loaded {} total futures from futures table (filtered empty FIGI)",
                allFuturesFigis.size());

        // Дополнительно загружаем фьючерсы по типам для детального логирования (исключаем пустые
        // FIGI)
        List<String> futuresSecurity = futureRepository.findFigisByAssetType("TYPE_SECURITY")
                .stream().filter(figi -> figi != null && !figi.trim().isEmpty()).toList();
        List<String> futuresCurrency = futureRepository.findFigisByAssetType("TYPE_CURRENCY")
                .stream().filter(figi -> figi != null && !figi.trim().isEmpty()).toList();
        List<String> futuresCommodity = futureRepository.findFigisByAssetType("TYPE_COMMODITY")
                .stream().filter(figi -> figi != null && !figi.trim().isEmpty()).toList();
        List<String> futuresIndex = futureRepository.findFigisByAssetType("TYPE_INDEX").stream()
                .filter(figi -> figi != null && !figi.trim().isEmpty()).toList();

        log.info("Futures breakdown by type:");
        log.info("  - TYPE_SECURITY: {} instruments", futuresSecurity.size());
        log.info("  - TYPE_CURRENCY: {} instruments", futuresCurrency.size());
        log.info("  - TYPE_COMMODITY: {} instruments", futuresCommodity.size());
        log.info("  - TYPE_INDEX: {} instruments", futuresIndex.size());

        // Загружаем индикативные инструменты (исключаем пустые FIGI)
        List<String> indicativesFigis = indicativeRepository.findAllDistinctFigi().stream()
                .filter(figi -> figi != null && !figi.trim().isEmpty()).toList();
        log.info("Loaded {} indicatives from indicatives table (filtered empty FIGI)",
                indicativesFigis.size());

        // Объединяем акции, фьючерсы и индикативные инструменты
        List<String> allFigis = new ArrayList<>();
        allFigis.addAll(sharesFigis);
        allFigis.addAll(allFuturesFigis);
        allFigis.addAll(indicativesFigis);

        // refresh caches for categorization
        this.shareFigisCache = new HashSet<>(sharesFigis);
        this.futureFigisCache = new HashSet<>(allFuturesFigis);
        this.indicativeFigisCache = new HashSet<>(indicativesFigis);

        // Детальное логирование
        log.info("=== SUBSCRIPTION INSTRUMENTS SUMMARY ===");
        log.info("Total instruments loaded: {}", allFigis.size());
        log.info("Shares: {} instruments", sharesFigis.size());
        log.info("Futures total: {} instruments", allFuturesFigis.size());
        log.info("Indicatives: {} instruments (no candles support)", indicativesFigis.size());
        log.info("Candles subscription: {} instruments (shares + futures only)",
                sharesFigis.size() + allFuturesFigis.size());
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
        if (!indicativesFigis.isEmpty()) {
            log.debug("Sample indicatives FIGIs: {}",
                    indicativesFigis.subList(0, Math.min(5, indicativesFigis.size())));
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

            // Подписываемся на минутные свечи (только для акций и фьючерсов)
            // Индикативные инструменты (индексы) не поддерживают свечи
            List<String> candleInstruments = new ArrayList<>();

            // Получаем акции для свечей
            List<String> sharesForCandles = shareRepository.findAllDistinctFigi().stream()
                    .filter(figi -> figi != null && !figi.trim().isEmpty()).toList();

            // Получаем фьючерсы для свечей
            List<String> futuresForCandles = futureRepository.findAllFigis().stream()
                    .filter(figi -> figi != null && !figi.trim().isEmpty()).toList();

            candleInstruments.addAll(sharesForCandles);
            candleInstruments.addAll(futuresForCandles);

            log.info(
                    "Creating Candles subscription request for {} instruments (shares + futures only)",
                    candleInstruments.size());
            SubscribeCandlesRequest candlesReq = SubscribeCandlesRequest.newBuilder()
                    .setSubscriptionAction(SubscriptionAction.SUBSCRIPTION_ACTION_SUBSCRIBE)
                    .addAllInstruments(candleInstruments.stream()
                            .map(f -> CandleInstrument.newBuilder().setInstrumentId(f)
                                    .setInterval(
                                            SubscriptionInterval.SUBSCRIPTION_INTERVAL_ONE_MINUTE)
                                    .build())
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

            // Отправляем подписку на минутные свечи
            log.info("Building Candles subscription request");
            MarketDataRequest candlesSubscribeReq =
                    MarketDataRequest.newBuilder().setSubscribeCandlesRequest(candlesReq).build();

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

                    if (resp.hasSubscribeCandlesResponse()) {
                        resp.getSubscribeCandlesResponse();
                        isConnected.set(true);
                        log.info("=== CANDLES SUBSCRIPTION RESPONSE ===");
                        log.info("Candles subscription response received");
                        log.info("=====================================");
                        return;
                    }

                    if (resp.hasLastPrice()) {
                        log.info("Received last price data from T-Invest API for FIGI: {}",
                                resp.getLastPrice().getFigi());
                        processLastPrice(resp.getLastPrice());
                    } else if (resp.hasTrade()) {
                        processTrade(resp.getTrade());
                    } else if (resp.hasCandle()) {
                        processCandle(resp.getCandle());
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

            // Отправляем подписку на минутные свечи
            log.info("Sending Candles subscription request to T-Invest API");
            requestObserver.onNext(candlesSubscribeReq);

            log.info("Successfully sent all subscription requests to T-Invest API");

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
            long r = totalTradeReceived.incrementAndGet();

            // Подсчет Trades по типам инструментов
            String figi = trade.getFigi();
            if (shareFigisCache.contains(figi)) {
                totalTradeReceivedShares.incrementAndGet();
            } else if (futureFigisCache.contains(figi)) {
                totalTradeReceivedFutures.incrementAndGet();
            } else if (indicativeFigisCache.contains(figi)) {
                totalTradeReceivedIndicatives.incrementAndGet();
            }

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
            if (r % 1000 == 0) {
                log.info("Received trades: {} | Inserted trades: {}", totalTradeReceived.get(),
                        totalTradeInserted.get());
            }


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
     * Высокопроизводительная обработка данных о минутных свечах
     */
    private void processCandle(Candle candle) {
        try {
            long rc = totalCandleReceived.incrementAndGet();

            Instant eventInstant = Instant.ofEpochSecond(candle.getTime().getSeconds(),
                    candle.getTime().getNanos());
            // Конвертируем время в UTC+3 (московское время)
            LocalDateTime eventTime = LocalDateTime.ofInstant(eventInstant, ZoneOffset.of("+3"));

            // Конвертируем цены из Quotation в BigDecimal
            BigDecimal open = convertQuotationToBigDecimal(candle.getOpen());
            BigDecimal high = convertQuotationToBigDecimal(candle.getHigh());
            BigDecimal low = convertQuotationToBigDecimal(candle.getLow());
            BigDecimal close = convertQuotationToBigDecimal(candle.getClose());

            // Создаем CandleEntity для минутной свечи
            CandleEntity candleEntity = new CandleEntity(candle.getFigi(), eventTime,
                    candle.getVolume(), high, low, close, open, true, // isComplete - временно
                                                                      // устанавливаем true
                    null, // createdAt будет установлен автоматически
                    null // updatedAt будет установлен автоматически
            );

            // increment per-category counters
            String figi = candle.getFigi();
            if (shareFigisCache.contains(figi)) {
                totalCandleReceivedShares.incrementAndGet();
            } else if (futureFigisCache.contains(figi)) {
                totalCandleReceivedFutures.incrementAndGet();
            } else if (indicativeFigisCache.contains(figi)) {
                totalCandleReceivedIndicatives.incrementAndGet();
            }

            // Выполняем неблокирующую асинхронную вставку Candle данных
            insertCandleDataAsync(candleEntity);
            if (rc % 1000 == 0) {
                log.info("Received candles: {} | Inserted candles: {}", totalCandleReceived.get(),
                        totalCandleInserted.get());
            }

            // Логируем каждую 50-ю свечу для мониторинга частоты
            // per-record logs disabled

            // detailed debug disabled to reduce per-record logging

        } catch (Exception e) {
            totalTradeErrors.incrementAndGet();
            log.error("Error processing candle for {}", candle.getFigi(), e);
        }
    }

    /**
     * Конвертирует Quotation в BigDecimal
     */
    private BigDecimal convertQuotationToBigDecimal(
            ru.tinkoff.piapi.contract.v1.Quotation quotation) {
        return BigDecimal.valueOf(quotation.getUnits())
                .add(BigDecimal.valueOf(quotation.getNano()).movePointLeft(9));
    }

    /**
     * Высокопроизводительная неблокирующая асинхронная вставка Candle данных в базу
     */
    private void insertCandleDataAsync(CandleEntity entity) {
        tradeInsertExecutor.submit(() -> {
            try {
                tradeInsertSemaphore.acquire();
                final String sql =
                        "INSERT INTO invest.candles (figi, time, volume, high, low, close, open, is_complete) "
                                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?) "
                                + "ON CONFLICT (figi, time) DO UPDATE SET "
                                + "volume = EXCLUDED.volume, high = EXCLUDED.high, low = EXCLUDED.low, "
                                + "close = EXCLUDED.close, open = EXCLUDED.open, is_complete = EXCLUDED.is_complete, "
                                + "updated_at = now()";
                java.sql.Timestamp ts = java.sql.Timestamp.valueOf(entity.getTime());
                streamJdbcTemplate.update(sql, entity.getFigi(), ts, entity.getVolume(),
                        entity.getHigh(), entity.getLow(), entity.getClose(), entity.getOpen(),
                        Boolean.TRUE.equals(entity.getIsComplete()));
                totalCandleInserted.incrementAndGet();
            } catch (Exception e) {
                totalTradeErrors.incrementAndGet();
                log.error("Error inserting candle data for {}", entity.getFigi(), e);
            } finally {
                tradeInsertSemaphore.release();
            }
        });
    }

    /**
     * Высокопроизводительная обработка данных о последней цене
     */
    private void processLastPrice(LastPrice price) {
        try {
            totalReceived.incrementAndGet();
            totalLastPriceReceived.incrementAndGet();

            // Подсчет LastPrice по типам инструментов
            String figi = price.getFigi();
            if (shareFigisCache.contains(figi)) {
                totalLastPriceReceivedShares.incrementAndGet();
            } else if (futureFigisCache.contains(figi)) {
                totalLastPriceReceivedFutures.incrementAndGet();
            } else if (indicativeFigisCache.contains(figi)) {
                totalLastPriceReceivedIndicatives.incrementAndGet();
            }

            Instant eventInstant =
                    Instant.ofEpochSecond(price.getTime().getSeconds(), price.getTime().getNanos());
            // Конвертируем время в UTC+3 (московское время)
            LocalDateTime eventTime = LocalDateTime.ofInstant(eventInstant, ZoneOffset.of("+3"));

            BigDecimal priceValue = BigDecimal.valueOf(price.getPrice().getUnits())
                    .add(BigDecimal.valueOf(price.getPrice().getNano()).movePointLeft(9));

            // aggregated logging only

            // Создаем TradeEntity для сохранения в таблицу trades
            TradeEntity tradeEntity = new TradeEntity(price.getFigi(), eventTime, "LAST_PRICE", // Направление
                                                                                                // для
                                                                                                // LastPrice
                    priceValue, 1L, // Количество = 1 для LastPrice
                    "RUB", "MOEX", "LAST_PRICE" // Источник = LAST_PRICE
            );

            // Выполняем неблокирующую асинхронную вставку в таблицу trades
            // aggregated logging only
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
                tradeInsertSemaphore.availablePermits(), MAX_CONCURRENT_TRADE_INSERTS,
                totalCandleReceived.get(), totalCandleInserted.get(), totalTradeInserted.get(),
                totalCandleReceivedShares.get(), totalCandleReceivedFutures.get(),
                totalCandleReceivedIndicatives.get(), totalLastPriceReceived.get(),
                totalLastPriceProcessed.get(), totalLastPriceInserted.get(),
                totalLastPriceReceivedShares.get(), totalLastPriceReceivedFutures.get(),
                totalLastPriceReceivedIndicatives.get(), totalTradeReceivedShares.get(),
                totalTradeReceivedFutures.get(), totalTradeReceivedIndicatives.get());
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

        private final long totalCandleReceived;
        private final long totalCandleInserted;
        private final long totalTradeInserted;
        private final long totalCandleReceivedShares;
        private final long totalCandleReceivedFutures;
        private final long totalCandleReceivedIndicatives;

        // LastPrice счетчики
        private final long totalLastPriceReceived;
        private final long totalLastPriceProcessed;
        private final long totalLastPriceInserted;
        private final long totalLastPriceReceivedShares;
        private final long totalLastPriceReceivedFutures;
        private final long totalLastPriceReceivedIndicatives;

        // Trade счетчики по типам инструментов
        private final long totalTradeReceivedShares;
        private final long totalTradeReceivedFutures;
        private final long totalTradeReceivedIndicatives;

        public ServiceStats(boolean isRunning, boolean isConnected, long totalTradeProcessed,
                long totalTradeErrors, long totalReceived, long totalTradeReceived,
                int tradeQueueSize, int tradeBufferCapacity, long totalCandleReceived,
                long totalCandleInserted, long totalTradeInserted, long totalCandleReceivedShares,
                long totalCandleReceivedFutures, long totalCandleReceivedIndicatives,
                long totalLastPriceReceived, long totalLastPriceProcessed,
                long totalLastPriceInserted, long totalLastPriceReceivedShares,
                long totalLastPriceReceivedFutures, long totalLastPriceReceivedIndicatives,
                long totalTradeReceivedShares, long totalTradeReceivedFutures,
                long totalTradeReceivedIndicatives) {
            this.isRunning = isRunning;
            this.isConnected = isConnected;
            this.totalTradeProcessed = totalTradeProcessed;
            this.totalTradeErrors = totalTradeErrors;
            this.totalReceived = totalReceived;
            this.totalTradeReceived = totalTradeReceived;
            this.tradeQueueSize = tradeQueueSize;
            this.tradeBufferCapacity = tradeBufferCapacity;
            this.totalCandleReceived = totalCandleReceived;
            this.totalCandleInserted = totalCandleInserted;
            this.totalTradeInserted = totalTradeInserted;
            this.totalCandleReceivedShares = totalCandleReceivedShares;
            this.totalCandleReceivedFutures = totalCandleReceivedFutures;
            this.totalCandleReceivedIndicatives = totalCandleReceivedIndicatives;
            this.totalLastPriceReceived = totalLastPriceReceived;
            this.totalLastPriceProcessed = totalLastPriceProcessed;
            this.totalLastPriceInserted = totalLastPriceInserted;
            this.totalLastPriceReceivedShares = totalLastPriceReceivedShares;
            this.totalLastPriceReceivedFutures = totalLastPriceReceivedFutures;
            this.totalLastPriceReceivedIndicatives = totalLastPriceReceivedIndicatives;
            this.totalTradeReceivedShares = totalTradeReceivedShares;
            this.totalTradeReceivedFutures = totalTradeReceivedFutures;
            this.totalTradeReceivedIndicatives = totalTradeReceivedIndicatives;
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

        public long getTotalCandleReceived() {
            return totalCandleReceived;
        }

        public long getTotalCandleInserted() {
            return totalCandleInserted;
        }

        public long getTotalTradeInserted() {
            return totalTradeInserted;
        }

        public long getTotalCandleReceivedShares() {
            return this.totalCandleReceivedShares;
        }

        public long getTotalCandleReceivedFutures() {
            return this.totalCandleReceivedFutures;
        }

        public long getTotalCandleReceivedIndicatives() {
            return this.totalCandleReceivedIndicatives;
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
            return totalTradeInserted + totalCandleInserted;
        }

        public long getTotalErrorsAll() {
            return totalTradeErrors;
        }

        public long getTotalReceivedAll() {
            return totalReceived + totalTradeReceived + totalCandleReceived;
        }

        // Группировка по типам сообщений от API
        public long getTotalLastPriceReceived() {
            return totalLastPriceReceived;
        }

        public long getTotalLastPriceProcessed() {
            return totalLastPriceProcessed;
        }

        public long getTotalLastPriceInserted() {
            return totalLastPriceInserted;
        }

        public long getTotalLastPriceReceivedShares() {
            return totalLastPriceReceivedShares;
        }

        public long getTotalLastPriceReceivedFutures() {
            return totalLastPriceReceivedFutures;
        }

        public long getTotalLastPriceReceivedIndicatives() {
            return totalLastPriceReceivedIndicatives;
        }

        public long getTotalTradeReceivedShares() {
            return totalTradeReceivedShares;
        }

        public long getTotalTradeReceivedFutures() {
            return totalTradeReceivedFutures;
        }

        public long getTotalTradeReceivedIndicatives() {
            return totalTradeReceivedIndicatives;
        }

        public long getTotalTradeMessagesReceived() {
            return totalTradeReceived;
        }

        public long getTotalCandleMessagesReceived() {
            return totalCandleReceived;
        }

        // Группировка по обработанным записям в БД
        public long getTotalTradesInserted() {
            return totalTradeInserted;
        }

        public long getTotalCandlesInserted() {
            return totalCandleInserted;
        }

        // Группировка по обработанным сообщениям (включая ошибки)
        public long getTotalTradesProcessed() {
            return totalTradeProcessed;
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
