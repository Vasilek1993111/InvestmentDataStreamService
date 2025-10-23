#!/bin/bash

echo "==========================================="
echo "Starting Investment Data Stream Service"
echo "Environment: PRODUCTION"
echo "==========================================="

# Проверяем наличие .env.prod файла
if [ ! -f ".env.prod" ]; then
    echo "WARNING: .env.prod file not found!"
    echo "Please create .env.prod file based on env.prod.example"
    echo ""
fi

# Загружаем переменные окружения из .env.prod
if [ -f ".env.prod" ]; then
    echo "Loading environment variables from .env.prod..."
    export $(grep -v '^#' .env.prod | grep -v '^$' | xargs)
    echo "Environment variables loaded successfully."
else
    echo "Using default environment variables..."
fi

echo ""
echo "Building application..."
mvn clean compile -DskipTests

if [ $? -ne 0 ]; then
    echo "Build failed! Please check the errors above."
    exit 1
fi

echo ""
echo "Starting application with PROD profile..."
echo "Creating log directories..."
mkdir -p logs/prod/current
mkdir -p logs/prod/archive

echo ""
echo "Application will start on port 8084"
echo "Logs will be written to logs/prod/current/"
echo ""
echo "Press Ctrl+C to stop the application"
echo ""

mvn spring-boot:run -Dspring-boot.run.profiles=prod
