# Open-Source Landscape Analysis: Agent Framework Patterns for a Unified Methodology

**Date:** 2026-04-05
**Scope:** 6 open-source frameworks analyzed for architectural patterns relevant to the GSD–Superpowers unified methodology
**Purpose:** Extract adoptable patterns and anti-patterns from the open-source agent ecosystem to inform M002 design decisions

---

## Introduction

This analysis examines six open-source AI agent frameworks through a specific lens: which architectural patterns should the unified GSD–Superpowers methodology adopt, adapt, or avoid? The goal is not framework comparison or selection — none of these will be used directly. Instead, each framework represents a set of design decisions made under real engineering constraints, and those decisions contain lessons for our own methodology design.

**Selection criteria:** Frameworks were chosen to span two categories relevant to our work. The first category — general-purpose multi-agent orchestration (CrewAI, LangGraph, AutoGen, Google ADK) — provides composability, deployment, and state management patterns. The second category — coding-agent-specific scaffolds (OpenHands, Codified Context Infrastructure) — provides verification, context management, and session persistence patterns closer to our target domain.

**What we're looking for:** Mechanisms that address five challenges the academic literature identifies as fundamental to AI agent effectiveness (see *Academic Literature Review*): (1) context engineering — how frameworks manage what agents see and when, (2) memory and state persistence — how they maintain knowledge across sessions, (3) agent composability — how they combine specialized agents into effective workflows, (4) human-in-the-loop integration — how they balance autonomy with human oversight, and (5) verification architecture — how they ensure output quality.

---

## Framework 1: CrewAI

**Repository:** github.com/crewAIInc/crewAI (30k+ stars)

### Architecture Overview

CrewAI is a Python framework for multi-agent automation offering two execution modes: **Crews** (autonomous collaborative agents organized around roles) and **Flows** (event-driven orchestration pipelines). The framework is independent of LangChain and uses a role-based agent design where agents receive natural language definitions of their role, goal, and backstory.

The dual-mode architecture is noteworthy. Crews operate as collaborative teams where agents delegate tasks to each other based on role fit. Flows provide explicit control over execution order through event-driven wiring. This mirrors a tension in our own design space: GSD's workflow engine is predominantly Flows-style (explicit orchestration), while Superpowers' skill invocation is closer to Crews-style (agents self-select based on task fit).

### Key Differentiator

Role-playing as an organizational metaphor. Agents have roles ("Senior Researcher"), goals ("Find the most relevant information"), and backstories ("You are a 20-year veteran researcher"). The "Crew" metaphor organizes these agents into collaborative teams with defined delegation protocols.

### Patterns Worth Adopting

**Structured task delegation with role affinity.** CrewAI's delegation model — where agents assess task requirements against role capabilities before delegating — maps to a pattern GSD partially implements through its agent registry (21 specialized agents). The explicit role/goal/backstory structure provides a template for formalizing agent specialization that is currently implicit in GSD's agent definitions. The academic finding that "scaffolding matters more than model capability" (Confucius SDK, Wong et al.) suggests that rich role definitions contribute to scaffolding quality even when the underlying model doesn't change.

**Built-in observability and tracing.** CrewAI includes native observability that traces agent decisions, delegation events, and task outcomes. GSD's hook system provides similar capabilities (context monitor, statusline) but as opt-in add-ons rather than built-in infrastructure. Making observability a first-class concern — not an afterthought — aligns with the academic emphasis on context engineering as the primary lever (Codified Context Infrastructure, Vasilopoulos).

### Patterns to Avoid

**Role-playing abstraction overhead.** The backstory/persona metaphor adds cognitive weight without clear benefit for coding tasks. Telling an agent it's "a 20-year veteran researcher" doesn't make its research better — providing it with domain-specific knowledge does. The Codified Context Infrastructure paper's finding that "over half of each agent specification is domain knowledge, not behavioral instructions" suggests role-playing abstractions are the wrong investment. Better to invest in concrete domain knowledge than narrative framing.

**Enterprise-scale abstraction for single-developer workflows.** CrewAI's orchestration infrastructure assumes teams of agents working on general automation tasks. The unified methodology targets individual developers with AI agents on coding workflows. The enterprise patterns (crew management, complex delegation hierarchies) add complexity without matching our use case.

