# Git Integration

## Content Scope

This reference defines how the unified methodology integrates with git for commit generation, history structure, and parallel execution safety. It specifies the commit format conventions, when commits happen in the workflow, and the mutual exclusion protocol for parallel agent execution.

**What belongs here:** Commit format templates, commit timing rules, parallel commit safety protocol, branching strategy, and commit type taxonomy.

**What does NOT belong here:** Verification pipeline logic (that is in `verification-patterns` and `repair-strategies`), checkpoint interaction points (that is in `checkpoint-types`), or agent behavioral specifications (those are in individual agent specs).

---

## Core Principle: Commit Outcomes, Not Process

The git log reads like a changelog of what shipped, not a diary of planning activity. Planning artifacts (plans, research documents, discovery notes) are intermediate work products that get committed only at milestone boundaries. Task completions — atomic units of delivered work — are the primary commit points.

---

## Commit Points

| Event | Commit? | Rationale |
|-------|---------|-----------|
| Project initialization (brief + roadmap) | Yes | Establishes project baseline |
| Plan creation | No | Intermediate — committed with plan completion |
| Research/discovery documents | No | Intermediate |
| **Task completion** | **Yes** | Atomic unit of work — one commit per task |
| **Slice completion** | **Yes** | Metadata commit (summary + state + roadmap) |
| Handoff (WIP state) | Yes | Preserves resumption context |

---

## Commit Format Convention

Task completion commits follow conventional commit format with scope identifying the slice context:

```
{type}({slice-id}): {task-name}

- [Key change 1]
- [Key change 2]
- [Key change 3]
```

**Commit types:** `feat` (new feature), `fix` (bug fix), `test` (test-only), `refactor` (code restructuring), `perf` (performance), `chore` (dependencies/config/tooling), `docs` (documentation).

Slice completion metadata commits use `docs` type with the slice identifier as scope.

---

## Parallel Commit Safety

When the orchestrator dispatches multiple executor agents in the same wave, concurrent git operations require mutual exclusion to prevent index corruption and merge conflicts.

### Lockfile-Based Mutual Exclusion

Before staging and committing, each executor acquires a lockfile (`.git/gsd-commit.lock`). The protocol:

1. Attempt to create the lockfile atomically (using `O_CREAT | O_EXCL` semantics)
2. If lockfile exists, wait with exponential backoff (100ms, 200ms, 400ms, max 5 retries)
3. After acquiring the lock: stage files, commit, push if configured
4. Release the lockfile after the commit completes
5. Stale lock detection: if the lockfile is older than 60 seconds, it is considered abandoned and can be removed

### Deferred Hook Runs

Pre-commit hooks (linting, formatting, type-checking) run during each individual task commit in sequential mode. In parallel mode, hooks are deferred: each executor commits with `--no-verify`, and the orchestrator runs a single validation pass after all agents in the wave complete. This prevents hook lock contention and duplicate work.

---

## Branching Strategy

The unified methodology operates on a single working branch (typically `main` or a feature branch). The orchestrator uses git worktrees when task isolation is configured, creating temporary worktrees for parallel executor agents. Each worktree operates on a detached branch that is merged back to the working branch after task verification passes.

---

## History Design Rationale

Per-task commits produce granular, bisectable git history. Each commit is independently revertable and `git blame` traces lines to specific task contexts. This granularity serves both human developers reviewing history and future agent sessions using `git log` as a context source. The verbosity trade-off is acceptable because the primary history consumer is the methodology's own agents, not human scanners.

---

## Cross-References

- **Executor agent spec:** §Task Completion Protocol implements commit generation using this reference
- **Orchestrator agent spec:** §Wave Execution manages the parallel commit safety protocol
- **`finishing-work` skill:** Loads this reference for commit format guidance during task wrap-up
- **Verifier agent spec:** Checks that commits exist for completed tasks as part of the wiring verification level
