# Core Design Principles

**Version:** 0.1 — Design specification for community readability
**Status:** Initial specification; grounding each principle in M001 academic research
**Parent:** `design/architecture-overview.md` — Section: Introduction & Design Philosophy (two-layer architecture rationale) and Appendix B (downstream spec map)
**Research Grounding:** `research/synergy-map.md` Section 4 (7 design principles), `research/academic-literature-review.md` (7 academic papers)

---

## Introduction

This document expands the seven design principles that constrain every architectural decision in the unified methodology. These principles are not aspirational goals — they are engineering constraints. Every component, skill, agent, and infrastructure service must be consistent with all seven principles, or it does not belong in the methodology.

**Who this document is for:** Developers encountering the methodology for the first time. Each principle is explained in plain language with concrete examples. You do not need to have read the M001 research papers to understand what each principle means and why it matters. The academic citations are provided for those who want to trace the reasoning, not as prerequisites for understanding.

**How these principles were derived:** During M001, we analyzed two existing AI coding agent systems (GSD and Superpowers), reviewed seven academic papers on AI-assisted software engineering, and surveyed six open-source agent frameworks. The analysis revealed patterns that appeared independently across multiple sources — findings that different research groups arrived at without knowledge of each other's work. These seven principles capture the patterns with the strongest cross-source validation.

**How these principles constrain the methodology:** Every design decision in the methodology must be consistent with all seven principles. When principles create tension — and they do — the resolution must be explicit. For example, Principle 4 (state scales with project scope) creates tension with Principle 1 (behavioral layer is the foundation) because stateless projects still need behavioral enforcement. The resolution: behavioral directives are constants across all state tiers; state management is the variable. These interactions are documented in the Principle Interactions section at the end.

---

## Principle 1: Behavioral Layer Is the Foundation; Infrastructure Layer Is the Amplifier

### The Principle

Every quality-critical behavior — verification discipline, test-driven development, root-cause-first debugging, planning before implementation — must be expressible as a standalone skill file with zero runtime dependencies. The infrastructure layer (hooks, CLI tools, state management) amplifies these behaviors with enforcement and persistence but is never required for them.

### What This Means in Plain Language

The methodology has two layers, and they are not equal. The behavioral layer — Markdown files containing iron laws, gate functions, and rationalization prevention tables — is the foundation. It works by itself, on any platform that can read Markdown, with no installation and no runtime code. The infrastructure layer — Node.js hooks, CLI tools, a state management service — adds enforcement on top of that foundation. It catches the cases where behavioral directives alone are not enough, like concurrent state access or programmatic stub detection.

Think of it like building safety codes versus building inspectors. The codes (behavioral layer) tell you how to build safely. The inspectors (infrastructure layer) verify that you actually did. A builder who follows the codes without inspectors produces a safe building. An inspector who checks a building with no codes has nothing to verify against. You need both, but the codes come first.

### Concrete Example

Consider verification. The behavioral layer contains the verification gate function — a five-step sequence (IDENTIFY → EXECUTE → INSPECT → JUDGE → CLAIM) that an agent must follow before claiming any work is complete. This gate function lives in a Markdown skill file. If the infrastructure layer is unavailable, the agent still follows the gate function because the behavioral directive shapes its reasoning.

The infrastructure layer adds programmatic stub detection — automated scanning for empty event handlers, hardcoded values, and implementations that look real but contain no logic. This catches failure modes the agent cannot self-recognize, even when following the gate function faithfully.

A developer using only the behavioral layer (skill files, no CLI tools) gets an agent that diligently runs verification. A developer adding the infrastructure layer gets an agent that diligently runs verification AND has an independent programmatic check confirming the code is structurally complete.

### Academic Grounding

**Scaffolding over model capability (SASE, Hassan et al., 2025; Confucius Code Agent, Wong et al., 2025).** Two independent research efforts converge on a finding that challenges the dominant narrative in AI development: the quality of the scaffolding surrounding an AI agent matters more than the capability of the underlying model. The Confucius Code Agent with Claude 4 Sonnet outperformed simpler scaffolds with the more capable Claude 4.5 Sonnet — a 6.6 percentage point improvement attributable entirely to scaffolding quality, not model upgrade. SASE frames this as the "Agent Command Environment" and "Agent Execution Environment" — the workbenches that determine an agent's performance ceiling. The unified methodology treats the behavioral layer as the primary scaffolding investment, with the infrastructure layer as an additional enforcement scaffold.

**The scaffolding/harness distinction (OpenDev, Bui, 2026).** OpenDev draws a critical separation between scaffolding (what the agent knows before the first prompt) and harness (how the agent is managed during execution). The behavioral layer maps to scaffolding — it shapes the agent's reasoning from the start. The infrastructure layer maps to harness — it manages the agent's execution at runtime. Both are needed, but scaffolding is the foundation.

### Cross-References

