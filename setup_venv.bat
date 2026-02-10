@echo off
setlocal

set VENV_DIR=%~dp0.venv
set REQ=%~dp0requirements.txt

if not exist "%VENV_DIR%\Scripts\python.exe" (
  py -3 -m venv "%VENV_DIR%"
)

call "%VENV_DIR%\Scripts\python.exe" -m pip install --upgrade pip
call "%VENV_DIR%\Scripts\python.exe" -m pip install -r "%REQ%"

echo.
echo Done. Venv at: %VENV_DIR%
pause
