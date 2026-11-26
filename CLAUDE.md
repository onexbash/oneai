# oneai

<!-- oneai-managed. Project specifics only; general rules live in the global CLAUDE.md. Keep under 100 lines. -->
Setup script for the Jarvis + side agents workflow (Claude Code, TUIOS, Worktrunk). Bash only.

## Commands
- Full verify (shellcheck, tests): `just verify`. Must pass before review and merge.
- Fast checks (`just fast`) run by themselves after each turn (Stop hook); you only see failures. A formatter runs on every edited file.
- Checks per stack live in `.claude/hooks/checks.sh`. Change them there.

## Paths
- Tests: `tests/` (plain Bash, run with `bash tests/oneai_test.sh` or `just verify`)
- Docs: `README.md`

## Project notes
- `bin/oneai` is the whole tool. `share/oneai/templates/` = project layer it installs, `share/oneai/global/` = global layer (`$CLAUDE_CONFIG_DIR`).
- This repo uses its own templates: keep `.claude/`, `CLAUDE.md`'s structure, `.config/wt.toml` in sync with `share/oneai/templates/`.
- Scripts target Bash 5.3 and GNU tools; must pass shellcheck.

## Lessons
