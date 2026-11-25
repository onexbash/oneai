---
description: Update docs from a merged diff (runs after the merge, on Sonnet)
argument-hint: <git range of the merge, e.g. abc123..def456>
model: sonnet
allowed-tools: Read, Edit, Write, Glob, Grep, Bash(git diff *), Bash(git log *), Bash(git add *), Bash(git commit *), Bash(oneai verify), Bash(oneai task ready)
---
## Merged change (pre-computed)
!`git log --oneline $ARGUMENTS 2>/dev/null | head -20; git diff --stat $ARGUMENTS 2>/dev/null | tail -30`

## Task
Update the documentation that this merged change made wrong or incomplete: README, docs/, CLAUDE.md "Project notes", code comments that describe behaviour.
- Read `git diff $ARGUMENTS` for what changed. Do not change code.
- Keep edits minimal and factual. If nothing needs updating, say so and stop.
- Commit with `docs: ...`, then run `oneai task ready`.
