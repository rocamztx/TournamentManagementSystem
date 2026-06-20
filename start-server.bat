@echo off
setlocal

cd /d "%~dp0backend"

echo.
echo ================================================
echo  Tournament Management System - Servidor local
echo ================================================
echo.
echo A API vai abrir em: http://0.0.0.0:8080
echo Para o celular, use o IPv4 do seu PC, por exemplo:
echo http://192.168.10.50:8080/api/classificacao/status
echo.
echo Os dados ficam salvos no PostgreSQL configurado em application.properties.
echo Fechar e abrir este servidor nao apaga as pontuacoes.
echo.

call mvnw.cmd spring-boot:run

pause
