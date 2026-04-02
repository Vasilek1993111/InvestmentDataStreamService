package com.example.investmentdatastreamservice.service;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.telegram.telegrambots.bots.TelegramLongPollingBot;
import org.telegram.telegrambots.meta.api.methods.send.SendMessage;
import org.telegram.telegrambots.meta.api.objects.Update;
import org.telegram.telegrambots.meta.api.objects.User;
import org.telegram.telegrambots.meta.exceptions.TelegramApiException;


@Service
public class TgBotService extends TelegramLongPollingBot {

    private static final Logger logger = LoggerFactory.getLogger(TgBotService.class);

    @Value("${TELEGRAM_BOT_TOKEN}")
    private String botToken;

    @Value("${TELEGRAM_BOT_USERNAME}")
    private String botUsername;
    
    @Value("${telegram.limit.channel.id:}")
    private String limitChannelId;

    private volatile boolean isInitialized = false;

    @PostConstruct
    public void init() {
        if (!isInitialized) {
            logger.info("╔════════════════════════════════════════════════════════════╗");
            logger.info("║          TELEGRAM BOT SERVICE INITIALIZATION              ║");
            logger.info("╠════════════════════════════════════════════════════════════╣");
            logger.info("║ Bot Username: {}", botUsername != null ? botUsername : "NOT SET");
            logger.info("║ Bot Token: {}", botToken != null ? "***SET***" : "NOT SET");
            logger.info("║ Limit Channel ID configured: {}",
                    limitChannelId != null && !limitChannelId.trim().isEmpty() ? "YES" : "NO");
            logger.info("║ Status: {}", botToken != null && botUsername != null ? "READY" : "NOT READY");
            logger.info("╚════════════════════════════════════════════════════════════╝");
            isInitialized = true;
        }
    }

    @Override
    public String getBotUsername() {
        return botUsername;
    }

    @Override
    public String getBotToken() {
        return botToken;
    }

    @Override
    public void onUpdateReceived(Update update) {
        try {
            if (update.hasMessage() && update.getMessage().hasText()) {
                handleMessage(update);
            }
        } catch (Exception e) {
            logger.error("Error processing update: {}", e.getMessage(), e);
        }
    }

    private void handleMessage(Update update) {
        User user = update.getMessage().getFrom();
        String chatId = update.getMessage().getChatId().toString();
        String text = update.getMessage().getText();

        logger.info("📨 Received message from Telegram user in configured bot chat");
        logger.debug("Telegram update metadata: userId={}, chatId={}, hasCommand={}",
                user.getId(), chatId, text.startsWith("/"));

        // Обработка команд
        if (text.startsWith("/")) {
            handleCommand(chatId, text, user);
        } else {
            sendText(chatId, "Ты написал: " + text);
        }
    }

    private void handleCommand(String chatId, String command, User user) {
        logger.info("⚙️  Processing command: {} from user: {}", command, user.getFirstName());

        switch (command.toLowerCase()) {
            case "/start":
                sendText(chatId, "🤖 Привет! Я бот для проекта Invest!\n" +
                        "\n📊 Доступные команды:\n" +
                        "/help - Список команд\n" +
                        "/status - Статус сервиса");
                logger.info("✅ Start command processed for user: {}", user.getFirstName());
                break;

            case "/help":
                sendText(chatId, "📋 Доступные команды:\n\n" +
                        "/start - Запустить бота\n" +
                        "/help - Показать список команд\n" +
                        "/status - Получить статус сервиса");
                logger.info("✅ Help command processed for user: {}", user.getFirstName());
                break;

            case "/status":
                sendText(chatId, "✅ Сервис работает нормально!\n" +
                        "🤖 Telegram бот активен\n" +
                        "📡 API подключение установлено");
                logger.info("✅ Status command processed for user: {}", user.getFirstName());
                break;

            default:
                sendText(chatId, "❓ Неизвестная команда. Используйте /help для списка команд.");
                logger.warn("⚠️  Unknown command: {} from user: {}", command, user.getFirstName());
        }
    }

    public void sendText(String chatId, String text) {
        try {
            logger.info("📤 Sending message to configured Telegram destination");
            logger.debug("Telegram message length: {}", text != null ? text.length() : 0);
            
            SendMessage message = new SendMessage();
            message.setChatId(chatId);
            message.setText(text);
            execute(message);
            
            logger.info("✅ Telegram message sent successfully");
        } catch (TelegramApiException e) {
            logger.error("❌ Ошибка при отправке сообщения в Telegram", e);
            
            // Дополнительная информация об ошибке
            if (e.getMessage().contains("chat not found")) {
                logger.error("💡 Возможные причины: чат не найден, бот не добавлен в чат, или неверный ID чата");
            } else if (e.getMessage().contains("bot was blocked")) {
                logger.error("💡 Бот заблокирован пользователем или удален из чата");
            } else if (e.getMessage().contains("Forbidden")) {
                logger.error("💡 У бота нет прав на отправку сообщений в этот чат");
            }
        }
    }

    
}
