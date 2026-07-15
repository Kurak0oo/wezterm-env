@echo off
REM Double-click or run: install.cmd -WithCursorTrail
REM Bypasses PowerShell Restricted execution policy on cybercafe / locked PCs.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
