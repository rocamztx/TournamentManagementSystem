@echo off
setlocal

cd /d "%~dp0backend"

echo.
echo ================================================
echo  Gerando JAR do servidor
echo ================================================
echo.

call mvnw.cmd clean package -DskipTests
if errorlevel 1 goto erro

echo.
echo JAR gerado em:
echo %~dp0backend\target\TournamentManagementSystem-0.0.1-SNAPSHOT.jar
echo.
pause
exit /b 0

:erro
echo.
echo Nao foi possivel gerar o JAR do servidor.
echo.
pause
exit /b 1
