# Workflow details

## Task lifecycle (oneai)
1. A task runs in its own git worktree on branch `task/<name>`, one Claude Code session per task.
2. Plan mode first. The approved plan is saved to `.claude/plan.md` by a hook (not committed).
3. Implement. The Stop hook runs fast checks (lint, typecheck, affected tests) and shows only failures.
4. `/finish`: `oneai verify` (full), commit, `oneai task ready`. The merge question then waits in the TUIOS Inbox.
5. Review notes come back as one batch. Fix them all, then `/finish` again.
6. After the merge, docs are updated in a separate Sonnet task from the merged diff, not during implementation.

## Context hygiene
- At about 80% context: `/compact`, or start a fresh session from `.claude/plan.md` and `STATE.md` in the main checkout.
- Don't read whole large files when a search or a subagent summary answers the question.
- Don't paste long command output into the conversation; let `log-reader` summarise it.

## Commits
- Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).
- One logical change per commit. Never commit secrets or `.env` files.

## Memory
- CLAUDE.md stays under 100 lines. Details go here or into another `.claude/rules/<topic>.md`.
- Path-specific rules: add `paths:` frontmatter so they load only for matching files.