### Relevance to Unified Methodology: Medium

CrewAI validates that role-based agent specialization and built-in observability are viable patterns. Its delegation model offers a template for formalizing how GSD's agent registry selects agents for tasks. But the role-playing abstraction and general automation focus make it a pattern source rather than a direct influence.

---

## Framework 2: LangGraph

**Repository:** github.com/langchain-ai/langgraph

### Architecture Overview

LangGraph is a low-level orchestration framework for building stateful, long-running agent workflows. Workflows are defined as directed graphs with nodes (computation steps) and edges (transitions, including conditional branches). The framework provides durable execution with automatic failure recovery — workflows persist through crashes, network failures, and process restarts via a checkpoint system.

The graph-based model represents the most explicit workflow formalization among the frameworks analyzed. Where GSD's workflows are Markdown files with natural language orchestration logic, LangGraph workflows are code-level graph definitions with typed state transitions. This trades readability for precision — a LangGraph workflow is unambiguous but requires programming knowledge to modify, while a GSD workflow is human-readable but depends on agent interpretation.

### Key Differentiator

First-class durable execution with comprehensive state management. LangGraph persists workflow state at every node boundary, enabling resume-from-checkpoint after any failure. Its memory system explicitly separates short-term working memory (within a workflow run) from long-term persistent memory (across sessions). This two-tier memory model maps to the three-tier architecture identified in the academic literature (Codified Context Infrastructure, Confucius SDK), though LangGraph's implementation is programmatic rather than document-based.

### Patterns Worth Adopting

**Graph-based workflow definition for phase transitions.** GSD's phase pipeline (discuss → plan → execute → verify) is conceptually a graph, but it's expressed as prose in workflow Markdown files. Formalizing phase transitions as a typed graph — with explicit state at each node and conditional edges based on verification outcomes — would make the pipeline more predictable and debuggable. LangGraph's approach of making the state at each node explicit and inspectable addresses the "speed vs. trust gap" (SASE, Hassan et al.) by making workflow progress transparent.

**Checkpoint/resume for long-running operations.** GSD already implements a version of this through its continuation-format protocol and HANDOFF.json for session persistence. LangGraph's approach is more granular — state is checkpointed at every node, not just at session boundaries. The OpenDev paper's finding that session persistence is essential for coding agents validates investing in finer-grained checkpointing.

**Human-in-the-loop interrupts at any graph node.** LangGraph allows inserting human review points at any node in the workflow graph. GSD's checkpoint system (90% human-verify, 9% decision, 1% human-action) provides similar functionality but is defined at plan time rather than dynamically. The ability to interrupt at any point — especially when verification fails — would make GSD's auto-mode more robust.

### Patterns to Avoid

**LangChain ecosystem dependency.** LangGraph is tightly coupled to the LangChain ecosystem, including LangSmith for observability and LangServe for deployment. This creates vendor lock-in that contradicts GSD's multi-runtime philosophy (10 supported platforms). The unified methodology should learn from LangGraph's patterns while avoiding ecosystem-specific dependencies.

**Graph-based abstraction for linear workflows.** Many coding tasks follow linear sequences that don't benefit from graph-based modeling. Adding graph abstractions to inherently sequential work (write test → implement → verify → commit) adds complexity without value. GSD's current PLAN.md approach — linear task lists with explicit dependencies — is simpler and sufficient for most coding workflows.

### Relevance to Unified Methodology: Medium

LangGraph's durable execution and checkpoint/resume patterns are directly applicable to improving GSD's session persistence. The graph-based workflow model offers a formalization path for GSD's phase transitions. But the LangChain ecosystem coupling and over-engineering risk for linear workflows limit its influence.

---

## Framework 3: AutoGen

**Repository:** github.com/microsoft/autogen

### Architecture Overview

AutoGen (now transitioning to "Microsoft Agent Framework") is a multi-agent conversation framework supporting both autonomous and human-in-the-loop interaction modes. The framework provides McpWorkbench for MCP server integration and AgentTool for agent-as-tool composition. The architecture centers on conversation as the coordination primitive — agents interact through structured message passing rather than task delegation.

The transition from "AutoGen" to "Microsoft Agent Framework" signals an industry shift from open-source framework to platform product, with implications for how the unified methodology should position itself.

### Key Differentiator

