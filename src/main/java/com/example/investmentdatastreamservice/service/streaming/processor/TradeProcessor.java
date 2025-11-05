package com.example.investmentdatastreamservice.service.streaming.processor;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;
import java.util.concurrent.atomic.AtomicLong;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import com.example.investmentdatastreamservice.entity.TradeEntity;
import com.example.investmentdatastreamservice.service.streaming.StreamingMetrics;

import ru.tinkoff.piapi.contract.v1.Trade;
import ru.tinkoff.piapi.contract.v1.TradeDirection;

import java.sql.Date;
import java.time.LocalDate;

/**
 * Процессор для обработки данных Trade (обезличенных сделок)
 * 
 * Высокопроизводительная обработка обезличенных сделок с асинхронным сохранением
 * в базу данных, детальным мониторингом и оптимизацией для высокочастотных данных.
 */
@Component
public class TradeProcessor implements DataProcessor<Trade> {
    
    private static final Logger log = LoggerFactory.getLogger(TradeProcessor.class);
    
    private final JdbcTemplate streamJdbcTemplate;
    private final StreamingMetrics metrics;
    private final ExecutorService insertExecutor;
    private final Semaphore insertSemaphore;
    
    // Конфигурация производительности
    private static final int INSERT_THREADS = Runtime.getRuntime().availableProcessors() * 6;
    private static final int MAX_CONCURRENT_INSERTS = 200;
    
    // Счетчики по типам инструментов
    private final AtomicLong sharesProcessed = new AtomicLong(0);
    private final AtomicLong futuresProcessed = new AtomicLong(0);
    private final AtomicLong indicativesProcessed = new AtomicLong(0);
    
    // Счетчики по направлениям сделок
    private final AtomicLong buyTradesProcessed = new AtomicLong(0);
    private final AtomicLong sellTradesProcessed = new AtomicLong(0);
    
    public TradeProcessor(@Qualifier("streamJdbcTemplate") JdbcTemplate streamJdbcTemplate) {
        this.streamJdbcTemplate = streamJdbcTemplate;
        this.metrics = new StreamingMetrics("TradeProcessor");
        this.insertExecutor = Executors.newFixedThreadPool(INSERT_THREADS, r -> {
            Thread t = new Thread(r, "trade-insert-" + System.currentTimeMillis());
            t.setDaemon(true);
            return t;
        });
        this.insertSemaphore = new Semaphore(MAX_CONCURRENT_INSERTS);
    }
    
    @Override
    public CompletableFuture<Void> process(Trade trade) {
        return CompletableFuture.runAsync(() -> {
            try {
                metrics.incrementReceived();
                
                // Создаем TradeEntity для сохранения
                TradeEntity entity = createTradeEntity(trade);
                
                // Асинхронное сохранение
                insertTradeDataAsync(entity);
                
                // Обновляем счетчики
                updateCounters(trade);
                
                // Логирование каждые 1000 записей
                if (metrics.getTotalReceived() % 1000 == 0) {
                    log.info("Trade processing: {}", metrics);
                }
                
            } catch (Exception e) {
                metrics.incrementErrors();
                log.error("Error processing Trade for FIGI: {}", trade.getFigi(), e);
            }
        });
    }
    
    @Override
    public void handleError(Throwable error) {
        metrics.incrementErrors();
        log.error("Trade processor error", error);
    }
    
    /**
     * Создание TradeEntity из Trade
     */
    private TradeEntity createTradeEntity(Trade trade) {
        java.time.Instant eventInstant = java.time.Instant.ofEpochSecond(
            trade.getTime().getSeconds(), 
            trade.getTime().getNanos()
        );
        
        java.time.LocalDateTime eventTime = java.time.LocalDateTime.ofInstant(
            eventInstant, 
            java.time.ZoneOffset.of("+3")
        );
        
        java.math.BigDecimal priceValue = java.math.BigDecimal.valueOf(trade.getPrice().getUnits())
            .add(java.math.BigDecimal.valueOf(trade.getPrice().getNano()).movePointLeft(9));
        
        // Определяем направление сделки
        String direction = trade.getDirection() == TradeDirection.TRADE_DIRECTION_BUY ? "BUY" : "SELL";
        
        return new TradeEntity(
            trade.getFigi(),
            eventTime,
            direction,
            priceValue,
            trade.getQuantity(),
            "RUB",
            "MOEX",
            "EXCHANGE"
        );
    }
    
