# Tiered State System Specification

**Version:** 0.1 — Design specification for D006 validation
**Status:** Initial specification; feasibility assessment included
**Parent:** `design/architecture-overview.md` — State Tier definitions (Section: Design Constraints & Tradeoffs)
**Decision under validation:** D006 — Proportional state with three tiers

---

## Overview: Why Proportional State

State management in an AI coding agent methodology faces a fundamental tension. GSD imposes a full state machine on every project — STATE.md with lockfile-based mutual exclusion, phase directories with PLAN.md/SUMMARY.md/VERIFICATION.md, HANDOFF.json for session continuity, and structured frontmatter for progress tracking. This works well for complex multi-phase projects but inflicts significant overhead on a developer who just wants to fix a bug. Superpowers takes the opposite position — zero persistent state, zero files, zero directories. This works well for focused single-session tasks but makes multi-session continuity impossible; every new session starts from zero, losing all accumulated context.

Neither extreme is correct. The GSD analysis (M001) documents the maintenance cost of persistent state: v1.32 specifically added STATE.md consistency gates to address state corruption bugs, and anti-pattern rule #15 prohibits direct Write/Edit to STATE.md because it bypasses lockfile-based mutual exclusion. The academic literature review (M001) documents the cost of statelessness: the Codified Context Infrastructure paper shows that agents without persistent context repeat mistakes and generate conflicting code. Both costs are real; the question is when each cost is justified.

**Proportional state** resolves this tension by scaling state complexity with project complexity. A 5-minute bug fix gets zero state overhead. A multi-session feature build gets enough state for continuity. A multi-phase autonomous execution gets the full state machine. The behavioral directives — iron laws, gate functions, rationalization prevention — remain constant across all tiers. State determines *what persists between sessions*; behavior determines *what happens within each session*.

This design directly implements D006's choice: "Proportional state with three tiers — Tier 0 (stateless) for single-session tasks, Tier 1 (lightweight: project brief + knowledge register + decision log) for multi-session work, Tier 2 (full orchestration with lockfile-based concurrency) for autonomous multi-phase execution."

---

## Tier 0 — Stateless

### Definition

Tier 0 is the absence of methodology state. No `.gsd/` directory exists. No methodology files are created. The agent operates within a single context window, using skills loaded at session start, and nothing persists after the session ends.

### When It Applies

- Single-session tasks: bug fixes, config changes, quick features
- Exploratory work: prototyping, investigation, code review
- Any task where the developer does not need cross-session memory
- The default state for any project that has not explicitly adopted the methodology's state artifacts

### What Is Active

All behavioral directives operate at Tier 0. The state tier controls persistence, not behavior.

**Active at Tier 0:**
- Iron laws (verification before completion, root-cause-first debugging, TDD when applicable)
- Gate functions (brainstorming gate for new features, verification gate for completion claims)
- Rationalization prevention tables (all evasion interception is active)
- Skill priority ordering (process skills before implementation skills)
- The 1% invocation threshold (if a skill might apply, it must be invoked)
- Dual-layer verification (behavioral gate function + programmatic stub detection when the infrastructure layer is available)
- Context management (degradation tiers, read-depth scaling)

**Not active at Tier 0:**
- Knowledge persistence (no KNOWLEDGE.md to append to)
- Decision tracking (no DECISIONS.md to record in)
- Session continuity (no HANDOFF.json, no continue-here mechanism)
- Progress tracking (no STATE.md, no milestone/phase/task tracking)
- Lockfile-based concurrency control (no state files to protect)

### What Is NOT Persisted

Nothing. The session's context window is the only memory. When the session ends, all context is lost. If the developer wants to preserve a decision or lesson, they do so through their own project artifacts (README, comments, documentation) — the methodology does not create or manage any files.

### User Experience

Zero setup. Zero files. Zero configuration. The developer opens a session, loads skills (automatically via session-start hook or manually), does the work, and closes the session. The methodology is entirely contained in the behavioral layer.

**The zero-overhead test:** If a developer uses the methodology for a quick fix and discovers that it has created files, directories, or configuration artifacts they did not ask for, the design has failed. Tier 0 is invisible — the methodology's value comes entirely from behavioral shaping, not from persistent infrastructure.

---

## Tier 1 — Lightweight

### Definition

Tier 1 introduces minimal persistent state through three human-editable Markdown files in a `.gsd/` directory. These files provide cross-session memory without the full machinery of orchestrated execution. Tier 1 is designed for multi-session projects where the developer is the coordinator — they guide work across sessions, and the state artifacts help them (and the agent) remember what was decided, what was learned, and what the project is about.

### The Three Artifacts

#### 1. Project Brief (`PROJECT.md`)

**Purpose:** Capture what the project is, what it aims to achieve, and what constraints it operates under. This is the "hot" context that should be loaded at the start of every session.

