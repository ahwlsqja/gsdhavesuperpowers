# Comparative Analysis: GSD and Superpowers Across Nine Dimensions

**Date:** 2026-04-05
**Scope:** Dimension-by-dimension comparison of GSD v1.32 and Superpowers v5.0.7, validated against academic findings and open-source framework patterns
**Purpose:** Provide the analytical foundation for the synergy/conflict map (T02) and M002 design decisions

---

## Introduction

GSD and Superpowers solve the same fundamental problem — making AI coding agents reliable enough for production work — through radically different mechanisms. GSD builds programmatic infrastructure: 21 specialized agents, 60 workflows, a 16,623-line TypeScript SDK, CLI tools with lockfile-based state management, and a nine-hook runtime integration layer. Superpowers builds behavioral infrastructure: 14 skill files containing iron laws, rationalization prevention tables, red-flag matrices, gate functions, and graphviz decision flows — with zero lines of runtime code and zero dependencies.

This analysis compares the two systems across nine dimensions, examining how each approaches the same engineering challenge through different operating principles. Each dimension references specific mechanisms from both systems (see `research/gsd-analysis.md` and `research/superpowers-analysis.md` for drill-down), cites academic findings that validate or challenge each approach (see `research/academic-literature-review.md`), and draws on open-source framework patterns for cross-validation (see `research/open-source-landscape.md`).

The goal is not to declare a winner in each dimension but to understand where each system's approach is strongest, where it is weakest, and where the mechanisms are complementary rather than competing. This understanding directly feeds the synergy/conflict map that follows.

---

## Dimension 1: Architecture & Design Philosophy

### The Problem

AI coding agents need a structured environment to operate effectively. Without scaffolding, agents produce inconsistent output, lose track of project state, forget instructions mid-session, and fail to verify their own work. The architectural question is: what form should that scaffolding take?

### GSD's Approach: Programmatic Infrastructure

GSD implements a five-layer architecture — Commands → Workflows → Agents → CLI Tools → File System — where each layer has a clear responsibility boundary. The system separates prompt-layer components (commands, workflows, agents, references, templates) from programmatic-layer components (gsd-tools.cjs with 19 domain modules, the TypeScript SDK). This separation means behavioral rules live in Markdown files that agents read, while enforcement logic lives in Node.js code that agents call.

