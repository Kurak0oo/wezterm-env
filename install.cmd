@echo off
REM Always Bypass so Restricted PCs can install
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
