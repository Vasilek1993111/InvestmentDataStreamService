package com.example.investmentdatastreamservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Главный класс приложения Investment Data Stream Service
 * 
 * Сервис для потоковой обработки инвестиционных данных в реальном времени с использованием T-Invest
 * API, PostgreSQL и gRPC.
 * 
 * @author Investment Data Stream Service Team
 * @version 1.0.0
 * @since 2024
 */
@SpringBootApplication
public class InvestmentDataStreamService {

    /**
     * Точка входа в приложение
     * 
     * @param args аргументы командной строки
     */
    public static void main(String[] args) {
        SpringApplication.run(InvestmentDataStreamService.class, args);
    }
}
