# Dependency inventory

This project supports Arch Linux and Debian.

## Required project packages

| Purpose | Arch package | Debian package |
|---|---|---|
| Interactive shell | zsh | zsh |
| Version control | git | git |
| Configuration management | stow | stow |

Authoritative installation lists:
- `packages/arch/required.txt`
- `packages/debian/required.txt`

These lists contain explicitly selected desired packages. They must not be
generated from the set of packages already installed on a machine.

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
