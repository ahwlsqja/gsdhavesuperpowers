# GSD Architecture Analysis

A deep analysis of Get Shit Done (GSD v1.32) — a meta-prompting framework that sits between the user and AI coding agents, providing context engineering, multi-agent orchestration, spec-driven development, and persistent state management.

---

## 1. Architecture Overview

### Design Philosophy

GSD is built on five design principles that shape every component:

1. **Fresh Context Per Agent** — Every agent spawned by an orchestrator gets a clean context window (up to 200K tokens, or 1M for models that support it). This eliminates context rot — the quality degradation that occurs as an AI fills its context window with accumulated conversation. Each executor, researcher, planner, and verifier starts clean, receiving only the artifacts it needs.

2. **Thin Orchestrators** — Workflow files (`get-shit-done/workflows/*.md`) never do heavy lifting. They load context via `gsd-tools.cjs init <workflow>`, spawn specialized agents with focused prompts, collect results and route to the next step, and update state between steps. The orchestrator coordinates; agents execute.

3. **File-Based State** — All state lives in `.planning/` as human-readable Markdown and JSON. No database, no server, no external dependencies. State survives context resets (`/clear`), is inspectable by both humans and agents, and can be committed to git for team visibility.

4. **Absent = Enabled** — Workflow feature flags follow the absent = enabled pattern. If a key is missing from `config.json`, it defaults to `true`. Users explicitly disable features; they don't need to enable defaults. This ensures the full pipeline runs by default.

5. **Defense in Depth** — Multiple layers prevent common failure modes: plans are verified before execution (plan-checker agent), execution produces atomic commits per task, post-execution verification checks against phase goals, and UAT provides human verification as a final gate.

### Layer Model

GSD operates through five distinct layers, each with a clear responsibility boundary:

```
USER → COMMANDS → WORKFLOWS → AGENTS → CLI TOOLS → FILE SYSTEM
```

- **Command Layer** (`commands/gsd/*.md`, 60 files) — User-facing entry points. Each file contains YAML frontmatter (name, description, allowed-tools) and a prompt body that bootstraps the workflow. Commands are installed as slash commands in Claude Code, skills in Codex, etc.

- **Workflow Layer** (`get-shit-done/workflows/*.md`, 60 files) — Orchestration logic. Workflows read references, spawn agents, manage state, and handle checkpoints. Key workflows include `autonomous.md` (1036 lines), `execute-phase.md` (1153 lines), `discuss-phase.md`, and `plan-phase.md`.

- **Agent Layer** (`agents/*.md`, 21 files) — Specialized agent definitions with frontmatter specifying name, description, allowed tools, and terminal color. Agents are spawned with fresh context windows and focused prompts.

- **CLI Tools Layer** (`get-shit-done/bin/gsd-tools.cjs` + 19 modules) — Node.js CLI utility providing atomic commands for state management, config parsing, phase operations, roadmap manipulation, verification, template rendering, and more. This is the programmatic backbone — what makes file-based state management safe and consistent.

- **File System Layer** (`.planning/`) — Persistent project memory. All artifacts (PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md, phase directories, PLAN.md, SUMMARY.md, VERIFICATION.md, UAT.md) live as human-readable Markdown.

### Implications for a Unified Methodology

The layer model creates clear boundaries: prompts stay in the prompt layer (commands, workflows, agents, references, templates), while programmatic logic stays in the CLI and SDK layers. This separation means prompt-based components can be adapted by editing Markdown, while programmatic components require code changes. The distinction is critical for understanding what GSD enables versus what it enforces.

---

## 2. Agent System

### Agent Registry (21 Agents)

GSD defines 21 specialized agents organized into 12 functional categories:

| Category | Agents | Parallelism |
|----------|--------|-------------|
| **Researchers** | `gsd-project-researcher`, `gsd-phase-researcher`, `gsd-ui-researcher`, `gsd-advisor-researcher` | 4 parallel (stack, features, architecture, pitfalls) |
| **Synthesizers** | `gsd-research-synthesizer` | Sequential (after researchers complete) |
| **Planners** | `gsd-planner`, `gsd-roadmapper` | Sequential |
| **Checkers** | `gsd-plan-checker`, `gsd-integration-checker`, `gsd-ui-checker`, `gsd-nyquist-auditor` | Sequential (max 3 iteration loop) |
| **Executors** | `gsd-executor` | Parallel within waves, sequential across waves |
| **Verifiers** | `gsd-verifier` | Sequential (after all executors) |
| **Mappers** | `gsd-codebase-mapper` | 4 parallel (tech, arch, quality, concerns) |
| **Debuggers** | `gsd-debugger` | Sequential (interactive) |
| **Auditors** | `gsd-ui-auditor`, `gsd-security-auditor` | Sequential |
| **Doc Writers** | `gsd-doc-writer`, `gsd-doc-verifier` | Sequential (writer then verifier) |
| **Profilers** | `gsd-user-profiler` | Sequential |
| **Analyzers** | `gsd-assumptions-analyzer` | Sequential (during discuss-phase) |

Each agent is defined in `agents/gsd-{name}.md` with YAML frontmatter specifying its name, description, allowed tools (Read, Write, Edit, Bash, Grep, Glob, WebSearch, mcp__context7__*, etc.), and terminal color for visual distinction.

### Spawn Mechanism

The orchestrator-agent pattern follows a rigid protocol:

1. **Load context**: `gsd-tools.cjs init <workflow> <phase>` — Returns a JSON payload with project info, config, state, and phase details.
2. **Resolve model**: `gsd-tools.cjs resolve-model <agent-name>` — Returns the appropriate model tier (opus, sonnet, haiku, or inherit) based on the active profile.
3. **Spawn agent**: Using `Task()` or `SubAgent()` with the agent definition, context payload, model assignment, and tool permissions.
4. **Collect result**: Parse the agent's completion marker and output artifacts.
5. **Update state**: `gsd-tools.cjs state update/patch/advance-plan` — Persist progress.

