# Reference Specification: Model Profiles

**Name:** `model-profiles`
**Scope:** Per-agent model tier assignments across profiles (quality/balanced/budget/inherit), resolution rules, and override mechanisms
**Loading Behavior:** Cold-tier — loaded by orchestrator during agent spawning, by configuration tools during profile selection
**Consumers:** Orchestrator agent (model resolution before spawning), profiler agent (resource tracking), all agents (via inherit fallback)
**Research Grounding:** GSD's `model-profiles.md` reference (139 lines); architecture-overview.md §Reference Documents entry 5

---

## Content Scope

This reference defines how model tiers are assigned to each agent in the unified 12-agent registry across four named profiles. It specifies the resolution logic the orchestrator uses when spawning agents, per-agent override syntax, and the rationale for tier assignments.

**What belongs here:** The profile table mapping agents to model tiers, profile philosophy descriptions, resolution order, override configuration format, and non-Anthropic runtime considerations.

**What does NOT belong here:** Agent behavioral specifications (those are in individual agent specs), context budget calculations (those are in the `context-budget` reference), or verification pipeline logic (that is in the `verification-patterns` and `repair-strategies` references).

---

## Profile Definitions

The unified 12-agent registry maps each agent to a model tier across four named profiles:

| Agent | `quality` | `balanced` | `budget` | `inherit` |
|-------|-----------|------------|----------|-----------|
| researcher | opus | sonnet | haiku | inherit |
| planner | opus | opus | sonnet | inherit |
| plan-checker | sonnet | sonnet | haiku | inherit |
| executor | opus | sonnet | sonnet | inherit |
| verifier | sonnet | sonnet | haiku | inherit |
| reviewer | opus | sonnet | sonnet | inherit |
| debugger | opus | sonnet | sonnet | inherit |
| mapper | sonnet | haiku | haiku | inherit |
| auditor | sonnet | sonnet | haiku | inherit |
| doc-writer | sonnet | sonnet | haiku | inherit |
| orchestrator | opus | opus | sonnet | inherit |
| profiler | sonnet | haiku | haiku | inherit |

---

## Profile Philosophy

**quality** — Maximum reasoning power. Opus for all decision-making agents (planner, executor, reviewer, debugger, orchestrator). Sonnet for verification and read-only agents. Use when quota is available and work involves critical architecture decisions.

**balanced** (default) — Smart tier allocation. Opus only for planning and orchestration where architecture decisions happen. Sonnet for execution, research, and verification where agents follow explicit instructions but need reasoning capability. Haiku for read-only exploration agents (mapper, profiler). Represents the best trade-off between quality and cost for normal development.

**budget** — Minimal high-tier usage. Sonnet for anything that writes or modifies code. Haiku for research, verification, and mapping. Use when conserving quota, during high-volume work, or for less critical phases.

**inherit** — All agents resolve to the session's currently active model. Required when using non-Anthropic providers (OpenRouter, local models) to prevent unexpected cross-provider API calls. Also useful when the runtime allows interactive model switching.

---

## Resolution Logic

The orchestrator resolves the model tier before spawning each agent using this precedence order:

1. Check per-agent overrides in configuration (`model_overrides` map)
2. If no override exists, look up the agent in the active profile table
3. If profile returns `inherit`, resolve to the session's current model
4. Pass the resolved model identifier to the agent spawn call

Per-agent overrides take precedence over profile defaults. Valid override values include named tiers (`opus`, `sonnet`, `haiku`, `inherit`) or fully-qualified model identifiers for cross-provider scenarios.

---

## Tier Assignment Rationale

**Why Opus for planner and orchestrator?** Planning involves architecture decisions, goal decomposition, and task design. Orchestration involves wave analysis, dependency resolution, and repair operator decisions. These are where model quality has the highest impact on downstream work quality.

**Why Sonnet (not Haiku) for verifier in balanced?** Verification requires goal-backward reasoning — checking whether code delivers what the task promised, not just pattern matching. Sonnet handles this well; Haiku may miss subtle verification gaps.

**Why Haiku for mapper and profiler?** These agents perform read-only exploration and structured output extraction. No reasoning-intensive decisions are required — they navigate file trees and emit structured inventories.

**Why inherit as a complete profile?** Some runtimes allow interactive model switching. The inherit profile keeps all agents aligned to the user's live selection. It also prevents cross-provider cost surprises when using non-Anthropic backends.

---

## Non-Anthropic Runtime Considerations

When installed for a non-Claude runtime (Codex, Gemini CLI, or other providers), the model resolution emits empty model parameters so each agent uses the runtime's default model. Specific agents can be overridden with model identifiers the runtime recognizes, applying the same tiering logic: stronger models for planning and debugging, cheaper models for execution and mapping.

---

## Cross-References

- **Agent specs (all 12):** Each agent spec declares its model tier in the capability contract header
- **`context-budget` reference:** Context window sizes vary by model tier, affecting degradation calculations
- **Orchestrator agent spec:** §Model Resolution implements the resolution logic described here
- **Profiler agent spec:** Tracks token consumption per model tier for cost attribution
