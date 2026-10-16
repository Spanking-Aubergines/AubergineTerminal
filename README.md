# dotfiles

Portable dotfiles for Arch Linux and Debian, with a dry-run-first installer.

## What this is

A small, opinionated dotfiles repository managed with GNU Stow. Zsh is the
interactive shell; Bash is used for scripts. The installer never makes
changes without being asked.

## Requirements

- Arch Linux or Debian
- Bash (bootstrap)
- `git`, `zsh`, `stow` (see `docs/dependencies.md`)

## Quick start

On a fresh machine:

~~~sh
DOTFILES_REPO_URL=<this-repo-url> ./scripts/bootstrap.sh
~~~

After the initial install, deploy every configuration package:

~~~sh
./scripts/install.sh --stow all --apply
~~~

Or clone manually:

~~~sh
git clone <this-repo> ~/.dotfiles
cd ~/.dotfiles
./scripts/install.sh
./scripts/install.sh --install
./scripts/install.sh --stow zsh
./scripts/install.sh --stow zsh --apply
./scripts/install.sh --set-shell
~~~

Run `./scripts/install.sh --help` for all flags.

## Interactive menu

For a guided workflow, run:

~~~sh
./scripts/menu.sh
~~~

It covers a guided full setup (packages, Stow deployment, login shell),
package status, installation, Stow deploy/unstow, Git hooks, and the
test suite.

## Layout

- `scripts/install.sh` — installer (dry-run by default)
- `packages/<distro>/required.txt` — desired packages per distribution
- `zsh/.zshrc` — shell configuration (deployed via Stow)
- `git/.gitconfig` — git configuration (deployed via Stow)
- `zsh/aliases.zsh` — navigation, listing, Git, and search aliases
- `zsh/functions.zsh` — directory, archive, process, and port helpers
- `zsh/.config/starship.toml` — Starship prompt (deployed via Stow)
- `btop/`, `fastfetch/`, `yazi/` — additional Stow packages
- `docs/decisions.md` — project decisions
- `docs/dependencies.md` — dependency inventory
- `tests/` — installer, manifest, and zsh-function regression tests

## Zsh aliases and functions

Aliases are loaded from `zsh/aliases.zsh`; helper functions are loaded from
`zsh/functions.zsh`. Both are sourced by `.zshrc` relative to their own file
location, so the repository does not need to live at a fixed path.

Useful functions:

- `mkcd DIR` — create a directory and change into it.
- `extract FILE` — extract supported `.tar`, `.tar.gz`, `.tar.bz2`,
  `.tar.xz`, `.gz`, `.bz2`, `.zip`, and `.7z` archives.
- `topcpu [N]` / `topmem [N]` — show processes sorted by CPU or memory use
  (default: 10 entries).
- `port PORT` — show listening sockets matching a port number.

Archive helpers require the relevant extraction utility to be installed.
`port` uses `ss`; process listings use `ps` and `head`. These are runtime
utility dependencies, not additional packages automatically installed by
the dotfiles installer.

## Tests

Run everything with one command:

~~~sh
./tests/run-all.sh
~~~

Or run the individual checks:

~~~sh
./tests/test-installer.sh
./tests/test-manifest.sh
shellcheck scripts/install.sh tests/*.sh
~~~

## Development

Install the repo's Git hooks once after cloning:

~~~sh
./scripts/install-hooks.sh
~~~

The pre-commit hook runs `./tests/run-all.sh` before each commit.

See `docs/testing.md` for test layout and conventions.

## Safety

- Dry-run is the default.
- Installation, Stow deployment, and login-shell changes are separate steps.
- The installer asks before installing packages and before applying Stow.
- The login shell is only changed with explicit confirmation.
- Existing unmanaged config files are never overwritten.
