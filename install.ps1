#Requires -Version 5.1
<#
.SYNOPSIS
  Deploy Kurak0oo/wezterm-env on Windows (WezTerm config + PowerShell profile, optional font and cursor trail).

.NOTES
  Restricted / cybercafe machines block scripts and often break winget. Run through
  install.cmd (always -ExecutionPolicy Bypass) or call powershell with Bypass yourself.

.EXAMPLE
  .\install.cmd -WithCursorTrail
  .\install.cmd -WithCursorTrail -SkipWinget
  & ([scriptblock]::Create((irm https://raw.githubusercontent.com/Kurak0oo/wezterm-env/main/install.ps1))) -WithCursorTrail
#>
[CmdletBinding()]
param(
    [switch]$WithCursorTrail,
    [switch]$WithFont,
    [switch]$SkipWinget,
    # Re-download the pinned trail release even if a trail build is already installed.
    [switch]$UpdateTrail,
    [switch]$BuildTrailFromSource,
    # Kept so old command lines keep working; fonts are opt-in now (-WithFont).
    [switch]$SkipFonts,
    # Do not default to $PSScriptRoot here: with [CmdletBinding()] it is empty during
    # parameter binding, which caused an infinite bootstrap re-invoke loop.
    [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
# Older Windows PowerShell 5.1 installs default to TLS 1.0, which GitHub rejects.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Pinned trail release. Bump both lines together when publishing a new build.
$TrailTag = 'v1.0.0'
$TrailSha256 = '76ad8114a82d661a914d097750e1abffca63bb7bca82be69e2504b155db73b31'
$TrailAsset = 'wezterm-trail-windows-x64.zip'
$RepoUrl = 'https://github.com/Kurak0oo/wezterm-env'

$script:Problems = [System.Collections.Generic.List[string]]::new()

function Write-Step([string]$Msg) { Write-Host "`n=== $Msg ===" -ForegroundColor Cyan }
function Write-Ok([string]$Msg) { Write-Host "  [ok] $Msg" -ForegroundColor Green }
function Write-Problem([string]$Msg) {
    Write-Host "  [!] $Msg" -ForegroundColor Yellow
    $script:Problems.Add($Msg)
}

function Test-WingetUsable {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { return $false }
    try {
        & winget --version | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Install-WingetPackage([string]$Id, [string]$Name) {
    # Native stderr is never redirected: under Windows PowerShell 5.1 with
    # ErrorActionPreference=Stop, redirected stderr lines become terminating errors.
    $list = & winget list --id $Id -e --accept-source-agreements | Out-String
    if ($LASTEXITCODE -eq 0 -and $list -match [regex]::Escape($Id)) {
        Write-Ok "$Name already installed"
        return
    }
    Write-Host "  Installing $Name ($Id) ..."
    & winget install --id $Id -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Problem "winget install failed for $Name (exit $LASTEXITCODE). Install it manually if needed."
    }
}

# Copy a managed file, keeping a timestamped backup only when the content actually changes.
function Install-ManagedFile([string]$Source, [string]$Destination) {
    New-Item -ItemType Directory -Force -Path (Split-Path $Destination) | Out-Null
    if (Test-Path -LiteralPath $Destination) {
        if ((Get-FileHash -LiteralPath $Source).Hash -eq (Get-FileHash -LiteralPath $Destination).Hash) {
            Write-Ok "Up to date: $Destination"
            return
        }
        $bak = "$Destination.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -LiteralPath $Destination -Destination $bak -Force
        Write-Host "  Backup: $bak"
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Ok "Wrote $Destination"
}

function Get-RepoViaZip([string]$Dest) {
    $zipUrl = "$RepoUrl/archive/refs/heads/main.zip"
    $zip = Join-Path $env:TEMP 'wezterm-env-main.zip'
    $extract = Join-Path $env:TEMP "wezterm-env-extract-$([guid]::NewGuid().ToString('N'))"
    Write-Host "  Downloading $zipUrl ..."
    Invoke-WebRequest -Uri $zipUrl -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $extract -Force
    $inner = Get-ChildItem $extract -Directory | Select-Object -First 1
    if (-not $inner) { throw "Zip extract failed" }
    New-Item -ItemType Directory -Force -Path (Split-Path $Dest) | Out-Null
    Move-Item $inner.FullName $Dest
    Remove-Item $zip, $extract -Recurse -Force -ErrorAction SilentlyContinue
}

if (-not $RepoRoot) { $RepoRoot = $PSScriptRoot }

# ---------------------------------------------------------------------------
# Bootstrap: running from irm (no repo next to the script) -> fetch repo, re-run from it
# ---------------------------------------------------------------------------
if (-not $RepoRoot -or -not (Test-Path (Join-Path $RepoRoot 'config\wezterm.lua'))) {
    $clone = Join-Path $env:USERPROFILE 'src\wezterm-env'
    Write-Step "Fetching repo to $clone"
    if (Test-Path (Join-Path $clone 'config\wezterm.lua')) {
        if ((Test-Path (Join-Path $clone '.git')) -and (Get-Command git -ErrorAction SilentlyContinue)) {
            & git -C $clone pull --ff-only
            if ($LASTEXITCODE -ne 0) { Write-Host "  git pull failed; using the existing copy" -ForegroundColor Yellow }
        }
    } else {
        if (Test-Path $clone) {
            # Never delete a folder we did not create; fetch next to it instead.
            $clone = Join-Path $env:TEMP "wezterm-env-$([guid]::NewGuid().ToString('N'))"
            Write-Host "  $env:USERPROFILE\src\wezterm-env exists but is not this repo; using $clone" -ForegroundColor Yellow
        }
        $cloned = $false
        if (Get-Command git -ErrorAction SilentlyContinue) {
            & git clone "$RepoUrl.git" $clone
            $cloned = ($LASTEXITCODE -eq 0)
            if (-not $cloned) {
                Write-Host "  git clone failed; falling back to zip" -ForegroundColor Yellow
                Remove-Item $clone -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        if (-not $cloned) { Get-RepoViaZip $clone }
    }
    Write-Ok "Repo ready at $clone"

    $forward = @('-RepoRoot', $clone)
    foreach ($name in 'WithCursorTrail', 'WithFont', 'SkipWinget', 'UpdateTrail', 'BuildTrailFromSource') {
        if ($PSBoundParameters[$name]) { $forward += "-$name" }
    }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $clone 'install.ps1') @forward
    # `exit` would close the user's window when this runs from irm; only exit from a script file.
    if ($PSCommandPath) { exit $LASTEXITCODE }
    return
}

$RepoRoot = (Resolve-Path $RepoRoot).Path
if ($SkipFonts) { $WithFont = $false }

Write-Host @"

=== wezterm-env installer ===
Repo:  $RepoRoot
Trail: $WithCursorTrail   Font: $WithFont
"@

try {
    & (Join-Path $RepoRoot 'scripts\Remove-LegacyInstall.ps1')
} catch {
    Write-Problem "Cleanup of old install failed: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 1) Packages (optional)
# ---------------------------------------------------------------------------
if ($SkipWinget) {
    Write-Step "winget packages (skipped)"
} else {
    Write-Step "winget packages"
    if (Test-WingetUsable) {
        Install-WingetPackage 'Microsoft.PowerShell' 'PowerShell 7'
        Install-WingetPackage 'wez.wezterm' 'WezTerm'
        Install-WingetPackage 'JanDeDobbeleer.OhMyPosh' 'Oh My Posh'
    } else {
        Write-Problem "winget missing or broken. Install WezTerm / PowerShell 7 / Oh My Posh manually, or re-run with -SkipWinget."
    }
}

# ---------------------------------------------------------------------------
# 2) WezTerm config + wallpaper folder
# ---------------------------------------------------------------------------
Write-Step "WezTerm config"
$cfgDst = Join-Path $env:USERPROFILE '.wezterm.lua'
try {
    Install-ManagedFile (Join-Path $RepoRoot 'config\wezterm.lua') $cfgDst
} catch {
    Write-Problem "Could not write ${cfgDst}: $($_.Exception.Message)"
}

$bgDir = Join-Path $env:USERPROFILE '.config\wezterm\backgrounds'
New-Item -ItemType Directory -Force -Path $bgDir | Out-Null
$localBg = Get-ChildItem (Join-Path $RepoRoot 'assets\backgrounds') -Filter 'bg.*' -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in '.jpg', '.png' } | Select-Object -First 1
if ($localBg -and -not (Test-Path (Join-Path $bgDir $localBg.Name))) {
    Copy-Item $localBg.FullName $bgDir
    Write-Ok "Copied wallpaper $($localBg.Name) to $bgDir"
}

# ---------------------------------------------------------------------------
# 3) PowerShell profile: managed file + one dot-source line in each $PROFILE
# ---------------------------------------------------------------------------
Write-Step "PowerShell profile"
$envDir = Join-Path $env:USERPROFILE '.config\wezterm-env'
$managedProfile = Join-Path $envDir 'profile.ps1'
$profileMarker = '# wezterm-env (managed line, removed by uninstall.ps1)'
$profileLine = "if (Test-Path `"`$HOME\.config\wezterm-env\profile.ps1`") { . `"`$HOME\.config\wezterm-env\profile.ps1`" } $profileMarker"
try {
    Install-ManagedFile (Join-Path $RepoRoot 'profile\Microsoft.PowerShell_profile.ps1') $managedProfile

    # Cache the prompt theme locally so new shells never hit the network.
    $theme = Join-Path $envDir 'catppuccin_mocha.omp.json'
    if (-not (Test-Path $theme)) {
        try {
            Invoke-WebRequest -UseBasicParsing -OutFile $theme `
                -Uri 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin_mocha.omp.json'
            Write-Ok "Cached Oh My Posh theme at $theme"
        } catch {
            Write-Problem "Could not download the Oh My Posh theme; the prompt falls back to the default theme."
        }
    }

    # PS7 uses Documents\PowerShell, Windows PowerShell 5.1 uses Documents\WindowsPowerShell.
    # MyDocuments follows OneDrive folder redirection; $USERPROFILE\Documents does not.
    $docs = [Environment]::GetFolderPath('MyDocuments')
    foreach ($sub in 'PowerShell', 'WindowsPowerShell') {
        $profPath = Join-Path $docs "$sub\Microsoft.PowerShell_profile.ps1"
        New-Item -ItemType Directory -Force -Path (Split-Path $profPath) | Out-Null
        $current = if (Test-Path $profPath) { Get-Content $profPath -Raw } else { '' }
        if ($current -like "*$profileMarker*") {
            Write-Ok "Already linked: $profPath"
            continue
        }
        if ($current -like '*Installed by Kurak0oo/wezterm-env install.ps1*') {
            # Older versions of this installer overwrote the whole profile; swap it for the link.
            Copy-Item $profPath "$profPath.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Set-Content $profPath $profileLine -Encoding UTF8
        } else {
            Add-Content $profPath "`r`n$profileLine" -Encoding UTF8
        }
        Write-Ok "Linked $profPath"
    }
} catch {
    Write-Problem "Profile setup failed: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# 4) Font (opt-in: WezTerm already bundles JetBrains Mono + Nerd Font symbols)
# ---------------------------------------------------------------------------
if ($WithFont) {
    Write-Step "Nerd Font (0xProto)"
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\Install-NerdFont.ps1') -FontFamily '0xProto'
    if ($LASTEXITCODE -ne 0) {
        Write-Problem "Font install failed. Manual: https://www.nerdfonts.com/font-downloads -> 0xProto"
    }
}

# ---------------------------------------------------------------------------
# 5) Cursor trail build + launcher
# ---------------------------------------------------------------------------
if ($WithCursorTrail) {
    Write-Step "Cursor trail WezTerm"
    $trailDir = Join-Path $env:LOCALAPPDATA 'WezTerm-Trail'
    $gui = Join-Path $trailDir 'wezterm-gui.exe'
    $stamp = Join-Path $trailDir 'release.txt'
    $installedTag = if (Test-Path $stamp) { (Get-Content $stamp -Raw).Trim() } else { $null }

    if ($BuildTrailFromSource) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\Build-WezTerm-Trail.ps1') -InstallDir $trailDir
        if ($LASTEXITCODE -ne 0) { Write-Problem "Source build failed (exit $LASTEXITCODE)." }
    } elseif ((Test-Path $gui) -and -not ($UpdateTrail -and $installedTag -ne $TrailTag)) {
        Write-Ok "Trail already at $trailDir ($(if ($installedTag) { $installedTag } else { 'unknown version' }); -UpdateTrail to replace)"
    } else {
        $zip = Join-Path $env:TEMP $TrailAsset
        try {
            $url = "$RepoUrl/releases/download/$TrailTag/$TrailAsset"
            Write-Host "  Downloading $url ..."
            Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
            $hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($hash -ne $TrailSha256) { throw "SHA256 mismatch (got $hash). Refusing to install." }

            $unpack = Join-Path $env:TEMP "wezterm-trail-$([guid]::NewGuid().ToString('N'))"
            Expand-Archive -Path $zip -DestinationPath $unpack -Force
            $found = Get-ChildItem $unpack -Recurse -Filter 'wezterm-gui.exe' | Select-Object -First 1
            if (-not $found) { throw "wezterm-gui.exe not found in $TrailAsset" }
            New-Item -ItemType Directory -Force -Path $trailDir | Out-Null
            Copy-Item (Join-Path $found.DirectoryName '*') $trailDir -Recurse -Force
            Set-Content $stamp $TrailTag
            Remove-Item $unpack -Recurse -Force -ErrorAction SilentlyContinue
            Write-Ok "Installed $TrailAsset ($TrailTag)"
        } catch {
            Write-Problem "Trail download failed: $($_.Exception.Message). See $RepoUrl/releases or use -BuildTrailFromSource."
        } finally {
            Remove-Item $zip -Force -ErrorAction SilentlyContinue
        }
    }

    # .bat launcher works under Restricted execution policy; config detects the trail build
    # from its install folder, the env var is a second signal.
    $startBat = Join-Path $trailDir 'Start-WezTerm-CursorTrail.bat'
    New-Item -ItemType Directory -Force -Path $trailDir | Out-Null
    @"
@echo off
set "WEZTERM_CURSOR_TRAIL=1"
if exist "%~dp0wezterm-gui.exe" (
  start "" "%~dp0wezterm-gui.exe"
  exit /b 0
)
echo Trail binary not found in %~dp0
echo Re-run: "$RepoRoot\install.cmd" -WithCursorTrail
pause
exit /b 1
"@ | Set-Content $startBat -Encoding ASCII
    Write-Ok "Wrote $startBat"

    try {
        $wsh = New-Object -ComObject WScript.Shell
        $desk = [Environment]::GetFolderPath('Desktop')
        if (-not $desk) { $desk = $env:USERPROFILE }
        $sc = $wsh.CreateShortcut((Join-Path $desk 'WezTerm Cursor Trail.lnk'))
        $sc.TargetPath = $startBat
        $sc.WorkingDirectory = $env:USERPROFILE
        if (Test-Path $gui) { $sc.IconLocation = "$gui,0" }
        $sc.Description = 'WezTerm with cursor trail'
        $sc.Save()
        Write-Ok "Desktop shortcut: WezTerm Cursor Trail"
    } catch {
        Write-Problem "Desktop shortcut failed: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Config:  $cfgDst"
Write-Host "Profile: $managedProfile (linked from `$PROFILE)"
Write-Host "Wallpaper (optional): $bgDir\bg.jpg"
if ($WithCursorTrail) { Write-Host "Trail:   double-click 'WezTerm Cursor Trail' on the desktop" }
if ($WithFont) { Write-Host "Fully quit WezTerm so it picks up the new font." }

if ($script:Problems.Count -gt 0) {
    Write-Host "`nFinished with $($script:Problems.Count) problem(s):" -ForegroundColor Yellow
    $script:Problems | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    if ($PSCommandPath) { exit 1 }
} else {
    Write-Host "`nDone." -ForegroundColor Green
}
