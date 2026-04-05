# Research Synthesis: GSD × Superpowers Unified Methodology

**Date:** 2026-04-05
**Milestone:** M001 — Research & Analysis
**Purpose:** Entry-point document for the M001 research corpus. Start here before reading any individual analysis.

---

## Executive Summary

This research set out to answer a single question: what would a unified AI coding agent methodology look like if it combined GSD's programmatic infrastructure with Superpowers' behavioral shaping? Over six research documents totaling approximately 36,000 words, we analyzed two production systems (GSD v1.32 and Superpowers v5.0.7), reviewed seven academic papers spanning 283+ development sessions and 108,000+ lines of generated code, surveyed six open-source agent frameworks, compared both systems across nine dimensions, and mapped twelve synergies against four genuine conflicts.

The headline conclusion: **the two systems are more complementary than competing.** GSD provides the machinery — 21 specialized agents, wave-based parallel execution, lockfile-based state management, programmatic stub detection, and a nine-hook runtime integration layer. Superpowers provides the psychology — iron laws that resist rationalization, gate functions that frame shortcuts as dishonesty, and adversarially-tested behavioral directives that shape how agents think, not just what they produce. Infrastructure catches what psychology misses (state corruption, concurrent access, unrecognized stubs). Psychology catches what infrastructure misses (reasoning quality, verification discipline, resistance to shortcuts). Neither layer alone is sufficient for reliable autonomous execution.

The research converges on seven design principles and five concrete deliverables for M002, the milestone that will build the unified methodology. These are detailed in the final sections of this document. Each claim traces back to specific mechanisms analyzed in the source documents, cited by filename throughout.

---

## System Analysis Summary

### GSD: Programmatic Infrastructure at Scale

GSD v1.32 is a meta-prompting framework that sits between the user and AI coding agents, providing context engineering, multi-agent orchestration, spec-driven development, and persistent state management. The full analysis in `research/gsd-analysis.md` covers 14 sections across the system's five-layer architecture (Commands → Workflows → Agents → CLI Tools → File System), its 21 specialized agents organized into 12 functional categories, and its elaborate quality assurance pipeline.

GSD's core architectural signatures are: **fresh context per agent** (every spawned agent gets a clean context window, eliminating the quality degradation that accumulates in long conversations), **file-based persistent state** (all artifacts live as human-readable Markdown in `.planning/`, surviving context resets and remaining inspectable by both humans and agents), and **defense in depth** (seven overlapping quality gates from plan checking through UAT). The system's programmatic backbone — `gsd-tools.cjs` with 19 domain modules — provides atomic operations that keep state consistent, including lockfile-based mutual exclusion for concurrent access safety. The TypeScript SDK (16,623 lines) enables headless execution with event streaming.

GSD's key strength is enforcement — it structurally prevents incorrect state manipulation, catches stubs through pattern matching against known signatures, and verifies output through an independent verifier agent that explicitly distrusts executor self-reports. Its key limitation is complexity: 21 agents, 60 workflows, 42 templates, 25 references, and a multi-thousand-line installer create a substantial surface area to maintain and understand.

### Superpowers: Behavioral Shaping Through Prose

Superpowers v5.0.7 is a behavioral shaping system that controls AI agent quality through carefully-tuned prose directives embedded as skill documents. The full analysis in `research/superpowers-analysis.md` covers eight sections across the system's skill architecture, five behavioral shaping mechanisms, and its pipeline from brainstorming through execution and review.

Superpowers' core architectural signatures are: **zero dependencies** (the entire system is 14 skill files, one agent, and a session-start hook — no build step, no runtime code, no external packages), **iron laws with rationalization prevention** (absolute behavioral constraints paired with pre-enumerated tables of excuses and their counters, each row representing a real evasion observed in adversarial testing), and **gate functions** (structural barriers that frame violations as dishonesty rather than shortcuts, leveraging the model's alignment with honesty values). The TDD-for-skills methodology adapts test-driven development to skill creation itself — skills are "code that shapes agent behavior" and must be validated through pressure testing.

Superpowers' key strength is behavioral effectiveness — its iron laws, rationalization prevention tables, and gate functions achieve reliable behavioral compliance with zero runtime infrastructure. Its key limitation is scope: it has no state management, no context monitoring, no concurrent access protection, and no programmatic verification. It relies entirely on the host platform for these capabilities.

---

## Academic & Ecosystem Context

### What the Literature Validates

The academic literature review (`research/academic-literature-review.md`) synthesized seven papers organized around cross-cutting themes. Five findings appeared across multiple independent research efforts, establishing high-confidence design principles:

**Scaffolding matters more than model capability.** The Confucius Code Agent study (Wong et al.) provided the strongest empirical evidence: Claude 4 Sonnet with advanced scaffolding outperformed Claude 4.5 Sonnet with simpler scaffolding by 6.6 percentage points on SWE-Bench-Pro. SASE (Hassan et al.) independently framed this as the "agent onboarding" argument — a quickly-contextualized agent outperforms a brilliant but brittle one. Both GSD and Superpowers represent heavy investments in scaffolding, validating the approach through different modalities.

**Context is the universal bottleneck.** Every paper treated context — what the agent sees and when — as the primary engineering challenge. The Codified Context Infrastructure study (Vasilopoulos) built and validated a three-tier memory architecture across 283 development sessions, finding that context documents become "load-bearing infrastructure" that agents depend on for correct behavior. When those documents go stale, agents produce conflicting code — a maintenance cost neither GSD nor Superpowers currently monitors with automated drift detection.

**Three-tier memory is universal.** Two independent research efforts — Codified Context Infrastructure and Confucius Code Agent — arrived at remarkably similar hot/warm/cold memory architectures. The convergence validates separating always-loaded core instructions from task-specific knowledge and on-demand reference material.

**Verification must be structural.** SASE identified the "speed vs. trust gap" that widens as agent autonomy increases. The LLMs Reshaping SE study (Tabarsi et al.) found that developers frequently discarded generated code and shifted effort from writing to evaluating. Both findings argue that verification cannot rely on agent discipline alone — it must be architecturally enforced.

**Agent-facing and human-facing representations should be separate.** The Confucius SDK's AX/UX/DX separation revealed that optimizing artifacts for human readability can degrade agent performance, and vice versa. The unified methodology should design separate representation paths rather than forcing dual-purpose artifacts.

### What the Open-Source Landscape Reveals

The open-source analysis (`research/open-source-landscape.md`) examined six frameworks — CrewAI, LangGraph, AutoGen, OpenHands, Google ADK, and Codified Context Infrastructure — for adoptable patterns. Three meta-patterns emerged:

**Context engineering is converging on the three-tier model.** Independent implementations across multiple frameworks validate the hot/warm/cold architecture identified in the academic literature.

**Declarative agent definition is the industry standard.** Every framework supporting agent customization does so through configuration (YAML, JSON, Markdown) rather than code. GSD's agent Markdown files, Superpowers' SKILL.md files, and Google ADK's Agent Config all independently arrived at this pattern — a strong convergence signal.

**The gap is in knowledge engineering, not agent orchestration.** Five of six frameworks focus on how to run agents. Only Codified Context Infrastructure focuses on how to manage the context documents agents depend on. Yet the academic literature consistently identifies context quality as the primary effectiveness lever. This gap represents the unified methodology's largest opportunity.

The frameworks most relevant to M002 design are Codified Context Infrastructure (for its knowledge engineering patterns, drift detection, and factory-based bootstrapping), OpenHands (for its SDK-first architecture and evaluation infrastructure), and Google ADK (for declarative agent configuration and session rewind capabilities).

---

## Comparative Assessment

The nine-dimension comparison in `research/comparative-analysis.md` examined how GSD and Superpowers approach the same engineering challenges through fundamentally different mechanisms. The analysis covered architecture, execution model, planning, verification, state management, context engineering, security, agent definition, and knowledge management.

Three meta-patterns emerged across all nine dimensions:

**Infrastructure vs Psychology.** In every dimension, GSD operates through infrastructure (code, state machines, file locks, automated verification) while Superpowers operates through psychology (iron laws, rationalization prevention, gate functions). These are genuinely complementary. GSD's four-level programmatic verification (Exists → Substantive → Wired → Functional) catches stubs and empty handlers that slip past agent attention. Superpowers' behavioral gate function (IDENTIFY → RUN → READ → VERIFY → CLAIM) ensures the agent actually runs verification and reads output before making claims. Neither defense alone closes the "speed vs. trust gap" — together, they create a dual-layer defense that catches failures at both the reasoning and codebase levels.

**Complexity vs Portability.** GSD's comprehensive infrastructure buys capabilities Superpowers cannot replicate: multi-agent parallelism, persistent cross-session state, and programmatic security scanning. But this comes at significant complexity cost. Superpowers achieves comparable per-dimension outcomes with dramatically lower complexity — 14 skill files against GSD's hundreds of components. The unified methodology must use Superpowers' minimalism as a design pressure against unnecessary infrastructure, calibrating complexity to the capabilities it actually needs.

