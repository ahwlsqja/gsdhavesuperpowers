# Academic Literature Review: Design Implications for a Unified AI Agent Methodology

**Date:** 2026-04-05
**Scope:** 7 academic papers mapped to design-relevant themes for the GSD–Superpowers unified methodology
**Purpose:** Establish the theoretical foundation for M002 design decisions by synthesizing academic findings into actionable design implications

---

## Introduction

This review synthesizes seven recent academic papers on AI-assisted software engineering, organized around cross-cutting design themes rather than individual paper summaries. Each theme represents a convergence point where multiple independent research efforts arrive at similar conclusions — conclusions that directly inform the design of a unified methodology merging GSD's programmatic infrastructure with Superpowers' behavioral shaping.

The papers span three categories: formal frameworks proposing how AI agents should participate in software engineering (SASE, LLMs Reshaping SE), empirical systems built and validated through real development work (Codified Context Infrastructure, OpenDev, Confucius Code Agent, Codified Expert Knowledge), and hybrid studies combining theoretical frameworks with practitioner evidence. Together they cover 283+ development sessions, 108,000+ lines of generated code, interviews with 16 professional developers, and benchmark evaluations across SWE-Bench and similar suites.

**Papers reviewed:**

1. SASE — Structured Agentic Software Engineering (Hassan et al., 2025, arXiv:2509.06216)
2. Codified Context Infrastructure (Vasilopoulos, 2026, arXiv:2602.20478)
3. OpenDev — Terminal-Native Agent Scaffolding & Harness (Bui, 2026, arXiv:2603.05344)
4. Confucius Code Agent — Scalable Agent Scaffolding (Wong et al., Meta/Harvard, 2025, arXiv:2512.10398)
5. Codified Human Expert Domain Knowledge (Ulan uulu et al., 2026, arXiv:2601.15153)
6. OpenDev Context Engineering Lessons — Extended (Bui, 2026, arXiv:2603.05344, extended sections)
7. LLMs' Reshaping of SE — Empirical Study (Tabarsi et al., 2025, arXiv:2503.05012)

---

## Theme 1: Scaffolding Over Model Capability

### Overview

Multiple independent research groups converge on a finding that challenges the dominant narrative in AI development: the quality of the scaffolding surrounding an AI agent matters more than the capability of the underlying model. This has direct implications for methodology design — investing in elaborate system prompts, workflow definitions, templates, and behavioral directives yields higher returns than simply upgrading to a more capable model.

### SASE — The Agent Onboarding Argument

**Core Finding:** Hassan et al. propose that "an AI teammate that can be quickly onboarded into the context of a specific team, project, or organization is more valuable than a brilliant but brittle specialist agent that falters." The paper frames SE 3.0 as a paradigm where scaffolding — defined as the Agent Command Environment (ACE) and Agent Execution Environment (AEE) — determines agent effectiveness more than raw model intelligence.

**Mechanism:** SASE decomposes the agent's operating environment into two workbenches. The ACE provides the command interface, context assembly, and task routing. The AEE provides the execution sandbox, tool access, and verification infrastructure. An agent's performance ceiling is set by the quality of these workbenches, not the model inside them.

**Design Implication:** The unified methodology should treat scaffolding as the primary engineering investment. GSD already exemplifies this with its 21-agent registry, 60 workflows, and elaborate template system. But the SASE framing suggests going further — the methodology should define explicit "onboarding" protocols that rapidly contextualize any model into a specific project, treating model selection as a secondary concern behind scaffolding quality.

**Alignment with GSD/Superpowers:** Strongly aligned with both. GSD's five-layer architecture (Commands → Workflows → Agents → CLI Tools → File System) is a concrete implementation of the ACE/AEE concept. Superpowers' iron laws and rationalization prevention tables are a different form of scaffolding — behavioral scaffolding that constrains model output through prose rather than code. The unified methodology should recognize both forms.

### Confucius Code Agent — Empirical Proof

**Core Finding:** Wong et al. provide the strongest empirical evidence for the scaffolding thesis. Confucius Code Agent with Claude 4 Sonnet outperformed simpler scaffolds with the more capable Claude 4.5 Sonnet. Moving from simple to advanced context handling raised SWE-Bench-Pro scores by 6.6 percentage points — a margin attributable entirely to scaffolding quality, not model improvement.

