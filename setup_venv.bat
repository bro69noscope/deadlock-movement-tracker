@echo off
setlocal
title Setting up Python environment

echo ==========================================
echo   Deadlock Movement Tracker - Setup
echo ==========================================
echo.
echo This will prepare the Python tools needed
echo to show graphs and statistics.
echo.
echo No system files will be changed.
echo.
echo If this is your first time running the app,
echo this setup only needs to be done once.
echo.


py -3 --version >nul 2>&1
if errorlevel 1 (
  echo Python was not found on this computer.
  echo.
  echo Please install Python 3 from:
  echo https://www.python.org/downloads/
  echo.
  echo During installation, make sure to check:
  echo   [x] Add Python to PATH
  echo.
  pause
  exit /b 1
)

set VENV_DIR=%~dp0.venv
set REQ=%~dp0requirements.txt

if not exist "%VENV_DIR%\Scripts\python.exe" (
  echo Creating a private Python environment...
  py -3 -m venv "%VENV_DIR%"
) else (
  echo Python environment already exists.
)

echo.
echo Installing required Python packages...
call "%VENV_DIR%\Scripts\python.exe" -m pip install --upgrade pip >nul
call "%VENV_DIR%\Scripts\python.exe" -m pip install -r "%REQ%"

if errorlevel 1 (
  echo.
  echo Something went wrong while installing packages.
  echo Please try running this file again.
  pause
  exit /b 1
)

echo.
echo ==========================================
echo Setup complete!
echo.
echo Python tools are ready.
echo You can now use graphs inside the app.
echo.
echo (You can close this window.)
echo ==========================================
pause