**Format:**

```markdown
# Project Brief

## Vision
[One paragraph describing what this project does and why]

## Constraints
- [Technical constraints, platform requirements, compatibility needs]
- [Business constraints, timeline, compliance requirements]

## Key Decisions
- [Major architectural decisions and their rationale]
- [Technology choices with justification]

## Current Focus
[What the project is currently working on — updated each session]
```

**What it enables:** Any agent starting a new session can read PROJECT.md and immediately understand the project context without the developer re-explaining everything. This addresses the Codified Context Infrastructure finding that "stale context causes agents to generate code conflicting with recent refactors" — by keeping PROJECT.md current, the agent's understanding matches the project's reality.

**Size constraint:** PROJECT.md should stay under 500 words. It is hot-tier context loaded into every session; bloated project briefs consume the context budget that should be spent on task-specific work. If the project brief exceeds 500 words, it should be refactored — move detailed decisions to DECISIONS.md, move technical details to project documentation.

#### 2. Knowledge Register (`KNOWLEDGE.md`)

**Purpose:** Accumulate project-specific rules, patterns, and lessons learned across sessions. This is an append-only register — entries are added but never removed (unless explicitly superseded by a newer entry).

**Format:**

```markdown
# Knowledge Register

<!-- Append-only. Each entry records a discovery that future sessions should know about. -->

## K001: [Short title]
**When:** [Date or session identifier]
**Context:** [What was happening when this was discovered]
**Rule/Pattern:** [The concrete rule or pattern — specific enough to act on]
**Why it matters:** [What goes wrong if this rule is ignored]

## K002: [Short title]
...
```

**What it enables:** Cross-session learning. When the agent discovers that "tests in this project must run with `--experimental-vm-modules` because the ESM loader isn't standard yet," that knowledge survives to the next session. Without this register, each session would rediscover the same requirement through the same error-debug-fix cycle.

**Relationship to CCI's warm-tier memory:** The Knowledge Register maps to the Codified Context Infrastructure's warm tier — domain-specific knowledge loaded per-task when relevant. Unlike hot-tier content (which is always loaded), knowledge entries are scanned at session start and relevant entries are loaded based on the current task context. The Confucius SDK's "hindsight notes" pattern influences the format: each entry captures not just what was learned but the context of the failure that motivated the learning, making it more actionable for future agents.

**Growth management:** The knowledge register grows monotonically. Over many sessions, it could become large enough to strain the context budget. Two mitigations: (1) entries are loaded selectively based on relevance to the current task, not all at once; (2) when the register exceeds 50 entries, the developer (or an agent in orchestrated mode) should consolidate related entries into summarized rules. The append-only constraint prevents accidental knowledge loss; consolidation is a deliberate editorial action.

#### 3. Decision Log (`DECISIONS.md`)

**Purpose:** Record significant decisions with their rationale, so future sessions understand not just *what* was decided but *why*. This prevents re-litigating settled questions and provides context for understanding existing code structure.

**Format:**

```markdown
# Decisions Register

<!-- Append-only. Never edit or remove existing rows.
     To reverse a decision, add a new row that supersedes it. -->

| # | When | Scope | Decision | Choice | Rationale | Revisable? |
|---|------|-------|----------|--------|-----------|------------|
| D001 | [date] | [scope] | [question] | [answer] | [why] | [yes/no + conditions] |
```

**What it enables:** Decision persistence and traceability. When a future session encounters a code pattern and wonders "why was it done this way?" the decision log provides the answer. When a decision needs to be revisited, the log shows the original rationale, enabling informed revision rather than blind reversal.

**Relationship to CCI's cold-tier memory:** Decisions are cold-tier content — accessed on demand when the agent encounters a decision-relevant context, not loaded into every session proactively. The decision log is queried when the agent is considering a change that might conflict with a prior decision, or when the developer asks about the rationale for an existing choice.

### Why These Three and Not More

The three-artifact design follows from a constraint analysis:

1. **Cross-session memory requires knowing what the project is** (PROJECT.md), **what was learned** (KNOWLEDGE.md), and **what was decided** (DECISIONS.md). These three categories are exhaustive for the information a new session needs to continue coherently.

2. **Adding a fourth artifact (e.g., a task tracker or progress file) would create a maintenance burden** that pushes toward Tier 2. If the developer needs progress tracking, they need the full orchestration tier — halfway measures (a simple task list without dependency tracking, wave coordination, or lockfile safety) create a false sense of order that breaks under real-world complexity.

3. **Fewer than three is insufficient.** Removing the decision log means re-litigating decisions. Removing the knowledge register means re-learning lessons. Removing the project brief means re-explaining context. Each artifact addresses a distinct failure mode of statelessness.