**Mechanism:** Confucius achieves this through three-perspective design — Agent Experience (AX), User Experience (UX), and Developer Experience (DX) — combined with hierarchical working memory, persistent note-taking for cross-session learning, and a meta-agent that automates configuration refinement. The "scaffolding" is both the static configuration and the dynamic adaptation mechanisms.

**Design Implication:** The unified methodology must include mechanisms for scaffolding self-improvement — not just static templates and workflows, but adaptive systems that learn from execution. GSD's KNOWLEDGE.md is a primitive version of this (append-only lessons learned). Confucius's meta-agent that refines agent configuration after each session suggests a more active approach: periodic review of execution patterns to identify where scaffolding could be strengthened.

**Alignment with GSD/Superpowers:** GSD's model profiles (quality/balanced/budget/inherit) already acknowledge that scaffolding compensates for model capability — the "budget" profile runs everything on cheaper models, relying on scaffolding to maintain quality. Superpowers' TDD-for-skills methodology provides a quality assurance mechanism for behavioral scaffolding. The tension: GSD's scaffolding is programmatic (enforced by code), while Superpowers' is psychological (enforced by prose). Both are needed.

### OpenDev — The Scaffolding/Harness Distinction

**Core Finding:** Bui draws a critical distinction between scaffolding (constructing the agent before the first prompt — system prompt, tools, subagent registry) and harness (runtime orchestration — tool dispatch, context compaction, safety enforcement, session persistence). Both are forms of scaffolding in the broad sense, but they operate at different phases of the agent lifecycle.

**Mechanism:** OpenDev implements scaffolding through a single parameterized agent (over class hierarchy), eager prompt building (over lazy), and SubAgentSpec registration (over inline definitions). The harness provides workload-specialized model routing, dual-agent architecture separating planning from execution, lazy tool discovery, adaptive context compaction, and event-driven system reminders.

**Design Implication:** The unified methodology should explicitly separate pre-prompt scaffolding (what the agent knows when it starts) from runtime harness (how the agent is managed during execution). GSD conflates these somewhat — its system prompt contains both static knowledge and runtime behavior instructions. The separation would allow different engineering teams to optimize each layer independently and would make the methodology more modular.

