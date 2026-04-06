---
name: writing-plans
description: "Use when decomposing work into tasks, creating execution plans, or preparing multi-step implementation sequences. Triggers: after brainstorming approval, 'write a plan', 'break this down', 'create tasks', any transition from design to execution. Always invoked after brainstorming — never skip directly to implementation skills."
---

# Writing Plans

Plans are written assuming **the engineer has zero context for our codebase and questionable taste.** This single sentence establishes the documentation bar — every plan must be self-contained, explicit, and unambiguous. If two different engineers could read the same plan and build different things, the plan is not finished.

## Task Granularity Standard

```
Every task must be completable in 2–5 minutes.
If a task takes longer, it is too large. Decompose further.
```

This granularity standard exists because:

- 2–5 minute tasks fit within a single reasoning frame — the agent does not need to maintain complex intermediate state
- Small tasks produce frequent checkpoints — if something goes wrong, minimal work is lost
- Granular tasks are independently verifiable — each task has a clear "done" signal
- Fine decomposition surfaces hidden complexity — if you cannot decompose a task to 2–5 minutes, you do not understand it well enough to implement it

### What 2–5 Minutes Looks Like

- Write one test for one behavior → run it → see it fail: **~2 minutes**
- Implement the minimal code to pass that test → run tests → see it pass: **~3 minutes**
- Add error handling for one specific error path → test it: **~3 minutes**
- Wire one component to one data source → verify the connection: **~4 minutes**
- Refactor one function to extract a helper → run tests → confirm no regressions: **~3 minutes**

### What Is Too Large

- "Implement the search feature" → Decompose into: write search query test, implement query, write results rendering test, implement rendering, write error handling test, implement error handling
- "Set up the database" → Decompose into: create schema migration, write connection config, add health check, seed test data
- "Build the API" → Decompose into: define route, write request validation test, implement validation, write handler test, implement handler, wire to data layer

## The No-Stub Mandate

```
NO PLACEHOLDERS. NO STUBS. NO DEFERRED DECISIONS.
Every task contains actual code, actual commands, actual implementation.
```

Plans must NOT contain:

| Prohibited Pattern | Example | Why It Fails |
|-------------------|---------|-------------|
| Deferred markers | "TBD", "TODO", "to be determined", "to do" | Pushes decisions to implementation time when context is thinnest |
| Vague directives | "Add appropriate error handling" | "Appropriate" is not a specification. Name the errors and their handlers. |
| Cross-references for content | "Similar to Task N" | The engineer may read tasks out of order. Repeat the code. |
| Description without implementation | "Create a function that processes X" | Show the function signature, the test, and the expected behavior. |
| Placeholder values | "Use a suitable library" | Name the library. Show the import. Show the usage. |
| Future-tense deferrals | "This will be addressed in a later task" | If it matters, address it now. If it doesn't, don't mention it. |

## Task Structure Template

Every task in a plan follows this structure:

```
### Task N: [Descriptive title]

**Files:** [Exact file paths that will be created or modified]

**Steps:**
1. Write the failing test
   - Actual test code (not a description of what to test)
   - Exact command to run: `npm test -- --grep "test name"`
   - Expected output: test fails with [specific error]

2. Implement minimal code to pass
   - Actual implementation code (not a description of what to implement)
   - Show imports, function signatures, and key logic

3. Run tests to verify
   - Exact command: `npm test`
   - Expected output: all tests pass

4. Commit
   - `git add [specific files]`
   - `git commit -m "[specific message]"`

**Verification:** [Exact command that proves this task is complete]
**Expected output:** [What the verification command should produce]
```

When TDD does not apply (configuration changes, documentation, infrastructure), adapt the template:

```
### Task N: [Descriptive title]

**Files:** [Exact file paths]

**Steps:**
1. [Specific action with actual content — file contents, command, configuration]
2. [Next specific action]

**Verification:** [Command that proves completion]
**Expected output:** [Expected result]
```

## 8-Dimension Structural Quality Checklist

Before a plan is ready for execution, verify it against all 8 dimensions. A plan that fails any dimension is not ready.

### Dimension 1: Requirement Coverage

- [ ] Every requirement from the design spec maps to at least one task
- [ ] No requirement is partially addressed — each is fully covered or explicitly deferred with justification
- [ ] Acceptance criteria from the spec are reflected as verification commands in the tasks

### Dimension 2: Task Atomicity

- [ ] Every task is completable in 2–5 minutes
- [ ] Every task has a single clear objective (not "do X and also Y")
- [ ] Every task is independently verifiable — its verification does not depend on uncommitted work from other tasks

