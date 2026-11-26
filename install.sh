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

# -- TTY STYLES -- #
# shellcheck disable=SC2034 # shared style block: not every script uses every style
tty_styles() {
  # Colors only when stdout and stderr are terminals and NO_COLOR is not set
  if [[ -t 1 && -t 2 && -z ${NO_COLOR-} ]]; then
    C_RED=$'\033[1;31m' C_GREEN=$'\033[1;32m' C_YELLOW=$'\033[1;33m'
    C_BLUE=$'\033[1;34m' C_PURPLE=$'\033[1;35m' C_CYAN=$'\033[1;36m'
    C_WHITE=$'\033[1;37m' C_GRAY=$'\033[0;90m' C_RESET=$'\033[0m'
  else
    C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_PURPLE="" C_CYAN="" C_WHITE="" C_GRAY="" C_RESET=""
  fi
  # Styled Output Variables
  I_MSG="${C_PURPLE}" # Output Variable without Prefix for Standard Messages
  I_SKIP="${C_GRAY}[${C_CYAN} SKIP ${C_GRAY}]${C_RESET} "
  I_WARN="${C_GRAY}[${C_YELLOW} WARN ${C_GRAY}]${C_RESET} "
  I_OK="${C_GRAY}[${C_GREEN} OK ${C_GRAY}]${C_RESET} "
  I_INFO="${C_GRAY}[${C_PURPLE} INFO ${C_GRAY}]${C_RESET} "
  I_ERR="${C_GRAY}[${C_RED} ERROR ${C_GRAY}]${C_RESET} "
  # Styled Input Variables
  I_INPUT="${C_GRAY}[${C_BLUE}  ${C_GRAY}]${C_RESET} "
  I_ASK="${C_GRAY}[${C_BLUE} ? ${C_GRAY}]${C_RESET} "
  I_YN="${C_GRAY}[${C_BLUE} y/n ${C_GRAY}]${C_RESET} "
}

# Shared Log Wrapper for Log Functions below
_log() {
  local style=$1
  shift
  printf '%s%s%s\n' "$style" "$*" "$C_RESET"
}

# Log Functions (Output)
log_() { _log "$I_MSG" "$@"; }
log_ok() { _log "$I_OK" "$@"; }
log_info() { _log "$I_INFO" "$@"; }
log_skip() { _log "$I_SKIP" "$@"; }
log_warn() { _log "$I_WARN" "$@" >&2; }
log_err() { _log "$I_ERR" "$@" >&2; }
tty_styles

die() {
  log_err "$@"
  exit 1
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if [ -z "$SRC" ]; then
  command -v curl >/dev/null || die "curl is required"
  log_info "downloading $REPO@$REF"
  curl -fsSL "https://codeload.github.com/$REPO/tar.gz/$REF" | tar -xz -C "$tmp" ||
    die "download failed (is $REPO public and does '$REF' exist?)"
  SRC="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
fi
[ -f "$SRC/bin/oneai" ] && [ -d "$SRC/share/oneai/templates" ] || die "no oneai sources in $SRC"

mkdir -p "$PREFIX/bin" "$PREFIX/share" 2>/dev/null || true
[ -w "$PREFIX/bin" ] && [ -w "$PREFIX/share" ] ||
  die "$PREFIX is not writable (no sudo by design): fix its ownership or use ONEAI_PREFIX=\$HOME/.local"

rm -rf "$PREFIX/share/oneai.new"
cp -R "$SRC/share/oneai" "$PREFIX/share/oneai.new"
rm -rf "$PREFIX/share/oneai"
mv "$PREFIX/share/oneai.new" "$PREFIX/share/oneai"
install -m 0755 "$SRC/bin/oneai" "$PREFIX/bin/oneai"

log_ok "installed $("$PREFIX/bin/oneai" --version) to $PREFIX/bin/oneai"
log_info "global layer: helper agents, CLAUDE.md workflow block, worktrees dir in settings.json"
if command -v jq >/dev/null; then
  "$PREFIX/bin/oneai" global || log_warn "global layer not updated; run 'oneai global' later"
else
  log_warn "jq is missing: install it, then run 'oneai global'"
fi
log_info "next: oneai <path-to-repo>"