4. **The Codified Context Infrastructure study validates minimal artifacts:** Vasilopoulos found that context documents are "load-bearing infrastructure" — they must be maintained or they cause harm. Three files is a maintenance burden a developer can sustain. Ten files is not. The threshold for "too many to maintain" is lower than most engineers assume.

### Why Human-Editable Markdown

Tier 1 artifacts are plain Markdown files that developers can read and edit directly. This is a deliberate design choice:

- **No YAML frontmatter, no structured data, no parsing required.** If Tier 1 artifacts needed a CLI tool to update, the design would have failed the zero-overhead test. The developer must be able to open any Tier 1 file in their editor, understand its contents immediately, and make changes directly.
- **No lockfile management.** Tier 1 assumes a single developer working across sessions. Concurrent access is not a concern — if multiple agents need to update state simultaneously, that is a Tier 2 scenario requiring full lockfile-based mutual exclusion.
- **Git-friendly.** All three files diff cleanly, merge predictably, and provide meaningful commit history. A developer can review the knowledge register's git log to see how understanding evolved.

---

## Tier 2 — Full Orchestration

### Definition

Tier 2 provides the complete state machine required for autonomous multi-phase execution. It includes everything in Tier 1 plus phase/milestone directories, plan files, summary files, verification reports, structured handoff documents, and lockfile-based concurrency control. Tier 2 is designed for scenarios where the orchestrator coordinates multiple agents executing in parallel, and state integrity must be guaranteed programmatically.

### Full Artifact Set

Tier 2 includes the Tier 1 artifacts (PROJECT.md, KNOWLEDGE.md, DECISIONS.md) plus:

| Artifact | Purpose | Maintained By |
|----------|---------|---------------|
| `STATE.md` | Living project memory — current position, active blockers, session history, performance metrics | Infrastructure layer (CLI tools with lockfile protection) |
| `ROADMAP.md` | Milestone and slice breakdown with dependency ordering and completion tracking | Infrastructure layer (plan tools) |
| `milestones/` directories | Per-milestone containers with slices, tasks, plans, summaries | Orchestrator + executors |
| `PLAN.md` files | Execution-ready task decompositions with file lists, verification commands, wave assignments | Planner agent |
| `SUMMARY.md` files | Per-task execution reports with deviations, self-checks, key decisions | Executor agents |
| `VERIFICATION.md` | Post-execution verification reports with status (passed/gaps_found/human_needed) and gap analysis | Verifier agent |
| `HANDOFF.json` | Structured session continuity — blockers, pending actions, in-progress state, environment context | Infrastructure layer (pause/resume protocol) |
| `*.lock` files | Lockfile-based mutual exclusion for concurrent state access (O_EXCL atomic creation, 10s stale detection, spin-wait with jitter) | Infrastructure layer (state management service) |
| `UAT.md` | User acceptance testing checklists and verification debt tracking | Verifier + human |

### Lockfile-Based Concurrency Mechanics

In orchestrated mode, multiple agents may attempt to update state simultaneously (e.g., two parallel executors completing tasks in the same wave). Tier 2 uses lockfile-based mutual exclusion adapted from GSD's `state.cjs`:

1. **Atomic lock creation:** Lock files (e.g., `STATE.md.lock`) are created with `O_EXCL` flag — the filesystem guarantees only one process succeeds if two attempt creation simultaneously.
2. **Stale lock detection:** If a lock file exists but is older than 10 seconds, it is considered stale (the holding process likely crashed) and is removed before a new lock attempt.
3. **Spin-wait with jitter:** If a lock is held by another process, the requesting process waits with randomized backoff (jitter prevents thundering herd when multiple agents wait for the same lock).
4. **Direct mutation prohibition:** All state file modifications must go through the infrastructure layer's CLI tools. Direct Write/Edit to STATE.md or ROADMAP.md bypasses lockfile protection, field validation, and consistent formatting — this is explicitly prohibited (GSD's anti-pattern rule #15).

### Session Continuity

Tier 2 provides structured session handoff via HANDOFF.json:

```json
{
  "position": {
    "milestone": "M002",
    "slice": "S01",
    "task": "T03",
    "status": "in-progress"
  },
  "blockers": [],
  "pendingActions": [
    { "type": "human-verify", "description": "Review UI layout" }
  ],
  "environment": {
    "branch": "m002-s01",
    "lastCommit": "abc1234"
  },
  "nextSteps": [
    "Complete T03 verification pipeline spec",
    "Run slice verification script"
  ]
}
```

When a session ends (whether through pause, context exhaustion, or crash), the infrastructure layer writes HANDOFF.json with the current state. When a new session begins, the resume protocol reads HANDOFF.json and reconstructs context — the new session continues from where the prior one left off, not from the beginning.

