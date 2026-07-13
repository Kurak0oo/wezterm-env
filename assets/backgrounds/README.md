# Backgrounds

Place a wallpaper file named **`bg.jpg`** (or update the path in `config/wezterm.lua`).

Install script creates:

```text
%USERPROFILE%\.config\wezterm\backgrounds\
```

Also accepted by the portable config:

```text
%USERPROFILE%\Pictures\WezTermBackgrounds\bg.jpg
```

## Tips

- Prefer dark / low-contrast images for readability
- ~1920×1080 is enough; large 4K files slow VRAM
- Opacity / brightness are tuned in `config/wezterm.lua` (`opacity`, `hsb.brightness`)

Personal wallpapers are **not** shipped in this repo (size / privacy). Copy your own `bg.jpg` after install.
