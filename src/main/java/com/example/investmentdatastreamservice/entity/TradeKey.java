package com.example.investmentdatastreamservice.entity;

import java.io.Serializable;
import java.time.LocalDateTime;
import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Составной ключ для entity TradeEntity
 * 
 * Содержит FIGI инструмента, временную метку и направление сделки для создания уникального
 * идентификатора записи в таблице обезличенных сделок.
 * 
 * Оптимизирован для высокопроизводительной обработки потоков данных.
 */
@Embeddable
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TradeKey implements Serializable {

    @Column(nullable = false, length = 50)
    private String figi;

    @Column(nullable = false)
    private LocalDateTime time;

    @Column(nullable = false, length = 10)
    private String direction;
}
