package com.example.investmentdatastreamservice.service;

import com.example.investmentdatastreamservice.dto.LimitAlertDto;
import com.example.investmentdatastreamservice.dto.LimitsDto;
import com.example.investmentdatastreamservice.dto.HistoricalPriceDto;
import com.example.investmentdatastreamservice.entity.ShareEntity;
import com.example.investmentdatastreamservice.entity.FutureEntity;
import com.example.investmentdatastreamservice.repository.ShareRepository;
import com.example.investmentdatastreamservice.repository.FutureRepository;
import com.example.investmentdatastreamservice.repository.LastPriceRepository;
import com.example.investmentdatastreamservice.entity.LastPriceEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Сервис для мониторинга приближения к лимитам инструментов и их достижения
 * 
 * Отслеживает цены LAST_PRICE и отправляет уведомления в Telegram:
 * - при приближении к лимитам (порог настраивается через limit.monitor.approach.threshold, по умолчанию 1%)
 * - при достижении лимитов (верхнего или нижнего)
 */
@Service
public class LimitMonitorService implements InitializingBean {
    
    private static final Logger logger = LoggerFactory.getLogger(LimitMonitorService.class);
    
    private final LimitsService limitsService;
    private final TgBotService telegramBotService;
    private final ShareRepository shareRepository;
    private final FutureRepository futureRepository;
    private final LastPriceRepository lastPriceRepository;
    private final CacheManager cacheManager;
    private final HistoricalPricesService historicalPricesService;
    
    // Счетчики для статистики
    private final AtomicLong totalAlertsProcessed = new AtomicLong(0);
    private final AtomicLong approachingLimitAlerts = new AtomicLong(0);
    private final AtomicLong limitReachedAlerts = new AtomicLong(0);
    private final AtomicLong notificationsSent = new AtomicLong(0);
    private final AtomicLong historicalExtremeAlerts = new AtomicLong(0);
    private final AtomicLong historicalExtremeReachedAlerts = new AtomicLong(0);
    
    @Value("${TELEGRAM_LIMIT_CHANNEL_ID}")
    private String telegramChannelId;
    
    // Порог приближения к лимиту (настраивается через конфигурацию limit.monitor.approach.threshold в процентах)
    @Value("${limit.monitor.approach.threshold:1.0}")
    private BigDecimal approachThresholdPercent;
    
    // Порог приближения к историческим экстремумам (настраивается через конфигурацию limit.monitor.historical.approach.threshold в процентах)
    @Value("${limit.monitor.historical.approach.threshold:1.0}")
    private BigDecimal historicalApproachThresholdPercent;
    
    // Конвертированные значения в десятичном формате (для расчетов)
    private BigDecimal approachThreshold;
    private BigDecimal historicalApproachThreshold;
    
    public LimitMonitorService(
            LimitsService limitsService,
            TgBotService telegramBotService,
            ShareRepository shareRepository,
            FutureRepository futureRepository,
            LastPriceRepository lastPriceRepository,
            CacheManager cacheManager,
            HistoricalPricesService historicalPricesService) {
        this.limitsService = limitsService;
        this.telegramBotService = telegramBotService;
        this.shareRepository = shareRepository;
        this.futureRepository = futureRepository;
        this.lastPriceRepository = lastPriceRepository;
        this.cacheManager = cacheManager;
        this.historicalPricesService = historicalPricesService;
    }
    
