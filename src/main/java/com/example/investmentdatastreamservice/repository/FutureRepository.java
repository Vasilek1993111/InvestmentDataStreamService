package com.example.investmentdatastreamservice.repository;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.example.investmentdatastreamservice.entity.FutureEntity;

/**
 * Repository для работы с фьючерсами
 * 
 * Предоставляет методы для поиска и получения информации о торговых инструментах типа "фьючерс".
 */
@Repository
public interface FutureRepository extends JpaRepository<FutureEntity, String> {

    /**
     * Найти FIGI фьючерсов по типу актива
     * 
     * @param assetType тип актива
     * @return список FIGI фьючерсов
     */
    @Query("SELECT f.figi FROM FutureEntity f WHERE f.assetType = :assetType")
    List<String> findFigisByAssetType(@Param("assetType") String assetType);

    /**
     * Найти все FIGI фьючерсов
     * 
     * @return список FIGI всех фьючерсов
     */
    @Query("SELECT f.figi FROM FutureEntity f")
    List<String> findAllFigis();
}
