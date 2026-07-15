# Launch WezTerm trail build with WEZTERM_CURSOR_TRAIL=1
# Prefer Start-WezTerm-CursorTrail.bat on Restricted PCs (no execution policy).
param(
    [string]$InstallDir = $(Join-Path $env:LOCALAPPDATA 'WezTerm-Trail')
)

$candidates = @(
    (Join-Path $InstallDir 'wezterm-gui.exe'),
    (Join-Path $InstallDir 'wezterm.exe'),
    (Join-Path $env:USERPROFILE 'src\wezterm-cursor-trail\target\release\wezterm-gui.exe'),
    'C:\Users\Personal\Projects\wezterm-cursor-trail\target\release\wezterm-gui.exe'
)

$exe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $exe) {
    Write-Host "Trail WezTerm binary not found under $InstallDir" -ForegroundColor Red
    Write-Host "Run: powershell -ExecutionPolicy Bypass -File .\install.ps1 -WithCursorTrail"
    Write-Host "Or download: https://github.com/Kurak0oo/wezterm-env/releases"
    exit 1
}

$dir = Split-Path -Parent $exe
$env:Path = "$dir;" + $env:Path
$env:WEZTERM_CURSOR_TRAIL = '1'
Start-Process -FilePath $exe -WorkingDirectory $env:USERPROFILE
