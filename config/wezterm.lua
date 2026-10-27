-- WezTerm config (portable) — part of Kurak0oo/wezterm-env
-- Windows: install.ps1 copies this to %USERPROFILE%\.wezterm.lua
-- macOS:   ln -s "$PWD/config/wezterm.lua" ~/.wezterm.lua

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find('windows') ~= nil
local is_macos = wezterm.target_triple:find('apple') ~= nil

local function file_exists(path)
  local f = io.open(path, 'rb')
  if f then
    f:close()
    return true
  end
  return false
end

-- ============================================================================
-- SHELL
-- ============================================================================
-- Windows: prefer PowerShell 7, fall back to Windows PowerShell (locked PCs often
-- have only 5.1). Other platforms keep the user's login shell.
if is_windows then
  local pwsh = 'C:\\Program Files\\PowerShell\\7\\pwsh.exe'
  local pwsh_store = wezterm.home_dir .. '\\AppData\\Local\\Microsoft\\WindowsApps\\pwsh.exe'
  if file_exists(pwsh) then
    config.default_prog = { pwsh, '-NoLogo' }
  elseif file_exists(pwsh_store) then
    config.default_prog = { pwsh_store, '-NoLogo' }
  else
    config.default_prog = { 'powershell.exe', '-NoLogo' }
  end
end

-- ============================================================================
-- FONT
-- ============================================================================
-- WezTerm bundles JetBrains Mono and Nerd Font symbols, so icons work even
-- without 0xProto installed (install.ps1 -WithFont).
config.font = wezterm.font_with_fallback {
  '0xProto Nerd Font',
  'JetBrains Mono',
}
-- macOS points are larger on Retina screens; 11 looks tiny there.
config.font_size = is_macos and 14.0 or 11.0
config.line_height = 1.05

-- ============================================================================
-- CURSOR
-- ============================================================================
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 650
config.cursor_thickness = '2px'
config.animation_fps = 60

-- ============================================================================
-- CURSOR SMEAR / TRAIL (PR #7737 builds only)
-- ============================================================================
-- Stock WezTerm rejects these unknown fields, so enable them only when running the
-- trail build: it lives in a WezTerm-Trail folder (install.ps1), or the launcher
-- sets WEZTERM_CURSOR_TRAIL=1 (e.g. a self-built binary on macOS).
local env_trail = os.getenv('WEZTERM_CURSOR_TRAIL')
local HAS_CURSOR_TRAIL = env_trail == '1'
  or env_trail == 'true'
  or (wezterm.executable_dir or ''):find('WezTerm%-Trail') ~= nil

if HAS_CURSOR_TRAIL then
  config.animation_fps = 120
  config.max_fps = 120
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
-- Optional wallpaper, first match wins ('/' works on Windows too):
--   ~/.config/wezterm/backgrounds/bg.jpg | bg.png
--   ~/Pictures/WezTermBackgrounds/bg.jpg
local bg_path = nil
for _, p in ipairs {
  wezterm.home_dir .. '/.config/wezterm/backgrounds/bg.jpg',
  wezterm.home_dir .. '/.config/wezterm/backgrounds/bg.png',
  wezterm.home_dir .. '/Pictures/WezTermBackgrounds/bg.jpg',
} do
  if file_exists(p) then
    bg_path = p
    break
  end
end

if bg_path then
  config.background = {
    { source = { Color = '#0d1117' }, width = '100%', height = '100%' },
    {
      source = { File = bg_path },
      width = '100%',
      height = '100%',
      opacity = 0.45,
      hsb = { brightness = 0.35, saturation = 0.85, hue = 1.0 },
    },
  }
  -- Translucent cell background so the wallpaper shows through the text area.
  config.colors = { background = 'rgba(13, 17, 23, 0.55)' }
else
  config.window_background_opacity = 0.96
  if is_macos then
    config.macos_window_background_blur = 20
  end
end

-- ============================================================================
-- APPEARANCE / BEHAVIOUR
-- ============================================================================
config.color_scheme = 'Catppuccin Mocha'
config.window_padding = {
  left = '0.6cell',
  right = '0.6cell',
  top = '0.35cell',
  bottom = '0.35cell',
}
config.window_decorations = 'TITLE | RESIZE'
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.scrollback_lines = 10000
-- Kitty keyboard protocol: needed by TUIs that use Shift+Enter for newlines.
config.enable_kitty_keyboard = true
config.audible_bell = 'Disabled'
config.visual_bell = {
  fade_in_duration_ms = 60,
  fade_out_duration_ms = 120,
}
config.hide_mouse_cursor_when_typing = true

return config