- `design/architecture-overview.md`, Section: Two-Layer Architecture — defines the behavioral and infrastructure layers, their composition, and their interaction model
- `design/architecture-overview.md`, Section: Introduction & Design Philosophy — establishes the "Infrastructure vs Psychology" meta-pattern that motivates the two-layer architecture
- `design/verification-pipeline.md`, Section: Overview — explains why both layers are needed for verification (Failure Mode 1 requires behavioral enforcement; Failure Mode 2 requires programmatic detection)

### What This Means for a Developer Using the Methodology

- **If you install only the skill files:** You get a fully functional methodology. Your AI agent follows verification discipline, plans before implementing, and debugs systematically. You lose enforcement guarantees (no programmatic stub detection, no state locking), but the behavioral quality bar is maintained.
- **If you install the full extension:** You get the behavioral layer plus programmatic enforcement. The infrastructure layer adds safety nets, not new behaviors. It catches the cases where your agent's behavioral compliance is not enough — empty handlers that pass superficial review, concurrent state mutations, prompt injection attempts.
- **When building new components:** Ask "does this belong in a skill file or a CLI tool?" If it shapes how the agent thinks, it is a skill. If it checks what the agent produced, it is infrastructure. If it does both, split it.

---

## Principle 2: Context Is the Primary Engineering Investment

### The Principle

Every architectural decision should be evaluated through the lens of context quality. What information reaches the agent, when, and in what form determines output quality more than any other factor. The three-tier memory model — hot memory (always loaded), warm memory (loaded per task), and cold memory (queried on demand) — is an explicit architectural commitment, not an emergent property.

### What This Means in Plain Language

An AI agent's output is only as good as the information it can see. A brilliant model with poor context produces worse results than an average model with excellent context. This is not theoretical — it is empirically demonstrated across multiple research studies. The methodology treats context engineering as its most important design activity.

Context has three tiers, each with different loading strategies and cost profiles:

1. **Hot memory** — Always loaded at session start. Iron laws, project brief, current task context. This is the information the agent needs for every interaction. It must be compact (it consumes context budget on every turn) and high-density (maximum behavioral impact per token).

2. **Warm memory** — Loaded when relevant. Skill files, agent definitions, task-specific knowledge. This is the information the agent needs for specific tasks. It is loaded on demand and unloaded when the task changes.

3. **Cold memory** — Queried when needed. Reference documents, knowledge base entries, historical decisions. This information is available but not preloaded — the agent retrieves it when a specific question arises.

### Concrete Example

When an agent starts a debugging session, it receives: the iron law for systematic debugging in hot memory (always loaded, shapes its approach), the systematic-debugging skill in warm memory (loaded because the task is debugging), and any relevant KNOWLEDGE.md entries about prior similar bugs in cold memory (queried if the agent searches for precedent). The hot-memory iron law ensures the agent follows root-cause-first investigation. The warm-memory skill provides the detailed debugging protocol. The cold-memory knowledge base prevents the agent from repeating investigations already done in prior sessions.

If the debugging iron law were in cold memory instead of hot, the agent might begin debugging without it — and fall into the common trap of guess-and-check thrashing before retrieving the directive. The tier placement is an engineering decision with real behavioral consequences.

### Academic Grounding

**Three-tier memory model (Codified Context Infrastructure, Vasilopoulos, 2026).** Built and validated across 283 development sessions producing a 108,000-line system, the three-tier architecture — hot-memory constitution, warm-tier specialized agents, cold-memory knowledge base — was "created when agents made mistakes, not as a planning exercise." Each tier emerged from observed failures: the constitution exists because agents without it made inconsistent decisions; specialized agents exist because generic prompts lacked domain depth; the knowledge base exists because agents repeated prior mistakes.

**Hierarchical working memory (Confucius Code Agent, Wong et al., 2025).** Confucius implements session-level working memory, project-level persistent notes, and "hindsight notes" that capture what the agent would have done differently. This creates a learning loop that improves future sessions. The unified methodology extends this concept through KNOWLEDGE.md as a cross-session learning register with structured entries.

**Context as the bottleneck (all seven papers reviewed).** Every system studied treats context management as the primary engineering challenge. The unified methodology inherits this finding as a design axiom: when in doubt about where to invest engineering effort, invest in context quality.

**Stale context harms (Codified Context Infrastructure, Vasilopoulos, 2026).** The research documents that stale context caused agents to "generate code conflicting with recent refactors." Context that falls behind reality is not merely unhelpful — it is actively harmful, producing confidently wrong output. This finding motivates the methodology's emphasis on keeping hot-memory content current and detecting drift in cold-memory documents.

### Cross-References

- `design/architecture-overview.md`, Section: Information Flow — defines how context flows between components through the three-tier memory model
- `design/architecture-overview.md`, Section: Component Map — shows the `context-management` skill and context monitor hook in the component inventory
- `design/tiered-state-system.md`, Section: Tier 1 — Lightweight — PROJECT.md serves as hot-tier context for Tier 1 projects
- `design/tiered-state-system.md`, Section: Behavioral Anchoring Across Tiers — all tiers implement context management through the same behavioral directives

