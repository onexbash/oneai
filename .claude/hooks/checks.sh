#!/usr/bin/env bash
# oneai-managed: `oneai --uninstall` asks before removing it once edited.
# Project checks, detected per stack. Edit the commands below to fit the project.
#   checks.sh fast   changed files only: lint, typecheck, affected tests (Stop hook)
#   checks.sh full   format check, lint, typecheck, all tests (before every merge)
# Prints one line per step; a failing step adds the tail of its output.
# Exit 0 = all passed, 1 = something failed.
set -u
mode="${1:-full}"
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root" || exit 1

logdir="${TMPDIR:-/tmp}/checks-$(printf '%s' "$root" | cksum | cut -d' ' -f1)"
mkdir -p "$logdir"
failed=0
ran=0

step() { # label command...
  label="$1"; shift
  ran=1
  log="$logdir/$(printf '%s' "$label" | tr -c 'A-Za-z0-9' '_').log"
  if "$@" >"$log" 2>&1; then
    printf 'ok   %s\n' "$label"
  else
    failed=1
    printf 'FAIL %s  (full log: %s)\n' "$label" "$log"
    tail -n 40 "$log" | sed 's/^/     /'
  fi
}

# Files changed against HEAD, plus untracked ones, that still exist.
changed() {
  { git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } |
    sort -u | while IFS= read -r f; do if [ -f "$f" ]; then printf '%s\n' "$f"; fi; done
}
changed_matching() { changed | grep -E "$1" || true; }

# ---------- Node / TypeScript ----------
if [ -f package.json ]; then
  if [ -f pnpm-lock.yaml ]; then pm=pnpm
  elif [ -f yarn.lock ]; then pm=yarn
  elif [ -f bun.lock ]; then pm=bun
  elif [ -f package-lock.json ]; then pm=npm
  else pm=pnpm; fi
  has_script() { jq -e --arg s "$1" '.scripts[$s] != null' package.json >/dev/null 2>&1; }
  bin() { [ -x "node_modules/.bin/$1" ]; }
  typecheck=""
  if has_script check; then typecheck=check; elif has_script typecheck; then typecheck=typecheck; fi

  if [ "$mode" = full ]; then
    if has_script format:check; then step format "$pm" run format:check
    elif bin prettier; then step format node_modules/.bin/prettier --check . --log-level warn; fi
    if has_script lint; then step lint "$pm" run lint; fi
    if [ -n "$typecheck" ]; then step typecheck "$pm" run "$typecheck"; fi
    if has_script test; then step test env CI=1 "$pm" run test; fi
  else
    files="$(changed_matching '\.(js|jsx|ts|tsx|mjs|cjs|svelte|vue)$')"
    if [ -n "$files" ]; then
      # shellcheck disable=SC2086 # file list split on purpose (paths without spaces)
      if bin eslint; then step lint node_modules/.bin/eslint $files
      elif has_script lint; then step lint "$pm" run lint; fi
      if [ -n "$typecheck" ]; then step typecheck "$pm" run "$typecheck"; fi
      # shellcheck disable=SC2086
      if bin vitest; then step tests-affected node_modules/.bin/vitest related --run --passWithNoTests $files; fi
    fi
  fi
fi

# ---------- Go ----------
if [ -f go.mod ]; then
  # shellcheck disable=SC2329 # called through step
  gofmt_clean() { out="$(gofmt -l "$@")"; [ -z "$out" ] || { printf 'not gofmt-ed:\n%s\n' "$out"; return 1; }; }
  if [ "$mode" = full ]; then
    step gofmt gofmt_clean .
    step vet go vet ./...
    if command -v golangci-lint >/dev/null; then step golangci-lint golangci-lint run; fi
    step test go test ./...
  else
    files="$(changed_matching '\.go$')"
    if [ -n "$files" ]; then
      # shellcheck disable=SC2086
      step gofmt gofmt_clean $files
      step vet go vet ./...
      pkgs="$(printf '%s\n' "$files" | xargs -n1 dirname | sort -u | sed 's|^|./|')"
      # shellcheck disable=SC2086
      step tests-affected go test $pkgs
    fi
  fi
fi

# ---------- Shell ----------
if command -v shellcheck >/dev/null; then
  if [ "$mode" = full ]; then
    files="$(git ls-files '*.sh' 2>/dev/null)"
  else
    files="$(changed_matching '\.sh$')"
  fi
  # shellcheck disable=SC2086
  if [ -n "$files" ]; then step shellcheck shellcheck $files; fi
fi

# ---------- Shell tests (tests/*_test.sh) ----------
if [ "$mode" = full ]; then
  for t in tests/*_test.sh; do
    if [ -f "$t" ]; then step "test $(basename "$t")" bash "$t"; fi
  done
fi

if [ "$ran" -eq 0 ]; then printf 'no checks for this stack yet: edit .claude/hooks/checks.sh\n'; fi
exit "$failed"
