# dotfiles

Personal configuration, deployed with [GNU Stow](https://www.gnu.org/software/stow/).
One branch, `main`, shared by every machine. Machines differ in *which packages
they link*, not in which branch they sit on.

## Layout

Every top-level directory except `hosts/` is a stow package whose contents
mirror `$HOME`:

```
aerospace/.config/aerospace/aerospace.toml   ->   ~/.config/aerospace/aerospace.toml
```

`hosts/<hostname>/packages` is a plain list, one package name per line, of what
that machine should link. Blank lines and `#` comments are ignored.

## Installing on a new machine

```sh
brew install stow
git clone git@github.com:awild/dotfiles.git ~/dotfiles
cd ~/dotfiles
mkdir -p "hosts/$(hostname -s)"
printf 'aerospace\n' > "hosts/$(hostname -s)/packages"
./install.sh
```

`./install.sh -n` shows what would change without writing anything. `./install.sh -D`
unlinks everything this host had linked. Set `DOTFILES_HOST` to act as another
machine.

Stow is run with `--no-folding`, so it links individual files and leaves shared
parent directories like `~/.config` as real directories. Unrelated files that
land there stay out of the repo.

## Per-machine differences

A package directory under `hosts/<hostname>/` takes precedence over the
same-named package at the repo root. To give one Mac its own AeroSpace config
while every other machine keeps the shared one:

```
aerospace/.config/aerospace/aerospace.toml          # shared default
hosts/othermac/aerospace/.config/aerospace/aerospace.toml   # just for othermac
```

Both hosts still list `aerospace` in their package file. Each gets the nearest
copy.

Prefer not to do this. Stow symlinks files and cannot merge them, so an override
is a second full copy that will drift from the original. Where the real
difference is small, keep the single shared file and push the variation into a
host-specific script invoked from `after-startup-command` or a keybinding. If
per-host variation ever needs to reach *inside* many files, Stow is the wrong
tool and [chezmoi](https://www.chezmoi.io/) is the right one.
