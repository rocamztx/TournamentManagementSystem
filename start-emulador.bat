@echo off
setlocal

echo ================================================
echo  Iniciando Emulador Android FRC
echo ================================================
echo.

set EMULATOR_PATH=C:\Users\Administrator\AppData\Local\Android\Sdk\emulator\emulator.exe

if not exist "%EMULATOR_PATH%" (
    echo [ERRO] O emulador nao foi encontrado no caminho padrao:
    echo %EMULATOR_PATH%
    pause
    exit /b 1
)

echo Iniciando o emulador FRC sem carregar snapshot anterior...
start "" "%EMULATOR_PATH%" -avd FRC -no-snapshot

echo.
echo Emulador enviado para o segundo plano.
echo Voce ja pode fechar esta janela do prompt.
echo.
timeout /t 3 > nul
exit /b 0