**Agent-as-tool composability.** AutoGen's AgentTool pattern wraps an entire agent as a tool callable by other agents, enabling recursive agent hierarchies. Agent A can invoke Agent B as a tool, which in turn invokes Agent C, creating composable multi-agent pipelines. This is distinct from CrewAI's delegation (agents choose who to delegate to) and LangGraph's graphs (explicit wiring at design time). AutoGen's approach is dynamic — any agent can invoke any other agent at runtime.

### Patterns Worth Adopting

**Agent-as-tool composition for subagent dispatch.** GSD's subagent system uses explicit spawning (the orchestrator constructs a prompt and spawns a named agent). AutoGen's agent-as-tool pattern offers a more composable alternative — agents are exposed as tools with input/output schemas, making them discoverable and invocable through the same mechanism as other tools. This would simplify GSD's agent dispatch and make it consistent with MCP tool invocation. The Confucius SDK's meta-agent pattern (an agent that configures other agents) benefits from exactly this kind of composability.

**MCP-first tool integration.** AutoGen's McpWorkbench provides native MCP server integration, treating MCP tools as first-class capabilities alongside built-in tools. GSD already supports MCP through its CLI tools, but the unified methodology could benefit from making MCP the primary tool integration pattern rather than a supplementary one. The Codified Context Infrastructure paper uses MCP for its cold-tier knowledge retrieval — further validating MCP as the standard tool integration protocol.

### Patterns to Avoid

**Framework in active transition.** AutoGen carries a deprecation notice directing users to "Microsoft Agent Framework." Building on a transitioning API creates maintenance burden and migration risk. The pattern is valuable; the specific implementation is not stable enough to depend on.

**Complex API surface with multiple agent types.** AutoGen provides AssistantAgent, UserProxyAgent, GroupChat, and more — a taxonomy of agent types that creates cognitive overhead. The academic finding that single parameterized agents outperform class hierarchies (OpenDev, Bui) suggests a flatter agent model is preferable.

### Relevance to Unified Methodology: Medium-Low

The agent-as-tool composability pattern is the primary takeaway. The MCP-first integration approach validates GSD's existing MCP support. But the framework's transition state and API complexity limit its direct applicability.

---

## Framework 4: OpenHands

**Repository:** github.com/All-Hands-AI/OpenHands (SDK + CLI + GUI + Cloud)

### Architecture Overview

OpenHands separates its architecture into four layers: a composable Python **SDK** (the engine), a **CLI** (terminal interface), a local **GUI** (web interface), and **Cloud** (hosted deployment). Multiple agent types are built on top of the SDK, supporting Claude, GPT, and other LLMs. The enterprise version includes integrations with Slack, Jira, and Linear.

This layered architecture is the closest analog to what the unified methodology should target. The SDK provides core capabilities (context management, tool dispatch, agent execution), while multiple interfaces expose those capabilities through different interaction patterns. GSD's current architecture partially mirrors this: the CLI tools layer (gsd-tools.cjs) serves as the SDK, and the command/workflow layer provides the interface. But GSD's SDK is more tightly coupled to its Markdown-based state model than OpenHands' SDK is to its interfaces.

### Key Differentiator

**SDK-first architecture with interface-agnostic core.** OpenHands builds every interface on top of the same SDK, ensuring behavioral consistency across CLI, GUI, and cloud usage. This validates the academic finding that the scaffolding/harness distinction matters (OpenDev, Bui) — the SDK is the harness, and the interfaces are different scaffolding configurations for the same engine.

### Patterns Worth Adopting

**Evaluation infrastructure as a first-class concern.** OpenHands maintains a separate benchmarks repository for systematic evaluation of agent performance. This is more rigorous than either GSD's verifier-based quality checks or Superpowers' TDD-for-skills approach, because it measures end-to-end system performance rather than individual component compliance. The unified methodology should include an evaluation framework that measures methodology effectiveness across standardized tasks — not just individual skill or workflow quality.

**Theory-of-Mind module for intent understanding.** OpenHands includes a module that models developer intent from sparse instructions. Rather than taking instructions literally, the module infers what the developer is trying to achieve and fills in unstated requirements. This addresses the "productivity-quality paradox" (Tabarsi et al.) by reducing the gap between what developers say and what they mean. GSD's discuss phase serves a similar purpose (extracting decisions through "dream extraction"), but OpenHands' approach operates at the instruction level rather than the project level.

