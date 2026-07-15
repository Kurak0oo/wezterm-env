# wezterm-env

Portable **WezTerm + PowerShell 7 + Oh My Posh + Nerd Font** setup for Windows, with optional **cursor smear/trail** ([PR #7737](https://github.com/wezterm/wezterm/pull/7737) + single-cell patch).

Maintainer: [Kurak0oo](https://github.com/Kurak0oo)

## Install (normal PC)

```powershell
git clone https://github.com/Kurak0oo/wezterm-env.git
cd wezterm-env
.\install.cmd -WithCursorTrail
```

`install.cmd` always uses `-ExecutionPolicy Bypass` so Restricted policies do not block the script.

## Install (cybercafe / locked PC)

```powershell
# You already cloned or unzipped the repo somewhere writable (e.g. U:\workspace\wezterm-env)
cd U:\workspace\wezterm-env

# Config + trail zip only (skip broken winget / fonts if needed)
.\install.cmd -WithCursorTrail -SkipWinget
# or:
powershell -ExecutionPolicy Bypass -File .\install.ps1 -WithCursorTrail -SkipWinget -SkipFonts
```

**Do not** run bare `.\install.ps1` under Restricted policy — use `install.cmd` or Bypass.

### Launch trail (no script policy)

After install, **double-click**:

```text
%USERPROFILE%\Start-WezTerm-CursorTrail.bat
```

or the desktop shortcut **WezTerm Cursor Trail**.

See [docs/RESTRICTED-PC.md](docs/RESTRICTED-PC.md) for winget/git/execution-policy errors.

## Online one-liner

```powershell
# Needs internet; uses git if present, else downloads repo zip (no git required)
irm https://raw.githubusercontent.com/Kurak0oo/wezterm-env/main/install.ps1 | iex
```

If that is blocked, download the repo ZIP from GitHub → extract → `install.cmd`.

## What you get

| Piece | Details |
|-------|---------|
| Config | `config/wezterm.lua` → `%USERPROFILE%\.wezterm.lua` |
| Shell profile | Oh My Posh + PSReadLine (fail-soft) |
| Font | 0xProto Nerd Font (optional install) |
| Trail | GitHub Release zip → `%LOCALAPPDATA%\WezTerm-Trail` |
| Launchers | `.bat` (no policy) + `.ps1` + desktop shortcut |

## Flags

| Flag | Meaning |
|------|---------|
| `-WithCursorTrail` | Download/install trail binary + launchers |
| `-SkipWinget` | Do not call winget (broken/locked PCs) |
| `-SkipFonts` | Skip Nerd Font download |
| `-BuildTrailFromSource` | Compile PR branch (needs Rust/MSVC; not for cafes) |

## Uninstall managed files

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -RemoveTrailBinary -RestoreBackups
```

## Layout

```text
install.cmd / install.ps1
config/wezterm.lua
profile/Microsoft.PowerShell_profile.ps1
scripts/...
patches/0001-single-cell-smear.patch
docs/RESTRICTED-PC.md
```

## Attribution

WezTerm, PR #7737 / MathurinV, Oh My Posh, Nerd Fonts — respective upstream licenses.  
This repo’s scripts/config: **MIT**.
