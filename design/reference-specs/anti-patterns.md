# Reference Specification: Anti-Patterns

**Name:** `anti-patterns`
**Scope:** Universal anti-pattern catalog with severity levels — rules that apply to ALL agents and workflows
**Loading Behavior:** On demand — loaded when agents need to verify compliance or when the auditor runs validation checks
**Consumers:** All agents (universal rules), orchestrator agent (state management rules), executor agent (behavioral rules), auditor agent (compliance validation)
**Research Grounding:** GSD's `universal-anti-patterns.md` (27 rules across 7 categories); SYN-03 managed context; SYN-09 defense-in-depth security

---

## Content Scope

This reference catalogs operational anti-patterns — things agents must NOT do — organized by category with severity levels. Every rule represents a documented failure mode observed in real agent sessions, not a hypothetical concern. The catalog is universal: these rules apply regardless of agent role, execution mode, or state tier.

**What belongs here:** Prohibitions and constraints that apply across all agents. Operational "don't" rules with rationale and severity.

**What does NOT belong here:** Agent-specific behavioral protocols (those are in agent specs), verification methodology (that is in skills and the verification pipeline), or positive guidance about what agents SHOULD do (that is in skills).

---

## Category 1: Context Budget Violations

**Severity: Warning (waste) / Critical (exhaustion)**

These anti-patterns cause unnecessary context consumption, leading to degraded output quality or premature session termination.

| # | Anti-Pattern | Why It Fails | Severity |
|---|-------------|-------------|----------|
| 1 | Reading agent definition files into orchestrator context | Agent definitions are auto-loaded when agents are spawned via `subagent_type`. Reading them into the orchestrator wastes context for content that is automatically injected. | Warning |
| 2 | Inlining large files into subagent prompts | Agents have their own context windows. Passing file content through the orchestrator doubles the context cost. Tell agents to read files from disk. | Warning |
| 3 | Ignoring read-depth scaling rules | At < 500K tokens, reading full artifact bodies when frontmatter suffices wastes context on content that degrades the agent's ability to process task-critical information. | Critical |
| 4 | Orchestrator performing execution work | The orchestrator routes and coordinates — it does not build, analyze, research, investigate, or verify. Performing these tasks inline consumes orchestrator context that should be reserved for coordination. | Critical |
| 5 | Failing to warn about context pressure | When significant context has been consumed (large file reads, multiple subagent results), not warning the user risks silent quality degradation. | Warning |

## Category 2: File Reading Violations

**Severity: Warning (unnecessary reads) / Critical (stale data)**

| # | Anti-Pattern | Why It Fails | Severity |
|---|-------------|-------------|----------|
| 6 | Reading full SUMMARY.md when frontmatter suffices | At < 500K context windows, full body reads of prior summaries consume budget for content that frontmatter (status, key files, decisions) already captures. | Warning |
| 7 | Reading PLAN.md from other tasks/phases | Plans for other scopes contain irrelevant detail that pollutes the current task's context. Only current scope plans should be read. | Warning |
| 8 | Reading log files | Only health/monitoring workflows should read logs. Other agents processing log files waste context on operational noise. | Critical |
| 9 | Re-reading full files when frontmatter suffices | Frontmatter contains status, key files, commits, and provides fields. Full re-reads are only justified when semantic content is needed and context budget permits. | Warning |

## Category 3: Subagent Violations

**Severity: Critical**

| # | Anti-Pattern | Why It Fails | Severity |
|---|-------------|-------------|----------|
| 10 | Using non-methodology agent types | Generic agents (general-purpose, feature-dev, etc.) bypass project-aware prompts, audit logging, and workflow context. Always use methodology-defined agent types. | Critical |
| 11 | Re-litigating locked decisions | Decisions locked in project context represent user choices that are settled. Reopening them wastes context and risks contradicting user intent. | Critical |

## Category 4: Questioning Anti-Patterns

**Severity: Warning (inefficiency) / Critical (alienation)**

| # | Anti-Pattern | Why It Fails | Severity |
|---|-------------|-------------|----------|
| 12 | Checklist walking | Asking questions one-by-one from a list is the most common questioning anti-pattern. It produces shallow answers and exhausts user patience. Use progressive depth: start broad, dig where interesting. | Critical |
| 13 | Corporate jargon | Terms like "stakeholder alignment," "synergize," and "deliverables" create distance. Use plain language that matches how developers actually communicate. | Warning |
| 14 | Premature constraint application | Narrowing the solution space before understanding the problem prevents discovery. Ask about the problem first, constrain second. | Warning |

