---
name: executing-plans
description: "Use when executing a task plan, following a PLAN.md, or implementing steps from a decomposed specification. Triggers: 'execute this plan', 'implement these tasks', 'follow the plan', starting work on a pre-written task list, any situation where a plan exists and needs to be carried out step-by-step. If a plan document exists for your current work, invoke this skill."
---

# Executing Plans

## Core Principle: Plans Are Contracts, Not Suggestions

A plan is a verified, execution-ready specification. Someone invested effort decomposing the work, identifying files, writing verification commands, and ordering dependencies. Your job is to execute it faithfully — not to re-architect it, not to "improve" it on the fly, and not to skip steps because they seem unnecessary.

Plans are written by agents with limited context. Reality will differ. The deviation rules below define exactly when you may adapt and when you must stop and escalate.

## Load-Plan Protocol

Before writing a single line of code:

1. **Read the entire plan.** Not the first task — the entire plan. Understand the full scope, dependency ordering, and end state.
2. **Identify the verification commands.** Know what success looks like before you start.
3. **Critical review.** Scan for file paths that don't exist, function signatures that don't match the real code, dependencies on artifacts that weren't created by prior tasks, and verification commands that test the wrong thing.
4. **Note discrepancies but do not re-plan.** Minor path errors or signature mismatches — adapt during execution. Fundamental architectural mismatches (plan assumes REST but codebase uses GraphQL) — escalate before starting.
5. **Create a mental model of the end state.** What will the codebase look like when all tasks are complete? This model guides decisions when the plan is ambiguous.

## Step-by-Step Execution Protocol

Execute each task in plan order. Do not skip ahead, do not reorder, do not parallelize unless the plan explicitly marks tasks as independent.

For each task:

1. **Read the task specification completely.** Every field — description, files, verification command, expected output.
2. **Verify preconditions.** Are the files the task references present? Did prior tasks produce the required artifacts?
3. **Implement exactly what is specified.** Build real functionality, not stubs. If the task says "create authentication endpoint," build one that authenticates against a real store — not one that returns hardcoded success.
4. **Run the task's verification command.** If it passes, proceed. If it fails, debug and fix before moving on. Do not accumulate broken tasks.
5. **Track deviations.** Any departure from the plan must be noted in your task summary. Undocumented deviations are invisible to downstream tasks and reviewers.

## Deviation Rules

### Rule 1: Auto-Fix Bugs (No Escalation Needed)
Wrong queries, logic errors, type errors, missing imports, incorrect function signatures — fix inline. The plan's intent is clear; the implementation detail was wrong. Fix it and note the deviation.

### Rule 2: Auto-Add Missing Critical Functionality (No Escalation Needed)
Missing error handling, absent input validation, no authentication on a sensitive endpoint — add automatically. They are omissions any competent implementation would include.

### Rule 3: Auto-Fix Blocking Issues (No Escalation Needed)
Missing dependency installation, wrong types that prevent compilation, broken imports from prior task drift — fix whatever blocks forward progress.

### Rule 4: STOP and Escalate Architectural Changes
New database tables the plan didn't envision, switching libraries, breaking public APIs, changing the data model — stop, describe the situation, and wait for guidance.

**Signs you need to escalate:**
- You're about to create a file the plan never mentioned AND it changes the system's architecture
- The change would break other parts of the codebase not covered by this plan
- You're second-guessing a fundamental assumption the plan was built on
- The deviation would surprise a reviewer who read the plan

### Deviation Summary Table

| Situation | Action | Escalation |
|-----------|--------|------------|
| Bug in plan's code | Fix inline | No — note deviation |
| Missing error handling | Add it | No — note deviation |
| Blocking build issue | Fix it | No — note deviation |
| Architectural change needed | STOP | Yes — describe situation |
| Plan step is impossible | STOP | Yes — describe why |
| Plan step is unnecessary | Execute anyway | No — it may matter downstream |

## The Analysis Paralysis Guard

A specific failure mode during execution: reading and re-reading code without making changes.

**The rule:** If you have made **5 or more consecutive read-only operations** (Read, Grep, Glob, search) without any write action (Edit, Write, Bash command that modifies state), you are in analysis paralysis. You must immediately do one of:

1. **Write code.** You have enough information. Start implementing.
2. **Report a blocker.** You genuinely cannot proceed. State what is missing and why.
3. **Run a command.** Execute a test, build, or verification to get concrete feedback instead of more reading.

### Analysis Paralysis Red Flags

- "Let me just check one more file..."
- "I want to understand the full context before changing anything"
- "Let me trace through this code path completely first"
- "I should read all the related tests before writing mine"
- "Let me verify my understanding by reading X, Y, and Z"

All of these sound reasonable. All of them, repeated past the 5-call threshold, are procrastination. You do not need complete understanding to start. You need enough understanding to make the first change, run the verification, and iterate.

Reading is not progress. Only artifacts (code, tests, configurations, documentation) are progress.

## Handling Plan Ambiguity

When a plan step is unclear:

1. **Check the verification command.** It often reveals the intended outcome better than prose.
2. **Check the expected output.** What files should exist after this task?
3. **Check neighboring tasks.** The task before and after often clarify intent.
4. **Apply the "zero context engineer" test.** What would someone with no context build from this plan? Build that.
5. **When in doubt, do less.** Build the minimal interpretation. It's easier to add functionality than remove an architectural decision made on a guess.

## Post-Execution Checklist

After completing all tasks in the plan:

1. **Run the plan's top-level verification.** Not individual task verifications — the plan-level verification that confirms the entire deliverable.
2. **Review your deviations list.** Are any significant enough to affect downstream plans or reviewers?
3. **Check for orphaned artifacts.** Did you create files not referenced by tests or other code?
4. **Confirm the end state matches your mental model.** Does the codebase look like what you expected when you read the plan?
