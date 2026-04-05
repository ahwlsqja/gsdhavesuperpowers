# Verification Pipeline Specification

**Date:** 2026-04-05
**Parent:** `design/architecture-overview.md` (Section: Pipeline Stages → Stage 5: Verify)
**Research Grounding:** SYN-01 (P0 dual-layer verification synergy), Principle 3 (verification is dual-layered and non-negotiable), SASE speed-vs-trust gap (Hassan et al., 2025)
**Downstream Consumers:** S02 (`verification-before-completion` skill spec), S03 (`verifier` agent spec, `verification-patterns` reference spec, `repair-strategies` reference spec)

---

## Overview

### The Problem: Why One Layer Is Not Enough

AI coding agents fail at verification in two fundamentally different ways, and no single verification mechanism catches both.

**Failure Mode 1 — The agent does not run verification.** The agent writes code, believes it works based on its reasoning, and claims completion without executing a single test command. This is the most common failure mode. The agent is not malicious — it genuinely believes the code is correct based on its understanding. But belief is not evidence. Superpowers' research across 24 documented failure cases established this pattern as the dominant quality failure: agents skip verification not because they are incapable of running it, but because they are confident enough to rationalize skipping it.

**Failure Mode 2 — The agent runs verification but misses structural problems.** The agent diligently runs tests, reads output, and confirms all tests pass — but the code contains empty event handlers, hardcoded values where dynamic data belongs, stub implementations behind real-looking function signatures, or components that render filler markup. The agent cannot catch what it does not recognize as a problem. Programmatic inspection is required to detect patterns the agent's reasoning cannot self-identify.

These two failure modes require two different solutions:

- **Behavioral verification** (Layer 1) addresses Failure Mode 1 by making verification execution a non-negotiable behavioral constraint with enforcement phrased in terms of honesty, not productivity. An agent that skips verification is *lying about what it knows*, not merely cutting corners.

- **Programmatic verification** (Layer 2) addresses Failure Mode 2 by running independent codebase inspection that does not depend on the agent's self-assessment. The programmatic layer checks what the behavioral layer cannot — structural completeness that passes human-looking review but fails machine analysis.

Neither layer is optional. Neither layer is a fallback for the other. Both run on every verification pass.

### The "Lying, Not Verifying" Framing

The behavioral layer's effectiveness depends on a specific psychological framing derived from Superpowers' verification-before-completion skill. The framing is:

> **Skip any step = lying, not verifying.**

This single sentence is the most important behavioral lever in the entire verification pipeline. It works because:

1. **AI agents have strong alignment with honesty values.** Framing verification skipping as "dishonest" rather than "suboptimal" activates a deeper behavioral constraint than appeals to productivity or quality.
2. **It reframes the default.** Without this framing, the agent's default is "I'll verify if I have time / if it seems risky / if I'm not confident." With this framing, the default becomes "I must verify or I am lying about my confidence."
3. **It is unfalsifiable by the agent.** An agent can rationalize "this is simple enough to skip verification" but cannot rationalize "it's okay to lie about verification."

### SASE's Speed-vs-Trust Gap

The academic foundation for dual-layer verification comes from SASE (Structured Agentic Software Engineering, Hassan et al., 2025), which identifies a fundamental tension: **AI agents increase development speed but decrease trust in the output. The gap between what is produced and what is trustworthy widens as agent autonomy increases.**

Key implications for the verification pipeline:

- **Higher autonomy requires heavier verification, not lighter.** When a human is closely supervising (interactive mode), the trust gap is smaller — the human provides an implicit verification layer. When an agent operates autonomously (orchestrated mode), the trust gap widens and must be closed by stronger automated verification.
- **Verification must be structural, not optional.** Every paper in the academic review (SASE, LLMs Reshaping SE, Codified Context Infrastructure) converges on this: verification cannot rely on agent discipline alone. It must be architecturally enforced.
- **The gap is narrowed from two directions.** Behavioral verification narrows the gap from the agent side (ensuring it actually runs verification). Programmatic verification narrows it from the codebase side (ensuring the output is structurally sound). Both directions are necessary.

---

## Layer 1 — Behavioral Verification (Gate Function)

