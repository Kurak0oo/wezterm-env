#Requires -Version 5.1
<#
.SYNOPSIS
  Deploy Kurak0oo/wezterm-env on Windows (WezTerm + PowerShell profile + fonts + optional trail).

.NOTES
  Restricted / cybercafe machines often block scripts and break winget.
  Always prefer:
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -WithCursorTrail
  Or double-click install.cmd in the repo root.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\install.ps1
  powershell -ExecutionPolicy Bypass -File .\install.ps1 -WithCursorTrail -SkipWinget
#>
[CmdletBinding()]
param(
    [switch]$WithCursorTrail,
    [switch]$SkipWinget,
    [switch]$SkipFonts,
    [switch]$BuildTrailFromSource,
    [string]$RepoRoot = $PSScriptRoot
)

# Do not stop the whole install on one failed external tool (winget on locked PCs).
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

function Write-Step([string]$Msg) { Write-Host "`n=== $Msg ===" -ForegroundColor Cyan }
function Write-Ok([string]$Msg) { Write-Host "  [ok] $Msg" -ForegroundColor Green }
function Write-Warn2([string]$Msg) { Write-Host "  [!] $Msg" -ForegroundColor Yellow }

function Test-WingetUsable {
    $cmd = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $cmd) { return $false }
    try {
        $p = Start-Process -FilePath $cmd.Source -ArgumentList '--version' -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\winget-ver.txt" -RedirectStandardError "$env:TEMP\winget-ver.err"
        return ($p.ExitCode -eq 0)
    } catch {
        return $false
    }
}

function Ensure-WingetPkg([string]$Id, [string]$Name) {
    try {
        $list = & winget list --id $Id -e 2>$null | Out-String
        if ($list -match [regex]::Escape($Id)) {
            Write-Ok "$Name already installed"
            return
        }
        Write-Host "  Installing $Name ($Id) ..."
        & winget install --id $Id -e --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Warn2 "winget install failed for $Name (exit $LASTEXITCODE). Install manually if needed."
        }
    } catch {
        Write-Warn2 "winget error for $Name : $($_.Exception.Message)"
    }
}

function Backup-IfExists([string]$Path) {
    if (Test-Path $Path) {
        $bak = "$Path.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -LiteralPath $Path -Destination $bak -Force
        Write-Host "  Backup: $bak"
    }
}

function Get-RepoViaZip([string]$Dest) {
    # No git required — works on cybercafe PCs after browser clone fails or for irm|iex
    $zipUrl = 'https://github.com/Kurak0oo/wezterm-env/archive/refs/heads/main.zip'
    $zip = Join-Path $env:TEMP 'wezterm-env-main.zip'
    $extract = Join-Path $env:TEMP 'wezterm-env-extract'
    Write-Host "  Downloading $zipUrl ..."
    Invoke-WebRequest -Uri $zipUrl -OutFile $zip -UseBasicParsing
    if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
    Expand-Archive -Path $zip -DestinationPath $extract -Force
    $inner = Get-ChildItem $extract -Directory | Select-Object -First 1
    if (-not $inner) { throw "Zip extract failed" }
    if (Test-Path $Dest) { Remove-Item $Dest -Recurse -Force }
    New-Item -ItemType Directory -Force -Path (Split-Path $Dest) | Out-Null
    Move-Item $inner.FullName $Dest
    Write-Ok "Repo ready at $Dest"
}

