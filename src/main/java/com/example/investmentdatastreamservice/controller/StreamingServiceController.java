package com.example.investmentdatastreamservice.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.example.investmentdatastreamservice.service.MarketDataStreamingService;
import com.example.investmentdatastreamservice.service.MarketDataStreamingService.ServiceStats;

/**
 * REST контроллер для мониторинга и управления потоковым сервисом
 * 
 * Предоставляет endpoints для мониторинга производительности и управления потоковым сервисом
 * данных.
 */
@RestController
@RequestMapping("/api/streaming-service")
public class StreamingServiceController {

    private final MarketDataStreamingService streamingService;

    public StreamingServiceController(MarketDataStreamingService streamingService) {
        this.streamingService = streamingService;
    }

    /**
     * Получить статистику производительности потокового сервиса
     * 
     * @return статистика сервиса
     */
    @GetMapping("/stats")
    public ResponseEntity<ObjectStats> getServiceStats() {
        ServiceStats stats = streamingService.getServiceStats();
        ObjectStats objectStats = new ObjectStats(stats);
        return ResponseEntity.ok(objectStats);
    }

    /**
     * Принудительное переподключение к T-Invest API
     * 
     * @return HTTP 200 OK при успешном запросе переподключения
     */
    @PostMapping("/reconnect")
    public ResponseEntity<Void> forceReconnect() {
        streamingService.forceReconnect();
        return ResponseEntity.ok().build();
    }

    /**
     * Получить состояние подключения
     * 
     * @return true если подключен к T-Invest API
     */
    @GetMapping("/status")
    public ResponseEntity<Boolean> getConnectionStatus() {
        ServiceStats stats = streamingService.getServiceStats();
        return ResponseEntity.ok(stats.isConnected());
    }

    /**
     * Получить детальную информацию о состоянии сервиса
     * 
     * @return детальная информация о сервисе
     */
    @GetMapping("/health")
    public ResponseEntity<ServiceHealth> getServiceHealth() {
        ServiceStats stats = streamingService.getServiceStats();
        ServiceHealth health = new ServiceHealth(stats.isRunning(), stats.isConnected(),
                stats.getTotalProcessedAll(), stats.getTotalErrorsAll(),
                stats.getTotalReceivedAll(), stats.getAvailableTradeInserts(),
                stats.getMaxConcurrentTradeInserts(), stats.getTradeInsertUtilization(),
                stats.getOverallErrorRate(), stats.getOverallProcessingRate());
        return ResponseEntity.ok(health);
    }



    /**
     * Детальная информация о состоянии сервиса
     */
    public static class ServiceHealth {
        private final boolean isRunning;
        private final boolean isConnected;
        private final long totalProcessed;
        private final long totalErrors;
        private final long totalReceived;
        private final int availableInserts;
        private final int maxConcurrentInserts;
        private final double insertUtilization;
        private final double errorRate;
        private final double processingRate;

        public ServiceHealth(boolean isRunning, boolean isConnected, long totalProcessed,
                long totalErrors, long totalReceived, int availableInserts,
                int maxConcurrentInserts, double insertUtilization, double errorRate,
                double processingRate) {
            this.isRunning = isRunning;
            this.isConnected = isConnected;
            this.totalProcessed = totalProcessed;
            this.totalErrors = totalErrors;
            this.totalReceived = totalReceived;
            this.availableInserts = availableInserts;
            this.maxConcurrentInserts = maxConcurrentInserts;
            this.insertUtilization = insertUtilization;
            this.errorRate = errorRate;
            this.processingRate = processingRate;
        }

        public boolean isRunning() {
            return isRunning;
        }

        public boolean isConnected() {
            return isConnected;
        }

        public long getTotalProcessed() {
            return totalProcessed;
        }

        public long getTotalErrors() {
            return totalErrors;
        }

        public long getTotalReceived() {
            return totalReceived;
        }

