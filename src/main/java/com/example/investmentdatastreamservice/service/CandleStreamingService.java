package com.example.investmentdatastreamservice.service;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import com.example.investmentdatastreamservice.dto.MinuteCandleDto;
import com.example.investmentdatastreamservice.repository.FutureRepository;
import com.example.investmentdatastreamservice.repository.ShareRepository;
import com.example.investmentdatastreamservice.utils.TimeZoneUtils;
import io.grpc.stub.StreamObserver;
import jakarta.annotation.PreDestroy;
import ru.tinkoff.piapi.contract.v1.Candle;
import ru.tinkoff.piapi.contract.v1.CandleInstrument;
import ru.tinkoff.piapi.contract.v1.MarketDataRequest;
import ru.tinkoff.piapi.contract.v1.MarketDataResponse;
import ru.tinkoff.piapi.contract.v1.MarketDataStreamServiceGrpc;
import ru.tinkoff.piapi.contract.v1.SubscribeCandlesRequest;
import ru.tinkoff.piapi.contract.v1.SubscriptionAction;
import ru.tinkoff.piapi.contract.v1.SubscriptionInterval;

/**
 * Сервис для управления подпиской на минутные свечи
 * 
 * <p>
 * Обеспечивает получение минутных свечей в реальном времени от T-Invest API для акций и фьючерсов.
 * </p>
 * 
 * @author InvestmentDataStreamService
 * @version 1.0
 * @since 2024
 */
@Service
public class CandleStreamingService {

    private static final Logger log = LoggerFactory.getLogger(CandleStreamingService.class);
    private static final int MAX_CONCURRENT_INSERTS = 200;

    private final MarketDataStreamServiceGrpc.MarketDataStreamServiceStub streamStub;
    private final ShareRepository shareRepository;
    private final FutureRepository futureRepository;
    private final JdbcTemplate streamJdbcTemplate;
    private final CandleService candleService;