### Model Profiles

GSD supports four model profiles (`quality`, `balanced`, `budget`, `inherit`) that control which AI model each agent uses. The profile assignments are defined in `get-shit-done/references/model-profiles.md`:

- **Quality**: All key agents get Opus — highest quality, highest cost.
- **Balanced**: Planners get Opus, executors get Sonnet, researchers get Sonnet — good tradeoff.
- **Budget**: Everyone gets Sonnet or Haiku — lowest cost.
- **Inherit**: Defers to the runtime's current model selection — essential for non-Anthropic providers.

Model resolution happens once per orchestration, not per spawn (`get-shit-done/references/model-profile-resolution.md`). Per-agent overrides take precedence over profile assignments.

### Completion Contracts

Agents signal completion through structured Markdown markers defined in `get-shit-done/references/agent-contracts.md`. Each agent has specific markers:

- `gsd-planner`: `## PLANNING COMPLETE`
- `gsd-executor`: `## PLAN COMPLETE` or `## CHECKPOINT REACHED`
- `gsd-verifier`: `## Verification Complete` (title case — intentional)
- `gsd-plan-checker`: `## VERIFICATION PASSED` or `## ISSUES FOUND`
- `gsd-phase-researcher`: `## RESEARCH COMPLETE` or `## RESEARCH BLOCKED`

Handoff contracts define formal interfaces between agents. The Planner→Executor handoff is via PLAN.md with required frontmatter (phase, plan, type, wave, depends_on, files_modified, autonomous, requirements) plus `<objective>`, `<tasks>`, `<verification>`, and `<success_criteria>` sections. The Executor→Verifier handoff is via SUMMARY.md with frontmatter (phase, plan, subsystem, tags, key-files, metrics) plus commits table, deviations section, and self-check result.

### Key Agent Deep-Dives

**gsd-executor** (`agents/gsd-executor.md`) — The plan executor implements four deviation rules that allow autonomous decision-making during execution:
- **Rule 1 (Auto-fix bugs)**: Wrong queries, logic errors, type errors — fix inline without asking.
- **Rule 2 (Auto-add missing critical functionality)**: Missing error handling, no input validation, no auth — add automatically.
- **Rule 3 (Auto-fix blocking issues)**: Missing dependency, wrong types, broken imports — fix to unblock.
- **Rule 4 (Ask about architectural changes)**: New DB tables, switching libraries, breaking APIs — STOP and ask.

The executor also implements an analysis paralysis guard: after 5+ consecutive Read/Grep/Glob calls without any Edit/Write/Bash action, it must stop and either write code or report being blocked. Authentication gates (401, 403 errors) are treated as flow control, not failures — the executor returns a checkpoint for human action.

**gsd-planner** (`agents/gsd-planner.md`) — Uses goal-backward methodology: start from what must be TRUE for the phase goal to be achieved, derive observable truths, required artifacts, required wiring, and key links. Plans are sized to complete within ~50% context budget (2-3 tasks per plan) to maintain quality. The planner enforces a scope reduction prohibition — it must never simplify user decisions silently. If a phase is too complex, it recommends splitting rather than delivering a "v1" that doesn't match what the user decided. The planner also includes a decomposed reference system: `planner-gap-closure.md`, `planner-reviews.md`, and `planner-revision.md` were split from the main agent file to stay under the 50K character limit imposed by some runtimes.

**gsd-verifier** (`agents/gsd-verifier.md`) — Implements four-level verification (Exists → Substantive → Wired → Functional) plus a Level 4 data-flow trace. The core principle is that task completion ≠ goal achievement. A task "create chat component" can be marked complete when the component is a placeholder — the verifier catches this by checking that artifacts are not just present but substantive, wired to the rest of the system, and flowing real data. The verifier explicitly does NOT trust SUMMARY.md claims — it verifies what ACTUALLY exists in the code.

---

## 3. Workflow Engine

### The Pipeline: discuss → plan → execute → verify

GSD's core pipeline transforms a phase from abstract roadmap entry to verified implementation through four stages:

**Discuss Phase** (`get-shit-done/workflows/discuss-phase.md`) — Extracts implementation decisions using a "dream extraction" philosophy where the user is the visionary and Claude is the builder. The discuss phase identifies gray areas (decisions that could go multiple ways), categorizes them by domain type (visual, API, CLI, content, organization), and captures decisions in CONTEXT.md. Locked decisions become non-negotiable constraints for downstream agents. A scope guardrail prevents discussion creep — new capabilities get noted as deferred ideas, not incorporated into the current phase.

**Plan Phase** (`get-shit-done/workflows/plan-phase.md`) — Orchestrates three agents in sequence with a feedback loop:
1. **Research Gate**: Spawns `gsd-phase-researcher` to investigate implementation approaches, producing RESEARCH.md.
2. **Planning**: Spawns `gsd-planner` to create PLAN.md files with task breakdowns, dependency graphs, and wave assignments.
3. **Plan-Checker Loop**: Spawns `gsd-plan-checker` to verify plans against 8 quality dimensions (requirement coverage, task atomicity, dependency ordering, file scope, verification commands, context fit, gap detection, Nyquist compliance). If issues are found, the planner revises and the checker re-verifies — maximum 3 iterations.

Plans are structured as XML within Markdown, with `<task>` elements containing `<name>`, `<files>`, `<action>`, `<verify>`, and `<done>` fields. Each task specifies a type: `auto` (fully autonomous), `checkpoint:human-verify` (90% of checkpoints), `checkpoint:decision` (9%), or `checkpoint:human-action` (1%, rare).