### What This Means for a Developer Using the Methodology

- **When starting a project:** The most impactful thing you can do is write a clear project brief. A one-paragraph vision statement plus a list of constraints and key decisions gives your agent more useful context than hours of conversation history.
- **When adding knowledge:** Ask "which tier does this belong in?" Universal rules (always follow TDD) go in hot memory. Task-specific protocols (how to handle API pagination) go in warm memory. Historical decisions (why we chose PostgreSQL over MongoDB) go in cold memory.
- **When debugging poor output:** Before blaming the model, check the context. Is the agent seeing stale information? Is critical knowledge missing from its context window? Is the context budget consumed by low-value content? Context problems masquerade as model problems.

---

## Principle 3: Verification Is Dual-Layered and Non-Negotiable

### The Principle

Every completion claim passes through both behavioral verification (gate function: IDENTIFY → EXECUTE → INSPECT → JUDGE → CLAIM) and programmatic verification (stub detection, four-level artifact checking, independent codebase inspection). Neither layer can be disabled. Neither is a fallback for the other. Both run on every verification pass.

### What This Means in Plain Language

When an AI agent says "I'm done," two independent checks must confirm that claim:

1. **Did the agent actually verify its work?** (Behavioral layer.) The gate function ensures the agent named a specific verification command, ran it completely, read the full output, judged the results against the specific claim being made, and only then made the completion claim. This prevents the most common failure mode: agents that believe their code works based on reasoning alone, without running any tests.

2. **Is the work structurally complete?** (Programmatic layer.) Independent automated inspection scans the codebase for empty event handlers, hardcoded values masquerading as dynamic data, function signatures with no implementation behind them, and components that render filler content. This catches what the agent's own review cannot — structural gaps that look correct in a superficial reading.

These two layers address different failure modes. An agent can follow the gate function perfectly — run tests, read output, confirm passage — and still miss an empty handler that the tests do not cover. Conversely, programmatic stub detection can find every structural gap but cannot force the agent to care about fixing them. Both layers are necessary because each catches what the other misses.

### Concrete Example

An agent implements a search feature. Behavioral verification: the agent runs the test suite, reads the output (all 47 tests pass), and confirms the search feature works. Programmatic verification: the stub detector scans the codebase and finds that the search results component renders a hardcoded list rather than the actual search results — the test passes because the test checks the presence of search result elements, not their content.

Without the behavioral layer, the agent might skip testing entirely, claiming "the implementation is straightforward." Without the programmatic layer, the agent would claim success based on passing tests that do not exercise the actual data flow. Together, the two layers close the trust gap.

### Academic Grounding

**The speed-versus-trust gap (SASE, Hassan et al., 2025).** SASE identifies a fundamental tension: AI agents increase development speed but decrease trust in the output. The gap between what is produced and what is trustworthy widens as agent autonomy increases. Higher autonomy requires heavier verification infrastructure, not lighter — because the human is less involved in production, they need more automated confidence in the output. The dual-layer approach narrows this gap from both directions.

**The productivity-quality paradox (LLMs Reshaping SE, Tabarsi et al., 2025).** Interviews with 16 professional developers revealed that developers often discarded AI-generated code and shifted effort from writing code to evaluating it. Developers independently developed "layered verification" practices — checking AI output at multiple levels before accepting it. The dual-layer verification pipeline codifies this emergent professional practice into the methodology's architecture.

**Verification must be structural (cross-paper convergence).** SASE, the LLMs Reshaping SE study, and the Codified Context Infrastructure paper all converge on the same conclusion: verification cannot rely on agent discipline alone. It must be architecturally enforced through gates, automated checks, and independent validation. The behavioral layer enforces discipline; the programmatic layer enforces structural correctness.

### Cross-References

- `design/verification-pipeline.md`, Section: Overview — establishes the two failure modes (agent skips verification vs. agent misses structural problems) and why both layers are required
- `design/verification-pipeline.md`, Section: Layer 1 — Behavioral Verification (Gate Function) — the five-step gate sequence, the iron law of verification, and the rationalization prevention table
- `design/verification-pipeline.md`, Section: Layer 2 — Programmatic Verification (Independent Checking) — the four-level artifact checking model (Exists → Substantive → Wired → Functional)
- `design/verification-pipeline.md`, Section: Failure Recovery — node repair operator (RETRY, DECOMPOSE, PRUNE) for handling verification failures
- `design/architecture-overview.md`, Section: Pipeline Stages — verification as Stage 5 in the six-stage execution pipeline

### What This Means for a Developer Using the Methodology

