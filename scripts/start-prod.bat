@echo off
echo ===========================================
echo Starting Investment Data Stream Service
echo Environment: PRODUCTION
echo ===========================================

REM Проверяем наличие .env.prod файла
if not exist ".env.prod" (
    echo WARNING: .env.prod file not found!
    echo Please create .env.prod file based on env.prod.example
    echo.
)

REM Загружаем переменные окружения из .env.prod
if exist ".env.prod" (
    echo Loading environment variables from .env.prod...
    for /f "usebackq tokens=1,2 delims==" %%a in (".env.prod") do (
        if not "%%a"=="" if not "%%a:~0,1%"=="#" (
            set "%%a=%%b"
        )
    )
    echo Environment variables loaded successfully.
) else (
    echo Using default environment variables...
)

echo.
echo Building application...
call mvn clean compile -DskipTests

if %ERRORLEVEL% neq 0 (
    echo Build failed! Please check the errors above.
    pause
    exit /b 1
)

echo.
echo Starting application with PROD profile...
echo Creating log directories...
if not exist "logs\prod\current" mkdir "logs\prod\current"
if not exist "logs\prod\archive" mkdir "logs\prod\archive"

echo.
echo Application will start on port 8084
echo Logs will be written to logs/prod/current/
echo.
echo Press Ctrl+C to stop the application
echo.

call mvn spring-boot:run -Dspring-boot.run.profiles=prod

pause
