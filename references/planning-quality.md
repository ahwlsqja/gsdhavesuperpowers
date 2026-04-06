# Planning Quality

## Content Scope

This reference defines the structural quality dimensions against which all plans are evaluated before execution. It merges GSD's 8-dimension plan-checker verification with Superpowers' self-review checklist into a unified quality standard. The dimensions check structural completeness, not technical approach — a plan with all tasks properly specified passes even if the plan-checker would have chosen a different library.

**What belongs here:** Quality dimension definitions, severity classifications, threshold values, and evaluation criteria. The shared knowledge that both the plan-checker agent (external verification) and the planner agent (self-review) need.

**What does NOT belong here:** The plan-checker's revision loop protocol (that is in the plan-checker agent spec), the planner's goal-backward methodology (that is in the planner agent spec), or the behavioral protocol for writing plans (that is in the `writing-plans` skill).

---

## The 8 Quality Dimensions

### Dimension 1: Requirement Coverage

**Question:** Does every requirement have task(s) addressing it?

Each requirement from the task scope must map to at least one plan task. Requirements with zero covering tasks are blockers. Requirements partially covered (e.g., login exists but logout does not) are blockers. Multiple requirements sharing one vague task ("implement auth" for login, logout, and session management) are warnings — they indicate insufficient decomposition.

**Severity:** Blocker (missing coverage) / Warning (shared vague tasks)

### Dimension 2: Task Completeness

**Question:** Does every task have Files + Action + Verify + Acceptance Criteria?

Each task is checked for four required fields. Missing verification commands are blockers because the executor cannot confirm completion without them. Vague actions ("implement auth" instead of concrete steps) are warnings. Empty file lists are blockers because the executor does not know what to create or modify.

**Severity:** Blocker (missing required fields) / Warning (vague content)

### Dimension 3: Dependency Ordering

**Question:** Are dependencies valid and acyclic?

Plans with dependencies must form a directed acyclic graph. Circular dependencies are blockers. References to non-existent plans or tasks are blockers. Wave assignments inconsistent with dependency ordering (a task in Wave 1 depending on a Wave 2 output) are warnings.

**Severity:** Blocker (cycles, invalid references) / Warning (wave inconsistencies)

### Dimension 4: Key Links (Wiring)

**Question:** Are artifacts wired together, not just created in isolation?

Plan tasks must connect components to their data sources, API routes to their consumers, forms to submit handlers, and state to rendering. Artifacts created but never imported or consumed are warnings. Critical wiring gaps (a component created but not connected to its API endpoint) are blockers.

**Severity:** Blocker (critical disconnections) / Warning (unused artifacts)

### Dimension 5: Scope Sanity (Context Fit)

**Question:** Will the plan complete within the executor's context budget?

Plans are evaluated against scope thresholds to prevent quality degradation from context exhaustion:

| Metric | Target | Warning | Blocker |
|--------|--------|---------|---------|
| Tasks per plan | 2–3 | 4 | 5+ |
| Files per plan | 5–8 | 10 | 15+ |
| Estimated context consumption | ~50% | ~70% | 80%+ |

Complex domains (authentication, payment processing, real-time communication) crammed into a single plan are warnings regardless of task count, because domain complexity amplifies context pressure.

**Severity:** Blocker (5+ tasks, 15+ files) / Warning (4 tasks, 10+ files, complex domains)

### Dimension 6: Verification Derivation

**Question:** Do verification criteria trace back to the stated goal?

Plan verification criteria must be user-observable outcomes, not implementation details. "User can log in with email and password" is a valid truth. "bcrypt library is installed" is an implementation detail that does not confirm goal achievement. Artifacts must support the stated truths, and key links must connect artifacts to functionality.

**Severity:** Warning (implementation-focused criteria) / Blocker (missing verification criteria entirely)

### Dimension 7: Context Compliance

**Question:** Do plans honor prior decisions and constraints?

