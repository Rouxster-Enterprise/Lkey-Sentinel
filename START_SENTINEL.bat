@echo off
title Lkey Sentinel
rem =====================================================================
rem  LKEY SENTINEL - bulletproof launcher (v2, Jul 22 2026)
rem  Finds a REAL Python and starts the Sentinel in the system tray.
rem  Windows Store "python" decoys FAIL the functional test below and
rem  are skipped automatically - this launcher cannot be fooled by them.
rem =====================================================================
setlocal EnableExtensions
cd /d "%~dp0"
set "SCRIPT=lkey_sentinel.py"
set "PYEXE="
set "PYARG="

if not exist "%SCRIPT%" (
  echo   Cannot find %SCRIPT% next to this launcher.
  echo   Keep START_SENTINEL.bat in the same folder as the Sentinel.
  pause
  exit /b 1
)

rem ---- candidates, best first: windowed launcher, windowed exe, console ----
call :try "pyw" "-3"
call :try "pythonw" ""
call :try "py" "-3"
call :try "python" ""
call :try "%LocalAppData%\Programs\Python\Python313\pythonw.exe" ""
call :try "%LocalAppData%\Programs\Python\Python312\pythonw.exe" ""
call :try "%LocalAppData%\Programs\Python\Python311\pythonw.exe" ""
call :try "%LocalAppData%\Programs\Python\Python310\pythonw.exe" ""
call :try "C:\Python313\pythonw.exe" ""
call :try "C:\Python312\pythonw.exe" ""
call :try "C:\Python311\pythonw.exe" ""

if defined PYEXE (
  echo   Sentinel launching with: %PYEXE% %PYARG%
  start "" "%PYEXE%" %PYARG% "%SCRIPT%" --tray
  exit /b 0
)

echo.
echo   ============================================================
echo   No REAL Python found on this computer.
echo   (The "python" that Windows ships is a Store decoy - it looks
echo    like Python but installs nothing and runs nothing.)
echo.
echo   The 3-step fix:
echo     1. Settings, then "App execution aliases":
echo        turn OFF  python.exe  and  python3.exe
echo     2. Install Python 3.12 from  python.org
echo        and TICK the box "Add python.exe to PATH"
echo     3. Run INSTALL.bat once, then run this file again.
echo   ============================================================
echo.
pause
exit /b 1

:try
rem %1 = interpreter, %2 = optional arg. A Store decoy prints its ad and
rem exits nonzero, so it can never pass this import test.
if defined PYEXE goto :eof
"%~1" %~2 -c "import sys" >nul 2>&1
if errorlevel 1 goto :eof
set "PYEXE=%~1"
set "PYARG=%~2"
goto :eof
