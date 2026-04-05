# Reference Specification: Context Budget

**Name:** `context-budget`
**Scope:** Context window management rules — read-depth scaling, degradation tiers, cache-friendly ordering, and behavioral adjustments under pressure
**Loading Behavior:** On demand — loaded by agents experiencing context pressure or by the context-management skill
**Consumers:** Orchestrator agent (context enrichment decisions), executor agent (read-depth selection), all agents via `context-management` skill
**Research Grounding:** GSD's `context-budget.md`; Codified Context Infrastructure three-tier memory model (Vasilopoulos, 2026); SYN-03 managed context with high-density content

---

## Content Scope

This reference provides the operational rules for managing context window consumption across all agents and modes. It defines how read depth scales with available context, what behavioral adjustments agents must make as context fills, and how to order content for maximum cache efficiency.

**What belongs here:** Quantitative thresholds, tier definitions, read-depth scaling tables, and behavioral adjustment rules. Domain-neutral knowledge about context management that any agent may need.

**What does NOT belong here:** The behavioral enforcement protocol for context awareness (that is in the `context-management` skill), agent-specific context enrichment decisions (those are in the orchestrator agent spec), or the three-tier memory model architecture (that is in the architecture overview).

---

## Read-Depth Scaling

Context window size determines how deeply agents read prior artifacts. The orchestrator uses these rules when assembling context for spawned agents. Individual agents use them when deciding whether to read full files or frontmatter only.

| Context Window | Subagent Output | SUMMARY.md | VERIFICATION.md | PLAN.md (other tasks) |
|---------------|----------------|------------|-----------------|----------------------|
| < 500K tokens (Standard models) | Frontmatter only | Frontmatter only | Frontmatter only | Current task scope only |
| ≥ 500K tokens (Large-context models) | Full body permitted | Full body permitted | Full body permitted | Current task scope only |

**Detection method:** Check the model's context window capacity from the active model profile. If unknown, default to the conservative tier (< 500K) to prevent context exhaustion.

**Transitive dependency rule:** Regardless of context window size, artifacts from two or more dependency hops back (transitive dependencies) are always read at frontmatter depth only. Only direct dependency outputs may receive full-body reads in large-context models.

---

## Context Degradation Tiers

Agents must monitor their context consumption and adjust behavior as capacity fills. These tiers define the behavioral contract at each consumption level.

### Tier: PEAK (0–30% consumed)

Full operational capacity. All read modes available.

- Read full artifact bodies when needed for decision-making
- Spawn multiple subagents when parallelism benefits the task
- Inline results from subagent output for synthesis
- Perform comprehensive verification with full output inspection

### Tier: GOOD (30–50% consumed)

Normal operations with proactive efficiency.

- Prefer frontmatter reads over full-body reads when frontmatter is sufficient
- Delegate aggressively to subagents rather than performing work inline
- Limit inlining of subagent results — summarize instead of quoting
- Begin prioritizing high-value context over comprehensive coverage

### Tier: DEGRADING (50–70% consumed)

Economize actively. Context pressure is affecting quality.

- Frontmatter-only reads for all artifacts except the current task's direct inputs
- Minimal inlining — reference artifacts by path rather than quoting content
- Warn the user (or orchestrator) about budget pressure: "Context budget is heavy. Consider checkpointing."
- Reduce verification depth: focus on critical checks, defer comprehensive sweeps
- Do not start new investigations or research tangents

### Tier: POOR (70%+ consumed)

Emergency mode. Checkpoint immediately.

- Stop all non-critical reads. No new file reads unless directly required to complete the current step
- Checkpoint progress immediately — write partial results to disk before context is lost
- No new subagent spawning — complete current work with available context
- If verification is incomplete, note which checks remain and write them to the handoff document
- Priority: preserve completed work over attempting additional work

---

## Context Degradation Warning Signs

Quality degrades gradually before tier thresholds trigger explicit warnings. Early signals to watch for:

