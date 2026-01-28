@echo off
title Clawdbot Launcher
color 0A

echo ============================================
echo       CLAWDBOT + CLIProxyAPI LAUNCHER
echo ============================================
echo.

:: Verificar se Docker esta rodando
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Docker Desktop nao esta rodando!
    echo Por favor, inicie o Docker Desktop primeiro.
    pause
    exit /b 1
)

:: Navegar para a pasta do projeto
cd /d "%~dp0"

:: Ler token do arquivo .env
set "GATEWAY_TOKEN="
for /f "tokens=1,* delims==" %%a in ('findstr /r "^CLAWDBOT_GATEWAY_TOKEN=" .env 2^>nul') do set "GATEWAY_TOKEN=%%b"

if "%GATEWAY_TOKEN%"=="" (
    echo [ERRO] Token nao encontrado no .env!
    echo Verifique se CLAWDBOT_GATEWAY_TOKEN esta definido.
    pause
    exit /b 1
)

echo [1/3] Iniciando CLIProxyAPI...
start "CLIProxyAPI" /min "%USERPROFILE%\CLIProxyAPI\cli-proxy-api.exe"

echo [2/3] Aguardando proxy iniciar...
timeout /t 4 /nobreak >nul

:: Testar se proxy esta rodando
curl -s http://localhost:8317/v1/models >nul 2>&1
if errorlevel 1 (
    echo [AVISO] Proxy pode nao estar pronto ainda...
) else (
    echo [OK] Proxy respondendo!
)

echo [3/3] Iniciando Clawdbot Docker...
docker-compose up -d

echo.
echo ============================================
echo              PRONTO!
echo ============================================
echo.
echo Acesse: http://localhost:18789/?token=%GATEWAY_TOKEN%
echo.
echo Para parar: docker-compose down
echo.
pause
