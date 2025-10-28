package com.example.investmentdatastreamservice.service;

import com.example.investmentdatastreamservice.dto.LimitAlertDto;
import com.example.investmentdatastreamservice.dto.LimitsDto;
import com.example.investmentdatastreamservice.entity.ShareEntity;
import com.example.investmentdatastreamservice.entity.FutureEntity;
import com.example.investmentdatastreamservice.entity.TradeEntity;
import com.example.investmentdatastreamservice.repository.ShareRepository;
import com.example.investmentdatastreamservice.repository.FutureRepository;
import com.example.investmentdatastreamservice.repository.TradeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Сервис для мониторинга приближения к лимитам инструментов
 * 
 * Отслеживает цены LAST_PRICE и отправляет уведомления в Telegram
 * при приближении к лимитам (1%) или их достижении.
 */
@Service
public class LimitMonitorService {
    
    private static final Logger logger = LoggerFactory.getLogger(LimitMonitorService.class);
    
    private final LimitsService limitsService;
    private final TgBotService telegramBotService;
    private final ShareRepository shareRepository;
    private final FutureRepository futureRepository;
    private final TradeRepository tradeRepository;
    
    // Кэш для отслеживания отправленных уведомлений за день
    private final Map<String, LocalDate> dailyNotifications = new ConcurrentHashMap<>();
    
    // Счетчики для статистики
    private final AtomicLong totalAlertsProcessed = new AtomicLong(0);
    private final AtomicLong approachingLimitAlerts = new AtomicLong(0);
    private final AtomicLong limitReachedAlerts = new AtomicLong(0);
    private final AtomicLong notificationsSent = new AtomicLong(0);
    
    @Value("${TELEGRAM_LIMIT_CHANNEL_ID}")
    private String telegramChannelId;
    
    // Порог приближения к лимиту (1%)
    private static final BigDecimal APPROACH_THRESHOLD = new BigDecimal("0.2");
    
    public LimitMonitorService(
            LimitsService limitsService,
            TgBotService telegramBotService,
            ShareRepository shareRepository,
            FutureRepository futureRepository,
            TradeRepository tradeRepository) {
        this.limitsService = limitsService;
        this.telegramBotService = telegramBotService;
        this.shareRepository = shareRepository;
        this.futureRepository = futureRepository;
        this.tradeRepository = tradeRepository;
        
        // Логируем информацию о настройке Telegram канала
        logger.info("🔧 Инициализация LimitMonitorService");
        if (telegramChannelId != null && !telegramChannelId.trim().isEmpty()) {
            logger.info("✅ Telegram канал для уведомлений о лимитах настроен: {}", telegramChannelId);
        } else {
            logger.warn("⚠️ Telegram канал для уведомлений о лимитах НЕ настроен");
            logger.warn("💡 Для настройки добавьте переменную TELEGRAM_LIMIT_CHANNEL_ID в .env файл");
        }
    }
    
    /**
     * Обработка данных LAST_PRICE для мониторинга лимитов
     * 
     * @param figi FIGI инструмента
     * @param currentPrice текущая цена
     * @param eventTime время события
     */
    public void processLastPrice(String figi, BigDecimal currentPrice, LocalDateTime eventTime) {
        try {
            totalAlertsProcessed.incrementAndGet();
            
            // Получаем лимиты для инструмента
            LimitsDto limits = limitsService.getLimitsFromCache(figi);
            if (limits == null || limits.getLimitUp() == null || limits.getLimitDown() == null) {
                logger.debug("Лимиты не найдены для инструмента: {}", figi);
                return;
            }
            
            // Получаем информацию об инструменте
            String ticker = getTickerByFigi(figi);
            String instrumentName = getInstrumentNameByFigi(figi);
            
            // Проверяем приближение к верхнему лимиту
            checkLimitApproach(figi, ticker, instrumentName, currentPrice, 
                             limits.getLimitUp(), "UP", eventTime, limits);
            
            // Проверяем приближение к нижнему лимиту
            checkLimitApproach(figi, ticker, instrumentName, currentPrice, 
                             limits.getLimitDown(), "DOWN", eventTime, limits);
            
        } catch (Exception e) {
            logger.error("Ошибка при обработке LAST_PRICE для мониторинга лимитов: {}", figi, e);
        }
    }
    
