# Audit summary (2026-07-12)

Portable packaging of the Eiji laptop setup under **Kurak0oo/wezterm-env**.

## Components

| Component | Status |
|-----------|--------|
| Stock WezTerm (winget) | Supported via install.ps1 |
| Cursor trail (PR #7737 + single-cell patch) | Optional `-WithCursorTrail` |
| `.wezterm.lua` | Portable paths + trail env guard |
| PowerShell 7 profile | Oh My Posh + PSReadLine (switch-safe) |
| 0xProto Nerd Font | Install-NerdFont.ps1 |
| Wallpaper | User-provided `bg.jpg` |

## Known intentional limits

- Stock WezTerm **cannot** smear; only trail binary + `WEZTERM_CURSOR_TRAIL=1` (or matching version string).
- Building trail from source needs Rust MSVC, VS C++ tools, Strawberry Perl.
- Prebuilt Release may be empty until CI/manual release is published; local copy path still works on the original machine.