**Execute Phase** (`get-shit-done/workflows/execute-phase.md`, 1153 lines) — Implements wave-based parallel execution:

1. **Discover plans**: Parse all PLAN.md files in the phase directory.
2. **Analyze dependencies**: Read `wave` and `depends_on` from frontmatter.
3. **Group into waves**: Plans with no dependencies form Wave 1 (parallel). Plans depending on Wave 1 form Wave 2. Continues until all plans are assigned.
4. **Spawn executors**: Each executor gets a fresh context window with the specific PLAN.md, project context, and phase context. For 1M-class models, prompts are enriched with prior wave summaries and phase research.
5. **Collect results**: Spot-check verification confirms SUMMARY.md existence and git commit state.
6. **Run verifier**: Spawns `gsd-verifier` to check phase goal achievement.

Parallel commit safety is ensured through two mechanisms:
- **`--no-verify` commits**: Parallel agents skip pre-commit hooks to avoid build lock contention (e.g., cargo lock fights in Rust projects). The orchestrator runs `git hook run pre-commit` once after each wave completes.
- **STATE.md file locking**: All `writeStateMd()` calls use lockfile-based mutual exclusion (`STATE.md.lock` with `O_EXCL` atomic creation, stale lock detection at 10s timeout, spin-wait with jitter).

**Verify Phase** — The verifier produces VERIFICATION.md with status (`passed`, `gaps_found`, `human_needed`) and a score (N/M must-haves verified). If gaps are found, they're structured in YAML frontmatter for `gsd-plan-phase --gaps` to consume and create targeted closure plans.

### Autonomous Mode

The autonomous workflow (`get-shit-done/workflows/autonomous.md`, 1036 lines) drives all remaining phases without manual intervention. It supports `--from N`, `--to N`, `--only N` (single phase), and `--interactive` flags. For each incomplete phase, it runs:

1. **Smart Discuss**: Proposes gray area answers in batch tables rather than sequential questioning. Users accept or override per area. Infrastructure-only phases (scaffolding, migration, refactor) skip discuss entirely.
2. **UI Design Contract**: Detects frontend phases and generates UI-SPEC.md before planning (respects `workflow.ui_phase` toggle).
3. **Plan**: Spawns the plan-phase pipeline.
4. **Execute**: Spawns the execute-phase pipeline with `--no-transition`.
5. **Post-Execution Routing**: Reads VERIFICATION.md status — passed routes automatically, human_needed prompts the user, gaps_found offers gap closure (limited to 1 retry to prevent infinite loops).
6. **UI Review**: Runs 6-pillar visual audit for frontend phases (advisory, non-blocking).
7. **Iterate**: Re-reads ROADMAP.md after each phase to catch dynamically inserted phases. Checks STATE.md for blockers.

After all phases complete, a lifecycle sequence runs: audit milestone → complete milestone (archive) → cleanup. The interactive mode (`--interactive`) enables pipeline parallelism: discuss Phase N+1 while Phase N builds, keeping the main context lean by delegating plan/execute to background agents.

### Wave Execution Detail

```
Wave Analysis:
  Plan 01 (no deps)      ─┐
  Plan 02 (no deps)      ─┤── Wave 1 (parallel)
  Plan 03 (depends: 01)  ─┤── Wave 2 (waits for Wave 1)
  Plan 04 (depends: 02)  ─┘
  Plan 05 (depends: 03,04) ── Wave 3 (waits for Wave 2)
```

Wave numbers are pre-computed during planning and stored in PLAN.md frontmatter. The execute-phase workflow reads these directly. Implicit dependencies are also detected: if two plans modify the same file, the later one is bumped to a subsequent wave. The planner prefers vertical slices (model + API + UI per feature) over horizontal layers (all models, then all APIs, then all UIs) to maximize parallelism.

### Adaptive Context Enrichment

When the context window is 500K+ tokens (1M-class models), subagent prompts are automatically enriched:
- **Executor agents** receive prior wave SUMMARY.md files and phase CONTEXT.md/RESEARCH.md, enabling cross-plan awareness within a phase.
- **Verifier agents** receive all PLAN.md, SUMMARY.md, CONTEXT.md files plus REQUIREMENTS.md, enabling history-aware verification.

The orchestrator reads `context_window` from config and conditionally includes richer context when the value is >= 500,000. For standard 200K windows, prompts use truncated versions with cache-friendly ordering.

---

## 4. CLI Tools

### Architecture

The CLI (`get-shit-done/bin/gsd-tools.cjs`) is a Node.js utility with 19 domain modules in `lib/`. It replaces repetitive inline bash patterns across ~50 GSD command/workflow/agent files, providing atomic operations that keep file-based state consistent.

### Module Inventory

