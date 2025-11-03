# ===========================================
# Multi-stage Dockerfile для Investment Data Stream Service
# ===========================================

# Stage 1: Build stage - сборка приложения
FROM maven:3.9-eclipse-temurin-21 AS build

# Установка рабочей директории
WORKDIR /app

# Копирование pom.xml для кэширования зависимостей
COPY pom.xml .

# Загрузка зависимостей (кэшируется если pom.xml не изменился)
RUN mvn dependency:go-offline -B

# Копирование исходного кода
COPY src ./src

# Сборка приложения (без запуска тестов для ускорения сборки)
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime stage - минимальный образ для запуска
FROM eclipse-temurin:21-jre-alpine

# Метаданные образа
LABEL maintainer="Investment Data Stream Service Team"
LABEL description="Investment Data Stream Service - Real-time market data processing with T-Invest API"
LABEL version="0.0.1"

# Установка curl для health check
RUN apk add --no-cache curl

# Создание непривилегированного пользователя для безопасности
RUN addgroup -S spring && adduser -S spring -G spring

# Установка рабочей директории
WORKDIR /app

# Копирование JAR файла из stage сборки
COPY --from=build /app/target/*.jar app.jar

# Изменение владельца файлов на непривилегированного пользователя
RUN chown -R spring:spring /app

# Переключение на непривилегированного пользователя
USER spring:spring

# Создание директории для логов
RUN mkdir -p /app/logs

# Открытие порта приложения
EXPOSE 8084

# Health check для мониторинга состояния контейнера
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8084/actuator/health || exit 1

# Переменные окружения по умолчанию
ENV SPRING_PROFILES_ACTIVE=prod \
    JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200" \
    TZ=Europe/Moscow

# Запуск приложения
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