# ---------------------------------------------------------------------------
# Resolve repo root (local clone / zip / irm|iex)
# ---------------------------------------------------------------------------
if (-not $RepoRoot -or -not (Test-Path (Join-Path $RepoRoot 'config\wezterm.lua'))) {
    $clone = Join-Path $env:USERPROFILE 'src\wezterm-env'
    Write-Step "Repo files not next to this script — fetching to $clone"
    if (Test-Path (Join-Path $clone 'config\wezterm.lua')) {
        Write-Ok "Using existing $clone"
    } elseif (Get-Command git -ErrorAction SilentlyContinue) {
        try {
            if (-not (Test-Path $clone)) {
                git clone https://github.com/Kurak0oo/wezterm-env.git $clone
            } else {
                Push-Location $clone; git pull; Pop-Location
            }
        } catch {
            Write-Warn2 "git failed: $($_.Exception.Message) — falling back to zip"
            Get-RepoViaZip $clone
        }
    } else {
        Write-Warn2 "git not in PATH — downloading zip from GitHub"
        Get-RepoViaZip $clone
    }
    $argList = @()
    if ($WithCursorTrail) { $argList += '-WithCursorTrail' }
    if ($SkipWinget) { $argList += '-SkipWinget' }
    if ($SkipFonts) { $argList += '-SkipFonts' }
    if ($BuildTrailFromSource) { $argList += '-BuildTrailFromSource' }
    $installer = Join-Path $clone 'install.ps1'
    # Re-invoke with Bypass so nested call works under Restricted policy
    $p = Start-Process -FilePath 'powershell.exe' -ArgumentList (
        @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $installer) + $argList
    ) -Wait -PassThru -NoNewWindow
    exit $p.ExitCode
}

Write-Host @"

=== wezterm-env installer ===
Repo:  $RepoRoot
Trail: $WithCursorTrail
User:  $env:USERPROFILE

"@

# ---------------------------------------------------------------------------
# 1) Packages (optional)
# ---------------------------------------------------------------------------
if (-not $SkipWinget) {
    Write-Step "winget packages"
    if (-not (Test-WingetUsable)) {
        Write-Warn2 "winget missing or broken on this PC. Skipping package installs."
        Write-Warn2 "Install WezTerm / PowerShell 7 / Oh My Posh manually if needed."
        Write-Warn2 "Or re-run with: -SkipWinget"
    } else {
        Ensure-WingetPkg 'Microsoft.PowerShell' 'PowerShell 7'
        Ensure-WingetPkg 'wez.wezterm' 'WezTerm (stock)'
        Ensure-WingetPkg 'JanDeDobbeleer.OhMyPosh' 'Oh My Posh'
    }
} else {
    Write-Step "winget packages (skipped)"
}

# ---------------------------------------------------------------------------
# 2) Config
# ---------------------------------------------------------------------------
Write-Step "WezTerm config"
$cfgSrc = Join-Path $RepoRoot 'config\wezterm.lua'
$cfgDst = Join-Path $env:USERPROFILE '.wezterm.lua'
Backup-IfExists $cfgDst
Copy-Item $cfgSrc $cfgDst -Force
Write-Ok "Wrote $cfgDst"

$bgDir = Join-Path $env:USERPROFILE '.config\wezterm\backgrounds'
New-Item -ItemType Directory -Force -Path $bgDir | Out-Null
$bgReadme = Join-Path $bgDir 'README.txt'
@"
Place bg.jpg here for wallpaper:
  $bgDir\bg.jpg
Also accepted: %USERPROFILE%\Pictures\WezTermBackgrounds\bg.jpg
"@ | Set-Content $bgReadme -Encoding UTF8
New-Item -ItemType Directory -Force -Path (Join-Path $env:USERPROFILE 'Pictures\WezTermBackgrounds') | Out-Null

# ---------------------------------------------------------------------------
# 3) PowerShell profile
# ---------------------------------------------------------------------------
Write-Step "PowerShell profile"
$profSrc = Join-Path $RepoRoot 'profile\Microsoft.PowerShell_profile.ps1'
$profDir = Join-Path $env:USERPROFILE 'Documents\PowerShell'
New-Item -ItemType Directory -Force -Path $profDir | Out-Null
$profDst = Join-Path $profDir 'Microsoft.PowerShell_profile.ps1'
Backup-IfExists $profDst
Copy-Item $profSrc $profDst -Force
Write-Ok "Wrote $profDst"

