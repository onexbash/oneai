---
description: Finish this task - full verify, commit, hand over for merge review
allowed-tools: Bash(oneai verify), Bash(oneai task ready), Bash(git add *), Bash(git commit *), Bash(git status *), Bash(git diff *)
---
## Context (pre-computed)
!`oneai task context 2>/dev/null || { git branch --show-current; git status --short; }`

## Steps
1. Run `oneai verify`. Fix every failure and run it again. After 3 failing rounds, stop and report what still fails.
2. Commit all changes on this branch with Conventional Commit messages: one commit per logical change.
3. Run `oneai task ready`. It re-checks, marks the task ready in STATE.md and puts the merge question in the TUIOS Inbox.
4. Reply in 5 lines or fewer: what changed, the verify result, and what the reviewer should look at.

Never merge, push or edit STATE.md yourself.
