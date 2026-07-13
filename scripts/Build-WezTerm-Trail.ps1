# Build WezTerm from MathurinV feature/cursor-trail + apply single-cell smear patch
# Requires: git, rustup (MSVC), VS Build Tools C++, Strawberry Perl
param(
    [string]$SourceDir = (Join-Path $env:USERPROFILE 'src\wezterm-cursor-trail'),
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'WezTerm-Trail'),
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$patch = Join-Path $RepoRoot 'patches\0001-single-cell-smear.patch'

function Test-Cmd($name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }

Write-Host "=== Checking build prerequisites ==="
if (-not (Test-Cmd cargo)) {
    throw "Rust/cargo not found. Install: winget install Rustlang.Rustup  then open a new shell."
}
if (-not (Test-Cmd git)) { throw "git not found." }
if (-not (Test-Path 'C:\Strawberry\perl\bin\perl.exe')) {
    Write-Warning "Strawberry Perl not found at C:\Strawberry. Install: winget install StrawberryPerl.StrawberryPerl"
}
$vcvars = @(
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $vcvars) {
    throw "MSVC vcvars64.bat not found. Install VS 2022 Build Tools with C++ workload."
}

if (-not (Test-Path $SourceDir)) {
    Write-Host "Cloning MathurinV/wezterm (feature/cursor-trail) ..."
    git clone --recursive https://github.com/MathurinV/wezterm.git $SourceDir
}
Set-Location $SourceDir
git fetch origin feature/cursor-trail 2>$null
git checkout feature/cursor-trail
git submodule update --init --recursive

# Apply patch if not already applied
$already = Select-String -Path 'wezterm-gui\src\termwindow\cursortrail.rs' -Pattern 'Single-cell moves' -Quiet
if (-not $already) {
    Write-Host "Applying single-cell smear patch ..."
    git apply --whitespace=nowarn $patch
    if ($LASTEXITCODE -ne 0) {
        # Fallback: manual replace if apply fails on drift
        Write-Warning "git apply failed; trying simple replace"
        $p = 'wezterm-gui\src\termwindow\cursortrail.rs'
        $c = Get-Content $p -Raw
        $old = '            } else if dx + dy > 0 {
                Phase::Snap
            } else {
                Phase::Tick
            };'
        $new = @'
            } else if dx + dy > 0 {
                // Single-cell moves (typing, left/right arrows, hjkl): arm a
                // short smear from the previous cell instead of snapping.
                Phase::Arm(self.prev_pos)
            } else {
                Phase::Tick
            };
'@
        if ($c -notlike '*Phase::Snap*') { throw "Could not locate Phase::Snap for patch." }
        $c2 = $c.Replace($old, $new)
        if ($c2 -eq $c) { throw "Patch replace failed (upstream source may have changed)." }
        Set-Content -Path $p -Value $c2 -NoNewline
    }
} else {
    Write-Host "Patch already present."
}

# Import MSVC env
$env:Path = "C:\Strawberry\perl\bin;" + $env:Path
$temp = [System.IO.Path]::GetTempFileName()
cmd /c "`"$vcvars`" && set" > $temp
Get-Content $temp | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}
Remove-Item $temp -Force
$env:Path = "C:\Strawberry\perl\bin;" + $env:Path

Write-Host "=== cargo build --release (long first time) ==="
cargo build --release
if ($LASTEXITCODE -ne 0) { throw "cargo build failed" }

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$rel = Join-Path $SourceDir 'target\release'
Copy-Item (Join-Path $rel 'wezterm.exe') $InstallDir -Force
Copy-Item (Join-Path $rel 'wezterm-gui.exe') $InstallDir -Force
if (Test-Path (Join-Path $rel 'wezterm-mux-server.exe')) {
    Copy-Item (Join-Path $rel 'wezterm-mux-server.exe') $InstallDir -Force
}

Write-Host "Installed trail binaries to $InstallDir"
& (Join-Path $InstallDir 'wezterm.exe') --version