**Breadth vs Depth.** GSD covers more ground — state management, context engineering, multi-runtime support, SDK, templates, references. Superpowers goes deeper on fewer topics — TDD has a 12-row rationalization prevention table, verification has 24 failure memories distilled into a gate function, skill creation has a full red-green-refactor methodology. The unified methodology should adopt GSD's breadth for system-level concerns and Superpowers' depth for behavior-level concerns.

The dimension-by-dimension analysis yields specific recommendations: GSD's verification is stronger structurally (independent verifier, stub detection) while Superpowers' is stronger behaviorally (gate function, anti-sycophancy). GSD's planning is structurally verified (8-dimension plan checker) while Superpowers' is execution-ready (actual code in every step). GSD's state management is essential for multi-session projects while Superpowers' statelessness is a genuine feature for quick tasks. In each case, the strengths are additive rather than contradictory.

---

## Synergy & Conflict Resolution

The synergy and conflict map (`research/synergy-map.md`) translated the comparative patterns into engineering decisions for M002. It identified twelve specific synergy opportunities and four genuine conflicts.

### Twelve Synergies in Three Categories

The synergies cluster into three categories:

**Infrastructure + Psychology** (six synergies): GSD provides the structural mechanisms; Superpowers provides the behavioral content those mechanisms deliver. The highest-priority synergy (SYN-01) combines GSD's four-level verifier with Superpowers' gate function into a dual-layer verification defense. SYN-02 combines GSD's KNOWLEDGE.md persistent register with Superpowers' iron laws for persistent knowledge with behavioral enforcement. SYN-03 combines GSD's context monitoring with Superpowers' high-density skill content for managed context that is also maximally effective per token.

**Organization + Quality Assurance** (four synergies): GSD provides organizational infrastructure (registers, templates, contracts); Superpowers provides quality methodology (TDD-for-skills, anti-sycophancy, rationalization prevention). SYN-04 combines GSD's structural plan checker with Superpowers' extreme task granularity for plans that are both structurally sound and mechanically executable.

**Container + Contents** (two synergies): GSD manages the context container (monitoring, thresholds); Superpowers optimizes what fills it (dense skill content, CSO-informed descriptions).

### Four Conflicts and Their Resolutions

The four conflicts represent genuinely incompatible design philosophies where choosing one approach structurally precludes the other:

**Conflict 1 — Dependency Policy:** GSD requires Node.js for enforcement guarantees (lockfile-based state management, programmatic stub detection). Superpowers requires zero dependencies for portability. **Resolution:** A two-layer architecture where the behavioral layer (Markdown skill files) has zero runtime dependencies and the infrastructure layer (CLI tools, hooks) uses Node.js. The behavioral layer is the minimum viable methodology; the infrastructure layer amplifies it with enforcement. This resolution acknowledges that D002 (dependencies allowed) resolves the policy question while preserving Superpowers' zero-dependency philosophy for the behavioral layer.

**Conflict 2 — Execution Model:** GSD uses multi-agent orchestration with wave-based parallelism. Superpowers uses single-agent skill loading. **Resolution:** Two execution modes — interactive (single agent with skill loading, the default for focused development) and orchestrated (multi-agent pipeline for complex autonomous execution). Both modes share the same behavioral directives; only the delivery mechanism changes.

**Conflict 3 — State Philosophy:** GSD maintains a persistent state machine. Superpowers is entirely stateless. **Resolution:** Proportional state that scales with project complexity — Tier 0 (stateless) for single-session tasks, Tier 1 (lightweight) for multi-session projects, Tier 2 (full orchestration) for autonomous multi-phase execution. Behavioral directives are active at all tiers; state management scales up only when needed.

**Conflict 4 — Distribution Model:** GSD distributes as a complex npm package with a multi-runtime installer. Superpowers distributes as a minimal zero-dependency package. **Resolution:** The unified methodology distributes as a Claude Code extension (per D001) with a skill-first user surface. Skills are the primary interaction; infrastructure operates transparently behind them.

---

## Unified Methodology Direction

The synergy/conflict analysis produced seven design principles and five concrete deliverables that constrain M002's architecture. The full detail is in `research/synergy-map.md`; what follows is the distilled direction with the reasoning that makes this document more than a summary of existing conclusions.

### Seven Design Principles

1. **Behavioral layer is the foundation; infrastructure layer is the amplifier.** Every quality-critical behavior must be expressible as a standalone skill file with zero dependencies. Infrastructure amplifies these behaviors with enforcement but is not required for them. This means a developer using only skills gets a useful methodology; adding infrastructure gets a robust one.

2. **Context is the primary engineering investment.** The three-tier memory model (hot: system prompt + iron laws; warm: agent/skill definitions; cold: reference documents + knowledge base) is an explicit architectural commitment. Content follows Superpowers' density principles; delivery follows GSD's managed approach with budget monitoring.

