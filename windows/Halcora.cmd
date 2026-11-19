@echo off
rem Double-click this file to run Halcora in a window on Windows.
rem It starts Halcora-VM.ps1 from the same folder. Nothing here touches your Windows disk.
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Halcora-VM.ps1" %*
if errorlevel 1 (
    echo.
    echo Halcora did not start. Read the message above, then press a key.
    pause >nul
)
