# wezterm-env

Portable **WezTerm + PowerShell + Oh My Posh** setup for Windows, with an optional **cursor smear/trail** build ([wezterm/wezterm#7737](https://github.com/wezterm/wezterm/pull/7737) + a single-cell patch). The WezTerm config also works on macOS.

Maintainer: [Kurak0oo](https://github.com/Kurak0oo)

## Install (Windows)

```powershell
git clone https://github.com/Kurak0oo/wezterm-env.git
cd wezterm-env
.\install.cmd -WithCursorTrail
```

`install.cmd` runs the installer with `-ExecutionPolicy Bypass`, so it also works where scripts are blocked.
On cybercafe / locked PCs add `-SkipWinget`; see [docs/RESTRICTED-PC.md](docs/RESTRICTED-PC.md).

Without git (downloads the repo to `%USERPROFILE%\src\wezterm-env`, then installs):

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Kurak0oo/wezterm-env/main/install.ps1))) -WithCursorTrail
```

Launch the trail build from the desktop shortcut **WezTerm Cursor Trail**. Plain `wezterm` stays the stock build.

### Flags

| Flag | Meaning |
|------|---------|
| `-WithCursorTrail` | Install the pinned trail release (SHA256-checked) + launcher + desktop shortcut |
| `-UpdateTrail` | Replace an installed trail build with the version pinned in `install.ps1` |
| `-WithFont` | Install 0xProto Nerd Font (optional: WezTerm already bundles Nerd Font symbols) |
| `-SkipWinget` | Don't use winget (broken or blocked on locked PCs) |
| `-BuildTrailFromSource` | Build the trail branch locally (needs Rust, VS C++ tools, Perl) |

Re-running the installer is safe: unchanged files are skipped, changed ones get a `.bak.<timestamp>` backup.

### What it changes

| Piece | Where |
|-------|-------|
| WezTerm config | `config/wezterm.lua` → `%USERPROFILE%\.wezterm.lua` |
| Shell profile | `~\.config\wezterm-env\profile.ps1`, loaded by one line added to `$PROFILE` (PS 7 and 5.1) |
| Trail build | `%LOCALAPPDATA%\WezTerm-Trail` (incl. `Start-WezTerm-CursorTrail.bat`) |
| Wallpaper (optional) | put `bg.jpg` in `~\.config\wezterm\backgrounds\`, or in `assets/backgrounds/` before installing |

### Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -RemoveTrailBinary -RemoveFont
```

`-RestoreBackups` puts back your previous `.wezterm.lua` instead of deleting it.

## macOS

```bash
brew install --cask wezterm
ln -s "$PWD/config/wezterm.lua" ~/.wezterm.lua
```

The config keeps your login shell on macOS. The trail effects only switch on in a trail build: set `WEZTERM_CURSOR_TRAIL=1` if you build PR #7737 yourself.

## Publishing a new trail build

1. Build with `scripts/Build-WezTerm-Trail.ps1` (pinned to a commit of the PR branch).
2. Zip the binaries as `wezterm-trail-windows-x64.zip` and attach it to a new GitHub release.
3. Update `$TrailTag` and `$TrailSha256` at the top of `install.ps1` (`Get-FileHash <zip>`).

## Known limits

- Stock WezTerm can't smear; that needs the trail build until #7737 is merged.
- Building the trail from source needs Rust (MSVC), VS 2022 C++ build tools and Perl.

## Attribution

WezTerm, PR #7737 / MathurinV, Oh My Posh, Nerd Fonts: respective upstream licenses.
This repo's scripts and config: **MIT**.
