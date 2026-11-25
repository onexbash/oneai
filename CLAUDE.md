# oneai

<!-- One or two lines: what this project is and who uses it. -->

## Commands
- Verify before every merge: `oneai verify` (also `just verify`). Runs format check, lint, typecheck, all tests.
- Fast checks run by themselves after each turn (Stop hook); you only see failures. A formatter runs on every edited file.
- Checks per stack live in `.claude/hooks/checks.sh`. Change them there, not in hooks.

## How we work
- Non-trivial work starts in plan mode. Plan = goal, files to touch, steps, how you will verify. Keep it short.
- After the plan is approved: implement in small, reviewable steps; follow existing conventions; no unrelated refactors.
- Done means `oneai verify` passes. Report failures exactly as they happened; never claim untested success.
- Finish a task with `/finish`. Never merge, never push, never edit STATE.md (`oneai state` owns it).
- Reading, not implementing, goes to subagents: `explorer` for code search across many files,
  `log-reader` for long test, build or log output. Keep big outputs out of the main context.
- Model: Opus by default. Sonnet only for mechanical work (docs, renames, tests that follow an existing pattern).
- When the same instruction or step comes up a second time, propose a slash command or a rule for it.
- When I correct you, run `/lesson <the rule>` so the lesson lands below.

More detail: `.claude/rules/workflow.md`.

## Project notes
<!-- Stack, architecture in 3–5 lines, gotchas. Long topics go to .claude/rules/<topic>.md. -->

## Lessons
<!-- One imperative line each, maintained with /lesson. Merge duplicates, drop outdated ones. -->