3. **Verification is dual-layered and non-negotiable.** Every completion claim passes through both behavioral verification (gate function) and programmatic verification (stub detection, artifact checking). Neither layer can be disabled.

4. **State scales with project scope.** Tier 0 for quick tasks, Tier 1 for multi-session projects, Tier 2 for autonomous execution. Behavioral directives are constants across all tiers; state infrastructure is variable.

5. **Skills are tested behavioral specifications.** Every skill is validated through adversarial pressure testing (TDD-for-skills). Rationalization prevention tables are empirical, not theoretical — each row represents a real evasion observed in testing.

6. **Agent definitions combine capability contracts with behavioral specifications.** Every agent has both a capability specification (role, tools, model tier, completion markers — from GSD) and a behavioral specification (iron laws, gate functions — from Superpowers).

7. **The methodology is opinionated about quality, flexible about process.** Verification discipline, planning-before-implementation, and root-cause-first debugging are non-negotiable. Execution mode, state tier, parallelism strategy, and model selection are configurable. Iron laws are absolute; workflows are flexible.

### Five M002 Deliverables

1. **Skill library** — Iron laws, gate functions, and rationalization prevention tables adapted from Superpowers, extended with GSD's domain coverage. Validated through TDD-for-skills. Zero runtime dependencies.

2. **Infrastructure extension** — Claude Code extension providing hooks (context monitoring, behavioral reinforcement), CLI tools (state management, stub detection), and the execution harness (agent spawning, wave coordination). Node.js runtime.

3. **Agent definition format** — Declarative YAML/Markdown combining capability contracts (role, tools, model tier, completion markers) with behavioral specifications (iron laws, gate functions). Usable in both interactive and orchestrated modes.

4. **Tiered state system** — Tier 0 (stateless), Tier 1 (project brief + knowledge register + decision log), Tier 2 (full phase tracking with lockfile-based concurrency). Automatic tier detection and escalation.

5. **Verification pipeline** — Dual-layer verification combining behavioral gates with programmatic checks. Independent verifier agent for orchestrated mode; self-verification with behavioral enforcement for interactive mode.

---

## Source Documents

The M001 research corpus consists of six documents produced during the Research & Analysis milestone. Each is self-contained and can be read independently, but this synthesis provides the recommended entry point and navigational context.

| # | Document | Description | Words |
|---|----------|-------------|-------|
| 1 | `research/gsd-analysis.md` | Deep analysis of GSD v1.32 — architecture, agents, workflows, CLI tools, hooks, references, templates, SDK, multi-runtime support, quality assurance, security, context engineering, and state management across 14 sections | ~6,300 |
| 2 | `research/superpowers-analysis.md` | Deep analysis of Superpowers v5.0.7 — design philosophy, skill system architecture, five behavioral shaping mechanisms (iron laws, rationalization prevention tables, red-flag matrices, hard gates, graphviz flows), pipeline architecture, subagent patterns, quality methodology, and distribution system across 8 sections | ~4,900 |
| 3 | `research/academic-literature-review.md` | Synthesis of 7 academic papers (SASE, Codified Context Infrastructure, OpenDev, Confucius Code Agent, Codified Expert Knowledge, OpenDev Extended, LLMs Reshaping SE) organized around 7 cross-cutting design themes with 20 design implications | ~5,300 |
| 4 | `research/open-source-landscape.md` | Analysis of 6 open-source frameworks (CrewAI, LangGraph, AutoGen, OpenHands, Google ADK, Codified Context Infrastructure) for adoptable patterns, with 10 design implications and a ranked relevance assessment | ~5,400 |
| 5 | `research/comparative-analysis.md` | Nine-dimension comparison (architecture, execution, planning, verification, state, context, security, agents, knowledge) with academic and open-source cross-validation, producing three meta-patterns that define the design space | ~6,700 |
| 6 | `research/synergy-map.md` | Actionable design input for M002 — 12 synergy opportunities, 4 conflict points with resolution strategies, 7 design principles, and 5 concrete M002 deliverables. The most decision-relevant document in the corpus | ~7,200 |

**Reading order recommendation:** This synthesis first (for orientation), then `research/synergy-map.md` (for M002 design decisions), then individual analyses as needed for drill-down on specific mechanisms.

**Total corpus:** Approximately 36,000 words across 6 documents plus this synthesis, covering 2 production systems, 7 academic papers, 6 open-source frameworks, 9 comparison dimensions, 12 synergies, 4 conflicts, 7 design principles, and 5 M002 deliverables.