**Alignment with GSD/Superpowers:** GSD is primarily scaffolding-heavy (elaborate system prompt, workflow definitions, template system) with moderate harness (hooks, state management, context monitor). Superpowers is scaffolding-light (SKILL.md loading at session start) with minimal harness (relies on Claude Code's built-in runtime). OpenDev's explicit separation suggests the unified methodology needs strong implementations of both.

---

## Theme 2: Context Engineering as Primary Lever

### Overview

Every system studied treats context — what the agent sees and when — as the primary engineering challenge. Raw model capability is bounded by the context window, and the quality of what fills that window determines output quality more than any other factor. Three papers address this from complementary angles: infrastructure design, runtime management, and the scaffolding that assembles context before execution.

### Codified Context Infrastructure — The Three-Tier Model

**Core Finding:** Vasilopoulos built and validated a three-tier context architecture across 283 development sessions producing a 108,000-line C# system. The tiers — hot-memory constitution (always loaded), specialized domain-expert agents (invoked per task), and cold-memory knowledge base (queried on demand via MCP) — were "created when agents made mistakes, not as a planning exercise."

**Mechanism:** The hot tier is a constitution document loaded into every agent session. The warm tier consists of 19 specialized agents, each containing domain-specific knowledge where "over half of each agent specification is domain knowledge, not behavioral instructions." The cold tier is a knowledge base of 34 documents accessible via MCP retrieval. Context documents were iteratively grown — each mistake triggered a new document or document revision.

**Design Implication:** The unified methodology should adopt the three-tier model explicitly. GSD approximates it: system prompt (hot), subagent definitions (warm), reference docs (cold). Superpowers' SKILL.md files are a mix of hot and warm — loaded on demand but comprehensive when loaded. The key insight is that context infrastructure must be grown iteratively from failure, not designed upfront. This validates GSD's KNOWLEDGE.md pattern and suggests extending it with structured categorization.

**Alignment with GSD/Superpowers:** The finding that "over half of each agent specification is domain knowledge, not behavioral instructions" creates tension with Superpowers' approach. Superpowers skills are almost entirely behavioral instructions — iron laws, rationalization prevention, gate functions. They contain minimal domain knowledge. The unified methodology should combine both: domain knowledge infrastructure (from the Codified Context model) with behavioral conditioning (from Superpowers).

**Warning:** Vasilopoulos documents that stale context caused agents to generate code conflicting with recent refactors. Context drift is a real maintenance cost. The unified methodology needs drift detection mechanisms — a pattern worth borrowing from the companion repository's validation scripts.

### OpenDev Extended — Runtime Context Management

**Core Finding:** The extended sections of OpenDev detail progressive context compaction — a runtime mechanism where older tool observations get summarized first, then removed entirely as the context window fills. This is more sophisticated than static context allocation because it adapts to the actual conversation length.

**Mechanism:** OpenDev implements adaptive compaction that progressively reduces older observations while preserving recent ones at full fidelity. The dual-agent architecture (planner + executor) also serves context engineering by giving each agent a focused context window rather than sharing a single overloaded one.

**Design Implication:** The unified methodology should implement both artifact-based context management (well-designed summaries that compress prior work, as GSD does) and runtime context management (progressive compaction that adapts to conversation length, as OpenDev does). GSD currently relies primarily on artifact design — summaries, frontmatter, and checkpoint files. Adding runtime compaction would allow agents to work on longer tasks without quality degradation.

**Alignment with GSD/Superpowers:** GSD's context-budget degradation model (PEAK/GOOD/DEGRADING/POOR) is a static policy that changes agent behavior at thresholds. OpenDev's approach is more dynamic — the content itself is managed rather than just the behavior. The Confucius SDK's hierarchical summarization provides a middle ground: structured compression that preserves important context while reducing token count. Superpowers has no context management at all — it relies entirely on the host platform's built-in mechanisms.

### Confucius SDK — Hierarchical Working Memory

**Core Finding:** Confucius implements hierarchical working memory that structures how information flows between agent sessions. Every session is logged as a structured trajectory and distilled into hierarchical Markdown notes, including "hindsight notes" that capture what the agent would have done differently.

**Mechanism:** The hierarchical memory system distinguishes between session-level working memory (what the agent is currently doing), project-level persistent notes (what the agent has learned across sessions), and hindsight annotations (what went wrong and how to avoid it). This creates a learning loop that improves future sessions without requiring manual knowledge engineering.

**Design Implication:** The unified methodology should adopt hindsight annotations as a complement to GSD's KNOWLEDGE.md. Currently, KNOWLEDGE.md captures what was learned but not the failure context that motivated the learning. Adding structured "what went wrong → what we learned → how to avoid it" entries would make the knowledge base more actionable for future agents.

---

## Theme 3: Memory Architecture (Three-Tier Convergence)

### Overview

Two independent research efforts — Codified Context Infrastructure and Confucius Code Agent — arrived at remarkably similar three-tier memory architectures. Combined with OpenDev's session persistence mechanisms, a clear pattern emerges for how AI agent systems should structure persistent knowledge.

### Codified Context Infrastructure — Constitution, Agents, Knowledge Base

**Core Finding:** The three-tier model (hot/warm/cold) emerged organically from 283 development sessions. Documents were created reactively — when agents made mistakes — rather than proactively. The cold tier (34 knowledge base documents) served as on-demand reference accessible through MCP, while the hot tier (constitution) provided the invariant behavioral foundation.

**Mechanism:** The MCP retrieval server enables cold-tier queries without loading entire documents into context. This is significant because it means the knowledge base can grow without proportionally increasing context consumption. The drift detection scripts check whether context documents still match the codebase reality — addressing the stale-context problem that causes agents to generate conflicting code.

**Design Implication:** The unified methodology should implement all three tiers with clear boundaries: Tier 1 (always-loaded behavioral foundation — GSD's system prompt + Superpowers' iron laws), Tier 2 (task-specific specialist knowledge — GSD's agent definitions + Superpowers' skill files), Tier 3 (on-demand reference — GSD's reference documents + project-specific knowledge base). The key architectural decision is how to gate access between tiers — MCP retrieval for cold storage, skill invocation for warm, and prompt injection for hot.

### Confucius SDK — Persistent Note-Taking

**Core Finding:** Every session produces structured trajectory data that gets distilled into hierarchical notes. Hindsight notes capture what the agent would have done differently — a form of counterfactual reasoning that standard logging misses. The meta-agent periodically reviews these notes and adjusts agent configuration.

**Mechanism:** Session trajectories include every tool call, every decision point, and every outcome. The distillation process extracts patterns: which approaches worked, which failed, which required human intervention. Hindsight notes add a reflective layer: "if I had known X, I would have done Y instead of Z."

**Design Implication:** The unified methodology should extend GSD's task summaries with structured hindsight fields. Currently, summaries capture what happened and what deviated from the plan. Adding "what would have been done differently and why" creates a feedback signal for improving future plans and scaffolding. This is more sophisticated than GSD's current KNOWLEDGE.md (which captures lessons) because it preserves the causal chain from failure to learning.

### OpenDev — Session Persistence and Instruction Fade-Out

**Core Finding:** OpenDev identifies "instruction fade-out" — the phenomenon where agents gradually forget system prompt guidelines over long conversations. The solution is event-driven system reminders that reinject critical instructions at strategic points during execution.

**Mechanism:** Rather than relying on the agent to remember all instructions throughout a session, OpenDev periodically reinjects key behavioral directives triggered by events (tool use patterns, conversation length, topic transitions). This maintains behavioral compliance without consuming the full context budget of the original system prompt.

**Design Implication:** The unified methodology should implement instruction reinforcement. Superpowers addresses fade-out through aggressive behavioral conditioning in SKILL.md files (iron laws, red-flag matrices), but this is a static solution — it works at session start but may fade over long sessions. OpenDev's event-driven approach could be combined with GSD's hook system to reinject critical behavioral directives at runtime. GSD's context monitor hook already injects context-budget warnings — the same mechanism could reinforce iron laws and verification requirements.

---

## Theme 4: Verification as Structural Requirement

### Overview

From Superpowers' iron law ("no completion claims without fresh verification evidence") to SASE's "speed vs. trust gap" to empirical findings that developers frequently discard generated code — the literature converges on a single conclusion: verification must be structural, not optional. It must be built into the methodology's architecture, not left to individual agent discipline.

### SASE — The Speed vs. Trust Gap

**Core Finding:** Hassan et al. identify a fundamental tension in AI-assisted development: AI agents increase development speed but decrease trust in the output. The gap between what is produced and what is trustworthy widens as agent autonomy increases. The paper proposes autonomy levels (analogous to SAE driving levels for autonomous vehicles) as a framework for managing this gap.

**Mechanism:** SASE defines five autonomy levels from fully manual to fully autonomous, with verification requirements that scale inversely to autonomy level. Higher autonomy requires more verification infrastructure, not less — because the human is less involved in production, they need more confidence in the output.

**Design Implication:** The unified methodology should implement graduated verification that scales with autonomy level. GSD's auto-mode currently applies uniform verification regardless of task complexity or autonomy level. SASE suggests that fully autonomous tasks (agent decides approach, implements, and verifies) need heavier verification than human-guided tasks (human provides approach, agent implements). The verification budget should be proportional to the trust gap.

**Alignment with GSD/Superpowers:** GSD addresses the trust gap through its four-level verification model (Exists → Substantive → Wired → Functional) and multi-layer quality gates (plan checker, executor self-check, post-execution verifier, UAT). Superpowers addresses it through behavioral enforcement — the iron law makes verification a non-negotiable agent behavior. Both are necessary: structural verification catches what behavioral discipline misses, and behavioral discipline ensures agents actually engage with verification rather than gaming it.

### LLMs Reshaping SE — The Productivity-Quality Paradox

**Core Finding:** Tabarsi et al. interviewed 16 professional developers and discovered a "productivity-quality paradox" — developers often discarded generated code and shifted effort from writing code to critically evaluating and integrating it. LLM use was phase-dependent: strong in implementation and debugging, weak in requirements gathering and architectural design.

**Mechanism:** Developers developed new competencies including "prompt engineering strategies, layered verification, and secure integration." They learned to treat AI output as a draft requiring evaluation rather than a finished product. The phase dependency finding shows that different development phases have different AI suitability levels.

**Design Implication:** The unified methodology should acknowledge that AI-generated code has a high discard rate and optimize the evaluate-discard-regenerate cycle. This means: (a) making verification fast and cheap so discarding is not costly, (b) preserving context between regeneration attempts so the agent learns from the discard, and (c) structuring the workflow so that evaluation happens automatically rather than requiring human effort. GSD's plan checker loop (max 3 iterations of plan → check → revise) is one implementation of this. The unified methodology should extend this pattern to code generation as well — generate → verify → discard/accept → regenerate if needed.

**Alignment with GSD/Superpowers:** The phase dependency finding directly validates GSD's phase-based workflow design (discuss → plan → execute → verify). Different phases need different levels of AI autonomy and different verification approaches. Superpowers' pipeline (brainstorm → write-plans → execute → review → finish) independently arrives at the same structure. The empirical finding that developers learned "layered verification" mirrors Superpowers' verification-before-completion gate function — the methodology should codify these competencies so they don't need to be re-learned by each developer or agent.

---

## Theme 5: Agent Experience vs User Experience

### Overview

The Confucius SDK introduces a distinction that has subtle but far-reaching implications for methodology design: what the agent sees (Agent Experience, AX) must be different from what the human sees (User Experience, UX). Verbose logs help humans debug but distract models. Structured data helps models parse but overwhelms human readers. The SASE framework extends this by considering the developer experience (DX) of building and configuring agents.

### Confucius SDK — The AX/UX/DX Separation

**Core Finding:** Wong et al. discovered that optimizing for human readability often degrades agent performance. Log output that helps a human developer understand what happened can distract an AI agent by filling its context with irrelevant detail. Conversely, structured data formats that are ideal for agent parsing can be impenetrable to human readers.

**Mechanism:** Confucius addresses this by maintaining separate representation layers: agent-facing tool outputs are structured and concise, human-facing dashboard views are verbose and visual, and developer-facing configuration interfaces use YAML/JSON with clear schemas. The meta-agent operates on agent-facing representations while producing human-facing reports.

**Design Implication:** The unified methodology should explicitly separate AX and UX concerns in its artifact system. GSD's artifacts currently serve dual purposes — PLAN.md is both human-readable documentation and agent-parseable task specification. STATE.md is both a human status dashboard and an agent state machine input. This dual-purpose design creates tension: making artifacts more parseable for agents (e.g., strict YAML frontmatter) makes them less pleasant for human reading, and vice versa.

**Alignment with GSD/Superpowers:** Superpowers optimizes heavily for AX — SKILL.md files are purely agent-facing behavioral specifications. The iron laws, rationalization prevention tables, and gate functions are designed to shape agent behavior, not to be read by humans (though they are readable). GSD takes the opposite approach, optimizing for human readability and relying on parsing code (gsd-tools.cjs) to extract structured data from human-friendly Markdown. The unified methodology should adopt Superpowers' AX-first approach for behavioral directives while maintaining GSD's human-readable approach for project documentation — different artifacts for different audiences.

### SASE — Developer Experience as Third Dimension

**Core Finding:** SASE extends the concern beyond AX and UX to include DX — the developer experience of building, configuring, and maintaining agent systems. The ACE/AEE workbench model recognizes that the people building agent infrastructure have different needs from both the agents using it and the end users benefiting from it.

**Mechanism:** SASE proposes that agent systems need clear interfaces between the DX layer (how agents are configured and deployed), the AX layer (what agents see and do), and the UX layer (how humans interact with agent output). These interfaces should be stable even as internal implementations change.

**Design Implication:** The unified methodology needs a clear extension/plugin model so that DX concerns (adding new agents, modifying workflows, creating skills) don't interfere with AX concerns (agent runtime behavior) or UX concerns (human interaction patterns). GSD's multi-runtime support (10 platforms) already addresses DX partially through its transformation layer. The unified methodology should formalize this into a stable DX API.

---

## Theme 6: Codified Knowledge Amplification

### Overview

Two papers directly address the practice of capturing and embedding human knowledge into AI agent systems — validating the core premise of both GSD and Superpowers that codified expert knowledge dramatically improves agent output.

### Codified Expert Knowledge — The 206% Improvement

**Core Finding:** Ulan uulu et al. demonstrate a 206% improvement in output quality when AI agents operate with properly codified domain knowledge. Non-experts achieved expert-level outcomes when the agent had access to structured expert rules, domain-specific classifiers, and visualization design principles.

**Mechanism:** The framework uses a request classifier to route tasks to appropriate knowledge sources, RAG-based code generation that draws on codified rules, explicit expert rules that constrain generation, and visualization design principles that guide output formatting. The distinction between "tacit" and "explicit" knowledge is central — tacit knowledge (how to approach problems) requires different codification strategies than explicit knowledge (specific patterns and rules).

**Design Implication:** The unified methodology should maintain separate codification strategies for tacit and explicit knowledge. Superpowers' behavioral conditioning (iron laws, rationalization prevention, gate functions) codifies tacit expert knowledge — the habits and instincts of skilled developers. GSD's reference documents (verification-patterns.md, universal-anti-patterns.md) codify explicit expert knowledge — specific patterns, rules, and checklists. Both forms are necessary and require different maintenance strategies. Tacit knowledge needs adversarial testing (Superpowers' TDD-for-skills). Explicit knowledge needs drift detection (Codified Context Infrastructure's validation scripts).

**Alignment with GSD/Superpowers:** The 206% improvement validates the core investment both systems make in knowledge codification. GSD invests in 25 reference documents, 42 templates, and a KNOWLEDGE.md append-only register. Superpowers invests in 14 skill files with iron laws, rationalization prevention tables, and gate functions. The empirical finding suggests both approaches work — and work well — because they address different types of knowledge.

### Codified Context Infrastructure — Documents as Load-Bearing Infrastructure

**Core Finding:** Vasilopoulos's most striking insight is that context documents become "load-bearing infrastructure" — the agents depend on them for correct behavior the same way a building depends on its structural members. When a context document goes stale, agents produce incorrect output. When a context document is accurate, agents produce correct output reliably.

**Mechanism:** This reframes documentation from a nice-to-have artifact to a critical infrastructure component. The companion repository includes drift detection scripts that check whether context documents still match the codebase reality, and factory scripts that bootstrap new context documents from templates.

**Design Implication:** The unified methodology should treat its knowledge artifacts (KNOWLEDGE.md, reference documents, skill files) as infrastructure with SLOs — they need versioning, drift detection, and maintenance schedules. Currently, GSD's reference documents are maintained by hand and can go stale without detection. Adding automated drift detection (checking whether patterns described in references still match the codebase) would increase reliability.

---

## Theme 7: Human-AI Collaboration Patterns

### Overview

Two papers examine the human side of AI-assisted development — how developers actually work with AI agents and what collaboration patterns emerge. These findings directly inform how the unified methodology should structure human-agent interaction.

### SASE — Autonomy Levels

**Core Finding:** Hassan et al. propose five autonomy levels that define how much human involvement is appropriate for different task types. The key insight is that autonomy is task-dependent, not system-wide — the same agent should operate at different autonomy levels for different tasks within the same session.

**Mechanism:** The autonomy spectrum ranges from Level 0 (human does everything, AI suggests) through Level 2 (AI does implementation, human reviews) to Level 4 (AI handles everything including deployment, human monitors). Each level has corresponding verification requirements and intervention triggers.

**Design Implication:** The unified methodology should implement per-task autonomy configuration rather than per-session. GSD currently defines task types (auto, checkpoint:human-verify, checkpoint:decision, checkpoint:human-action) in PLAN.md frontmatter — this is already a form of per-task autonomy. The SASE framework suggests formalizing this into explicit autonomy levels with corresponding verification budgets. Higher autonomy tasks get heavier automated verification. Lower autonomy tasks can rely more on human review.

**Alignment with GSD/Superpowers:** GSD's checkpoint system (90% human-verify, 9% decision, 1% human-action) is a practical implementation of graduated autonomy. Superpowers' hard gates (brainstorming must complete before implementation, verification must pass before completion) enforce minimum autonomy constraints — certain transitions always require explicit confirmation regardless of autonomy level.

### LLMs Reshaping SE — Emergent Competencies

**Core Finding:** Tabarsi et al. observe that developers working with AI agents develop new competencies: prompt engineering strategies, layered verification habits, and secure integration practices. These competencies are currently learned ad hoc by each developer through trial and error.

**Mechanism:** The empirical study reveals that effective AI collaboration is a skill that must be learned. Developers who succeed with AI agents don't just write better prompts — they develop mental models of when to trust AI output, how to structure requests for better results, and how to verify output efficiently. These are exactly the competencies that a methodology should codify.

**Design Implication:** The unified methodology should explicitly codify these emergent competencies into its skill and training materials. Superpowers already does this to some extent — the brainstorming skill teaches structured requirement exploration, the verification skill teaches layered verification. GSD's reference documents (questioning.md, checkpoints.md) codify interaction patterns. The unified methodology should frame itself not just as a tool for managing agents but as a training system for developing human-AI collaboration competencies.

**Alignment with GSD/Superpowers:** Both systems implicitly train these competencies through use. A developer who works with GSD's phase-based workflow learns to break work into verifiable increments. A developer who works with Superpowers' brainstorming skill learns to explore requirements before implementing. The unified methodology should make this training function explicit rather than incidental.

---

## Design Implications Summary

The following table maps each paper to its primary design implications for the unified methodology (M002). Each row identifies the paper, its core contribution to the unified methodology, the specific design area affected, and the implementation priority.

| Paper | Core Contribution | Primary Design Implication | Design Area | Priority |
|-------|-------------------|----------------------------|-------------|----------|
| SASE (Hassan et al.) | SE 3.0 framework; autonomy levels; speed-vs-trust gap | Implement graduated verification that scales with per-task autonomy level; treat scaffolding as primary engineering investment over model capability | Verification architecture, autonomy model | High |
| Codified Context Infrastructure (Vasilopoulos) | Three-tier memory model; documents as load-bearing infrastructure; iterative context growth from failures | Adopt explicit three-tier context architecture (hot/warm/cold) with drift detection; grow context infrastructure from observed failures, not upfront design | Memory architecture, knowledge management | High |
| OpenDev (Bui) | Scaffolding/harness distinction; dual-agent planning/execution; instruction fade-out | Separate pre-prompt scaffolding from runtime harness; implement event-driven instruction reinforcement to combat fade-out | System architecture, runtime management | High |
| Confucius Code Agent (Wong et al.) | AX/UX/DX separation; scaffolding > model capability; meta-agent self-improvement; hindsight notes | Separate agent-facing and human-facing artifact representations; implement scaffolding self-improvement via structured hindsight annotations | Artifact design, learning loops | High |
| Codified Expert Knowledge (Ulan uulu et al.) | 206% quality improvement; tacit vs explicit knowledge distinction | Maintain separate codification strategies for tacit knowledge (behavioral conditioning) and explicit knowledge (patterns, rules); both need different testing approaches | Knowledge engineering | Medium |
| OpenDev Context Engineering (Bui, extended) | Progressive context compaction; dual-agent architecture for context isolation | Implement runtime context management alongside artifact-based context management; use progressive compaction for long sessions | Context engineering | Medium |
| LLMs Reshaping SE (Tabarsi et al.) | Productivity-quality paradox; phase-dependent AI suitability; emergent developer competencies | Optimize the evaluate-discard-regenerate cycle; acknowledge phase-dependent AI capability; codify emergent human-AI collaboration competencies into methodology | Workflow design, training | Medium |

### Cross-Paper Convergence Points

Five findings appear across multiple papers and should be treated as high-confidence design principles:

1. **Scaffolding > Model** (SASE, Confucius, OpenDev): Invest in elaborate context engineering, behavioral directives, and workflow orchestration. Model upgrades yield diminishing returns compared to scaffolding improvements.

2. **Three-Tier Memory is Universal** (Codified Context, Confucius, OpenDev): Always-loaded core instructions, task-specific specialist knowledge, and on-demand reference material. Every successful system independently converges on this architecture.

3. **Context is the Bottleneck** (all seven papers): Every system addresses context management differently, but all treat it as the primary engineering challenge. The unified methodology needs both well-designed artifacts (GSD's approach) and runtime context management (OpenDev's approach).

4. **Verification Must Be Structural** (SASE, LLMs Reshaping SE, Codified Context): Verification cannot rely on agent discipline alone. It must be architecturally enforced through gates, automated checks, and independent validation. Both GSD's programmatic verification and Superpowers' behavioral enforcement are necessary.

5. **AX ≠ UX** (Confucius, SASE): Agent-facing and human-facing representations should be explicitly separated. Dual-purpose artifacts create tension that degrades both experiences. The unified methodology should design separate output paths for agent consumption and human reading.

### Tensions and Open Questions

Several papers surface tensions that the unified methodology must resolve:

- **Domain knowledge vs behavioral instructions:** Codified Context finds that "over half of each agent specification is domain knowledge," while Superpowers skills are almost entirely behavioral instructions with minimal domain content. The unified methodology must decide how to balance these — or provide a framework for projects to calibrate the ratio based on their needs.

- **Static vs dynamic context management:** GSD manages context through artifact design (summaries, frontmatter). OpenDev manages it through runtime compaction. These are complementary but require different engineering investments. The unified methodology should specify when to use each approach.

- **Upfront design vs iterative growth:** Codified Context validates that context infrastructure should be "created when agents made mistakes, not as a planning exercise." But GSD's template and reference system is largely designed upfront. The unified methodology should provide a minimal upfront scaffold with clear extension points for iterative growth.

- **Autonomy granularity:** SASE proposes per-task autonomy levels. GSD implements per-task types. Superpowers enforces uniform behavioral constraints. The right granularity for the unified methodology depends on the balance between flexibility and cognitive overhead.

---

## Methodological Notes

**Recency and peer review:** Several papers (OpenDev, Codified Context Infrastructure) are from early 2026 and have not undergone full peer review. Their findings should be treated as preliminary, though the empirical evidence (283 development sessions, 108,000 lines of code) provides substantial validation.

**Benchmark limitations:** The Confucius SDK's SWE-Bench-Pro evaluation provides useful quantitative evidence, but our unified methodology targets interactive development, not automated issue resolution. Benchmark gains may not directly translate to interactive workflow improvements.

**Scope limitations:** Two papers from the initial research plan (the "AI Agentic Programming survey" and the "MSR'26 coding agent impact study") could not be located. The LLMs Reshaping SE paper (Tabarsi et al.) and the Codified Expert Knowledge paper (Ulan uulu et al.) provide comparable empirical and framework coverage. If the original papers are located, they should be incorporated during the comparative analysis phase (S03).

---

## References

1. Hassan, M. M. et al. (2025). "SASE: Structured Agentic Software Engineering." arXiv:2509.06216.
2. Vasilopoulos, A. (2026). "Codified Context Infrastructure for AI-Assisted Software Development." arXiv:2602.20478.
3. Bui, S. (2026). "OpenDev: Terminal-Native Agent Scaffolding and Harness." arXiv:2603.05344.
4. Wong, J. et al. (2025). "Confucius: Scalable Code Agent Scaffolding." Meta/Harvard. arXiv:2512.10398.
5. Ulan uulu, E. et al. (2026). "Codified Human Expert Domain Knowledge for AI Agents." arXiv:2601.15153.
6. Bui, S. (2026). "OpenDev Context Engineering Lessons." arXiv:2603.05344 (extended sections).
7. Tabarsi, A. et al. (2025). "LLMs' Reshaping of Software Engineering: An Empirical Study." arXiv:2503.05012.
