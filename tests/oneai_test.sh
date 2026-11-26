#!/usr/bin/env bash
# Tests for bin/oneai. tuios and wt are replaced by stubs that log their calls,
# and CLAUDE_CONFIG_DIR points to a temp dir, so nothing real is touched.
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd -P)"
oneai="$here/bin/oneai"
t="$(cd "$(mktemp -d)" && pwd -P)" # physical path: git and Claude Code see it that way
trap 'rm -rf "$t"' EXIT
fails=0

check() { # DESCRIPTION COMMAND...
  if "${@:2}" >/dev/null 2>&1; then printf 'ok   %s\n' "$1"; else
    printf 'FAIL %s\n' "$1"
    fails=$((fails + 1))
  fi
}

# --- stubs ---
mkdir -p "$t/bin"
cat >"$t/bin/tuios" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$STUB_LOG"
case "$1 ${2:-}" in
  "integration status") echo "claude-code  installed, current (v3)" ;;
  "ls "*) echo '[]' ;;
  "list-windows "*) printf '{"windows":[%s]}\n' "${STUB_WINDOWS:-}" ;;
esac
EOF
cat >"$t/bin/wt" <<'EOF'
#!/usr/bin/env bash
printf 'wt %s\n' "$*" >>"$STUB_LOG"
EOF
chmod +x "$t/bin/"*
# The Worktrunk setup of your shell must not leak into the tests.
unset WORKTRUNK_CONFIG_PATH WORKTRUNK_SYSTEM_CONFIG_PATH WORKTRUNK_PROJECT_CONFIG_PATH WORKTRUNK_WORKTREE_PATH
export PATH="$t/bin:$PATH" STUB_LOG="$t/calls.log" CLAUDE_CONFIG_DIR="$t/cfg"
# Global files are symlinks into a dotfiles dir, with content of their own.
mkdir -p "$t/cfg" "$t/dot" "$t/xdg/worktrunk"
echo '{"enabledPlugins":{"worktrunk@worktrunk":true},"statusLine":{"command":"tuios x"},"permissions":{"additionalDirectories":["~/a"]}}' >"$t/dot/settings.json"
printf '# Global preferences\n\n- my rule\n' >"$t/dot/CLAUDE.md"
ln -s "$t/dot/settings.json" "$t/cfg/settings.json"
ln -s "$t/dot/CLAUDE.md" "$t/cfg/CLAUDE.md"
echo 'worktree-path = "~/dev/worktrees/{{ repo }}/{{ branch | sanitize }}"' >"$t/xdg/worktrunk/config.toml"
export XDG_CONFIG_HOME="$t/xdg"

# --- global layer only (what install.sh runs) ---
"$oneai" global --dry-run >/dev/null 2>&1
check "global dry-run writes nothing" test ! -e "$t/cfg/agents"
"$oneai" global --yes >/dev/null 2>&1
check "global: agents created" test -f "$t/cfg/agents/test-writer.md"
check "global: settings.json is still a symlink" test -L "$t/cfg/settings.json"
check "global: CLAUDE.md is still a symlink" test -L "$t/cfg/CLAUDE.md"
check "global: worktrees dir added, own entries kept" \
  jq -e '.permissions.additionalDirectories == ["~/a", "~/dev/worktrees"] and .statusLine.command == "tuios x"' "$t/dot/settings.json"
check "global: workflow block appended, own text kept" bash -c "grep -q '^- my rule' '$t/dot/CLAUDE.md' && grep -q '^## Workflow' '$t/dot/CLAUDE.md'"
gsum() { cksum "$t/dot/"* "$t/cfg/agents/"*; }
g1="$(gsum)"
"$oneai" global --yes >/dev/null 2>&1
check "global: second run changes nothing" test "$g1" = "$(gsum)"
gsed -i 's/^## Workflow$/## Workflow (old)/' "$t/dot/CLAUDE.md"
"$oneai" global --yes >/dev/null 2>&1
check "global: outdated block replaced in place, once" test "$(grep -c '^## Workflow' "$t/dot/CLAUDE.md")" = 1
check "global: replaced block is current" grep -qx '## Workflow' "$t/dot/CLAUDE.md"
# a hand-pasted copy without markers gets wrapped, not duplicated
{ printf '# Global preferences\n\n- my rule\n\n'; sed '1d;$d' "$here/share/oneai/global/CLAUDE.workflow.md"; printf '\n## Later section\n'; } >"$t/pasted.md"
CLAUDE_CONFIG_DIR="$t/p" bash -c "mkdir -p '$t/p' && cp '$t/pasted.md' '$t/p/CLAUDE.md' && '$oneai' global --yes" >/dev/null 2>&1
check "global: pasted copy wrapped, not duplicated" \
  bash -c "[ \$(grep -c '^## Workflow' '$t/p/CLAUDE.md') = 1 ] && grep -q oneai:begin '$t/p/CLAUDE.md' && grep -q '^## Later section' '$t/p/CLAUDE.md'"
