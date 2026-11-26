#!/usr/bin/env bash
# oneai-managed: `oneai --uninstall` asks before removing it once edited.
# PostToolUse hook (Edit|Write|MultiEdit): format the edited file. Always silent, always exit 0.
f="$(jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[ -n "$f" ] && [ -f "$f" ] || exit 0
root="$(git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null || dirname "$f")"
case "$f" in
  *.go) command -v gofmt >/dev/null && gofmt -w "$f" ;;
  *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.svelte|*.vue|*.json|*.css|*.scss|*.html|*.md|*.yaml|*.yml)
    [ -x "$root/node_modules/.bin/prettier" ] && (cd "$root" && node_modules/.bin/prettier --write --log-level silent "$f") ;;
  *.sh) command -v shfmt >/dev/null && shfmt -w -i 2 "$f" ;;
  *.py) command -v ruff >/dev/null && ruff format -q "$f" ;;
  *.tf|*.tofu) command -v tofu >/dev/null && tofu fmt "$f" ;;
esac >/dev/null 2>&1
exit 0