| Module | Purpose | Key Mechanism |
|--------|---------|---------------|
| `core.cjs` | Error handling, output formatting, shared utilities | Central error boundary, JSON/text output switching via `--raw` |
| `state.cjs` | STATE.md parsing, updating, progression, metrics | YAML frontmatter CRUD, field-level updates, lockfile-based mutual exclusion |
| `phase.cjs` | Phase directory operations, decimal numbering, plan indexing | Decimal phase calculation (e.g., 3.1 between 3 and 4), plan wave grouping |
| `roadmap.cjs` | ROADMAP.md parsing, phase extraction, plan progress | Full roadmap analysis returning disk status and completion per phase |
| `config.cjs` | config.json read/write, section initialization | Absent=enabled defaults, section initialization |
| `verify.cjs` | Plan structure, phase completeness, reference, commit validation | 4-level verification (exists/substantive/wired/functional), artifact checking against must_haves, key-link verification |
| `template.cjs` | Template selection and filling with variable substitution | Template rendering with `{{variable}}` substitution from context |
| `frontmatter.cjs` | YAML frontmatter CRUD operations | Parse/update/validate frontmatter in Markdown files |
| `init.cjs` | Compound context loading for each workflow type | Single `init <workflow> <phase>` call returns full JSON context for any workflow |
| `milestone.cjs` | Milestone archival, requirements marking | Archive to MILESTONES.md, mark requirements complete in REQUIREMENTS.md |
| `commands.cjs` | Slug generation, timestamps, todos, scaffolding, stats | Utility operations: `generate-slug`, `current-timestamp`, `list-todos` |
| `model-profiles.cjs` | Model profile resolution table | Maps agent name + profile → model tier (opus/sonnet/haiku/inherit) |
| `security.cjs` | Path traversal prevention, prompt injection detection, safe JSON parsing, shell argument validation | 13+ regex patterns for injection detection, path sanitization |
| `uat.cjs` | UAT file parsing, verification debt tracking, audit-uat support | Cross-phase verification debt surfacing, blocked test categorization |
| `docs.cjs` | Docs-update workflow init, Markdown scanning, monorepo detection | Documentation generation support |
| `workstream.cjs` | Workstream CRUD, migration, session-scoped active pointer | Multi-workstream support with active pointer management |
| `schema-detect.cjs` | Schema-drift detection for ORM patterns | Detects Prisma, Drizzle, and other ORM schema changes |
| `profile-pipeline.cjs` | User behavioral profiling data pipeline | Session file scanning, message extraction, behavioral sampling |
| `profile-output.cjs` | Profile rendering, USER-PROFILE.md generation | Renders 8-dimension behavioral profiles from session data |

### Key Operations

**Context Loading** — The `init` command is the most important: `gsd-tools.cjs init execute-phase 5` returns a JSON payload with everything the execute-phase workflow needs — executor model, commit docs setting, phase directory, plan list, incomplete plan list, branching strategy, worktree config, and more. This single call replaces dozens of grep/cat/ls commands that workflows would otherwise need.

**State Management** — `state.cjs` provides atomic operations: `advance-plan` (increments current plan, handles edge cases), `update-progress` (recalculates from SUMMARY.md counts on disk), `record-metric` (appends to performance table), `add-decision` (records architectural choices), `record-session` (updates session timestamp). All mutations use safe update logic — direct Write/Edit to STATE.md is explicitly prohibited by anti-pattern rule #15.

**Verification** — `verify.cjs` implements programmatic artifact verification against PLAN.md `must_haves` frontmatter: `verify artifacts <plan_path>` checks existence, line count, and pattern matching; `verify key-links <plan_path>` checks that critical connections between files exist via regex pattern matching.

---

## 5. Hook System

### Architecture

GSD's 9 hooks integrate with the host AI agent's runtime to provide context monitoring, security scanning, status display, and update checking. Hooks are registered in `settings.json` and triggered by runtime events.

### Hook Registry

| Hook | File | Event | Mechanism |
|------|------|-------|-----------|
| **Context Monitor** | `gsd-context-monitor.js` | `PostToolUse` / `AfterTool` | Reads context metrics from a statusline bridge file (`/tmp/claude-ctx-{session}.json`). Injects warnings as `additionalContext` when remaining context drops below thresholds: WARNING at ≤35% remaining ("avoid starting new complex work"), CRITICAL at ≤25% ("context nearly exhausted"). Debounce: 5 tool uses between warnings. Severity escalation (WARNING→CRITICAL) bypasses debounce. |
| **Prompt Guard** | `gsd-prompt-guard.js` | `PreToolUse` | Scans `.planning/` writes for prompt injection patterns using 13 regex patterns (role override, instruction bypass, system tag injection) plus invisible Unicode detection. Advisory-only — logs detection, does not block. Patterns are inlined (subset of `security.cjs`) for hook independence. |
| **Statusline** | `gsd-statusline.js` | `statusLine` | Displays model, current task, directory, and context usage bar. Color coding: <50% green, <65% yellow, <80% orange, ≥80% red with skull emoji. Writes metrics to bridge file for the context monitor. |
| **Update Checker** | `gsd-check-update.js` | `SessionStart` | Background check for new GSD versions via npm. Caches results to `~/.claude/cache/gsd-update-check.json`. |
| **Workflow Guard** | `gsd-workflow-guard.js` | `PreToolUse` | Detects file edits outside GSD workflow context (no active `/gsd-` command). Advises using `/gsd-quick` or `/gsd-fast`. Opt-in via `hooks.workflow_guard: true` (default: false). |
| **Read Guard** | `gsd-read-guard.js` | `PreToolUse` | Advisory guard preventing Edit/Write on files not yet read in the session. Prevents blind edits. |
| **Session State** | `gsd-session-state.sh` | `PostToolUse` | Session state tracking for shell-based runtimes. |
| **Validate Commit** | `gsd-validate-commit.sh` | `PostToolUse` | Commit validation for conventional commit format enforcement. |
| **Phase Boundary** | `gsd-phase-boundary.sh` | `PostToolUse` | Phase boundary detection for workflow transitions. |

### Safety Properties

All hooks share critical safety characteristics:
- **Silent failure**: Every hook wraps in try/catch and exits silently on error — never blocks tool execution.
- **Stdin timeout guard**: 10-second timeout (3s in some hooks) prevents hanging on pipe issues (Windows/Git Bash, slow piping during large outputs).
- **Stale metric handling**: Context monitor ignores metrics older than 60 seconds.
- **Missing bridge file handling**: Graceful degradation when bridge files don't exist (subagents, fresh sessions).
- **Advisory-only**: Hooks inform, never override user preferences or block operations.
- **Path traversal protection**: Session IDs used in file paths are validated against `/../` and path separator characters.

### Bridge Architecture

