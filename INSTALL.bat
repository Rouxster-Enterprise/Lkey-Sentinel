@echo off
REM ============================================================
REM   LKEY SENTINEL - one-time setup. Double-click ONCE.
REM ============================================================
title Lkey Sentinel Setup
cd /d "%~dp0"
color 0A
echo.
echo    ================================================
echo      LKEY SENTINEL - protecting this computer
echo    ================================================
echo.
echo    Installs a tiny background guardian that warns
echo    before the PC gets too hot or stressed, and can
echo    text an alert to a phone if something goes wrong.
echo.
echo    Setting up now (needs internet, about a minute)...
echo.

REM --- find Python; try to auto-install via winget if absent ---
where python >nul 2>nul
if errorlevel 1 (
    echo    Python not found - attempting automatic install...
    where winget >nul 2>nul
    if errorlevel 1 (
        color 0C
        echo.
        echo    [!] Could not auto-install Python on this PC.
        echo        1. Go to python.org/downloads
        echo        2. Download Python 3, run it
        echo        3. IMPORTANT: tick "Add Python to PATH"
        echo        4. Then double-click this INSTALL.bat again.
        echo.
        pause
        exit /b
    )
    winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
    echo    Python installed. Please CLOSE this window and run
    echo    INSTALL.bat one more time to finish setup.
    echo.
    pause
    exit /b
)

echo    [1/2] Installing the small pieces it needs...
python -m pip install --quiet --disable-pip-version-check psutil nvidia-ml-py pystray pillow
if errorlevel 1 (
    echo    [!] Some pieces failed - retrying once...
    python -m pip install --disable-pip-version-check psutil nvidia-ml-py pystray pillow
)
echo         done.

echo    [2/2] Making the desktop shortcut...
set "TARGET=%~dp0START_SENTINEL.bat"
powershell -NoProfile -Command "$w=New-Object -ComObject WScript.Shell; $s=$w.CreateShortcut([Environment]::GetFolderPath('Desktop')+'\Lkey Sentinel.lnk'); $s.TargetPath='%TARGET%'; $s.WorkingDirectory='%~dp0'; $s.IconLocation='%SystemRoot%\System32\shell32.dll,77'; $s.Save()"
echo         done.

echo.
color 0A
echo    ================================================
echo      ALL SET!  A "Lkey Sentinel" icon is now on the
echo      desktop. Double-click it before gaming to turn
echo      on protection. A green dot near the clock means
echo      it's watching. That's the whole thing!
echo    ================================================
echo.
pause
