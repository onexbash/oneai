<!-- oneai:begin workflow (managed by oneai; edit in the oneai repo, `oneai --uninstall` removes this block) -->
## Workflow
- Non-trivial work: plan mode first (goal, acceptance criteria, approach); `explorer` for reading across files. Skip for small, obvious changes.
- Before implementing, `test-writer` writes tests from the acceptance criteria. After the full verify passes, `doc-writer` updates docs. Long output goes to `output-reader`.
- Start each new task with /clear. At ≥80% context: /compact, or restart from STATE.md.
- STATE.md (main checkout): only the main session writes it; under 100 lines, finished items to STATE-archive.md.
- After I correct you: one-line lesson under `## Lessons` in the project CLAUDE.md, drop outdated ones. Lessons about my preferences: propose them for this file.
- When a step repeats, propose a slash command (repo if project-specific, global if generic).
- Side agents: propose only for small independent tasks (no shared files, migrations, lockfile changes, or dependency on current work). After my OK: `oneai side BRANCH '<goal, files, acceptance criteria, verify command>'`. Track with `wt list` / `tuios agent-log -w side-<slug> --recap` (`oneai side` prints the pane name, e.g. side-fix-typo for fix/typo). After my OK to merge: first `oneai metrics log --who side --dir <worktree> TASK`, then `wt -C <worktree> merge` (from the main checkout a plain `wt merge` would merge your own branch; it removes the worktree), then `tuios close-window side-<slug>`.
<!-- oneai:end workflow -->
