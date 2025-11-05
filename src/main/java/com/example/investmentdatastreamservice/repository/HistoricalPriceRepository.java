package com.example.investmentdatastreamservice.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import com.example.investmentdatastreamservice.entity.HistoricalPricesEntity;

public interface HistoricalPriceRepository extends JpaRepository<HistoricalPricesEntity, String> {

    

}
