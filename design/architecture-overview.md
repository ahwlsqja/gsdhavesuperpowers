# Architecture Overview: Unified AI Coding Agent Methodology

**Version:** 0.1 — Draft specification for M002 design validation
**Status:** Initial architecture specification; component details will be elaborated in S02 (skills) and S03 (agents & references)
**Audience:** Developers encountering the methodology for the first time, and agents consuming it as operational context

---

## Introduction & Design Philosophy

This document defines the architecture for a unified AI coding agent methodology that merges two systems: **GSD** (programmatic infrastructure for multi-agent orchestration, persistent state, and automated verification) and **Superpowers** (behavioral shaping through iron laws, rationalization prevention, and gate functions). Neither system alone is sufficient — GSD's infrastructure catches failure modes agents cannot self-recognize, while Superpowers' behavioral conditioning ensures agents care about quality in the first place.

Three meta-patterns from the M001 comparative analysis organize the architecture:

1. **Infrastructure vs Psychology.** GSD operates through code (lockfiles, CLI tools, automated verification). Superpowers operates through prose (iron laws, rationalization prevention tables, gate functions). These are complementary — infrastructure catches what psychology misses (state corruption, stub detection, concurrent access), and psychology catches what infrastructure misses (reasoning quality, verification discipline, resistance to shortcuts). The unified methodology requires both.

2. **Complexity vs Portability.** GSD's 21 agents, 60 workflows, and 16,623-line SDK provide powerful capabilities at significant complexity cost. Superpowers' 14 skill files achieve comparable behavioral outcomes with zero runtime code. The unified methodology calibrates complexity to the capabilities actually needed — it uses Superpowers' minimalism as a design pressure against unnecessary infrastructure while preserving the capabilities (parallelism, persistent state, programmatic verification) that only infrastructure can provide.

3. **Breadth vs Depth.** GSD covers more dimensions (state, context, orchestration, security, 42 templates, 25 references). Superpowers goes deeper on fewer topics (TDD has a 12-row rationalization prevention table; verification has a gate function built from 24 failure memories). The unified methodology adopts GSD's breadth for system-level concerns and Superpowers' depth for behavior-level concerns.

### Why Two Layers

The architecture is organized into two composable layers:

- **Behavioral Layer** — Zero-dependency Markdown skill files containing iron laws, rationalization prevention tables, gate functions, and process protocols. This layer works standalone on any platform that reads Markdown. It defines *what agents should do* and *how they should think while doing it*.

- **Infrastructure Layer** — A Claude Code extension providing hooks, CLI tools, state management, and the multi-agent execution harness. This layer requires Node.js and amplifies the behavioral layer with enforcement guarantees, persistence, and programmatic verification. It ensures agents *actually do* what the behavioral layer prescribes.

A developer using only the behavioral layer gets a useful methodology. Adding the infrastructure layer makes it robust. The behavioral layer is never optional; the infrastructure layer degrades gracefully when unavailable.

---

## Unified Vocabulary

GSD and Superpowers use overlapping terminology with different meanings. The following definitions resolve every collision. All components in this methodology use these definitions exclusively.

### Core Terms