The context monitoring system uses a two-part bridge:
1. The statusline hook (`gsd-statusline.js`) writes metrics to `/tmp/claude-ctx-{session}.json` — this is the only hook with access to real-time context usage data.
2. The context monitor hook (`gsd-context-monitor.js`) reads those metrics on each tool use and injects `additionalContext` warnings that the agent sees in its conversation — making the agent context-budget-aware.

This bridge pattern is necessary because the statusline event provides context data but can't inject agent-facing messages, while PostToolUse can inject messages but doesn't receive context data directly.

---

## 6. Reference System

### Architecture

References (`get-shit-done/references/*.md`, 25 files) are shared knowledge documents that workflows and agents `@-reference`. They encode patterns, contracts, and rules that multiple components need access to without duplicating content.

### Reference Inventory

| Reference | Purpose | Key Content |
|-----------|---------|-------------|
| `verification-patterns.md` | How to verify different artifact types | 4-level verification model (Exists → Substantive → Wired → Functional), universal stub detection patterns, React component/API route/DB schema/hook verification checklists |
| `agent-contracts.md` | Completion markers and handoff schemas | Registry of all 21 agents with their completion markers, formal Planner→Executor (PLAN.md) and Executor→Verifier (SUMMARY.md) handoff interfaces |
| `context-budget.md` | Context window budget allocation rules | Read depth scales by context window (200K vs 1M), context degradation tiers (PEAK/GOOD/DEGRADING/POOR), warning signs of quality degradation |
| `universal-anti-patterns.md` | 27 rules covering all common failure modes | Context budget rules, file reading rules, subagent rules, questioning anti-patterns, state management rules, behavioral rules, error recovery rules, GSD-specific rules |
| `model-profiles.md` | Per-agent model tier assignments | 4 profiles (quality/balanced/budget/inherit) with assignments for all agents |
| `model-profile-resolution.md` | Model resolution algorithm | How profile + per-agent overrides resolve to a final model tier |
| `questioning.md` | Dream extraction philosophy | "Thinking partner, not interviewer." Progressive depth questioning approach for project initialization |
| `checkpoints.md` | Checkpoint type definitions and interaction patterns | Human-verify (90%), decision (9%), human-action (1%), automation-first principle |
| `git-integration.md` | Git commit, branching, and history patterns | Atomic commits per task, structured format (`type(scope): description`), 3 branching strategies (none/phase/milestone) |
| `tdd.md` | Test-driven development integration | Red-Green-Refactor cycle, when to use TDD plans vs standard plans |
| `ui-brand.md` | Visual output formatting | Terminal output conventions for GSD workflows |
| `revision-loop.md` | Plan revision iteration patterns | How planner revises based on checker feedback (max 3 iterations) |
| `gate-prompts.md` | Gate/checkpoint prompt templates | Templates for quality gates and checkpoint interactions |
| `domain-probes.md` | Domain-specific probing questions | Questions organized by domain type for discuss-phase gray area identification |
| `continuation-format.md` | Session continuation/resume format | How to structure context handoff between sessions |
| `planner-gap-closure.md` | Gap closure mode for planner | How the planner creates targeted plans from VERIFICATION.md gaps |
| `planner-reviews.md` | Cross-AI review integration | How the planner incorporates feedback from external AI reviews |
| `planner-revision.md` | Plan revision patterns | How the planner processes checker feedback into plan revisions |
| `planning-config.md` | Full config schema | All configurable settings with types, defaults, and behavioral descriptions |
| `artifact-types.md` | Planning artifact type definitions | What each artifact type is and when to create it |
| `phase-argument-parsing.md` | Phase argument conventions | How phase numbers and flags are parsed |
| `decimal-phase-calculation.md` | Decimal sub-phase numbering | How to calculate decimal phases (e.g., 5.1 inserted between 5 and 6) |
| `workstream-flag.md` | Workstream active pointer | How the active workstream pointer works for multi-workstream projects |
| `user-profiling.md` | User behavioral profiling methodology | 8-dimension analysis (communication style, decision patterns, debugging approach, etc.) |

### Usage Pattern

References are loaded via `@-reference` syntax in agent and workflow files: `@~/.claude/get-shit-done/references/verification-patterns.md`. They're injected into the agent's context at spawn time, providing shared knowledge without duplicating content across multiple files. The planner was decomposed into a core agent plus three reference modules specifically because the monolithic file exceeded the 50K character limit imposed by some runtimes.

---

## 7. Template System

### Architecture

Templates (`get-shit-done/templates/`, 42 files) provide pre-structured Markdown for all planning artifacts. They're used by `gsd-tools.cjs template fill` and `scaffold` commands with `{{variable}}` substitution.

### Template Inventory by Category

**Core Project Templates (5)**:
- `project.md` — Project vision, constraints, decisions, evolution rules
- `requirements.md` — Scoped requirements (v1/v2/out-of-scope)
- `roadmap.md` — Phase breakdown with status tracking
- `state.md` — Living project memory (position, decisions, blockers, metrics)
- `config.json` — Workflow configuration with default settings

**Execution Templates (5)**:
- `phase-prompt.md` — Phase execution prompt template
- `summary.md` — Execution summary template (base)
- `summary-minimal.md` — Minimal summary for simple tasks
- `summary-standard.md` — Standard summary with full structure
- `summary-complex.md` — Complex summary for multi-concern plans

**Quality Templates (5)**:
- `DEBUG.md` — Debug session tracking template
- `UAT.md` — User acceptance testing template
- `VALIDATION.md` — Nyquist test coverage mapping template
- `UI-SPEC.md` — UI design contract template
- `SECURITY.md` — Security audit template

**Context and Research Templates (5)**:
- `context.md` — Phase-level discussion context
- `discovery.md` — Library/approach discovery
- `research.md` — Phase research template
- `discussion-log.md` — Discussion audit trail
- `continue-here.md` — Context handoff for session continuity

