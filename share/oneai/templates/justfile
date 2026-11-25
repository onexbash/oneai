# The checks live in .claude/hooks/checks.sh (it detects the stack); edit them there.

# Full verify: format check, lint, typecheck, all tests. Run before every merge.
verify:
    bash .claude/hooks/checks.sh full

# Fast checks on changed files, the same the Stop hook runs.
fast:
    bash .claude/hooks/checks.sh fast
