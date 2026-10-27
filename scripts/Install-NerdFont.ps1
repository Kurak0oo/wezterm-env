# Install a Nerd Font for the current user (Windows, no admin needed)
param(
    [string]$FontFamily = '0xProto'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$fontsUser = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$regKey = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

$registered = Get-ItemProperty $regKey -ErrorAction SilentlyContinue
if ($registered -and ($registered.PSObject.Properties.Name -like "$FontFamily*Nerd*Font*")) {
    Write-Host "$FontFamily Nerd Font is already installed."
    return
}

# Direct "latest" link: no api.github.com call, so no 60/hour rate limit on shared IPs.
$url = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FontFamily.zip"
$zip = Join-Path $env:TEMP "$FontFamily.zip"
$tmp = Join-Path $env:TEMP "nerdfont-$FontFamily"
Write-Host "Downloading $url"
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
Expand-Archive -Path $zip -DestinationPath $tmp -Force

$files = Get-ChildItem -Path $tmp -Recurse -Include *.ttf, *.otf
if (-not $files) { throw "No font files found in $FontFamily.zip" }

New-Item -ItemType Directory -Force -Path $fontsUser | Out-Null
New-Item -Path $regKey -Force -ErrorAction SilentlyContinue | Out-Null
foreach ($f in $files) {
    $dest = Join-Path $fontsUser $f.Name
    Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
    # A per-user font is only installed once it is registered under HKCU.
    $kind = if ($f.Extension -eq '.otf') { 'OpenType' } else { 'TrueType' }
    Set-ItemProperty -Path $regKey -Name "$($f.BaseName) ($kind)" -Value $dest
}

Remove-Item $zip, $tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Installed $($files.Count) font file(s) to $fontsUser"
Write-Host "Fully quit and reopen WezTerm so it sees the new font."
