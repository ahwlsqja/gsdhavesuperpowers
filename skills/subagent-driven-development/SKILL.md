---
name: subagent-driven-development
description: "Use when executing multi-task plans where subagents are available, when tasks benefit from fresh context windows, or when work can be parallelized across agents. Triggers: 'dispatch a subagent', 'use fresh context', multi-task execution with subagent capability, plan headers referencing subagent-driven development, any execution where spawning a focused agent per task would improve quality. If you have subagent capability and a multi-task plan, invoke this skill."
---

# Subagent-Driven Development

## Core Principle: Fresh Context Per Task + Two-Stage Review = Quality

Every task gets a fresh subagent with a clean context window. The subagent inherits no accumulated confusion from prior tasks. It receives exactly the context it needs — no more, no less. After completion, a two-stage review verifies both specification compliance and code quality before proceeding.

This is not optional overhead. Self-verification (the same agent checking its own work) is insufficient for reliable execution. The coordinator and the implementer must be different contexts.

## When to Use Subagents vs Inline Execution

### Use Subagents When
- The plan has **3+ tasks** that benefit from isolated context
- Tasks touch **different subsystems** (each subagent loads only relevant context)
- Any task is **complex enough** that accumulated context would degrade quality
- You need **parallel execution** on independent tasks

### Use Inline Execution When
- The plan has **1-2 simple tasks** where spawning overhead exceeds benefit
- Tasks are **tightly coupled** — each depends on understanding exactly what the previous one did
- The work is a **quick fix** where fresh context setup costs more than the fix itself
- Subagent capability is **not available** in the current environment

When in doubt, prefer subagents. The cost of spawning is low; the cost of context-rotted execution is high.

## The Implementer Dispatch Protocol

### 1. Prepare the Subagent Prompt
The implementer subagent receives:
- **Complete task text.** Extract the full task specification and provide it directly. Do not tell the subagent to "read the plan."
- **Scene-setting context.** Where this task fits in the overall plan, what prior tasks produced, what architectural decisions are relevant.
- **File references.** Which files the task will read and modify, with paths explicitly listed.
- **Verification command.** The exact command that proves the task is complete.

### 2. Set Model Selection by Complexity
- **Standard model**: Mechanical implementation — isolated functions, clear specs, 1-2 files. Most tasks are mechanical when the plan is well-specified.
- **Capable model**: Integration tasks, multi-file coordination, debugging complex interactions.
- **Most capable model**: Architecture decisions, design review, tasks requiring broad codebase understanding.

Default to standard. Escalate only when the task requires it.

### 3. Dispatch and Monitor
Dispatch the subagent and wait for completion. Do not intervene during execution unless the subagent explicitly requests context.

## The Four-Status Implementer Protocol

Every implementer subagent reports one of exactly four statuses:

### DONE
Task complete. Verification passed. Proceed to two-stage review.

**Coordinator action:** Dispatch spec compliance review.

### DONE_WITH_CONCERNS
Task complete and verification passed, but the implementer identified concerns:
- **Correctness/scope concerns** (e.g., "This won't scale past 1000 items"): MUST be addressed before proceeding.
- **Observational concerns** (e.g., "This file is getting large"): Note for future consideration. Proceed.

**Coordinator action:** Read concerns. Address correctness concerns. Note observational concerns. Dispatch review.

### NEEDS_CONTEXT
The implementer cannot proceed — missing file, unclear requirement, nonexistent dependency.

**Coordinator action:** Provide the missing context. Re-dispatch same subagent, same model, adding only what was missing.

### BLOCKED
Fundamental obstacle — task as specified is impossible, API doesn't work as documented, irreconcilable contradiction in the plan.

**Coordinator action:** Assess the blocker category:
- **Context problem:** Provide more context and re-dispatch.
- **Reasoning problem:** Re-dispatch with a more capable model.
- **Scope problem:** Break into smaller pieces and dispatch each separately.
- **Plan problem:** The plan is wrong. Escalate to re-plan.

**Red flag:** Never ignore an escalation or force the same model to retry without changes. If a subagent reports BLOCKED and you re-dispatch with identical instructions and the same model, you will get the same result. Change something.

## Two-Stage Review Protocol

After DONE or DONE_WITH_CONCERNS, work undergoes two sequential reviews. Both must pass.

### Stage 1: Spec Compliance Review

**Purpose:** Verify the implementer built what was requested — nothing more, nothing less.

**Review prompt framing:** "The implementer finished suspiciously quickly. Their report may be incomplete, inaccurate, or optimistic. You MUST verify everything independently."

The reviewer must:
1. Read the task specification
2. Read the actual code changes (not the implementer's summary)
3. Verify every spec requirement has a corresponding implementation
4. Verify no unrequested functionality was added (scope creep)
5. Run the verification command independently

**Outcomes:**
- **Pass:** Proceed to Stage 2.
- **Fail:** Return to implementer with specific issues. Fix. Review again. Do not skip the re-review.

### Stage 2: Code Quality Review

**Purpose:** Verify the implementation is clean, tested, and maintainable. Only runs after spec compliance passes.

The reviewer evaluates: code correctness, edge case handling, test coverage, naming and readability, error handling, and consistency with project patterns.

**Outcomes:**
- **Pass:** Task complete. Proceed to next task.
- **Fail:** Return to implementer. Fix. Re-review.

### Review Loop Limits
If a task fails review 3 times on the same issue, the problem is likely in the task specification. Escalate to re-examine the task rather than continuing the fix/review cycle.

## Context Construction for Subagents

### What to Include
- The full task specification (extracted, not referenced)
- Relevant file contents the task will modify
- Architectural decisions affecting this task
- Output from prior tasks this one depends on
- The verification command and expected outcome

### What to Exclude
- The full plan (subagent only needs its task)
- Prior task summaries (unless this task depends on them)
- Conversation history from the coordinator
- Other task specifications (noise invites scope creep)
- Generic project documentation (unless specifically required)

### The Context Rule of Thumb
If you removed a piece of context and the subagent could still complete the task correctly, that context should not have been included. Every irrelevant token dilutes focus.

## Coordination Across Tasks

**Sequential tasks:** Execute in order. Each subagent receives prior task output as context. Review must pass before dispatching the next.

**Independent tasks (parallel candidates):** Dispatch simultaneously if no shared files and no dependency relationship. Ensure no two subagents modify the same file.

**Dependent tasks with shared context:** Include task A's actual changes (not just its summary) in task B's context. The subagent needs to see exactly what was built.
