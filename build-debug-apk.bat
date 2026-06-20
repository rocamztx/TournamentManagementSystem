@echo off
setlocal

cd /d "%~dp0frontend"

echo.
echo ================================================
echo  Gerando APK de teste
echo ================================================
echo.
echo Digite o IPv4 do PC servidor. Exemplo: 192.168.10.50
echo Se deixar vazio, sera usado 192.168.10.50.
echo.
set /p SERVER_IP=IP do servidor: 
if "%SERVER_IP%"=="" set SERVER_IP=192.168.10.50

echo.
echo O APK vai apontar para: http://%SERVER_IP%:8080
echo.

call flutter pub get
if errorlevel 1 goto erro

call flutter build apk --debug --target-platform android-arm64 --dart-define=SERVER_IP=%SERVER_IP% --dart-define=SERVER_PORT=8080
if errorlevel 1 goto erro

echo.
echo APK gerado em:
echo %~dp0frontend\build\app\outputs\flutter-apk\app-debug.apk
echo.
pause
exit /b 0

:erro
echo.
echo Nao foi possivel gerar o APK. Confira se o Flutter esta instalado e no PATH.
echo.
pause
exit /b 1
