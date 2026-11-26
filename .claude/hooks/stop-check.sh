#!/usr/bin/env bash
# oneai-managed: `oneai --uninstall` asks before removing it once edited.
# Stop hook: fast checks after each turn. Silent when they pass or nothing
# changed since the last pass; on failure Claude sees only the failing steps
# (exit 2). After 3 failed rounds in a row it lets the turn end, so it can't loop.
set -u
input="$(cat)"
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
root="$(git rev-parse --show-toplevel)"
cd "$root" || exit 0
statedir="$(git rev-parse --git-dir)/oneai-stop"
mkdir -p "$statedir"

# Fingerprint of the working tree: tracked diff plus untracked file contents.
fp="$({ git diff HEAD 2>/dev/null; git ls-files --others --exclude-standard -z 2>/dev/null | xargs -0 cat 2>/dev/null; } | cksum)"
[ "$fp" = "$(cat "$statedir/pass" 2>/dev/null)" ] && exit 0

active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)"
rounds="$(cat "$statedir/rounds" 2>/dev/null || echo 0)"
[ "$active" = true ] || rounds=0

if out="$(bash .claude/hooks/checks.sh fast 2>&1)"; then
  printf '%s' "$fp" >"$statedir/pass"
  echo 0 >"$statedir/rounds"
  exit 0
fi

rounds=$((rounds + 1))
echo "$rounds" >"$statedir/rounds"
[ "$rounds" -gt 3 ] && exit 0
{
  printf 'Fast checks failed (round %s of 3). Fix these, then stop again:\n' "$rounds"
  printf '%s\n' "$out" | grep -v '^ok ' | head -n 80
} >&2
exit 2
