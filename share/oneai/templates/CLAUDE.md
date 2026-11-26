# {{PROJECT}}

<!-- oneai-managed. Project specifics only; general rules live in the global CLAUDE.md. Keep under 100 lines. -->
<!-- One or two lines: what this project is and who uses it. -->

## Commands
- Full verify (format check, lint, typecheck, all tests): `just verify`. Must pass before review and merge.
- Fast checks (`just fast`) run by themselves after each turn (Stop hook); you only see failures. A formatter runs on every edited file.
- Checks per stack live in `.claude/hooks/checks.sh`. Change them there.

## Paths
- Tests: `tests/` (run with `just verify`)
- Docs: `README.md`, `docs/`

## Project notes
<!-- Stack, architecture in 3–5 lines, gotchas. -->

## Lessons
<!-- One imperative line each. Merge duplicates, drop outdated ones. -->