**Research Project Templates (5)** (`research-project/`):
- `SUMMARY.md`, `STACK.md`, `FEATURES.md`, `ARCHITECTURE.md`, `PITFALLS.md` — New project research output structure

**Brownfield Templates (7)** (`codebase/`):
- `stack.md`, `architecture.md`, `conventions.md`, `concerns.md`, `structure.md`, `testing.md`, `integrations.md` — Existing codebase mapping

**Specialized Templates (10)**:
- `claude-md.md` — CLAUDE.md generation for project instructions
- `copilot-instructions.md` — GitHub Copilot instructions adaptation
- `debug-subagent-prompt.md` — Debug agent spawn prompt
- `planner-subagent-prompt.md` — Planner agent spawn prompt
- `milestone.md` — Milestone planning template
- `milestone-archive.md` — Completed milestone archive
- `retrospective.md` — Milestone retrospective
- `user-profile.md` — User behavioral profile
- `dev-preferences.md` — Developer preferences
- `user-setup.md` — External service setup instructions
- `verification-report.md` — Verification report structure

### Granularity-Aware Summaries

The summary template system adapts to plan complexity:
- **Minimal** (`summary-minimal.md`): Simple tasks — streamlined frontmatter, basic outcomes.
- **Standard** (`summary-standard.md`): Typical tasks — full frontmatter, deviations, self-check.
- **Complex** (`summary-complex.md`): Multi-concern plans — rich frontmatter, dependency tracking, threat flags, stub tracking.

Template selection is based on task count and complexity heuristics in the executor agent.

---

## 8. SDK

### Architecture

The GSD SDK (`sdk/src/`, 16,623 lines TypeScript, 46 files including tests) provides a programmatic interface for running GSD plans without the interactive CLI. It enables headless execution, custom integrations, and programmatic control of the full GSD pipeline.

### Module Inventory

| Module | Purpose | What It Enables |
|--------|---------|-----------------|
| `index.ts` | Main GSD class with `executePlan()`, `runPhase()`, `run()` | Single-call plan execution, phase lifecycle, full milestone runs |
| `plan-parser.ts` | Parse PLAN.md files into structured objects | Frontmatter extraction, XML task parsing, dependency graph construction |
| `prompt-builder.ts` | Build executor prompts from plans and context | Assemble agent prompts with proper context injection, tool permissions |
| `prompt-sanitizer.ts` | Sanitize prompts for safe execution | Remove dangerous patterns, validate prompt structure |
| `context-engine.ts` | Context assembly and management | Load phase files (CONTEXT.md, RESEARCH.md, prior SUMMARYs), determine which artifacts to include based on context window size |
| `context-truncation.ts` | Smart context truncation | Markdown-aware truncation that preserves structure, milestone extraction for focused context |
| `phase-runner.ts` | Phase lifecycle state machine | Drives discuss→research→plan→execute→verify for a single phase with step-level result tracking |
| `session-runner.ts` | Run Claude query sessions | Execute prompts against Claude API with cost tracking, turn limits, error handling |
| `init-runner.ts` | Project initialization workflow | Programmatic new-project flow: questions → research → requirements → roadmap |
| `phase-prompt.ts` | Phase-specific prompt factory | Build prompts for each phase step (discuss, plan, execute, verify) with proper workflow and reference injection |
| `config.ts` | Configuration loading | Parse `.planning/config.json` with defaults, validate structure |
| `gsd-tools.ts` | TypeScript wrapper for gsd-tools.cjs | Typed interface to CLI tool operations (roadmapAnalyze, stateLoad, etc.) |
| `event-stream.ts` | Event emission system | Typed events (PlanStart, TaskComplete, PhaseComplete, MilestoneStart, etc.) for monitoring execution |
| `tool-scoping.ts` | Tool permission management | Map agents to allowed tools, enforce tool restrictions per phase step |
| `research-gate.ts` | Research gate checking | Determine if research is needed before planning (checks for unresolved open questions) |
| `logger.ts` | Structured logging | Log levels, entry formatting, GSD-specific log context |
| `cli-transport.ts` | CLI output transport | Format events as CLI output (progress bars, tables, status messages) |
| `ws-transport.ts` | WebSocket output transport | Stream events over WebSocket for remote/dashboard consumption |
| `types.ts` | Type definitions | GSDOptions, PlanResult, SessionOptions, GSDEvent, PhaseRunnerOptions, MilestoneRunnerOptions, etc. |

### Key Capabilities

**Single-Call Execution**: The `GSD` class provides three levels of execution:
1. `executePlan(planPath)` — Execute a single PLAN.md file and return a `PlanResult` with cost, duration, and success/error status.
2. `runPhase(phaseNumber)` — Drive a full phase lifecycle (discuss→research→plan→execute→verify) and return per-step results.
3. `run(prompt)` — Run an entire milestone: discover phases, execute each in order, re-discover after each completion to catch dynamic insertions.

**Event Streaming**: The `GSDEventStream` emits typed events throughout execution, enabling real-time monitoring via CLI transport (terminal output) or WebSocket transport (remote dashboards). Events include `PlanStart`, `TaskComplete`, `PhaseComplete`, `MilestoneStart`, and `MilestoneComplete` with cost and timing data.

**Context Engineering**: The `ContextEngine` assembles context for each agent based on the phase step and available context window. It manages the file manifest (which artifacts to load), handles truncation when context is limited, and enriches prompts for larger context windows.

**Transport Layer**: Two transports are provided — `CLITransport` for terminal output (progress bars, status messages) and `WSTransport` for WebSocket streaming. Custom transports can be implemented via the `TransportHandler` interface.

### Relationship to CLI Tools

