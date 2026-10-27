# Restricted / cybercafe Windows PCs

Typical failures on locked machines and how to get around them.

## Recommended flow

1. Clone or download the repo ZIP to a **writable** folder (`U:\`, USB stick, Documents).
2. Run:
   ```powershell
   .\install.cmd -WithCursorTrail -SkipWinget
   ```
3. Start WezTerm from the desktop shortcut **WezTerm Cursor Trail**.

The installer prints a list of anything that failed at the end and exits with code 1 if something did.

## 1. `禁止运行脚本` / execution policy

```text
无法加载文件 ...\install.ps1，因为在此系统上禁止运行脚本
```

Use `install.cmd`, which always runs the installer with `-ExecutionPolicy Bypass`, or:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -WithCursorTrail
```

The trail launcher is a `.bat` file, so it runs without any policy change.

## 2. winget crashes / `无法启动此应用程序`

winget may be installed but broken under the cafe account. Add `-SkipWinget` and install WezTerm yourself
if it's missing (portable ZIP from wezterm.org, or ask staff). The trail build is self-contained, so you
don't need stock WezTerm to use it.

## 3. No git

The online installer doesn't need git; it falls back to downloading the repo ZIP:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Kurak0oo/wezterm-env/main/install.ps1))) -WithCursorTrail -SkipWinget
```

## 4. WezTerm: `pwsh.exe ... exited with code 1`

The config falls back to Windows PowerShell when PowerShell 7 isn't installed. If the shell still exits,
open `powershell -NoProfile` and run `. $HOME\.config\wezterm-env\profile.ps1`: the profile now prints
its errors instead of hiding them.

## What usually works without admin

| Step | Needs admin? |
|------|--------------|
| Copy `.wezterm.lua` + profile | No |
| Trail ZIP to `%LOCALAPPDATA%` | No |
| Per-user font (`-WithFont`) | No |
| winget installs | Often **yes** / blocked |
| Build trail from source | Yes (toolchain installs) |
