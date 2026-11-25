#!/usr/bin/env bash
# Install oneai:  curl -fsSL https://raw.githubusercontent.com/onexbash/oneai/main/install.sh | bash
# Environment:
#   ONEAI_REF=main            branch or tag to install
#   ONEAI_REPO=onexbash/oneai GitHub repository
#   ONEAI_PREFIX=/usr/local   installs bin/oneai and share/oneai below it
#   ONEAI_SRC=/path/checkout  install from a local checkout instead of GitHub
set -eu

REPO="${ONEAI_REPO:-onexbash/oneai}"
REF="${ONEAI_REF:-main}"
PREFIX="${ONEAI_PREFIX:-/usr/local}"
SRC="${ONEAI_SRC:-}"

say() { printf '==> %s\n' "$*"; }
die() { printf 'install.sh: %s\n' "$*" >&2; exit 1; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if [ -z "$SRC" ]; then
  command -v curl >/dev/null || die "curl is required"
  say "downloading $REPO@$REF"
  curl -fsSL "https://codeload.github.com/$REPO/tar.gz/$REF" | tar -xz -C "$tmp" ||
    die "download failed (is $REPO public and does '$REF' exist?)"
  SRC="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
fi
[ -f "$SRC/bin/oneai" ] && [ -d "$SRC/share/oneai/templates" ] || die "no oneai sources in $SRC"

sudo=""
mkdir -p "$PREFIX/bin" "$PREFIX/share" 2>/dev/null || true
if [ ! -w "$PREFIX/bin" ] || [ ! -w "$PREFIX/share" ]; then
  command -v sudo >/dev/null || die "$PREFIX is not writable and sudo is missing"
  say "$PREFIX is not writable; using sudo"
  sudo="sudo"
fi
as() { if [ -n "$sudo" ]; then sudo "$@"; else "$@"; fi; }

as mkdir -p "$PREFIX/bin" "$PREFIX/share"
as rm -rf "$PREFIX/share/oneai.new"
as cp -R "$SRC/share/oneai" "$PREFIX/share/oneai.new"
as rm -rf "$PREFIX/share/oneai"
as mv "$PREFIX/share/oneai.new" "$PREFIX/share/oneai"
as install -m 0755 "$SRC/bin/oneai" "$PREFIX/bin/oneai"

say "installed $("$PREFIX/bin/oneai" --version) to $PREFIX/bin/oneai"
"$PREFIX/bin/oneai" deps || true
say "next: oneai <path-to-project>"
