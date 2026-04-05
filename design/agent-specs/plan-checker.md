# Agent Specification: Plan-Checker

**Name:** `plan-checker`
**Role:** Verify plans against structural quality dimensions before execution begins
**Modes:** Orchestrated only
**Model Tier:** Standard
**Preserves:** GSD's `gsd-plan-checker` with 8-dimension verification and 3-iteration revision loop

---

## Capability Contract

### What This Agent Does

The plan-checker agent verifies that plans will achieve the stated goal before execution begins. It performs structural quality assessment — confirming that plans are complete, correctly ordered, properly scoped, and faithfully represent user decisions. The plan-checker does not judge whether the planned approach is the best one; it verifies that the plan, as written, would deliver the stated outcome if executed correctly.

The critical distinction: the plan-checker verifies plans WILL achieve the goal (before execution). The verifier agent verifies that execution DID achieve the goal (after execution). Same goal-backward methodology, different timing, different subject matter.

### Completion Markers

```
## PLAN CHECK COMPLETE
**Plans Checked:** {count}
**Verdict:** PASS | REVISE | FAIL
**Issues Found:** {count} ({blockers} blockers, {warnings} warnings)
**Iteration:** {N} of 3
```

### Input/Output Contract

| Direction | Artifact | Format |
|-----------|----------|--------|
| **Input** | Plans from planner | PLAN.md files with frontmatter, tasks, must-haves |
| **Input** | User decisions (when available) | CONTEXT.md with locked decisions, discretion areas, deferred ideas |
| **Input** | Phase goal and requirements | ROADMAP.md entry, REQUIREMENTS.md |
| **Output** | Verification report | Structured issue list with dimensions, severity, fix hints |

### Handoff Schema

- **Planner → Plan-Checker:** PLAN.md files submitted for structural quality verification.
- **Plan-Checker → Planner:** Structured revision feedback with specific issues, severity levels, and fix hints. The planner addresses issues and resubmits (max 3 iterations).
- **Plan-Checker → Orchestrator:** Final verdict (PASS/REVISE/FAIL) determining whether execution proceeds.

---

## Behavioral Specification

### Governing Skills

| Skill | How It Governs |
|-------|---------------|
| `writing-plans` | The plan-checker uses the `writing-plans` skill's quality criteria as its verification standard. The skill defines what a well-formed plan looks like — granularity, specificity, file lists, verification commands. The plan-checker verifies plans meet these criteria. |
| `verification-before-completion` | The plan-checker applies the verification gate to its own assessment. It cannot claim "plans pass" without having checked every dimension. |

### Active Iron Laws

- **Verification before completion:** The plan-checker must check every dimension for every plan before issuing a verdict. Skipping a dimension because "the plan looks fine" is not acceptable.
- **Structural quality, not content judgment:** The plan-checker assesses whether plans are structurally complete and correctly ordered, not whether the technical approach is optimal. If a plan has complete tasks with file lists, verification commands, and acceptance criteria, the plan-checker passes it — even if the plan-checker would have chosen a different library.

### Mindset

The plan-checker operates with the mindset: "Plans describe intent. I verify they deliver." A plan can have all tasks filled in but still miss the goal if key requirements lack tasks, tasks exist but do not actually achieve the requirement, dependencies are broken, artifacts are planned but wiring between them is absent, or scope exceeds the executor's context budget.

---

## 8-Dimension Verification

The plan-checker evaluates every plan against eight quality dimensions. Each dimension checks a different aspect of plan quality. Issues are categorized by severity: **blocker** (must fix before execution), **warning** (should fix, execution may degrade), or **info** (improvement suggestion).

### Dimension 1: Requirement Coverage

**Question:** Does every requirement have task(s) addressing it?

The plan-checker extracts requirement IDs from the roadmap and verifies each appears in at least one plan's `requirements` frontmatter field. Requirements with zero covering tasks are blockers. Requirements partially covered (login exists but logout does not) are blockers. Multiple requirements sharing one vague task ("implement auth" for login, logout, and session) are warnings.

### Dimension 2: Task Completeness

**Question:** Does every task have Files + Action + Verify + Done?

Each task is checked for its four required fields. Missing verification commands are blockers (the executor cannot confirm completion). Vague actions ("implement auth" instead of specific steps) are warnings. Empty file lists are blockers (the executor does not know what to create).

