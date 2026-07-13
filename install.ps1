#Requires -Version 5.1
<#
.SYNOPSIS
  Deploy Kurak0oo/wezterm-env on Windows (WezTerm config + PowerShell + Oh My Posh + fonts).

.EXAMPLE
  .\install.ps1
  .\install.ps1 -WithCursorTrail
  irm https://raw.githubusercontent.com/Kurak0oo/wezterm-env/main/install.ps1 | iex
#>
param(
    [switch]$WithCursorTrail,
    [switch]$SkipWinget,
    [switch]$SkipFonts,
    [switch]$BuildTrailFromSource,
    [string]$RepoRoot = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'

# When piped from irm | iex, $PSScriptRoot may be empty — clone then re-run
if (-not $RepoRoot -or -not (Test-Path (Join-Path $RepoRoot 'config\wezterm.lua'))) {
    $clone = Join-Path $env:USERPROFILE 'src\wezterm-env'
    Write-Host "Repo files not found next to install.ps1; cloning to $clone ..."
    if (-not (Test-Path $clone)) {
        git clone https://github.com/Kurak0oo/wezterm-env.git $clone
    } else {
        Push-Location $clone; git pull; Pop-Location
    }
    $args = @()
    if ($WithCursorTrail) { $args += '-WithCursorTrail' }
    if ($SkipWinget) { $args += '-SkipWinget' }
    if ($SkipFonts) { $args += '-SkipFonts' }
    if ($BuildTrailFromSource) { $args += '-BuildTrailFromSource' }
    & (Join-Path $clone 'install.ps1') @args
    exit $LASTEXITCODE
}

function Backup-IfExists([string]$Path) {
    if (Test-Path $Path) {
        $bak = "$Path.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -LiteralPath $Path -Destination $bak -Force
        Write-Host "  Backup: $bak"
    }
}

function Ensure-WingetPkg([string]$Id, [string]$Name) {
    $found = winget list --id $Id -e 2>$null | Select-String -Pattern $Id -Quiet
    if ($found) {
        Write-Host "  [ok] $Name already installed"
        return
    }
    Write-Host "  Installing $Name ($Id) ..."
    winget install --id $Id -e --accept-package-agreements --accept-source-agreements
}

Write-Host @"

=== wezterm-env installer ===
Repo: $RepoRoot
Trail: $WithCursorTrail

"@

# 1) Packages
if (-not $SkipWinget) {
    Write-Host "=== winget packages ==="
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning "winget not found; skip package install (-SkipWinget)."
    } else {
        Ensure-WingetPkg 'Microsoft.PowerShell' 'PowerShell 7'
        Ensure-WingetPkg 'wez.wezterm' 'WezTerm'
        Ensure-WingetPkg 'JanDeDobbeleer.OhMyPosh' 'Oh My Posh'
    }
}

# 2) Config
Write-Host "=== WezTerm config ==="
$cfgSrc = Join-Path $RepoRoot 'config\wezterm.lua'
$cfgDst = Join-Path $env:USERPROFILE '.wezterm.lua'
Backup-IfExists $cfgDst
Copy-Item $cfgSrc $cfgDst -Force
Write-Host "  Wrote $cfgDst"

# Backgrounds dir
$bgDir = Join-Path $env:USERPROFILE '.config\wezterm\backgrounds'
New-Item -ItemType Directory -Force -Path $bgDir | Out-Null
$bgReadme = Join-Path $bgDir 'README.txt'
if (-not (Test-Path $bgReadme)) {
    Copy-Item (Join-Path $RepoRoot 'assets\backgrounds\README.md') $bgReadme -ErrorAction SilentlyContinue
    @"
Place bg.jpg here for WezTerm wallpaper:
  $bgDir\bg.jpg

Also accepted: %USERPROFILE%\Pictures\WezTermBackgrounds\bg.jpg
"@ | Set-Content $bgReadme -Encoding UTF8
}
# Also keep Pictures path for users who already use it
$picBg = Join-Path $env:USERPROFILE 'Pictures\WezTermBackgrounds'
New-Item -ItemType Directory -Force -Path $picBg | Out-Null

# 3) PowerShell profile
Write-Host "=== PowerShell profile ==="
$profSrc = Join-Path $RepoRoot 'profile\Microsoft.PowerShell_profile.ps1'
# Prefer PowerShell 7 profile path
$profDir = Join-Path $env:USERPROFILE 'Documents\PowerShell'
New-Item -ItemType Directory -Force -Path $profDir | Out-Null
$profDst = Join-Path $profDir 'Microsoft.PowerShell_profile.ps1'
Backup-IfExists $profDst
Copy-Item $profSrc $profDst -Force
Write-Host "  Wrote $profDst"