**Silent partial completion:** The agent claims a task is done but the implementation is incomplete. The self-check catches file existence but not semantic completeness. When this pattern appears, suspect context pressure even if the tier threshold has not been formally crossed.

**Increasing vagueness:** The agent begins using phrases like "appropriate handling," "standard patterns," or "as expected" instead of specific code references, exact function names, or concrete verification output. Vague language in agent output correlates with context pressure.

**Skipped steps:** The agent omits protocol steps it would normally follow. If a verification protocol has 5 steps but the agent reports only 3, the omitted steps were likely lost to context pressure rather than consciously skipped.

**Repetitive re-reading:** The agent reads the same file multiple times because it lost the content from earlier reads. Repeated reads of the same artifact indicate context recycling and approaching capacity limits.

---

## Cache-Friendly Ordering Principles

When assembling context for agents (especially in orchestrated mode), content ordering affects cache hit rates and processing efficiency.

**Principle 1 — Stable content first.** Iron laws, gate functions, and project constraints change rarely and should appear early in context. This maximizes the portion of context that remains cache-valid across multiple agent invocations.

**Principle 2 — Task-specific content last.** The current task plan, file contents, and recent outputs are unique to each invocation and should appear at the end of the context assembly. This ensures the stable prefix remains cacheable even when task content changes.

**Principle 3 — Reference documents in the middle.** References are loaded on demand and vary by task, but less frequently than task-specific content. Placing them between stable behavioral content and volatile task content optimizes the cache boundary.

**Ordering template:**
1. Iron laws + gate functions (hot tier — stable)
2. Project constraints + knowledge base (warm tier — semi-stable)
3. Reference documents (cold tier — loaded on demand)
4. Task plan + current context (volatile — changes per invocation)

---

## Context Budget for Verification

Verification cycles consume context. The following thresholds prevent verification from consuming the entire session:

| Signal | Threshold | Action |
|--------|-----------|--------|
| Verification consuming notable portion of budget | 30% of remaining context | Warning: "Verification is consuming significant context. Consider simplifying checks." |
| Verification dominating budget | 40% of remaining context | Force PRUNE: stop verification and escalate regardless of retry budget |
| Multiple verification failures | 3+ RETRY attempts without resolution | Escalate to DECOMPOSE regardless of remaining budget |

These thresholds interact with the degradation tiers — an agent in DEGRADING tier that enters a verification cycle is more likely to hit the 40% threshold and should plan accordingly.

---

## Usage Patterns

**When loaded:** On demand when an agent or skill needs to make a context-depth decision. The `context-management` skill references this document for threshold values. The orchestrator references it when assembling spawned agent context.

**How agents use it:** As a lookup table for behavioral adjustments. When an agent notices context pressure signals, it loads this reference to determine the correct tier and adjust behavior accordingly.

---

## Maintenance Rules

**When to update:** When empirical observation reveals that tier thresholds are too aggressive (causing premature checkpointing) or too permissive (allowing quality degradation before warnings fire). M003 empirical validation may produce threshold adjustments.

**Who updates:** The orchestrator implementation team and the context-management skill author. Threshold changes should be based on observed agent behavior across multiple sessions, not theoretical reasoning.

**Measurement guidance:** Track the correlation between context consumption percentage and output quality metrics (verification pass rate, stub detection misses, skipped steps). Adjust tier boundaries to align with observed quality inflection points.

---

## Cross-References

- `design/architecture-overview.md` — Three-Tier Memory Model (Hot/Warm/Cold) and Context Delivery by Mode
- `design/agent-specs/orchestrator.md` — Context enrichment assembly for spawned agents
- `design/agent-specs/executor.md` — Read-depth decisions during task execution
- `design/agent-specs/profiler.md` — Behavioral pattern analysis including context usage patterns
- Skill: `context-management` — Behavioral enforcement of degradation-tier adjustments
- Reference: `anti-patterns` — Context budget anti-patterns (rules 1–5)