        public int getAvailableInserts() {
            return availableInserts;
        }

        public int getMaxConcurrentInserts() {
            return maxConcurrentInserts;
        }

        public double getInsertUtilization() {
            return insertUtilization;
        }

        public double getErrorRate() {
            return errorRate;
        }

        public double getProcessingRate() {
            return processingRate;
        }
    }


    /**
     * Статистика, сгруппированная на 4 объекта: общая, lastPrice, trades, candles
     */
    public static class ObjectStats {
        private final GeneralStats general;
        private final LastPriceStats lastPrice;
        private final TradeStats trades;
        private final CandleStats candles;

        public ObjectStats(ServiceStats stats) {
            this.general = new GeneralStats(stats);
            this.lastPrice = new LastPriceStats(stats);
            this.trades = new TradeStats(stats);
            this.candles = new CandleStats(stats);
        }

        public GeneralStats getGeneral() {
            return general;
        }

        public LastPriceStats getLastPrice() {
            return lastPrice;
        }

        public TradeStats getTrades() {
            return trades;
        }

        public CandleStats getCandles() {
            return candles;
        }

        /**
         * Общая статистика сервиса
         */
        public static class GeneralStats {
            private final boolean running;
            private final boolean connected;
            private final long totalReceived;
            private final long totalProcessed;
            private final long totalInserted;
            private final long totalErrors;
            private final double overallProcessingRate;
            private final double overallErrorRate;
            private final double tradeInsertUtilization;
            private final int availableTradeInserts;
            private final int maxConcurrentTradeInserts;

            public GeneralStats(ServiceStats stats) {
                this.running = stats.isRunning();
                this.connected = stats.isConnected();
                this.totalReceived = stats.getTotalReceivedAll();
                this.totalProcessed = stats.getTotalProcessedAll();
                this.totalInserted = stats.getTotalProcessedAll(); // same as processed for now
                this.totalErrors = stats.getTotalErrorsAll();
                this.overallProcessingRate = stats.getOverallProcessingRate();
                this.overallErrorRate = stats.getOverallErrorRate();
                this.tradeInsertUtilization = stats.getTradeInsertUtilization();
                this.availableTradeInserts = stats.getAvailableTradeInserts();
                this.maxConcurrentTradeInserts = stats.getMaxConcurrentTradeInserts();
            }

            public boolean isRunning() {
                return running;
            }

            public boolean isConnected() {
                return connected;
            }

            public long getTotalReceived() {
                return totalReceived;
            }

            public long getTotalProcessed() {
                return totalProcessed;
            }

            public long getTotalInserted() {
                return totalInserted;
            }

            public long getTotalErrors() {
                return totalErrors;
            }

            public double getOverallProcessingRate() {
                return overallProcessingRate;
            }

            public double getOverallErrorRate() {
                return overallErrorRate;
            }

            public double getTradeInsertUtilization() {
                return tradeInsertUtilization;
            }

            public int getAvailableTradeInserts() {
                return availableTradeInserts;
            }

            public int getMaxConcurrentTradeInserts() {
                return maxConcurrentTradeInserts;
            }
        }

        /**
         * Статистика по LastPrice данным
         */
        public static class LastPriceStats {
            private final long received;
            private final long processed;
            private final long inserted;
            private final long errors;
            private final double processingRate;
            private final double errorRate;
            private final long receivedShares;
            private final long receivedFutures;
            private final long receivedIndicatives;

            public LastPriceStats(ServiceStats stats) {
                this.received = stats.getTotalLastPriceReceived();
                this.processed = stats.getTotalLastPriceProcessed();
                this.inserted = stats.getTotalLastPriceInserted();
                this.errors = stats.getTotalErrorsAll();
                this.processingRate = received > 0 ? (double) processed / received : 0.0;
                this.errorRate =
                        (processed + errors) > 0 ? (double) errors / (processed + errors) : 0.0;
                this.receivedShares = stats.getTotalLastPriceReceivedShares();
                this.receivedFutures = stats.getTotalLastPriceReceivedFutures();
                this.receivedIndicatives = stats.getTotalLastPriceReceivedIndicatives();
            }

