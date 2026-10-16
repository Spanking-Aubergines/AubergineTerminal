# Dependency inventory

This project supports Arch Linux and Debian.

## Required project packages

| Purpose | Arch package | Debian package |
|---|---|---|
| Interactive shell | zsh | zsh |
| Version control | git | git |
| Configuration management | stow | stow |
| Shell prompt | starship | starship |
| Ping with a graph | gping | gping |
| Fuzzy finder and completion menu | fzf | fzf |
| Terminal file manager | yazi | yazi |
| `cat` replacement | bat | bat |
| `find` replacement | fd | fd-find |
| `grep` replacement | ripgrep | ripgrep |
| Smarter `cd` | zoxide | zoxide |
| `ls` replacement | eza | eza |
| Resource monitor | btop | btop |
| System info display | fastfetch | fastfetch |
| Terminal emulator | kitty | kitty |

Authoritative installation lists:
- `packages/arch/required.txt`
- `packages/debian/required.txt`

On Debian, configure the official Yazi APT repository using the [upstream installation instructions](https://yazi-rs.github.io/docs/installation/) before installing required packages if `yazi` is unavailable in the configured repositories.

These lists contain explicitly selected desired packages. They must not be
generated from the set of packages already installed on a machine.

## Nerd Fonts

Prompt and TUI tools (Starship, yazi, eza, btop) use Nerd Font glyphs. A
patched font must be installed for those glyphs to render correctly.

- Arch Linux: `ttf-jetbrains-mono-nerd` (in `packages/arch/required.txt`).
- Debian: the Nerd Font patched build is not packaged. Install it manually
  from <https://www.nerdfonts.com/fonts> into `~/.local/share/fonts/`, then
  run `fc-cache -fv`. The kitty configuration expects
  `JetBrainsMono Nerd Font`.

## Bootstrap prerequisites

- Bash: runs the installer and maintenance scripts.
- A supported distribution and its package manager:
  - Arch Linux: `pacman`
  - Debian: `apt-get`
- `getent`: identifies the current login shell for `--set-shell`.
- `chsh`: changes the login shell when explicitly approved.
- Administrative privileges when packages need to be installed.
- Network access when the package manager needs to download packages.

Git is needed to clone or update this repository. If the repository has
already been downloaded, Git is not inherently required just to read or
run the installer.

## Installer operations

- Default / `--dry-run`: check the required package manifest without changes.
- `--install`: ask before installing missing required packages.
- `--stow PACKAGE`: preview deployment of a Stow package.
- `--stow PACKAGE --apply`: ask before deploying configuration.
- `--set-shell`: check Zsh and offer to change the login shell.

The login-shell operation is separate from package installation and Stow
deployment. It checks that `/usr/bin/zsh` is executable and listed in
`/etc/shells`, and requires confirmation before calling `chsh`.


## Zsh plugins (managed by Zinit)

| Plugin | Purpose |
|---|---|
| zdharma-continuum/fast-syntax-highlighting | Real-time syntax highlighting as you type |
| zsh-users/zsh-autosuggestions | Fish-style history-based suggestions |
| zsh-users/zsh-completions | Extra completion definitions |
| zsh-users/zsh-history-substring-search | Search history by substring with Ctrl+P/Ctrl+N |
| hlissner/zsh-autopair | Auto-close brackets and quotes |
| MichaelAquilina/zsh-you-should-use | Remind you when an alias exists for a command you typed |
| Aloxaf/fzf-tab | Use fzf as the tab-completion menu (requires `fzf`) |
| jeffreytse/zsh-vi-mode | Improved vi mode: cursor shape, ESC delay fix, text objects |

Zinit itself is cloned on first run of `zsh/.zshrc` into
`${XDG_DATA_HOME:-$HOME/.local/share}/zinit`. Plugins are loaded in Turbo
mode, so most of them finish loading just after the first prompt appears.

The primary interactive shell remains Zsh, as declared in
`packages/<distro>/required.txt`.

## Utilities used by Zsh helpers

The helper functions use system commands when invoked; not every utility is
needed for every workflow:

- `extract`: `tar`, `bunzip2`, `gunzip`, `unzip`, or `7z`, depending on the
  archive format.
- `topcpu` and `topmem`: `ps` and `head`.
- `port`: `ss` and `grep`.

Install the relevant utility if a helper reports that it is unavailable.
These utilities are not added to the required package manifests solely
because an optional helper can use them.

## Machine-specific overrides

Optional files not tracked by this repository, sourced only if present:

- `~/.zshrc.local` — sourced at the end of `~/.zshrc`.
- `~/.gitconfig.local` — included by `~/.gitconfig`.

Use these for work email addresses, tokens, machine-only paths, or anything
that should never enter version control.

## Stow packages

Each top-level directory is a GNU Stow package:

| Package | Deploys |
|---|---|
| `zsh` | `~/.zshrc`, `~/.config/starship.toml` |
| `git` | `~/.gitconfig` |
| `btop` | `~/.config/btop/btop.conf` |
| `fastfetch` | `~/.config/fastfetch/config.jsonc` |
| `yazi` | `~/.config/yazi/yazi.toml` |

Deploy one with `./scripts/install.sh --stow PACKAGE --apply`.

## Dependency management rules

- Add a package only when the project explicitly requires or offers it.
- Record the Arch and Debian package names separately.
- Document why each dependency is needed.
- Keep required and optional dependencies separate.
- Do not export installed package inventories.
- Do not remove packages automatically.
- Check which required packages are missing before installing.
- Ask for confirmation before making system changes.
- Ask for explicit confirmation before changing the login shell.

## Optional terminal tools

| Tool | Purpose | Configuration |
|---|---|---|
| btop | Interactive resource monitor | Stow package `btop` |
| Fastfetch | System information display | Stow package `fastfetch` |