**Interface-agnostic SDK with multiple frontends.** The unified methodology should define its core capabilities as an SDK/library that can be consumed through multiple interfaces — GSD's CLI workflow, Superpowers' skill loading, or a potential future GUI. GSD's SDK module (16,623 lines TypeScript) already provides this foundation, but it's currently focused on headless execution rather than serving as the universal core.

### Patterns to Avoid

**Heavy container-based sandboxing.** OpenHands uses containers for execution sandboxing, adding infrastructure complexity. For Claude Code-native usage, the host filesystem is the execution environment, and container overhead would slow iteration. The unified methodology should provide sandboxing through git worktrees (as Superpowers already does) rather than containers.

### Relevance to Unified Methodology: High

OpenHands is the closest architectural match to our target. The SDK-first pattern, evaluation infrastructure, and intent modeling are all directly adoptable. The main lesson: the unified methodology's core should be an SDK that multiple interfaces consume, not a monolithic system with one interface.

---

## Framework 5: Google Agent Development Kit (ADK)

**Repository:** github.com/google/adk-python (also Java, Go, Web)

### Architecture Overview

Google ADK is a code-first Python framework optimized for Gemini but model-agnostic. It supports modular multi-agent systems with hierarchical composition and provides the Agent2Agent (A2A) protocol for cross-framework agent communication. The framework spans Python, Java, Go, and Web implementations, making it the most polyglot entry in this analysis.

The multi-language support is significant because it validates building agent scaffolding as a cross-language concern rather than a Python-specific one. GSD's gsd-tools.cjs (Node.js) and SDK (TypeScript) already operate in a different language ecosystem than most agent frameworks. ADK shows this is viable at scale.

### Key Differentiator

**Agent Config — declarative agent definition without code.** ADK allows agents to be defined as configuration files (YAML/JSON) rather than Python classes. An agent's behavior, tools, memory settings, and composition rules can be specified declaratively and loaded at runtime. This eliminates the need for code changes when modifying agent behavior.

This pattern directly maps to GSD's agent definitions (agents/*.md with YAML frontmatter) and Superpowers' skill files (SKILL.md with metadata headers). All three systems independently arrive at declarative agent configuration — a strong convergence signal that the unified methodology should treat agent definitions as data, not code.

### Patterns Worth Adopting

**Declarative agent definitions as the configuration primitive.** ADK's Agent Config validates GSD's existing pattern of defining agents in Markdown with YAML frontmatter. The unified methodology should formalize this as the canonical agent definition format, ensuring that agent behavior can be modified by editing configuration rather than code. The Confucius SDK paper's finding that scaffolding quality matters more than model capability reinforces this: making scaffolding easy to modify accelerates improvement.

**Session rewind (undo to previous state).** ADK provides a "rewind" feature that returns a session to a previously checkpointed state, undoing all intermediate actions. This is more powerful than LangGraph's checkpoint/resume because it supports undo, not just resume. GSD's current state model doesn't support rewind — once a task is marked complete, it stays complete. Adding rewind capability would make auto-mode more robust to wrong turns.

**Tool confirmation flow (HITL guard on tool execution).** ADK implements a tool confirmation mechanism where certain tools require human approval before execution. The tool runs, produces a preview of what it would do, and waits for human confirmation before applying the change. This maps directly to Superpowers' verification-before-completion gate and GSD's checkpoint system, but at a finer granularity — per-tool rather than per-task. The SASE paper's graduated autonomy framework suggests that different tools need different confirmation levels based on their impact.

### Patterns to Avoid

**Google ecosystem assumptions.** ADK is optimized for Vertex AI deployment, Cloud Run hosting, and Google-specific observability. The unified methodology must remain platform-agnostic (GSD already supports 10 runtimes). Adopting ADK patterns without its ecosystem coupling requires explicit decoupling.

**A2A protocol overhead for single-framework systems.** The Agent2Agent protocol enables cross-framework agent communication, which adds protocol overhead for systems where all agents operate within the same framework. The unified methodology operates as a single integrated system, not a federation of frameworks, making A2A unnecessary for our use case.

### Relevance to Unified Methodology: Medium

