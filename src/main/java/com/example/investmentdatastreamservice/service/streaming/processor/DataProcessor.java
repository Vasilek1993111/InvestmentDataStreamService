package com.example.investmentdatastreamservice.service.streaming.processor;

import java.util.concurrent.CompletableFuture;

/**
 * Интерфейс для обработки потоковых данных
 * 
 * Определяет контракт для процессоров различных типов данных,
 * поступающих от внешних API.
 * 
 * @param <T> тип обрабатываемых данных
 */
public interface DataProcessor<T> {
    
    /**
     * Обработка единичного элемента данных
     * 
     * @param data данные для обработки
     * @return CompletableFuture, завершающийся при обработке
     */
    CompletableFuture<Void> process(T data);
    
    /**
     * Обработка ошибок
     * 
     * @param error ошибка для обработки
     */
    void handleError(Throwable error);
}


