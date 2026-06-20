@echo off
setlocal

set JAR=%~dp0backend\target\TournamentManagementSystem-0.0.1-SNAPSHOT.jar

if not exist "%JAR%" (
  echo.
  echo JAR nao encontrado. Rode build-server-jar.bat primeiro.
  echo.
  pause
  exit /b 1
)

echo.
echo ================================================
echo  Iniciando servidor pelo JAR
echo ================================================
echo.
echo API local: http://localhost:8080/api/classificacao/status
echo API na rede: http://IP_DO_PC:8080/api/classificacao/status
echo.

java -jar "%JAR%"

pause
