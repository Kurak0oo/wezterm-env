# Launch WezTerm trail build with WEZTERM_CURSOR_TRAIL=1 so config enables smear opts
param(
    [string]$InstallDir = $(Join-Path $env:LOCALAPPDATA 'WezTerm-Trail')
)

$candidates = @(
    (Join-Path $InstallDir 'wezterm-gui.exe'),
    (Join-Path $InstallDir 'wezterm.exe'),
    'C:\src\wezterm-cursor-trail\target\release\wezterm-gui.exe'
)

$exe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $exe) {
    Write-Error @"
Trail WezTerm binary not found.
Run: .\install.ps1 -WithCursorTrail
Or build: .\scripts\Build-WezTerm-Trail.ps1
Expected under: $InstallDir
"@
    exit 1
}

$dir = Split-Path -Parent $exe
$env:Path = "$dir;" + $env:Path
$env:WEZTERM_CURSOR_TRAIL = '1'
Start-Process -FilePath $exe -WorkingDirectory $env:USERPROFILE