### Purpose

Layer 1 ensures the agent **actually performs verification** before making any completion claim. It addresses the agent's tendency to skip verification when confident, to run partial verification and extrapolate, or to claim verification was performed without having done so.

### The Unified Gate Sequence

The unified methodology reconciles two verification vocabularies into a single behavioral gate sequence:

| Unified Step | GSD Origin | Superpowers Origin | What Happens |
|---|---|---|---|
| **1. IDENTIFY** | Exists level (does the artifact exist?) | IDENTIFY (what command proves this claim?) | The agent names the *specific command or check* that would prove the completion claim. Not "run tests" — the exact command, with arguments. If the agent cannot name the command, the claim is unverifiable and must be reformulated. |
| **2. EXECUTE** | Wired level (is it connected?) | RUN (execute the FULL command) | The agent runs the *complete* verification command. Not a subset. Not a cached result. Not a prior run's output. A fresh, full execution in the current codebase state. |
| **3. INSPECT** | Substantive level (is it real, not a stub?) | READ (full output, check exit code, count failures) | The agent reads the *complete* output — exit code, stdout, stderr, failure count, warning count. No truncation. No scanning for "PASS" while ignoring failure details. The agent must process the full output before forming a judgment. |
| **4. JUDGE** | Functional level (does it work end-to-end?) | VERIFY (does output confirm the claim?) | The agent compares the actual output against the specific claim being verified. Not "tests passed" if the claim was "the search feature works." The judgment must be *claim-specific*, not generic. |
| **5. CLAIM** | Completion marker in SUMMARY.md | ONLY THEN: make the claim | Only after steps 1–4 have been performed and the judgment is affirmative may the agent make the completion claim. The claim must reference the evidence (command run, output observed). |

**Reconciliation rationale:** GSD's 4-level model (Exists → Substantive → Wired → Functional) describes *what to check* at ascending levels of rigor. Superpowers' 5-step gate (IDENTIFY → RUN → READ → VERIFY → CLAIM) describes *the behavioral sequence for performing a check*. These are complementary, not competing. The unified sequence uses Superpowers' behavioral steps as the execution protocol and GSD's artifact levels as the rigor framework applied within step 4 (JUDGE). The artifact verification levels are detailed in Layer 2.

### The Iron Law of Verification

> **No completion claim without fresh verification evidence. Violating the letter of this rule is violating the spirit of this rule.**

This iron law applies universally:
- In both interactive and orchestrated modes
- At all state tiers (Tier 0, Tier 1, Tier 2)
- For all artifact types (code, documents, configuration, tests)
- Regardless of agent confidence level
- Regardless of perceived task simplicity

"Fresh" means: generated during this execution pass, not carried over from a prior session, prior task, or prior attempt. Stale evidence is not evidence.

### Rationalization Prevention Table

The following table enumerates known evasion patterns observed in real agent sessions, with corrections. Each row represents a documented failure mode, not a hypothetical concern. This table is a behavioral lookup — when the agent recognizes its own reasoning in the left column, it must apply the correction in the right column.

| Rationalization | Reality | Why It Fails |
|---|---|---|
| "Tests should pass based on my changes" | Run the tests. "Should" is not evidence. | Agents frequently misjudge side effects, import chains, and runtime behavior that differs from static reasoning. |
| "I'm confident this works" | Confidence is not verification. Execute the gate sequence. | Confidence correlates with familiarity, not correctness. Novel code with no prior patterns produces high confidence and high failure rates simultaneously. |
| "The change is too simple to need verification" | Simple changes have simple verifications. Run them. | "Simple" changes account for a disproportionate share of production incidents because they bypass review and verification. |
| "I already verified a similar change earlier" | Each change gets its own verification. Prior evidence is stale. | Code changes interact. A verification that passed before a subsequent edit may fail after it. |
| "The tests are slow and I already know the result" | Slow tests exist for a reason. Run them fully. | Skipping slow tests means skipping the most thorough checks. Speed of verification does not determine its necessity. |
| "I'll verify at the end after all changes are done" | Verify after each logical unit. Deferred verification compounds risk. | Deferred verification turns debugging into archaeology — when multiple changes are interleaved, isolating which change broke what becomes exponentially harder. |
| "Different words so the rule doesn't apply" | The spirit of verification applies regardless of how the task is framed. | Rephrasing "completion" as "ready for review" or "initial implementation" does not exempt work from verification. |
| "The build passed so everything works" | Build success ≠ functional correctness. Run the functional checks. | Builds verify compilation and static analysis. They do not verify runtime behavior, data flow, or user-facing correctness. |

