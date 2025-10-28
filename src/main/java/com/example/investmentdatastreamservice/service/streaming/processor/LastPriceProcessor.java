package com.example.investmentdatastreamservice.service.streaming.processor;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;
import java.util.concurrent.atomic.AtomicLong;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import com.example.investmentdatastreamservice.entity.TradeEntity;
import com.example.investmentdatastreamservice.service.streaming.StreamingMetrics;

import ru.tinkoff.piapi.contract.v1.LastPrice;

/**
 * Процессор для обработки данных LastPrice
 * 
 * Высокопроизводительная обработка цен последних сделок с асинхронным сохранением
 * в базу данных и детальным мониторингом производительности.
 */
@Component
public class LastPriceProcessor implements DataProcessor<LastPrice> {
    
    private static final Logger log = LoggerFactory.getLogger(LastPriceProcessor.class);
    
    private final JdbcTemplate streamJdbcTemplate;
    private final StreamingMetrics metrics;
    private final ExecutorService insertExecutor;
    private final Semaphore insertSemaphore;
    
    // Конфигурация производительности
    private static final int INSERT_THREADS = Runtime.getRuntime().availableProcessors() * 4;
    private static final int MAX_CONCURRENT_INSERTS = 100;
    
    // Счетчики по типам инструментов
    private final AtomicLong sharesProcessed = new AtomicLong(0);
    private final AtomicLong futuresProcessed = new AtomicLong(0);
    private final AtomicLong indicativesProcessed = new AtomicLong(0);
    
    public LastPriceProcessor(@Qualifier("streamJdbcTemplate") JdbcTemplate streamJdbcTemplate) {
        this.streamJdbcTemplate = streamJdbcTemplate;
        this.metrics = new StreamingMetrics("LastPriceProcessor");
        this.insertExecutor = Executors.newFixedThreadPool(INSERT_THREADS, r -> {
            Thread t = new Thread(r, "lastprice-insert-" + System.currentTimeMillis());
            t.setDaemon(true);
            return t;
        });
        this.insertSemaphore = new Semaphore(MAX_CONCURRENT_INSERTS);
    }
    
    @Override
    public CompletableFuture<Void> process(LastPrice lastPrice) {
        return CompletableFuture.runAsync(() -> {
            try {
                metrics.incrementReceived();
                
                // Создаем TradeEntity для сохранения
                TradeEntity entity = createTradeEntity(lastPrice);
                
                // Асинхронное сохранение
                insertTradeDataAsync(entity);
                
                // Обновляем счетчики по типам инструментов
                updateInstrumentCounters(lastPrice.getFigi());
                
                // Логирование каждые 100 записей
                if (metrics.getTotalReceived() % 100 == 0) {
                    log.info("LastPrice processing: {}", metrics);
                }
                
            } catch (Exception e) {
                metrics.incrementErrors();
                log.error("Error processing LastPrice for FIGI: {}", lastPrice.getFigi(), e);
            }
        });
    }
    
    @Override
    public void handleError(Throwable error) {
        metrics.incrementErrors();
        log.error("LastPrice processor error", error);
    }
    
    /**
     * Создание TradeEntity из LastPrice
     */
    private TradeEntity createTradeEntity(LastPrice lastPrice) {
        java.time.Instant eventInstant = java.time.Instant.ofEpochSecond(
            lastPrice.getTime().getSeconds(), 
            lastPrice.getTime().getNanos()
        );
        
        java.time.LocalDateTime eventTime = java.time.LocalDateTime.ofInstant(
            eventInstant, 
            java.time.ZoneOffset.of("+3")
        );
        
        java.math.BigDecimal priceValue = java.math.BigDecimal.valueOf(lastPrice.getPrice().getUnits())
            .add(java.math.BigDecimal.valueOf(lastPrice.getPrice().getNano()).movePointLeft(9));
        
        return new TradeEntity(
            lastPrice.getFigi(),
            eventTime,
            "LAST_PRICE",
            priceValue,
            1L, // Количество = 1 для LastPrice
            "RUB",
            "MOEX",
            "LAST_PRICE"
        );
    }
    