| Term | Unified Definition | GSD Usage | Superpowers Usage |
|------|-------------------|-----------|-------------------|
| **Skill** | A Markdown document containing behavioral directives (iron laws, gate functions, rationalization prevention) that shape agent reasoning. Zero runtime dependencies. Loaded into context on demand. | Not used (closest: "reference") | Core unit — 14 skill files |
| **Agent** | A declarative definition (Markdown/YAML) combining capability specification (role, tools, model tier, completion markers) with behavioral specification (which skills govern this agent's behavior). Agents are spawned as subprocesses with fresh context. | 21 specialized agent files with capability contracts | 1 agent (`code-reviewer`); skills serve the agent specialization role |
| **Reference** | A shared knowledge document loaded into agent context to provide domain-specific information (verification patterns, context budgets, anti-patterns). References contain knowledge; skills contain behavioral directives. | 25 reference documents loaded via `@-reference` syntax | Not used (knowledge is embedded in skills) |
| **Verification** | The dual-layer process of confirming work quality. Layer 1 (behavioral): the gate function ensuring the agent runs commands, reads output, and claims honestly. Layer 2 (programmatic): independent codebase inspection for stubs, empty handlers, wiring gaps, and data flow. | 4-level model (Exists → Substantive → Wired → Functional) plus stub detection | 5-step gate (IDENTIFY → RUN → READ → VERIFY → CLAIM) with "lying, not verifying" framing |
| **Plan** | A structured specification of work to be done, containing tasks with explicit file lists, verification commands, and expected outputs. Plans are written to the bar of "an engineer with zero context and questionable taste" and verified against structural quality dimensions before execution. | PLAN.md with XML task elements, 8-dimension plan checker, 3-iteration revision loop | Writing-plans skill with 2–5 minute task granularity, no-stub mandate |
| **Gate** | A structural barrier in the execution pipeline that prevents progression until conditions are met. Gates are behavioral (prose-enforced) and optionally infrastructure-backed (programmatically enforced). | Implicit in pipeline structure (plan-checker must pass before execution) | Explicit gate functions (brainstorming hard gate, verification gate) |
| **Iron Law** | An absolute behavioral constraint that cannot be rationalized away. Accompanied by a rationalization prevention table enumerating known evasion patterns with corrections. Active at all state tiers and in all execution modes. | Not used (closest: anti-pattern rules in `universal-anti-patterns.md`) | Core mechanism — 3 iron laws (TDD, debugging, verification) |
| **Hook** | A runtime integration point that executes code at specific events (session start, tool use, context threshold). Hooks deliver behavioral reinforcement, monitor context budgets, and scan for security threats. | 9 hooks (context-monitor, prompt-guard, statusline, etc.) | 1 hook (session-start for skill loading) |
| **Template** | A pre-structured Markdown file with `{{variable}}` substitution for consistent artifact formatting. Templates are infrastructure for knowledge capture, not behavioral directives. | 42 templates across 7 categories | Not used |
| **Mode** | The execution model selected for a task or project. Interactive mode: single agent with skill loading. Orchestrated mode: multi-agent pipeline with fresh context per agent. | Multi-agent orchestration is the default model | Single-agent skill loading is the default model |
| **State Tier** | The level of persistent state maintained for a project. Tier 0: stateless. Tier 1: lightweight (3 Markdown files). Tier 2: full orchestration with lockfile-based concurrency. | Full state always (equivalent to Tier 2 only) | Stateless always (equivalent to Tier 0 only) |

### Disambiguation Notes

- **"Verification"** always means both layers. When referring to a single layer, use "behavioral verification" (gate function) or "programmatic verification" (independent codebase inspection).
- **"Agent"** always means a spawnable definition with both capability and behavioral specs. It does not mean "the AI model itself" — that is the "model" or "underlying model."
- **"Skill"** is never used to mean "capability" or "competence." It always refers to a specific Markdown document containing behavioral directives.
- **"Plan"** does not mean "rough outline" or "intention." It means a verified, execution-ready task decomposition with concrete file lists, commands, and success criteria.

---

## Execution Modes

The methodology supports two execution modes that share the same behavioral protocol but differ in orchestration infrastructure.

### Interactive Mode

**Derived from:** Superpowers' single-agent skill loading model
**When to use:** Focused development sessions, pair programming, bug fixes, feature implementation where the developer is actively engaged.

In interactive mode, a single agent operates within one context window. The agent loads relevant skills at task boundaries and follows their behavioral directives. The developer is the coordinator — they guide task selection, review output, and make judgment calls.

**How it works:**
1. The agent loads the `using-superpowers` meta-skill at session start (via session-start hook)
2. As work progresses, the agent invokes relevant skills: `brainstorming` for new features, `writing-plans` for task decomposition, `verification-before-completion` before any completion claim
3. When tasks benefit from fresh context, the agent dispatches subagents per the `subagent-driven-development` skill
4. The two-stage review protocol (spec compliance → code quality) provides quality assurance on subagent output
5. The four-status implementer protocol (DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED) structures subagent reporting

**Agent definitions in interactive mode:** Agent specs are not formally spawned as separate processes. Instead, the single primary agent *adopts* the behavioral specification of the relevant agent definition by loading its skills. In effect, the agent becomes a "TDD practitioner," "systematic debugger," or "code reviewer" by loading the corresponding skill set. The capability specification (model tier, tool permissions) is inherited from the session context.

**State tier:** Typically Tier 0 (stateless) or Tier 1 (lightweight). The developer manages persistence through project artifacts (spec docs, knowledge files) rather than methodology state machinery.

### Orchestrated Mode

**Derived from:** GSD's multi-agent pipeline with wave-based parallelism
**When to use:** Autonomous multi-phase execution, complex multi-task milestones, unattended batch processing where the developer is not actively watching.

In orchestrated mode, a thin orchestrator spawns specialized agents with fresh context windows. Each agent gets a clean context (eliminating accumulated confusion), focused context (only the artifacts relevant to its task), and behavioral conditioning (iron laws and gate functions injected into its prompt).

**How it works:**
1. The orchestrator reads the milestone roadmap and decomposes into slices and tasks
2. Tasks are analyzed for dependencies and grouped into waves (independent tasks run in parallel, dependent tasks wait for predecessors)
3. For each task, the orchestrator spawns a fresh agent with: the task plan, project context (scaled by context window size), and the behavioral specification from the relevant agent definition
4. Each spawned agent follows the same iron laws and gate functions as in interactive mode — the behavioral content is identical, only the delivery mechanism changes (injected into prompt rather than loaded via skill invocation)
5. Results are collected via completion markers and handoff contracts
6. An independent verifier agent checks results with a distrust mindset — it does not trust executor claims in summary documents

**Agent definitions in orchestrated mode:** Agent specs are formally instantiated. Each spawned agent receives its capability specification (which tools it can use, what model tier to run on) and its behavioral specification (which iron laws apply, which gate functions to enforce). The orchestrator resolves model assignments from the active model profile.

**State tier:** Always Tier 2 (full orchestration). The infrastructure layer manages state, lockfiles, wave coordination, and session continuity.

### Mode Selection Heuristics

The following heuristics are **candidates for M003 empirical validation** — they reflect reasonable engineering judgment but have not been tested against real-world usage data.

| Signal | Suggested Mode | Confidence |
|--------|---------------|------------|
| Developer is actively present and guiding work | Interactive | High |
| Auto-mode activated on a multi-slice milestone | Orchestrated | High |
| Single-file bug fix or config change | Interactive | High |
| Multi-phase project with 5+ tasks across 3+ files | Orchestrated | Medium |
| First-time project setup (needs human decisions) | Interactive | High |
| Regression fix on known codebase | Either — depends on scope | Low |

**Mode override:** The developer can always override automatic mode selection. The heuristics suggest; the developer decides.

### Shared Behavioral Protocol

Regardless of mode, the following behavioral elements are always active:

- **Iron laws:** Verification before completion, root-cause-first debugging, TDD when applicable
- **Gate functions:** Brainstorming gate for new features, verification gate for completion claims
- **Rationalization prevention:** All prevention tables are active, intercepting known evasion patterns
- **Skill priority ordering:** Process skills (brainstorming, debugging) before implementation skills (frontend design, infrastructure)
- **The 1% invocation threshold:** If there is even a 1% chance a skill applies, it must be invoked

The behavioral protocol is the constant; the execution infrastructure is the variable.

---

## Component Map

This section enumerates every planned component in the unified methodology. Each component is named and categorized but not fully specified — detailed specifications follow in S02 (skills) and S03 (agents and references).

### Skill Catalog

Skills are categorized by type following Superpowers' priority ordering: process skills (determine HOW to approach work) are always loaded before implementation skills (guide execution details).

#### Process Skills (Load First)

| # | Skill Name | One-Line Description | Research Grounding |
|---|-----------|---------------------|-------------------|
| 1 | `using-methodology` | Meta-skill establishing invocation protocol, 1% threshold, priority ordering, and red-flag rationalization matrix | Superpowers' `using-superpowers` meta-skill; CSO discovery about description-vs-content behavior |
| 2 | `brainstorming` | Hard gate preventing implementation before design approval; 9-step design exploration and spec writing | Superpowers' `brainstorming` skill; SYN-07 programmatically enforced behavioral gates |
| 3 | `writing-plans` | Execution-ready task decomposition with no-stub mandate and 2–5 minute granularity | Superpowers' `writing-plans`; SYN-04 merger of GSD's 8-dimension structural checker with Superpowers' granularity standard |
| 4 | `verification-before-completion` | Dual-layer verification gate: behavioral (IDENTIFY→RUN→READ→VERIFY→CLAIM) + programmatic (Exists→Substantive→Wired→Functional) | SYN-01 P0 synergy; Superpowers' gate function merged with GSD's `gsd-verifier` 4-level model |
| 5 | `test-driven-development` | Iron law for TDD with 12-row rationalization prevention table and red-green-refactor flow | Superpowers' `test-driven-development` skill; Codified Expert Knowledge study's 206% improvement finding |
| 6 | `systematic-debugging` | Root-cause-first investigation with 8-row excuse/reality table and 12 red flags | Superpowers' `systematic-debugging`; SYN-11 structured failure recovery with disciplined investigation |
| 7 | `receiving-code-review` | Anti-sycophancy protocol prohibiting performative agreement; YAGNI checks against actual codebase usage | Superpowers' `receiving-code-review`; SYN-10 honest agent interactions |
| 8 | `requesting-code-review` | Structured review request template with git SHAs and verification references | Superpowers' `requesting-code-review`; SYN-10 formal agent contracts |
| 9 | `context-management` | Context budget awareness: degradation tiers (PEAK/GOOD/DEGRADING/POOR), read-depth scaling, checkpoint triggers | GSD's `context-budget.md` reference + context-monitor hook; SYN-03 managed context with high-density content |
| 10 | `knowledge-management` | Append-only knowledge register protocol with structured hindsight annotations and drift detection guidance | GSD's KNOWLEDGE.md + DECISIONS.md; SYN-02 persistent knowledge with behavioral enforcement; CCI three-tier model |

#### Implementation Skills (Load After Process Skills)

| # | Skill Name | One-Line Description | Research Grounding |
|---|-----------|---------------------|-------------------|
| 11 | `executing-plans` | Single-agent inline execution: load plan, critical review, step-by-step execution with deviation tracking | Superpowers' `executing-plans`; SYN-05 behavioral protocol for task execution |
| 12 | `subagent-driven-development` | Multi-agent execution: fresh subagent per task, two-stage review (spec compliance → code quality), four-status protocol | Superpowers' `subagent-driven-development`; SYN-05 orchestrated fresh-context execution |
| 13 | `writing-skills` | TDD-for-skills methodology: pressure scenarios → observe → write skill → verify → close loopholes | Superpowers' `writing-skills`; SYN-08 quality-assured knowledge artifacts; Principle 5 |
| 14 | `frontend-design` | UI implementation patterns with component architecture, accessibility, and visual polish | Superpowers' `frontend-design`; implementation-domain skill |
| 15 | `finishing-work` | Structured completion: verify tests → present options (merge/push/keep/discard) → cleanup | Superpowers' `finishing-a-development-branch`; post-execution workflow |
| 16 | `git-worktree-management` | Worktree isolation: directory selection, safety verification, auto-detection of project type, baseline tests | Superpowers' `using-git-worktrees`; workspace management |
| 17 | `security-enforcement` | Threat modeling requirements (STRIDE), prompt injection awareness, execution scope boundaries | GSD's security module + prompt-guard hook; SYN-09 defense-in-depth |
| 18 | `parallel-dispatch` | When and how to dispatch parallel subagents: independence criteria, prompt structure, result collection | Superpowers' `dispatching-parallel-agents`; GSD's wave-based parallelism |

**Note on skill count:** The synergy map analysis identified 15–20 potential skills based on mechanism inventory. This catalog lists 18. S02 may adjust the count during detailed specification — some skills may be merged if they share behavioral mechanisms, or split if a single skill covers too much ground. The catalog above is the starting enumeration, not the final count.

### Agent Registry

GSD defines 21 specialized agents. The unified methodology consolidates to 12 agents based on three principles: (a) merge agents that share the same behavioral protocol and differ only in domain focus, (b) eliminate agents whose function is subsumed by skills in the behavioral layer, (c) preserve agents whose independence is structurally important (verifiers must be separate from executors).

| # | Agent Name | Role | Mode(s) | Model Tier | Consolidation Rationale |
|---|-----------|------|---------|------------|------------------------|
| 1 | `researcher` | Investigate implementation approaches, analyze codebase, identify risks and patterns | Both | Standard | Merges GSD's 4 parallel researchers (`project-researcher`, `phase-researcher`, `ui-researcher`, `advisor-researcher`) + `research-synthesizer`. Domain-specific research focus is achieved through prompt parameterization, not separate agent definitions — validated by Confucius SDK's finding that a single parameterized agent outperforms class hierarchies. |
| 2 | `planner` | Create verified, execution-ready task decompositions from research output | Both | Capable | Preserves GSD's `gsd-planner` with its goal-backward methodology and scope reduction prohibition. The `writing-plans` skill provides the behavioral specification (granularity, no-stub mandate). |
| 3 | `plan-checker` | Verify plans against structural quality dimensions before execution begins | Orchestrated | Standard | Preserves GSD's `gsd-plan-checker` with 8-dimension verification and 3-iteration revision loop. In interactive mode, the plan self-review checklist from the `writing-plans` skill serves this function. |
| 4 | `executor` | Execute plan tasks: write code, run tests, produce artifacts, report deviations | Both | Standard | Preserves GSD's `gsd-executor` with deviation rules (auto-fix bugs, auto-add missing critical functionality, ask about architectural changes) and analysis paralysis guard. Behavioral specification via `executing-plans` and `verification-before-completion` skills. |
| 5 | `verifier` | Independently verify execution results with distrust mindset — does not trust executor claims | Orchestrated | Capable | Preserves GSD's `gsd-verifier` with 4-level verification plus data-flow trace. This agent's independence from the executor is structurally critical — self-verification is insufficient for autonomous execution (validated by SASE's speed-vs-trust gap). In interactive mode, the behavioral gate function plus programmatic checks replace the independent verifier. |
| 6 | `reviewer` | Code quality review with anti-sycophancy protocol: technical pushback required, YAGNI checks | Both | Capable | Merges GSD's doc-verifier function with Superpowers' `code-reviewer` agent. The anti-sycophancy behavioral specification from `receiving-code-review` skill is this agent's defining characteristic. |
| 7 | `debugger` | Systematic debugging with root-cause-first investigation, structured failure recovery | Interactive | Standard | Preserves GSD's `gsd-debugger`. Behavioral specification via `systematic-debugging` skill. Used interactively — orchestrated mode uses the repair operator (RETRY/DECOMPOSE/PRUNE) rather than interactive debugging. |
| 8 | `mapper` | Analyze existing codebase: technology stack, architecture patterns, conventions, quality concerns | Both | Standard | Merges GSD's 4 parallel mappers (`codebase-mapper` dimensions: tech, architecture, quality, concerns). Parameterized by mapping focus area. |
| 9 | `auditor` | Specialized auditing: security (STRIDE analysis), UI (6-pillar visual audit), integration checks | Orchestrated | Capable | Merges GSD's `security-auditor`, `ui-auditor`, `ui-checker`, `integration-checker`, `nyquist-auditor`. Audit type is parameterized. |
| 10 | `doc-writer` | Generate and maintain project documentation | Both | Standard | Preserves GSD's `gsd-doc-writer`. Documentation is generated from execution artifacts rather than written from scratch. |
| 11 | `orchestrator` | Coordinate multi-agent pipeline: wave analysis, agent spawning, result collection, state management | Orchestrated | Capable | Not a spawned agent — this is the control loop in orchestrated mode. Thin by design: coordinates but does not execute. Implements GSD's wave-based parallelism, model resolution, and context enrichment. |
| 12 | `profiler` | Analyze user behavioral patterns across sessions for methodology adaptation | Neither (background) | Budget | Preserves GSD's `gsd-user-profiler` as a background analysis task, not an active pipeline participant. Runs on request, not per-task. |

**Why 12, not 21:** GSD's 21 agents include many single-purpose specialists that differ only in their domain focus (4 researchers, 4 mappers, multiple auditor types). The unified methodology parameterizes agents by focus area rather than defining separate agent files for each variant. This follows the academic finding (Confucius SDK, OpenDev) that a single parameterized agent outperforms rigid class hierarchies.

**Agent specs are mode-universal.** Every agent definition contains both a capability specification and a behavioral specification. In interactive mode, the behavioral specification is loaded as skills. In orchestrated mode, the full specification is injected into the spawned agent's prompt. The agent definition format is the same regardless of mode — only the instantiation mechanism differs.

### Reference Documents

References provide shared knowledge that multiple agents need. They contain domain information, not behavioral directives (that distinction belongs to skills).

| # | Reference Name | Scope | Research Grounding |
|---|---------------|-------|-------------------|
| 1 | `verification-patterns` | Stub detection signatures: comment-based markers, empty implementations, hardcoded values, framework-specific patterns, wiring red flags | GSD's `verification-patterns.md` — the most detailed stub taxonomy in either system |
| 2 | `agent-contracts` | Completion markers, handoff schemas (Planner→Executor via PLAN.md, Executor→Verifier via SUMMARY.md), four-status protocol | GSD's `agent-contracts.md`; SYN-10 |
| 3 | `context-budget` | Read-depth scaling by window size, degradation tiers with behavioral adjustments, cache-friendly ordering | GSD's `context-budget.md` |
| 4 | `anti-patterns` | Universal anti-pattern catalog with severity levels: context budget, file reading, subagent, state management, error recovery | GSD's `universal-anti-patterns.md` (27 rules) |
| 5 | `model-profiles` | Per-agent model tier assignments across profiles (quality/balanced/budget/inherit) | GSD's `model-profiles.md` + resolution rules |
| 6 | `git-integration` | Commit conventions, branching strategies, parallel commit safety (lockfile-based mutual exclusion, deferred hook runs) | GSD's `git-integration.md` |
| 7 | `planning-quality` | 8-dimension structural quality checklist for plans: requirement coverage, task atomicity, dependency ordering, file scope, verification commands, context fit, gap detection, Nyquist compliance | Merger of GSD's plan-checker dimensions with Superpowers' self-review checklist |
| 8 | `checkpoint-types` | Checkpoint type taxonomy: auto (fully autonomous), human-verify (90%), decision (9%), human-action (1%) | GSD's `checkpoints.md` |
| 9 | `domain-probes` | Domain-specific probing questions for discuss phase: visual, API, CLI, content, organization | GSD's `domain-probes.md` |
| 10 | `repair-strategies` | Node repair operator: RETRY with adjustment, DECOMPOSE into smaller steps, PRUNE and escalate. Budgets and escalation thresholds. | GSD's node repair operator; SYN-11 |

**Reduction from 25 to 10:** GSD's 25 references include many that are subsumed by the skill system (TDD reference → TDD skill), the agent consolidation (planner decomposition references → planner agent behavioral spec), or the infrastructure extension (config schema → extension configuration). References in the unified methodology contain only domain knowledge that multiple components share — they do not duplicate skill content or agent specifications.

### Infrastructure Services

The infrastructure layer is packaged as a Claude Code extension (per D001) providing:

| Service | Mechanism | Source |
|---------|-----------|--------|
| **State Management** | Lockfile-based atomic operations on state files (O_EXCL creation, stale lock detection, spin-wait with jitter). Tier-aware: no-ops in Tier 0, lightweight file I/O in Tier 1, full lockfile management in Tier 2. | GSD's `state.cjs` |
| **Context Monitor** | Runtime context budget tracking via statusline bridge file. Injects agent-facing warnings at thresholds (WARNING ≤35%, CRITICAL ≤25%). Debounce of 5 tool uses; severity escalation bypasses debounce. | GSD's `gsd-context-monitor.js` + statusline bridge |
| **Prompt Guard** | Scans file writes for prompt injection patterns (13 regex patterns: role override, instruction bypass, system tag injection, invisible Unicode). Advisory-only — detects, does not block. | GSD's `gsd-prompt-guard.js` |
| **Stub Detector** | Programmatic scanner for verification-patterns reference: comment-based stubs, empty implementations, hardcoded values, framework-specific patterns. Runs independently of agent self-assessment. | GSD's `verify.cjs` |
| **Template Engine** | Template selection and variable substitution for consistent artifact formatting. Granularity-aware summary templates (minimal/standard/complex). | GSD's `template.cjs` |
| **Agent Spawner** | Spawn mechanism for orchestrated mode: load context, resolve model, spawn with agent definition + tools + behavioral spec, collect result via completion markers. | GSD's workflow layer spawn protocol |
| **Wave Coordinator** | Dependency analysis and wave grouping for parallel execution. Implicit dependency detection (same-file modification bumps to later wave). | GSD's execute-phase wave analysis |
| **Session Continuity** | Pause/resume with structured handoff (HANDOFF.json with blockers, pending actions, in-progress state). Context handoff for session boundaries. | GSD's pause/resume protocol |

---

## Information Flow

### Three-Tier Memory Model

Context delivery follows the three-tier memory model validated by Codified Context Infrastructure (Vasilopoulos, 2026) and the Confucius Code Agent (Wong et al., 2025):

**Hot Tier — Always Loaded**
Contents loaded into every agent context regardless of task:
- Iron laws (verification, TDD, systematic debugging)
- Gate functions (brainstorming gate, verification gate)
- The meta-skill invocation protocol (1% threshold, priority ordering)
- Active project constraints (from project brief, when Tier 1+ state exists)

This tier is the behavioral constant — it never varies across modes, tiers, or tasks. Content follows Superpowers' density principles: maximum behavioral impact per token.

**Warm Tier — Loaded Per-Task**
Contents selected based on the current task and agent role:
- Relevant skill files (the skills applicable to the current work)
- Agent behavioral specification (the specific agent definition for the current role)
- Task plan and context (PLAN.md, CONTEXT.md, RESEARCH.md for the current task)
- Prior task summaries (when context window permits, scaled by CCI's enrichment rules)

Selection criteria: load what the agent needs for *this task*, not everything available. In interactive mode, the agent loads skills on demand. In orchestrated mode, the orchestrator assembles the warm-tier context for each spawned agent.

**Cold Tier — Queried On Demand**
Contents accessed only when needed during execution:
- Reference documents (verification patterns, anti-patterns, context budgets)
- Knowledge base (KNOWLEDGE.md, DECISIONS.md — project-specific accumulated knowledge)
- Codebase artifacts (source files, test files, configuration)
- Prior phase/slice summaries (for cross-task awareness)

Cold-tier content is not pre-loaded — agents access it through file reads or reference loading when their task requires it. This prevents context pollution from irrelevant domain knowledge.

### Context Delivery by Mode

**Interactive mode:** The agent manages its own context. Skills are loaded incrementally as work progresses. Cold-tier access is through direct file reads. The context-management skill provides degradation-tier awareness and checkpoint guidance.

**Orchestrated mode:** The orchestrator assembles context for each spawned agent following the propagation chain:

```
PROJECT.md ────────► All agents
KNOWLEDGE.md ──────► All agents (hot/warm boundary)
PLAN.md ───────────► Executor, Plan-checker
CONTEXT.md ────────► Researcher, Planner, Executor
RESEARCH.md ───────► Planner, Plan-checker
SUMMARY.md ────────► Verifier, Orchestrator (state tracking)
REQUIREMENTS.md ───► Planner, Verifier, Auditor
ROADMAP.md ────────► Orchestrator
```

Read depth scales with context window size: models with <500K tokens receive frontmatter and summaries only. Models with ≥500K tokens receive full body content plus prior wave summaries for cross-plan awareness.

### Context Density Principles

All context content follows these rules derived from the CSO (Claude Search Optimization) discovery and Superpowers' information density practice:

1. **Skill descriptions contain only triggering conditions, never workflow summaries.** Agents may follow a description summary instead of reading the full skill — this is an observed behavioral bug that the methodology works around by keeping descriptions to invocation criteria only.

2. **Iron laws and rationalization prevention tables maximize behavioral impact per token.** Each table row represents a real evasion pattern observed and patched through adversarial testing, not a hypothetical concern.

3. **Summaries compress prior work without losing decision context.** The template system enforces structured summaries (frontmatter with key decisions, deviations, self-check results) that compress well for downstream consumption.

4. **Reference documents are loaded on demand, not pre-loaded.** Only the verification-patterns reference is loaded proactively (because verification applies to every task). All other references are loaded when relevant to the specific task.

---

## Two-Layer Architecture

### Layer 1: Behavioral Layer (Zero Dependencies)

The behavioral layer consists of Markdown skill files, agent behavioral specifications, and reference documents. It has no runtime dependencies — it works on any platform that can read Markdown files and present them to an AI agent.

**What it provides:**
- Iron laws establishing non-negotiable quality constraints
- Rationalization prevention tables intercepting known evasion patterns
- Gate functions creating structural barriers at critical pipeline points
- Process protocols (brainstorming → planning → execution → verification → completion)
- Anti-sycophancy protocols for honest code review
- TDD-for-skills methodology for validating behavioral directives

**What it cannot provide:**
- State persistence across sessions (requires file I/O infrastructure)
- Concurrent access safety (requires lockfile management)
- Programmatic stub detection (requires code-level codebase scanning)
- Context budget monitoring (requires runtime hooks)
- Multi-agent orchestration (requires spawn/collect infrastructure)

**Graceful degradation:** When the infrastructure layer is unavailable, the behavioral layer operates as a standalone methodology similar to Superpowers. The developer gets behavioral discipline without programmatic enforcement. Verification becomes self-verification with behavioral gates (sufficient for interactive mode with a present developer) rather than independent programmatic verification (required for autonomous execution).

### Layer 2: Infrastructure Layer (Node.js Extension)

The infrastructure layer is packaged as a Claude Code extension (per D001, D002) that amplifies the behavioral layer with enforcement and persistence.

**What it provides on top of the behavioral layer:**
- **State management:** Tier-aware persistence with lockfile-based concurrency control
- **Programmatic verification:** Independent stub detection, 4-level artifact checking, data-flow tracing
- **Context engineering:** Runtime budget monitoring, threshold-based behavioral adjustment, adaptive context enrichment
- **Security scanning:** Prompt injection detection, path traversal prevention, session ID sanitization
- **Multi-agent orchestration:** Agent spawning, wave coordination, model resolution, handoff management
- **Template rendering:** Variable substitution for consistent artifact formatting
- **Session continuity:** Structured pause/resume with HANDOFF.json

**How the layers compose:**
1. The behavioral layer defines *what should happen* (e.g., "verify before claiming completion")
2. The infrastructure layer ensures *it actually happens* (e.g., programmatic stub detection runs independently of the agent's self-assessment)
3. When both layers agree (behavioral gate passes, programmatic checks pass), the work proceeds
4. When they disagree (behavioral gate passes but programmatic checks find stubs), the programmatic finding takes precedence — infrastructure overrides behavioral self-assessment

**Extension lifecycle:**
- Installation: `claude extension install` (single command per D001 distribution model)
- Session start: Hook system loads behavioral content, initializes context monitoring, detects state tier
- During execution: Hooks provide real-time monitoring; CLI tools provide atomic state operations; spawner manages multi-agent coordination
- Session end: State is persisted according to the active tier; session metrics are recorded

---

## Pipeline Stages

The execution pipeline stages reflect actual development flow grounded in both systems' empirical experience. Rather than forcing a fixed stage count, the pipeline is presented as the natural workflow with annotated decision points.

### Stage 1: Discover & Understand

**Purpose:** Build sufficient understanding of the problem and codebase to make design decisions.
**Activities:** Codebase mapping (for existing projects), requirement extraction, constraint identification, stakeholder intent clarification.
**Agent:** `researcher` (parameterized by focus: stack, architecture, features, risks)
**Key skill:** `brainstorming` — hard gate prevents implementation before design approval
**Output:** Research artifacts (RESEARCH.md, codebase maps), identified constraints and gray areas

### Stage 2: Design & Decide

**Purpose:** Make architectural decisions and get user approval before any code is written.
**Activities:** Propose approaches with tradeoffs, capture decisions in design specs, identify gray areas and resolve them through structured questioning.
**Agent:** `researcher` (design focus) in orchestrated mode; primary agent with brainstorming skill in interactive mode
**Key skill:** `brainstorming` — 9-step design exploration, spec writing, sub-project decomposition for large scopes
**Gate:** Design approval required before proceeding. In interactive mode, the developer approves. In orchestrated mode, the design spec serves as the approval artifact.
**Output:** Design specification (in `docs/` or spec directory), decision log entries

### Stage 3: Plan

**Purpose:** Decompose approved design into execution-ready task specifications.
**Activities:** Task breakdown with file lists, verification commands, and success criteria. Structural verification against quality dimensions. Plan revision loop (max 3 iterations).
**Agent:** `planner` + `plan-checker` (revision loop in orchestrated mode); primary agent with `writing-plans` skill in interactive mode
**Key skills:** `writing-plans` (granularity, no-stub mandate), `context-management` (plan sizing to fit context budget)
**Gate:** Plan must pass structural quality check before execution begins
**Output:** PLAN.md files with task elements, wave assignments, dependency ordering

### Stage 4: Execute

**Purpose:** Implement the plan — write code, run tests, produce artifacts.
**Activities:** Per-task execution following the plan. Deviation tracking (auto-fix bugs, auto-add missing functionality, ask about architectural changes). Analysis paralysis detection (5+ consecutive reads without action).
**Agent:** `executor` in orchestrated mode (fresh context per task, parallel within waves); primary agent with `executing-plans` or `subagent-driven-development` skill in interactive mode
**Key skills:** `test-driven-development` (when applicable), `executing-plans` or `subagent-driven-development`, `verification-before-completion`
**Gate:** Each task completion triggers verification gate before proceeding to next task
**Output:** Code changes, test suites, SUMMARY.md per task, git commits

### Stage 5: Verify

**Purpose:** Confirm that execution achieved the goal, not just completed the tasks.
**Activities:** Dual-layer verification (behavioral gate + programmatic checks). Independent codebase inspection for stubs, empty handlers, wiring gaps. Data-flow tracing for critical paths.
**Agent:** `verifier` (independent agent in orchestrated mode with distrust mindset); self-verification with behavioral gate in interactive mode
**Key skills:** `verification-before-completion` (behavioral layer)
**Infrastructure:** Stub detector, 4-level artifact checker (programmatic layer)
**Failure recovery:** Node repair operator — RETRY with adjustment (budget: 2 per task), DECOMPOSE into smaller steps, PRUNE and escalate
**Output:** VERIFICATION.md with status and score

### Stage 6: Ship & Finish

**Purpose:** Complete the work cycle — merge, document, clean up, capture lessons.
**Activities:** Final test run, branch management (merge/push/keep/discard), worktree cleanup, knowledge register updates, decision log updates.
**Agent:** `doc-writer` (if documentation is needed); primary agent with `finishing-work` skill in interactive mode
**Key skill:** `finishing-work` (structured completion protocol), `knowledge-management` (capture lessons learned)
**Output:** Merged code, updated documentation, KNOWLEDGE.md entries, clean workspace

### Cross-Stage Concerns

These apply at every stage:

- **Context budget management:** The `context-management` skill and context-monitor hook track usage and adjust behavior at thresholds
- **Security scanning:** The prompt-guard hook scans file writes for injection patterns continuously
- **State persistence:** State is persisted according to the active tier after each significant action
- **Behavioral reinforcement:** Iron laws and gate functions are active at all stages — they do not relax as work progresses
- **Regression detection:** In orchestrated mode, prior stages' test suites run after execution to catch regressions

---

## Design Constraints & Tradeoffs

### Active Constraints

**D001 — Claude Code Native Only**
The methodology targets Claude Code as its sole runtime. This eliminates the need for GSD's 3,000-line multi-runtime installer and 10-runtime transformation layer. The behavioral layer (Markdown skills) remains portable to other platforms, but the infrastructure layer (Node.js extension) is Claude Code-specific. If Anthropic reopens third-party harness access in the future, the behavioral layer can be repackaged without rewriting.

**D002 — Dependencies Allowed**
The infrastructure layer may use Node.js dependencies. This enables lockfile-based state management, programmatic verification, template rendering, and multi-agent orchestration — capabilities that purely behavioral systems cannot replicate. The behavioral layer remains zero-dependency as a design constraint.

**D006 — Proportional State (Three Tiers)**
State complexity scales with project complexity:
- **Tier 0 (Stateless):** Zero setup, zero files. For single-session tasks and quick fixes.
- **Tier 1 (Lightweight):** Three Markdown files (project brief, knowledge register, decision log). For multi-session projects.
- **Tier 2 (Full Orchestration):** Complete state machine with lockfile-based concurrency. For autonomous multi-phase execution.

Detailed tier specification is in `design/tiered-state-system.md` (S01/T02 deliverable). The dual-layer verification system is detailed in `design/verification-pipeline.md` (S01/T03 deliverable). The seven design principles constraining all architecture decisions are expanded in `design/core-principles.md` (S01/T04 deliverable).

### What Was Explicitly Dropped

These mechanisms were evaluated during M001 research and explicitly excluded from the unified methodology:

| Dropped Mechanism | Source | Why Dropped |
|-------------------|--------|-------------|
| Multi-runtime installer (~3,000 lines, 10 runtimes) | GSD | D001 constrains to Claude Code. The installer's transformation layer is unnecessary maintenance burden. |
| 60 command files (user-facing slash commands) | GSD | The skill-first surface replaces the command layer. Skills are the primary user interaction; commands are derived from skill invocations. |
| Deprecated commands (`brainstorm.md`, `execute-plan.md`, `write-plan.md`) | Superpowers | Already deprecated in favor of skills. Dropped entirely. |
| Role-playing agent metaphors (backstory/persona framing) | Landscape analysis | Domain knowledge and behavioral conditioning are more effective than narrative framing (Codified Expert Knowledge: "over half of each agent specification is domain knowledge, not behavioral instructions"). |
| "Human partner" framing | Superpowers | Effective in interactive mode but misleading in orchestrated mode where no human is present. Replaced with neutral framing. The collaborative intent survives in the methodology's design (user instructions take priority per skill priority hierarchy). |
| 16,623-line TypeScript SDK | GSD | The unified methodology provides a focused extension API, not a full SDK reimplementation. The SDK's core capabilities (plan parsing, context assembly) are implemented as extension internals. Premature SDK-ification adds maintenance burden before the internal architecture stabilizes. |

### Key Tradeoffs Acknowledged

1. **Two execution modes add complexity** — but the academic evidence (OpenDev, SASE) demonstrates that different task types need different orchestration approaches, and GSD's multi-agent model excels at autonomous execution while Superpowers' single-agent model excels at interactive development.

2. **Three state tiers add a decision point at project initialization** — but forcing full state management on a 5-minute fix is hostile to the developer, while attempting stateless multi-session projects leads to repeated work.

3. **Claude Code-only (D001) limits portability** — but the behavioral layer remains independently portable, and Anthropic's current policy makes multi-runtime support moot for the immediate term.

4. **Dual-layer verification doubles the verification cost** — but neither layer alone is sufficient (SASE's speed-vs-trust gap), and the cost of missed stubs or verification shortcuts in production far exceeds the verification overhead.

---

## Appendix A: Component Traceability Matrix

Every component named in this document traces to a specific mechanism in the M001 research corpus.

| Component | Research Source | Synergy/Principle |
|-----------|---------------|-------------------|
| `using-methodology` meta-skill | Superpowers `using-superpowers` (CSO discovery) | SYN-03, Principle 2 |
| `brainstorming` skill | Superpowers `brainstorming` (hard gate) | SYN-07, Principle 7 |
| `writing-plans` skill | Superpowers `writing-plans` + GSD plan-checker | SYN-04, Principle 5 |
| `verification-before-completion` skill | Superpowers gate function + GSD verifier | SYN-01, Principle 3 |
| `test-driven-development` skill | Superpowers TDD (12-row rationalization table) | Principle 5 |
| `systematic-debugging` skill | Superpowers debugging (8-row excuse/reality) | SYN-11, Principle 1 |
| `receiving-code-review` skill | Superpowers anti-sycophancy protocol | SYN-10, Principle 6 |
| `requesting-code-review` skill | Superpowers review request template | SYN-10 |
| `context-management` skill | GSD context-budget + context-monitor | SYN-03, Principle 2 |
| `knowledge-management` skill | GSD KNOWLEDGE.md + CCI three-tier | SYN-02, Principle 2 |
| `executing-plans` skill | Superpowers executing-plans | SYN-05 |
| `subagent-driven-development` skill | Superpowers subagent protocol | SYN-05, Principle 6 |
| `writing-skills` skill | Superpowers TDD-for-skills | SYN-08, Principle 5 |
| `frontend-design` skill | Superpowers frontend-design | Implementation domain |
| `finishing-work` skill | Superpowers finishing-a-dev-branch | Post-execution |
| `git-worktree-management` skill | Superpowers using-git-worktrees | Workspace management |
| `security-enforcement` skill | GSD security module + prompt-guard | SYN-09 |
| `parallel-dispatch` skill | Superpowers dispatching-parallel-agents + GSD waves | SYN-05 |
| `researcher` agent | GSD 4 researchers + synthesizer → parameterized | Confucius single-agent finding |
| `planner` agent | GSD planner (goal-backward, scope prohibition) | SYN-04 |
| `plan-checker` agent | GSD plan-checker (8 dimensions, 3 iterations) | SYN-04 |
| `executor` agent | GSD executor (4 deviation rules, paralysis guard) | SYN-05 |
| `verifier` agent | GSD verifier (4-level, distrust mindset) | SYN-01, Principle 3 |
| `reviewer` agent | GSD doc-verifier + Superpowers code-reviewer | SYN-10, Principle 6 |
| `debugger` agent | GSD debugger | SYN-11 |
| `mapper` agent | GSD 4 mappers → parameterized | Confucius single-agent finding |
| `auditor` agent | GSD security/UI/integration auditors → parameterized | SYN-09 |
| `doc-writer` agent | GSD doc-writer | Post-execution |
| `orchestrator` agent | GSD workflow layer (thin orchestrator) | Principle 1 |
| `profiler` agent | GSD user-profiler | Background analysis |
| State management service | GSD `state.cjs` + lockfile mechanics | Resolution 3, D006 |
| Context monitor hook | GSD `gsd-context-monitor.js` | SYN-03, Principle 2 |
| Prompt guard hook | GSD `gsd-prompt-guard.js` | SYN-09 |
| Stub detector | GSD `verify.cjs` + verification-patterns | SYN-01, Principle 3 |
| Template engine | GSD `template.cjs` | SYN-08 |
| Three-tier memory model | CCI (Vasilopoulos) + Confucius (Wong et al.) | Principle 2 |
| Proportional state (Tiers 0/1/2) | Resolution 3 (D006) | Principle 4 |
| Dual-layer verification | SYN-01 merger | Principle 3 |
| Wave-based parallelism | GSD execute-phase wave analysis | Orchestrated mode |
| Node repair operator | GSD RETRY/DECOMPOSE/PRUNE | SYN-11, Principle 7 |

---

## Appendix B: Downstream Specification Map

This architecture overview names components; the following slices provide detailed specifications:

| Component Category | Specification Slice | What It Covers |
|-------------------|-------------------|----------------|
| Skills (18 enumerated) | **S02 — Skill Library Specification** | Detailed behavioral content for each skill: iron laws, rationalization prevention tables, gate functions, interaction with other skills |
| Agents (12 enumerated) | **S03 — Agent & Reference Specification** | Capability contracts, behavioral specifications, model tier assignments, completion markers, handoff schemas |
| References (10 enumerated) | **S03 — Agent & Reference Specification** | Content scope, usage patterns, maintenance rules for each reference document |
| Infrastructure services (8 enumerated) | **S03 — Agent & Reference Specification** | Extension API, hook registration, CLI tool interfaces, state management internals |
| State tiers (3 defined) | **S01/T02 — Tiered State System** | Tier definitions, detection heuristics, escalation mechanics, feasibility assessment |
| Verification pipeline | **S01/T03 — Verification Pipeline** | Dual-layer specification, mode-specific behavior, failure recovery, artifact-type-specific levels |
| Design principles (7 defined) | **S01/T04 — Core Design Principles** | Expanded principles with academic grounding, examples, and cross-references |