### Red-Flag Language Patterns

The agent must monitor its own output for language that signals an unverified claim is about to be made:

- **"Should"** — "This should work" → Stop. Run the gate sequence.
- **"Probably"** — "This probably handles the edge case" → Stop. Write a test for the edge case.
- **"Seems to"** — "The output seems correct" → Stop. Define what "correct" means quantitatively and verify.
- **"I believe"** — "I believe this is complete" → Stop. What specific evidence supports the belief?
- **"Based on my understanding"** — This phrase is a confession that no verification has been performed.

---

## Layer 2 — Programmatic Verification (Independent Checking)

### Purpose

Layer 2 inspects the codebase independently of the agent's self-assessment. It catches structural problems the agent cannot self-identify: stub implementations hidden behind real-looking interfaces, empty handlers that pass type checking but do nothing, hardcoded values where dynamic data should flow, and wiring gaps where components exist in isolation but are not connected.

### The 4-Level Artifact Verification Model

Programmatic verification applies four ascending levels of rigor. Each level subsumes the checks from all prior levels.

**Level 1 — Exists**
- Does the claimed artifact exist on disk at the expected path?
- Is the file non-empty (more than trivial boilerplate)?
- Does it have the expected file extension and basic structure?

This level catches the most basic failure: claiming to have created a file that does not exist. It also catches zero-byte files and files containing only import statements with no actual implementation.

**Level 2 — Substantive**
- Does the artifact contain real implementation, not stubs?
- Are there actual function bodies, not just signatures?
- Is the content beyond boilerplate scaffolding?

This is the stub detection level — the most critical programmatic check. The agent may sincerely believe it has implemented a feature when it has actually produced a well-structured skeleton with no functional content.

**Level 3 — Wired**
- Is the artifact connected to the rest of the system?
- Are imports used, not just declared?
- Are exports consumed by other modules?
- Are event handlers attached to actual events?
- Are API endpoints registered in the router?

This level catches "island" artifacts — code that exists and is substantive but is not integrated into the application. A fully implemented component that is never rendered, an API handler that is never routed, a utility function that is never called.

**Level 4 — Functional**
- Does the artifact work end-to-end with real data?
- Do data flows complete from source to destination?
- Do user-facing features produce the expected behavior?
- Are error paths handled, not just happy paths?

This level requires runtime verification — actually executing the code and observing its behavior. It catches everything the prior levels miss: correct-looking code that fails at runtime due to type mismatches, missing environment variables, incorrect API contracts, or logic errors.

### Stub Detection Patterns

Programmatic verification scans for five categories of stub patterns. Per K001, pattern examples below use descriptive names rather than literal marker strings to avoid false positives in analytical documents.

**Category 1 — Comment-Based Markers**
Detects marker comments that signal incomplete implementation:
- Deferred-work markers (e.g., repair-needed flags, attention-needed flags, workaround flags) that indicate known incomplete areas
- Deferral phrases in comments: "implement later", "arriving soon", "add logic here", "needs implementation"
- Empty documentation blocks with only filler descriptions

**Category 2 — Empty Implementations**
Detects function bodies that compile but do nothing:
- Functions returning `null`, `undefined`, empty objects `{}`, or empty arrays `[]`
- Arrow functions with empty bodies: `() => {}`
- Functions consisting only of a `console.log` or `print` statement
- Methods that only call `super()` without adding behavior
- Error handlers that silently swallow: `catch(e) {}`

**Category 3 — Hardcoded Values**
Detects static data where dynamic behavior is expected:
- Hardcoded user IDs, counts, or display values in business logic
- Static arrays returned by functions that should query a data source
- Configuration values embedded in source code rather than loaded from configuration
- Date/time values that are literals rather than computed