    /**
     * Асинхронная вставка данных в базу
     */
    private void insertTradeDataAsync(TradeEntity entity) {
        if (!insertSemaphore.tryAcquire()) {
            metrics.incrementDropped();
            log.warn("Too many concurrent inserts, dropping LastPrice for {}", entity.getId().getFigi());
            return;
        }
        
        insertExecutor.submit(() -> {
            try {
                final String sql = """
                    INSERT INTO invest.trades 
                    (figi, time, direction, price, quantity, currency, exchange, trade_source, trade_direction) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) 
                    ON CONFLICT (figi, time, direction) DO UPDATE SET 
                    price = EXCLUDED.price, quantity = EXCLUDED.quantity, 
                    currency = EXCLUDED.currency, exchange = EXCLUDED.exchange, 
                    trade_source = EXCLUDED.trade_source, trade_direction = EXCLUDED.trade_direction
                    """;
                
                java.sql.Timestamp ts = java.sql.Timestamp.valueOf(entity.getId().getTime());
                
                streamJdbcTemplate.update(sql,
                    entity.getId().getFigi(),
                    ts,
                    entity.getId().getDirection(),
                    entity.getPrice(),
                    entity.getQuantity(),
                    entity.getCurrency(),
                    entity.getExchange(),
                    entity.getTradeSource(),
                    entity.getTradeDirection()
                );
                
                metrics.incrementProcessed();
                
            } catch (Exception e) {
                metrics.incrementErrors();
                log.error("Error inserting LastPrice for {}", entity.getId().getFigi(), e);
            } finally {
                insertSemaphore.release();
            }
        });
    }
    
    /**
     * Обновление счетчиков по типам инструментов
     */
    private void updateInstrumentCounters(String figi) {
        // Здесь можно добавить логику определения типа инструмента
        // Пока просто увеличиваем общий счетчик
        // В реальной реализации можно использовать кэш типов инструментов
    }
    
    /**
     * Получение метрик процессора
     */
    public StreamingMetrics getMetrics() {
        return metrics;
    }
    
    /**
     * Получение детализированных метрик
     */
    public LastPriceMetrics getDetailedMetrics() {
        return new LastPriceMetrics(
            metrics.getTotalReceived(),
            metrics.getTotalProcessed(),
            metrics.getTotalErrors(),
            metrics.getTotalDropped(),
            sharesProcessed.get(),
            futuresProcessed.get(),
            indicativesProcessed.get(),
            insertSemaphore.availablePermits(),
            MAX_CONCURRENT_INSERTS
        );
    }
    
    /**
     * Завершение работы процессора
     */
    public void shutdown() {
        log.info("Shutting down LastPriceProcessor...");
        
        insertExecutor.shutdown();
        try {
            if (!insertExecutor.awaitTermination(30, java.util.concurrent.TimeUnit.SECONDS)) {
                insertExecutor.shutdownNow();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            insertExecutor.shutdownNow();
        }
        
        log.info("LastPriceProcessor shutdown completed: {}", metrics);
    }
    
    /**
     * Детализированные метрики для LastPrice
     */
    public static class LastPriceMetrics {
        private final long totalReceived;
        private final long totalProcessed;
        private final long totalErrors;
        private final long totalDropped;
        private final long sharesProcessed;
        private final long futuresProcessed;
        private final long indicativesProcessed;
        private final int availableInserts;
        private final int maxConcurrentInserts;
        
        public LastPriceMetrics(long totalReceived, long totalProcessed, long totalErrors, 
                              long totalDropped, long sharesProcessed, long futuresProcessed, 
                              long indicativesProcessed, int availableInserts, int maxConcurrentInserts) {
            this.totalReceived = totalReceived;
            this.totalProcessed = totalProcessed;
            this.totalErrors = totalErrors;
            this.totalDropped = totalDropped;
            this.sharesProcessed = sharesProcessed;
            this.futuresProcessed = futuresProcessed;
            this.indicativesProcessed = indicativesProcessed;
            this.availableInserts = availableInserts;
            this.maxConcurrentInserts = maxConcurrentInserts;
        }
        
        // Getters
        public long getTotalReceived() { return totalReceived; }
        public long getTotalProcessed() { return totalProcessed; }
        public long getTotalErrors() { return totalErrors; }
        public long getTotalDropped() { return totalDropped; }
        public long getSharesProcessed() { return sharesProcessed; }
        public long getFuturesProcessed() { return futuresProcessed; }
        public long getIndicativesProcessed() { return indicativesProcessed; }
        public int getAvailableInserts() { return availableInserts; }
        public int getMaxConcurrentInserts() { return maxConcurrentInserts; }
        
        public double getInsertUtilization() {
            return maxConcurrentInserts > 0 
                ? (double) (maxConcurrentInserts - availableInserts) / maxConcurrentInserts 
                : 0.0;
        }
    }
}