### Progress Tracking

Tier 2 enables progress tracking through:

- **Plan completion:** PLAN.md checkbox tracking (tasks marked complete/incomplete)
- **Roadmap progress:** ROADMAP.md slice completion tracking (slices marked done/in-progress/pending)
- **Regression detection:** Running prior phases' test suites after execution to catch regressions introduced by new work
- **Verification debt:** Cross-phase tracking of unresolved UAT items and verification gaps

---

## Tier Detection Heuristics

The methodology determines the current state tier through filesystem observation. No CLI tool or configuration command is required — the tier is an emergent property of what files exist on disk.

### Detection Rules

| Rule | Condition | Detected Tier | Confidence |
|------|-----------|---------------|------------|
| R1 | No `.gsd/` directory exists | Tier 0 | Definitive |
| R2 | `.gsd/` exists but contains only `PROJECT.md`, `KNOWLEDGE.md`, and/or `DECISIONS.md` (no milestone directories, no STATE.md, no ROADMAP.md) | Tier 1 | Definitive |
| R3 | `.gsd/` contains milestone directories (e.g., `milestones/M001/`) with PLAN.md files | Tier 2 | Definitive |
| R4 | `.gsd/` contains STATE.md or ROADMAP.md | Tier 2 | Definitive |
| R5 | `.gsd/` exists but is empty or contains only unrecognized files | Tier 0 (treat as uninitialized) | High |

### Detection Algorithm

```
function detectTier(projectRoot):
  gsdDir = projectRoot / ".gsd"
  
  if not gsdDir.exists():
    return Tier0
  
  hasMilestones = any directory matching "milestones/M*" exists in gsdDir
  hasState = (gsdDir / "STATE.md").exists()
  hasRoadmap = (gsdDir / "ROADMAP.md").exists()
  
  if hasMilestones or hasState or hasRoadmap:
    return Tier2
  
  hasBrief = (gsdDir / "PROJECT.md").exists()
  hasKnowledge = (gsdDir / "KNOWLEDGE.md").exists()
  hasDecisions = (gsdDir / "DECISIONS.md").exists()
  
  if hasBrief or hasKnowledge or hasDecisions:
    return Tier1
  
  return Tier0  // .gsd/ exists but has no recognized content
```

### Why Filesystem-Observable

The detection algorithm uses only `exists()` checks on known file paths. This design choice is critical:

1. **No CLI dependency for tier detection.** If determining the tier required running `gsd-tools detect-tier`, the methodology would impose a runtime requirement on every session start — including sessions that should be Tier 0 (zero overhead). The filesystem check runs in the session-start hook as a series of path existence tests, requiring no external tooling.

2. **No configuration file.** If the developer had to set `tier: 1` in a config file, they would need to know about tiers before using the methodology. The tier should be an emergent property of what artifacts exist, not a declaration the developer must maintain.

3. **Deterministic and inspectable.** Any developer can determine the current tier by looking at the `.gsd/` directory contents. There is no hidden state, no database query, no API call. The tier is what you see.

4. **Agent-observable.** Any agent can determine the tier through file reads without needing tool access beyond basic filesystem operations. This means tier detection works in both the behavioral layer (agent reads files) and the infrastructure layer (hook checks paths).

---

## Escalation Mechanics

### Tier 0 → Tier 1: Adopting Persistent Memory

**When to escalate:** When a project spans multiple sessions and the developer (or agent) wants continuity. Concrete triggers:

- The developer starts a second session on the same project and expresses intent to continue prior work ("let's pick up where we left off," "continue the refactoring we started")
- The agent discovers a project-specific rule or constraint that should survive the current session
- The developer makes a significant design decision that should be recorded for future reference
- The developer explicitly asks for project setup or initialization

**How escalation happens:**

1. Create `.gsd/` directory in the project root
2. Create the relevant Tier 1 artifact(s). Not all three are required simultaneously — the developer might start with just KNOWLEDGE.md to capture a discovery, or just DECISIONS.md to record a decision. PROJECT.md is created when the project scope is established.
3. The session-start hook detects the `.gsd/` directory on next session start and loads Tier 1 context.

**What happens to existing work:** Nothing. Tier 0 has no state to migrate. The escalation creates new files; it does not modify existing project artifacts.

**Who triggers it:** In interactive mode, the developer triggers escalation by asking to set up project continuity, or the agent suggests it when multi-session patterns are detected. In orchestrated mode, Tier 0→1 is skipped — orchestrated mode always starts at Tier 2.

### Tier 1 → Tier 2: Adopting Full Orchestration

**When to escalate:** When the project requires autonomous multi-phase execution, parallel agent coordination, or structured progress tracking. Concrete triggers:

- Auto-mode launches a milestone (the orchestrator creates milestone directories, STATE.md, and ROADMAP.md automatically)
- The developer requests structured planning with task decomposition, wave analysis, and automated execution
- The project grows to require multiple coordinated work streams with dependency tracking
- The developer explicitly asks for the full methodology pipeline (discuss → plan → execute → verify)

**How escalation happens:**

1. The infrastructure layer creates Tier 2 artifacts: STATE.md, ROADMAP.md, milestone directories
2. Tier 1 artifacts (PROJECT.md, KNOWLEDGE.md, DECISIONS.md) are preserved as-is. They become part of the Tier 2 context delivery chain — PROJECT.md feeds into all agents, KNOWLEDGE.md provides cross-session learning, DECISIONS.md provides decision context.
3. The lockfile-based concurrency system activates for state mutations.
4. The session-start hook detects Tier 2 artifacts and initializes the full infrastructure.

**What happens to existing Tier 1 artifacts:** They are preserved and promoted. PROJECT.md becomes the project context document loaded into every spawned agent. KNOWLEDGE.md entries are available to all agents. DECISIONS.md is referenced during planning and execution. Nothing is re-done — the Tier 1 artifacts are the seed for Tier 2's richer state.

**Migration cost:** Minimal. Tier 1 artifacts are human-readable Markdown with no structural requirements beyond the formats defined above. The infrastructure layer reads them as inputs, not as structured state that needs format migration.

### Tier 2 → Tier 1: Descaling After Completion

**When to descale:** After a milestone completes and the developer returns to maintenance mode. The full orchestration machinery is no longer needed for bug fixes and small changes.

**How descaling happens:**

1. Milestone directories are archived (moved to an archive directory or committed as completed)
2. STATE.md and ROADMAP.md are removed or archived
3. Lockfile management is deactivated
4. Tier 1 artifacts (PROJECT.md, KNOWLEDGE.md, DECISIONS.md) remain — they retain the accumulated knowledge and decisions from the completed milestone

**What survives descaling:** All knowledge and decisions. The developer's cross-session memory is preserved in Tier 1 format. What is removed is the orchestration machinery — the state tracking, progress monitoring, and concurrency control that are only needed during active multi-phase execution.

### Tier 1 → Tier 0: Full Teardown

**When to revert:** When the developer no longer needs cross-session memory for this project — the project is complete, handed off, or the developer prefers a clean start.

**How reversion happens:** Delete the `.gsd/` directory. All methodology state is gone. The next session starts at Tier 0.

**This is intentionally permanent.** Deleting `.gsd/` removes accumulated knowledge and decisions. If the developer wants to preserve these, they should commit them to version control before deletion or move them to project documentation.

---

## Behavioral Anchoring Across Tiers

The most important design principle in the tiered state system: **behavioral directives are constants; state is the variable.**

### What Does NOT Change Across Tiers

| Behavioral Directive | Active at Tier 0 | Active at Tier 1 | Active at Tier 2 |
|---------------------|:-:|:-:|:-:|
| Iron law: verification before completion | ✓ | ✓ | ✓ |
| Iron law: root-cause-first debugging | ✓ | ✓ | ✓ |
| Iron law: TDD when applicable | ✓ | ✓ | ✓ |
| Gate: brainstorming before implementation | ✓ | ✓ | ✓ |
| Gate: verification before completion claims | ✓ | ✓ | ✓ |
| Rationalization prevention (all tables) | ✓ | ✓ | ✓ |
| Skill priority ordering (process before implementation) | ✓ | ✓ | ✓ |
| 1% invocation threshold | ✓ | ✓ | ✓ |
| Anti-sycophancy in code review | ✓ | ✓ | ✓ |
| Context budget management | ✓ | ✓ | ✓ |

### What DOES Change Across Tiers

| Capability | Tier 0 | Tier 1 | Tier 2 |
|-----------|--------|--------|--------|
| Cross-session memory | None | PROJECT.md + KNOWLEDGE.md + DECISIONS.md | Full state machine |
| Decision persistence | None (lost at session end) | DECISIONS.md (human-maintained) | DECISIONS.md + STATE.md decisions field (infrastructure-maintained) |
| Knowledge accumulation | None (lost at session end) | KNOWLEDGE.md (append-only) | KNOWLEDGE.md + structured summaries + hindsight annotations |
| Progress tracking | None | None (developer tracks manually) | ROADMAP.md + STATE.md + plan checkboxes |
| Session continuity | None | Manual (developer re-explains) | HANDOFF.json (structured, automatic) |
| Concurrency control | None (single agent) | None (single developer) | Lockfile-based mutual exclusion |
| Verification depth | Behavioral gate (self-verification) | Behavioral gate + programmatic checks | Behavioral gate + independent verifier agent + programmatic checks |
| Regression detection | None | None | Cross-phase test suite execution |