## Category 5: State Management Violations

**Severity: Critical**

| # | Anti-Pattern | Why It Fails | Severity |
|---|-------------|-------------|----------|
| 15 | Direct mutation of state files | Writing or editing STATE.md, ROADMAP.md, or other managed state files directly bypasses safe update logic and is unsafe in multi-session environments. Always use the provided CLI tools or state management APIs. | Critical |

## Category 6: Behavioral Violations

**Severity: Warning (bad practice) / Critical (scope breach)**

| # | Anti-Pattern | Why It Fails | Severity |
|---|-------------|-------------|----------|
| 16 | Creating unapproved artifacts | Creating planning documents, specs, or other artifacts the user did not request or approve wastes effort and may contradict user intent. | Warning |
| 17 | Modifying out-of-scope files | Changing files outside the plan's stated scope introduces untracked side effects. Check the plan's file list before modifying. | Critical |
| 18 | Suggesting multiple actions without priority | Presenting 3+ options without clear recommendation creates decision paralysis. Lead with one primary suggestion, list alternatives as secondary. | Warning |
| 19 | Using broad git staging | `git add .` or `git add -A` stages unintended files (logs, temp files, secrets). Stage specific files only. | Warning |
| 20 | Including sensitive data in artifacts | API keys, passwords, tokens, and other secrets must never appear in planning documents, commits, or agent output. | Critical |

## Category 7: Error Recovery Violations

**Severity: Warning (fragility) / Critical (data loss)**

| # | Anti-Pattern | Why It Fails | Severity |
|---|-------------|-------------|----------|
| 21 | Ignoring git lock files | Proceeding after "Unable to create lock file" errors risks concurrent state corruption. Check for stale `.git/index.lock` and advise removal. | Critical |
| 22 | Silent config fallback | Config loading that returns null on invalid JSON without warning produces mysterious downstream failures. Validate and warn explicitly. | Warning |
| 23 | Proceeding past state mismatches | When state references (e.g., a phase directory that does not exist) are broken, proceeding silently compounds the mismatch. Stop and diagnose. | Critical |

## Category 8: Methodology-Specific Rules

**Severity: Critical (operational correctness)**

| # | Anti-Pattern | Why It Fails | Severity |
|---|-------------|-------------|----------|
| 24 | Using wrong mode detection flag | The methodology uses a `yolo` config flag for autonomous mode, not `mode === 'auto'` or `mode === 'autonomous'`. Wrong flag checks cause incorrect mode behavior. | Critical |
| 25 | Using wrong tool entry point | The methodology uses CommonJS entry points for Node.js CLI compatibility. Using alternative file extensions or module formats causes import failures. | Critical |
| 26 | Using wrong plan file naming | Plan files must follow the defined naming convention. Variant naming patterns break automated detection and state tracking. | Critical |
| 27 | Executing next task before writing summary | Downstream tasks may reference the current task's SUMMARY.md via includes. Skipping summary writing before proceeding breaks the dependency chain. | Critical |

---

## Usage Patterns

**When loaded:** On demand when agents need to verify their own compliance or when the auditor agent runs a validation sweep. The orchestrator may load this reference when assembling context for agents working in areas with high anti-pattern risk (state management, error recovery).

**How agents use it:** As a negative checklist — agents scan their planned actions against these rules before executing. The auditor agent uses this catalog as the basis for compliance validation.

---

## Maintenance Rules

**When to update:** When a new anti-pattern is observed in real agent sessions that causes measurable harm (context waste, state corruption, user frustration). New entries must include a documented failure case, not theoretical concerns.

**Who updates:** Any agent or developer who observes a repeating failure pattern may propose a new entry. Entries are added through the knowledge management process: observe failure → document pattern → add to catalog → verify against false positives.

**Severity review:** Severity levels should be reviewed periodically. Warning-level patterns that repeatedly cause critical failures should be upgraded. Critical-level patterns that produce excessive false positives should be downgraded or refined.

---

## Cross-References

- `design/architecture-overview.md` — Component Map and execution modes
- `design/agent-specs/orchestrator.md` — State management rules (Category 5) enforcement
- `design/agent-specs/executor.md` — Behavioral rules (Category 6) compliance
- `design/agent-specs/auditor.md` — Compliance validation using this catalog
- Reference: `context-budget` — Detailed degradation tiers referenced by Category 1 rules
- Skill: `context-management` — Behavioral enforcement of context budget awareness