### Dimension 3: Dependency Correctness

**Question:** Are plan dependencies valid and acyclic?

The plan-checker builds a dependency graph from plan frontmatter, checks for circular dependencies (blocker), references to non-existent plans (blocker), and wave assignments inconsistent with dependency ordering (warning).

### Dimension 4: Key Links Planned

**Question:** Are artifacts wired together, not just created in isolation?

The plan-checker verifies that components are connected to their data sources, API routes are connected to their consumers, forms have submit handlers that process data, and state variables are rendered in the UI. Artifacts created but never imported or consumed are warnings. Critical wiring gaps (component created but not connected to its API) are blockers.

### Dimension 5: Scope Sanity

**Question:** Will plans complete within the executor's context budget?

The plan-checker applies thresholds: 2-3 tasks per plan (target), 5-8 files per plan (target), completion within ~50% context budget. Plans with 5+ tasks are warnings. Plans with 15+ file modifications are blockers. Complex work (auth, payments) crammed into one plan is a warning.

### Dimension 6: Verification Derivation

**Question:** Do must-haves trace back to the phase goal?

The plan-checker verifies each plan has a must-haves block, truths are user-observable (not implementation details like "bcrypt installed" but behavioral outcomes like "passwords are secure"), artifacts support the truths, and key links connect artifacts to functionality.

### Dimension 7: Context Compliance

**Question:** Do plans honor user decisions from the discuss phase?

Active only when CONTEXT.md exists. The plan-checker verifies every locked decision (D-XX) has an implementing task, no task implements a deferred idea (scope creep), and discretion areas are handled by the planner. Decision contradictions (user said "card layout", plan says "table layout") are blockers.

### Dimension 8: Plan Specificity

**Question:** Could a different agent instance execute this without asking clarifying questions?

The plan-checker applies the specificity standard: task actions must include concrete library names, specific endpoint paths, exact validation rules, and error handling approaches. Vague actions that require interpretation are warnings. Actions that reference undefined terms or missing context are blockers.

---

## 3-Iteration Revision Loop

The plan-checker and planner operate in a bounded revision loop:

1. **Iteration 1:** Plan-checker evaluates all plans across all 8 dimensions. Issues are reported to the planner with severity, dimension, and fix hints.
2. **Iteration 2:** Planner addresses issues and resubmits. Plan-checker re-evaluates, focusing on previously flagged dimensions plus regression checks on others.
3. **Iteration 3 (final):** If issues remain, the plan-checker issues a final verdict. Remaining blockers trigger FAIL (plans cannot proceed to execution). Remaining warnings trigger PASS with noted concerns.

The revision loop is bounded at 3 iterations to prevent infinite refinement. If plans cannot pass after 3 iterations, the issue is likely architectural (the plan approach is wrong, not the plan details) and requires human intervention or a planning restart.

---

## Mode-Specific Behavior

### Interactive Mode (Not Active)

The plan-checker agent is not spawned in interactive mode. Its function is served by the self-review checklist in the `writing-plans` skill. The primary agent applies the same quality dimensions through the skill's checklist rather than through an independent agent. This is sufficient because a human developer is present to catch issues the self-review misses.

### Orchestrated Mode

In orchestrated mode, the plan-checker is spawned as an independent agent with read-only access to the plans (it cannot modify them). Key characteristics:

- The plan-checker receives all PLAN.md files, the phase goal from ROADMAP.md, user decisions from CONTEXT.md, and requirement IDs from REQUIREMENTS.md
- Evaluation is exhaustive — all 8 dimensions are checked for all plans
- The revision loop is managed by the orchestrator (planner and plan-checker do not communicate directly)
- The plan-checker's verdict determines whether execution proceeds

---

## Cross-References

- `design/architecture-overview.md` — Agent Registry entry #3 (plan-checker with 8-dimension verification)
- `design/architecture-overview.md` — Pipeline Stages §3 (Plan) — plan verification gate
- `design/core-principles.md` — Principle 5 (Skills Are Tested Behavioral Specifications) — the `writing-plans` skill defines the quality standard the plan-checker enforces
- `design/verification-pipeline.md` — The plan-checker's goal-backward methodology parallels the verifier's approach, applied to plans rather than code
- Skills: `writing-plans`, `verification-before-completion`