ADK's declarative agent definitions and tool confirmation flow are directly applicable. Session rewind offers a capability GSD currently lacks. The multi-language validation is encouraging for GSD's Node.js/TypeScript approach. But the Google ecosystem focus and federation overhead limit direct adoption.

---

## Framework 6: Codified Context Infrastructure

**Repository:** github.com/arisvas4/codified-context-infrastructure

### Architecture Overview

The companion repository to Vasilopoulos's academic paper, this is a reference implementation of the three-tier context architecture validated across 283 development sessions. It includes quickstart factories (constitution-factory, agent-factory, context-factory), an MCP retrieval server for cold-tier knowledge access, case study artifacts from the 108,000-line C# system, and validation/drift detection scripts.

Unlike the other frameworks in this analysis, Codified Context Infrastructure is not an agent execution framework — it's a knowledge engineering framework. It provides the infrastructure for managing the context documents that agents depend on, rather than managing the agents themselves. This makes it uniquely complementary to GSD's agent orchestration and Superpowers' behavioral shaping.

### Key Differentiator

**Context engineering as the primary product.** This is the only framework specifically designed to make documentation into "load-bearing infrastructure" — context documents that agents depend on for correct behavior the same way a building depends on its structural members. Every other framework treats context as an input to agent execution. This framework treats context management as the main engineering problem.

The academic paper's finding that "documents were created when agents made mistakes, not as a planning exercise" reframes how context infrastructure should grow: reactively from observed failures, not proactively from anticipated needs. This directly validates GSD's KNOWLEDGE.md append-only pattern and suggests extending it with the factory and validation patterns this repository provides.

### Patterns Worth Adopting

**Factory pattern for bootstrapping agent configurations.** The constitution-factory, agent-factory, and context-factory provide templates and scaffolding for creating new context documents. This is more structured than GSD's template system (42 templates in get-shit-done/templates/) because it includes not just templates but validation rules and relationship declarations. The unified methodology should adopt factory patterns that generate context documents with built-in quality constraints.

**Drift detection scripts for stale context identification.** The repository includes scripts that detect when context documents no longer match the codebase they describe — a critical maintenance concern the paper documents as causing agents to generate conflicting code. GSD's reference documents (25 files in get-shit-done/references/) are manually maintained and have no automated staleness detection. Adding drift detection would prevent the failure mode where agents follow outdated guidance. This addresses the "documents as load-bearing infrastructure" concern: if context is infrastructure, it needs monitoring like infrastructure.

