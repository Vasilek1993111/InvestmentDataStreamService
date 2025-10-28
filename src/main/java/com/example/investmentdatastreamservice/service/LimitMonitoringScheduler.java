package com.example.investmentdatastreamservice.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

/**
 * Планировщик задач для сервиса мониторинга лимитов
 * 
 * Выполняет периодические задачи по очистке кэша уведомлений
 * и поддержанию работоспособности системы мониторинга.
 */
@Service
public class LimitMonitoringScheduler {
    
    private static final Logger logger = LoggerFactory.getLogger(LimitMonitoringScheduler.class);
    
    private final LimitMonitorService limitMonitorService;
    
    public LimitMonitoringScheduler(LimitMonitorService limitMonitorService) {
        this.limitMonitorService = limitMonitorService;
    }
    
    /**
     * Ежедневная очистка кэша уведомлений
     * 
     * Выполняется каждый день в 00:01 по московскому времени
     * для очистки кэша уведомлений за предыдущие дни.
     */
    @Scheduled(cron = "0 1 0 * * *", zone = "Europe/Moscow")
    public void clearDailyNotificationsCache() {
        try {
            logger.info("🔄 Выполняется ежедневная очистка кэша уведомлений о лимитах");
            limitMonitorService.clearDailyNotifications();
            logger.info("✅ Кэш уведомлений о лимитах очищен успешно");
        } catch (Exception e) {
            logger.error("❌ Ошибка при ежедневной очистке кэша уведомлений: {}", e.getMessage(), e);
        }
    }
    
    /**
     * Еженедельная статистика мониторинга лимитов
     * 
     * Выполняется каждый понедельник в 09:00 по московскому времени
     * для вывода статистики работы за неделю.
     */
    @Scheduled(cron = "0 0 9 * * MON", zone = "Europe/Moscow")
    public void weeklyStatisticsReport() {
        try {
            logger.info("📊 Генерация еженедельной статистики мониторинга лимитов");
            
            var stats = limitMonitorService.getStatistics();
            
            logger.info("=== ЕЖЕНЕДЕЛЬНАЯ СТАТИСТИКА МОНИТОРИНГА ЛИМИТОВ ===");
            logger.info("📈 Всего обработано алертов: {}", stats.get("totalAlertsProcessed"));
            logger.info("⚠️ Приближение к лимиту: {}", stats.get("approachingLimitAlerts"));
            logger.info("🚨 Лимит достигнут: {}", stats.get("limitReachedAlerts"));
            logger.info("📤 Уведомлений отправлено: {}", stats.get("notificationsSent"));
            logger.info("📅 Активных уведомлений за день: {}", stats.get("dailyNotificationsCount"));
            logger.info("🤖 Telegram канал настроен: {}", stats.get("telegramChannelConfigured"));
            logger.info("================================================");
            
        } catch (Exception e) {
            logger.error("❌ Ошибка при генерации еженедельной статистики: {}", e.getMessage(), e);
        }
    }
}