    /**
     * Инициализация после создания бина и инжекции всех зависимостей
     */
    @Override
    public void afterPropertiesSet() {
        // Конвертируем проценты в десятичный формат для расчетов
        approachThreshold = approachThresholdPercent.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
        historicalApproachThreshold = historicalApproachThresholdPercent.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
        
        // Логируем информацию о настройке Telegram канала и пороге приближения
        logger.info("================================================================");
        logger.info("🔧 Инициализация LimitMonitorService");
        logger.info("📊 ПОРОГ ПРИБЛИЖЕНИЯ К ЛИМИТУ: {}% (десятичное значение: {})", 
                   approachThresholdPercent.setScale(2, RoundingMode.HALF_UP), approachThreshold);
        logger.info("   Уведомления будут отправляться при приближении к лимиту на {}% и менее", 
                   approachThresholdPercent.setScale(2, RoundingMode.HALF_UP));
        logger.info("   Настройка: limit.monitor.approach.threshold={}%", approachThresholdPercent.setScale(2, RoundingMode.HALF_UP));
        
        logger.info("📊 ПОРОГ ПРИБЛИЖЕНИЯ К ИСТОРИЧЕСКИМ ЭКСТРЕМУМАМ: {}% (десятичное значение: {})", 
                   historicalApproachThresholdPercent.setScale(2, RoundingMode.HALF_UP), historicalApproachThreshold);
        logger.info("   Уведомления будут отправляться при приближении к историческому экстремуму на {}% и менее", 
                   historicalApproachThresholdPercent.setScale(2, RoundingMode.HALF_UP));
        logger.info("   Настройка: limit.monitor.historical.approach.threshold={}%", 
                   historicalApproachThresholdPercent.setScale(2, RoundingMode.HALF_UP));
        if (telegramChannelId != null && !telegramChannelId.trim().isEmpty()) {
            logger.info("✅ Telegram канал для уведомлений о лимитах настроен: {}", telegramChannelId);
        } else {
            logger.warn("⚠️ Telegram канал для уведомлений о лимитах НЕ настроен");
            logger.warn("💡 Для настройки добавьте переменную TELEGRAM_LIMIT_CHANNEL_ID в .env файл");
        }
        logger.info("================================================================");
    }
    
