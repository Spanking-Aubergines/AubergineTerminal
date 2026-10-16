# Project decisions

## Supported distributions
- Arch Linux
- Debian

## Interactive shell
- Zsh is the default interactive shell.
- Bash remains available for bootstrap and maintenance scripts.
- The installer must verify that Zsh is installed before offering to
  change the user's login shell.
- Changing the login shell requires explicit user confirmation.

## Package management
- Package manifests contain explicitly selected desired packages.
- Do not export the currently installed package inventory.
- Track required, feature-specific, and optional dependencies separately.
- Record distribution-specific package names.
- Do not automatically remove packages.


## Plugin management
- Zinit is the plugin manager for Zsh.
- It loads plugins individually from GitHub and from the Oh My Zsh ecosystem
  without requiring Oh My Zsh itself.
- Turbo mode is used to defer plugin loading until after the prompt appears,
  keeping startup fast even with many plugins.
- Plugins are declared in `zsh/.zshrc`; no external framework is required.

## Configuration management
- GNU Stow manages configuration packages.
- Inspect existing files and symlinks before applying Stow.
- Do not overwrite existing user configuration without consent.

## Scope
- Do not assume Oh My Zsh, prompt frameworks, or plugins are required.
- Add each dependency to the manifests when its feature is approved.

## Installer behavior
- Package installation, Stow deployment, and login-shell changes are separate operations.
- Dry-run is the default for package checks and Stow deployment.
- The installer must not overwrite an existing unmanaged configuration file.
- The login shell remains unchanged unless the user explicitly confirms the change.
