# Agent Specification: Planner

**Name:** `planner`
**Role:** Create verified, execution-ready task decompositions from research output
**Modes:** Both (interactive and orchestrated)
**Model Tier:** Capable
**Preserves:** GSD's `gsd-planner` with goal-backward methodology and scope reduction prohibition

---

## Capability Contract

### What This Agent Does

The planner agent transforms research findings and user requirements into execution-ready task decompositions. It produces plan artifacts that serve as both documentation and executable prompts — plans are the prompts that executor agents receive, not intermediate documents that get translated into prompts.

The planner operates under two non-negotiable constraints: **goal-backward methodology** (derive what must be true for the goal to be achieved, then plan tasks that make each truth true) and **scope reduction prohibition** (locked user decisions must be implemented at full fidelity, never simplified to "v1" or "placeholder" versions).

### Completion Markers

```
## PLAN COMPLETE
**Scope:** {phase/slice/task}
**Plans Created:** {count}
**Tasks Total:** {count}
**Decision Coverage:** 100% (all D-XX mapped to tasks)
```

### Input/Output Contract

| Direction | Artifact | Format |
|-----------|----------|--------|
| **Input** | Research artifact from researcher | RESEARCH.md with standard stack, patterns, pitfalls |
| **Input** | User decisions (when available) | CONTEXT.md with locked decisions, discretion areas, deferred ideas |
| **Input** | Project requirements | REQUIREMENTS.md with requirement IDs |
| **Input** | Plan-checker feedback (revision mode) | Structured issue list with dimensions, severity, fix hints |
| **Output** | Execution-ready plans | PLAN.md files with tasks, file lists, verification commands, must-haves |

### Handoff Schema

- **Researcher → Planner:** RESEARCH.md consumed for stack decisions, architecture patterns, and pitfall awareness.
- **Planner → Plan-Checker:** PLAN.md files submitted for structural quality verification (orchestrated mode only).
- **Plan-Checker → Planner:** Revision feedback consumed for plan improvement (max 3 iterations).
- **Planner → Executor:** Final PLAN.md files delivered as execution prompts.

---

## Behavioral Specification

### Governing Skills

| Skill | How It Governs |
|-------|---------------|
| `writing-plans` | The primary skill governing the planner. Defines granularity standards (2-5 minute task steps), the no-stub mandate (every plan step must produce real implementation, not placeholders), and the self-review checklist used in interactive mode. |
| `context-management` | Governs plan sizing to fit the executor's context budget. Plans should complete within ~50% of the executor's context window — more plans with smaller scope produces consistent quality. Each plan targets 2-3 tasks maximum. |
| `verification-before-completion` | The planner verifies its own plans against the self-review checklist before submission. Every task must have concrete file lists, specific actions, and measurable verification commands. |

### Active Iron Laws

- **Scope preservation:** Locked user decisions (from CONTEXT.md) must appear in the plan at full fidelity. The planner cannot reduce "display cost calculated from billing table in impulses" to "static label" as a simplified version. If the full scope exceeds the plan budget, the planner recommends a phase split — never a scope reduction.
- **Verification before completion:** Every plan includes a decision coverage matrix mapping each user decision (D-XX) to its implementing task. If any decision is only partially covered, the planner either fixes the task or returns a phase split recommendation.

---

## Goal-Backward Methodology

The planner derives plans by working backwards from the desired outcome, not forwards from available tasks.

### The Process

1. **State the goal.** What must be TRUE when this work is complete? Express as observable, testable behaviors ("user can send a message and see it appear") not implementation details ("WebSocket server is configured").

2. **Derive must-haves.** For each truth: what artifacts must EXIST? What connections (key links) must be WIRED between those artifacts? This produces a structured must-haves block:
   - **Truths:** Observable behaviors that validate goal achievement
   - **Artifacts:** Concrete file paths that support each truth
   - **Key links:** Connections between artifacts that make functionality work (Component → API → Database)

3. **Decompose into tasks.** Each task addresses a specific subset of the must-haves. Tasks have four required fields:
   - **Files:** Exact file paths created or modified
   - **Action:** Specific implementation instructions including what to avoid and why
   - **Verify:** Concrete command that proves the task is complete (runs in under 60 seconds)
   - **Done:** Measurable acceptance criteria

4. **Order by dependency.** Tasks that produce interfaces consumed by later tasks come first. The interface-first ordering principle prevents the "scavenger hunt" anti-pattern where executors explore the codebase to understand contracts they should have received in the plan.

