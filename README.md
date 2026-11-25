# oneai

Author: onexbash
Repo: https://github.com/onexbash/oneai

One command sets up a project for Claude Code inside TUIOS:
verification hooks, a permission allowlist, team memory, slash commands, subagents, a
`STATE.md` board and a TUIOS session with five workspaces. Each task runs as one normal
Claude Code session in its own git worktree. Parallel work means parallel tasks: there are
no agent teams and no lead/worker orchestration.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/onexbash/oneai/main/install.sh | bash
```

This installs `/usr/local/bin/oneai` and its templates in `/usr/local/share/oneai`, using sudo
if needed. Required tools: `git tuios claude jq`. Recommended: `lazygit nvim glow just shellcheck`.
`oneai deps` lists what is missing. Uninstall with `oneai --uninstall`.

## Set up a project

```bash
oneai ~/dev/repos/my-project
```

The command is idempotent and asks before every change (`--dry-run` shows the plan first):

1. **Dependencies:** lists what is missing.
2. **TUIOS integration:** installs the Claude Code hooks and the status line if they are
   missing, after backing up your `settings.json`. They send plan approvals, questions and
   finished turns to the TUIOS Inbox, and show context use on the rail.
3. **Project files:** creates the files below. A file that already exists and differs is shown
   as a diff, and you choose. Then it offers to commit them, because worktrees only get
   committed files.
4. **TUIOS session:** creates it, or attaches to it if it exists.

| File | Purpose |
|---|---|
| `CLAUDE.md` | Team memory, under 100 lines, with a `## Lessons` section (`/lesson`) |
| `.claude/rules/workflow.md` | Detail rules that don't belong in CLAUDE.md |
| `.claude/settings.json` | Opus, plan mode by default, allowlist for routine commands, hooks |
| `.claude/hooks/checks.sh` | The project's checks, detected per stack (Node/TS, Go, shell). Edit them here |
| `.claude/hooks/stop-check.sh` | Stop hook: fast checks after each turn, shows only failures |
| `.claude/hooks/format.sh` | PostToolUse hook: formats each edited file |
| `.claude/hooks/on-plan.sh` | After plan approval: saves `.claude/plan.md`, sets the task status |
| `.claude/hooks/notify.sh` | Optional "needs input" push (off unless `ONEAI_NOTIFY_URL` is set) |
| `.claude/commands/` | `/finish`, `/lesson`, `/docs` |
| `.claude/agents/` | `explorer` (code search) and `log-reader` (long output), read-only, Sonnet |
| `justfile` | `just verify`, `just fast` |
| `.mcp.json` | Playwright MCP, frontend projects only |
| `STATE.md` | The board, main checkout only (gitignored) |

Personal settings go in `.claude/settings.local.json` (gitignored). `oneai task start` copies it
into each new worktree.

## The session

| Workspace | Content |
|---|---|
| 1 Coding | lazygit (top left), shell (bottom left), nvim (right, 70%) |
| 2 Main | Claude Code on the main checkout, for questions and small changes |
| 3 Logstream | Two shells, 50/50, for container logs (`podman compose logs -f`) |
| 4 Board | `STATE.md` rendered live with glow, next to agents, tasks and Inbox counts |
| 5 Tasks | A shell for `oneai task start`; task sessions open next to it |

## Daily use

```bash
oneai task start login-limit "Add rate limiting to POST /login, 5/min per IP"
```

1. `task start` creates `../<repo>.worktrees/login-limit` on branch `task/login-limit` and
   adds a STATE.md entry. It opens Claude Code there in plan mode (Opus) on workspace 5,
   plus a small minimized gate pane. At most 4 tasks run at once.
2. Approve the plan in the **TUIOS Inbox**. Choose the auto-accept-edits option to let it run.
3. The agent implements. Fast checks run after every turn, and the agent sees only failures.
4. The agent ends with `/finish`: full verify, commit, then `oneai task ready`.
5. The Inbox asks you **merge / review / send back / later**:
   - **review** opens `tuios review` for the task. Leave your notes there.
   - **send back** delivers all your notes to the agent as one batch.
   - **merge** merges into the base branch, removes the worktree and branch, archives the
     STATE.md entry, logs the metrics, and offers a docs task. The docs task runs on Sonnet
     and works from the merged diff. It goes through the same gate.

To check progress without asking the agent, use `tuios agent-log -w login-limit --recap`.
At 80% context or more (shown on the rail), run `/compact`, or start fresh from
`.claude/plan.md` and STATE.md.

Other commands:

```bash
oneai task ls                 # tasks and their status
oneai task finish NAME        # merge from the terminal instead of the Inbox
oneai verify --all            # full checks in every task worktree
oneai metrics summary         # averages per stage: time, tokens, interventions, first-try verify
```

## Worktree trust

Claude Code ignores a project's allowlist in folders you haven't trusted, and it stores trust
per path. Every new worktree therefore starts untrusted. `oneai task start --trust` (or
`ONEAI_TRUST=1`) marks the worktree as trusted in `.claude.json` and backs the file up first.
It's opt-in: use it only for repositories you trust.

## Metrics

Tasks run with `oneai task` are logged automatically at merge, to `.claude/metrics.csv` in the
main checkout (gitignored). The log reads tokens, model, time and your typed messages from the
Claude Code transcripts. Rework rounds and the first verify result come from the gate.
To log a task done in a plain session, run `oneai metrics log --stage plain NAME`.

## Later: Lead mode

Not built. It can be added as an opt-in `oneai lead` for large features that split cleanly:
one plan that creates several `oneai task start` entries, each with its own gate. Nothing in
the per-task flow needs to change for that.
