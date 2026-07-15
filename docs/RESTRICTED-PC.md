# Restricted / cybercafe Windows PCs

Typical failures when using **wezterm-env** on locked machines, and how to fix them.

## 1. `禁止运行脚本` / Execution Policy

```text
无法加载文件 ...\install.ps1，因为在此系统上禁止运行脚本
```

**Fix (always works for one run):**

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -WithCursorTrail
```

Or double-click / run:

```text
install.cmd -WithCursorTrail
```

**Launch trail without policy issues:**

```text
%USERPROFILE%\Start-WezTerm-CursorTrail.bat
```

Do **not** rely on bare `.\install.ps1` or `powershell -File ...ps1` under Restricted.

---

## 2. winget crashes / `无法启动此应用程序`

winget may be installed but broken under the cafe account.

**Fix:** skip package manager; only deploy configs + trail zip:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -WithCursorTrail -SkipWinget -SkipFonts
```

Install WezTerm / pwsh yourself if missing (portable zip or ask staff).

---

## 3. `git` not found with `irm | iex`

The online installer no longer requires git: it downloads a **zip** of the repo if git is missing.

Still simplest on a PC where you already cloned with GitHub Desktop / zip extract:

```powershell
cd U:\workspace\wezterm-env
.\install.cmd -WithCursorTrail -SkipWinget
```

---

## 4. WezTerm: `pwsh.exe ... Exited with code 1` / CloseOnCleanExit

Usually the PowerShell **profile** printed errors or set a bad exit code.

Current profile is fail-soft and clears `$LASTEXITCODE`. Config sets `exit_behavior = 'Close'`.

If pwsh is not installed:

```lua
-- in %USERPROFILE%\.wezterm.lua
config.default_prog = { 'powershell.exe', '-NoLogo' }
```

---

## 5. Recommended cybercafe flow

1. Clone or download zip of `wezterm-env` to a **writable** path (`U:\`, USB, Documents).
2. Run:
   ```powershell
   .\install.cmd -WithCursorTrail -SkipWinget
   ```
3. Ensure trail binary downloaded (needs internet for GitHub Releases).
4. Start with **Start-WezTerm-CursorTrail.bat** or desktop shortcut.
5. Optional: copy your own `bg.jpg` to `%USERPROFILE%\.config\wezterm\backgrounds\`.

## What usually works without admin

| Step | Needs admin? |
|------|----------------|
| Copy `.wezterm.lua` + profile | No |
| Download trail zip to `%LOCALAPPDATA%` | No (user write) |
| User font install | Often no |
| winget install apps | Often **yes** / blocked |
| Build trail from source | Yes (tools) |