    /**
     * Получение актуальных лимитов для текущего дня недели
     * 
     * @param limits объект с лимитами
     * @return массив из двух элементов: [limitDown, limitUp]
     */
    private BigDecimal[] getActualLimits(LimitsDto limits) {
        DayOfWeek dayOfWeek = LocalDate.now().getDayOfWeek();
        boolean isWeekend = dayOfWeek == DayOfWeek.SATURDAY || dayOfWeek == DayOfWeek.SUNDAY;
        
        BigDecimal limitDown;
        BigDecimal limitUp;
        
        if (isWeekend) {
            // Выходные дни - используем лимиты для внебиржевых торгов
            limitDown = limits.getLimitDownOverExchangeTrades();
            limitUp = limits.getLimitUpOverExchangeTrades();
            logger.debug("Используются лимиты для ВЫХОДНЫХ дней: limitDown={}, limitUp={}", limitDown, limitUp);
        } else {
            // Рабочие дни (пн-пт) - используем обычные биржевые лимиты
            limitDown = limits.getLimitDown();
            limitUp = limits.getLimitUp();
            logger.debug("Используются лимиты для РАБОЧИХ дней: limitDown={}, limitUp={}", limitDown, limitUp);
        }
        
        return new BigDecimal[]{limitDown, limitUp};
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
            if (limits == null) {
                logger.debug("Лимиты не найдены для инструмента: {} (порог приближения: {}%)", 
                           figi, approachThresholdPercent.setScale(2, RoundingMode.HALF_UP));
                return;
            }
            
            // Получаем актуальные лимиты для текущего дня недели
            BigDecimal[] actualLimits = getActualLimits(limits);
            BigDecimal limitDown = actualLimits[0];
            BigDecimal limitUp = actualLimits[1];
            
            // Проверяем, что лимиты определены
            if (limitUp == null || limitDown == null) {
                logger.debug("Лимиты не определены для инструмента: {} (порог приближения: {}%)", 
                           figi, approachThresholdPercent.setScale(2, RoundingMode.HALF_UP));
                return;
            }
            
            // Получаем информацию об инструменте
            String ticker = getTickerByFigi(figi);
            String instrumentName = getInstrumentNameByFigi(figi);
            
            // Проверяем приближение к верхнему лимиту
            checkLimitApproach(figi, ticker, instrumentName, currentPrice, 
                             limitUp, "UP", eventTime, limits);
            
            // Проверяем приближение к нижнему лимиту
            checkLimitApproach(figi, ticker, instrumentName, currentPrice, 
                             limitDown, "DOWN", eventTime, limits);
            
            // Проверяем исторические экстремумы
            processHistoricalExtremes(figi, ticker, instrumentName, currentPrice, eventTime);
            
            logger.debug("Обработка лимитов для {} ({}): текущая цена={}, порог приближения={}%", 
                       ticker, figi, currentPrice, approachThresholdPercent.setScale(2, RoundingMode.HALF_UP));
            
        } catch (Exception e) {
            logger.error("Ошибка при обработке LAST_PRICE для мониторинга лимитов: {} (порог приближения: {}%)", 
                        figi, approachThresholdPercent.setScale(2, RoundingMode.HALF_UP), e);
        }
    }
    
    /**
     * Проверка приближения к лимиту и достижения лимита
     */
    private void checkLimitApproach(String figi, String ticker, String instrumentName,
                                   BigDecimal currentPrice, BigDecimal limitPrice, 
                                   String limitType, LocalDateTime eventTime, LimitsDto limits) {
        
        if (limitPrice == null) {
            return;
        }
        
        // Вычисляем расстояние до лимита в процентах
        BigDecimal distanceToLimit = calculateDistanceToLimit(currentPrice, limitPrice);
        BigDecimal distanceToLimitPercent = distanceToLimit.multiply(new BigDecimal("100"));
        
        // Проверяем, достигнут ли лимит
        boolean isLimitReached = isLimitReached(currentPrice, limitPrice, limitType);
        
        // Проверяем, приближается ли к лимиту (порог настраивается через конфигурацию)
        boolean isApproachingLimit = distanceToLimit.compareTo(approachThreshold) <= 0 && !isLimitReached;
        
        // Логируем информацию о проверке лимита
        logger.debug("Проверка лимита для {} ({}): текущая цена={}, лимит={}, расстояние={}%, порог приближения={}%", 
                    ticker, limitType, currentPrice, limitPrice, 
                    distanceToLimitPercent.setScale(2, RoundingMode.HALF_UP),
                    approachThresholdPercent.setScale(2, RoundingMode.HALF_UP));
        
        // Приоритет: сначала проверяем достижение лимита, затем приближение
        if (isLimitReached) {
            // Инструмент достиг лимита - отправляем уведомление о достижении
            logger.info("🚨 Лимит {} достигнут для {} ({}): цена={}, лимит={}, порог приближения={}%", 
                       limitType, ticker, figi, currentPrice, limitPrice,
                       approachThresholdPercent.setScale(2, RoundingMode.HALF_UP));
            sendLimitReachedNotification(figi, ticker, instrumentName, currentPrice, 
                                       limitPrice, limitType, eventTime, limits, distanceToLimit);
        } else if (isApproachingLimit) {
            // Инструмент приближается к лимиту - отправляем уведомление о приближении
            logger.info("⚠️ Приближение к лимиту {} для {} ({}): расстояние={}%, порог={}%", 
                       limitType, ticker, figi, 
                       distanceToLimitPercent.setScale(2, RoundingMode.HALF_UP),
                       approachThresholdPercent.setScale(2, RoundingMode.HALF_UP));
            sendApproachingLimitNotification(figi, ticker, instrumentName, currentPrice, 
                                           limitPrice, limitType, eventTime, limits, distanceToLimit);
        }
    }
    
    /**
     * Отправка уведомления о достижении лимита
     */
    private void sendLimitReachedNotification(String figi, String ticker, String instrumentName,
                                            BigDecimal currentPrice, BigDecimal limitPrice,
                                            String limitType, LocalDateTime eventTime, 
                                            LimitsDto limits, BigDecimal distanceToLimit) {
        // Получаем цены закрытия
        BigDecimal closePriceOs = getLastClosePrice(figi, "OS");
        BigDecimal closePriceEvening = getLastClosePrice(figi, "EVENING");
        
        // Получаем актуальные лимиты для текущего дня недели
        BigDecimal[] actualLimits = getActualLimits(limits);
        BigDecimal limitDown = actualLimits[0];
        BigDecimal limitUp = actualLimits[1];
        
        // Создаем DTO для уведомления о достижении лимита
        LimitAlertDto alert = LimitAlertDto.builder()
            .figi(figi)
            .ticker(ticker)
            .instrumentName(instrumentName)
            .eventTime(eventTime)
            .currentPrice(currentPrice)
            .limitPrice(limitPrice)
            .limitType(limitType)
            .limitDown(limitDown)
            .limitUp(limitUp)
            .closePriceOs(closePriceOs)
            .closePriceEvening(closePriceEvening)
            .distanceToLimit(distanceToLimit.multiply(new BigDecimal("100"))) // В процентах
            .isLimitReached(true)
            .isApproachingLimit(false)
            .isHistorical(false)
            .build();
        
        // Отправляем уведомление
        sendLimitAlert(alert);
    }
    
    /**
     * Отправка уведомления о приближении к лимиту
     */
    private void sendApproachingLimitNotification(String figi, String ticker, String instrumentName,
                                                 BigDecimal currentPrice, BigDecimal limitPrice,
                                                 String limitType, LocalDateTime eventTime, 
                                                 LimitsDto limits, BigDecimal distanceToLimit) {
        // Получаем цены закрытия
        BigDecimal closePriceOs = getLastClosePrice(figi, "OS");
        BigDecimal closePriceEvening = getLastClosePrice(figi, "EVENING");
        
        // Получаем актуальные лимиты для текущего дня недели
        BigDecimal[] actualLimits = getActualLimits(limits);
        BigDecimal limitDown = actualLimits[0];
        BigDecimal limitUp = actualLimits[1];
        
        // Создаем DTO для уведомления о приближении к лимиту
        LimitAlertDto alert = LimitAlertDto.builder()
            .figi(figi)
            .ticker(ticker)
            .instrumentName(instrumentName)
            .eventTime(eventTime)
            .currentPrice(currentPrice)
            .limitPrice(limitPrice)
            .limitType(limitType)
            .limitDown(limitDown)
            .limitUp(limitUp)
            .closePriceOs(closePriceOs)
            .closePriceEvening(closePriceEvening)
            .distanceToLimit(distanceToLimit.multiply(new BigDecimal("100"))) // В процентах
            .isLimitReached(false)
            .isApproachingLimit(true)
            .build();
        
        // Отправляем уведомление
        sendLimitAlert(alert);
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
            // Получаем последние цены для инструмента
            LocalDateTime today = LocalDateTime.now().withHour(0).withMinute(0).withSecond(0);
            
            // Для ОС сессии ищем цены с 9:00 до 18:45
            if ("OS".equals(sessionType)) {
                LocalDateTime sessionStart = today.withHour(9).withMinute(0).withSecond(0);
                LocalDateTime sessionEnd = today.withHour(18).withMinute(45).withSecond(0);
                
                return lastPriceRepository.findByFigiAndTimeBetween(figi, sessionStart, sessionEnd)
                    .stream()
                    .findFirst()
                    .map(LastPriceEntity::getPrice)
                    .orElse(null);
            }
            
            // Для вечерней сессии ищем цены с 19:05 до 23:50
            if ("EVENING".equals(sessionType)) {
                LocalDateTime sessionStart = today.withHour(19).withMinute(5).withSecond(0);
                LocalDateTime sessionEnd = today.withHour(23).withMinute(50).withSecond(0);
                
                return lastPriceRepository.findByFigiAndTimeBetween(figi, sessionStart, sessionEnd)
                    .stream()
                    .findFirst()
                    .map(LastPriceEntity::getPrice)
                    .orElse(null);
            }
            
            return null;
        } catch (Exception e) {
            logger.warn("Ошибка при получении цены закрытия для {}: {}", figi, e.getMessage());
            return null;
        }
    }
    
    /**
     * Отправка уведомления о лимите (достижении или приближении)
     * 
     * Использует существующие методы для получения данных и форматирования сообщения.
     * Для достижения лимита и приближения к лимиту используются разные ключи кэша.
     */
    private void sendLimitAlert(LimitAlertDto alert) {
        try {
            // Формируем ключ кэша: для достижения лимита и приближения используются разные ключи
            // Для исторических экстремумов добавляем префикс HISTORICAL_
            String prefix = alert.isHistorical() ? "HISTORICAL_" : "";
            String alertKey = prefix + alert.getFigi() + "_" + alert.getLimitType() + "_" + 
                            (alert.isLimitReached() ? "REACHED" : "APPROACHING");
            LocalDate today = LocalDate.now();
            
            // Проверяем кэш уведомлений в Caffeine
            Cache notificationsCache = cacheManager.getCache("notificationsCache");
            if (notificationsCache != null) {
                Cache.ValueWrapper wrapper = notificationsCache.get(alertKey);
                if (wrapper != null && wrapper.get() != null) {
                    LocalDate cachedDate = (LocalDate) wrapper.get();
                    if (cachedDate.equals(today)) {
                        String alertType = alert.isLimitReached() ? "достижении лимита" : "приближении к лимиту";
                        logger.debug("Уведомление о {} для {} уже отправлено сегодня", alertType, alertKey);
                        return;
                    }
                }
            }
            
            // Формируем сообщение используя существующий метод
            String message = formatLimitAlertMessage(alert);
            
            // Отправляем в Telegram
            if (telegramChannelId != null && !telegramChannelId.trim().isEmpty()) {
                String alertType = alert.isLimitReached() 
                    ? (alert.isHistorical() ? "достижении исторического экстремума" : "достижении лимита")
                    : (alert.isHistorical() ? "приближении к историческому экстремуму" : "приближении к лимиту");
                BigDecimal thresholdPercent = alert.isHistorical() 
                    ? historicalApproachThresholdPercent.setScale(2, RoundingMode.HALF_UP)
                    : approachThresholdPercent.setScale(2, RoundingMode.HALF_UP);
                logger.info("📤 Отправка уведомления о {} в Telegram канал: {}", alertType, telegramChannelId);
                logger.info("📊 Данные уведомления:");
                logger.info("   - Тип: {}", alert.isHistorical() ? "Исторический экстремум" : "Биржевой лимит");
                logger.info("   - Тикер: {}", alert.getTicker());
                logger.info("   - FIGI: {}", alert.getFigi());
                logger.info("   - Тип лимита: {}", alert.getLimitType());
                logger.info("   - Текущая цена: {} ₽", alert.getCurrentPrice());
                logger.info("   - Цена лимита/экстремума: {} ₽", alert.getLimitPrice());
                logger.info("   - ПОРОГ ПРИБЛИЖЕНИЯ: {}% (настроен в {})", 
                           thresholdPercent, alert.isHistorical() 
                               ? "limit.monitor.historical.approach.threshold" 
                               : "limit.monitor.approach.threshold");
                
                telegramBotService.sendText(telegramChannelId, message);
                
                String statusEmoji = alert.isLimitReached() 
                    ? (alert.isHistorical() ? "🏆" : "🚨") 
                    : (alert.isHistorical() ? "📈" : "⚠️");
                logger.info("{} Уведомление о {} успешно отправлено в Telegram канал: {} для тикера: {}", 
                           statusEmoji, alertType, telegramChannelId, alert.getTicker());
            } else {
                logger.warn("❌ Telegram channel ID не настроен (значение: '{}'), уведомление не отправлено", 
                           telegramChannelId != null ? telegramChannelId : "null");
                logger.warn("💡 Для настройки добавьте переменную TELEGRAM_LIMIT_CHANNEL_ID в .env файл");
            }
            
            // Обновляем счетчики
            if (alert.isHistorical()) {
                // Счетчики для исторических экстремумов
                if (alert.isLimitReached()) {
                    historicalExtremeReachedAlerts.incrementAndGet();
                } else {
                    historicalExtremeAlerts.incrementAndGet();
                }
            } else {
                // Счетчики для биржевых лимитов
                if (alert.isLimitReached()) {
                    limitReachedAlerts.incrementAndGet();
                } else {
                    approachingLimitAlerts.incrementAndGet();
                }
            }
            notificationsSent.incrementAndGet();
            
            // Сохраняем информацию об отправленном уведомлении в кэш Caffeine
            if (notificationsCache != null) {
                notificationsCache.put(alertKey, today);
                logger.debug("Уведомление для {} сохранено в кэш Caffeine", alertKey);
            }
            
        } catch (Exception e) {
            logger.error("Ошибка при отправке уведомления о лимите: {}", e.getMessage(), e);
        }
    }
    
    /**
     * Форматирование сообщения для Telegram
     */
    private String formatLimitAlertMessage(LimitAlertDto alert) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm:ss");
        DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("dd.MM.yyyy");
        
        StringBuilder message = new StringBuilder();
        
        if (alert.isHistorical()) {
            // Отдельное форматирование для исторических экстремумов
            if (alert.isLimitReached()) {
                message.append("🏆 ИСТОРИЧЕСКИЙ ЭКСТРЕМУМ ДОСТИГНУТ\n\n");
            } else {
                message.append("📈 ПРИБЛИЖЕНИЕ К ИСТОРИЧЕСКОМУ ЭКСТРЕМУМУ\n\n");
            }
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
            
            message.append("🎯 Тип экстремума: ").append(alert.getLimitType().equals("UP") ? "МАКСИМУМ" : "МИНИМУМ").append("\n");
            message.append("📊 Исторический экстремум: ").append(alert.getLimitPrice()).append(" ₽\n");
            
            if (alert.getHistoricalExtremeDate() != null) {
                message.append("📆 Дата экстремума: ").append(alert.getHistoricalExtremeDate().format(dateFormatter)).append("\n");
            }
            
            if (alert.isApproachingLimit()) {
                message.append("⚠️ Расстояние до экстремума: ").append(alert.getDistanceToLimit()).append("%\n");
            }
        } else {
            // Форматирование для биржевых лимитов
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
     * 
     * <p>
     * Удаляет все записи из кэша уведомлений. Caffeine автоматически удалит
     * записи по истечении TTL (24 часа), но для гарантированной очистки
     * старых записей выполняется ручная очистка.
     * </p>
     */
    public void clearDailyNotifications() {
        try {
            Cache notificationsCache = cacheManager.getCache("notificationsCache");
            if (notificationsCache != null) {
                // Очищаем весь кэш уведомлений
                notificationsCache.clear();
                logger.info("✅ Кэш уведомлений (Caffeine) очищен");
            } else {
                logger.warn("⚠️ Кэш 'notificationsCache' не найден");
            }
        } catch (Exception e) {
            logger.error("❌ Ошибка при очистке кэша уведомлений: {}", e.getMessage(), e);
        }
    }
    
    /**
     * Обработка исторических экстремумов для мониторинга приближения
     */
    private void processHistoricalExtremes(String figi, String ticker, String instrumentName, 
                                           BigDecimal currentPrice, LocalDateTime eventTime) {
        try {
            // Получаем исторические экстремумы для инструмента
            HistoricalPriceDto historicalPrice = historicalPricesService.getHistoricalPriceByFigi(figi);
            if (historicalPrice == null || historicalPrice.getHistoricalHigh() == null || 
                historicalPrice.getHistoricalLow() == null) {
                logger.debug("Исторические экстремумы не найдены для инструмента: {}", figi);
                return;
            }
            
            // Проверяем приближение к историческому максимуму
            checkHistoricalExtremeApproach(figi, ticker, instrumentName, currentPrice, 
                                         historicalPrice.getHistoricalHigh(), "UP", eventTime, 
                                         historicalPrice.getHistoricalHighDate(), historicalPrice);
            
            // Проверяем приближение к историческому минимуму
            checkHistoricalExtremeApproach(figi, ticker, instrumentName, currentPrice, 
                                         historicalPrice.getHistoricalLow(), "DOWN", eventTime, 
                                         historicalPrice.getHistoricalLowDate(), historicalPrice);
            
        } catch (Exception e) {
            logger.error("Ошибка при обработке исторических экстремумов для {}: {}", figi, e.getMessage(), e);
        }
    }
    
    /**
     * Проверка приближения к историческому экстремуму и его достижения
     */
    private void checkHistoricalExtremeApproach(String figi, String ticker, String instrumentName,
                                               BigDecimal currentPrice, BigDecimal extremePrice, 
                                               String limitType, LocalDateTime eventTime, 
                                               OffsetDateTime extremeDate, HistoricalPriceDto historicalPrice) {
        
        if (extremePrice == null) {
            return;
        }
        
        // Вычисляем расстояние до экстремума в процентах
        BigDecimal distanceToLimit = calculateDistanceToLimit(currentPrice, extremePrice);
        BigDecimal distanceToLimitPercent = distanceToLimit.multiply(new BigDecimal("100"));
        
        // Проверяем, достигнут ли экстремум
        boolean isLimitReached = isLimitReached(currentPrice, extremePrice, limitType);
        
        // Проверяем, приближается ли к экстремуму
        boolean isApproachingLimit = distanceToLimit.compareTo(historicalApproachThreshold) <= 0 && !isLimitReached;
        
        // Логируем информацию о проверке исторического экстремума
        logger.debug("Проверка исторического экстремума {} для {} ({}): текущая цена={}, экстремум={}, расстояние={}%, порог приближения={}%", 
                    limitType, ticker, figi, currentPrice, extremePrice, 
                    distanceToLimitPercent.setScale(2, RoundingMode.HALF_UP),
                    historicalApproachThresholdPercent.setScale(2, RoundingMode.HALF_UP));
        
        // Приоритет: сначала проверяем достижение экстремума, затем приближение
        if (isLimitReached) {
            // Инструмент достиг исторического экстремума - отправляем уведомление о достижении
            logger.info("🏆 Исторический экстремум {} достигнут для {} ({}): цена={}, экстремум={}, порог приближения={}%", 
                       limitType, ticker, figi, currentPrice, extremePrice,
                       historicalApproachThresholdPercent.setScale(2, RoundingMode.HALF_UP));
            sendHistoricalExtremeReachedNotification(figi, ticker, instrumentName, currentPrice, 
                                                   extremePrice, limitType, eventTime, extremeDate, 
                                                   historicalPrice, distanceToLimit);
        } else if (isApproachingLimit) {
            // Инструмент приближается к историческому экстремуму - отправляем уведомление о приближении
            logger.info("📈 Приближение к историческому экстремуму {} для {} ({}): расстояние={}%, порог={}%", 
                       limitType, ticker, figi, 
                       distanceToLimitPercent.setScale(2, RoundingMode.HALF_UP),
                       historicalApproachThresholdPercent.setScale(2, RoundingMode.HALF_UP));
            sendHistoricalExtremeApproachingNotification(figi, ticker, instrumentName, currentPrice, 
                                                        extremePrice, limitType, eventTime, extremeDate, 
                                                        historicalPrice, distanceToLimit);
        }
    }
    
    /**
     * Отправка уведомления о достижении исторического экстремума
     */
    private void sendHistoricalExtremeReachedNotification(String figi, String ticker, String instrumentName,
                                                         BigDecimal currentPrice, BigDecimal extremePrice,
                                                         String limitType, LocalDateTime eventTime, 
                                                         OffsetDateTime extremeDate, HistoricalPriceDto historicalPrice,
                                                         BigDecimal distanceToLimit) {
        // Получаем цены закрытия
        BigDecimal closePriceOs = getLastClosePrice(figi, "OS");
        BigDecimal closePriceEvening = getLastClosePrice(figi, "EVENING");
        
        // Создаем DTO для уведомления о достижении исторического экстремума
        LimitAlertDto alert = LimitAlertDto.builder()
            .figi(figi)
            .ticker(ticker)
            .instrumentName(instrumentName)
            .eventTime(eventTime)
            .currentPrice(currentPrice)
            .limitPrice(extremePrice)
            .limitType(limitType)
            .limitDown(historicalPrice.getHistoricalLow())
            .limitUp(historicalPrice.getHistoricalHigh())
            .closePriceOs(closePriceOs)
            .closePriceEvening(closePriceEvening)
            .distanceToLimit(distanceToLimit.multiply(new BigDecimal("100"))) // В процентах
            .isLimitReached(true)
            .isApproachingLimit(false)
            .isHistorical(true)
            .historicalExtremeDate(extremeDate)
            .build();
        
        // Отправляем уведомление
        sendLimitAlert(alert);
    }
    
    /**
     * Отправка уведомления о приближении к историческому экстремуму
     */
    private void sendHistoricalExtremeApproachingNotification(String figi, String ticker, String instrumentName,
                                                             BigDecimal currentPrice, BigDecimal extremePrice,
                                                             String limitType, LocalDateTime eventTime, 
                                                             OffsetDateTime extremeDate, HistoricalPriceDto historicalPrice,
                                                             BigDecimal distanceToLimit) {
        // Получаем цены закрытия
        BigDecimal closePriceOs = getLastClosePrice(figi, "OS");
        BigDecimal closePriceEvening = getLastClosePrice(figi, "EVENING");
        
        // Создаем DTO для уведомления о приближении к историческому экстремуму
        LimitAlertDto alert = LimitAlertDto.builder()
            .figi(figi)
            .ticker(ticker)
            .instrumentName(instrumentName)
            .eventTime(eventTime)
            .currentPrice(currentPrice)
            .limitPrice(extremePrice)
            .limitType(limitType)
            .limitDown(historicalPrice.getHistoricalLow())
            .limitUp(historicalPrice.getHistoricalHigh())
            .closePriceOs(closePriceOs)
            .closePriceEvening(closePriceEvening)
            .distanceToLimit(distanceToLimit.multiply(new BigDecimal("100"))) // В процентах
            .isLimitReached(false)
            .isApproachingLimit(true)
            .isHistorical(true)
            .historicalExtremeDate(extremeDate)
            .build();
        
        // Отправляем уведомление
        sendLimitAlert(alert);
    }
    
    /**
     * Получение статистики мониторинга лимитов
     */
    public Map<String, Object> getStatistics() {
        // Получаем размер кэша уведомлений из Caffeine
        long notificationsCacheSize = 0;
        try {
            Cache notificationsCache = cacheManager.getCache("notificationsCache");
            if (notificationsCache != null && notificationsCache.getNativeCache() instanceof 
                    com.github.benmanes.caffeine.cache.Cache) {
                @SuppressWarnings("unchecked")
                com.github.benmanes.caffeine.cache.Cache<String, LocalDate> caffeineCache = 
                    (com.github.benmanes.caffeine.cache.Cache<String, LocalDate>) notificationsCache.getNativeCache();
                notificationsCacheSize = caffeineCache.estimatedSize();
            }
        } catch (Exception e) {
            logger.debug("Ошибка при получении размера кэша уведомлений: {}", e.getMessage());
        }
        
        return Map.of(
            "totalAlertsProcessed", totalAlertsProcessed.get(),
            "approachingLimitAlerts", approachingLimitAlerts.get(),
            "limitReachedAlerts", limitReachedAlerts.get(),
            "historicalExtremeAlerts", historicalExtremeAlerts.get(),
            "historicalExtremeReachedAlerts", historicalExtremeReachedAlerts.get(),
            "notificationsSent", notificationsSent.get(),
            "dailyNotificationsCount", notificationsCacheSize,
            "telegramChannelConfigured", telegramChannelId != null && !telegramChannelId.trim().isEmpty()
        );
    }


    
}
