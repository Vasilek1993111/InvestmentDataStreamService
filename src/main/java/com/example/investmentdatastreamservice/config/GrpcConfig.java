package com.example.investmentdatastreamservice.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import io.grpc.ClientInterceptor;
import io.grpc.ForwardingClientCall;
import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import io.grpc.Metadata;
import ru.tinkoff.piapi.contract.v1.InstrumentsServiceGrpc;
import ru.tinkoff.piapi.contract.v1.MarketDataServiceGrpc;
import ru.tinkoff.piapi.contract.v1.MarketDataStreamServiceGrpc;
import ru.tinkoff.piapi.contract.v1.UsersServiceGrpc;
import ru.tinkoff.piapi.core.InvestApi;
import ru.tinkoff.piapi.core.MarketDataService;

/**
 * Конфигурация gRPC клиентов для работы с T-Invest API
 * 
 * Настраивает подключение к T-Invest API через gRPC с аутентификацией и создает необходимые stub'ы
 * для различных сервисов.
 */
@Configuration
public class GrpcConfig {

    private static final Logger logger = LoggerFactory.getLogger(GrpcConfig.class);

    @Value("${T_INVEST_TEST_TOKEN:${T_INVEST_PROD_TOKEN:your-token-here}}")
    private String token;

    /**
     * Создает управляемый канал для подключения к T-Invest API с оптимизацией для потоковых данных
     * 
     * @return настроенный ManagedChannel с аутентификацией и оптимизацией для минимальных задержек
     */
    @Bean
    public ManagedChannel investChannel() {
        ClientInterceptor authInterceptor = new ClientInterceptor() {
            @Override
            public <ReqT, RespT> io.grpc.ClientCall<ReqT, RespT> interceptCall(
                    io.grpc.MethodDescriptor<ReqT, RespT> method, io.grpc.CallOptions callOptions,
                    io.grpc.Channel next) {
                return new ForwardingClientCall.SimpleForwardingClientCall<>(
                        next.newCall(method, callOptions)) {
                    @Override
                    public void start(Listener<RespT> responseListener, Metadata headers) {
                        headers.put(
                                Metadata.Key.of("Authorization", Metadata.ASCII_STRING_MARSHALLER),
                                "Bearer " + token);
                        super.start(responseListener, headers);
                    }
                };
            }
        };

        return ManagedChannelBuilder.forAddress("invest-public-api.tinkoff.ru", 443)
                .useTransportSecurity().intercept(authInterceptor)
                // Оптимизация для потоковых данных с минимальными задержками
                .keepAliveTime(30, java.util.concurrent.TimeUnit.SECONDS)
                .keepAliveTimeout(5, java.util.concurrent.TimeUnit.SECONDS)
                .keepAliveWithoutCalls(true).maxInboundMessageSize(4 * 1024 * 1024) // 4MB
                .maxInboundMetadataSize(8 * 1024) // 8KB
                .enableRetry().maxRetryAttempts(3).build();
    }

    /**
     * Создает stub для потокового сервиса рыночных данных
     * 
     * @param channel управляемый канал
     * @return MarketDataStreamServiceStub для потоковой передачи данных
     */
    @Bean
    public MarketDataStreamServiceGrpc.MarketDataStreamServiceStub marketDataStreamStub(
            ManagedChannel channel) {
        return MarketDataStreamServiceGrpc.newStub(channel);
    }

    /**
     * Создает блокирующий stub для сервиса пользователей
     * 
     * @param channel управляемый канал
     * @return UsersServiceBlockingStub для работы с пользователями
     */
    @Bean
    public UsersServiceGrpc.UsersServiceBlockingStub usersServiceStub(ManagedChannel channel) {
        return UsersServiceGrpc.newBlockingStub(channel);
    }

    /**
     * Создает блокирующий stub для сервиса инструментов
     * 
     * @param channel управляемый канал
     * @return InstrumentsServiceBlockingStub для работы с инструментами
     */
    @Bean
    public InstrumentsServiceGrpc.InstrumentsServiceBlockingStub instrumentsServiceStub(
            ManagedChannel channel) {
        return InstrumentsServiceGrpc.newBlockingStub(channel);
    }

    /**
     * Создает асинхронный stub для сервиса рыночных данных
     * 
     * @param channel управляемый канал
     * @return MarketDataServiceFutureStub для асинхронной работы с рыночными данными
     */
    @Bean
    public MarketDataServiceGrpc.MarketDataServiceFutureStub marketDataServiceFutureStub(
            ManagedChannel channel) {
        return MarketDataServiceGrpc.newFutureStub(channel);
    }

    /**
     * Создает InvestApi с токеном аутентификации
     * 
     * @return настроенный InvestApi для работы с T-Invest API
     */
    @Bean
    public InvestApi investApi() {
        logger.info("=== CREATING INVEST API ===");
        logger.info("Token loaded from Spring properties: {}", token != null && token.length() > 4 ? 
            token.substring(0, 4) + "***" : "NULL");
        
        if (token == null || token.trim().isEmpty() || "your-token-here".equals(token)) {
            logger.error("Tinkoff API token is not properly configured!");
            throw new IllegalStateException("Tinkoff API token is not configured. Please check your .env file.");
        }
        
        logger.info("=== INVEST API CREATED ===");
        return InvestApi.create(token);
    }

    /**
     * Создает MarketDataService из InvestApi
     * 
     * @param investApi настроенный InvestApi
     * @return MarketDataService для работы с рыночными данными
     */
    @Bean
    public MarketDataService marketDataService(InvestApi investApi) {
        logger.info("Creating MarketDataService with InvestApi");
        return investApi.getMarketDataService();
    }
}
