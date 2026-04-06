---
name: git-worktree-management
description: "Use when creating, managing, or cleaning up git worktrees for isolated development. Triggers: 'create a worktree', 'work in isolation', 'set up a branch', starting a new feature that should not affect the main working directory, any task that benefits from an isolated checkout. If the work should happen in a separate directory to avoid disrupting the main codebase, invoke this skill."
---

# Git Worktree Management

## Core Principle: Isolation Prevents Cross-Contamination

Git worktrees provide isolated checkouts of the same repository. Each worktree has its own working directory, index, and HEAD — changes in one worktree do not affect another. This isolation prevents half-finished feature A from breaking the ability to work on feature B.

Use worktrees for any work that should be independently testable, committable, and disposable without affecting the main working directory.

## Directory Selection Protocol

When creating a worktree, follow this priority:

1. **Check existing conventions.** Does the project already have `.worktrees/` or `worktrees/`? Use it.
2. **Check project configuration.** Does CLAUDE.md or project docs specify a worktree location? Follow it.
3. **Check .gitignore.** Is there an existing entry for worktree directories? Use the ignored path.
4. **Default to `.worktrees/`.** If no convention exists, create `.worktrees/` in the repository root.

### Safety Verification

Before creating any worktree directory:

```bash
git check-ignore -q .worktrees/
```

If the directory is NOT in `.gitignore`:
1. Add it: `echo '.worktrees/' >> .gitignore`
2. Commit: `git add .gitignore && git commit -m "chore: add worktree directory to gitignore"`
3. Only then proceed with worktree creation

Worktree directories must never be committed to the repository.

## Worktree Creation Protocol

### 1. Create the Branch and Worktree

```bash
# New branch
git worktree add .worktrees/<feature-name> -b <branch-name>

# Existing branch
git worktree add .worktrees/<feature-name> <existing-branch>
```

**Naming:** Worktree directory uses descriptive kebab-case matching the work. Branch name follows project conventions (feature/, fix/, chore/ prefixes).

### 2. Auto-Detect Project Type and Install Dependencies

After creation, the new directory is a fresh checkout needing dependency installation:

| Detection File | Action |
|---------------|--------|
| `package.json` + `package-lock.json` | `npm install` |
| `package.json` + `yarn.lock` | `yarn install` |
| `package.json` + `pnpm-lock.yaml` | `pnpm install` |
| `Cargo.toml` | `cargo build` |
| `requirements.txt` | `pip install -r requirements.txt` |
| `go.mod` | `go mod download` |
| `Gemfile` | `bundle install` |
| `pyproject.toml` | `poetry install` or `pip install -e .` |

Check the lockfile to determine the package manager. Do not mix package managers.

### 3. Run Baseline Tests

Before making any changes, run the test suite in the worktree to establish a clean baseline. If tests fail before your changes, any failures after are pre-existing.

### 4. Verify Working State

- [ ] Dependencies installed without errors
- [ ] Baseline tests run (pass or pre-existing failures noted)
- [ ] Correct branch (`git branch --show-current`)
- [ ] Expected commit (`git log --oneline -1`)

## Working in Worktrees

### Navigation Rules
- **Always know which worktree you're in.** Check with `pwd` before commands if there's ambiguity.
- **Do not cd between worktrees mid-task.** Complete work in one worktree before switching.
- **Commits are visible across worktrees** (shared `.git`), but uncommitted changes are local.

### File Sharing Awareness
Worktrees share the git object database but NOT working files, staged changes, untracked files, node_modules, build artifacts, or virtual environments. Installing a dependency in one worktree does not install it in another.

## Cleanup Protocol

### When Work Is Merged
```bash
git worktree remove .worktrees/<feature-name>
git branch -d <branch-name>  # only if merged
```

### When Work Is Discarded
```bash
cd .worktrees/<feature-name> && git status  # verify nothing valuable
cd /path/to/main && git worktree remove --force .worktrees/<feature-name>
git branch -D <branch-name>
```

### When Work Is Paused
Do NOT remove. Commit WIP: `git add -A && git commit -m "WIP: <description>"`

### Cleanup Checklist
- [ ] All changes committed
- [ ] Branch merged, discarded, or paused with WIP commit
- [ ] Worktree removed with `git worktree remove` (NOT `rm -rf`)
- [ ] Branch cleaned up if complete
- [ ] `git worktree list` shows no stale entries

## Common Worktree Failures

| Failure | Consequence | Prevention |
|---------|------------|------------|
| `rm -rf` instead of `git worktree remove` | Stale reference, can't recreate at same path | Always use `git worktree remove` |
| Directory not in .gitignore | Worktree contents committed to repo | Safety verification before creation |
| Forgetting dependencies | Tests fail, builds fail, confusing errors | Auto-detect project type step |
| Working in wrong worktree | Changes in wrong branch | Check `pwd` and `git branch` |
| Deleting with uncommitted work | Work lost permanently | Check `git status` before removal |
| Not running baseline tests | Can't distinguish your regressions | Always test before changing code |