- **You cannot skip verification for "simple" changes.** Simple changes have simple verifications. The gate function applies to every completion claim regardless of perceived task simplicity. Simple changes account for a disproportionate share of production incidents precisely because they bypass review.
- **"Tests pass" is necessary but not sufficient.** Passing tests confirm what is tested. Programmatic verification confirms what exists. A component can pass all tests and still contain hardcoded values, empty handlers, or filler content that the tests do not exercise.
- **Verification evidence must be fresh.** Evidence from a prior session, prior task, or prior attempt does not count. Each verification pass uses evidence generated during that pass. Stale evidence is not evidence.

---

## Principle 4: State Scales with Project Scope

### The Principle

The methodology does not impose a fixed state overhead. Three tiers — stateless (Tier 0), lightweight (Tier 1), and full orchestration (Tier 2) — scale state complexity with project complexity. Behavioral directives are active at all tiers. State management scales up only when needed. Tier escalation is automatic when project characteristics exceed the current tier's capabilities.

### What This Means in Plain Language

A 5-minute bug fix should not require creating directories, writing configuration files, or managing state artifacts. A 3-month multi-phase project needs persistent state for decisions, knowledge, and progress tracking. These are fundamentally different situations, and the methodology should not treat them the same way.

- **Tier 0 (Stateless):** No methodology files. No directories. The agent loads skills at session start and follows behavioral directives. When the session ends, nothing persists. This is the right choice for quick fixes, config changes, code reviews, and exploratory work.

- **Tier 1 (Lightweight):** Three Markdown files in a `.gsd/` directory: a project brief (PROJECT.md — what we are building), a knowledge register (KNOWLEDGE.md — what we have learned), and a decision log (DECISIONS.md — what we have decided). Human-editable, human-readable, no special tooling required. This is the right choice for multi-session features, refactoring projects, and anything that spans more than one session.

- **Tier 2 (Full Orchestration):** Complete state management with milestone tracking, slice decomposition, lockfile-based concurrency control, structured handoff artifacts, and progress metrics. This is the right choice for autonomous multi-phase execution where the agent operates without active human supervision.

The key insight: behavioral quality is constant across tiers. A Tier 0 project follows the same verification discipline as a Tier 2 project. The iron laws apply regardless of how much state is being tracked. State determines what persists between sessions; behavior determines what happens within each session.

### Concrete Example

A developer starts fixing a small CSS bug (Tier 0 — no state files). During investigation, they discover the CSS issue is a symptom of a larger layout architecture problem. They create a project brief and knowledge file (escalating to Tier 1) so they can track decisions across multiple sessions. If the refactoring grows into a multi-phase project requiring autonomous execution, the methodology escalates to Tier 2 with full state tracking. At every tier, the verification gate function applies identically.

### Academic Grounding

**Statelessness has real costs (Codified Context Infrastructure, Vasilopoulos, 2026).** The research demonstrates that agents without persistent context repeat mistakes and generate conflicting code. Knowledge accumulated during one session is lost in the next. For any project spanning multiple sessions — which is most real-world development — statelessness means repeating discovery work, re-making decisions, and losing accumulated understanding.

**State management has real costs (GSD v1.32 analysis, M001).** GSD's own evolution documents the maintenance burden of persistent state: version 1.32 specifically added STATE.md consistency gates to address state corruption bugs, and anti-pattern rule #15 prohibits direct file edits because they bypass lockfile-based mutual exclusion. Every state mutation is a potential corruption point. Every state file is a maintenance obligation.

**The resolution: proportional investment (SASE autonomy levels, Hassan et al., 2025).** SASE proposes that autonomy should be task-dependent, not system-wide. The same principle applies to state: state complexity should be task-dependent. The three-tier model allows each project to operate at the state level appropriate for its complexity, avoiding both the overhead of unnecessary state and the amnesia of insufficient state.

### Cross-References

- `design/tiered-state-system.md`, Section: Overview: Why Proportional State — the full rationale for three tiers
- `design/tiered-state-system.md`, Section: Tier 0 — Stateless — zero-overhead definition and the "zero-overhead test"
- `design/tiered-state-system.md`, Section: Tier 1 — Lightweight — the three artifacts (PROJECT.md, KNOWLEDGE.md, DECISIONS.md)
- `design/tiered-state-system.md`, Section: Tier 2 — Full Orchestration — complete state management specification
- `design/tiered-state-system.md`, Section: Tier Detection Heuristics — how the methodology determines which tier a project needs
- `design/tiered-state-system.md`, Section: Escalation Mechanics — how projects move between tiers without losing prior work
- `design/tiered-state-system.md`, Section: Feasibility Assessment — D006 validation results

### What This Means for a Developer Using the Methodology

- **Start at Tier 0.** Unless you know you need persistent state, do not create state files. Let the methodology escalate naturally when your project grows beyond a single session.
- **Tier 1 requires only three files.** If you need cross-session memory, create `.gsd/PROJECT.md`, `.gsd/KNOWLEDGE.md`, and `.gsd/DECISIONS.md`. That is the entire state setup. No configuration, no CLI initialization, no build steps.
- **Tier 2 activates automatically.** When you use orchestrated mode (auto-mode milestones), the methodology bootstraps full state management. You do not need to set it up manually.
- **Behavioral quality does not depend on state tier.** Your agent follows the same verification discipline, the same debugging protocol, and the same planning standards regardless of whether you are at Tier 0, 1, or 2.