### The Behavioral Anchoring Principle

The table above makes the design philosophy explicit: **the methodology's quality guarantees come from behavior, not state.** A Tier 0 session with a skilled developer following iron laws and gate functions produces higher-quality output than a Tier 2 session where the developer ignores behavioral directives and relies on infrastructure enforcement alone.

State amplifies behavior. It does not replace it. Lockfile-based concurrency prevents state corruption, but it does not prevent bad code. Programmatic stub detection catches missed stubs, but it does not catch flawed design. Session continuity preserves context, but it does not ensure the context was good in the first place.

This anchoring principle means the methodology degrades gracefully. If the infrastructure layer is unavailable (broken hook, missing CLI tool, corrupted state file), the behavioral layer still functions. The developer loses enforcement and persistence but retains discipline and quality judgment. The reverse is not true — infrastructure without behavior produces well-formatted, well-tracked garbage.

---

## Feasibility Assessment

D006 established proportional state as the methodology's approach to state management. This section validates whether the design is implementable, identifies risks, and recommends adjustments where needed.

### Assessment Criteria

The feasibility assessment evaluates four questions, each representing a risk identified in the task plan:

- **(a)** Can Tier 1's three files genuinely support multi-session continuity?
- **(b)** Are the tier detection heuristics implementable without a CLI tool?
- **(c)** Can mid-project escalation avoid re-doing prior work?
- **(d)** Is there a risk of tier ambiguity (state that fits between tiers)?

### (a) Tier 1 Multi-Session Continuity: Feasible

**Question:** Can three Markdown files (PROJECT.md, KNOWLEDGE.md, DECISIONS.md) genuinely support multi-session continuity without Tier 2's full machinery?

**Assessment:** Yes, with a scope constraint.

Tier 1's three files support *developer-coordinated* multi-session continuity — where a human developer guides work across sessions, and the state artifacts help them and the agent maintain shared understanding. They do NOT support *autonomous* multi-session continuity — where an orchestrator automatically resumes and coordinates work without human involvement.

**Evidence:**

1. **CCI's warm-tier memory validates the pattern.** Vasilopoulos's 283-session study used 19 specialized agent documents (warm tier) and 34 knowledge base documents (cold tier) to maintain continuity across sessions. The warm-tier documents averaged 500–1000 words of domain-specific knowledge — comparable in density and purpose to Tier 1's three artifacts. The critical insight: continuity came from *what was in the documents*, not from state management machinery around them.

2. **Confucius SDK's persistent notes validate the mechanism.** Wong et al.'s hierarchical Markdown notes — including hindsight entries recording what the agent would have done differently — demonstrate that plain Markdown files provide effective cross-session memory when structured for agent consumption. No lockfiles, no state machine, no CLI tools — just well-structured Markdown read at session start.

3. **Real-world multi-session development validates the scope.** In interactive development (the scenario Tier 1 targets), continuity is maintained by a combination of project state (the codebase itself, git history), project artifacts (READMEs, specs, docs), and conversational re-establishment ("we were working on the auth system"). Tier 1's three files provide the third element — structured context for conversational re-establishment — while the codebase and git history provide the first two.

**Limitation:** Tier 1 cannot support progress tracking, task dependency management, or parallel execution coordination. If a multi-session project needs these capabilities, it needs Tier 2. This is by design — Tier 1's value proposition is "enough state for continuity, not enough state to orchestrate."

### (b) Tier Detection Without CLI Tool: Feasible

**Question:** Are the tier detection heuristics implementable without a CLI tool?

**Assessment:** Yes, definitively.

The detection algorithm uses only `exists()` checks on known paths. These can be implemented:

