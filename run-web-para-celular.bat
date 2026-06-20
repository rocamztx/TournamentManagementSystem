@echo off
setlocal

cd /d "%~dp0frontend"

echo.
echo ================================================
echo  Rodando app Flutter Web para testar no celular
echo ================================================
echo.
echo Digite o IPv4 do PC servidor. Exemplo: 192.168.10.50
echo Se deixar vazio, sera usado 192.168.10.50.
echo.
set /p SERVER_IP=IP do servidor: 
if "%SERVER_IP%"=="" set SERVER_IP=192.168.10.50

echo.
echo Abra no celular:
echo http://%SERVER_IP%:3000
echo.
echo O app Web vai conversar com a API em:
echo http://%SERVER_IP%:8080
echo.

call flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 --dart-define=SERVER_IP=%SERVER_IP% --dart-define=SERVER_PORT=8080

pause
