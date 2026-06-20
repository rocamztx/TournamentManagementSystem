@echo off
echo.
echo Este script libera a porta 8080 no Firewall do Windows para os celulares
echo conseguirem acessar a API do servidor.
echo.
echo Execute como Administrador se o Windows negar permissao.
echo.

netsh advfirewall firewall add rule name="Tournament Management API 8080" dir=in action=allow protocol=TCP localport=8080

echo.
echo Se apareceu "Ok.", a porta 8080 foi liberada.
echo.
pause
