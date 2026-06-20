@echo off
echo ========================================
echo   BUILD APK DEFINITIVO - DYNAMIC CONFIG
echo ========================================
echo.

REM Define o diretório do projeto
set PROJECT_DIR=%~dp0frontend

echo [1/5] Verificando Flutter...
flutter --version
if %ERRORLEVEL% NEQ 0 (
    echo Erro: Flutter nao encontrado. Instale o Flutter SDK.
    pause
    exit /b 1
)

echo.
echo [2/5] Limpando build anterior...
cd /d "%PROJECT_DIR%"
flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo Erro ao limpar o projeto.
    pause
    exit /b 1
)

echo.
echo [3/5] Atualizando dependencias...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo Erro ao atualizar dependencias.
    pause
    exit /b 1
)

echo.
echo [4/5] Gerando APK Release...
flutter build apk --release --split-per-abi
if %ERRORLEVEL% NEQ 0 (
    echo Erro ao gerar APK.
    pause
    exit /b 1
)

echo.
echo [5/5] Build Completo!
echo.
echo APKs gerados em:
echo %PROJECT_DIR%\build\app\outputs\flutter-apk\
echo.
echo Arquivos criados:
dir "%PROJECT_DIR%\build\app\outputs\flutter-apk\" /b
echo.
echo ========================================
echo   BUILD FINALIZADO COM SUCESSO
echo ========================================
echo.
echo Características do APK:
echo ✓ Detecção dinâmica de IP/Servidor
echo ✓ Tela de configuração integrada
echo ✓ Armazenamento persistente
echo ✓ Menu de reconfiguração
echo.
pause
