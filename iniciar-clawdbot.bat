@echo off
setlocal enabledelayedexpansion
title Clawdbot Launcher
color 0A

:MENU
cls
echo ============================================
echo       CLAWDBOT + CLIProxyAPI LAUNCHER
echo ============================================
echo.
echo Escolha uma opcao:
echo.
echo [1] Login no Gemini CLI
echo [2] Login no Claude Code
echo [3] Login no Codex CLI
echo [4] Login no Qwen CLI
echo [5] Apenas iniciar servidor (pular login)
echo [0] Sair
echo.
set /p OPCAO="Digite sua escolha: "

if "%OPCAO%"=="1" goto LOGIN_GEMINI
if "%OPCAO%"=="2" goto LOGIN_CLAUDE
if "%OPCAO%"=="3" goto LOGIN_CODEX
if "%OPCAO%"=="4" goto LOGIN_QWEN
if "%OPCAO%"=="5" goto START_SERVER
if "%OPCAO%"=="0" exit /b 0
echo Opcao invalida!
timeout /t 2 >nul
goto MENU

:LOGIN_GEMINI
cls
echo ============================================
echo         LOGIN NO GEMINI CLI
echo ============================================
echo.
cd /d "%~dp0CLIProxyAPI"
cli-proxy-api.exe --login
if errorlevel 1 (
    echo.
    echo [ERRO] Falha no login do Gemini!
    pause
    goto MENU
)
echo.
echo [OK] Login no Gemini concluido!
timeout /t 2 >nul
goto MENU

:LOGIN_CLAUDE
cls
echo ============================================
echo        LOGIN NO CLAUDE CODE
echo ============================================
echo.
cd /d "%~dp0CLIProxyAPI"
cli-proxy-api.exe --claude-login
if errorlevel 1 (
    echo.
    echo [ERRO] Falha no login do Claude!
    pause
    goto MENU
)
echo.
echo [OK] Login no Claude concluido!
timeout /t 2 >nul
goto MENU

:LOGIN_CODEX
cls
echo ============================================
echo         LOGIN NO CODEX CLI
echo ============================================
echo.
cd /d "%~dp0CLIProxyAPI"
cli-proxy-api.exe --codex-login
if errorlevel 1 (
    echo.
    echo [ERRO] Falha no login do Codex!
    pause
    goto MENU
)
echo.
echo [OK] Login no Codex concluido!
timeout /t 2 >nul
goto MENU

:LOGIN_QWEN
cls
echo ============================================
echo         LOGIN NO QWEN CLI
echo ============================================
echo.
cd /d "%~dp0CLIProxyAPI"
cli-proxy-api.exe --qwen-login
if errorlevel 1 (
    echo.
    echo [ERRO] Falha no login do Qwen!
    pause
    goto MENU
)
echo.
echo [OK] Login no Qwen concluido!
timeout /t 2 >nul
goto MENU

:START_SERVER
cls
echo ============================================
echo       INICIANDO CLAWDBOT + CLIPROXYAPI
echo ============================================
echo.

:: Navegar para a pasta do projeto
cd /d "%~dp0"

:: Verificar se Docker esta rodando
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Docker Desktop nao esta rodando!
    echo Por favor, inicie o Docker Desktop primeiro.
    pause
    goto MENU
)

:: Ler token do arquivo .env
set "GATEWAY_TOKEN="
for /f "tokens=1,* delims==" %%a in ('findstr /r "^CLAWDBOT_GATEWAY_TOKEN=" .env 2^>nul') do set "GATEWAY_TOKEN=%%b"

if "%GATEWAY_TOKEN%"=="" (
    echo [ERRO] Token nao encontrado no .env!
    echo Verifique se CLAWDBOT_GATEWAY_TOKEN esta definido.
    pause
    goto MENU
)

echo [1/3] Iniciando CLIProxyAPI...
start "CLIProxyAPI - NAO FECHE" cmd /k "cd /d "%~dp0CLIProxyAPI" && cli-proxy-api.exe"

echo [2/3] Aguardando proxy iniciar...
timeout /t 6 /nobreak >nul

:: Testar se proxy esta rodando (tenta 3 vezes)
set PROXY_OK=0
for /l %%i in (1,1,3) do (
    if !PROXY_OK!==0 (
        curl -s http://localhost:8317/v1/models >nul 2>&1
        if not errorlevel 1 set PROXY_OK=1
        if !PROXY_OK!==0 timeout /t 2 /nobreak >nul
    )
)
if %PROXY_OK%==1 (
    echo [OK] Proxy respondendo!
) else (
    echo [AVISO] Proxy pode nao estar pronto. Verifique a janela do CLIProxyAPI.
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
echo Pressione qualquer tecla para voltar ao menu ou feche esta janela.
pause >nul
goto MENU
