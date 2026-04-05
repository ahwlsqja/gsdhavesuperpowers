# Reference Specification: Agent Contracts

**Name:** `agent-contracts`
**Scope:** Completion markers, handoff schemas, and inter-agent communication protocols for the unified 12-agent registry
**Loading Behavior:** On demand — loaded when agents need to produce or consume handoff artifacts
**Consumers:** Orchestrator agent (marker detection, routing), executor agent (SUMMARY.md production), verifier agent (SUMMARY.md consumption with distrust), planner agent (PLAN.md production)
**Research Grounding:** GSD's `agent-contracts.md` (21-agent registry); SYN-10 (formal agent contracts with honest interactions)

---

## Content Scope

This reference defines the communication contracts between agents in the unified methodology. It specifies what each agent produces, what format it uses, what completion markers signal state transitions, and what the receiving agent is required to verify independently versus accept at face value.

**What belongs here:** Completion marker formats, handoff artifact schemas, inter-agent data contracts, and the rules governing what is trusted versus independently verified across agent boundaries.

**What does NOT belong here:** Agent behavioral specifications (those are in individual agent specs), skill content (those are in skill specs), or verification methodology (that is in the `verification-before-completion` skill and verification pipeline).

---

## Unified 12-Agent Registry — Completion Markers

| # | Agent | Completion Markers | Notes |
|---|-------|--------------------|-------|
| 1 | `researcher` | `## RESEARCH COMPLETE`, `## RESEARCH BLOCKED` | Parameterized by focus area; all variants use same markers |
| 2 | `planner` | `## PLANNING COMPLETE` | Produces PLAN.md artifacts |
| 3 | `plan-checker` | `## PLAN CHECK COMPLETE` with verdict (PASS/REVISE/FAIL) | Issues structured feedback on REVISE |
| 4 | `executor` | `## PLAN COMPLETE` | Produces SUMMARY.md; may also emit `## CHECKPOINT REACHED` for pause |
| 5 | `verifier` | `## VERIFICATION COMPLETE` with verdict (PASSED/GAPS_FOUND/HUMAN_NEEDED) | Produces VERIFICATION.md with findings |
| 6 | `reviewer` | `## REVIEW COMPLETE` | Produces structured review with anti-sycophancy protocol |
| 7 | `debugger` | `## DEBUG COMPLETE`, `## ROOT CAUSE FOUND` | Interactive mode only; may also emit `## CHECKPOINT REACHED` |
| 8 | `mapper` | No marker — writes documentation artifacts directly | Output is project documentation files |
| 9 | `auditor` | `## AUDIT COMPLETE` with verdict, or `## ESCALATE` for critical findings | Parameterized by audit type (security/UI/integration/validation) |
| 10 | `doc-writer` | No marker — writes documentation directly | Output is generated/updated documentation files |
| 11 | `orchestrator` | Not a spawned agent — control loop | Does not produce completion markers |
| 12 | `profiler` | No marker — returns structured analysis | Background analysis, not pipeline participant |

### Marker Rules

1. **Standard format:** All markers are H2 headings (`## `) at the start of a line in the agent's final output
2. **ALL-CAPS convention:** Markers use ALL-CAPS by default (e.g., `## PLANNING COMPLETE`)
3. **Agents without markers** either write artifacts directly to disk or return structured data that the orchestrator parses from the output
4. **Verdict markers** (plan-checker, verifier, auditor) include structured metadata below the heading: verdict, score, issue counts, and recommendation

---

## Primary Handoff Schemas

### Planner → Executor (via PLAN.md)

The planner produces execution-ready plans consumed by the executor as task prompts.

| Field | Required | Description |
|-------|----------|-------------|
| Frontmatter | Yes | Milestone/slice/task IDs, dependencies, file scope, requirements covered |
| Tasks section | Yes | Ordered task list with file lists, specific actions, verification commands, acceptance criteria |
| Verification section | Yes | Overall verification steps for the plan as a whole |
| Success criteria | Yes | Measurable completion criteria traceable to requirements |

**Contract:** The executor treats PLAN.md as an executable prompt. Each task specifies exact files, specific actions, verification commands, and expected outputs. The executor follows tasks sequentially, applying deviation rules for unexpected situations.

### Executor → Verifier (via SUMMARY.md)

The executor produces a structured summary that the verifier treats as an unverified claim document.

| Field | Required | Description |
|-------|----------|-------------|
| Frontmatter | Yes | Task/slice/milestone IDs, key files, key decisions |
| One-liner | Yes | Single-sentence summary of accomplishment |
| Narrative | Yes | Detailed description of what happened |
| Verification section | Yes | What was verified — commands run, output observed, evidence |
| Deviations | Yes | How execution differed from the plan, or "None" |
| Self-Check | Yes | PASSED or FAILED with specific findings |