When project context includes locked decisions, the plan must implement every decision. No task may contradict a locked decision. No task may implement ideas that were explicitly deferred (scope creep). The planner may use discretion in areas marked for agent judgment.

This dimension also checks for scope reduction — plans that reference a decision but deliver only a fraction of what was decided. Scope reduction (e.g., a decision says "dynamic pricing display" but the plan says "static labels, dynamic pricing is a future enhancement") is always a blocker. Planners must not invent version splits that do not exist in the original decisions.

**Severity:** Blocker (contradictions, deferred idea inclusion, scope reduction) / Warning (discretion area handling)

### Dimension 8: Plan Specificity (Nyquist Compliance)

**Question:** Could a different agent instance execute this plan without asking clarifying questions?

Task actions must include concrete library names, specific endpoint paths, exact validation rules, error handling approaches, and enough detail that execution is deterministic. Vague actions that require interpretation are warnings. Actions referencing undefined terms or missing context are blockers.

Additionally, verification commands must be automated and fast. Plans relying solely on full end-to-end test suites for verification are warned to include faster unit or smoke tests. Consecutive implementation tasks without automated verification checks violate the sampling continuity requirement.

**Severity:** Blocker (ambiguous actions, missing automated verification) / Warning (slow verification, vague specifics)

---

## Self-Review Checklist

The planner applies these dimensions as a self-review before submitting plans for external verification. The self-review uses the same dimensions as the plan-checker but operates as an internal quality gate rather than an external audit.

**Self-review sequence:**
1. Trace each requirement to its covering task(s) — any gaps?
2. Check each task for files, action, verify, acceptance criteria — any blanks?
3. Draw the dependency graph mentally — any cycles or invalid references?
4. For each created artifact, identify its consumer — any islands?
5. Count tasks and files — does this fit in the executor's context budget?
6. Read each verification criterion — is it user-observable or implementation-focused?
7. Cross-check against locked decisions — any contradictions or omissions?
8. Read each action as if you have zero context — could you execute it?

If any dimension fails self-review, the planner revises before submission. The plan-checker then performs the same checks independently, catching issues the planner's self-review missed.

---

## Revision Loop

The plan-checker and planner operate in a bounded revision loop:

- **Iteration 1:** Full 8-dimension evaluation. Issues reported with severity and fix hints.
- **Iteration 2:** Re-evaluation focusing on previously flagged dimensions plus regression checks.
- **Iteration 3 (final):** Remaining blockers trigger FAIL. Remaining warnings trigger PASS with noted concerns.

The loop is bounded at 3 iterations to prevent infinite refinement. If plans cannot pass after 3 iterations, the issue is likely architectural (wrong approach, not wrong details) and requires human intervention.

---

## Usage Patterns

**When loaded:** On demand by the plan-checker agent (every verification pass) and by the planner agent (self-review). The orchestrator references these dimensions when deciding whether to proceed to execution.

**How agents use it:** As a dimension checklist — each dimension is evaluated independently, and the aggregate result determines the plan verdict (PASS/REVISE/FAIL).

---

## Maintenance Rules

**When to update:** When new plan quality failures are observed that the existing 8 dimensions do not catch. New dimensions must demonstrate a repeating failure pattern, not a one-time incident.

**Who updates:** The plan-checker agent author and the writing-plans skill author. Both must stay synchronized — the same quality standard must apply whether verification is external (plan-checker) or internal (self-review).

---

## Cross-References

- `design/agent-specs/plan-checker.md` — Plan-checker agent implementing 8-dimension verification
- `design/agent-specs/planner.md` — Planner agent applying self-review checklist
- `design/architecture-overview.md` — Pipeline Stages §3 (Plan verification gate)
- `design/verification-pipeline.md` — Verification levels by artifact type (design documents require Level 2)
- Skill: `writing-plans` — Behavioral protocol for creating execution-ready plans
- Skill: `verification-before-completion` — The verification gate that the plan-checker itself must follow