    // Управление потоками
    private final ExecutorService insertExecutor =
            Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors() * 4);
    private final Semaphore insertSemaphore = new Semaphore(MAX_CONCURRENT_INSERTS);

    // Состояние сервиса
    private final AtomicBoolean isRunning = new AtomicBoolean(false);
    private final AtomicBoolean isConnected = new AtomicBoolean(false);
    private final AtomicLong totalReceived = new AtomicLong(0);
    private final AtomicLong totalInserted = new AtomicLong(0); // Всего обработано (INSERT +
                                                                // UPDATE)
    private final AtomicLong totalErrors = new AtomicLong(0);

    private volatile StreamObserver<MarketDataRequest> requestObserver;

    public CandleStreamingService(
            MarketDataStreamServiceGrpc.MarketDataStreamServiceStub streamStub,
            ShareRepository shareRepository, FutureRepository futureRepository,
            @Qualifier("streamJdbcTemplate") JdbcTemplate streamJdbcTemplate,
            CandleService candleService) {
        this.streamStub = streamStub;
        this.shareRepository = shareRepository;
        this.futureRepository = futureRepository;
        this.streamJdbcTemplate = streamJdbcTemplate;
        this.candleService = candleService;
    }

    /**
     * Запустить подписку на минутные свечи
     * 
     * <p>
     * Подписывается на минутные свечи для всех акций и фьючерсов из кэша.
     * </p>
     */
    public void startCandleSubscription() {
        if (isRunning.get()) {
            log.warn("Candle streaming service is already running");
            throw new IllegalStateException("Подписка на свечи уже активна");
        }

        log.info("Starting candle streaming service...");
        isRunning.set(true);

        // Получаем список инструментов для подписки
        List<String> candleInstruments = getCandleInstruments();

        if (candleInstruments.isEmpty()) {
            log.warn("No instruments found for candle subscription");
            isRunning.set(false);
            throw new IllegalStateException("Нет инструментов для подписки на свечи");
        }

        log.info("Subscribing to candles for {} instruments (shares + futures)",
                candleInstruments.size());

        try {
            // Создаем запрос на подписку
            SubscribeCandlesRequest candlesReq = SubscribeCandlesRequest.newBuilder()
                    .setSubscriptionAction(SubscriptionAction.SUBSCRIPTION_ACTION_SUBSCRIBE)
                    .addAllInstruments(candleInstruments.stream()
                            .map(f -> CandleInstrument.newBuilder().setInstrumentId(f)
                                    .setInterval(
                                            SubscriptionInterval.SUBSCRIPTION_INTERVAL_ONE_MINUTE)
                                    .build())
                            .toList())
                    .build();

            MarketDataRequest candlesSubscribeReq =
                    MarketDataRequest.newBuilder().setSubscribeCandlesRequest(candlesReq).build();

            // Создаем обсервер для получения данных
            StreamObserver<MarketDataResponse> responseObserver = new StreamObserver<>() {
                @Override
                public void onNext(MarketDataResponse resp) {
                    if (resp.hasSubscribeCandlesResponse()) {
                        isConnected.set(true);
                        log.info("=== CANDLES SUBSCRIPTION RESPONSE ===");
                        log.info("Successfully subscribed to {} candles",
                                resp.getSubscribeCandlesResponse().getCandlesSubscriptionsList()
                                        .size());
                        log.info("=====================================");
                        return;
                    }

                    if (resp.hasCandle()) {
                        processCandle(resp.getCandle());
                    }
                }

                @Override
                public void onError(Throwable t) {
                    isConnected.set(false);
                    totalErrors.incrementAndGet();
                    log.error("Candle stream error: {}", t.getMessage(), t);
                }

                @Override
                public void onCompleted() {
                    isConnected.set(false);
                    log.info("Candle stream completed");
                }
            };

            // Открываем стрим и отправляем подписку
            requestObserver = streamStub.marketDataStream(responseObserver);
            requestObserver.onNext(candlesSubscribeReq);

            log.info("Candle streaming service started successfully");

        } catch (Exception e) {
            isRunning.set(false);
            totalErrors.incrementAndGet();
            log.error("Error starting candle streaming service", e);
            throw new RuntimeException("Ошибка при запуске подписки на свечи: " + e.getMessage(),
                    e);
        }
    }

    /**
     * Остановить подписку на минутные свечи
     */
    public void stopCandleSubscription() {
        if (!isRunning.get()) {
            log.warn("Candle streaming service is not running");
            throw new IllegalStateException("Подписка на свечи не активна");
        }

        log.info("Stopping candle streaming service...");
        isRunning.set(false);
        isConnected.set(false);

        if (requestObserver != null) {
            try {
                // Отправляем запрос на отписку
                List<String> candleInstruments = getCandleInstruments();
                SubscribeCandlesRequest unsubscribeReq = SubscribeCandlesRequest.newBuilder()
                        .setSubscriptionAction(SubscriptionAction.SUBSCRIPTION_ACTION_UNSUBSCRIBE)
                        .addAllInstruments(candleInstruments.stream().map(f -> CandleInstrument
                                .newBuilder().setInstrumentId(f)
                                .setInterval(SubscriptionInterval.SUBSCRIPTION_INTERVAL_ONE_MINUTE)
                                .build()).toList())
                        .build();

                MarketDataRequest unsubscribeRequest = MarketDataRequest.newBuilder()
                        .setSubscribeCandlesRequest(unsubscribeReq).build();

                requestObserver.onNext(unsubscribeRequest);
                requestObserver.onCompleted();
            } catch (Exception e) {
                log.warn("Error during unsubscribe", e);
            }
        }

        log.info("Candle streaming service stopped successfully");
    }

    /**
     * Получить список инструментов для подписки на свечи
     * 
     * @return список FIGI акций и фьючерсов
     */
    private List<String> getCandleInstruments() {
        List<String> instruments = new ArrayList<>();

        // Получаем акции
        List<String> shares = shareRepository.findAllDistinctFigi().stream()
                .filter(figi -> figi != null && !figi.trim().isEmpty()).toList();

        // Получаем фьючерсы
        List<String> futures = futureRepository.findAllFigis().stream()
                .filter(figi -> figi != null && !figi.trim().isEmpty()).toList();

        instruments.addAll(shares);
        instruments.addAll(futures);

        log.info("Found {} instruments for candle subscription (shares: {}, futures: {})",
                instruments.size(), shares.size(), futures.size());

        return instruments;
    }

    /**
     * Обработать полученную свечу
     */
    private void processCandle(Candle candle) {
        try {
            totalReceived.incrementAndGet();

            Instant eventInstant = Instant.ofEpochSecond(candle.getTime().getSeconds(),
                    candle.getTime().getNanos());
            LocalDateTime eventTime = LocalDateTime.ofInstant(eventInstant, ZoneOffset.of("+3"));

            BigDecimal open = convertQuotationToBigDecimal(candle.getOpen());
            BigDecimal high = convertQuotationToBigDecimal(candle.getHigh());
            BigDecimal low = convertQuotationToBigDecimal(candle.getLow());
            BigDecimal close = convertQuotationToBigDecimal(candle.getClose());

            // Используем CandleService для создания свечи с техническими показателями
            MinuteCandleDto candleDto = candleService.enrichCandleWithTechnicalIndicators(open, high, low, close);
            candleDto.setFigi(candle.getFigi());
            candleDto.setTime(eventTime.atZone(TimeZoneUtils.getMoscowZone()).toInstant());
            candleDto.setVolume(candle.getVolume());
            candleDto.setComplete(true);

            // Асинхронно сохраняем в БД
            insertCandleAsync(candleDto);

            // Мониторинг каждые 100 свечей
            if (totalReceived.get() % 100 == 0) {
                long processed = totalInserted.get();
                long errors = totalErrors.get();
                long pending = totalReceived.get() - processed - errors;
                double utilization = getStats().getInsertUtilization();

                log.info("Received {} | Processed {} | Pending {} | Utilization {:.1f}%",
                        totalReceived.get(), processed, pending, utilization * 100);

                // КРИТИЧЕСКИЕ АЛЕРТЫ
                if (pending > 1000) {
                    log.error(
                            "!!! CRITICAL: Pending operations exceed 1000 ({}). Possible backlog!",
                            pending);
                }

                if (utilization > 0.95) {
                    log.error(
                            "!!! CRITICAL: Insert pool utilization > 95% ({:.1f}%). System overloaded!",
                            utilization * 100);
                }

                if (errors > 0 && (double) errors / totalReceived.get() > 0.01) {
                    log.error("!!! WARNING: Error rate > 1% ({:.2f}%). Check logs for details!",
                            (double) errors / totalReceived.get() * 100);
                }
            }

        } catch (Exception e) {
            totalErrors.incrementAndGet();
            log.error("Error processing candle for {}", candle.getFigi(), e);
        }
    }

    /**
     * Асинхронная вставка свечи в БД
     * 
     * <p>
     * Быстрая неблокирующая вставка с использованием INSERT...ON CONFLICT. Выполняется один запрос
     * вместо двух для максимальной производительности.
     * </p>
     * <p>
     * Каждая операция увеличивает totalInserted (включая UPDATE), т.к. невозможно определить INSERT
     * vs UPDATE без дополнительного запроса. Для получения реального количества уникальных свечей
     * используйте метод {@link #getActualCandleCount()}.
     * </p>
     */
    private void insertCandleAsync(MinuteCandleDto dto) {
        insertExecutor.submit(() -> {
            try {
                insertSemaphore.acquire();

                java.sql.Timestamp ts = java.sql.Timestamp.valueOf(dto.getTime().atZone(TimeZoneUtils.getMoscowZone()).toLocalDateTime());

                // Быстрая вставка одним запросом (INSERT или UPDATE)
                final String sql = "INSERT INTO invest.minute_candles "
                        + "(figi, time, open, high, low, close, volume, is_complete, "
                        + "price_change, price_change_percent, candle_type, body_size, "
                        + "upper_shadow, lower_shadow, high_low_range, average_price) "
                        + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) "
                        + "ON CONFLICT (figi, time) DO UPDATE SET "
                        + "open = EXCLUDED.open, high = EXCLUDED.high, low = EXCLUDED.low, "
                        + "close = EXCLUDED.close, volume = EXCLUDED.volume, "
                        + "is_complete = EXCLUDED.is_complete, "
                        + "price_change = EXCLUDED.price_change, "
                        + "price_change_percent = EXCLUDED.price_change_percent, "
                        + "candle_type = EXCLUDED.candle_type, "
                        + "body_size = EXCLUDED.body_size, "
                        + "upper_shadow = EXCLUDED.upper_shadow, "
                        + "lower_shadow = EXCLUDED.lower_shadow, "
                        + "high_low_range = EXCLUDED.high_low_range, "
                        + "average_price = EXCLUDED.average_price, " + "updated_at = CURRENT_TIMESTAMP";

                streamJdbcTemplate.update(sql, dto.getFigi(), ts, dto.getOpen(),
                        dto.getHigh(), dto.getLow(), dto.getClose(), dto.getVolume(),
                        dto.isComplete(), dto.getPriceChange().doubleValue(),
                        dto.getPriceChangePercent().doubleValue(), dto.getCandleType(),
                        dto.getBodySize(), dto.getUpperShadow(), dto.getLowerShadow(),
                        dto.getHighLowRange().doubleValue(), dto.getAveragePrice().doubleValue());

                // Увеличиваем счетчик успешных операций
                totalInserted.incrementAndGet();

            } catch (Exception e) {
                totalErrors.incrementAndGet();
                log.error("Error inserting/updating candle for FIGI: {}, Time: {} - Error: {}",
                        dto.getFigi(), dto.getTime(), e.getMessage());
            } finally {
                insertSemaphore.release();
            }
        });
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
     * Получить реальное количество уникальных свечей в БД за сегодня
     * 
     * @return количество уникальных записей в таблице minute_candles за текущий день
     */
    public long getActualCandleCount() {
        try {
            String sql = "SELECT COUNT(*) FROM invest.minute_candles "
                    + "WHERE time >= CURRENT_DATE AND time < CURRENT_DATE + INTERVAL '1 day'";
            Long count = streamJdbcTemplate.queryForObject(sql, Long.class);
            return count != null ? count : 0L;
        } catch (Exception e) {
            log.error("Error getting actual candle count: {}", e.getMessage());
            return 0L;
        }
    }

    /**
     * Получить статистику сервиса
     */
    public CandleStreamingStats getStats() {
        long actualCount = getActualCandleCount();
        return new CandleStreamingStats(isRunning.get(), isConnected.get(), totalReceived.get(),
                totalInserted.get(), actualCount, totalErrors.get(),
                insertSemaphore.availablePermits(), MAX_CONCURRENT_INSERTS);
    }

    /**
     * Завершение работы сервиса
     */
    @PreDestroy
    public void shutdown() {
        log.info("Shutting down CandleStreamingService...");

        long pendingBeforeShutdown = totalReceived.get() - totalInserted.get() - totalErrors.get();
        log.warn("Pending operations before shutdown: {}", pendingBeforeShutdown);

        if (isRunning.get()) {
            try {
                stopCandleSubscription();
            } catch (Exception e) {
                log.warn("Error during shutdown", e);
            }
        }

        insertExecutor.shutdown();
        try {
            // Увеличиваем таймаут до 60 секунд для корректного завершения всех операций
            if (!insertExecutor.awaitTermination(60, java.util.concurrent.TimeUnit.SECONDS)) {
                log.error("ExecutorService did not terminate in time. Forcing shutdown...");
                List<Runnable> droppedTasks = insertExecutor.shutdownNow();
                log.error("Dropped {} tasks during forced shutdown", droppedTasks.size());
            } else {
                long pendingAfterShutdown =
                        totalReceived.get() - totalInserted.get() - totalErrors.get();
                log.info("Graceful shutdown completed. Remaining pending: {}",
                        pendingAfterShutdown);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.error("Interrupted during shutdown", e);
            insertExecutor.shutdownNow();
        }

        log.info(
                "CandleStreamingService shutdown completed - Received: {}, Processed: {}, Errors: {}",
                totalReceived.get(), totalInserted.get(), totalErrors.get());
    }

    /**
     * Статистика сервиса подписки на свечи
     */
    public static class CandleStreamingStats {
        private final boolean isRunning;
        private final boolean isConnected;
        private final long totalReceived;
        private final long totalProcessed; // Всего обработано (INSERT + UPDATE)
        private final long actualCandleCount; // Реальное количество уникальных свечей в БД за
                                              // сегодня
        private final long totalErrors;
        private final int availableInserts;
        private final int maxConcurrentInserts;

        public CandleStreamingStats(boolean isRunning, boolean isConnected, long totalReceived,
                long totalProcessed, long actualCandleCount, long totalErrors, int availableInserts,
                int maxConcurrentInserts) {
            this.isRunning = isRunning;
            this.isConnected = isConnected;
            this.totalReceived = totalReceived;
            this.totalProcessed = totalProcessed;
            this.actualCandleCount = actualCandleCount;
            this.totalErrors = totalErrors;
            this.availableInserts = availableInserts;
            this.maxConcurrentInserts = maxConcurrentInserts;
        }

        public boolean isRunning() {
            return isRunning;
        }

        public boolean isConnected() {
            return isConnected;
        }

        public long getTotalReceived() {
            return totalReceived;
        }

        public long getTotalProcessed() {
            return totalProcessed;
        }

        public long getActualCandleCount() {
            return actualCandleCount;
        }

        public long getTotalErrors() {
            return totalErrors;
        }

        public int getAvailableInserts() {
            return availableInserts;
        }

        public int getMaxConcurrentInserts() {
            return maxConcurrentInserts;
        }

        public long getPendingOperations() {
            return totalReceived - totalProcessed - totalErrors;
        }

        public double getInsertUtilization() {
            return maxConcurrentInserts > 0
                    ? (double) (maxConcurrentInserts - availableInserts) / maxConcurrentInserts
                    : 0.0;
        }

        public double getErrorRate() {
            long total = totalProcessed + totalErrors;
            return total > 0 ? (double) totalErrors / total : 0.0;
        }
    }
}

