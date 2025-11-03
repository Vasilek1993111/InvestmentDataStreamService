package com.example.investmentdatastreamservice.service.streaming.processor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import com.example.investmentdatastreamservice.entity.MinuteCandleEntity;
import com.example.investmentdatastreamservice.service.streaming.StreamingMetrics;

import ru.tinkoff.piapi.contract.v1.Candle;

/**
 * Процессор для обработки минутных свечей
 * 
 * Высокопроизводительная обработка минутных свечей с асинхронным сохранением
 * в базу данных и детальным мониторингом производительности.
 */
@Component
public class CandleProcessor implements DataProcessor<Candle> {
    
    private static final Logger log = LoggerFactory.getLogger(CandleProcessor.class);
    
    private final JdbcTemplate streamJdbcTemplate;
    private final StreamingMetrics metrics;
    private final ExecutorService insertExecutor;
    private final Semaphore insertSemaphore;
    
    // Конфигурация производительности
    private static final int INSERT_THREADS = Runtime.getRuntime().availableProcessors() * 4;
    private static final int MAX_CONCURRENT_INSERTS = 200;
    
    public CandleProcessor(@Qualifier("streamJdbcTemplate") JdbcTemplate streamJdbcTemplate) {
        this.streamJdbcTemplate = streamJdbcTemplate;
        this.metrics = new StreamingMetrics("CandleProcessor");
        this.insertExecutor = Executors.newFixedThreadPool(INSERT_THREADS, r -> {
            Thread t = new Thread(r, "candle-insert-" + System.currentTimeMillis());
            t.setDaemon(true);
            return t;
        });
        this.insertSemaphore = new Semaphore(MAX_CONCURRENT_INSERTS);
    }
    
    @Override
    public CompletableFuture<Void> process(Candle candle) {
        return CompletableFuture.runAsync(() -> {
            try {
                metrics.incrementReceived();
                
                // Создаем MinuteCandleEntity для сохранения
                MinuteCandleEntity entity = createCandleEntity(candle);
                
                // Асинхронное сохранение
                insertCandleDataAsync(entity);
                
                // Логирование каждые 100 записей
                if (metrics.getTotalReceived() % 100 == 0) {
                    log.info("Candle processing: {}", metrics);
                }
                
            } catch (Exception e) {
                metrics.incrementErrors();
                log.error("Error processing Candle for FIGI: {}", candle.getFigi(), e);
            }
        });
    }
    
    @Override
    public void handleError(Throwable error) {
        metrics.incrementErrors();
        log.error("Candle processor error", error);
    }
    
    /**
     * Создание MinuteCandleEntity из Candle
     */
    private MinuteCandleEntity createCandleEntity(Candle candle) {
        Instant eventInstant = Instant.ofEpochSecond(
            candle.getTime().getSeconds(), 
            candle.getTime().getNanos()
        );
        
        BigDecimal open = convertQuotationToBigDecimal(candle.getOpen());
        BigDecimal high = convertQuotationToBigDecimal(candle.getHigh());
        BigDecimal low = convertQuotationToBigDecimal(candle.getLow());
        BigDecimal close = convertQuotationToBigDecimal(candle.getClose());
        
        return new MinuteCandleEntity(
            candle.getFigi(),
            candle.getVolume(),
            high,
            low,
            eventInstant,
            close,
            open,
            true  // isComplete
        );
    }
    
    /**
     * Конвертирует Quotation в BigDecimal
     */
    private BigDecimal convertQuotationToBigDecimal(ru.tinkoff.piapi.contract.v1.Quotation quotation) {
        return BigDecimal.valueOf(quotation.getUnits())
            .add(BigDecimal.valueOf(quotation.getNano()).movePointLeft(9));
    }
    
    /**
     * Асинхронная вставка данных в базу
     */
    private void insertCandleDataAsync(MinuteCandleEntity entity) {
        if (!insertSemaphore.tryAcquire()) {
            metrics.incrementDropped();
            log.warn("Too many concurrent inserts, dropping Candle for {}", entity.getFigi());
            return;
        }
        
        insertExecutor.submit(() -> {
            try {
                final String sql = """
                    INSERT INTO invest.minute_candles 
                    (figi, time, open, high, low, close, volume, is_complete, 
                    price_change, price_change_percent, candle_type, body_size, 
                    upper_shadow, lower_shadow, high_low_range, average_price, 
                    created_at, updated_at) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) 
                    ON CONFLICT (figi, time) DO UPDATE SET 
                    open = EXCLUDED.open, high = EXCLUDED.high, low = EXCLUDED.low, 
                    close = EXCLUDED.close, volume = EXCLUDED.volume, 
                    is_complete = EXCLUDED.is_complete, 
                    price_change = EXCLUDED.price_change, 
                    price_change_percent = EXCLUDED.price_change_percent, 
                    candle_type = EXCLUDED.candle_type, 
                    body_size = EXCLUDED.body_size, 
                    upper_shadow = EXCLUDED.upper_shadow, 
                    lower_shadow = EXCLUDED.lower_shadow, 
                    high_low_range = EXCLUDED.high_low_range, 
                    average_price = EXCLUDED.average_price, 
                    updated_at = EXCLUDED.updated_at
                    """;
                
                java.sql.Timestamp ts = java.sql.Timestamp.from(entity.getTime());
                java.sql.Timestamp createdAt = java.sql.Timestamp.from(entity.getCreatedAt());
                java.sql.Timestamp updatedAt = java.sql.Timestamp.from(entity.getUpdatedAt());
                
                streamJdbcTemplate.update(sql,
                    entity.getFigi(),
                    ts,
                    entity.getOpen(),
                    entity.getHigh(),
                    entity.getLow(),
                    entity.getClose(),
                    entity.getVolume(),
                    entity.isComplete(),
                    entity.getPriceChange(),
                    entity.getPriceChangePercent(),
                    entity.getCandleType(),
                    entity.getBodySize(),
                    entity.getUpperShadow(),
                    entity.getLowerShadow(),
                    entity.getHighLowRange(),
                    entity.getAveragePrice(),
                    createdAt,
                    updatedAt
                );
                
                metrics.incrementProcessed();
                
                // Детальное логирование каждой свечи
                log.info("✅ CANDLE → DB: FIGI={}, Time={}, O={}, H={}, L={}, C={}, Vol={}, Type={}", 
                    entity.getFigi(), 
                    ts, 
                    entity.getOpen(), 
                    entity.getHigh(), 
                    entity.getLow(), 
                    entity.getClose(), 
                    entity.getVolume(),
                    entity.getCandleType());
                
            } catch (Exception e) {
                metrics.incrementErrors();
                log.error("❌ Error inserting Candle for FIGI={}, Time={}: {}", 
                    entity.getFigi(), entity.getTime(), e.getMessage(), e);
            } finally {
                insertSemaphore.release();
            }
        });
    }
    
    /**
     * Получение метрик процессора
     */
    public StreamingMetrics getMetrics() {
        return metrics;
    }
    
    /**
     * Завершение работы процессора
     */
    public void shutdown() {
        log.info("Shutting down CandleProcessor...");
        
        insertExecutor.shutdown();
        try {
            if (!insertExecutor.awaitTermination(30, java.util.concurrent.TimeUnit.SECONDS)) {
                insertExecutor.shutdownNow();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            insertExecutor.shutdownNow();
        }
        
        log.info("CandleProcessor shutdown completed: {}", metrics);
    }
}

