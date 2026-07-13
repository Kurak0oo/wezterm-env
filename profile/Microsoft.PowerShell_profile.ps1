# =============================================================================
# PowerShell 7+ Profile - WezTerm + Oh My Posh (portable)
# Installed by Kurak0oo/wezterm-env install.ps1 -> $PROFILE
# =============================================================================

$ompThemeUrl = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin_mocha.omp.json'

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    try {
        oh-my-posh init pwsh --config $ompThemeUrl | Invoke-Expression
    } catch {
        Write-Warning "Oh My Posh init failed: $_"
        function prompt { "PS $($executionContext.SessionState.Path.CurrentLocation)> " }
    }
} else {
    Write-Warning "oh-my-posh not found. Install: winget install JanDeDobbeleer.OhMyPosh"
}

if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
    # Switch params: do NOT pass $true (becomes a stray positional argument)
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd -ErrorAction SilentlyContinue
    Set-PSReadLineOption -ShowToolTips -ErrorAction SilentlyContinue
    Set-PSReadLineOption -BellStyle None -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key 'Ctrl+d' -Function DeleteCharOrExit -ErrorAction SilentlyContinue
}

Set-Alias -Name which -Value Get-Command -ErrorAction SilentlyContinue