**Three-tier memory model with explicit access patterns.** The implementation makes the hot/warm/cold tiers concrete: hot-tier constitution documents are always loaded (analogous to GSD's system prompt), warm-tier agent specifications are loaded per-task (analogous to GSD's subagent definitions), and cold-tier knowledge base documents are queried on-demand via MCP (analogous to GSD's reference documents accessed through read operations). The explicit access pattern for each tier — injection, invocation, and retrieval — provides a template for the unified methodology's knowledge management architecture.

### Patterns to Avoid

**Single-project scope assumption.** The repository is designed for a single large project (the 108,000-line C# system). The unified methodology must work across projects of varying sizes and tech stacks. The factory patterns and drift detection scripts need to be generalized beyond the single-project case.

### Relevance to Unified Methodology: High

This is the most directly applicable framework for knowledge management design. The factory patterns, drift detection, and three-tier memory model address gaps in GSD's current knowledge infrastructure. The context-as-infrastructure philosophy aligns perfectly with both GSD's reference system and Superpowers' skill system — both treat their knowledge artifacts as critical infrastructure, and both would benefit from the engineering rigor this framework applies to context management.

---

## Cross-Framework Pattern Synthesis

Five cross-cutting patterns appear across multiple frameworks. These represent convergence points where independent engineering teams arrived at similar solutions — a strong signal that these patterns address fundamental challenges in AI agent system design.

### Agent Composability Patterns

Three distinct composability models emerged across the frameworks:

| Pattern | Framework(s) | Mechanism | Applicability |
|---------|-------------|-----------|---------------|
| **Role-based delegation** | CrewAI | Agents assess task fit against role definitions and delegate to best-fit agents | Medium — useful for formalizing GSD's agent registry, but role-playing overhead is unnecessary |
| **Graph-based wiring** | LangGraph | Agents are nodes in an explicit graph; edges define data flow and conditional transitions | Medium — useful for formalizing GSD's phase pipeline, but over-complex for linear task sequences |
| **Agent-as-tool** | AutoGen | Agents are wrapped as tools with input/output schemas, invocable by any other agent | High — simplifies subagent dispatch and makes agent invocation consistent with MCP tool invocation |
| **SDK composition** | OpenHands | Agents are built on a shared SDK; composition happens at the SDK layer, not the agent layer | High — validates the unified methodology should define core capabilities as an SDK |
| **Hierarchical nesting** | Google ADK | Parent agents contain child agents; delegation flows through the hierarchy | Medium — useful for complex workflows but adds hierarchy overhead |

The convergence point: **agents should be composable units with typed interfaces**. Whether composed through delegation (CrewAI), wiring (LangGraph), or tool invocation (AutoGen), the underlying pattern is the same — agents need clear input/output contracts to be combined effectively. GSD's agent contracts (defined in agent-contracts.md) partially address this, but the completion markers and handoff schemas could be formalized into typed interfaces that enable programmatic composition.

The Confucius SDK's meta-agent finding reinforces this: if an agent can configure and invoke other agents, the composition mechanism must be well-defined enough for an agent to use it, not just a human.

### Memory and State Management

Every framework addresses persistence, but through different architectural layers:

| Approach | Framework(s) | Tier 1 (Hot) | Tier 2 (Warm) | Tier 3 (Cold) |
|----------|-------------|------|------|------|
| **Document-based** | Codified Context Infrastructure | Constitution (always loaded) | Agent specs (per-task) | Knowledge base (MCP query) |
| **Checkpoint-based** | LangGraph | Working memory (in-session) | Checkpoint state (per-node) | Long-term memory store |
| **SDK-managed** | OpenHands | Agent context (per-session) | Session state (persisted) | External integrations |
| **Config-based** | Google ADK | Agent Config (loaded at init) | Session state (rewindable) | Tool state (external) |

The convergence point: **all successful systems implement at least two tiers of memory persistence**, separating always-available context from on-demand reference material. This validates the three-tier model identified in the academic literature (Codified Context, Confucius SDK). The unified methodology should explicitly define its memory tiers:

- **Tier 1 (Hot):** GSD system prompt + Superpowers iron laws + project constitution (always in context)
- **Tier 2 (Warm):** Agent/skill definitions + phase context + task plans (loaded per-task)
- **Tier 3 (Cold):** Reference documents + knowledge base + project history (queried on demand)

### Tool Integration Approaches

Two integration paradigms dominate:

| Paradigm | Framework(s) | Mechanism | Tradeoffs |
|----------|-------------|-----------|-----------|
| **MCP-native** | AutoGen, Google ADK, Codified Context | Tools exposed as MCP servers; agents discover and invoke through the MCP protocol | Standards-based, discoverable, but adds protocol overhead |
| **SDK-embedded** | OpenHands, LangGraph, CrewAI | Tools are SDK functions; agents invoke through the framework's internal API | Lower overhead, tighter integration, but framework-specific |

The convergence point: **MCP is emerging as the standard tool integration protocol**, with even SDK-embedded frameworks adding MCP support. The unified methodology should treat MCP as the primary tool integration pattern while maintaining direct SDK integration for performance-critical tools. GSD's existing MCP support (through gsd-tools.cjs) positions it well for this pattern. The Codified Context Infrastructure's use of MCP for cold-tier knowledge retrieval demonstrates MCP's applicability beyond external service integration — it can serve as the access pattern for the methodology's own knowledge base.

### Human-in-the-Loop Mechanisms

Frameworks implement HITL at different granularities:

| Granularity | Framework(s) | Mechanism | GSD/Superpowers Equivalent |
|-------------|-------------|-----------|---------------------------|
| **Per-tool** | Google ADK | Tool confirmation before execution | No direct equivalent — GSD checkpoints are per-task |
| **Per-node** | LangGraph | Interrupt at any graph node | Partial — GSD's checkpoint types allow per-task interrupts |
| **Per-task** | CrewAI, OpenHands | Human review after task completion | GSD's checkpoint:human-verify (90% of checkpoints) |
| **Per-session** | Codified Context | Constitution defines session-level autonomy | Superpowers' hard gates (brainstorming, verification) |

The convergence point: **effective HITL requires multiple granularity levels, not a single mechanism**. The SASE paper's autonomy levels framework suggests that different tasks need different HITL granularity — fully autonomous tasks need no interrupts, while high-impact tasks need per-tool confirmation. GSD's checkpoint system (90% human-verify, 9% decision, 1% human-action) implements graduated granularity, but only at the per-task level. The unified methodology should extend this to support per-tool confirmation for high-impact operations (database migrations, deployments, external API calls).

### Declarative vs Imperative Agent Definition

A clear split exists between frameworks that define agents in code vs configuration:

| Approach | Framework(s) | Agent definition format | Modification requires |
|----------|-------------|------------------------|----------------------|
| **Declarative** | Google ADK, Codified Context | YAML/JSON config files, Markdown documents | Editing configuration |
| **Imperative** | LangGraph, AutoGen | Python classes, code-level graph definitions | Code changes |
| **Hybrid** | CrewAI, OpenHands | Code-first with configuration overrides | Code for structure, config for tuning |

The convergence point: **declarative agent definition enables faster iteration and non-programmer modification**. Three independent systems (GSD's agent/*.md files, Superpowers' SKILL.md files, Google ADK's Agent Config) arrived at declarative agent definition using markup languages. The academic finding that scaffolding quality is the primary lever (Confucius SDK, OpenDev) means scaffolding must be easy to modify — declarative definitions lower the modification barrier. The unified methodology should standardize on declarative agent/skill definition as its primary configuration surface, using code only for the harness layer (runtime orchestration, tool dispatch).

---

## Design Implications for Unified Methodology

The following table maps extracted patterns to specific GSD/Superpowers mechanisms they could enhance. Each row identifies the pattern, its source frameworks, the mechanism in the current systems it would improve, and the expected benefit.

| Pattern | Source Frameworks | GSD/Superpowers Mechanism to Enhance | Expected Benefit |
|---------|------------------|--------------------------------------|------------------|
| Agent-as-tool composability | AutoGen, Google ADK | GSD's subagent dispatch + MCP tool invocation | Unified agent/tool invocation model; agents become discoverable like MCP tools |
| SDK-first architecture | OpenHands | GSD's SDK module (16K lines TypeScript) | Interface-agnostic core enabling CLI, skill, and future GUI consumption |
| Declarative agent config | Google ADK, Codified Context | GSD's agent/*.md + Superpowers' SKILL.md | Standardized agent/skill definition format across the unified methodology |
| Three-tier memory model | Codified Context, LangGraph | GSD's system prompt + agents + references | Explicit hot/warm/cold tiers with defined access patterns |
| Drift detection for context | Codified Context | GSD's reference documents (25 files) | Automated staleness detection preventing conflicting agent guidance |
| Factory patterns for bootstrapping | Codified Context | GSD's template system (42 templates) | Template-plus-validation for new context documents, not just templates |
| Checkpoint/resume with rewind | LangGraph, Google ADK | GSD's continuation-format + HANDOFF.json | Finer-grained checkpointing with undo capability for wrong turns |
| Per-tool HITL confirmation | Google ADK | GSD's checkpoint system | Graduated confirmation granularity matching tool impact |
| Evaluation infrastructure | OpenHands | GSD's verifier + Superpowers' TDD-for-skills | End-to-end methodology performance measurement |
| Built-in observability | CrewAI, LangGraph | GSD's hook system | First-class tracing for agent decisions, not just context usage |

---

## Frameworks Most Relevant to Our Work

Ranked by direct applicability to the unified methodology's design challenges:

### 1. Codified Context Infrastructure — Highest Relevance

**Rationale:** This is the only framework that treats context management as its primary engineering problem — exactly the problem the academic literature identifies as the primary lever for agent effectiveness. Its three-tier memory model, drift detection scripts, and factory patterns address the most critical gap in GSD's current architecture: knowledge management is extensive (25 references, 42 templates, KNOWLEDGE.md) but lacks engineering rigor (no staleness detection, no access-pattern formalization, no validation rules). The unified methodology should adopt this framework's engineering approach to context management while implementing it within GSD's Markdown-based state model.

### 2. OpenHands — High Relevance

**Rationale:** OpenHands' SDK-first architecture is the closest structural match to our target. The separation of engine (SDK) from interfaces (CLI, GUI, Cloud) validates the architectural direction the unified methodology should take — a core SDK consumed by multiple interfaces. The evaluation infrastructure provides a quality measurement capability that neither GSD nor Superpowers currently offers at the system level. The Theory-of-Mind module's intent modeling addresses a real gap in how both systems handle ambiguous user instructions.

### 3. Google ADK — Medium-High Relevance

**Rationale:** ADK contributes three specific patterns: declarative agent configuration (validating GSD's existing approach), session rewind (a new capability), and per-tool HITL confirmation (a finer-grained version of GSD's checkpoints). The multi-language validation is encouraging for GSD's Node.js/TypeScript approach. The A2A protocol is not relevant for our single-framework use case but signals industry direction.

### 4. LangGraph — Medium Relevance

**Rationale:** LangGraph's durable execution and checkpoint/resume patterns are directly applicable to improving GSD's session persistence. The graph-based workflow model offers a formalization path for GSD's phase transitions but risks over-engineering for workflows that are inherently sequential. The human-in-the-loop interrupt model provides a pattern for more flexible checkpoint placement.

### 5. CrewAI — Medium-Low Relevance

**Rationale:** CrewAI's primary contribution is the role-based specialization pattern, which provides a template for formalizing GSD's agent registry. The built-in observability validates making tracing a first-class concern. But the role-playing metaphor and enterprise focus limit direct applicability.

### 6. AutoGen — Low Relevance (Pattern Value Only)

**Rationale:** AutoGen's agent-as-tool composability pattern is valuable as a design concept, but the framework itself is in active transition (deprecation notice) and carries a complex API surface. The MCP integration validates GSD's existing MCP support. The primary takeaway is the composability pattern, not the framework.

---

## Synthesis: What the Landscape Tells Us

Three meta-patterns emerge from examining these six frameworks alongside the academic literature:

**1. Context engineering is converging on the three-tier model.** Codified Context Infrastructure's hot/warm/cold tiers, LangGraph's working/checkpoint/long-term memory, and Google ADK's config/session/tool state are all implementations of the same insight: agents need always-available core context, task-specific loaded context, and on-demand queryable context. The unified methodology should formalize this as an explicit architectural decision rather than leaving it implicit in the current GSD/Superpowers design.

**2. Declarative agent definition is the industry standard.** Every framework that supports agent customization does so through configuration (YAML, JSON, Markdown) rather than requiring code changes. GSD's agent/*.md files and Superpowers' SKILL.md files already follow this pattern. The unified methodology should commit to declarative agent/skill definition as the primary configuration surface, with code reserved for the harness layer.

**3. The gap is in knowledge engineering, not agent orchestration.** Five of six frameworks focus on agent execution — how to run agents, compose them, and manage their state. Only Codified Context Infrastructure focuses on knowledge engineering — how to manage the context documents agents depend on. Yet the academic literature consistently identifies context quality as the primary lever for agent effectiveness. The unified methodology's largest opportunity is in the knowledge engineering space: treating context artifacts (KNOWLEDGE.md, references, skills) as load-bearing infrastructure with versioning, drift detection, and formal access patterns.

---

## References

1. CrewAI multi-agent framework. github.com/crewAIInc/crewAI
2. LangGraph stateful agent orchestration. github.com/langchain-ai/langgraph
3. AutoGen multi-agent framework. github.com/microsoft/autogen
4. OpenHands AI-driven development SDK. github.com/All-Hands-AI/OpenHands
5. Google Agent Development Kit. github.com/google/adk-python
6. Codified Context Infrastructure. github.com/arisvas4/codified-context-infrastructure
7. Hassan, M. M. et al. (2025). "SASE: Structured Agentic Software Engineering." arXiv:2509.06216.
8. Vasilopoulos, A. (2026). "Codified Context Infrastructure for AI-Assisted Software Development." arXiv:2602.20478.
9. Bui, S. (2026). "OpenDev: Terminal-Native Agent Scaffolding and Harness." arXiv:2603.05344.
10. Wong, J. et al. (2025). "Confucius: Scalable Code Agent Scaffolding." arXiv:2512.10398.
11. Tabarsi, A. et al. (2025). "LLMs' Reshaping of Software Engineering." arXiv:2503.05012.