**Category 4 — Framework-Specific Patterns**
Detects patterns specific to common frameworks that indicate incomplete implementation:
- React: components returning minimal markup like `<div>ComponentName</div>`, empty event handlers (`onClick={() => {}}`), `onSubmit` handlers that only call `preventDefault()` without processing
- API routes: endpoints returning empty arrays or static JSON without data source queries, routes that ignore request parameters
- Database: models defined without migration files, schemas without seed data when seeding is required

**Category 5 — Wiring Red Flags**
Detects connection failures between system components:
- API fetch calls that discard or ignore the response
- State variables that are set but never rendered or used in conditions
- Event handlers that only prevent default behavior without executing business logic
- Imports declared but never referenced in the module body
- Environment variable references without corresponding configuration entries

### Independence From Agent Self-Assessment

The critical design property of Layer 2 is that it operates independently of the agent's judgment. The programmatic checks:

1. **Do not read SUMMARY.md.** They inspect the codebase directly.
2. **Do not accept "this is intentional" as an override.** If a stub pattern is detected, it is reported regardless of context.
3. **Are not run by the agent that wrote the code** (in orchestrated mode). The verifier agent runs them, and the verifier has a distrust mindset toward the executor's claims.
4. **Produce machine-readable output.** Detection results are structured (file, line, pattern category, severity) rather than prose — enabling automated processing and trend analysis.

False positives are handled through an explicit allowlist mechanism: a file may contain a `// verification:allow <category> <reason>` annotation that the stub detector recognizes. These allowlist entries are themselves subject to review — they must be justified and are flagged for periodic audit.

---

## Interactive Mode Verification

### How Verification Works With a Single Agent

In interactive mode, a single agent performs both execution and verification. This creates a self-assessment problem: the agent checking its own work is subject to the same blind spots that produced the work. The dual-layer architecture mitigates this through complementary mechanisms.

### Behavioral Layer in Interactive Mode

The agent follows the 5-step unified gate sequence (IDENTIFY → EXECUTE → INSPECT → JUDGE → CLAIM) for every completion claim. The gate function is loaded as the `verification-before-completion` skill, which the meta-skill (`using-methodology`) requires before any completion claim.

The behavioral layer's effectiveness in interactive mode rests on three reinforcements:

1. **The iron law** is loaded in the hot tier (always present in context) and cannot be deprioritized by other concerns.
2. **The rationalization prevention table** is loaded alongside the iron law and intercepts the specific thoughts that precede verification skipping.
3. **A human developer is typically present** in interactive sessions, providing an implicit third verification layer through review and follow-up questions.

### Programmatic Layer in Interactive Mode

After the agent completes the behavioral gate sequence and makes a completion claim, the programmatic verification layer runs as a second pass:

1. The stub detector scans all files modified during the task for patterns in all five stub categories.
2. The 4-level artifact checker verifies each claimed output against Exists → Substantive → Wired → Functional criteria.
3. Results are reported to the agent (and the developer, if present).

In interactive mode, the programmatic layer runs as an infrastructure service invoked by the agent — the agent is expected to run it as part of the gate sequence. The `verification-before-completion` skill explicitly directs the agent to invoke programmatic checks after passing the behavioral gate.

### Conflict Resolution: Behavioral Claim vs. Programmatic Finding

When the behavioral gate passes (the agent claims completion with evidence) but the programmatic layer finds issues, the resolution rule is:

> **Programmatic findings override behavioral claims.**

The agent may have honestly run tests and read output, but the stub detector found an empty handler the agent did not recognize as incomplete. In this case:

1. The programmatic finding is reported to the agent with specific file, line, and pattern category.
2. The agent must address each finding — either fix the issue or provide an explicit justification annotated with `// verification:allow`.
3. The verification cycle restarts: fix → behavioral gate → programmatic check → resolve conflicts.
4. The cycle terminates when both layers agree (no remaining conflicts) or when the developer explicitly accepts a known limitation.

The inverse case (behavioral gate fails but programmatic checks would pass) does not arise in interactive mode — if the agent fails the behavioral gate, it does not proceed to the programmatic layer.