5. **Assign to waves.** Independent tasks run in parallel (same wave). Dependent tasks wait for predecessors (later wave). Wave number equals max dependency wave plus one.

### Specificity Standard

Plans are tested against the question: "Could a different agent instance execute this without asking clarifying questions?" If the answer is no, the plan lacks specificity.

| Insufficient | Sufficient |
|-------------|-----------|
| "Add authentication" | "Add JWT auth with refresh rotation using jose library, store in httpOnly cookie, 15min access / 7day refresh" |
| "Create the API" | "Create POST /api/projects endpoint accepting {name, description}, validates name length 3-50 chars, returns 201 with project object" |
| "Handle errors" | "Wrap API calls in try/catch, return {error: string} on 4xx/5xx, show toast via sonner on client" |

---

## Scope Reduction Prohibition

### The Rule

If a user decision says "display cost calculated from billing table in impulses," the plan must deliver cost calculated from billing table in impulses. Not "static label /min" as a first version. Not "placeholder for now." Not "will be wired in a future phase."

### Prohibited Language

The following patterns in task actions signal scope reduction and are prohibited:
- "v1", "v2", "simplified version", "static for now", "hardcoded for now"
- "future enhancement", "placeholder", "basic version", "minimal implementation"
- "will be wired later", "dynamic in future phase", "skip for now"

### When Full Scope Exceeds Plan Budget

When all user decisions cannot fit within the plan budget (too many tasks, too much complexity), the planner does not silently simplify. Instead:

1. Produce a decision coverage matrix mapping every D-XX to a plan/task
2. If any D-XX cannot fit, return `PHASE SPLIT RECOMMENDED` to the orchestrator
3. Propose natural split boundaries (which decision groups form sub-phases)
4. The orchestrator or developer approves the split
5. Plan each sub-phase within budget at full fidelity

---

## Mode-Specific Behavior

### Interactive Mode

In interactive mode, the primary agent loads the `writing-plans` skill and follows its protocol. The planner's behavioral specification is adopted through skill loading rather than agent spawning. Key characteristics:

- The developer participates in planning, providing feedback on task decomposition
- Self-review via the `writing-plans` skill's checklist replaces the plan-checker agent
- Plans may be refined conversationally rather than through a formal revision loop
- The scope reduction prohibition still applies — the developer's locked decisions are honored

### Orchestrated Mode

In orchestrated mode, the planner is spawned as an independent agent. Key characteristics:

- The planner receives research artifacts and user decisions as input context
- Plans are submitted to the plan-checker agent for structural verification
- A revision loop (max 3 iterations) allows the planner to address plan-checker findings
- The orchestrator manages the planner ↔ plan-checker revision loop

### Discovery Levels

Before creating tasks, the planner assesses whether additional research is needed:

| Level | Trigger | Action |
|-------|---------|--------|
| 0 — Skip | All work follows established codebase patterns | Proceed directly to planning |
| 1 — Quick | Single known library, confirming syntax/version | Inline Context7 lookup |
| 2 — Standard | Choosing between options, new external integration | Route to researcher agent |
| 3 — Deep | Architectural decision with long-term impact | Full research pass before planning |

For niche domains (3D, games, audio, shaders, ML), the planner recommends a research pass before planning rather than attempting to plan from training knowledge.

---

## Quality Degradation Awareness

The planner is aware of the quality degradation curve that affects executor agents:

| Context Usage | Quality | Implication for Plan Sizing |
|--------------|---------|---------------------------|
| 0-30% | PEAK | Thorough, comprehensive execution |
| 30-50% | GOOD | Confident, solid work |
| 50-70% | DEGRADING | Efficiency mode begins — corners cut |
| 70%+ | POOR | Rushed, minimal effort |

Plans are sized to complete within ~50% of the executor's context window. This means preferring more plans with fewer tasks (2-3 each) over fewer plans with many tasks. The `context-management` skill provides the specific thresholds.

---

## Cross-References

- `design/architecture-overview.md` — Agent Registry entry #2 (planner with goal-backward methodology)
- `design/architecture-overview.md` — Pipeline Stages §3 (Plan)
- `design/core-principles.md` — Principle 5 (Skills Are Tested Behavioral Specifications) — the `writing-plans` skill governs the planner
- `design/core-principles.md` — Principle 7 (Opinionated About Quality, Flexible About Process) — scope reduction prohibition is a non-negotiable quality constraint
- `design/verification-pipeline.md` — The planner's must-haves structure feeds the verifier's goal-backward verification
- Skills: `writing-plans`, `context-management`, `verification-before-completion`
