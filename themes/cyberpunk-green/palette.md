# cyberpunk-green

A green-dominant cyberpunk palette for the whole terminal. Dark near-black
base, neon green accent, and a full multi-hue ANSI ramp so syntax
highlighting stays readable.

Single source of truth: when a color changes, change it here first, then
propagate to each app's theme file.

## Base

| Role           | Hex       | Notes                            |
|----------------|-----------|----------------------------------|
| bg             | `#0a1410` | Deep green-black background      |
| bg_alt         | `#101c18` | Panels, inactive lines           |
| bg_highlight   | `#16271f` | Selection, cursor line           |
| fg             | `#d8f5e3` | Pale mint, primary text          |
| fg_dim         | `#7a9b8a` | Comments, annotations            |

## Neon accents

| Role           | Hex       | Use                              |
|----------------|-----------|----------------------------------|
| neon_green     | `#00ff9f` | Primary accent, keywords, prompt |
| neon_cyan      | `#00e5ff` | Functions, links                 |
| neon_magenta   | `#ff2e97` | Strings, git branch              |
| neon_amber     | `#ffb000` | Numbers, warnings, git status    |
| neon_purple    | `#bd93f9` | Types, directory                 |
| neon_blue      | `#4d7fff` | Constants, info                  |
| neon_red       | `#ff3b5c` | Errors, deletions                |

## ANSI 16-color ramp

| #  | Name       | Hex       |
|----|------------|-----------|
| 0  | black      | `#0a1410` |
| 1  | red        | `#ff3b5c` |
| 2  | green      | `#00ff9f` |
| 3  | yellow     | `#ffb000` |
| 4  | blue       | `#4d7fff` |
| 5  | magenta    | `#ff2e97` |
| 6  | cyan       | `#00e5ff` |
| 7  | white      | `#d8f5e3` |
| 8  | br_black   | `#3a4d44` |
| 9  | br_red     | `#ff6b87` |
| 10 | br_green   | `#5cffb8` |
| 11 | br_yellow  | `#ffd066` |
| 12 | br_blue    | `#7aa3ff` |
| 13 | br_magenta | `#ff6bb5` |
| 14 | br_cyan    | `#5cefff` |
| 15 | br_white   | `#f0fff7` |

## Per-app mapping

Each app's theme file is generated from this palette. Status:

- [ ] Starship (`zsh/.config/starship.toml`)
- [ ] kitty (`kitty/.config/kitty/current-theme.conf`)
- [ ] btop (`btop/.config/btop/btop.conf`)
- [ ] bat (custom `.tmTheme` + `BAT_THEME`)
- [ ] delta (`git/.gitconfig` syntax-theme)
- [ ] yazi (`yazi/.config/yazi/theme.toml`)
- [ ] lazygit (`lazygit/.config/lazygit/config.yml`)
- [ ] lazydocker (`lazydocker/.config/lazydocker/config.yml`)
- [ ] fastfetch (`fastfetch/.config/fastfetch/config.jsonc`)
- [ ] eza (`EZA_COLORS` in `.zshrc`)
- [ ] fzf (`FZF_DEFAULT_OPTS` in `.zshrc`)
- [ ] zsh-vi-mode (`ZVM_*` variables)
