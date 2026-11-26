# oneai

One main Claude Code session ("Jarvis") that does the real work, plus at most one
side agent for small independent tasks in its own Worktrunk worktree. TUIOS holds
the panes. `oneai` sets this up for a repository and gets out of the way.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/onexbash/oneai/main/install.sh | bash
```

From a local checkout instead: `ONEAI_SRC=~/dev/repos/onexbash/oneai bash install.sh`.

It installs to `/usr/local/bin` and `/usr/local/share/oneai`. Those belong to root on macOS, so
only the copy steps run with `sudo` (password prompt). Run the installer itself as your user, not
with `sudo`. Without root: `ONEAI_PREFIX=$HOME/.local`.

`install.sh` ends with `oneai global`, which keeps the global layer in `$CLAUDE_CONFIG_DIR`
current: the four helper agents and a marked workflow block in your `CLAUDE.md` (nothing else
there is touched). It shows every change as a diff, asks once, keeps `*.oneai-bak` backups and writes
through symlinks. Run `oneai global` again after pulling a new oneai version.

Needs `git claude tuios wt jq just`; recommends `lazygit nvim glow shellcheck shfmt`.
`oneai` checks the TUIOS Claude Code integration and the Worktrunk Claude Code plugin.
`oneai --uninstall REPO` removes what it created (edited files go to `*.oneai-bak`).

## Which file lives where

| Layer | Location | Files |
|---|---|---|
| Global | `$CLAUDE_CONFIG_DIR` (default `~/.claude`) | `agents/{explorer,output-reader,test-writer,doc-writer}.md`; in your own `CLAUDE.md` only the `oneai:begin/end workflow` block. Source: `share/oneai/global/` |
| Project | `<repo>/` | `CLAUDE.md` (verify command, test and docs paths, lessons), `justfile`, `.claude/settings.json` (narrow allow rules, format + Stop hooks), `.claude/hooks/*.sh`, `.config/wt.toml` or `$WORKTRUNK_PROJECT_CONFIG_PATH` (Worktrunk hooks), `.worktreeinclude` |
| Worktrunk user config | `$WORKTRUNK_CONFIG_PATH` (default `~/.config/worktrunk/config.toml`) | `worktree-path = "{{ repo_path }}/.worktrees/{{ branch \| sanitize }}"`: side agents' worktrees live inside the repo (`/.worktrees/` is gitignored), so Jarvis can read and review them without extra permissions |
| Project, not committed | main checkout | `STATE.md`, `STATE-archive.md`, `.claude/metrics.csv`, `.claude/settings.local.json` |

Helpers read the test and docs paths from the `## Paths` section of the project's CLAUDE.md.

## TUIOS session

1. **Coding**: lazygit / shell | nvim
2. **Jarvis**: Claude Code (70%) | STATE.md live / `wt list` live
3. **Logstream**: two shells
4. **Side agents**: panes from `oneai side`; questions reach you through the TUIOS Inbox

## Daily use

**A task with Jarvis** (workspace 2, main checkout, feature branch):
1. `/clear`, then describe the task. Non-trivial: plan mode, Jarvis uses `explorer`; you approve.
   Hard tasks: `/model fable` + `/effort high` for planning, back to `/model opus` + `/effort medium` to implement.
2. `test-writer` writes tests from the acceptance criteria; Jarvis implements.
3. The Stop hook runs `just fast` after every turn; `just verify` before you review.
4. `doc-writer` updates docs. You review and approve the commit/merge.
5. `oneai metrics log --who jarvis --effort medium --rework N --verify y|n TASK`

**A side agent** (small, independent: no shared files, migrations or lockfile changes):
```bash
oneai side fix/typo 'Goal: … Files: … Acceptance: … Verify: just verify'
oneai side --model sonnet docs/rename '…'      # mechanical work
```
It creates the worktree in `<repo>/.worktrees/<branch>` (`wt switch -c -x claude`), copies `.env*` via `.worktreeinclude`,
and opens Claude Code on workspace 4. Track it with `wt list` and
`tuios agent-log -w side-<slug> --recap`. After your OK, from the worktree:
log metrics with `oneai metrics log --who side --dir <worktree> …`, then `wt -C <worktree> merge`
(the pre-merge hook runs `just verify`; the worktree is removed), then close its pane with
`tuios close-window side-<slug>` (`oneai side` prints the name). One side agent at a
time; raise `ONEAI_SIDE_MAX` only when metrics show long unattended runs that pass verify first try.

**Your own parallel coding**: `wt switch -c my-branch` in a shell, so you and Jarvis never share a checkout.

**Worktrees inside the repo**: git, ripgrep and Claude's search skip `/.worktrees/` because it is
gitignored, but some tools don't read `.gitignore`. If tests or type checks in the main checkout
also pick up files from `.worktrees/`, exclude it there (e.g. vitest `exclude`, tsconfig `exclude`).

**Metrics**: `oneai metrics summary` compares averages per `--who`. For the baseline, log tasks
done in a plain session: `oneai metrics sessions` lists recent session IDs, then
`oneai metrics log --who plain -s <id> --merged <commit> TASK`.

**Existing files**: a daily `oneai REPO` only opens the session. Files you edit (`CLAUDE.md`,
`STATE.md`, `justfile`, `.claude/settings.json`, `checks.sh`, the Worktrunk project config, `.worktreeinclude`) are
created once and then left alone; `format.sh`, `stop-check.sh` and `.mcp.json` follow the templates
(diff and question when they differ).

## Development

`just verify` runs shellcheck and `tests/oneai_test.sh` (tuios and wt are stubbed).
