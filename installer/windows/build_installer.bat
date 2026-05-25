@echo off
setlocal

if "%1"=="" (
  echo Usage: build_installer.bat VERSION
  echo Example: build_installer.bat 0.0.3
  exit /B 1
)

set VERSION=%1
set SCRIPT_DIR=%~dp0

if not exist "%SCRIPT_DIR%..\..\build\windows\x64\runner\Release\" (
  echo Error: build\windows\x64\runner\Release\ not found.
  echo Run "flutter build windows --release" first.
  exit /B 1
)

iscc "%SCRIPT_DIR%setup.iss" /dMyAppVersion=%VERSION%
if %ERRORLEVEL% NEQ 0 (
  echo InnoSetup compilation failed.
  exit /B 1
)

echo Installer created: %SCRIPT_DIR%output\pr_list-setup-%VERSION%.exe