# 4) Fonts
if (-not $SkipFonts) {
    Write-Host "=== Nerd Font (0xProto) ==="
    try {
        & (Join-Path $RepoRoot 'scripts\Install-NerdFont.ps1') -FontFamily '0xProto'
    } catch {
        Write-Warning "Font install failed: $_  (You can install manually from https://www.nerdfonts.com/font-downloads)"
    }
}

# 5) Trail binary
$trailInstall = Join-Path $env:LOCALAPPDATA 'WezTerm-Trail'
if ($WithCursorTrail) {
    Write-Host "=== Cursor trail WezTerm ==="
    $gui = Join-Path $trailInstall 'wezterm-gui.exe'
    $haveLocal = Test-Path 'C:\Users\Personal\Projects\wezterm-cursor-trail\target\release\wezterm-gui.exe'

    if ($BuildTrailFromSource) {
        & (Join-Path $RepoRoot 'scripts\Build-WezTerm-Trail.ps1') -InstallDir $trailInstall
    } elseif (-not (Test-Path $gui)) {
        # Try GitHub Release first
        $gotRelease = $false
        try {
            Write-Host "  Trying GitHub Release download ..."
            $api = 'https://api.github.com/repos/Kurak0oo/wezterm-env/releases/latest'
            $rel = Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent' = 'wezterm-env' } -ErrorAction Stop
            $asset = $rel.assets | Where-Object { $_.name -match 'wezterm-trail.*\.zip' } | Select-Object -First 1
            if ($asset) {
                $zip = Join-Path $env:TEMP 'wezterm-trail.zip'
                Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
                New-Item -ItemType Directory -Force -Path $trailInstall | Out-Null
                Expand-Archive -Path $zip -DestinationPath $trailInstall -Force
                $gotRelease = Test-Path $gui
                Write-Host "  Installed from release: $($asset.name)"
            }
        } catch {
            Write-Host "  No release asset yet: $($_.Exception.Message)"
        }

        if (-not $gotRelease -and $haveLocal) {
            Write-Host "  Copying local build from C:\Users\Personal\Projects\wezterm-cursor-trail ..."
            New-Item -ItemType Directory -Force -Path $trailInstall | Out-Null
            Copy-Item 'C:\Users\Personal\Projects\wezterm-cursor-trail\target\release\wezterm.exe' $trailInstall -Force
            Copy-Item 'C:\Users\Personal\Projects\wezterm-cursor-trail\target\release\wezterm-gui.exe' $trailInstall -Force
            if (Test-Path 'C:\Users\Personal\Projects\wezterm-cursor-trail\target\release\wezterm-mux-server.exe') {
                Copy-Item 'C:\Users\Personal\Projects\wezterm-cursor-trail\target\release\wezterm-mux-server.exe' $trailInstall -Force
            }
        } elseif (-not $gotRelease) {
            Write-Warning @"
  Trail binary not available (no release + no local build).
  Options:
    .\install.ps1 -WithCursorTrail -BuildTrailFromSource
    .\scripts\Build-WezTerm-Trail.ps1
"@
        }
    } else {
        Write-Host "  Trail already at $trailInstall"
    }

    # Launchers
    $startScript = Join-Path $env:USERPROFILE 'Start-WezTerm-CursorTrail.ps1'
    Copy-Item (Join-Path $RepoRoot 'scripts\Start-WezTerm-Trail.ps1') $startScript -Force
    $binDir = Join-Path $env:USERPROFILE 'bin'
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    @"
@echo off
set "WEZTERM_CURSOR_TRAIL=1"
set "PATH=$trailInstall;%PATH%"
"$trailInstall\wezterm.exe" %*
"@ | Set-Content (Join-Path $binDir 'wezterm-trail.cmd') -Encoding ASCII

    # Prepend trail dir to User PATH if missing
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*WezTerm-Trail*") {
        [Environment]::SetEnvironmentVariable('Path', "$trailInstall;$binDir;$userPath", 'User')
        Write-Host "  Prepended $trailInstall to user PATH (new shells)"
    }

    # Desktop shortcut
    try {
        $wsh = New-Object -ComObject WScript.Shell
        $sc = $wsh.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'WezTerm Cursor Trail.lnk'))
        $sc.TargetPath = 'powershell.exe'
        $sc.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$startScript`""
        $sc.WorkingDirectory = $env:USERPROFILE
        $sc.Description = 'WezTerm with cursor smear/trail (PR #7737 build)'
        $sc.Save()
        Write-Host "  Desktop shortcut: WezTerm Cursor Trail.lnk"
    } catch {
        Write-Warning "Could not create desktop shortcut: $_"
    }
}

Write-Host @"

=== Done ===
Config:  $cfgDst
Profile: $profDst
Wallpaper folder: $bgDir  (drop bg.jpg there)

Launch stock WezTerm:  wezterm
Launch trail build:    powershell -File `$env:USERPROFILE\Start-WezTerm-CursorTrail.ps1
                       (or Desktop: WezTerm Cursor Trail)

Fully quit and reopen WezTerm after font install.
"@
