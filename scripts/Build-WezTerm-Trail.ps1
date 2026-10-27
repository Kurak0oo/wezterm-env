# Build WezTerm from MathurinV feature/cursor-trail (PR #7737) + single-cell smear patch.
# Requires: git, rustup (MSVC toolchain), VS 2022 Build Tools (C++), Perl (Strawberry).
param(
    [string]$SourceDir = (Join-Path $env:USERPROFILE 'src\wezterm-cursor-trail'),
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'WezTerm-Trail'),
    # Pinned so the patch always applies and builds are reproducible. Bump deliberately.
    [string]$Commit = '114a305d'
)

$ErrorActionPreference = 'Stop'
$patch = Join-Path (Split-Path -Parent $PSScriptRoot) 'patches\0001-single-cell-smear.patch'

# Native commands never throw; check their exit code instead. stderr is not redirected
# because Windows PowerShell 5.1 turns redirected stderr into terminating errors.
function Invoke-Native([string]$Exe, [string[]]$Arguments) {
    & $Exe @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Exe $($Arguments -join ' ') failed (exit $LASTEXITCODE)" }
}

Write-Host "=== Checking build prerequisites ==="
foreach ($tool in 'git', 'cargo') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "$tool not found. Install: winget install Git.Git Rustlang.Rustup, then open a new shell."
    }
}
$perl = Get-Command perl -ErrorAction SilentlyContinue
$perlDir = if ($perl) { Split-Path $perl.Source } elseif (Test-Path 'C:\Strawberry\perl\bin\perl.exe') { 'C:\Strawberry\perl\bin' }
if (-not $perlDir) { throw "Perl not found. Install: winget install StrawberryPerl.StrawberryPerl" }
$vcvars = @(
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $vcvars) { throw "MSVC vcvars64.bat not found. Install VS 2022 Build Tools with the C++ workload." }

if (-not (Test-Path $SourceDir)) {
    Write-Host "Cloning MathurinV/wezterm ..."
    Invoke-Native git @('clone', 'https://github.com/MathurinV/wezterm.git', $SourceDir)
}
Invoke-Native git @('-C', $SourceDir, 'fetch', 'origin', 'feature/cursor-trail')
Invoke-Native git @('-C', $SourceDir, 'checkout', '--force', $Commit)
Invoke-Native git @('-C', $SourceDir, 'submodule', 'update', '--init', '--recursive')

# Reverse-check succeeds only if the patch is already applied. Its stderr is expected
# noise, so relax ErrorActionPreference for this one redirected call.
$ErrorActionPreference = 'Continue'
& git -C $SourceDir apply --check --reverse $patch 2>$null
$alreadyApplied = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = 'Stop'
if ($alreadyApplied) {
    Write-Host "Patch already applied."
} else {
    Write-Host "Applying single-cell smear patch ..."
    Invoke-Native git @('-C', $SourceDir, 'apply', '--whitespace=nowarn', $patch)
}

# Import the MSVC environment into this process.
cmd /c "`"$vcvars`" >nul && set" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') { Set-Item "env:$($matches[1])" $matches[2] }
}
$env:Path = "$perlDir;$env:Path"

Write-Host "=== cargo build --release (slow the first time) ==="
Push-Location $SourceDir
try { Invoke-Native cargo @('build', '--release') } finally { Pop-Location }

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$rel = Join-Path $SourceDir 'target\release'
foreach ($exe in 'wezterm.exe', 'wezterm-gui.exe', 'wezterm-mux-server.exe') {
    $src = Join-Path $rel $exe
    if (Test-Path $src) { Copy-Item $src $InstallDir -Force }
}
Set-Content (Join-Path $InstallDir 'release.txt') "source-$Commit"

Write-Host "Installed trail binaries to $InstallDir"
& (Join-Path $InstallDir 'wezterm.exe') --version