# fresh config dir: CLAUDE.md is created with the block, not empty
CLAUDE_CONFIG_DIR="$t/fresh" "$oneai" global --yes >/dev/null 2>&1
check "global: fresh dir gets CLAUDE.md with the block" grep -q '^## Workflow' "$t/fresh/CLAUDE.md"
# begin marker without end marker: file stays as it is, in setup and uninstall
mkdir -p "$t/broken"
printf 'a\n<!-- oneai:begin workflow\nedited\nmy own later text\n' >"$t/broken/CLAUDE.md"
cp "$t/broken/CLAUDE.md" "$t/broken.orig"
CLAUDE_CONFIG_DIR="$t/broken" "$oneai" global --yes >/dev/null 2>&1
check "global: missing end marker leaves CLAUDE.md unchanged" cmp -s "$t/broken/CLAUDE.md" "$t/broken.orig"
git init -q "$t/ur" && CLAUDE_CONFIG_DIR="$t/broken" "$oneai" --uninstall --yes "$t/ur" >/dev/null 2>&1
check "uninstall: missing end marker leaves CLAUDE.md unchanged" cmp -s "$t/broken/CLAUDE.md" "$t/broken.orig"
# reworded marker comments still match (prefix), so no second block
gsed -i 's/^<!-- oneai:begin workflow.*/<!-- oneai:begin workflow (old wording) -->/; s/^<!-- oneai:end workflow.*/<!-- oneai:end workflow (old) -->/' "$t/dot/CLAUDE.md"
"$oneai" global --yes >/dev/null 2>&1
check "global: reworded markers replaced, not duplicated" test "$(grep -c '^## Workflow' "$t/dot/CLAUDE.md")" = 1
# "~/x" and "$HOME/x" are one entry
mkdir -p "$t/abs"
printf '{"permissions":{"additionalDirectories":["%s/dev/worktrees"]}}\n' "$HOME" >"$t/abs/settings.json"
CLAUDE_CONFIG_DIR="$t/abs" "$oneai" global --yes >/dev/null 2>&1
check "global: absolute spelling counts as present" jq -e '.permissions.additionalDirectories | length == 1' "$t/abs/settings.json"
# Worktrunk env vars: WORKTRUNK_WORKTREE_PATH beats WORKTRUNK_CONFIG_PATH beats the system config
printf '{}\n' >"$t/wtenv.json"
wtdir() { mkdir -p "$t/w" && cp "$t/wtenv.json" "$t/w/settings.json" && CLAUDE_CONFIG_DIR="$t/w" "$@" "$oneai" global --yes >/dev/null 2>&1; jq -r '.permissions.additionalDirectories[0]' "$t/w/settings.json"; }
echo 'worktree-path = "~/from-user/{{ repo }}"' >"$t/wt-user.toml"
echo 'worktree-path = "~/from-system/{{ repo }}"' >"$t/wt-system.toml"
# shellcheck disable=SC2088 # the literal "~/…" in settings.json is what is checked
{
check "worktree dir: WORKTRUNK_CONFIG_PATH is read" test "$(wtdir env WORKTRUNK_CONFIG_PATH="$t/wt-user.toml")" = "~/from-user"
check "worktree dir: system config when the user config has none" \
  test "$(wtdir env WORKTRUNK_CONFIG_PATH="$t/none.toml" WORKTRUNK_SYSTEM_CONFIG_PATH="$t/wt-system.toml")" = "~/from-system"
check "worktree dir: WORKTRUNK_WORKTREE_PATH wins" \
  test "$(wtdir env WORKTRUNK_WORKTREE_PATH='~/from-env/{{ branch }}' WORKTRUNK_CONFIG_PATH="$t/wt-user.toml")" = "~/from-env"
}
rm -rf "$t/cfg/agents"

repo="$t/myproj"
git init -q "$repo"
git -C "$repo" -c user.name=test -c user.email=test@example.invalid commit -q --allow-empty -m init

# --- dry run changes nothing ---
"$oneai" --dry-run --no-attach "$repo" >/dev/null 2>&1
check "dry-run creates no project files" test ! -e "$repo/CLAUDE.md"
check "dry-run creates no global files" test ! -e "$t/cfg/agents"

# --- setup ---
"$oneai" --yes --no-attach "$repo" >/dev/null 2>&1
for f in CLAUDE.md justfile STATE.md .claude/settings.json .claude/hooks/checks.sh .config/wt.toml .worktreeinclude; do
  check "creates $f" test -f "$repo/$f"
done
for a in explorer output-reader test-writer doc-writer; do
  check "creates global agent $a" test -f "$t/cfg/agents/$a.md"
done
check "CLAUDE.md names the project" grep -q '^# myproj' "$repo/CLAUDE.md"
check "hooks are executable" test -x "$repo/.claude/hooks/stop-check.sh"
check ".gitignore has STATE.md" grep -qxF /STATE.md "$repo/.gitignore"
check "no defaultMode in project settings" bash -c "! jq -e '.permissions.defaultMode' '$repo/.claude/settings.json'"
check "Jarvis starts on workspace 2" grep -q 'start-agent claude .*--workspace 2 .*--name jarvis' "$t/calls.log"
check "workspace 4 is named" grep -q 'set-workspace-name 4 Side agents' "$t/calls.log"
check "first setup approves the wt hooks" grep -q 'wt -C .* config approvals add' "$t/calls.log"