---

## Principle 5: Skills Are Tested Behavioral Specifications, Not Documentation

### The Principle

Every skill file is executable behavioral code — it shapes agent reasoning the way a program shapes computation. Skills are validated through adversarial pressure testing: run pressure scenarios without the skill (observe natural agent behavior), load the skill (verify compliance), then close loopholes (refine rationalization prevention tables). Each row in a rationalization prevention table represents a real evasion observed in testing, not a hypothetical concern.

### What This Means in Plain Language

Skills are not documentation that agents might read and follow. They are behavioral specifications that agents must comply with. The difference matters: documentation tells the agent what to do; a behavioral specification changes how the agent thinks about what it is doing.

Consider the difference between a documentation page that says "run tests before claiming completion" and an iron law that says "skipping verification is lying, not just cutting corners." The documentation version is a suggestion the agent can weigh against other priorities (time, confidence, simplicity). The iron law version reframes skipping verification as a violation of the agent's honesty — activating alignment training that is harder to rationalize away than a process suggestion.

This distinction is why skills are tested through adversarial pressure, not just written from best practices. The TDD-for-skills methodology works like test-driven development for code:

1. **Red:** Present the agent with a pressure scenario — a situation where it is tempted to cut corners (tight deadline, high confidence, simple-seeming task). Observe what it does without the skill loaded.
2. **Green:** Load the skill. Present the same pressure scenario. Verify the agent now follows the desired behavior.
3. **Refactor:** If the agent finds a way to rationalize non-compliance despite the skill, add the rationalization to the prevention table. Retest.

### Concrete Example

The TDD iron law has a 12-row rationalization prevention table. Row 1: "This is too simple for tests" → Reality: "Simple code deserves simple tests. If it is really that simple, writing the test takes 30 seconds." Row 12: "The tests are passing anyway" → Reality: "Tests that existed before your change do not validate your change. Write tests for the new behavior." Each row was discovered during adversarial testing — a real scenario where an agent found a way to rationalize skipping TDD despite the iron law. The table is a living document that grows as new evasion patterns are observed.

### Academic Grounding

**The 206% quality improvement (Codified Expert Knowledge, Ulan uulu et al., 2026).** This study demonstrates that non-experts achieved expert-level outcomes when AI agents operated with properly codified domain knowledge — a 206% improvement over agents without such knowledge. The key distinction is between "tacit" knowledge (how to approach problems — habits, instincts, judgment) and "explicit" knowledge (specific patterns, rules, and checklists). Skills codify tacit expert knowledge: they encode the habits and instincts of skilled developers into behavioral directives that shape agent reasoning. This is fundamentally different from reference documents, which codify explicit knowledge (specific patterns and rules).

**Documents as load-bearing infrastructure (Codified Context Infrastructure, Vasilopoulos, 2026).** Vasilopoulos's key insight is that context documents become "load-bearing infrastructure" — agents depend on them for correct behavior the same way a building depends on structural members. When a context document goes stale, agents produce incorrect output. When it is accurate, agents perform reliably. This finding elevates skills from "helpful guidance" to "critical infrastructure" requiring the same engineering discipline as production code: version control, drift detection, and adversarial testing.

**Skill description content matters (CSO discovery, Superpowers research).** The methodology's research discovered that skill descriptions should contain only triggering conditions, never workflow summaries — because agents follow the summary instead of reading the full skill. This finding about how description content affects agent behavior underscores that skills are behavioral specifications: even their metadata must be engineered for behavioral impact, not human readability.

### Cross-References

- `design/architecture-overview.md`, Section: Component Map — the 18-skill catalog with traceability to synergies and principles
- `design/architecture-overview.md`, Section: Two-Layer Architecture — skills as the foundation of the behavioral layer
- `design/architecture-overview.md`, Appendix A: Component Traceability Matrix — each skill traced to its research source and governing principle
- `design/verification-pipeline.md`, Section: Layer 1 — Behavioral Verification (Gate Function) — the verification skill as a concrete example of a behavioral specification in action

### What This Means for a Developer Using the Methodology

- **Treat skills as code, not documentation.** When modifying a skill, test it adversarially. Present your agent with pressure scenarios and verify compliance. A skill that reads well but fails under pressure is a broken skill.
- **Read the rationalization prevention tables.** They tell you exactly how agents try to bypass the skill's intent. Each row is a battle-tested defense against a specific evasion pattern. If your agent is not following a skill, check whether it is using one of these rationalizations.
- **New skills must earn their place.** A skill is not added to the methodology because someone thinks it is a good idea. It is added because adversarial testing demonstrates that without it, agents fail in specific, documented ways. The red-green-refactor cycle for skills ensures every skill addresses a real behavioral gap.