The design philosophy rests on five principles: fresh context per agent (eliminating context rot through clean spawns), thin orchestrators (workflows coordinate but don't execute), file-based state (all artifacts in `.planning/` as human-readable Markdown), absent-equals-enabled defaults (features opt-out rather than opt-in), and defense in depth (overlapping quality gates at plan, execution, verification, and UAT stages).

The programmatic backbone — `gsd-tools.cjs` — provides atomic operations for state management. Direct Write/Edit to STATE.md is explicitly prohibited (anti-pattern rule #15) because it bypasses lockfile-based mutual exclusion, field validation, and consistent formatting. This is infrastructure-level enforcement: the system prevents incorrect state manipulation by making it structurally impossible through the intended interface.

### Superpowers' Approach: Behavioral Shaping

Superpowers has no layers, no CLI tools, no SDK, and no runtime code. Its entire architecture is 14 skill files, 1 agent definition, 3 deprecated commands, and a session-start hook that bootstraps the system by injecting the `using-superpowers` meta-skill as additional context. The `package.json` contains only `name`, `version`, `type`, and `main` — zero dependencies.

The design philosophy rests on three principles: zero dependencies (portable to any platform that reads Markdown), human partner framing (positioning the agent as a collaborator rather than a tool), and behavioral testing over static analysis (skills are validated through adversarial pressure testing with subagents, not structural review).

Where GSD prevents bad behavior through code-level guardrails, Superpowers prevents it through psychological conditioning. The meta-skill's 1% invocation threshold ("If you think there is even a 1% chance a skill might apply, you ABSOLUTELY MUST invoke the skill") creates a default-invoke behavioral pattern. The iron laws ("NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST") establish absolute constraints. The rationalization prevention tables intercept specific evasion thoughts the agent might have. The gate functions make verification a structural requirement framed as an honesty obligation ("Skip any step = lying, not verifying").

### Academic Validation

The SASE framework (Hassan et al.) decomposed the agent operating environment into the Agent Command Environment (ACE) and Agent Execution Environment (AEE), arguing that an agent's performance ceiling is set by the quality of these workbenches rather than the model inside them. GSD is a concrete implementation of both workbenches — its workflow layer is the ACE, its CLI tools and file system are the AEE. Superpowers is a different kind of scaffolding — behavioral scaffolding that constrains model output through prose rather than code. Both are valid implementations of the scaffolding-over-model-capability thesis.

The Confucius Code Agent study (Wong et al.) provided the strongest empirical evidence: Claude 4 Sonnet with advanced scaffolding outperformed Claude 4.5 Sonnet with simpler scaffolding by 6.6 percentage points on SWE-Bench-Pro. This validates both systems' heavy investment in scaffolding, though through different modalities.

### Open-Source Validation

The landscape analysis reveals a split: general-purpose frameworks (CrewAI, LangGraph, AutoGen) lean toward GSD's programmatic approach with typed state, graph-based workflows, and SDK layers. Coding-specific frameworks (OpenHands, Codified Context Infrastructure) are more aligned with hybrid approaches — OpenHands with its SDK-first architecture, Codified Context Infrastructure with its document-as-infrastructure philosophy. No major framework uses pure behavioral shaping like Superpowers, making it a genuinely novel approach in the ecosystem.

### Comparative Assessment

GSD's programmatic approach provides **stronger enforcement guarantees** — lockfile-based state management, automated verification pipelines, and deterministic workflow execution cannot be bypassed by agent rationalization. Superpowers' behavioral approach provides **lower integration cost** — adding a skill requires editing a Markdown file, not modifying a codebase. GSD is harder to set up but harder to circumvent. Superpowers is trivial to deploy but depends on the model's willingness to comply with prose directives. The approaches are complementary: behavioral shaping catches the cases where programmatic enforcement has gaps (agent judgment calls, quality of implementation, reasoning discipline), while programmatic enforcement catches the cases where behavioral shaping fails (state consistency, concurrency, deterministic verification).

---

## Dimension 2: Execution Model

### The Problem

Once a plan exists, how does the work actually get done? The execution model determines how tasks are assigned to agents, how parallel work is coordinated, what happens when tasks fail, and how results are collected and verified.

### GSD's Approach: Multi-Agent Pipeline with Wave-Based Parallelism

GSD uses a multi-agent architecture where the orchestrator spawns specialized agents for each function. The execution pipeline follows a rigid sequence: discuss → plan → execute → verify. Within the execute phase, tasks are grouped into waves based on dependency analysis — Wave 1 runs all independent tasks in parallel, Wave 2 runs tasks that depend on Wave 1, and so on. Each executor gets a fresh context window with only its specific plan, project context, and (for 1M-class models) prior wave summaries.

The spawn mechanism follows a protocol: load context via `gsd-tools.cjs init`, resolve the model via `gsd-tools.cjs resolve-model`, spawn the agent with its definition and tool permissions, collect the result via completion markers, and update state. Parallel commit safety is ensured through `--no-verify` commits (avoiding build lock contention) with a post-wave hook run, plus lockfile-based mutual exclusion on STATE.md.

When execution fails, GSD's node repair operator chooses between RETRY (attempt with adjustment, budget of 2 per task), DECOMPOSE (break into smaller steps), or PRUNE (remove unachievable tasks and escalate). The plan-checker loop allows up to 3 iterations of plan → check → revise before execution begins.

### Superpowers' Approach: Single Agent with Skill Loading

Superpowers operates within a single agent's context window. There is no orchestrator, no parallel execution, no wave analysis. Instead, the agent loads relevant skills at task boundaries and follows their behavioral directives sequentially. The execution path is: brainstorming skill → writing-plans skill → executing-plans skill (or subagent-driven-development skill) → finishing-a-development-branch skill.

The `subagent-driven-development` skill provides the closest analog to multi-agent execution: a coordinator dispatches fresh subagents for each task, with a two-stage review after each (spec compliance then code quality). But the coordination is behavioral — the skill tells the agent how to dispatch subagents, what context to provide them, and how to handle their four possible statuses (DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED). There is no programmatic enforcement of the dispatch protocol; the agent follows the skill's instructions because the behavioral conditioning makes it do so.

Model selection is prescribed by complexity: cheap models for mechanical tasks touching 1-2 files, standard models for integration work, and the most capable model for architecture and review. This is guidance, not enforcement — the agent chooses based on the skill's recommendations.

### Academic Validation

OpenDev (Bui) drew a critical distinction between scaffolding (constructing the agent before the first prompt) and harness (runtime orchestration during execution). GSD has strong implementations of both — elaborate pre-prompt scaffolding through its system prompt, workflow definitions, and templates, plus a runtime harness through hooks, state management, and the context monitor. Superpowers is scaffolding-heavy (SKILL.md loading at session start) with minimal harness, relying on the host platform's built-in runtime mechanisms. OpenDev's findings suggest that effective systems need strong implementations of both layers.

The dual-agent architecture proposed by OpenDev — separating planning from execution — validates GSD's planner/executor split. The Confucius SDK's meta-agent that configures other agents maps to GSD's orchestrator pattern but suggests even more dynamic configuration than GSD currently implements.

### Open-Source Validation

AutoGen's agent-as-tool composability pattern offers a simpler dispatch model than GSD's explicit spawning — agents are wrapped as tools with input/output schemas, making them invocable through the same mechanism as any other tool. Google ADK's hierarchical nesting provides another composition model. Both validate the multi-agent approach but suggest GSD's dispatch could be simplified. No major framework validates Superpowers' single-agent-with-skill-loading model as a primary execution architecture, though it works effectively within the constraints of Claude Code's subagent spawning.

### Comparative Assessment

GSD's multi-agent model provides **stronger isolation** (fresh context per agent eliminates accumulated confusion), **better parallelism** (wave-based execution maximizes throughput), and **deterministic orchestration** (the pipeline runs the same way regardless of agent judgment). Superpowers' single-agent model provides **lower overhead** (no spawn/collect cycle), **richer context** (the coordinator retains the full conversation history), and **simpler debugging** (everything happens in one observable context window). GSD excels at large, multi-task executions where isolation and parallelism matter. Superpowers excels at focused, interactive development where context continuity matters.

---

## Dimension 3: Planning & Design Phase

### The Problem

Plans must be specific enough to execute without ambiguity but flexible enough to accommodate the inherent uncertainty of software development. Too vague, and agents fill in the gaps with assumptions. Too rigid, and agents waste effort on plans that don't match reality.

### GSD's Approach: Milestone/Slice/Task Hierarchy with Verification Gates

GSD decomposes work into three levels: milestones (major project phases), slices (demoable vertical increments ordered by risk), and tasks (single-context-window units of work). Plans are written in PLAN.md files with XML-structured task elements containing `<name>`, `<files>`, `<action>`, `<verify>`, and `<done>` fields. Each task specifies a type: `auto` (fully autonomous), `checkpoint:human-verify` (90%), `checkpoint:decision` (9%), or `checkpoint:human-action` (1%).

Before execution, plans pass through a quality gate. The `gsd-plan-checker` agent verifies plans against 8 dimensions: requirement coverage, task atomicity, dependency ordering, file scope, verification commands, context fit, gap detection, and Nyquist compliance (ensuring test coverage maps to requirements). If issues are found, the planner revises and the checker re-verifies — maximum 3 iterations. Plans target completion within ~50% of the context budget (2-3 tasks per plan) to maintain quality throughout execution.

The planner uses goal-backward methodology: start from what must be true for the phase goal to be achieved, derive observable truths, required artifacts, required wiring, and key links. A scope reduction prohibition prevents the planner from silently simplifying user decisions — if a phase is too complex, it recommends splitting rather than delivering a reduced version.

### Superpowers' Approach: Iron-Law Planning Gates

Superpowers enforces planning through behavioral gates rather than structural verification. The `brainstorming` skill implements a hard gate: "Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it." This applies to every project "regardless of perceived simplicity."

The `writing-plans` skill prescribes extreme task granularity — 2-5 minutes per step — with each step following a strict template: write the failing test (with actual code), run it to verify failure (with exact command), implement minimal code (with actual implementation), run tests to verify pass (with exact command), commit (with exact git commands). A "No Placeholders" section enumerates specific plan failures: deferred-marker strings, vague directives like "Add appropriate error handling," cross-references like "Similar to Task N" (counter: "repeat the code — the engineer may be reading tasks out of order"), and steps that describe what to do without showing how.

Plans are written assuming "the engineer has zero context for our codebase and questionable taste" — establishing a documentation bar that forces explicitness. The self-review checklist covers spec coverage, placeholder scan, and type consistency across tasks.

### Academic Validation

The LLMs Reshaping SE study (Tabarsi et al.) found that AI effectiveness is phase-dependent — strong in implementation and debugging, weak in requirements gathering and architectural design. Both systems independently validate this by investing heavily in the planning phase: GSD with its multi-agent pipeline (researcher → planner → plan-checker), Superpowers with its brainstorming → writing-plans sequence. The empirical finding that developers learned "layered verification" mirrors both systems' multi-stage plan quality gates.

SASE's autonomy levels suggest that different tasks need different planning depth — a principle GSD implements through task types (auto vs checkpoint variants) but Superpowers applies uniformly. The finding that per-task autonomy configuration is more effective than per-session configuration (DI from SASE) supports GSD's per-task type system.

### Open-Source Validation

LangGraph's graph-based workflow definition formalizes the kind of conditional planning that GSD's verify-then-revise loop implements informally. Google ADK's declarative agent configuration validates both systems' use of Markdown/YAML for plan definitions. OpenHands' Theory-of-Mind module addresses a gap both systems share: neither explicitly models developer intent beyond what is stated in the plan.

### Comparative Assessment

GSD's planning is **structurally verified** — the plan-checker agent provides an independent quality gate with 8 specific dimensions, and the 3-iteration revision loop ensures plans meet a minimum quality bar before execution. Superpowers' planning is **execution-ready** — the extreme granularity (2-5 minute tasks with actual code snippets) means plans can be followed mechanically without interpretation. GSD optimizes for plan correctness at a structural level. Superpowers optimizes for plan unambiguity at the step level. A unified approach would benefit from both: structural verification that the plan covers requirements and orders dependencies correctly, plus execution-level granularity that eliminates interpretation gaps in each task.

---

## Dimension 4: Verification & Quality Assurance

### The Problem

AI agents routinely claim work is complete when it is not. They produce stub implementations, hardcoded values, empty handlers, and placeholder components — all of which pass superficial checks. The verification challenge is detecting these failure modes reliably without relying on the agent's own assessment.

### GSD's Approach: Multi-Layer Programmatic Verification

GSD implements seven overlapping quality gates:

1. **Plan Checker** (`gsd-plan-checker`): Verifies plans against 8 dimensions before execution.
2. **Executor Self-Check**: The executor verifies its own SUMMARY.md claims — checking that created files exist and commits are present.
3. **Post-Execution Verifier** (`gsd-verifier`): Four-level verification (Exists → Substantive → Wired → Functional) plus Level 4 data-flow trace. Crucially, the verifier does NOT trust SUMMARY.md claims — it independently verifies codebase state.
4. **UAT** (`gsd-verify-work`): Human acceptance testing with auto-diagnosis.
5. **Nyquist Validation**: Maps test coverage to requirements before code is written.
6. **Cross-Phase Regression Gate**: Runs prior phases' test suites to catch regressions.
7. **Requirements Coverage Gate**: Ensures every requirement appears in at least one plan.

The stub detection system (`verification-patterns.md`) catalogs extensive patterns: comment-based stubs (FIXME, HACK, PLACEHOLDER), empty implementations (return null/{}/ []), hardcoded values, React-specific stubs (empty handlers, components returning bare divs), and API-specific stubs (routes returning static arrays). The verifier checks for these patterns programmatically, meaning the agent cannot produce stubs without detection.

The node repair operator provides a structured response to verification failure: RETRY (with adjustment), DECOMPOSE (break into smaller steps), or PRUNE (escalate). This prevents the common pattern of agents retrying the same failed approach indefinitely.

### Superpowers' Approach: Behavioral Gate Functions

Superpowers implements verification through a single iron law: "NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE." This is enforced through a five-step gate function:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
5. ONLY THEN: Make the claim

The framing of gate violations as "lying, not verifying" leverages the model's alignment with honesty values. An 8-row rationalization prevention table intercepts specific evasion thoughts: "Should work now" → "RUN the verification," "I'm confident" → "Confidence ≠ evidence," "Different words so rule doesn't apply" → "Spirit over letter."

The Common Failures table maps claims to required evidence: "Tests pass" requires test command output with 0 failures (not "should pass"). "Bug fixed" requires testing the original symptom (not "code changed, assumed fixed"). "Agent completed" requires VCS diff showing changes (not "agent reports success"). This last entry establishes that an agent's self-reported success is never sufficient evidence — creating a recursive trust verification protocol.

The `subagent-driven-development` skill adds a two-stage review: spec compliance review ("The implementer finished suspiciously quickly. Their report may be incomplete, inaccurate, or optimistic. You MUST verify everything independently.") followed by code quality review. Review loops enforce re-review after fixes.

### Academic Validation

SASE identified the "speed vs. trust gap" — AI agents increase development speed but decrease trust in output. This gap widens as agent autonomy increases. Both systems address this: GSD with structural verification that scales through automated quality gates, Superpowers with behavioral enforcement that makes verification a non-negotiable step. The finding that "verification must be structural, not optional" (a cross-paper convergence point across SASE, LLMs Reshaping SE, and Codified Context Infrastructure) validates both approaches while suggesting they should be combined.

The LLMs Reshaping SE study found that developers frequently discarded generated code — optimizing the evaluate-discard-regenerate cycle matters. GSD's plan-checker loop (max 3 iterations) and node repair operator both implement structured regeneration cycles.

### Open-Source Validation

OpenHands maintains a separate benchmarks repository for evaluation — more rigorous than either system's approach because it measures end-to-end performance. Google ADK's per-tool confirmation flow provides finer-grained verification than either GSD's per-task checkpoints or Superpowers' per-completion gates. The unified methodology should support verification at multiple granularities.

### Comparative Assessment

GSD's verification is **independent and programmatic** — the verifier does not trust executor claims and checks the codebase independently using pattern-matching against known stub signatures. Superpowers' verification is **behavioral and process-oriented** — it ensures the agent runs real verification commands and reads real output before making claims. GSD catches stubs that slip past agent attention. Superpowers prevents the agent from skipping verification in the first place. Neither alone is sufficient: GSD's programmatic verification can detect stubs but cannot force the agent to write quality code in the first place. Superpowers' behavioral enforcement can make the agent disciplined but cannot catch failure modes the agent doesn't recognize. Together they create a two-layer defense — behavioral discipline ensures the agent tries to verify, programmatic verification catches what the agent misses.

---

## Dimension 5: State Management

### The Problem

AI agents operate in context windows that get cleared between sessions (and sometimes within sessions). Without persistent state, every session starts from zero — the agent doesn't know what was done before, what decisions were made, or where the project stands. State management determines how project memory survives across context resets.

### GSD's Approach: File-Based Persistent State Machine

GSD maintains all state in `.planning/` as human-readable Markdown and JSON. The state model includes PROJECT.md (living vision document), REQUIREMENTS.md (scoped requirements with unique IDs), ROADMAP.md (phase breakdown with status tracking), STATE.md (living memory with current position, decisions, blockers, metrics), config.json (workflow configuration), and per-phase directories with CONTEXT.md, RESEARCH.md, PLAN.md, SUMMARY.md, VERIFICATION.md, and UAT.md files.

State mutations go through `gsd-tools.cjs` — never direct file edits. The CLI tools provide lockfile-based mutual exclusion (STATE.md.lock with O_EXCL atomic creation, stale lock detection at 10s, spin-wait with jitter) for concurrent access safety. Operations are atomic: `advance-plan` increments the current plan with edge case handling, `update-progress` recalculates from SUMMARY.md counts on disk, `add-decision` records architectural choices.

Session continuity is handled through pause/resume: `/gsd-pause-work` saves position to `continue-here.md` and structured HANDOFF.json (including blockers, pending human actions, in-progress task state). `/gsd-resume-work` restores context from HANDOFF.json (preferred) or state files (fallback).

Context propagation follows a defined chain: PROJECT.md feeds all agents, REQUIREMENTS.md feeds the planner/verifier/auditor, ROADMAP.md feeds orchestrators, and so on. This ensures each agent sees the right state without loading everything.

### Superpowers' Approach: Stateless Behavioral Directives

Superpowers has no state management mechanism. No persistent state file, no context propagation chain, no session continuity protocol, no lockfile management. The system is entirely stateless — skills are loaded fresh each session via the session-start hook, and the agent's state is whatever the host platform (Claude Code, Cursor, etc.) maintains.

The only state-like artifact is the spec document written during brainstorming (`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`), which serves as a planning record the agent can reference in subsequent sessions. But this is a project artifact, not methodology state — Superpowers itself retains nothing between sessions.

Git worktree management (`using-git-worktrees` skill) provides isolation for work-in-progress, but this is workspace management, not state management. The agent doesn't know which worktrees exist or what state they're in unless it checks.

### Academic Validation

The three-tier memory architecture identified independently by Codified Context Infrastructure (Vasilopoulos) and Confucius Code Agent (Wong et al.) — hot/warm/cold tiers with explicit access patterns — directly validates GSD's layered state model. GSD's system prompt is hot-tier (always loaded), agent definitions and phase context are warm-tier (loaded per-task), and reference documents are cold-tier (queried on demand). Superpowers' skills are warm-tier only (loaded per-skill-invocation), with no hot or cold tier under its own management.

The OpenDev paper identified "instruction fade-out" — agents gradually forget system prompt guidelines over long conversations. GSD addresses this through fresh context windows (each agent starts clean) and the context monitor hook (reinjects warnings at threshold crossings). Superpowers addresses it through aggressive behavioral conditioning (iron laws, red-flag matrices) that is loaded once and intended to persist through the session. Neither approach fully solves fade-out; event-driven instruction reinforcement (OpenDev's proposal) would complement both.

### Open-Source Validation

LangGraph provides the most sophisticated state management — checkpoint-based persistence at every graph node with resume-from-any-point capability. Google ADK adds session rewind (undo to a previous state). Both exceed GSD's current capabilities, which checkpoint at session boundaries rather than task boundaries. Codified Context Infrastructure's drift detection scripts address a gap both GSD and Superpowers share: neither detects when their knowledge artifacts go stale relative to the codebase.

### Comparative Assessment

GSD provides **comprehensive state persistence** that makes project memory durable across sessions, agents, and failures. Superpowers provides **zero state overhead** — no state to maintain, no state to corrupt, no state inconsistency bugs. GSD's approach is essential for multi-phase projects where continuity matters but adds maintenance cost (STATE.md consistency gates were added in v1.32 specifically to address state corruption bugs). Superpowers' statelessness is a feature for single-session tasks but a limitation for anything requiring cross-session memory. The unified methodology needs GSD's state management (or something equivalent) for project continuity, while Superpowers' zero-overhead philosophy should inform the design — state complexity should be proportional to project complexity, not a fixed tax.

---

## Dimension 6: Context Engineering

### The Problem

AI agents have finite context windows that fill as they work. Quality degrades as context fills — a phenomenon documented in GSD's context-budget reference as the PEAK → GOOD → DEGRADING → POOR progression. The context engineering challenge is maximizing the quality of what fills the window while monitoring and managing its consumption.

### GSD's Approach: Infrastructure-Level Context Management

GSD attacks context engineering at three levels. First, **fresh context windows** — every agent spawned by the orchestrator starts with a clean context window, eliminating context rot from accumulated conversation. Second, **context budget monitoring** — the context-monitor hook tracks usage via a statusline bridge file (`/tmp/claude-ctx-{session}.json`) and injects agent-facing warnings at two thresholds: WARNING at ≤35% remaining ("avoid starting new complex work") and CRITICAL at ≤25% ("context nearly exhausted"). Third, **adaptive context enrichment** — when the context window is 500K+ tokens (1M-class models), subagent prompts are enriched with prior wave summaries and phase research, enabling cross-plan awareness.

The context propagation chain is explicit: each artifact has a defined audience (PROJECT.md → all agents, PLAN.md → executor/plan-checker, SUMMARY.md → verifier/state tracking). Read depth scales with context window size: at <500K, agents read only frontmatter and summaries; at ≥500K, full body reads are permitted. Plans target completion within ~50% context to maintain quality through execution.

The bridge architecture between the statusline hook and context-monitor hook is a specific engineering solution to a platform constraint: the statusline event provides context data but cannot inject agent-facing messages, while PostToolUse can inject messages but doesn't receive context data. The bridge file synchronizes the two.

### Superpowers' Approach: Context-Dense Skill Loading

Superpowers loads entire skill files into the agent's context window when invoked — iron laws, rationalization prevention tables, red-flag matrices, gate functions, and graphviz diagrams all consume context tokens. The `using-superpowers` meta-skill is injected at session start, and additional skills are loaded on demand via the Skill tool.

The system has no context monitoring, no usage tracking, no degradation tiers, and no budget management. It relies entirely on the host platform's context management. The implicit assumption is that skill files are dense enough (high information per token) to justify their context cost, and the 1% invocation threshold ensures skills are loaded aggressively rather than conservatively.

The CSO discovery (Claude Search Optimization) represents a significant finding about context usage: skill descriptions should contain only triggering conditions, never workflow summaries, because agents may follow the description instead of reading the full skill. This means the system is aware of how context content affects behavior, even without formal context management infrastructure.

### Academic Validation

Every paper reviewed treats context as the primary engineering challenge. The Codified Context Infrastructure paper's three-tier model (hot/warm/cold) maps to GSD's layered context propagation chain but not to Superpowers' flat skill-loading approach. OpenDev's progressive context compaction — summarizing older observations first, then removing them as the window fills — is more dynamic than GSD's static threshold model. The Confucius SDK's hierarchical working memory provides a middle ground: structured compression that preserves important context while reducing token count.

The cross-paper convergence finding that "context is the bottleneck" validates GSD's heavy investment in context management infrastructure while highlighting that Superpowers' lack of context management is a genuine gap, not a feature.

### Open-Source Validation

None of the six analyzed frameworks match GSD's sophistication in context monitoring (real-time usage tracking with threshold-based behavioral adjustment). LangGraph's checkpoint-based persistence and OpenHands' SDK-managed context provide state persistence but not the active monitoring that GSD's hook system enables. Superpowers' approach — no context management, just dense skill content — is unique in the landscape and represents a bet that quality of context matters more than quantity management.

### Comparative Assessment

GSD provides **active context management** — monitoring usage, adjusting behavior at thresholds, scaling read depth by window size, and enriching prompts when capacity permits. Superpowers provides **high-density context content** — iron laws and rationalization prevention tables pack maximum behavioral impact per token. GSD manages the container. Superpowers optimizes the contents. Both are needed: the unified methodology should manage context budgets (GSD's infrastructure) while ensuring that what fills those budgets is maximally effective (Superpowers' content density and the CSO finding about description-vs-content behavior).

---

## Dimension 7: Security

### The Problem

AI agents read and write files, execute commands, and interact with external services — all under the guidance of prompts that could be manipulated. Security in this context means protecting against prompt injection (malicious content in files the agent reads), path traversal (escaping intended directories), and unauthorized actions (the agent doing more than it should).

### GSD's Approach: Multi-Layer Programmatic Defense

GSD implements security at four layers. The **prompt guard hook** (`gsd-prompt-guard.js`) scans `.planning/` file writes for 13 prompt injection patterns — role override, instruction bypass, system tag injection, and invisible Unicode — on every tool use event. It is advisory-only (logs detection, does not block) to avoid false-positive disruption.

The **CLI security module** (`lib/security.cjs`) provides path traversal prevention, prompt injection detection (a superset of the hook's patterns), safe JSON parsing (preventing prototype pollution), and shell argument validation. Session ID sanitization rejects IDs containing path traversal sequences, preventing file path escape attacks.

**Security enforcement** (v1.31) requires every plan to include a `<threat_model>` section with STRIDE threat register and mitigation dispositions. The **execution scope boundary** limits auto-fixes to issues directly caused by the current task — pre-existing warnings and unrelated file issues are logged to `deferred-items.md`, not fixed.

### Superpowers' Approach: Behavioral Security Rules

Superpowers has no programmatic security mechanisms — no injection detection, no path validation, no session sanitization. Security is enforced entirely through behavioral directives. The `using-superpowers` meta-skill establishes a priority hierarchy: user instructions > Superpowers skills > default system prompt. This hierarchy means that if a malicious file contains instructions claiming to be "system" directives, they are lower priority than the user's actual instructions and the skill files.

The hard gates serve as implicit security boundaries: the brainstorming gate prevents implementation before design approval (catching cases where injected content might trigger unauthorized code generation), and the verification gate requires evidence before completion claims (catching cases where injected content might cause the agent to report false success).

### Academic Validation

The SASE framework's autonomy levels suggest that security requirements should scale with autonomy — higher autonomy needs more security infrastructure because the human provides less oversight. This supports GSD's multi-layer approach for autonomous execution while acknowledging that Superpowers' behavioral approach may be sufficient for interactive sessions where the human is actively reviewing.

### Open-Source Validation

OpenHands uses container-based sandboxing — the heaviest security approach in the landscape. Google ADK's per-tool confirmation flow provides a different security model: rather than scanning for threats, it requires human approval for high-impact operations. Neither approach matches GSD's advisory scanning model, which detects threats without blocking action. Superpowers' purely behavioral approach has no direct parallel in the landscape.

### Comparative Assessment

GSD provides **defense-in-depth** with programmatic detection at multiple layers, making it harder for injection attacks to succeed undetected. Superpowers provides **minimal attack surface** — with no code, no state files, and no CLI tools, there are fewer components that could be exploited. GSD's approach is appropriate for autonomous execution where the human is not watching. Superpowers' approach relies on the human partner being present to catch issues that behavioral rules miss. The unified methodology should implement GSD's programmatic security for autonomous mode while using Superpowers' behavioral hierarchy (user > skills > defaults) as a complementary layer for all modes.

---

## Dimension 8: Agent Definition & Composition

### The Problem

AI agent systems need to define what agents are (their capabilities, constraints, and knowledge), how agents are selected for tasks, and how agents hand off work to each other. The agent definition model determines how modular, maintainable, and extensible the system is.

### GSD's Approach: 21-Agent Registry with Typed Contracts

GSD defines 21 specialized agents across 12 functional categories: researchers (4 parallel), synthesizers, planners, checkers, executors, verifiers, mappers, debuggers, auditors, doc writers, profilers, and analyzers. Each agent is defined in `agents/gsd-{name}.md` with YAML frontmatter specifying name, description, allowed tools, and terminal color.

Agent composition is orchestrator-driven: workflows define which agents to spawn, in what order, with what context. The agent contracts reference (`agent-contracts.md`) defines formal completion markers and handoff schemas — the Planner→Executor handoff via PLAN.md and the Executor→Verifier handoff via SUMMARY.md. Model profiles (quality/balanced/budget/inherit) control which model tier each agent uses, resolved once per orchestration.

The executor agent implements four deviation rules that allow autonomous decision-making: auto-fix bugs (Rule 1), auto-add missing critical functionality (Rule 2), auto-fix blocking issues (Rule 3), and ask about architectural changes (Rule 4). An analysis paralysis guard triggers after 5+ consecutive read-only tool calls without any action.

### Superpowers' Approach: Skill-Based Behavioral Specialization

Superpowers ships exactly one agent (`code-reviewer`) and 14 skills. The agent system is the skill system — agents specialize by loading different skill combinations, not by having separate definitions. The `subagent-driven-development` skill prescribes fresh subagents per task but defines them inline via prompt construction rather than referencing a registry.

Skill type classification (rigid vs flexible) determines enforcement strictness. Skill priority ordering (process skills first, implementation skills second) prevents the common failure of jumping to implementation without investigation. The meta-skill's red-flag table intercepts 12 specific rationalization patterns that would cause the agent to skip skill loading.

The four-status implementer protocol (DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED) provides a lightweight agent contract. The two-sided review protocol (requesting + receiving code review) addresses agent sycophancy — explicitly forbidding phrases like "You're absolutely right!" and requiring technical pushback when reviewer feedback is wrong.

### Academic Validation

The Confucius SDK's finding that a single parameterized agent outperforms class hierarchies (OpenDev, Bui) creates tension with GSD's 21-agent registry. The OpenDev paper specifically advocates for "a single parameterized agent over class hierarchy" — suggesting GSD's many-agent approach may add complexity without proportional benefit. However, GSD's agents serve different functions (research vs planning vs execution vs verification), not just different parameterizations of the same function, which is a different design space than what OpenDev examined.

The Codified Expert Knowledge study found that "over half of each agent specification is domain knowledge, not behavioral instructions" — contrasting sharply with Superpowers' skills, which are almost entirely behavioral instructions with minimal domain content. The unified methodology needs both: domain knowledge in agent specifications (the Codified Context approach) with behavioral conditioning layered on top (the Superpowers approach).

### Open-Source Validation

Google ADK's declarative Agent Config validates both systems' use of Markdown for agent definitions — all three independently arrived at declarative configuration as the agent definition format. CrewAI's role-based specialization pattern provides a template for formalizing agent selection based on task requirements. AutoGen's agent-as-tool pattern suggests that agents should be invocable through the same protocol as tools, which would simplify GSD's dispatch mechanism.

### Comparative Assessment

GSD provides **explicit specialization** — each agent has a defined role, tool permissions, model assignment, and completion contract, making the system predictable and auditable. Superpowers provides **dynamic specialization** — the same agent becomes a TDD practitioner, a systematic debugger, or a brainstorming facilitator depending on which skills are loaded, making the system more flexible and lighter-weight. GSD's approach is better for complex multi-phase projects where specialized agents with clear contracts reduce coordination errors. Superpowers' approach is better for interactive development where the agent needs to shift between modes fluidly.

---

## Dimension 9: Knowledge Management

### The Problem

AI agents need access to project-specific knowledge (conventions, patterns, past decisions) and methodology-level knowledge (best practices, anti-patterns, verification procedures). Without this knowledge, agents repeat mistakes, violate conventions, and produce inconsistent output. The knowledge management challenge is capturing, organizing, and delivering this knowledge effectively.

### GSD's Approach: Append-Only Registers and Reference Library

GSD maintains knowledge across three mechanisms. **KNOWLEDGE.md** is an append-only register of project-specific rules, patterns, and lessons learned — read at the start of every unit, appended when agents discover recurring issues or non-obvious patterns. **DECISIONS.md** is an append-only register of architectural and pattern decisions that downstream work should know about. The **reference system** (25 files in `get-shit-done/references/`) provides shared knowledge documents that workflows and agents load via `@-reference` syntax — covering verification patterns, agent contracts, context budgets, anti-patterns, model profiles, questioning philosophy, and more.

Context propagation ensures the right knowledge reaches the right agents: REQUIREMENTS.md feeds the planner/verifier/auditor, ROADMAP.md feeds orchestrators, STATE.md (including decisions and blockers) feeds all agents. The template system (42 files) provides pre-structured Markdown for all planning artifacts, ensuring consistent knowledge capture.

Knowledge maintenance is manual — reference documents are updated by the GSD maintainers during releases (v1.27 through v1.32). There is no automated drift detection for reference content.

### Superpowers' Approach: Embedded Expertise in Skill Files

Superpowers embeds methodology knowledge directly in skill files as behavioral directives. The TDD skill contains the Red-Green-Refactor methodology with 12 rationalization-prevention entries. The systematic-debugging skill contains a structured investigation methodology with 8 red flags and 8 excuse/reality pairs. The verification-before-completion skill contains a verification methodology built from "24 failure memories." Each skill is a self-contained knowledge artifact that teaches the agent both what to do and why, plus how to resist the temptation to cut corners.

The TDD-for-skills methodology (`writing-skills` skill) provides a quality assurance mechanism for knowledge artifacts themselves. Skills are treated as "code that shapes agent behavior" — tested with adversarial pressure scenarios, refined through red-green-refactor cycles, and hardened against observed rationalization patterns. Each row in a rationalization prevention table represents a real evasion observed in agent sessions and plugged empirically.

The CSO discovery that skill descriptions should never summarize workflows (because agents follow the summary instead of reading the full skill) is itself a knowledge management finding — it reveals how the format of knowledge delivery affects agent behavior.

### Academic Validation

The Codified Expert Knowledge study (Ulan uulu et al.) demonstrated 206% quality improvement when agents operate with properly codified domain knowledge. The distinction between tacit knowledge (how to approach problems) and explicit knowledge (specific patterns and rules) maps precisely to the GSD/Superpowers split: Superpowers codifies tacit knowledge through behavioral conditioning, GSD codifies explicit knowledge through reference documents and templates. Both forms are necessary and require different testing approaches — tacit knowledge needs adversarial pressure testing (Superpowers' TDD-for-skills), explicit knowledge needs drift detection (Codified Context Infrastructure's validation scripts).

Codified Context Infrastructure's central insight — that documents become "load-bearing infrastructure" with agents depending on them for correct behavior — validates both systems' heavy investment in knowledge artifacts while warning that stale knowledge causes incorrect output.

### Open-Source Validation

Codified Context Infrastructure is the only analyzed framework that treats knowledge management as its primary product. Its factory patterns (constitution-factory, agent-factory, context-factory) provide more structured bootstrapping than GSD's templates, and its drift detection scripts address a gap neither GSD nor Superpowers fills. The three-tier memory model provides an explicit framework for organizing knowledge by access pattern: always-loaded (constitution/system prompt), task-specific (agent specs/skills), and on-demand (knowledge base/references).

### Comparative Assessment

GSD provides **systematic knowledge organization** — structured registers, reference libraries, template systems, and defined propagation chains that ensure knowledge reaches the right agents. Superpowers provides **behaviorally effective knowledge delivery** — iron laws, rationalization prevention tables, and gate functions that don't just inform the agent but actively shape its behavior in the moment of decision. GSD's knowledge is broad and well-organized but passive (the agent must choose to apply it). Superpowers' knowledge is narrow and deeply effective but incomplete (covering only the topics its 14 skills address). The unified methodology should combine GSD's organizational infrastructure with Superpowers' behavioral delivery mechanisms — using GSD's registers and reference libraries for breadth, with Superpowers' iron laws and rationalization prevention for the highest-stakes knowledge that must not be forgotten or rationalized away.

---

## Cross-Dimensional Synthesis

Three patterns emerge across all nine dimensions that should directly inform the synergy/conflict map and M002 design:

**Pattern 1: Infrastructure vs Psychology.** In every dimension, GSD operates through infrastructure (code, tools, state machines, file locks, automated verification) while Superpowers operates through psychology (iron laws, rationalization prevention, gate functions, anti-sycophancy protocols). These are genuinely complementary — infrastructure catches what psychology misses (state corruption, concurrent access, stub detection), and psychology catches what infrastructure misses (agent reasoning quality, verification discipline, resistance to shortcuts). The unified methodology needs both layers.

**Pattern 2: Complexity vs Portability.** GSD's comprehensive infrastructure comes with significant complexity — 21 agents, 60 workflows, 19 CLI modules, a 16K-line SDK. Superpowers' behavioral approach achieves comparable per-dimension outcomes with dramatically lower complexity — 14 skill files and zero code. But GSD's complexity buys capabilities Superpowers cannot replicate: multi-agent parallelism, persistent state across sessions, programmatic security scanning. The unified methodology must calibrate complexity to the capabilities it actually needs, using Superpowers' minimalism as a design pressure against unnecessary infrastructure.

**Pattern 3: Breadth vs Depth.** GSD covers more ground — state management, context engineering, multi-runtime support, SDK, 42 templates, 25 references. Superpowers goes deeper on fewer topics — TDD has a 12-row rationalization prevention table, verification has 24 failure memories distilled into a gate function, skill creation has a full red-green-refactor methodology. The unified methodology should adopt GSD's breadth for system-level concerns (state, context, orchestration) and Superpowers' depth for behavior-level concerns (verification discipline, planning rigor, reasoning quality).

These patterns define the design space for the synergy map that follows in `research/synergy-map.md`.
