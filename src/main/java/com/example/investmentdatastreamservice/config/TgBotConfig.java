package com.example.investmentdatastreamservice.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.telegram.telegrambots.meta.TelegramBotsApi;
import org.telegram.telegrambots.meta.exceptions.TelegramApiException;
import org.telegram.telegrambots.updatesreceivers.DefaultBotSession;

import com.example.investmentdatastreamservice.service.TgBotService;

@Configuration  
public class TgBotConfig {

    @Bean
   public TelegramBotsApi telegramBotsApi(TgBotService bot) throws TelegramApiException {
    TelegramBotsApi botsApi = new TelegramBotsApi(DefaultBotSession.class);
    botsApi.registerBot(bot);
    return botsApi;
   }
}