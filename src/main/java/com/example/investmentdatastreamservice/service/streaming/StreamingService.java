package com.example.investmentdatastreamservice.service.streaming;

import java.util.concurrent.CompletableFuture;

/**
 * Базовый интерфейс для всех потоковых сервисов
 * 
 * Определяет стандартный контракт для сервисов, работающих с потоковыми данными
 * от внешних API (T-Invest, другие брокеры).
 * 
 * @param <T> тип обрабатываемых данных
 */
public interface StreamingService<T> {
    
    /**
     * Запуск потокового сервиса
     * 
     * @return CompletableFuture, завершающийся при успешном запуске
     */
    CompletableFuture<Void> start();
    
    /**
     * Остановка потокового сервиса
     * 
     * @return CompletableFuture, завершающийся при корректной остановке
     */
    CompletableFuture<Void> stop();
    
    /**
     * Принудительное переподключение
     * 
     * @return CompletableFuture, завершающийся при переподключении
     */
    CompletableFuture<Void> reconnect();
    
    /**
     * Проверка состояния сервиса
     * 
     * @return true если сервис запущен
     */
    boolean isRunning();
    
    /**
     * Проверка состояния подключения
     * 
     * @return true если подключен к внешнему API
     */
    boolean isConnected();
    
    /**
     * Получение метрик сервиса
     * 
     * @return объект с метриками производительности
     */
    StreamingMetrics getMetrics();
    
    /**
     * Получение имени сервиса для логирования и мониторинга
     * 
     * @return уникальное имя сервиса
     */
    String getServiceName();
    
    /**
     * Получение типа обрабатываемых данных
     * 
     * @return класс типа данных
     */
    Class<T> getDataType();
}