    /**
     * Проверка приближения к лимиту
     */
    private void checkLimitApproach(String figi, String ticker, String instrumentName,
                                   BigDecimal currentPrice, BigDecimal limitPrice, 
                                   String limitType, LocalDateTime eventTime, LimitsDto limits) {
        
        if (limitPrice == null) {
            return;
        }
        
        // Вычисляем расстояние до лимита в процентах
        BigDecimal distanceToLimit = calculateDistanceToLimit(currentPrice, limitPrice);
        
        // Проверяем, достигнут ли лимит
        boolean isLimitReached = isLimitReached(currentPrice, limitPrice, limitType);
        
        // Проверяем, приближается ли к лимиту (1%)
        boolean isApproachingLimit = distanceToLimit.compareTo(APPROACH_THRESHOLD) <= 0 && !isLimitReached;
        
        if (isLimitReached || isApproachingLimit) {
            // Получаем цены закрытия
            BigDecimal closePriceOs = getLastClosePrice(figi, "OS");
            BigDecimal closePriceEvening = getLastClosePrice(figi, "EVENING");
            
            // Создаем DTO для уведомления
            LimitAlertDto alert = LimitAlertDto.builder()
                .figi(figi)
                .ticker(ticker)
                .instrumentName(instrumentName)
                .eventTime(eventTime)
                .currentPrice(currentPrice)
                .limitPrice(limitPrice)
                .limitType(limitType)
                .limitDown(limits.getLimitDown())
                .limitUp(limits.getLimitUp())
                .closePriceOs(closePriceOs)
                .closePriceEvening(closePriceEvening)
                .distanceToLimit(distanceToLimit.multiply(new BigDecimal("100"))) // В процентах
                .isLimitReached(isLimitReached)
                .isApproachingLimit(isApproachingLimit)
                .build();
            
            // Отправляем уведомление
            sendLimitAlert(alert);
        }
    }
    
    /**
     * Вычисление расстояния до лимита в процентах
     */
    private BigDecimal calculateDistanceToLimit(BigDecimal currentPrice, BigDecimal limitPrice) {
        if (currentPrice == null || limitPrice == null || currentPrice.compareTo(BigDecimal.ZERO) == 0) {
            return BigDecimal.ZERO;
        }
        
        BigDecimal difference = limitPrice.subtract(currentPrice).abs();
        return difference.divide(currentPrice, 4, RoundingMode.HALF_UP);
    }
    
    /**
     * Проверка, достигнут ли лимит
     */
    private boolean isLimitReached(BigDecimal currentPrice, BigDecimal limitPrice, String limitType) {
        if ("UP".equals(limitType)) {
            return currentPrice.compareTo(limitPrice) >= 0;
        } else if ("DOWN".equals(limitType)) {
            return currentPrice.compareTo(limitPrice) <= 0;
        }
        return false;
    }
    
    /**
     * Получение последней цены закрытия
     */
    private BigDecimal getLastClosePrice(String figi, String sessionType) {
        try {
            // Получаем последние сделки для инструмента
            LocalDateTime today = LocalDateTime.now().withHour(0).withMinute(0).withSecond(0);
            
            // Для ОС сессии ищем сделки с 9:00 до 18:45
            if ("OS".equals(sessionType)) {
                LocalDateTime sessionStart = today.withHour(9).withMinute(0).withSecond(0);
                LocalDateTime sessionEnd = today.withHour(18).withMinute(45).withSecond(0);
                
                return tradeRepository.findByFigiAndDirectionOrderByTimeDesc(figi, "LAST_PRICE")
                    .stream()
                    .filter(trade -> trade.getId().getTime().isAfter(sessionStart) && 
                                   trade.getId().getTime().isBefore(sessionEnd))
                    .findFirst()
                    .map(TradeEntity::getPrice)
                    .orElse(null);
            }
            
            // Для вечерней сессии ищем сделки с 19:05 до 23:50
            if ("EVENING".equals(sessionType)) {
                LocalDateTime sessionStart = today.withHour(19).withMinute(5).withSecond(0);
                LocalDateTime sessionEnd = today.withHour(23).withMinute(50).withSecond(0);
                
                return tradeRepository.findByFigiAndDirectionOrderByTimeDesc(figi, "LAST_PRICE")
                    .stream()
                    .filter(trade -> trade.getId().getTime().isAfter(sessionStart) && 
                                   trade.getId().getTime().isBefore(sessionEnd))
                    .findFirst()
                    .map(TradeEntity::getPrice)
                    .orElse(null);
            }
            
            return null;
        } catch (Exception e) {
            logger.warn("Ошибка при получении цены закрытия для {}: {}", figi, e.getMessage());
            return null;
        }
    }
    