---

## Orchestrated Mode Verification

### How Verification Works With Multiple Agents

In orchestrated mode, execution and verification are performed by structurally independent agents. The executor agent writes code and produces a SUMMARY.md. The verifier agent receives the SUMMARY.md and the codebase, and independently verifies the executor's claims. This structural independence is the orchestrated mode's primary advantage for verification — it eliminates the self-assessment problem entirely.

### The Verifier Agent's Distrust Mindset

The verifier agent operates under a principle of constructive distrust:

> **The verifier does NOT trust SUMMARY.md. Task completion ≠ goal achievement.**

This means:

1. **The verifier ignores the executor's self-check results.** SUMMARY.md may say "Self-Check: PASSED" — the verifier treats this as an unverified claim and runs its own checks.
2. **The verifier assumes stubs until proven otherwise.** For every artifact the executor claims to have created, the verifier assumes it is a stub until the 4-level check demonstrates otherwise.
3. **The verifier traces data flow independently.** If the executor claims "the search feature works," the verifier traces the data flow from user input through API call through database query through response rendering — not by reading the executor's description, but by inspecting the actual code.
4. **The verifier uses a capable model tier.** Verification requires high reasoning quality to catch subtle issues. The verifier is assigned to the Capable model tier, not Budget or Standard.

### Verification Execution in Orchestrated Mode

The verifier agent executes both verification layers in sequence:

**Step 1 — Behavioral Gate (on the verifier's own assessment)**
The verifier applies the unified gate sequence to its own verification process:
- IDENTIFY: What checks will prove this executor's claims?
- EXECUTE: Run those checks against the actual codebase.
- INSPECT: Read complete output from all verification commands.
- JUDGE: Do the results confirm the executor's claims?
- CLAIM: Only then report verification status.

The verifier is subject to the same iron law as the executor — the verifier cannot claim "verification passed" without running the gate sequence on its own assessment.

**Step 2 — Programmatic Checks (independent of both agents)**
The verifier runs the programmatic verification layer:
- Stub detector across all files modified by the executor
- 4-level artifact checker against each claimed output
- Data-flow trace for critical paths identified in the task plan

**Step 3 — Verdict Generation**
The verifier produces a structured verification result:
- **Status:** `passed` | `gaps_found` | `human_needed`
- **Score:** N/M must-haves verified (where M is derived from the task plan's verification criteria)
- **Findings:** Structured list of issues (file, line, category, severity, description)
- **Recommendation:** `proceed` | `retry` | `decompose` | `escalate`

### Node Repair Operator Integration

When the verifier's verdict is not `passed`, the orchestrator invokes the node repair operator:

**RETRY with Adjustment** (budget: 2 attempts per task)
- The executor receives the verifier's specific findings (not just "failed").
- The executor addresses each finding and re-runs the task.
- The verifier re-verifies the updated output independently.
- If the second retry also fails, the orchestrator escalates to DECOMPOSE.

**DECOMPOSE into Smaller Steps**
- The orchestrator breaks the failed task into 2–4 smaller, independently verifiable sub-tasks.
- Each sub-task targets a specific verification finding.
- Sub-tasks are planned and executed through the full pipeline (plan → execute → verify).
- DECOMPOSE is used when the failure indicates the task was too complex for atomic execution, not when the executor made a simple mistake.

**PRUNE and Escalate**
- If RETRY and DECOMPOSE both fail, the task is marked as unachievable in the current context.
- The orchestrator escalates to the user (interactive fallback) or records the failure for human review.
- PRUNE is the option of last resort — it means the automated pipeline cannot solve this problem.

### Systematic Debugging Integration

When verification fails and RETRY is selected, the retry must follow the systematic debugging iron law:

> **No fixes without root cause investigation first.**

This prevents the "guess-and-check thrashing" failure mode where the executor makes random changes hoping to pass verification. The retry sequence is:

1. **Investigate:** Read the verifier's findings. Understand *why* the issue exists.
2. **Hypothesize:** Form a specific theory about the root cause.
3. **Test the hypothesis:** Make a targeted change that addresses the root cause.
4. **Verify the fix:** Run the gate sequence on the specific fix.

Red flags that indicate the executor is thrashing rather than debugging:
- "Just try changing X and see if it works" → Return to investigation.
- "One more fix attempt" when already tried 2+ → Escalate to DECOMPOSE.
- Making multiple changes simultaneously → Revert and change one thing at a time.

---

## Verification Levels by Artifact Type

Not every artifact requires the full 4-level verification. The following table defines the minimum verification level required by artifact type, with rationale for each assignment.

| Artifact Type | Minimum Level | Gate Sequence Required | Rationale |
|---|---|---|---|
| **Source code (new feature)** | Level 4 (Functional) | Full 5-step | New features must work end-to-end. All four levels apply: the file exists (L1), contains real implementation (L2), is wired to the system (L3), and functions correctly with real data (L4). |
| **Source code (bug fix)** | Level 4 (Functional) | Full 5-step | Bug fixes must demonstrate the original symptom is resolved and no regressions are introduced. The specific failure case must be verified, not just "tests pass." |
| **Source code (refactor)** | Level 3 (Wired) + regression | Full 5-step | Refactors should not change behavior. Verify existing tests still pass (regression) and the refactored code is still wired to its consumers (L3). Functional verification (L4) is implicit through passing existing tests. |
| **Test files** | Level 2 (Substantive) + execution | Full 5-step | Tests must exist (L1), contain real assertions not just scaffolding (L2), and actually execute (run the test command). Wiring (L3) is implicit — tests wire to the code under test. |
| **Design documents** | Level 2 (Substantive) | 3-step (IDENTIFY → INSPECT → CLAIM) | Design documents must exist (L1) and contain substantive content meeting word count and section requirements (L2). They do not need wiring (L3) or functional (L4) checks. The gate sequence is abbreviated — EXECUTE is replaced by INSPECT because there is no command to "run" a design document. |
| **Configuration files** | Level 3 (Wired) | Full 5-step | Configuration must exist (L1), contain valid values (L2), and be referenced by the application (L3). For critical configuration (database, auth), Level 4 functional verification is recommended. |
| **Migration/schema files** | Level 4 (Functional) | Full 5-step | Migrations must be runnable. Verify by executing the migration against a test database and confirming schema changes. Schema-only verification (L2) is insufficient — migrations that parse correctly but fail at runtime are common. |
| **Documentation (README, guides)** | Level 1 (Exists) + review | 3-step (IDENTIFY → INSPECT → CLAIM) | Documentation must exist and be non-trivial. Content review is human-facing and best handled by the reviewer agent, not programmatic verification. |
| **Infrastructure (CI/CD, Dockerfile)** | Level 3 (Wired) | Full 5-step | Infrastructure files must be valid, referenced by the build system, and produce the intended artifacts. Full functional verification (L4) typically requires a CI run and may be deferred to the CI pipeline. |

### Graduated Verification Budget

Verification cost scales with the trust gap. Higher-autonomy execution gets heavier verification:

| Execution Context | Verification Budget | Rationale |
|---|---|---|
| Human-guided task (interactive, developer present) | Standard: behavioral gate + spot-check programmatic | The developer provides implicit verification through review. |
| Agent-executed task (interactive, autonomous) | Enhanced: behavioral gate + full programmatic sweep | No human in the loop. The programmatic layer must compensate for absent human review. |
| Orchestrated auto-mode task | Maximum: independent verifier + behavioral gate + full programmatic sweep + data-flow trace | Maximum trust gap. The full dual-layer pipeline with independent verifier is required. |

---

## Failure Recovery

### When Verification Fails

Verification failure is not exceptional — it is an expected part of the development workflow. The methodology treats verification failure as a signal that work needs adjustment, not as a deficiency of the agent. The recovery protocol is designed to resolve failures efficiently while preventing the "guess-and-check thrashing" pattern that wastes context budget.

### The Repair Operator

The repair operator selects a recovery strategy based on the failure type:

| Failure Signal | Recovery Strategy | Budget | Trigger for Escalation |
|---|---|---|---|
| Single finding, clear fix | **RETRY** with targeted adjustment | 2 attempts per task | Third failure on same finding → DECOMPOSE |
| Multiple findings, interconnected | **DECOMPOSE** into smaller verifiable units | 2–4 sub-tasks | Any sub-task fails after its own RETRY budget → PRUNE |
| Fundamental approach mismatch | **PRUNE** and escalate | N/A | Immediate escalation |
| Environmental or tooling issue | **RETRY** after environment fix | 1 attempt | Environment still broken → PRUNE |

### RETRY Protocol

1. The agent (executor in orchestrated mode, primary agent in interactive mode) receives the specific verification findings.
2. The agent applies the systematic debugging iron law: investigate root cause before fixing.
3. The agent makes a targeted fix addressing one finding at a time.
4. The full verification pipeline re-runs (both layers).
5. If the fix resolves the finding, proceed to the next finding.
6. If the fix fails, the agent has consumed one retry attempt.
7. After exhausting the retry budget (2 attempts), escalate to DECOMPOSE.

### DECOMPOSE Protocol

1. The orchestrator (or primary agent in interactive mode) analyzes the verification failures to identify natural decomposition boundaries.
2. The failed task is split into 2–4 sub-tasks, each targeting a specific aspect of the original task that can be independently verified.
3. Each sub-task goes through the full pipeline: plan → execute → verify.
4. Sub-tasks inherit the parent task's verification criteria, scoped to their specific aspect.
5. Each sub-task has its own RETRY budget (2 attempts).

### PRUNE Protocol

1. The task is marked as unachievable in the current automated pipeline.
2. A detailed failure report is generated, including:
   - All verification findings across all attempts
   - Root cause analysis from each RETRY attempt
   - Decomposition rationale and sub-task failure details
3. In interactive mode: the failure report is presented to the developer for manual resolution.
4. In orchestrated mode: the failure report is recorded in the slice state and the orchestrator continues with remaining tasks, noting the dependency gap.

### Escalation Thresholds

The total verification budget per task (including retries and decomposition) is bounded to prevent infinite loops:

- **Maximum total attempts per original task:** 2 (RETRY) + 4 × 2 (DECOMPOSE sub-tasks with their own RETRY) = 10 verification cycles
- **Maximum wall-clock time:** The context-management skill tracks verification cycles against the context budget. If verification is consuming more than 40% of the remaining context window, force PRUNE regardless of retry budget.
- **Cross-task escalation:** If 3+ tasks in the same slice hit DECOMPOSE, the orchestrator pauses execution and escalates the entire slice for reassessment — the plan may be fundamentally wrong.

---

## Cross-Reference to Skills and Agents

This section maps the verification pipeline to the specific components that implement it, providing the contract that S02 (skill specifications) and S03 (agent and reference specifications) will build from.

### Skills Required

| Skill | Role in Verification Pipeline | Key Content to Specify (for S02) |
|---|---|---|
| `verification-before-completion` | Primary skill implementing Layer 1. Contains the iron law, unified gate sequence, rationalization prevention table, and red-flag language patterns. | The full gate sequence with step definitions, the complete rationalization prevention table (8 rows minimum), red-flag language patterns, the iron law text, conflict resolution protocol (behavioral claim vs. programmatic finding). Must be a rigid skill (follow exactly, no adaptation). |
| `systematic-debugging` | Invoked during RETRY when verification fails. Provides the root-cause-first investigation protocol that prevents guess-and-check thrashing. | The debugging iron law, 12 red flags, 8-row excuse/reality table, Phase 1 (investigate) → Phase 2 (hypothesize) → Phase 3 (fix) → Phase 4 (verify) sequence. Interaction with verification pipeline: the debugging skill is activated when RETRY is selected. |
| `executing-plans` | Loads verification-before-completion as a dependency. Ensures verification is invoked during plan execution, not just at final completion. | Must explicitly invoke the verification gate after each task step, not just at task end. The task-level granularity of verification is specified here. |
| `context-management` | Monitors context budget consumption during verification cycles. Triggers forced PRUNE when verification consumes excessive context. | Context-budget thresholds for verification: warning at 30% consumed by verification, critical at 40%. Escalation rules when verification is budget-dominant. |

### Agents Required

| Agent | Role in Verification Pipeline | Key Content to Specify (for S03) |
|---|---|---|
| `verifier` | Implements independent verification in orchestrated mode. Runs both Layer 1 (behavioral gate on own assessment) and Layer 2 (programmatic checks). Produces structured verification verdicts. | Distrust mindset (does not trust SUMMARY.md), 4-level verification with data-flow trace at Level 4, verdict generation (status, score, findings, recommendation), interaction with repair operator (provides findings to executor on RETRY, flags DECOMPOSE-worthy failures). Model tier: Capable. |
| `executor` | Subject of verification. Runs self-verification in interactive mode (Layer 1) and invokes programmatic checks (Layer 2). In orchestrated mode, produces artifacts for the verifier to check. | Self-check protocol (verify own claims before writing SUMMARY.md), deviation reporting (what was planned vs. what was done), integration with verification-before-completion skill. |
| `orchestrator` | Coordinates the repair operator. Decides RETRY vs. DECOMPOSE vs. PRUNE based on verifier findings. Manages retry budgets and escalation thresholds. | Repair operator decision logic, retry budget tracking per task, cross-task escalation rules (3+ DECOMPOSE triggers in same slice → pause), DECOMPOSE task generation protocol. |

### Reference Documents Required

| Reference | Role in Verification Pipeline | Key Content to Specify (for S03) |
|---|---|---|
| `verification-patterns` | Provides the stub detection signatures used by the programmatic layer (Layer 2). Loaded proactively — the only reference loaded into every task context. | Five stub categories with pattern signatures (comment-based, empty implementations, hardcoded values, framework-specific, wiring red flags). Each category: regex patterns, example violations, severity levels, allowlist annotation syntax. |
| `repair-strategies` | Provides the repair operator logic used by the orchestrator when verification fails. | RETRY/DECOMPOSE/PRUNE decision criteria, retry budget rules, decomposition heuristics, PRUNE escalation protocol, cross-task escalation thresholds. |
| `agent-contracts` | Defines the handoff schema between executor and verifier (Executor→Verifier via SUMMARY.md). | SUMMARY.md required fields for verifier consumption, completion marker format, self-check section format, what the verifier is required to ignore vs. verify independently. |

### Infrastructure Services Required

| Service | Role in Verification Pipeline |
|---|---|
| **Stub Detector** | Programmatic scanner implementing the five stub categories from the `verification-patterns` reference. Runs independently of agent self-assessment. Produces structured output (file, line, category, severity). |
| **Context Monitor** | Tracks context budget consumption during verification cycles. Triggers escalation signals when verification is consuming excessive budget. |

---

## Design Constraints Summary

1. **Both verification layers are non-negotiable.** Neither layer can be disabled, made optional, or configured away. The methodology structurally requires both layers for every verification pass.

2. **The "lying, not verifying" framing is preserved.** This framing is not stylistic — it is a specific behavioral lever that activates the agent's alignment with honesty values. Any rewrite of the verification skill must preserve this framing.

3. **The unified vocabulary reconciles without loss.** GSD's 4-level model is used for artifact rigor (what to check). Superpowers' 5-step gate is used for behavioral sequence (how to check). Neither system's insights are discarded.

4. **Programmatic findings override behavioral claims.** When the agent claims completion but the stub detector finds issues, the programmatic finding takes precedence. The agent cannot override programmatic verification through behavioral self-assessment.

5. **Verification scales with autonomy.** Higher autonomy (orchestrated mode, fully autonomous tasks) receives heavier verification. Lower autonomy (interactive mode, human-guided tasks) can rely partially on human review. The verification budget is proportional to the trust gap.

6. **The verifier is structurally independent from the executor.** In orchestrated mode, the verifier agent receives the same model tier as the executor (Capable) and operates under a distrust mindset. This structural independence is not a nice-to-have — it is the mechanism that closes SASE's speed-vs-trust gap for autonomous execution.

7. **Failure recovery is bounded.** Verification retry budgets prevent infinite loops. Context-budget monitoring prevents verification from consuming the entire session. Cross-task escalation prevents local failures from blocking global progress.