# ---------------------------------------------------------------------------
# 4) Fonts (best-effort)
# ---------------------------------------------------------------------------
if (-not $SkipFonts) {
    Write-Step "Nerd Font (0xProto)"
    try {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\Install-NerdFont.ps1') -FontFamily '0xProto'
    } catch {
        Write-Warn2 "Font install failed: $($_.Exception.Message)"
        Write-Warn2 "Manual: https://www.nerdfonts.com/font-downloads → 0xProto"
    }
} else {
    Write-Step "Fonts (skipped)"
}

# ---------------------------------------------------------------------------
# 5) Cursor trail binary + launchers (always create .bat — no ExecutionPolicy)
# ---------------------------------------------------------------------------
$trailInstall = Join-Path $env:LOCALAPPDATA 'WezTerm-Trail'
$binDir = Join-Path $env:USERPROFILE 'bin'
New-Item -ItemType Directory -Force -Path $binDir | Out-Null

if ($WithCursorTrail) {
    Write-Step "Cursor trail WezTerm"
    $gui = Join-Path $trailInstall 'wezterm-gui.exe'
    $localCandidates = @(
        (Join-Path $env:USERPROFILE 'src\wezterm-cursor-trail\target\release\wezterm-gui.exe'),
        'C:\Users\Personal\Projects\wezterm-cursor-trail\target\release\wezterm-gui.exe'
    )
    $haveLocal = $localCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($BuildTrailFromSource) {
        try {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\Build-WezTerm-Trail.ps1') -InstallDir $trailInstall
        } catch {
            Write-Warn2 "Source build failed: $($_.Exception.Message)"
        }
    } elseif (-not (Test-Path $gui)) {
        $gotRelease = $false
        try {
            Write-Host "  Downloading GitHub Release ..."
            $api = 'https://api.github.com/repos/Kurak0oo/wezterm-env/releases/latest'
            $rel = Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent' = 'wezterm-env' }
            $asset = $rel.assets | Where-Object { $_.name -match 'wezterm-trail.*\.zip' } | Select-Object -First 1
            if ($asset) {
                $zip = Join-Path $env:TEMP 'wezterm-trail.zip'
                Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
                New-Item -ItemType Directory -Force -Path $trailInstall | Out-Null
                Expand-Archive -Path $zip -DestinationPath $trailInstall -Force
                # Zip may nest a folder
                if (-not (Test-Path $gui)) {
                    $nested = Get-ChildItem $trailInstall -Recurse -Filter 'wezterm-gui.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($nested) {
                        $nd = $nested.DirectoryName
                        Copy-Item (Join-Path $nd 'wezterm*.exe') $trailInstall -Force
                    }
                }
                $gotRelease = Test-Path $gui
                if ($gotRelease) { Write-Ok "Installed from release: $($asset.name)" }
            }
        } catch {
            Write-Warn2 "Release download failed: $($_.Exception.Message)"
        }

        if (-not $gotRelease -and $haveLocal) {
            $ld = Split-Path $haveLocal
            Write-Host "  Copying local build from $ld ..."
            New-Item -ItemType Directory -Force -Path $trailInstall | Out-Null
            Copy-Item (Join-Path $ld 'wezterm.exe') $trailInstall -Force -ErrorAction SilentlyContinue
            Copy-Item (Join-Path $ld 'wezterm-gui.exe') $trailInstall -Force
            Copy-Item (Join-Path $ld 'wezterm-mux-server.exe') $trailInstall -Force -ErrorAction SilentlyContinue
        } elseif (-not $gotRelease) {
            Write-Warn2 "Trail binary missing. Options:"
            Write-Warn2 "  - Check https://github.com/Kurak0oo/wezterm-env/releases"
            Write-Warn2 "  - Or: -BuildTrailFromSource (needs Rust/MSVC)"
        }
    } else {
        Write-Ok "Trail already at $trailInstall"
    }

    # .ps1 launcher (for Bypass / Desktop shortcut)
    $startPs1 = Join-Path $env:USERPROFILE 'Start-WezTerm-CursorTrail.ps1'
    Copy-Item (Join-Path $RepoRoot 'scripts\Start-WezTerm-Trail.ps1') $startPs1 -Force

    # .cmd / .bat — works under Restricted execution policy
    $startBat = Join-Path $env:USERPROFILE 'Start-WezTerm-CursorTrail.bat'
    @"