    /**
     * Отправка уведомления о лимите
     */
    private void sendLimitAlert(LimitAlertDto alert) {
        try {
            // Проверяем, не отправляли ли уже уведомление за сегодня
            String alertKey = alert.getFigi() + "_" + alert.getLimitType() + "_" + 
                            (alert.isLimitReached() ? "REACHED" : "APPROACHING");
            LocalDate today = LocalDate.now();
            
            if (dailyNotifications.containsKey(alertKey) && 
                dailyNotifications.get(alertKey).equals(today)) {
                logger.debug("Уведомление для {} уже отправлено сегодня", alertKey);
                return;
            }
            
            // Формируем сообщение
            String message = formatLimitAlertMessage(alert);
            
            // Отправляем в Telegram
            if (telegramChannelId != null && !telegramChannelId.trim().isEmpty()) {
                logger.info("📤 Отправка уведомления о лимите в Telegram канал: {}", telegramChannelId);
                logger.info("📊 Данные уведомления - Тикер: {}, FIGI: {}, Тип лимита: {}, Текущая цена: {}, Лимит: {}", 
                           alert.getTicker(), alert.getFigi(), alert.getLimitType(), 
                           alert.getCurrentPrice(), alert.getLimitPrice());
                
                telegramBotService.sendText(telegramChannelId, message);
                
                logger.info("✅ Уведомление о лимите успешно отправлено в Telegram канал: {} для тикера: {}", 
                           telegramChannelId, alert.getTicker());
            } else {
                logger.warn("❌ Telegram channel ID не настроен (значение: '{}'), уведомление не отправлено", 
                           telegramChannelId != null ? telegramChannelId : "null");
                logger.warn("💡 Для настройки добавьте переменную TELEGRAM_LIMIT_CHANNEL_ID в .env файл");
            }
            
            // Обновляем счетчики
            if (alert.isLimitReached()) {
                limitReachedAlerts.incrementAndGet();
            } else {
                approachingLimitAlerts.incrementAndGet();
            }
            notificationsSent.incrementAndGet();
            
            // Сохраняем информацию об отправленном уведомлении
            dailyNotifications.put(alertKey, today);
            
        } catch (Exception e) {
            logger.error("Ошибка при отправке уведомления о лимите: {}", e.getMessage(), e);
        }
    }
    
    /**
     * Форматирование сообщения для Telegram
     */
    private String formatLimitAlertMessage(LimitAlertDto alert) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm:ss");
        
        StringBuilder message = new StringBuilder();
        message.append("🚨 ").append(alert.isLimitReached() ? "ЛИМИТ ДОСТИГНУТ" : "ПРИБЛИЖЕНИЕ К ЛИМИТУ").append("\n\n");
        message.append("📊 Тикер: ").append(alert.getTicker()).append("\n");
        message.append("🔗 FIGI: ").append(alert.getFigi()).append("\n");
        message.append("📅 Дата и время: ").append(alert.getEventTime().format(formatter)).append("\n");
        message.append("💰 Текущая цена: ").append(alert.getCurrentPrice()).append(" ₽\n");
        
        if (alert.getClosePriceOs() != null) {
            message.append("📈 Цена закрытия ОС: ").append(alert.getClosePriceOs()).append(" ₽\n");
        }
        if (alert.getClosePriceEvening() != null) {
            message.append("🌙 Цена закрытия вечерней: ").append(alert.getClosePriceEvening()).append(" ₽\n");
        }
        
        message.append("🎯 Тип лимита: ").append(alert.getLimitType()).append("\n");
        message.append("📊 Цена лимита: ").append(alert.getLimitPrice()).append(" ₽\n");
        
        if (alert.isApproachingLimit()) {
            message.append("⚠️ Расстояние до лимита: ").append(alert.getDistanceToLimit()).append("%\n");
        }
        
        return message.toString();
    }
    
    /**
     * Получение тикера по FIGI
     */
    private String getTickerByFigi(String figi) {
        try {
            ShareEntity share = shareRepository.findById(figi).orElse(null);
            if (share != null) {
                return share.getTicker();
            }
            
            FutureEntity future = futureRepository.findById(figi).orElse(null);
            if (future != null) {
                return future.getTicker();
            }
            
            return "UNKNOWN";
        } catch (Exception e) {
            logger.warn("Ошибка при получении тикера для {}: {}", figi, e.getMessage());
            return "UNKNOWN";
        }
    }
    
    /**
     * Получение названия инструмента по FIGI
     */
    private String getInstrumentNameByFigi(String figi) {
        try {
            ShareEntity share = shareRepository.findById(figi).orElse(null);
            if (share != null) {
                return share.getName();
            }
            
            FutureEntity future = futureRepository.findById(figi).orElse(null);
            if (future != null) {
                return future.getTicker();
            }
            
            return "Unknown Instrument";
        } catch (Exception e) {
            logger.warn("Ошибка при получении названия инструмента для {}: {}", figi, e.getMessage());
            return "Unknown Instrument";
        }
    }
    
    /**
     * Очистка кэша уведомлений (вызывается ежедневно)
     */
    public void clearDailyNotifications() {
        LocalDate today = LocalDate.now();
        dailyNotifications.entrySet().removeIf(entry -> !entry.getValue().equals(today));
        logger.info("Очищен кэш уведомлений за предыдущие дни");
    }
    
    /**
     * Получение статистики мониторинга лимитов
     */
    public Map<String, Object> getStatistics() {
        return Map.of(
            "totalAlertsProcessed", totalAlertsProcessed.get(),
            "approachingLimitAlerts", approachingLimitAlerts.get(),
            "limitReachedAlerts", limitReachedAlerts.get(),
            "notificationsSent", notificationsSent.get(),
            "dailyNotificationsCount", dailyNotifications.size(),
            "telegramChannelConfigured", telegramChannelId != null && !telegramChannelId.trim().isEmpty()
        );
    }
}
