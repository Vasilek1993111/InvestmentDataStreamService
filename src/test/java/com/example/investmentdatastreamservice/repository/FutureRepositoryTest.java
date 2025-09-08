package com.example.investmentdatastreamservice.repository;

import static org.junit.jupiter.api.Assertions.assertFalse;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

/**
 * Тесты для FutureRepository
 * 
 * Проверяет корректность работы репозитория с фьючерсами и выполнения запросов к базе данных.
 */
@SpringBootTest(classes = com.example.investmentdatastreamservice.InvestmentDataStreamService.class)
class FutureRepositoryTest {

    @Autowired
    private FutureRepository futureRepository;

    @Test
    void testFindFigisByAssetType() {
        List<String> figis = futureRepository.findFigisByAssetType("TYPE_SECURITY");
        System.out.println("Found " + figis.size() + " futures: " + figis);
        assertFalse(figis.isEmpty()); // Проверка, что список не пустой
    }
}