@echo off
REM Launches trail WezTerm without PowerShell execution-policy issues
set "WEZTERM_CURSOR_TRAIL=1"
set "TRAIL=%LOCALAPPDATA%\WezTerm-Trail"
if exist "%TRAIL%\wezterm-gui.exe" (
  start "" "%TRAIL%\wezterm-gui.exe"
  exit /b 0
)
if exist "%TRAIL%\wezterm.exe" (
  start "" "%TRAIL%\wezterm.exe"
  exit /b 0
)
echo Trail binary not found under %TRAIL%
echo Re-run: powershell -ExecutionPolicy Bypass -File "%~dp0..\workspace\wezterm-env\install.ps1" -WithCursorTrail
pause
exit /b 1
"@ | Set-Content $startBat -Encoding ASCII
    Write-Ok "Wrote $startBat  (double-click this — no Bypass needed)"

    @"
@echo off
set "WEZTERM_CURSOR_TRAIL=1"
set "PATH=%LOCALAPPDATA%\WezTerm-Trail;%PATH%"
"%LOCALAPPDATA%\WezTerm-Trail\wezterm.exe" %*
"@ | Set-Content (Join-Path $binDir 'wezterm-trail.cmd') -Encoding ASCII

    try {
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($userPath -and $userPath -notlike '*WezTerm-Trail*') {
            [Environment]::SetEnvironmentVariable('Path', "$trailInstall;$binDir;$userPath", 'User')
            Write-Ok "Prepended trail dir to user PATH (new shells)"
        }
    } catch {
        Write-Warn2 "Could not edit user PATH: $($_.Exception.Message)"
    }

    # Desktop shortcut → .bat (no ExecutionPolicy)
    try {
        $desk = [Environment]::GetFolderPath('Desktop')
        if (-not $desk) { $desk = $env:USERPROFILE }
        $wsh = New-Object -ComObject WScript.Shell
        $sc = $wsh.CreateShortcut((Join-Path $desk 'WezTerm Cursor Trail.lnk'))
        $sc.TargetPath = $startBat
        $sc.WorkingDirectory = $env:USERPROFILE
        $sc.Description = 'WezTerm with cursor trail (no ExecutionPolicy needed)'
        $sc.Save()
        Write-Ok "Desktop shortcut → $startBat"
    } catch {
        Write-Warn2 "Desktop shortcut failed: $($_.Exception.Message)"
    }
}

# Repo-local install.cmd helper for next time
$installCmd = Join-Path $RepoRoot 'install.cmd'
@"
@echo off
REM Always Bypass so Restricted PCs can install
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
"@ | Set-Content $installCmd -Encoding ASCII

Write-Host @"

=== Done ===
Config:  $cfgDst
Profile: $profDst
Wallpaper: $bgDir\bg.jpg  (optional)

Launch (stock WezTerm):
  wezterm

Launch (cursor trail) — pick one:
  1) Double-click:  $env:USERPROFILE\Start-WezTerm-CursorTrail.bat
  2) Desktop:       WezTerm Cursor Trail
  3) powershell -ExecutionPolicy Bypass -File `$env:USERPROFILE\Start-WezTerm-CursorTrail.ps1

Restricted PC tips:
  - Always: powershell -ExecutionPolicy Bypass -File .\install.ps1 ...
  - Or:     .\install.cmd -WithCursorTrail
  - If winget breaks: .\install.cmd -WithCursorTrail -SkipWinget
  - Fully quit WezTerm after font install

"@
