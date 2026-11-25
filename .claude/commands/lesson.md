---
description: Turn a correction into a one-line lesson in CLAUDE.md
argument-hint: <the rule, in your words>
allowed-tools: Read, Edit
---
## Current lessons
!`sed -n '/^## Lessons/,$p' CLAUDE.md 2>/dev/null || true`

## Task
Record this lesson: $ARGUMENTS

- One imperative line, at most 120 characters, general (no task-specific details), under `## Lessons` in CLAUDE.md.
- If it overlaps an existing lesson, merge the two. Remove lessons it makes outdated or contradicts.
- A long or path-specific rule goes to `.claude/rules/<topic>.md` instead (with `paths:` frontmatter when path-specific).
- CLAUDE.md must stay under 100 lines.
- Reply with the changed lines only.
