#!/usr/bin/env bash
# PostToolUse hook (ExitPlanMode): runs once the plan is approved. Saves the plan
# to .claude/plan.md (not committed) so a fresh session can resume from it, and
# marks the task "implementing" in STATE.md through oneai. Token-free, exit 0.
input="$(cat)"
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
plan="$(printf '%s' "$input" | jq -r '.tool_input.plan // empty' 2>/dev/null)"
[ -n "$plan" ] && printf '%s\n' "$plan" >"$root/.claude/plan.md"
branch="$(git branch --show-current 2>/dev/null)"
case "$branch" in
  task/* | docs/*) command -v oneai >/dev/null && oneai state set "${branch#*/}" "implementing (plan approved)" >/dev/null 2>&1 ;;
esac
exit 0
