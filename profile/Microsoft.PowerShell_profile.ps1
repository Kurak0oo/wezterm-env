# =============================================================================
# wezterm-env PowerShell profile (PowerShell 7 and Windows PowerShell 5.1)
# install.ps1 copies this to ~\.config\wezterm-env\profile.ps1 and dot-sources it
# from $PROFILE. Every step is optional and must never throw: a failing profile
# makes WezTerm report "pwsh exited with code 1".
# =============================================================================

# Oh My Posh: use the theme cached by install.ps1, never fetch it at shell start.
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ompTheme = Join-Path $PSScriptRoot 'catppuccin_mocha.omp.json'
    try {
        if (Test-Path $ompTheme) {
            oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
        } else {
            oh-my-posh init pwsh | Invoke-Expression
        }
    } catch {
        Write-Warning "wezterm-env: Oh My Posh init failed: $($_.Exception.Message)"
    }
    Remove-Variable ompTheme
}

# PSReadLine: prediction options need PSReadLine 2.1+ (5.1 ships 2.0), hence the try.
if (Get-Module -ListAvailable -Name PSReadLine) {
    try {
        Import-Module PSReadLine
        Set-PSReadLineOption -EditMode Windows -BellStyle None -HistorySearchCursorMovesToEnd -ShowToolTips
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Key 'Ctrl+d' -Function DeleteCharOrExit
        Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
    } catch { }
}

Set-Alias -Name which -Value Get-Command

$global:LASTEXITCODE = 0
