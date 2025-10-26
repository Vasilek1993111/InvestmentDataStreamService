package com.example.investmentdatastreamservice.dto;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LimitsDto {
    private String instrumentId;
    private BigDecimal limitDown;
    private BigDecimal limitUp;
}