# --- idempotent ---
sum() { find "$repo" "$t/cfg/agents" -type f -not -path '*/.git/*' -exec cksum {} + | sort; }
before="$(sum)"
out="$("$oneai" --yes --no-attach "$repo" 2>&1)"
check "second run changes nothing" test "$before" = "$(sum)"
check "second run creates nothing" bash -c "! grep -q created <<<'$out'"

# --- edited files: seed files are left alone, synced files replaced only with a backup ---
echo "- my lesson" >>"$repo/CLAUDE.md"
echo "# my change" >>"$repo/.claude/hooks/format.sh"
: >"$STUB_LOG"
"$oneai" --yes --no-attach "$repo" >/dev/null 2>&1
check "edited CLAUDE.md is kept as it is" bash -c "grep -q 'my lesson' '$repo/CLAUDE.md' && test ! -e '$repo/CLAUDE.md.oneai-bak'"
check "edited format.sh is backed up before replace" grep -q 'my change' "$repo/.claude/hooks/format.sh.oneai-bak"
check "wt approvals are not asked again" bash -c "! grep -q 'config approvals' '$STUB_LOG'"

# --- WORKTRUNK_PROJECT_CONFIG_PATH: project hooks go where wt reads them ---
repo2="$t/proj2"
git init -q "$repo2"
WORKTRUNK_PROJECT_CONFIG_PATH=worktrunk.toml "$oneai" --yes --no-attach "$repo2" >/dev/null 2>&1
check "project config follows WORKTRUNK_PROJECT_CONFIG_PATH" bash -c "test -f '$repo2/worktrunk.toml' && test ! -e '$repo2/.config/wt.toml'"
WORKTRUNK_PROJECT_CONFIG_PATH=/abs/wt.toml "$oneai" --yes --no-attach "$repo2" >/dev/null 2>&1
check "absolute project config path is left alone" test ! -e /abs/wt.toml

# --- side agents ---
: >"$STUB_LOG"
(cd "$repo" && "$oneai" side --model sonnet fix/typo 'Fix the typo') >/dev/null 2>&1
check "side agent opens on workspace 4 via wt" \
  grep -q 'new-window side-fix-typo --workspace 4 .* wt switch --create fix/typo -x claude -- --model sonnet -n side-fix-typo Fix the typo' "$STUB_LOG"
check "side agent limit is enforced" bash -c "cd '$repo' && ! STUB_WINDOWS='{\"name\":\"side-x\"}' '$oneai' side b p"

# --- metrics ---
proj="$t/cfg/projects/$(printf '%s' "$repo" | sed 's/[^A-Za-z0-9]/-/g')"
mkdir -p "$proj"
cat >"$proj/s1.jsonl" <<'EOF'
{"type":"user","uuid":"u1","origin":{"kind":"human"},"timestamp":"2026-11-26T10:00:00.000Z","message":{"content":"do it"}}
{"type":"assistant","uuid":"a1","message":{"id":"m1","model":"claude-opus-5-5","usage":{"input_tokens":10,"output_tokens":5,"cache_read_input_tokens":100,"cache_creation_input_tokens":20}}}
EOF
row="$(cd "$repo" && "$oneai" metrics log --who side --effort medium --verify y --rework 0 --merged now t1 2>/dev/null)"
check "metrics row has who, model, effort, tokens" grep -q '^t1,.*,side,claude-opus-5-5,medium,.*,10,5,100,20,' <<<"$row"
check "metrics summary groups by who" bash -c "cd '$repo' && '$oneai' metrics summary | grep -q '^side: 1 tasks'"

# --- uninstall ---
printf 'my own\n' >"$repo/justfile" # no marker: not ours anymore
"$oneai" --uninstall --yes "$repo" >/dev/null 2>&1
check "uninstall removes unchanged files" test ! -e "$repo/.config/wt.toml"
check "uninstall removes global agents" test ! -e "$t/cfg/agents/explorer.md"
check "uninstall keeps files without marker" grep -qx 'my own' "$repo/justfile"
check "uninstall keeps metrics" test -s "$repo/.claude/metrics.csv"
check "uninstall removes the workflow block, keeps own text" \
  bash -c "! grep -q oneai:begin '$t/dot/CLAUDE.md' && grep -q '^- my rule' '$t/dot/CLAUDE.md'"
check "uninstall keeps settings.json a symlink" test -L "$t/cfg/settings.json"

if command -v shellcheck >/dev/null; then check "bin/oneai passes shellcheck" shellcheck "$oneai"; fi

[ "$fails" -eq 0 ] || {
  printf '%s test(s) failed\n' "$fails"
  exit 1
}
