#!/usr/bin/env bash
# Notification hook: optional push for "needs input". Off unless ONEAI_NOTIFY_URL
# is set (e.g. an ntfy topic URL, in .claude/settings.local.json "env").
# Sends only the pane name, never the message or any project content.
cat >/dev/null
[ -n "${ONEAI_NOTIFY_URL:-}" ] || exit 0
pane="${ONEAI_PANE:-$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")}"
curl -fsS -m 5 --data-binary "needs input: $pane" "$ONEAI_NOTIFY_URL" >/dev/null 2>&1
exit 0
