# Reference Specification: Repair Strategies

**Name:** `repair-strategies`
**Scope:** Node repair operator logic: RETRY/DECOMPOSE/PRUNE decision criteria, retry budget rules, decomposition heuristics, escalation thresholds
**Loading Behavior:** Hot-tier in orchestrated mode — loaded by orchestrator when any verification verdict is not `passed`
**Consumers:** Orchestrator agent (repair operator decision logic), verifier agent (failure categorization for repair selection), executor agent (retry protocol compliance), debugger agent (invoked during RETRY for root cause analysis)
**Research Grounding:** verification-pipeline.md §Failure Recovery, §Node Repair Operator Integration, §Cross-References; orchestrator agent spec §Node Repair Operator; SYN-11

---

## Content Scope

This reference provides the decision criteria and operational protocols the orchestrator uses when verification fails. It defines three recovery strategies (RETRY, DECOMPOSE, PRUNE), their selection criteria, budget constraints, and escalation thresholds. Verification failure is treated as an expected part of the development workflow, not as an agent deficiency.

**What belongs here:** Strategy selection criteria, retry budgets, decomposition heuristics, PRUNE escalation protocol, cross-task escalation thresholds, and the systematic debugging integration requirement.

**What does NOT belong here:** Stub detection patterns (those are in `verification-patterns`), agent behavioral specifications (those are in individual agent specs), or context budget calculations (those are in `context-budget`).

---

## Strategy Selection Criteria

The repair operator selects a recovery strategy based on the failure signal from the verifier:

| Failure Signal | Recovery Strategy | Budget | Trigger for Escalation |
|---|---|---|---|
| Single finding, clear fix | **RETRY** with targeted adjustment | 2 attempts per task | Third failure on same finding → DECOMPOSE |
| Multiple findings, interconnected | **DECOMPOSE** into smaller verifiable units | 2–4 sub-tasks | Any sub-task fails after its own RETRY budget → PRUNE |
| Fundamental approach mismatch | **PRUNE** and escalate | N/A | Immediate escalation |
| Environmental or tooling issue | **RETRY** after environment fix | 1 attempt | Environment still broken → PRUNE |

---

## RETRY Protocol

RETRY is the first-line recovery strategy for isolated, addressable failures.

1. The executor receives the verifier's specific findings — not just "failed" but the structured list of what failed and why
2. The executor applies the systematic debugging iron law: **investigate root cause before fixing**. No fixes without understanding the cause first
3. The executor makes a targeted fix addressing one finding at a time — multiple simultaneous changes are prohibited because they prevent attribution of what worked
4. The full verification pipeline re-runs (both Layer 1 behavioral gate and Layer 2 programmatic checks)
5. If the retry succeeds, execution continues normally
6. If the retry fails on a different finding, another retry is permitted (budget counts per-finding)
7. If the retry fails on the same finding twice, escalate to DECOMPOSE — the failure indicates the task is too complex for atomic execution

**Systematic debugging integration:** During RETRY, the debugging iron law prevents "guess-and-check thrashing" where the executor makes random changes hoping to pass verification. The sequence is: investigate → form hypothesis → test hypothesis → fix if confirmed.

**Red flags that indicate RETRY should be skipped:** "One more fix attempt" when already tried 2+ times, or making multiple changes simultaneously. These signal that DECOMPOSE is the appropriate strategy.

---

## DECOMPOSE Protocol

DECOMPOSE is the escalation strategy when RETRY cannot resolve the failure, indicating the task was too complex for atomic execution.

1. The orchestrator analyzes verification failures to identify natural decomposition boundaries — each sub-task should target a specific aspect of the original task
2. The failed task is split into 2–4 smaller, independently verifiable sub-tasks
3. Each sub-task goes through the full pipeline: plan → execute → verify
4. Sub-tasks inherit the parent task's verification criteria, scoped to their specific aspect
5. Each sub-task has its own RETRY budget (2 attempts)

**Decomposition heuristics:** Split along verification finding boundaries (one sub-task per finding), along functional boundaries (input handling, core logic, output formatting), or along integration boundaries (internal logic vs. external API interaction). The decomposition should produce sub-tasks that are independently meaningful — not just "do the first half" and "do the second half."

---

## PRUNE Protocol

PRUNE is the strategy of last resort — it means the automated pipeline cannot solve this problem in the current context.

1. The task is marked as unachievable in the current automated pipeline
2. A detailed failure report is generated containing: all verification findings across all attempts, root cause analysis from each RETRY attempt, decomposition rationale and sub-task failure details
3. In interactive mode: the failure report is presented to the developer for manual resolution
4. In orchestrated mode: the failure report is recorded in the slice state and the orchestrator continues with remaining tasks, noting the dependency gap

---

## Escalation Thresholds

Numerical limits that bound the repair operator's effort before forcing escalation:

- **RETRY attempts per task:** 2 (third failure on same finding triggers DECOMPOSE)
- **DECOMPOSE sub-tasks per failed task:** Maximum 4
- **Maximum total verification cycles per original task:** 2 (RETRY) + 4 × 2 (DECOMPOSE sub-tasks with their own RETRY) = 10
- **Context budget ceiling:** If verification is consuming more than 40% of the remaining context window, force PRUNE regardless of retry budget remaining — tracked by the context-management skill
- **Cross-task escalation:** If 3 or more tasks in the same slice hit DECOMPOSE, the orchestrator pauses execution and escalates the entire slice for reassessment. This signals that the plan may be fundamentally wrong — individual task failures are expected, but systematic decomposition across multiple tasks indicates a planning-level problem

---

## Cross-References

- **Orchestrator agent spec:** §Node Repair Operator implements this reference's decision logic
- **Verifier agent spec:** Produces the structured findings that drive strategy selection
- **Executor agent spec:** Follows the RETRY protocol constraints (one fix at a time, root cause first)
- **Debugger agent spec:** Invoked during RETRY to provide systematic root cause investigation
- **`verification-patterns` reference:** Defines the stub detection patterns that produce verification findings
- **`context-budget` reference:** Provides the 40% ceiling threshold for forced PRUNE
- **`systematic-debugging` skill:** Supplies the iron law and investigation methodology used during RETRY