**What the verifier is required to ignore:** The executor's self-check verdict. SUMMARY.md may say "Self-Check: PASSED" — the verifier treats this as an unverified claim and runs its own independent checks against the codebase.

**What the verifier is required to verify independently:**
- Every file claimed as created or modified — verified via filesystem inspection
- Every verification command claimed as run — re-executed independently
- Every behavioral claim ("feature X works") — traced through actual code data flow
- Stub detection across all modified files — using the `verification-patterns` reference

### Verifier → Orchestrator (via VERIFICATION.md)

| Field | Required | Description |
|-------|----------|-------------|
| Status | Yes | `PASSED`, `GAPS_FOUND`, or `HUMAN_NEEDED` |
| Score | Yes | N/M must-haves verified |
| Findings | Yes | Structured list: file, line, category, severity, description |
| Recommendation | Yes | `PROCEED`, `RETRY`, `DECOMPOSE`, or `ESCALATE` |

**Contract:** The orchestrator uses the recommendation to invoke the appropriate repair operator. On RETRY, specific findings are forwarded to the executor. On DECOMPOSE, the orchestrator generates sub-tasks. On ESCALATE, the failure is recorded for human review.

---

## Four-Status Protocol

Agents operating as subagents (dispatched by the orchestrator or by another agent via the `subagent-driven-development` skill) report completion using a four-status protocol:

| Status | Meaning | Orchestrator Action |
|--------|---------|-------------------|
| `DONE` | Task completed successfully, all verification passed | Proceed to next task or wave |
| `DONE_WITH_CONCERNS` | Task completed but with noted concerns or partial coverage | Proceed with concerns logged; may trigger additional verification |
| `NEEDS_CONTEXT` | Agent cannot proceed without additional information | Orchestrator provides requested context or escalates to human |
| `BLOCKED` | Agent encountered an unresolvable issue | Orchestrator invokes repair operator (RETRY/DECOMPOSE/PRUNE) |

The four-status protocol applies in both interactive mode (subagents dispatched by the primary agent) and orchestrated mode (agents spawned by the orchestrator).

---

## Self-Check Section Format

Every SUMMARY.md includes a self-check section following this structure:

```markdown
## Self-Check

**Verdict:** PASSED | FAILED

### Files Verified
- [x] path/to/file.ts — exists, N lines
- [x] path/to/other.ts — exists, M lines

### Stub Scan
- Scanned N files for stub patterns
- Findings: 0 issues | N issues (listed below)

### Verification Commands
- `command1` — exit code 0, output confirms X
- `command2` — exit code 0, N tests passed
```

The self-check is the executor's own assessment. The verifier reads it to understand what the executor claims, then independently verifies each claim. The self-check is evidence of the executor's diligence, not proof of correctness.

---

## Usage Patterns

**When loaded:** On demand by agents that produce or consume handoff artifacts. The orchestrator loads it when parsing completion markers. The executor loads it when writing SUMMARY.md. The verifier loads it when interpreting SUMMARY.md structure.

**How agents use it:** As a schema reference — agents check this document to ensure their output conforms to the expected format and their input parsing handles all defined fields.

---

## Maintenance Rules

**When to update:** When a new agent is added to the registry, when an existing handoff schema gains or loses required fields, or when a new completion marker format is introduced.

**Who updates:** The orchestrator implementation drives marker format changes. Agent spec authors drive handoff schema changes. All changes must be reflected both here and in the corresponding agent specification.

**Consistency rule:** Every agent listed in this reference must have a corresponding agent specification in `design/agent-specs/`. Every completion marker format defined here must match the format defined in the agent's spec. Discrepancies between this reference and agent specs are treated as documentation bugs requiring immediate resolution.

---

## Cross-References

- `design/architecture-overview.md` — Agent Registry table (12 agents with modes and model tiers)
- `design/agent-specs/executor.md` — Executor self-check protocol and SUMMARY.md production
- `design/agent-specs/verifier.md` — Verifier distrust mindset and independent verification protocol
- `design/agent-specs/orchestrator.md` — Orchestrator marker detection and repair operator routing
- `design/agent-specs/plan-checker.md` — Plan-checker verdict format and revision loop
- `design/verification-pipeline.md` — Full dual-layer verification pipeline
- Reference: `verification-patterns` — Stub detection patterns used in self-check and verifier scans
- Reference: `repair-strategies` — Repair operator logic triggered by verifier recommendations
