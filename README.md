# dotfiles

My personal Linux configuration, managed with GNU Stow.
Works on **Arch Linux** and **Debian**.

---

## For humans — start here

### What is this?

This is my dotfiles repository. It holds the configuration files that make
my terminal feel like home: my shell setup, prompt, aliases, git config,
and the settings for a few command-line tools.

Instead of copying files around by hand, everything lives here in one place
and gets "linked" into the right spot on any machine.

### What do I do with it?

**On a brand-new machine**, open a terminal and run:

~~~sh
git clone <this-repo-url> ~/.dotfiles
cd ~/.dotfiles
./scripts/menu.sh
~~~

That last command opens a simple menu. Pick **"1) Full setup"** and follow
the prompts. The menu will:

1. Check which packages you need and offer to install the missing ones.
2. Link all the configuration files into your home directory.
3. Offer to make Zsh your default shell.

That's it. Answer the questions, and you're done.

### I already have it installed. What now?

Run the menu any time:

~~~sh
cd ~/.dotfiles
./scripts/menu.sh
~~~

Everything is a numbered option. Nothing changes on your system unless you
say yes to a prompt first.

### I want to remove it.

Each piece can be undone. To remove the links for one config package:

~~~sh
./scripts/unstow.sh <package-name>
~~~

It shows you what would be removed first. Add `--apply` to actually do it.

### Where do my personal settings go?

Anything machine-specific — work email, private tokens, a path that only
exists on one computer — goes in one of these files, which are **never**
committed:

- `~/.zshrc.local`
- `~/.gitconfig.local`

They're read automatically if they exist.

### I'm nervous about it doing something unexpected.

Good. It's built that way:

- **Nothing happens without asking.** Every action shows what it will do
  and waits for a `y`.
- **Dry runs are the default.** The installer shows you the plan before
  touching anything.
- **Nothing is deleted.** No package removal, no overwriting your files.
- **No hidden steps.** If a file already exists and isn't managed by this
  repo, the installer stops and tells you.

---

## Quick start (technical)

Clone and run the guided setup:

~~~sh
git clone <this-repo> ~/.dotfiles
cd ~/.dotfiles
./scripts/menu.sh
~~~

Or drive it directly:

~~~sh
./scripts/install.sh                   # check packages (dry-run)
./scripts/install.sh --install         # install missing packages
./scripts/install.sh --stow all        # preview all config links
./scripts/install.sh --stow all --apply
./scripts/install.sh --set-shell       # make Zsh the login shell
~~~

`./scripts/install.sh --help` lists every flag.

### One-shot bootstrap

On a fresh machine, clone and set up in one command:

~~~sh
DOTFILES_REPO_URL=<this-repo-url> ./scripts/bootstrap.sh
~~~

## Interactive menu

`./scripts/menu.sh` provides a numbered menu for:

- **Full setup** — packages, Stow deployment, and login shell in one flow.
- Package status and installation.
- Stow deployment (all packages, or one at a time).
- Unstow (dry-run or apply).
- Login shell change.
- Git hook installation.
- Running the test suite.

## Layout

- `scripts/menu.sh` — interactive menu
- `scripts/install.sh` — package check/install and Stow deployment
- `scripts/unstow.sh` — remove Stow-created links
- `scripts/bootstrap.sh` — clone + install on a fresh machine
- `packages/<distro>/required.txt` — desired packages per distribution
- `zsh/` — shell, prompt, aliases, functions
- `git/`, `kitty/`, `btop/`, `fastfetch/`, `yazi/` — app configs
- `docs/decisions.md` — why things are the way they are
- `docs/dependencies.md` — dependency inventory
- `docs/testing.md` — test layout and conventions
- `tests/` — regression tests

## Development

Install the repository's Git hooks once after cloning:

~~~sh
./scripts/install-hooks.sh
~~~

The pre-commit hook runs `./tests/run-all.sh` before each commit.
See `docs/testing.md` for test layout and conventions.

## Safety

- Dry-run is the default for every operation.
- Installation, Stow deployment, and login-shell changes are separate steps.
- The installer asks before installing packages and before creating links.
- The login shell is only changed with explicit confirmation.
- Existing unmanaged files are never overwritten.
