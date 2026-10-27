#Requires -Version 5.1
<#
.SYNOPSIS
  Remove what install.ps1 set up. winget packages (WezTerm, pwsh, Oh My Posh) are kept.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -RemoveTrailBinary -RestoreBackups
#>
param(
    [switch]$RemoveTrailBinary,
    # Put back the newest .bak.* of ~\.wezterm.lua instead of deleting it.
    [switch]$RestoreBackups,
    [switch]$RemoveFont
)

$ErrorActionPreference = 'Stop'

function Remove-IfExists([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
        Write-Host "  Removed $Path"
    }
}

Write-Host "Uninstalling wezterm-env ..."

# Profile: drop the managed dot-source line from both PowerShell profiles.
$marker = '# wezterm-env (managed line, removed by uninstall.ps1)'
$docs = [Environment]::GetFolderPath('MyDocuments')
foreach ($sub in 'PowerShell', 'WindowsPowerShell') {
    $profPath = Join-Path $docs "$sub\Microsoft.PowerShell_profile.ps1"
    if (-not (Test-Path $profPath)) { continue }
    $lines = @(Get-Content $profPath)
    $kept = @($lines | Where-Object { $_ -notlike "*$marker*" })
    if ($kept.Count -ne $lines.Count) {
        if (($kept -join '').Trim()) { Set-Content $profPath $kept -Encoding UTF8 } else { Remove-Item $profPath -Force }
        Write-Host "  Unlinked $profPath"
    }
}
Remove-IfExists (Join-Path $env:USERPROFILE '.config\wezterm-env')

# WezTerm config
$cfg = Join-Path $env:USERPROFILE '.wezterm.lua'
$backup = Get-ChildItem "$cfg.bak.*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($RestoreBackups -and $backup) {
    Copy-Item $backup.FullName $cfg -Force
    Write-Host "  Restored $cfg from $($backup.Name)"
} else {
    Remove-IfExists $cfg
}

# Trail launcher + shortcut (and files from older installers)
Remove-IfExists (Join-Path ([Environment]::GetFolderPath('Desktop')) 'WezTerm Cursor Trail.lnk')
$trail = Join-Path $env:LOCALAPPDATA 'WezTerm-Trail'
if ($RemoveTrailBinary) {
    Remove-IfExists $trail
} else {
    Remove-IfExists (Join-Path $trail 'Start-WezTerm-CursorTrail.bat')
}
& (Join-Path $PSScriptRoot 'scripts\Remove-LegacyInstall.ps1')

if ($RemoveFont) {
    $regKey = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    $props = Get-ItemProperty $regKey -ErrorAction SilentlyContinue
    if ($props) {
        foreach ($p in $props.PSObject.Properties | Where-Object { $_.Name -like '0xProto*Nerd*Font*' }) {
            Remove-ItemProperty -Path $regKey -Name $p.Name
            # The file may stay locked until sign-out if an app still uses the font.
            Remove-Item -LiteralPath $p.Value -Force -ErrorAction SilentlyContinue
            Write-Host "  Removed font $($p.Name)"
        }
    }
}

Write-Host "Done. winget apps (WezTerm, Oh My Posh, pwsh) were not removed."