- **In a session-start hook** (the infrastructure layer's implementation) — 5-10 lines of JavaScript checking path existence
- **By an agent reading files** (the behavioral layer's implementation) — the agent checks for `.gsd/PROJECT.md`, `.gsd/milestones/`, etc. as part of its initial context assessment
- **By a human** (manual inspection) — look at the `.gsd/` directory structure

No algorithm, no state parsing, no YAML frontmatter inspection. The tier is determined entirely by which files and directories exist.

**Risk mitigation:** The detection rules are ordered by specificity — Tier 2 markers (milestone directories, STATE.md) take precedence over Tier 1 markers (PROJECT.md only). This prevents false Tier 1 detection when a Tier 2 project's Tier 1 artifacts are present alongside Tier 2 artifacts.

### (c) Mid-Project Escalation Without Re-doing Work: Feasible

**Question:** Can mid-project escalation (Tier 0→1, Tier 1→2) avoid re-doing prior work?

**Assessment:** Yes. Escalation is additive, not destructive.

**Tier 0→1:** Creates new files (PROJECT.md, KNOWLEDGE.md, DECISIONS.md). No prior state exists to migrate, so there is nothing to re-do. The developer may choose to retroactively populate the artifacts with decisions and knowledge from the current session, but this is forward documentation, not re-work.

**Tier 1→2:** Creates Tier 2 artifacts (STATE.md, ROADMAP.md, milestone directories) alongside existing Tier 1 artifacts. The Tier 1 files become inputs to the Tier 2 system — PROJECT.md is loaded as project context, KNOWLEDGE.md entries inform planning, DECISIONS.md constraints shape execution. No Tier 1 file is modified or migrated; they are consumed as-is by the Tier 2 infrastructure.

**Evidence from GSD:** GSD's existing state management demonstrates this pattern. When a project initializes (`/gsd-init`), it creates PROJECT.md first, then adds REQUIREMENTS.md, then ROADMAP.md, then phase directories — an additive sequence where each step builds on the previous without modifying it. The tiered model formalizes this existing pattern.

**One nuance:** When escalating from Tier 1→2, the PROJECT.md content should be reviewed for compatibility with the structured expectations of Tier 2 agents. If PROJECT.md was written as a free-form narrative (appropriate for Tier 1), a Tier 2 planner agent might prefer more structured content (explicit constraints, scoped requirements). This is a content quality concern, not a structural migration concern — the file format does not change, but the content depth expectation increases.

### (d) Tier Ambiguity Risk: Low, With One Edge Case

**Question:** Is there a risk of state that fits between tiers — too much for one tier, not enough for the next?

**Assessment:** Low risk overall. One edge case identified, with a clear resolution.

**Why the risk is low:** The three tiers map to genuinely distinct usage patterns:
- Tier 0: Single-session, no files → clearly stateless
- Tier 1: Multiple sessions, developer-coordinated, 2-3 files → clearly lightweight
- Tier 2: Autonomous execution, orchestration, full artifact set → clearly full

The gap between these patterns is wide enough that most projects fall clearly into one tier.

**The edge case: "Tier 1.5" — structured task tracking without full orchestration.** A developer might want a simple task list (plan + track a few tasks) without the full machinery of waves, lockfiles, agents, and verification reports. This falls between Tier 1 (no progress tracking) and Tier 2 (full orchestration with lockfile-based concurrency).

**Resolution:** This edge case is handled by *not creating a new tier*. Instead, the developer can use Tier 1 with a simple task list in PROJECT.md's "Current Focus" section. If the task list becomes complex enough to need dependency tracking and automated execution, that signals escalation to Tier 2. The methodology does not optimize for the midpoint — it provides two clean states (lightweight vs. full) and trusts the developer to choose. Adding a Tier 1.5 would increase design complexity, add a new detection heuristic, and blur the clean boundary between "developer coordinates" and "orchestrator coordinates."

**Secondary edge case: unrecognized files in `.gsd/`.** If a developer creates custom files in `.gsd/` (e.g., `.gsd/notes.md`, `.gsd/scratch.txt`), the detection algorithm treats this as Tier 0 (no recognized artifacts). This is correct behavior — custom files are not methodology state, and the methodology should not assume they are.

### Overall Verdict: Feasible

**The D006 proportional state model is feasible as designed.** The three-tier model provides clear boundaries, filesystem-observable detection, additive escalation, and constant behavioral anchoring. No fundamental design changes are required.

Confidence levels:

| Component | Feasibility | Confidence | Notes |
|-----------|-------------|------------|-------|
| Tier 0 (stateless) | Feasible | High | Trivially implementable — it is the absence of state |
| Tier 1 (lightweight) | Feasible | High | Validated by CCI warm-tier model and Confucius persistent notes |
| Tier 2 (full orchestration) | Feasible | High | GSD's existing implementation demonstrates the full machinery |
| Tier detection heuristics | Feasible | High | Pure filesystem checks — no parsing, no CLI, no ambiguity for standard cases |
| Tier 0→1 escalation | Feasible | High | Additive file creation, no migration |
| Tier 1→2 escalation | Feasible | High | Additive artifact creation, Tier 1 files consumed as inputs |
| Tier 2→1 descaling | Feasible | Medium | Requires archival discipline — developer must decide what to archive |
| Behavioral anchoring | Feasible | High | Behavioral layer is mode/tier-independent by architecture |

---

## Design Adjustments

The feasibility assessment identified no fundamental changes needed to the D006 model. The following adjustments refine the design without altering its structure:

### Adjustment 1: PROJECT.md Size Constraint

**Issue:** PROJECT.md is hot-tier context loaded into every session. Without a size constraint, it grows unboundedly, consuming context budget that should serve task-specific work.

**Adjustment:** Add a 500-word soft limit to PROJECT.md. When exceeded, the developer should move detailed decisions to DECISIONS.md and technical details to project documentation. The infrastructure layer's session-start hook can warn when PROJECT.md exceeds the threshold.

**Impact:** Minor. Does not change the tier model — adds a quality guideline to Tier 1 artifact management.

### Adjustment 2: Knowledge Register Consolidation Protocol

**Issue:** KNOWLEDGE.md grows monotonically (append-only). Over many sessions, it could exceed the context budget for a single load.

**Adjustment:** When KNOWLEDGE.md exceeds 50 entries, the developer (or an agent in Tier 2) should consolidate related entries into summarized rules. The consolidation preserves the append-only invariant by adding a consolidated entry that supersedes (but does not delete) its source entries — superseded entries are marked with a `Superseded-by: KXXX` annotation.

**Impact:** Minor. Adds a maintenance protocol to the knowledge register; does not change the tier model.

### Adjustment 3: Escalation Suggestion Protocol

**Issue:** The developer might not realize when their project has outgrown the current tier. Without prompting, they could operate at Tier 0 for a multi-session project, losing valuable context between sessions.

**Adjustment:** The session-start hook (infrastructure layer) or the meta-skill behavioral directive (behavioral layer) should suggest escalation when signals indicate a mismatch:
- At Tier 0: If the agent detects this is a continuation of prior work (same directory, same codebase, prior conversation about this project), suggest creating `.gsd/PROJECT.md`.
- At Tier 1: If the developer requests multi-task execution with dependencies, suggest escalation to Tier 2.

Suggestions are advisory, not automatic. The developer decides.

**Impact:** Minor. Adds detection heuristics for escalation suggestions; does not change tier detection or escalation mechanics.

---

## Relationship to Architecture Components

### State System and Execution Modes

| Execution Mode | Typical Tier | Why |
|---------------|-------------|-----|
| Interactive | Tier 0 or Tier 1 | Developer coordinates; lightweight or no state needed |
| Orchestrated | Tier 2 | Orchestrator coordinates; full state required for concurrency, progress tracking, handoffs |

Interactive mode *can* operate at Tier 2 (the developer works within an active milestone), and this is common — a developer executing tasks within a Tier 2 milestone uses interactive mode for individual tasks while the orchestration infrastructure manages cross-task coordination. The mode and tier are orthogonal axes: mode describes *how* work is coordinated; tier describes *how much* state is persisted.

### State System and Three-Tier Memory Model

The state tiers map to — but are distinct from — the three-tier memory model defined in `design/architecture-overview.md`:

| Memory Tier | State Tier 0 | State Tier 1 | State Tier 2 |
|-------------|-------------|-------------|-------------|
| Hot (always loaded) | Iron laws, gate functions, meta-skill protocol | Same + PROJECT.md summary | Same + STATE.md current position |
| Warm (per-task) | Relevant skills, task context from conversation | Same + KNOWLEDGE.md entries | Same + PLAN.md, CONTEXT.md, RESEARCH.md |
| Cold (on-demand) | Codebase, docs, git history | Same + DECISIONS.md | Same + prior SUMMARY.md, VERIFICATION.md, reference docs |

The state system determines what *artifacts exist* to populate each memory tier. The memory model determines *when and how* those artifacts are loaded into agent context. They are complementary subsystems — the state system feeds the memory model, and the memory model consumes the state system's output.

### State System and Verification Pipeline

Verification depth scales with state tier, but verification *discipline* does not:

- **Tier 0:** Behavioral verification (gate function) plus programmatic stub detection (if infrastructure layer available). The agent runs verification commands and reads output honestly. No independent verifier agent.
- **Tier 1:** Same as Tier 0. Tier 1 does not add verification infrastructure — it adds persistence, not enforcement.
- **Tier 2:** Behavioral verification + programmatic stub detection + independent verifier agent + cross-phase regression detection. The verifier agent operates with a distrust mindset, independently inspecting the codebase rather than trusting executor claims.

The detailed verification pipeline specification is in `design/verification-pipeline.md`.

---

## Summary

The tiered state system implements D006's proportional state model through three filesystem-observable tiers:

1. **Tier 0** — Zero overhead, zero files, all behavioral directives active, nothing persisted
2. **Tier 1** — Three human-editable Markdown files providing cross-session memory for developer-coordinated multi-session work
3. **Tier 2** — Full state machine with lockfile-based concurrency for orchestrator-coordinated autonomous execution

Tier detection is filesystem-observable (no CLI tool required). Escalation is additive (no prior work is re-done). Behavioral directives are constant across all tiers (iron laws, gate functions, and rationalization prevention never vary by tier). The feasibility verdict is **feasible** — no fundamental design changes are required, with three minor adjustments recommended for artifact size management, knowledge consolidation, and escalation suggestion.
