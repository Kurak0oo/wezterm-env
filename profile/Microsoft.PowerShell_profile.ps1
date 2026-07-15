# =============================================================================
# PowerShell 7+ Profile - WezTerm + Oh My Posh (portable, fail-soft)
# Installed by Kurak0oo/wezterm-env install.ps1 -> $PROFILE
# Never throws: avoids WezTerm "pwsh exited with code 1" / CloseOnCleanExit noise
# =============================================================================

$ErrorActionPreference = 'SilentlyContinue'

# Oh My Posh (optional)
$ompThemeUrl = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin_mocha.omp.json'
try {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        oh-my-posh init pwsh --config $ompThemeUrl 2>$null | Invoke-Expression
    }
} catch {
    # keep default prompt
}

# PSReadLine (optional)
try {
    if (Get-Module -ListAvailable -Name PSReadLine) {
        Import-Module PSReadLine -ErrorAction SilentlyContinue
        Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
        Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
        # HistoryAndPlugin may fail on older PSReadLine — fall back already History
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
        # Switch parameters: do NOT pass $true
        Set-PSReadLineOption -HistorySearchCursorMovesToEnd -ErrorAction SilentlyContinue
        Set-PSReadLineOption -ShowToolTips -ErrorAction SilentlyContinue
        Set-PSReadLineOption -BellStyle None -ErrorAction SilentlyContinue
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ErrorAction SilentlyContinue
        Set-PSReadLineKeyHandler -Key 'Ctrl+d' -Function DeleteCharOrExit -ErrorAction SilentlyContinue
    }
} catch { }

try {
    Set-Alias -Name which -Value Get-Command -ErrorAction SilentlyContinue
} catch { }

# Clear leftover error records so shell starts "clean"
$Error.Clear()
$global:LASTEXITCODE = 0