            public long getReceived() {
                return received;
            }

            public long getProcessed() {
                return processed;
            }

            public long getInserted() {
                return inserted;
            }

            public long getErrors() {
                return errors;
            }

            public double getProcessingRate() {
                return processingRate;
            }

            public double getErrorRate() {
                return errorRate;
            }

            public long getReceivedShares() {
                return receivedShares;
            }

            public long getReceivedFutures() {
                return receivedFutures;
            }

            public long getReceivedIndicatives() {
                return receivedIndicatives;
            }
        }

        /**
         * Статистика по Trade данным
         */
        public static class TradeStats {
            private final long received;
            private final long processed;
            private final long inserted;
            private final long errors;
            private final double processingRate;
            private final double errorRate;
            private final long receivedShares;
            private final long receivedFutures;
            private final long receivedIndicatives;

            public TradeStats(ServiceStats stats) {
                this.received = stats.getTotalTradeMessagesReceived();
                this.processed = stats.getTotalTradesProcessed();
                this.inserted = stats.getTotalTradesInserted();
                this.errors = stats.getTotalErrorsAll();
                this.processingRate = received > 0 ? (double) processed / received : 0.0;
                this.errorRate =
                        (processed + errors) > 0 ? (double) errors / (processed + errors) : 0.0;
                this.receivedShares = stats.getTotalTradeReceivedShares();
                this.receivedFutures = stats.getTotalTradeReceivedFutures();
                this.receivedIndicatives = stats.getTotalTradeReceivedIndicatives();
            }

            public long getReceived() {
                return received;
            }

            public long getProcessed() {
                return processed;
            }

            public long getInserted() {
                return inserted;
            }

            public long getErrors() {
                return errors;
            }

            public double getProcessingRate() {
                return processingRate;
            }

            public double getErrorRate() {
                return errorRate;
            }

            public long getReceivedShares() {
                return receivedShares;
            }

            public long getReceivedFutures() {
                return receivedFutures;
            }

            public long getReceivedIndicatives() {
                return receivedIndicatives;
            }
        }

        /**
         * Статистика по Candle данным
         */
        public static class CandleStats {
            private final long received;
            private final long processed;
            private final long inserted;
            private final long errors;
            private final double processingRate;
            private final double errorRate;
            private final long receivedShares;
            private final long receivedFutures;
            private final long receivedIndicatives;

            public CandleStats(ServiceStats stats) {
                this.received = stats.getTotalCandleMessagesReceived();
                this.processed = stats.getTotalCandlesInserted(); // candles сразу вставляются
                this.inserted = stats.getTotalCandlesInserted();
                this.errors = stats.getTotalErrorsAll();
                this.processingRate = received > 0 ? (double) processed / received : 0.0;
                this.errorRate =
                        (processed + errors) > 0 ? (double) errors / (processed + errors) : 0.0;
                this.receivedShares = stats.getTotalCandleReceivedShares();
                this.receivedFutures = stats.getTotalCandleReceivedFutures();
                this.receivedIndicatives = stats.getTotalCandleReceivedIndicatives();
            }

            public long getReceived() {
                return received;
            }

            public long getProcessed() {
                return processed;
            }

            public long getInserted() {
                return inserted;
            }

            public long getErrors() {
                return errors;
            }

            public double getProcessingRate() {
                return processingRate;
            }

            public double getErrorRate() {
                return errorRate;
            }

            public long getReceivedShares() {
                return receivedShares;
            }

            public long getReceivedFutures() {
                return receivedFutures;
            }

            public long getReceivedIndicatives() {
                return receivedIndicatives;
            }
        }
    }
}
