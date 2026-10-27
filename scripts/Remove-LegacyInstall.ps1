# Remove files and PATH entries written by older versions of install.ps1
# (launchers in %USERPROFILE%, bin\wezterm-trail.cmd, trail dir on the user PATH).
# Called by install.ps1 and uninstall.ps1.

$binDir = Join-Path $env:USERPROFILE 'bin'
foreach ($old in @(
        (Join-Path $env:USERPROFILE 'Start-WezTerm-CursorTrail.ps1'),
        (Join-Path $env:USERPROFILE 'Start-WezTerm-CursorTrail.bat'),
        (Join-Path $binDir 'wezterm-trail.cmd')
    )) {
    if (Test-Path $old) {
        Remove-Item $old -Force
        Write-Host "  Removed old $old"
    }
}

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath) {
    $drop = @(Join-Path $env:LOCALAPPDATA 'WezTerm-Trail')
    # Only drop ~\bin when it is empty: the user may keep their own tools there.
    if ((Test-Path $binDir) -and -not (Get-ChildItem $binDir -Force | Select-Object -First 1)) {
        Remove-Item $binDir -Force
        $drop += $binDir
    }
    $kept = $userPath -split ';' | Where-Object { $_ -and ($drop -notcontains $_.TrimEnd('\')) }
    $newPath = $kept -join ';'
    if ($newPath -ne $userPath) {
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Host "  Removed old wezterm-env entries from user PATH"
    }
}
