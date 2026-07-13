# Remove wezterm-env managed files (does not uninstall winget packages)
param(
    [switch]$RemoveTrailBinary,
    [switch]$RestoreBackups
)

$ErrorActionPreference = 'Continue'
Write-Host "Uninstalling wezterm-env managed copies (packages kept)..."

$cfg = Join-Path $env:USERPROFILE '.wezterm.lua'
$prof = Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$start = Join-Path $env:USERPROFILE 'Start-WezTerm-CursorTrail.ps1'
$cmd = Join-Path $env:USERPROFILE 'bin\wezterm-trail.cmd'
$trail = Join-Path $env:LOCALAPPDATA 'WezTerm-Trail'
$desk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'WezTerm Cursor Trail.lnk'

foreach ($p in @($start, $cmd, $desk)) {
    if (Test-Path $p) { Remove-Item $p -Force; Write-Host "Removed $p" }
}

if ($RemoveTrailBinary -and (Test-Path $trail)) {
    Remove-Item $trail -Recurse -Force
    Write-Host "Removed $trail"
}

if ($RestoreBackups) {
    $latestCfg = Get-ChildItem "$cfg.bak.*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestCfg) { Copy-Item $latestCfg.FullName $cfg -Force; Write-Host "Restored config from $($latestCfg.Name)" }
    $latestProf = Get-ChildItem "$prof.bak.*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestProf) { Copy-Item $latestProf.FullName $prof -Force; Write-Host "Restored profile from $($latestProf.Name)" }
} else {
    Write-Host "Left $cfg and profile in place (use -RestoreBackups to restore .bak.*)."
}

Write-Host "Done. winget apps (WezTerm, Oh My Posh, pwsh) were not removed."
