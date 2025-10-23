package com.example.investmentdatastreamservice.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "indicatives", schema = "invest")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class IndicativeEntity {
    @Id
    private String figi;
    private String ticker;
    private String name;
    private String currency;
    private String exchange;
    private String classCode;
    private String uid;
    private Boolean sellAvailableFlag;
    private Boolean buyAvailableFlag;
}
