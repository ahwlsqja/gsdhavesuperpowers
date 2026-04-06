---
name: parallel-dispatch
description: "Use when deciding whether to dispatch multiple subagents simultaneously, when coordinating parallel work, or when collecting results from concurrent agents. Triggers: 'run in parallel', 'dispatch multiple agents', 3+ independent tasks available, wave-based execution, any situation where tasks have no dependencies and could run concurrently. If you are considering running multiple agents at the same time, invoke this skill."
---

# Parallel Dispatch

## Core Principle: Parallelism Is a Tool, Not a Default

Running tasks in parallel is faster only when tasks are genuinely independent. Parallel tasks that share state, modify the same files, or depend on each other's output produce conflicts, race conditions, and debugging nightmares costing more than sequential execution. The decision to parallelize must be deliberate, based on explicit independence criteria — not assumed because tasks are listed adjacently in a plan.

## Independence Criteria for Parallel Tasks

Before dispatching in parallel, verify ALL of the following:

### 1. No Shared File Modifications
No two parallel tasks may modify the same file. Read access is fine — multiple agents can read configuration. But if two agents write the same file, one overwrites the other.

**Check:** Compare `files` lists across tasks. Any overlap in files to be modified disqualifies those tasks from parallel execution.

### 2. No Data Dependencies
Task B must not depend on any output from Task A. If B needs to read a file A creates, they cannot run in parallel.

**Check:** List what each task produces (files created, state changes) and what each consumes. Any production-consumption pair means sequential execution.

### 3. No Shared Resources
No two parallel tasks should compete for the same limited resource — database connection pool, port, external API with rate limits, lock file.

**Check:** Identify external resources each task uses. Same database is OK only if they touch different tables with no cross-table dependencies.

### 4. Each Task Is Self-Contained
Each task can be understood and executed without knowledge of what parallel tasks are doing. If understanding Task A helps understand Task B, they likely share context requiring sequential execution.

### Independence Checklist

| Check | Pass | Fail |
|-------|------|------|
| No shared file writes | ✅ Parallel OK | ❌ Sequential required |
| No data dependencies | ✅ Parallel OK | ❌ Sequential required |
| No shared resources | ✅ Parallel OK | ❌ Sequential or coordinated |
| Self-contained tasks | ✅ Parallel OK | ❌ Shared context → sequential |

All four must pass. One failure means sequential for those tasks (others may still parallelize).

## When Parallelism Helps vs Hurts

### Parallelism Helps When
- **3+ truly independent tasks** exist (2 tasks rarely justify coordination overhead)
- **Each task is substantial** (5+ minutes). Dispatch/collect overhead is fixed — small tasks don't benefit.
- **No shared state** — different files, subsystems, concerns
- **Results combine cleanly** — independent artifacts, no merging

### Parallelism Hurts When
- **Tasks share files** — merge conflicts from parallel modifications
- **Failures are related** — investigating the same root cause twice wastes time
- **Tasks need full system state** — can't be isolated into focused context
- **Tasks are discovery-oriented** — research changes scope based on findings; parallel discovery produces redundant or contradictory results

### The 3-Task Threshold
Do not dispatch fewer than 3 tasks in parallel. With 2 tasks, coordination overhead often exceeds time savings. With 3+, savings compound.

## Prompt Structure for Parallel Agents

Each parallel agent receives a focused prompt:

### Required Elements
1. **Focused scope:** Exactly one task. The agent should not know about other parallel tasks.
2. **Clear goal:** Verification command or observable outcome proving completion.
3. **Constraints:** Files and subsystems that are off-limits (owned by other parallel agents).
4. **Expected output:** What artifact this task produces.

### Explicitly Excluded
- Other tasks in the parallel batch (prevents scope creep)
- Full project history (only what this task needs)
- Broad codebase context (focused context is the point)

### Prompt Template

```
## Task
[Full task specification — extracted, not referenced]

## Scope Boundaries
You are responsible for: [files/subsystems this task owns]
You must NOT modify: [files owned by other parallel agents]

## Context
[Only what this specific task needs]

## Verification
[Exact command proving completion]

## Reporting
Report: DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, or BLOCKED.
```

## Result Collection Protocol

### Collecting Results
1. **Wait for all agents to complete.** Do not process partial results.
2. **Check for conflicts.** Compare output file lists for unexpected overlaps.
3. **Run integration verification.** After all complete, run the test suite to verify combined changes work.
4. **Address failures individually.** One failed task doesn't invalidate others. Fix individually.

### Conflict Resolution
If parallel agents produced conflicting changes:
1. Identify conflict scope — which files overlap, which changes conflict
2. Determine authoritative change — the task that more directly owns the file
3. Merge manually or re-run the subordinate task with the authoritative change as context
4. Note the independence failure — update analysis for future batches

## Wave-Based Coordination

For plans with many tasks and complex dependencies:

```
Wave 1: Tasks with no dependencies → parallel
Wave 2: Tasks depending on Wave 1 → parallel within wave
Wave 3: Tasks depending on Wave 2 → parallel within wave
```

### Wave Rules
- **Within a wave:** All tasks parallel (passed independence criteria)
- **Between waves:** Sequential (Wave N+1 waits for all of Wave N)
- **Wave assignment:** task's wave = max(wave of all its dependencies) + 1
- **Integration:** Run verification after each wave before starting the next

### Implicit Dependencies
Tasks modifying the same file have an implicit dependency even if undeclared. During wave assignment, detect file overlap and bump the later task to a subsequent wave.

### Wave Example
```
Task A: no deps         → Wave 1
Task B: no deps         → Wave 1
Task C: depends on A    → Wave 2
Task D: depends on B    → Wave 2
Task E: depends on C, D → Wave 3
```

A and B run in parallel. After both complete, C and D run in parallel. Then E runs.

## Monitoring Parallel Execution

### Early Termination Decisions
If one agent fails in a way that invalidates other agents' work:
1. **Isolated failure:** Let others continue. Fix after batch completes.
2. **Cascade failure (invalidates shared assumptions):** Cancel remaining agents. Fix root cause. Re-dispatch the wave.

Most failures are isolated. Do not cancel an entire batch because one task hit a bug — that wastes successful agents' work.
