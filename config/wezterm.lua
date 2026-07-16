-- WezTerm config (portable) — part of Kurak0oo/wezterm-env
-- Windows: copy to %USERPROFILE%\.wezterm.lua  (install.ps1 does this)

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- ============================================================================
-- SHELL
-- ============================================================================
-- Prefer PowerShell 7 (pwsh). If missing (common with -SkipWinget / locked PCs),
-- fall back to Windows PowerShell so the pane does not die with exit code 1 and
-- "didn't exit cleanly" / CloseOnCleanExit noise.
local function exe_exists(name)
  -- where.exe succeeds when the name is on PATH (Windows).
  if wezterm.run_child_process then
    local ok = wezterm.run_child_process { 'where.exe', name }
    if ok then
      return true
    end
  end
  return false
end

local function file_exists_path(path)
  local f = io.open(path, 'rb')
  if f then
    f:close()
    return true
  end
  return false
end

if wezterm.target_triple and wezterm.target_triple:find('windows') then
  local home = wezterm.home_dir or os.getenv('USERPROFILE') or ''
  local pwsh_candidates = {
    home .. '\\AppData\\Local\\Microsoft\\WindowsApps\\pwsh.exe',
    'C:\\Program Files\\PowerShell\\7\\pwsh.exe',
    'C:\\Program Files\\PowerShell\\7-preview\\pwsh.exe',
  }
  local have_pwsh = false
  for _, p in ipairs(pwsh_candidates) do
    if file_exists_path(p) then
      config.default_prog = { p, '-NoLogo' }
      have_pwsh = true
      break
    end
  end
  if not have_pwsh and exe_exists('pwsh.exe') then
    config.default_prog = { 'pwsh.exe', '-NoLogo' }
    have_pwsh = true
  end
  if not have_pwsh then
    config.default_prog = { 'powershell.exe', '-NoLogo' }
  end
else
  config.default_prog = { 'pwsh', '-NoLogo' }
end

-- Close pane on any shell exit (avoids sticky "didn't exit cleanly" banner).
-- WezTerm default is CloseOnCleanExit, which shows that warning whenever the
-- shell exits with a non-zero code (missing pwsh, profile errors, etc.).
config.exit_behavior = 'Close'

-- ============================================================================
-- FONT
-- ============================================================================
-- Prefer 0xProto Nerd Font (install.ps1 can install it). Fallbacks for fresh machines.
config.font = wezterm.font_with_fallback {
  { family = '0xProto Nerd Font Mono' },
  { family = '0xProto Nerd Font' },
  { family = 'JetBrainsMono Nerd Font' },
  { family = 'JetBrainsMono NF' },
  { family = 'JetBrains Mono' },
  { family = 'Cascadia Code PL' },
  { family = 'Cascadia Code' },
  { family = 'FiraCode Nerd Font' },
  'Consolas',
}
config.font_size = 11.0
config.line_height = 1.05
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }

-- ============================================================================
-- CURSOR (always available)
-- ============================================================================
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 650
config.cursor_thickness = '2px'
config.cursor_blink_ease_in = 'EaseIn'
config.cursor_blink_ease_out = 'EaseOut'
config.animation_fps = 120
config.max_fps = 120

-- ============================================================================
-- CURSOR SMEAR / TRAIL (PR #7737 custom builds only)
-- ============================================================================
-- Stock WezTerm rejects unknown fields. Enable only when:
--   - launcher sets WEZTERM_CURSOR_TRAIL=1, or
--   - binary version looks like our trail build / PR commit
local ver = tostring(wezterm.version or '')
local env_trail = os.getenv('WEZTERM_CURSOR_TRAIL')
local HAS_CURSOR_TRAIL = (env_trail == '1' or env_trail == 'true')
  or ver:find('114a305d', 1, true)
  or ver:find('20260701', 1, true)
  or ver:find('cursor%-trail')
  or ver:find('cursor_trail')

if HAS_CURSOR_TRAIL then
  config.cursor_smear = true
  config.cursor_smear_gradient = true
  config.cursor_animation_duration = 0.12
  config.cursor_trail_size = 0.85
  config.cursor_trail_min_distance = 1
  config.cursor_trail_style = 'Torpedo' -- or nil for smear-only
  config.cursor_vfx_opacity = 0.45
  config.cursor_vfx_particle_lifetime = 0.28
  config.cursor_vfx_particle_density = 0.45
  config.cursor_vfx_particle_speed = 7.0
  config.cursor_vfx_particle_size = 0.4
  config.default_cursor_style = 'BlinkingBlock'
end

-- ============================================================================
-- BACKGROUND
-- ============================================================================
-- Prefer portable locations (first match wins):
--   ~/.config/wezterm/backgrounds/bg.jpg
--   ~/Pictures/WezTermBackgrounds/bg.jpg
local candidates = {
  wezterm.home_dir .. '\\.config\\wezterm\\backgrounds\\bg.jpg',
  wezterm.home_dir .. '\\Pictures\\WezTermBackgrounds\\bg.jpg',
  wezterm.home_dir .. '/.config/wezterm/backgrounds/bg.jpg',
  wezterm.home_dir .. '/Pictures/WezTermBackgrounds/bg.jpg',
}

local function file_exists(path)
  if wezterm.glob then
    local g = wezterm.glob(path)
    return g and #g > 0
  end
  -- Fallback: try io.open
  local f = io.open(path, 'rb')
  if f then
    f:close()
    return true
  end
  return false
end

local bg_path = nil
for _, p in ipairs(candidates) do
  if file_exists(p) then
    bg_path = p
    break
  end
end

config.background = {
  {
    source = { Color = '#0d1117' },
    width = '100%',
    height = '100%',
  },
}

if bg_path then
  table.insert(config.background, {
    source = { File = bg_path },
    width = '100%',
    height = '100%',
    opacity = 0.45,
    hsb = { brightness = 0.35, saturation = 0.85, hue = 1.0 },
  })
  config.colors = {
    background = 'rgba(13, 17, 23, 0.55)',
  }
else
  config.window_background_opacity = 0.96
end

-- ============================================================================
-- APPEARANCE
-- ============================================================================
config.color_scheme = 'Catppuccin Mocha'
config.window_padding = {
  left = '0.6cell',
  right = '0.6cell',
  top = '0.35cell',
  bottom = '0.35cell',
}
config.window_decorations = 'TITLE | RESIZE'
config.window_close_confirmation = 'NeverPrompt'
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.front_end = 'WebGpu'
config.webgpu_power_preference = 'HighPerformance'
config.scrollback_lines = 10000
-- Kitty keyboard protocol: required for apps (e.g. Grok TUI) that use Shift+Enter
-- for newlines. Without this, Grok reports "kitty keyboard protocol is off".
config.enable_kitty_keyboard = true
config.audible_bell = 'Disabled'
config.visual_bell = {
  fade_in_duration_ms = 60,
  fade_out_duration_ms = 120,
}
config.hide_mouse_cursor_when_typing = true

return config