---

## Principle 6: Agent Definitions Combine Capability Contracts with Behavioral Specifications

### The Principle

Every agent in the unified methodology has two components: a capability specification (role, tools, model tier, completion markers, handoff schemas) and a behavioral specification (which skills govern this agent's reasoning). Capability specifications define what the agent can do; behavioral specifications define how the agent should think while doing it. Both are expressed declaratively in Markdown or YAML.

### What This Means in Plain Language

An agent definition is not just a job description — it is a complete operating specification. It tells the system both what the agent is equipped to do and how the agent should reason while doing it.

The **capability specification** answers infrastructure questions: What tools can this agent access? What model tier should it run on? What does a "done" signal look like? What data does it hand off to the next agent?

The **behavioral specification** answers reasoning questions: What iron laws must this agent follow? What gate functions constrain its decisions? What rationalization patterns should it watch for in its own thinking?

Neither alone is sufficient. An agent with clear capabilities but no behavioral conditioning — it knows what tools it has but not how to think about quality — produces structurally correct but behaviorally undisciplined output. An agent with strong behavioral conditioning but no capability contract — it thinks carefully about quality but has unclear tool boundaries — produces well-reasoned decisions about the wrong things.

### Concrete Example

The `verifier` agent has a capability specification: it runs on a quality-tier model, has access to file reading and command execution tools, receives a SUMMARY.md from the executor as input, and produces a verification report as output. It also has a behavioral specification: it operates with a distrust mindset (does not trust the executor's claims in the summary), follows the dual-layer verification pipeline, and applies the verification iron law.

The capability spec tells the system to spawn the verifier with the right tools and model. The behavioral spec tells the verifier to be skeptical, thorough, and honest in its assessment. Without the capability spec, the verifier might not have the tools it needs. Without the behavioral spec, the verifier might rubber-stamp the executor's claims.

### Academic Grounding

**Three-way convergence on declarative agent definitions (GSD, Google ADK, Superpowers).** Three independent systems — GSD's 21-agent registry with typed contracts, Google's Agent Development Kit with declarative YAML configuration, and Superpowers' skill-based agent specialization — all arrived at declarative agent definition. This cross-framework convergence validates that agents should be defined as configuration, not code. The unified methodology extends this pattern by requiring both capability and behavioral components in every definition.

**Single parameterized agent over class hierarchy (Confucius Code Agent, Wong et al., 2025).** Confucius discovered that a single agent definition parameterized for different roles outperforms a class hierarchy of specialized agents. This finding informed the methodology's consolidation of GSD's 21 agents to 12 — achieved by parameterizing agents that performed the same function with different inputs (four researchers became one parameterized `researcher` agent, four mappers became one parameterized `mapper` agent).

**Domain knowledge in agent specifications (Codified Expert Knowledge, Ulan uulu et al., 2026).** The Codified Context Infrastructure research found that "over half of each agent specification is domain knowledge, not behavioral instructions." This means agent definitions are not just behavioral wrappers — they are knowledge delivery vehicles. The capability specification carries domain knowledge (what the agent needs to know about its role); the behavioral specification carries process knowledge (how the agent should approach its role).

### Cross-References

- `design/architecture-overview.md`, Section: Execution Modes — how agent definitions are used differently in interactive mode (adopted as skill sets) versus orchestrated mode (formally instantiated as subprocesses)
- `design/architecture-overview.md`, Section: Component Map — the 12-agent registry with role descriptions
- `design/architecture-overview.md`, Appendix A: Component Traceability Matrix — each agent traced to its research source
- `design/architecture-overview.md`, Appendix B: Downstream Specification Map — S03 (Agent & Reference Specification) provides detailed agent definitions

### What This Means for a Developer Using the Methodology

- **In interactive mode:** You do not spawn agents explicitly. Instead, the single primary agent adopts the behavioral specification of the relevant agent definition by loading its skills. When you need the agent to think like a verifier, it loads the verification skills. The capability specification (model tier, tool permissions) is inherited from your session context.
- **In orchestrated mode:** Agent definitions are formally instantiated. The orchestrator spawns each agent with its capability specification (tools, model tier) and behavioral specification (iron laws, gate functions). Each spawned agent gets a fresh context window with both components.
- **When defining new agents:** Always specify both components. A capability-only definition produces an agent that has the right tools but the wrong approach. A behavior-only definition produces an agent that thinks correctly but lacks the right resources.

---

## Principle 7: The Methodology Is Opinionated About Quality, Flexible About Process

### The Principle

The behavioral directives — verification discipline, TDD compliance, root-cause-first debugging, planning before implementation — are non-negotiable. They apply to every task regardless of complexity, execution mode, or state tier. The process infrastructure — execution mode, state tier, parallelism strategy, model selection — is flexible and adapts to project characteristics, developer preferences, and task requirements. Iron laws are absolute; workflows are configurable.

### What This Means in Plain Language

The methodology draws a hard line between two categories of decisions:

**Non-negotiable quality constraints (iron laws):**
- You cannot claim work is complete without fresh verification evidence.
- You cannot fix a bug without first investigating its root cause.
- You cannot implement before planning when the task is non-trivial.
- You cannot skip verification for "simple" changes.
- You cannot bypass the brainstorming gate for new features.

**Configurable process choices (workflows):**
- Interactive mode or orchestrated mode? Your choice.
- Tier 0, Tier 1, or Tier 2 state? Depends on your project.
- Sequential or parallel task execution? Based on dependency analysis.
- Quality-tier or budget-tier model? Depends on the task complexity.
- Full TDD or test-after? Depends on the development context (though TDD is strongly preferred).

This distinction matters because it prevents two common failure modes: (1) methodologies that are so rigid about process that developers abandon them for simple tasks, and (2) methodologies that are so flexible about quality that developers rationalize skipping verification when under pressure.

### Concrete Example

A developer fixing a one-line typo (Tier 0, interactive mode, no plan needed) still runs the verification gate function — they cannot claim the fix is done without running the build or tests. The process is minimal (no plan, no state files, no formal task decomposition), but the quality constraint is identical to a developer running a multi-phase autonomous refactoring (Tier 2, orchestrated mode, full planning pipeline).

Conversely, two developers working on the same project can use different execution modes. Developer A prefers interactive mode and guides the agent through each task. Developer B prefers orchestrated mode and lets the agent handle task decomposition autonomously. Both produce the same quality output because the iron laws apply identically — only the orchestration differs.

### Academic Grounding

**Phase-dependent AI suitability (LLMs Reshaping SE, Tabarsi et al., 2025).** The empirical study found that AI effectiveness varies by development phase — strong in implementation and debugging, weaker in requirements gathering and architectural design. This validates process flexibility: the methodology should adapt its process to the phase (more human involvement in architecture, more agent autonomy in implementation) while maintaining constant quality constraints across all phases.

**Per-task autonomy (SASE, Hassan et al., 2025).** SASE proposes autonomy levels that vary per task, not per system. The same agent should operate at different autonomy levels for different tasks within the same session. The methodology implements this through configurable execution modes and state tiers while keeping quality constraints (verification, debugging discipline) constant regardless of the autonomy level selected.

**Event-driven behavioral reinforcement (OpenDev, Bui, 2026).** OpenDev identifies "instruction fade-out" — agents gradually forget system prompt guidelines over long conversations — and proposes event-driven system reminders as the solution. The methodology's hook system can reinject iron laws at strategic points during execution, ensuring that quality constraints persist even through long sessions where the agent might otherwise drift. The quality constraints are architecturally reinforced, not dependent on the agent's memory.

### Cross-References

- `design/architecture-overview.md`, Section: Execution Modes — the two configurable execution modes (interactive and orchestrated)
- `design/architecture-overview.md`, Section: Design Constraints & Tradeoffs — the tradeoffs acknowledged for two execution modes, three state tiers, and Claude Code-only distribution
- `design/tiered-state-system.md`, Section: Behavioral Anchoring Across Tiers — demonstrates that behavioral directives are constants while state management is variable
- `design/verification-pipeline.md`, Section: Interactive Mode Verification — how verification applies in interactive mode
- `design/verification-pipeline.md`, Section: Orchestrated Mode Verification — how verification applies in orchestrated mode (same standards, different enforcement mechanisms)

### What This Means for a Developer Using the Methodology

- **Quality is not optional.** You can choose your execution mode, your state tier, your parallelism strategy. You cannot choose to skip verification, bypass the brainstorming gate, or claim completion without evidence. These are not configurable.
- **Process adapts to you.** The methodology does not prescribe a single workflow for all situations. A quick bug fix follows a minimal process. A new feature follows a thorough planning-first process. A multi-phase project follows a fully orchestrated process. The process scales; the quality does not.
- **Iron laws apply even under pressure.** When deadlines are tight and the temptation to skip verification is strongest, the iron laws are most important. The rationalization prevention tables specifically address time-pressure evasions because they are the most common and most damaging.

---

## Principle Interactions

The seven principles do not operate in isolation — they reinforce and constrain each other. Understanding these interactions is essential for making architectural decisions that must balance competing concerns.

### Verification + Tested Skills = Quality Assurance Loop

Principles 3 (verification is dual-layered) and 5 (skills are tested behavioral specifications) create a self-reinforcing quality loop. The verification pipeline validates work output. The TDD-for-skills methodology validates the behavioral directives that drive the verification pipeline. When a new verification evasion pattern is discovered (an agent finds a way to satisfy the gate function without genuinely verifying), it becomes a new row in the rationalization prevention table — and that table is itself tested adversarially. Quality assurance feeds back into itself.

### Context Investment + State Scaling = Efficient Knowledge Management

Principles 2 (context is the primary investment) and 4 (state scales with scope) together determine how the methodology manages knowledge across sessions. At Tier 0, context investment is limited to skill loading — the hot-memory content that shapes immediate behavior. At Tier 1, context investment expands to include a project brief and knowledge register — warm-memory content that provides cross-session continuity. At Tier 2, context investment includes the full state machine — cold-memory content that enables autonomous multi-phase execution. The context tiers (hot/warm/cold) and the state tiers (0/1/2) are parallel architectures that reinforce each other.

### Behavioral Foundation + Opinionated Quality = Portable Standards

Principles 1 (behavioral layer is the foundation) and 7 (opinionated about quality, flexible about process) together ensure that quality standards are portable across platforms. Because the quality constraints (iron laws, gate functions) live in the behavioral layer (zero dependencies, pure Markdown), they can be deployed on any platform — even platforms that cannot run the infrastructure layer. A developer using only skill files on a platform without Node.js still gets the same quality constraints as a developer using the full extension on Claude Code. Process flexibility (execution mode, state tier) requires the infrastructure layer, but quality does not.

### Agent Definitions + Dual-Layer Verification = Accountable Execution

Principles 6 (agents combine capability and behavioral specs) and 3 (verification is dual-layered) together create accountable execution in orchestrated mode. Each agent has clear capability boundaries (what it is equipped to do) and behavioral expectations (how it should approach quality). The dual-layer verification pipeline independently confirms that the agent's output meets both the behavioral standard (the gate function was followed) and the structural standard (the code is complete and connected). The verifier agent specifically operates with a distrust mindset — it does not trust the executor's behavioral claims, treating them as hypotheses to be independently confirmed.

### Tested Skills + Agent Definitions = Composable Quality

Principles 5 (skills are tested behavioral specs) and 6 (agents combine capability and behavioral specs) together enable composable quality. Because each skill is independently tested for behavioral compliance, and each agent definition references specific skills, the quality of an agent's behavior is the composition of its skills' tested behaviors. If the verification skill passes adversarial testing, and the debugging skill passes adversarial testing, then an agent loading both skills inherits both tested behaviors. This composability means new agents can be constructed from tested components rather than requiring end-to-end behavioral validation from scratch.

### State Scaling + Verification = Proportional Rigor

Principles 4 (state scales) and 3 (verification is non-negotiable) interact to create proportional rigor. At Tier 0, verification is behavioral-only (the gate function runs, but there is no persistent record of verification results). At Tier 1, verification results can be appended to KNOWLEDGE.md as learned outcomes. At Tier 2, verification is fully recorded — every verification pass produces structured artifacts (SUMMARY.md, VERIFICATION.md) that enable regression detection and audit trails. The verification bar is constant; the verification infrastructure scales with state tier.

### Context Investment + Tested Skills = Effective Behavioral Delivery

Principles 2 (context is the primary investment) and 5 (skills are tested behavioral specs) together determine how behavioral content should be structured for maximum impact. Because context budget is finite and skill content competes for space, every token in a skill file must earn its place through demonstrated behavioral impact. The CSO discovery (descriptions contain only triggering conditions, not workflow summaries) is a direct consequence of this interaction — skill descriptions are optimized for accurate invocation, not human readability, because misallocated context budget degrades overall behavioral effectiveness.

---

## Summary

These seven principles — behavioral foundation, context investment, dual-layer verification, proportional state, tested skills, dual-specification agents, and opinionated quality — form the engineering constraints for the unified methodology. They are not independent rules applied separately but an interconnected system where each principle reinforces the others.

A developer new to the methodology needs to internalize three things from these principles:

1. **Quality is structural, not aspirational.** The methodology builds quality into its architecture through iron laws, gate functions, and dual-layer verification. Quality is not a goal to strive for — it is a constraint that cannot be bypassed.

2. **Context determines output.** What the agent sees matters more than which model the agent runs on. Investing in clear project briefs, well-structured knowledge, and accurate context documents yields higher returns than any model upgrade.

3. **Start simple, scale as needed.** The methodology does not impose overhead proportional to its maximum capability. Start at Tier 0 with behavioral directives only. Add state when your project needs cross-session memory. Add full orchestration when your project needs autonomous multi-phase execution. The behavioral quality bar is constant at every level.

Each principle is grounded in empirical evidence from academic research: the scaffolding-over-model-capability finding (SASE, Confucius), the three-tier memory model (Codified Context Infrastructure, Confucius), the speed-versus-trust gap (SASE), the 206% knowledge amplification (Codified Expert Knowledge), the documents-as-infrastructure discovery (Codified Context Infrastructure), the productivity-quality paradox (LLMs Reshaping SE), and the instruction fade-out phenomenon (OpenDev). These are not theoretical preferences — they are patterns validated across 283+ development sessions, 108,000+ lines of generated code, and interviews with 16 professional developers.
