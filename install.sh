#!/usr/bin/env bash
#
# Link this host's dotfile packages into $HOME with GNU Stow.
#
# Packages are listed one per line in hosts/<hostname>/packages. For each name,
# a directory at hosts/<hostname>/<name> wins over the shared one at <name>,
# which is how a single machine overrides a shared config.

set -euo pipefail

readonly REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HOST="${DOTFILES_HOST:-$(hostname -s)}"
readonly HOST_DIR="$REPO/hosts/$HOST"
readonly MANIFEST="$HOST_DIR/packages"

# Link individual files rather than whole directories, so that unrelated files
# landing in a shared parent like ~/.config do not get swept into the repo.
STOW_FLAGS=(--no-folding --target="$HOME")

usage() {
    cat <<USAGE
usage: ${0##*/} [-n] [-D]

  -n  dry run; print what would change without touching the filesystem
  -D  unlink this host's packages instead of linking them

Host is detected as '$HOST'. Override it with DOTFILES_HOST.
USAGE
}

die() { printf '%s: %s\n' "${0##*/}" "$*" >&2; exit 1; }

main() {
    local action=--stow
    while getopts ':nDh' opt; do
        case "$opt" in
            n) STOW_FLAGS+=(--simulate --verbose) ;;
            D) action=--delete ;;
            h) usage; return 0 ;;
            *) usage >&2; return 2 ;;
        esac
    done

    command -v stow >/dev/null || die "GNU Stow is not installed; try 'brew install stow'"
    [[ -f "$MANIFEST" ]] || die "no package list at ${MANIFEST#$REPO/}; create it to enrol this host"

    local -a packages=()
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="$(printf '%s' "$line" | tr -d '[:space:]')"
        [[ -n "$line" ]] && packages+=("$line")
    done < "$MANIFEST"

    [[ ${#packages[@]} -gt 0 ]] || die "${MANIFEST#$REPO/} lists no packages"

    local pkg dir
    for pkg in "${packages[@]}"; do
        if [[ -d "$HOST_DIR/$pkg" ]]; then
            dir="$HOST_DIR"
        elif [[ -d "$REPO/$pkg" ]]; then
            dir="$REPO"
        else
            die "package '$pkg' exists neither in hosts/$HOST/ nor at the repo root"
        fi

        local verb=linking origin=''
        [[ $action == --delete ]] && verb=unlinking
        [[ $dir != "$REPO" ]] && origin=" (from ${dir#$REPO/})"
        printf '%s %s%s\n' "$verb" "$pkg" "$origin"

        stow "$action" "${STOW_FLAGS[@]}" --dir="$dir" "$pkg"
    done
}

main "$@"
