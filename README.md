# wezterm-env

Portable **WezTerm + PowerShell 7 + Oh My Posh + Nerd Font** setup for Windows, with optional **cursor smear/trail** (WezTerm [PR #7737](https://github.com/wezterm/wezterm/pull/7737) + single-cell typing/arrow patch).

Maintainer GitHub: [Kurak0oo](https://github.com/Kurak0oo)

## One-command install

```powershell
# Quick: stock WezTerm + config + profile + 0xProto Nerd Font
irm https://raw.githubusercontent.com/Kurak0oo/wezterm-env/main/install.ps1 | iex
```

```powershell
# Full: also install cursor-trail binary (Release download, or local build copy)
git clone https://github.com/Kurak0oo/wezterm-env.git $env:USERPROFILE\src\wezterm-env
cd $env:USERPROFILE\src\wezterm-env
.\install.ps1 -WithCursorTrail
```

Build trail from source (slow, needs Rust + VS C++ + Strawberry Perl):

```powershell
.\install.ps1 -WithCursorTrail -BuildTrailFromSource
```

## What you get

| Piece | Details |
|-------|---------|
| Config | `config/wezterm.lua` → `%USERPROFILE%\.wezterm.lua` |
| Shell | PowerShell 7 + Oh My Posh Catppuccin Mocha |
| Font | 0xProto Nerd Font Mono (with fallbacks) |
| Theme | Catppuccin Mocha, high-FPS cursor blink |
| Wallpaper | Drop `bg.jpg` in `%USERPROFILE%\.config\wezterm\backgrounds\` |
| Trail (optional) | GPU smear + Torpedo particles; desktop shortcut **WezTerm Cursor Trail** |

## Launch trail WezTerm

Stock winget WezTerm **does not** support `cursor_smear` (config would error without guards).

```powershell
powershell -File $env:USERPROFILE\Start-WezTerm-CursorTrail.ps1
# or Desktop shortcut: "WezTerm Cursor Trail"
# or: wezterm-trail start
```

The launcher sets `WEZTERM_CURSOR_TRAIL=1` so the config enables smear options only for that process.

## Layout

```text
config/wezterm.lua
profile/Microsoft.PowerShell_profile.ps1
scripts/Install-NerdFont.ps1
scripts/Build-WezTerm-Trail.ps1
scripts/Start-WezTerm-Trail.ps1
patches/0001-single-cell-smear.patch
install.ps1
uninstall.ps1
```

## Uninstall managed files

```powershell
.\uninstall.ps1 -RemoveTrailBinary -RestoreBackups
```

Does **not** remove winget packages (WezTerm / Oh My Posh / PowerShell).

## Attribution

- WezTerm — [wezterm/wezterm](https://github.com/wezterm/wezterm)
- Cursor trail — [PR #7737](https://github.com/wezterm/wezterm/pull/7737) / MathurinV
- Oh My Posh, Nerd Fonts — respective upstream projects

Your scripts/config in this repo: **MIT** (see `LICENSE`).

## Docs

- [docs/AUDIT.md](docs/AUDIT.md) — checklist of the original setup
