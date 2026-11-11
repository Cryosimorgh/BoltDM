@echo off
setlocal EnableExtensions
set "SRC=%~dp0"
set "DEST=%LOCALAPPDATA%\Programs\BoltDM"

echo Installing BoltDM to:
echo   %DEST%
echo.
if not exist "%SRC%BoltDM.exe" goto :missing
if not exist "%SRC%BoltDM-Launcher.exe" goto :missing
if not exist "%SRC%BoltDM.ico" goto :missing
if not exist "%DEST%" mkdir "%DEST%" || goto :fail

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath '%SRC%' -File -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue"
copy /Y "%SRC%BoltDM.exe" "%DEST%\BoltDM.exe" >nul || goto :fail
copy /Y "%SRC%BoltDM-Launcher.exe" "%DEST%\BoltDM-Launcher.exe" >nul || goto :fail
copy /Y "%SRC%BoltDM.ico" "%DEST%\BoltDM.ico" >nul || goto :fail
if exist "%SRC%yt-dlp.exe" copy /Y "%SRC%yt-dlp.exe" "%DEST%\yt-dlp.exe" >nul || goto :fail
if exist "%SRC%ffmpeg.exe" copy /Y "%SRC%ffmpeg.exe" "%DEST%\ffmpeg.exe" >nul || goto :fail

rem Shortcuts: interactive app launcher, desktop entry, and background startup
rem for download interception after signing into Windows (no admin required).
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $sh=New-Object -ComObject WScript.Shell; $dir=Join-Path $env:LOCALAPPDATA 'Programs\BoltDM'; $exe=Join-Path $dir 'BoltDM-Launcher.exe'; $icon=Join-Path $dir 'BoltDM.ico'; $programs=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'; function Make-Link($p,$shortcutArgs){$s=$sh.CreateShortcut($p);$s.TargetPath=$exe;$s.WorkingDirectory=$dir;$s.IconLocation=$icon;$s.Arguments=$shortcutArgs;$s.Save()}; Make-Link (Join-Path $programs 'BoltDM.lnk') ''; Make-Link (Join-Path $programs 'Startup\BoltDM.lnk') '--background'; Make-Link (Join-Path ([Environment]::GetFolderPath('Desktop')) 'BoltDM.lnk') ''"
if errorlevel 1 goto :fail

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath '%DEST%' -File | Unblock-File -ErrorAction SilentlyContinue"
start "" "%DEST%\BoltDM-Launcher.exe"
echo BoltDM installed. Background startup is enabled for browser capture.
echo Disable startup in Windows Settings - Apps - Startup if preferred.
exit /b 0

:missing
echo Installation files missing. Extract the full BoltDM release ZIP first.
exit /b 1

:fail
echo Installation failed. If BoltDM is running, exit via the tray and retry.
exit /b 1