    /**
     * Асинхронная вставка данных в базу
     */
    private void insertTradeDataAsync(TradeEntity entity) {
        if (!insertSemaphore.tryAcquire()) {
            metrics.incrementDropped();
            log.warn("Too many concurrent inserts, dropping Trade for {}", entity.getId().getFigi());
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
                
                try {
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
                    
                    // Детальное логирование каждой сделки
                    log.info("🔄 TRADE → DB: FIGI={}, Time={}, Direction={}, Price={}, Qty={}", 
                        entity.getId().getFigi(), 
                        ts, 
                        entity.getId().getDirection(),
                        entity.getPrice(), 
                        entity.getQuantity());
                        
                } catch (DataIntegrityViolationException e) {
                    // Проверяем, является ли ошибка связанной с отсутствием партиции
                    String errorMessage = e.getMessage();
                    Throwable cause = e.getCause();
                    // Проверяем как основное сообщение, так и причину (PSQLException)
                    boolean isPartitionError = (errorMessage != null && errorMessage.contains("no partition")) ||
                                              (cause != null && cause.getMessage() != null && cause.getMessage().contains("no partition"));
                    
                    if (isPartitionError) {
                        // Извлекаем дату из timestamp и создаем партицию
                        LocalDate partitionDate = entity.getId().getTime().toLocalDate();
                        log.warn("⚠️ Partition not found for date {}, creating partition...", partitionDate);
                        
                        try {
                            // Создаем партицию через функцию БД (функция уже проверяет существование)
                            String createPartitionSql = "SELECT invest_utils.create_trades_partition(?)";
                            String result = streamJdbcTemplate.queryForObject(createPartitionSql, String.class, Date.valueOf(partitionDate));
                            log.info("✅ Partition creation result for date {}: {}", partitionDate, result);
                            
                            // Повторяем попытку вставки после создания партиции
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
                            log.info("🔄 TRADE → DB (retry): FIGI={}, Time={}, Direction={}, Price={}, Qty={}", 
                                entity.getId().getFigi(), 
                                ts, 
                                entity.getId().getDirection(),
                                entity.getPrice(), 
                                entity.getQuantity());
                        } catch (Exception retryException) {
                            metrics.incrementErrors();
                            log.error("❌ Error creating partition or retrying insert for FIGI={}, Time={}: {}", 
                                entity.getId().getFigi(), entity.getId().getTime(), retryException.getMessage(), retryException);
                            throw retryException;
                        }
                    } else {
                        // Другая ошибка целостности данных
                        metrics.incrementErrors();
                        log.error("❌ Data integrity error inserting Trade for FIGI={}, Time={}: {}", 
                            entity.getId().getFigi(), entity.getId().getTime(), e.getMessage(), e);
                        throw e;
                    }
                }
                
            } catch (Exception e) {
                metrics.incrementErrors();
                log.error("❌ Error inserting Trade for FIGI={}, Time={}: {}", 
                    entity.getId().getFigi(), entity.getId().getTime(), e.getMessage(), e);
            } finally {
                insertSemaphore.release();
            }
        });
    }
    
    /**
     * Обновление счетчиков
     */
    private void updateCounters(Trade trade) {
        // Обновляем счетчики по направлениям
        if (trade.getDirection() == TradeDirection.TRADE_DIRECTION_BUY) {
            buyTradesProcessed.incrementAndGet();
        } else {
            sellTradesProcessed.incrementAndGet();
        }
        
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
    public TradeMetrics getDetailedMetrics() {
        return new TradeMetrics(
            metrics.getTotalReceived(),
            metrics.getTotalProcessed(),
            metrics.getTotalErrors(),
            metrics.getTotalDropped(),
            sharesProcessed.get(),
            futuresProcessed.get(),
            indicativesProcessed.get(),
            buyTradesProcessed.get(),
            sellTradesProcessed.get(),
            insertSemaphore.availablePermits(),
            MAX_CONCURRENT_INSERTS
        );
    }
    
    /**
     * Завершение работы процессора
     */
    public void shutdown() {
        log.info("Shutting down TradeProcessor...");
        
        insertExecutor.shutdown();
        try {
            if (!insertExecutor.awaitTermination(30, java.util.concurrent.TimeUnit.SECONDS)) {
                insertExecutor.shutdownNow();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            insertExecutor.shutdownNow();
        }
        
        log.info("TradeProcessor shutdown completed: {}", metrics);
    }
    
    /**
     * Детализированные метрики для Trade
     */
    public static class TradeMetrics {
        private final long totalReceived;
        private final long totalProcessed;
        private final long totalErrors;
        private final long totalDropped;
        private final long sharesProcessed;
        private final long futuresProcessed;
        private final long indicativesProcessed;
        private final long buyTradesProcessed;
        private final long sellTradesProcessed;
        private final int availableInserts;
        private final int maxConcurrentInserts;
        
        public TradeMetrics(long totalReceived, long totalProcessed, long totalErrors, 
                           long totalDropped, long sharesProcessed, long futuresProcessed, 
                           long indicativesProcessed, long buyTradesProcessed, long sellTradesProcessed,
                           int availableInserts, int maxConcurrentInserts) {
            this.totalReceived = totalReceived;
            this.totalProcessed = totalProcessed;
            this.totalErrors = totalErrors;
            this.totalDropped = totalDropped;
            this.sharesProcessed = sharesProcessed;
            this.futuresProcessed = futuresProcessed;
            this.indicativesProcessed = indicativesProcessed;
            this.buyTradesProcessed = buyTradesProcessed;
            this.sellTradesProcessed = sellTradesProcessed;
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
        public long getBuyTradesProcessed() { return buyTradesProcessed; }
        public long getSellTradesProcessed() { return sellTradesProcessed; }
        public int getAvailableInserts() { return availableInserts; }
        public int getMaxConcurrentInserts() { return maxConcurrentInserts; }
        
        public double getInsertUtilization() {
            return maxConcurrentInserts > 0 
                ? (double) (maxConcurrentInserts - availableInserts) / maxConcurrentInserts 
                : 0.0;
        }
        
        public double getBuySellRatio() {
            long total = buyTradesProcessed + sellTradesProcessed;
            return total > 0 ? (double) buyTradesProcessed / total : 0.0;
        }
    }
}







