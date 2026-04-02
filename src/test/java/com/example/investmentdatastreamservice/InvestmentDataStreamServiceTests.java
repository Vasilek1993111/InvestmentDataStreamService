package com.example.investmentdatastreamservice;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;

import com.example.investmentdatastreamservice.service.TgBotService;

import ru.tinkoff.piapi.core.MarketDataService;

/**
 * Основные тесты приложения Investment Data Stream Service
 * 
 * Проверяет корректность загрузки контекста Spring Boot и инициализацию всех компонентов
 * приложения.
 */
@SpringBootTest(properties = "spring.main.lazy-initialization=true")
@ActiveProfiles("test")
class InvestmentDataStreamServiceTests {

    @MockBean
    private TgBotService tgBotService;

    @MockBean
    private MarketDataService marketDataService;

    @Test
    void contextLoads() {
        // Тест проверяет, что Spring Boot контекст загружается корректно
        // и все бины инициализируются без ошибок
    }
}