### Dimension 3: Dependency Ordering

- [ ] Tasks are ordered so that each task's dependencies are completed before it starts
- [ ] No circular dependencies exist
- [ ] Independent tasks are identified (they can be executed in parallel if needed)
- [ ] File-level dependencies are explicit — if Task 5 modifies a file that Task 3 creates, the dependency is stated

### Dimension 4: File Scope

- [ ] Every task lists the exact files it creates or modifies
- [ ] No task modifies files outside its listed scope
- [ ] File paths are absolute or relative to project root — no ambiguity
- [ ] New files include their full initial content in the task (no "create an empty file and fill it later")

### Dimension 5: Verification Commands

- [ ] Every task has a concrete verification command (not "verify it works" — an actual command)
- [ ] Verification commands are runnable as-is — no placeholders, no "adjust for your environment"
- [ ] Expected output is specified — what does success look like when you run the command?
- [ ] Verification commands test the task's specific contribution, not just "all tests pass"

### Dimension 6: Context Fit

- [ ] The plan fits within the executor's context window (individual tasks do not require reading the entire codebase)
- [ ] Each task includes enough context for an executor with zero prior knowledge to complete it
- [ ] Long plans are broken into phases with clear handoff points between phases

### Dimension 7: Gap Detection

- [ ] No implicit steps exist between tasks (nothing is "obvious" or "standard")
- [ ] Error handling is explicit in every task that touches I/O, network, or user input
- [ ] Edge cases identified during design are addressed in specific tasks (not left as "the implementation should handle these")

### Dimension 8: Nyquist Compliance

- [ ] The plan's verification frequency is at least 2x the expected change frequency
- [ ] No long stretch of tasks goes without verification (max 2 tasks between verification checkpoints)
- [ ] Integration points between components have explicit verification tasks

## Plan Self-Review Checklist

After writing the plan and before presenting it for execution, review against these criteria:

- [ ] **Placeholder scan:** Search for "TBD", "TODO", "appropriate", "suitable", "similar to", "as needed", "will be". Each one is an unresolved decision. Resolve it.
- [ ] **Type consistency:** Are function names, variable names, and type signatures consistent across all tasks? A function called `clearLayers()` in Task 3 must not be called `clearFullLayers()` in Task 7.
- [ ] **Import consistency:** Do all tasks that use a module import it? Do any tasks import modules that don't exist yet (and if so, which prior task creates them)?
- [ ] **Test coverage:** Does every behavioral change have a corresponding test task? Are tests written BEFORE implementation (TDD order)?
- [ ] **Spec alignment:** Does every task trace back to the design spec? Are there tasks that implement things not in the spec (scope creep)?

## Execution Handoff

The plan's header must include a reference to the next skill:

```
REQUIRED: Use `subagent-driven-development` (recommended when subagents are available)
or `executing-plans` (for single-agent inline execution) to implement this plan task-by-task.
```

This wires the next phase into the plan itself — the executor knows which skill to load for implementation.

## Rationalization Prevention Table

| # | Thought Pattern | Correction |
|---|----------------|------------|
| 1 | "The tasks are self-explanatory, no need for verification commands" | If it is self-explanatory, the verification command is obvious and takes 10 seconds to write. Write it. |
| 2 | "I'll figure out the exact implementation during execution" | A plan that defers implementation details to execution time is not a plan — it is a wish list. |
| 3 | "These tasks are roughly 2–5 minutes each" | "Roughly" is not the standard. If you cannot confidently say a task completes in 2–5 minutes, decompose further. |
| 4 | "The engineer will know what I mean" | The engineer has zero context and questionable taste. They will not know what you mean. Be explicit. |
| 5 | "Error handling can be added later" | Later never comes. Error handling in the plan or error handling never. |
| 6 | "This is a standard pattern, no need to spell it out" | Standard to whom? Write it out. The executor may not share your definition of standard. |
| 7 | "The plan is getting too long with all this detail" | A long, explicit plan is better than a short, ambiguous one. Ambiguity costs more than verbosity. |
| 8 | "I'll add verification after the implementation tasks" | Verification commands are written WITH each task, not appended afterward. Each task is a verified unit. |

## What This Skill Produces

The output of this skill is a single artifact: an execution-ready plan document with:

- Ordered, atomic tasks at 2–5 minute granularity
- Explicit file lists, code content, and verification commands per task
- Structural quality verified against all 8 dimensions
- Self-reviewed for placeholders, consistency, and spec alignment
- Clear handoff to execution skills

This plan document is the contract between the planner and the executor. The executor follows it exactly. Deviations are tracked and justified, not silent.