The SDK wraps `gsd-tools.cjs` via `GSDTools` class, providing a typed TypeScript interface to CLI operations. This means the SDK can call `roadmapAnalyze()`, `stateLoad()`, `resolveModel()` etc. without shelling out to bash. However, the SDK adds its own higher-level abstractions: `PhaseRunner` orchestrates the phase lifecycle as a state machine, `ContextEngine` manages context assembly, and `PromptFactory` builds prompts — none of which exist in the CLI tools.

---

## 9. Multi-Runtime Support

### Architecture

GSD supports 10 AI coding agent runtimes through a unified command/workflow architecture with per-runtime transformations at install time:

| Runtime | Command Format | Agent System | Config Location |
|---------|---------------|--------------|-----------------|
| Claude Code | `/gsd-command` (slash commands) | Task spawning | `~/.claude/` |
| OpenCode | `/gsd-command` (slash commands) | Subagent mode | `~/.config/opencode/` |
| Kilo | `/gsd-command` (slash commands) | Subagent mode | `~/.config/kilo/` |
| Gemini CLI | `/gsd-command` (slash commands) | Task spawning | `~/.gemini/` |
| Codex | `$gsd-command` (skills) | Skills | `~/.codex/` |
| Copilot | `/gsd-command` (slash commands) | Agent delegation | `~/.github/` |
| Antigravity | Skills | Skills | `~/.gemini/antigravity/` |
| Trae | Skills | Skills | `~/.trae/` |
| Cline | Rules | Rules | `.clinerules` |
| Augment Code | Skills | Skills | Augment config |

### Transformation Points

The installer (`bin/install.js`, ~3,000 lines) transforms content at five abstraction points:
1. **Tool name mapping**: Each runtime has its own tool names (e.g., Claude's `Bash` → Copilot's `execute`).
2. **Hook event names**: Claude uses `PostToolUse`, Gemini uses `AfterTool`.
3. **Agent frontmatter**: Each runtime has its own agent definition format.
4. **Path conventions**: Each runtime stores config in different directories.
5. **Model references**: The `inherit` profile lets GSD defer to runtime's model selection.

Workflows and agents are written in Claude Code's native format and transformed during deployment. This means the source of truth is always Claude Code format — other runtimes are derived.

### Runtime-Specific Adaptations

- **Copilot**: Subagent spawning doesn't reliably return completion signals, so execute-phase defaults to sequential inline execution with spot-check fallback for completion detection.
- **Gemini**: Hook events use `AfterTool` instead of `PostToolUse`.
- **Codex**: Commands become TOML skills, agents become skills with descriptions.
- **Cline**: Uses `.clinerules` for rule-based integration instead of commands.

---

## 10. Quality Assurance Mechanisms

### Verification Pipeline

GSD implements multiple overlapping quality gates:

1. **Plan Checker** (`gsd-plan-checker`): Verifies plans against 8 dimensions before execution — requirement coverage, task atomicity, dependency ordering, file scope, verification commands, context fit, gap detection, Nyquist compliance. Max 3 revision iterations.

2. **Executor Self-Check**: After writing SUMMARY.md, the executor verifies its own claims — checks created files exist, checks commits exist. Appends `## Self-Check: PASSED` or `## Self-Check: FAILED`.

3. **Post-Execution Verifier** (`gsd-verifier`): 4-level verification plus Level 4 data-flow trace. Does NOT trust SUMMARY.md claims — independently verifies codebase state.

4. **UAT** (`gsd-verify-work`): Human acceptance testing with auto-diagnosis for failures.

5. **Nyquist Validation**: Maps automated test coverage to phase requirements before code is written, ensuring a feedback signal exists for every requirement.

6. **Cross-Phase Regression Gate**: Runs prior phases' test suites after execution to catch regressions.

7. **Requirements Coverage Gate**: Ensures every phase requirement appears in at least one plan before planning completes.

### Stub Detection

GSD includes extensive stub detection patterns in `get-shit-done/references/verification-patterns.md`:

- **Comment-based stubs**: Detects marker comments (e.g., `FIXME`, `XXX`, `HACK`, `PLACEHOLDER`) and phrases like "implement", "add later", "coming soon"
- **Empty implementations**: `return null`, `return {}`, `return []`, `=> {}`
- **Hardcoded values**: Hardcoded IDs, counts, display values where dynamic data is expected
- **React-specific**: `return <div>Component</div>`, empty handlers (`onClick={() => {}}`), `onSubmit` that only prevents default
- **API-specific**: Routes returning static empty arrays without DB queries, static responses ignoring query results
- **Wiring red flags**: Fetch calls without response handling, state variables not rendered, handlers only preventing default

### Verification Debt Tracking

The system prevents silent loss of UAT/verification items through:
- Cross-phase health checks on every `/gsd-progress` call
- `status: partial` distinguishing "session ended" from "all tests resolved"
- `result: blocked` with `blocked_by` tag for externally-blocked tests
- HUMAN-UAT.md persistence for human-needed verification items
- Phase completion warnings surfacing outstanding items

### Node Repair

When task verification fails during execution, the node repair operator chooses one of three strategies:
- **RETRY**: Attempt with a concrete adjustment (budget: 2 attempts per task by default).
- **DECOMPOSE**: Break task into smaller verifiable sub-steps.
- **PRUNE**: Remove unachievable tasks and escalate to user.

---

## 11. Security Mechanisms

### Defense-in-Depth

GSD implements security at multiple layers:

**Prompt Guard Hook** (`hooks/gsd-prompt-guard.js`): Scans `.planning/` file writes for 13 prompt injection patterns including role override (`ignore all previous instructions`), instruction bypass (`disregard previous`), system tag injection (`<system>`, `[SYSTEM]`, `[INST]`, `<<SYS>>`), and invisible Unicode detection. Advisory-only — logs for awareness.

