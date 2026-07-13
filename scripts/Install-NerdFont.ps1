# Install 0xProto Nerd Font for the current user (Windows)
param(
    [string]$FontFamily = '0xProto'
)

$ErrorActionPreference = 'Stop'
$tmp = Join-Path $env:TEMP "nerdfont-$FontFamily"
$zip = Join-Path $env:TEMP "$FontFamily.zip"
$fontsUser = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
New-Item -ItemType Directory -Force -Path $fontsUser | Out-Null

# Official Nerd Fonts release asset naming
$asset = switch ($FontFamily) {
    '0xProto' { '0xProto.zip' }
    'JetBrainsMono' { 'JetBrainsMono.zip' }
    default { "$FontFamily.zip" }
}

$releaseApi = 'https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest'
Write-Host "Resolving latest Nerd Fonts release for $asset ..."
$rel = Invoke-RestMethod -Uri $releaseApi -Headers @{ 'User-Agent' = 'wezterm-env' }
$url = ($rel.assets | Where-Object { $_.name -eq $asset } | Select-Object -First 1).browser_download_url
if (-not $url) {
    throw "Could not find asset $asset in latest nerd-fonts release."
}

Write-Host "Downloading $url"
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
Expand-Archive -Path $zip -DestinationPath $tmp -Force

$shell = New-Object -ComObject Shell.Application
$fontsNs = $shell.Namespace(0x14) # Fonts special folder (per-user when available)
$ttfs = Get-ChildItem -Path $tmp -Recurse -Include *.ttf, *.otf -ErrorAction SilentlyContinue
if (-not $ttfs) { throw "No font files found in archive." }

$count = 0
foreach ($f in $ttfs) {
    # Prefer Mono Regular/Bold for terminals; install all still OK
    $dest = Join-Path $fontsUser $f.Name
    Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
    # Register with Windows Fonts folder (best-effort)
    try {
        $fontsNs.CopyHere($f.FullName, 0x10)
    } catch { }
    $count++
}

Write-Host "Installed/copied $count font file(s) to $fontsUser"
Write-Host "Fully quit and reopen WezTerm so font caches refresh."
Remove-Item $zip -Force -ErrorAction SilentlyContinue
