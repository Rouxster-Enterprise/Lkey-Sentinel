@echo off
REM ============================================================
REM   LKEY SENTINEL - one-time setup (v2, decoy-proof).
REM   Double-click ONCE.
REM ============================================================
title Lkey Sentinel Setup
cd /d "%~dp0"
setlocal EnableExtensions
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

REM ---- find a REAL Python. Windows ships FAKE python decoys that
REM ---- pass a "where" check but run nothing; each candidate below
REM ---- must actually execute code, so decoys are skipped for free.
set "PYEXE="
set "PYARG="
call :try "py" "-3"
call :try "python" ""
call :try "%LocalAppData%\Programs\Python\Python313\python.exe" ""
call :try "%LocalAppData%\Programs\Python\Python312\python.exe" ""
call :try "%LocalAppData%\Programs\Python\Python311\python.exe" ""
call :try "%LocalAppData%\Programs\Python\Python310\python.exe" ""
call :try "C:\Python313\python.exe" ""
call :try "C:\Python312\python.exe" ""
call :try "C:\Python311\python.exe" ""
if defined PYEXE goto :install

REM ---- no real Python: try automatic install, else explain plainly ----
echo    Python not found - attempting automatic install...
where winget >nul 2>nul
if errorlevel 1 goto :manual
winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
echo.
echo    Python installed. Please CLOSE this window and run
echo    INSTALL.bat one more time to finish setup.
echo.
pause
exit /b 0

:manual
color 0C
echo.
echo    [!] Could not auto-install Python on this PC.
echo        The 3-step fix:
echo        1. Settings, then "App execution aliases":
echo           turn OFF  python.exe  and  python3.exe
echo           (Windows ships fake ones that block the real thing)
echo        2. Go to python.org/downloads - install Python 3
echo           IMPORTANT: tick "Add Python to PATH"
echo        3. Double-click this INSTALL.bat again.
echo.
pause
exit /b 1

:install
echo    Using real Python: %PYEXE% %PYARG%
echo    [1/2] Installing the small pieces it needs...
"%PYEXE%" %PYARG% -m pip install --quiet --disable-pip-version-check psutil nvidia-ml-py pystray pillow
if errorlevel 1 (
    echo    [!] Some pieces failed - retrying once...
    "%PYEXE%" %PYARG% -m pip install --disable-pip-version-check psutil nvidia-ml-py pystray pillow
)

REM ---- honesty gate: ALL SET may only print if the pieces truly
REM ---- import. This installer can no longer say ALL SET on a failure.
"%PYEXE%" %PYARG% -c "import psutil, pystray, PIL, pynvml" >nul 2>&1
if errorlevel 1 goto :failed
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
exit /b 0

:failed
color 0C
echo.
echo    [!] Setup did NOT finish - the pieces would not install.
echo        Usual causes: no internet, or a network/antivirus block.
echo        Nothing on this PC was changed or broken. Fix the
echo        connection and run this file again - it is safe to
echo        run as many times as you need.
echo.
pause
exit /b 1

:try
if defined PYEXE goto :eof
"%~1" %~2 -c "import sys" >nul 2>&1
if errorlevel 1 goto :eof
set "PYEXE=%~1"
set "PYARG=%~2"
goto :eof