**CLI Security Module** (`lib/security.cjs`): Path traversal prevention, prompt injection detection (superset of hook patterns), safe JSON parsing (prevents prototype pollution), and shell argument validation. Used by `gsd-tools.cjs` for all file operations.

**Session ID Sanitization**: The context monitor rejects session IDs containing path traversal sequences (`/../`) or path separators, preventing file path escape attacks.

**Security Enforcement** (v1.31): When `security_enforcement` is enabled (absent=enabled), every plan must include a `<threat_model>` section with trust boundary identification and STRIDE threat register. Each threat gets a disposition (mitigate/accept/transfer) with specific implementation references.

**Execution Scope Boundary**: The executor only auto-fixes issues directly caused by the current task's changes. Pre-existing warnings, linting errors, or failures in unrelated files are out of scope — logged to `deferred-items.md`, not fixed.

---

## 12. Context Engineering

### The Context Problem

AI coding agents degrade as their context window fills. GSD addresses this through multiple mechanisms:

**Fresh Context Windows**: Every agent starts with a clean context window. The planner gets a fresh 200K (or 1M) window for planning. Each executor gets its own fresh window. The verifier gets a fresh window. This eliminates the gradual degradation that occurs in long conversations.

**Context Budget Monitoring**: The context monitor hook tracks usage and injects agent-facing warnings at two thresholds:
- WARNING (≤35% remaining): "Avoid starting new complex work"
- CRITICAL (≤25% remaining): "Context nearly exhausted, inform user"

**Context Degradation Tiers**: Behavior adjusts based on usage:
- PEAK (0-30%): Full operations, body reads, multiple agents.
- GOOD (30-50%): Normal operations, prefer frontmatter reads.
- DEGRADING (50-70%): Economize, frontmatter-only, warn user.
- POOR (70%+): Emergency mode, checkpoint immediately.

**Read Depth Scaling**: At <500K tokens, agents read only frontmatter, status fields, or summaries. At ≥500K (1M models), full body reads are permitted. This is codified in `references/context-budget.md`.

**Context Propagation**: Artifacts feed into subsequent stages through a defined propagation chain:
```
PROJECT.md ────────► All agents
REQUIREMENTS.md ───► Planner, Verifier, Auditor
ROADMAP.md ────────► Orchestrators
STATE.md ──────────► All agents (decisions, blockers)
CONTEXT.md ────────► Researcher, Planner, Executor
RESEARCH.md ───────► Planner, Plan Checker
PLAN.md ───────────► Executor, Plan Checker
SUMMARY.md ────────► Verifier, State tracking
```

**Plan Sizing for Context**: Plans target completion within ~50% context to maintain quality — 2-3 tasks per plan. The quality degradation curve is documented:
- 0-30% context usage: PEAK quality — thorough, comprehensive.
- 30-50%: GOOD — confident, solid work.
- 50-70%: DEGRADING — efficiency mode begins.
- 70%+: POOR — rushed, minimal.

---

## 13. State Management

### File-Based Persistent Memory

All GSD state lives in `.planning/` as human-readable Markdown and JSON:

- **PROJECT.md**: Project vision, constraints, decisions, evolution rules. Living document.
- **REQUIREMENTS.md**: Scoped requirements with unique IDs (REQ-XX). Tracks v1 (must-have), v2 (future), and out-of-scope categories.
- **ROADMAP.md**: Phase breakdown with status tracking. Re-read after each phase to catch dynamic insertions.
- **STATE.md**: Living memory — current position, decisions, blockers, metrics, session info.
- **config.json**: Workflow configuration with ~20 toggleable settings.
- **Phase directories**: Each phase has its own directory with CONTEXT.md, RESEARCH.md, PLAN.md files, SUMMARY.md files, VERIFICATION.md, UAT.md.

### Anti-Pattern: Direct State Mutation

Rule #15 from `universal-anti-patterns.md`: "No direct Write/Edit to STATE.md or ROADMAP.md for mutations. Always use `gsd-tools.cjs` CLI commands." Direct Write bypasses safe update logic and is unsafe in multi-session environments where parallel agents might modify state simultaneously. The CLI tools handle locking, field validation, and consistent formatting.

### Session Continuity

GSD provides session management through:
- **Pause** (`/gsd-pause-work`): Saves position and next steps to `continue-here.md` and structured `HANDOFF.json`.
- **Resume** (`/gsd-resume-work`): Restores context from HANDOFF.json (preferred) or state files (fallback).
- **Progress** (`/gsd-progress`): Shows current position, next action, overall completion. Also surfaces verification debt from all prior phases.

HANDOFF.json includes blockers, human actions pending, and in-progress task state — ensuring nothing is lost across session boundaries.

---

## 14. Feature Evolution

GSD has evolved through 8 releases (v1.27–v1.32), accumulating 88 features across 14 categories. Key evolutionary milestones:

- **v1.27**: Fast mode (trivial inline tasks), cross-AI peer review, persistent context threads, security hardening (prompt guard, workflow guard).
- **v1.28**: Forensics debugging, milestone summary, workstream namespacing, manager dashboard.
- **v1.29**: Windsurf runtime support, internationalized documentation.
- **v1.30**: GSD SDK (programmatic execution API).
- **v1.31**: Schema drift detection, security enforcement (STRIDE threat models), documentation generation, discuss chain mode, scope reduction detection, claim provenance tagging.
- **v1.32**: STATE.md consistency gates, research gate, read-before-edit guard hook, context reduction, phase dependency analysis, anti-pattern severity levels, planner reachability check, Playwright-MCP UI verification, 3 new runtimes (Trae, Cline, Augment Code).

The evolution shows a clear trajectory: core pipeline first, then quality assurance (verification, plan checking), then security (prompt guard, threat models), then developer experience (SDK, new runtimes), then operational hardening (state consistency, context reduction, dependency analysis).
