package com.example.investmentdatastreamservice.repository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;
import com.example.investmentdatastreamservice.entity.FutureEntity;

/**
 * Тесты для FutureRepository
 * 
 * Проверяет корректность работы репозитория с фьючерсами и выполнения запросов к базе данных.
 */
@DataJpaTest(properties = {
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.datasource.url=jdbc:h2:mem:future-repository;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH;INIT=CREATE SCHEMA IF NOT EXISTS invest",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.datasource.username=sa",
        "spring.datasource.password=",
        "spring.jpa.properties.hibernate.default_schema=invest"
})
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("test")
class FutureRepositoryTest {

    @Autowired
    private FutureRepository futureRepository;

    @Test
    void testFindFigisByAssetType() {
        FutureEntity matchingFuture = new FutureEntity(
                "FIGI_MATCH",
                "SBRF",
                "TYPE_SECURITY",
                "SBER",
                "RUB",
                "MOEX",
                true,
                LocalDateTime.of(2030, 1, 1, 0, 0),
                new BigDecimal("0.01"),
                1,
                new BigDecimal("1.0"));
        FutureEntity nonMatchingFuture = new FutureEntity(
                "FIGI_OTHER",
                "GAZR",
                "TYPE_CURRENCY",
                "GAZP",
                "RUB",
                "MOEX",
                true,
                LocalDateTime.of(2030, 1, 1, 0, 0),
                new BigDecimal("0.01"),
                1,
                new BigDecimal("1.0"));

        futureRepository.save(matchingFuture);
        futureRepository.save(nonMatchingFuture);

        List<String> figis = futureRepository.findFigisByAssetType("TYPE_SECURITY");

        assertEquals(1, figis.size());
        assertTrue(figis.contains("FIGI_MATCH"));
    }
}
