package com.example.investmentdatastreamservice.service.streaming;

import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Утилита для разделения инструментов на батчи для подписки
 * 
 * API ограничивает 300 подписок на один stream (свечи + стаканы + ленты обезличенных сделок).
 * Этот класс разделяет инструменты на батчи, чтобы не превышать лимит.
 */
public class SubscriptionBatcher {
    
    private static final Logger log = LoggerFactory.getLogger(SubscriptionBatcher.class);
    
    /**
     * Безопасный размер батча (меньше лимита API в 300)
     */
    public static final int DEFAULT_BATCH_SIZE = 250;
    
    /**
     * Максимальное количество запросов подписки в минуту
     */
    public static final int MAX_REQUESTS_PER_MINUTE = 100;
    
    /**
     * Задержка между батчами в миллисекундах (для соблюдения rate limit)
     */
    public static final long BATCH_DELAY_MS = 1000; // 1 секунда между батчами
    
    private final int batchSize;
    
    public SubscriptionBatcher() {
        this(DEFAULT_BATCH_SIZE);
    }
    
    public SubscriptionBatcher(int batchSize) {
        if (batchSize <= 0 || batchSize > 300) {
            throw new IllegalArgumentException("Batch size must be between 1 and 300, got: " + batchSize);
        }
        this.batchSize = batchSize;
        log.info("SubscriptionBatcher initialized with batch size: {}", batchSize);
    }
    
    /**
     * Разделяет список инструментов на батчи
     * 
     * @param instruments список FIGI инструментов
     * @return список батчей
     */
    public List<List<String>> createBatches(List<String> instruments) {
        if (instruments == null || instruments.isEmpty()) {
            log.warn("Empty instruments list provided");
            return new ArrayList<>();
        }
        
        List<List<String>> batches = new ArrayList<>();
        int totalInstruments = instruments.size();
        int batchCount = (int) Math.ceil((double) totalInstruments / batchSize);
        
        log.info("Creating {} batches for {} instruments (batch size: {})", 
            batchCount, totalInstruments, batchSize);
        
        for (int i = 0; i < totalInstruments; i += batchSize) {
            int endIndex = Math.min(i + batchSize, totalInstruments);
            List<String> batch = instruments.subList(i, endIndex);
            batches.add(new ArrayList<>(batch));
            
            log.debug("Batch {}/{}: {} instruments", 
                batches.size(), batchCount, batch.size());
        }
        
        log.info("Created {} batches successfully", batches.size());
        return batches;
    }
    
    /**
     * Получает информацию о батчах для логирования
     */
    public BatchInfo getBatchInfo(List<String> instruments) {
        int totalInstruments = instruments.size();
        int batchCount = (int) Math.ceil((double) totalInstruments / batchSize);
        return new BatchInfo(totalInstruments, batchCount, batchSize);
    }
    
    /**
     * Информация о батчах
     */
    public static class BatchInfo {
        private final int totalInstruments;
        private final int batchCount;
        private final int batchSize;
        
        public BatchInfo(int totalInstruments, int batchCount, int batchSize) {
            this.totalInstruments = totalInstruments;
            this.batchCount = batchCount;
            this.batchSize = batchSize;
        }
        
        public int getTotalInstruments() {
            return totalInstruments;
        }
        
        public int getBatchCount() {
            return batchCount;
        }
        
        public int getBatchSize() {
            return batchSize;
        }
        
        @Override
        public String toString() {
            return String.format("BatchInfo[total=%d, batches=%d, size=%d]", 
                totalInstruments, batchCount, batchSize);
        }
    }
}

