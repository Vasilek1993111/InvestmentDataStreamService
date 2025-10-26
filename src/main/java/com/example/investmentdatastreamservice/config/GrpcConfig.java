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
import io.github.cdimascio.dotenv.Dotenv;

/**
 * Конфигурация gRPC клиентов для работы с T-Invest API
 * 
 * Настраивает подключение к T-Invest API через gRPC с аутентификацией и создает необходимые stub'ы
 * для различных сервисов.
 */
@Configuration
public class GrpcConfig {

    private static final Logger logger = LoggerFactory.getLogger(GrpcConfig.class);

    @Value("${tinkoff.api.token}")
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
        
        // Загружаем токен напрямую из .env файла
        String actualToken = loadTokenFromEnv();
        
        logger.info("Spring token length: {}", token != null ? token.length() : "NULL");
        logger.info("Spring token starts with: {}", token != null && token.length() > 4 ? token.substring(0, 4) + "***" : "***");
        logger.info("Actual token length: {}", actualToken != null ? actualToken.length() : "NULL");
        logger.info("Actual token starts with: {}", actualToken != null && actualToken.length() > 4 ? actualToken.substring(0, 4) + "***" : "***");
        
        logger.info("=== INVEST API CREATED ===");
        return InvestApi.create(actualToken != null ? actualToken : token);
    }
    
    /**
     * Загружает токен напрямую из .env файла
     */
    private String loadTokenFromEnv() {
        try {
            // Определяем активный профиль
            String activeProfile = System.getProperty("spring.profiles.active", "test");
            String envFile = getEnvFileName(activeProfile);
            
            logger.info("Loading token from: {}", envFile);
            
            Dotenv dotenv = Dotenv.configure()
                .filename(envFile)
                .ignoreIfMalformed()
                .ignoreIfMissing()
                .load();
            
            String token = dotenv.get("T_INVEST_TEST_TOKEN");
            if (token == null || token.trim().isEmpty()) {
                logger.warn("T_INVEST_TEST_TOKEN not found in {}, using Spring value", envFile);
                return token;
            }
            
            logger.info("Successfully loaded token from {}", envFile);
            return token;
            
        } catch (Exception e) {
            logger.error("Error loading token from .env file: {}", e.getMessage());
            logger.warn("Falling back to Spring property value");
            return token;
        }
    }
    
    /**
     * Определяет имя .env файла в зависимости от активного профиля
     */
    private String getEnvFileName(String activeProfile) {
        switch (activeProfile.toLowerCase()) {
            case "test":
                return ".env.test";
            case "prod":
            case "production":
                return ".env.prod";
            default:
                return ".env";
        }
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
