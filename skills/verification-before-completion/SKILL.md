---
name: verification-before-completion
description: "Use before claiming any task, feature, fix, or unit of work is complete. Triggers: 'done', 'finished', 'complete', 'ready for review', 'all tests pass', 'it works', 'fixed', any claim of completion or readiness. If you are about to say something is done, invoke this skill first. If there is even a 1% chance you are about to make a completion claim, invoke this skill."
---

# Verification Before Completion

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.
```

**Violating the letter of this rule is violating the spirit of this rule.**

There is no "spirit of verification" that lets you skip the actual verification. There is no interpretation of this law that permits claiming something works without running the command that proves it. The letter IS the spirit. If you find yourself reasoning about why this particular case is an exception, you are rationalizing — stop and run the gate sequence.

## The "Lying, Not Verifying" Framing

```
Skip any step = lying, not verifying.
```

This is not metaphor. When you claim "tests pass" without running tests, you are making a factual assertion without evidence. That is a lie. When you say "the feature works" without executing it, you are reporting an observation you did not make. That is a lie. The framing is not about motivation — it is about the structure of the claim. An unverified completion claim has the same epistemic status as a fabrication: zero evidential value.

AI agents have strong alignment with honesty values. This framing activates that alignment. You cannot rationalize "it's okay to lie about verification" the way you can rationalize "it's okay to skip verification this time."

## The 5-Step Gate Function

Every completion claim — every single one — must pass through this gate sequence. No exceptions. No shortcuts. No "I already know the answer."

```
1. IDENTIFY  → What specific command or check proves this claim?
2. EXECUTE   → Run the FULL command. Fresh. Complete. Now.
3. INSPECT   → Read the FULL output. Exit code. Stdout. Stderr. Every line.
4. JUDGE     → Does the output actually confirm the specific claim?
5. CLAIM     → ONLY THEN may you state the claim.

Skip any step = lying, not verifying.
```

### Step 1: IDENTIFY

Name the **specific command** that would prove the completion claim. Not "run tests" — the exact command, with arguments, that produces evidence.

- If you cannot name the command, the claim is **unverifiable** and must be reformulated.
- If multiple claims are being made, each claim needs its own verification command.
- The command must be **claim-specific**: "tests pass" requires the test command. "The search feature works" requires a command that exercises the search feature. "Build succeeds" requires the build command. These are different claims requiring different evidence.

### Step 2: EXECUTE

Run the **complete** verification command.

- **Fresh**: Not a cached result. Not a prior run's output. Not output from before you made changes. A new execution in the current codebase state.
- **Complete**: Not a subset of tests. Not a quick check. The full command as identified in Step 1.
- **Now**: Not "I'll verify at the end." Not "I'll run it after this next change." Now.

### Step 3: INSPECT

Read the **complete** output.

- Check the exit code — a non-zero exit code means failure regardless of what stdout says.
- Read stdout fully — do not scan for "PASS" while ignoring failure details above it.
- Read stderr — warnings and errors appear here and are often the most important signal.
- Count failures — "3 passed, 1 failed" is not "tests pass." It is "tests fail."

### Step 4: JUDGE

Compare the actual output against the **specific claim** being verified.

Apply GSD's 4-level artifact verification model to judge the evidence rigorously:

| Level | Question | What It Catches |
|-------|----------|-----------------|
| **1. Exists** | Does the claimed artifact exist on disk at the expected path? Is it non-empty? | Files that were never created. Zero-byte files. Import-only files with no implementation. |
| **2. Substantive** | Does it contain real implementation, not stubs? Are there actual function bodies, not just signatures? | Well-structured skeletons with no functional content. Functions returning `null` or `{}`. Empty event handlers. |
| **3. Wired** | Is it connected to the rest of the system? Are imports used? Are exports consumed? Are handlers attached? | "Island" artifacts — code that exists and is substantive but is never integrated. Components never rendered. Endpoints never routed. |
| **4. Functional** | Does it work end-to-end with real data? Do data flows complete? Are error paths handled? | Correct-looking code that fails at runtime. Happy paths that work but error paths that crash. |

A completion claim is only valid when verification passes **all four levels**. "The file exists" is Level 1 — necessary but nowhere near sufficient. "The tests pass" may only reach Level 2 or 3. Full verification reaches Level 4.

### Step 5: CLAIM

**Only after Steps 1–4 have been performed and the judgment is affirmative** may you make the completion claim. The claim must reference the evidence:

- ✅ "Tests pass — ran `npm test`, exit code 0, 47 passed, 0 failed."
- ✅ "Feature works — executed the search flow, returned 3 results matching the query."
- ❌ "Tests should pass now." (Step 2 not performed)
- ❌ "I'm confident this works." (Step 2 not performed)
- ❌ "The build passed so everything works." (Build ≠ functional correctness)

## Dual-Layer Verification

Verification operates on two independent layers. Neither is optional. Neither is a fallback for the other. Both run on every verification pass.

### Layer 1 — Behavioral Verification (This Gate Function)

Layer 1 ensures you **actually perform** verification before making any completion claim. It addresses the dominant quality failure: agents skip verification not because they are incapable, but because they are confident enough to rationalize skipping it.

### Layer 2 — Programmatic Verification (Independent Checking)

Layer 2 inspects the codebase **independently of your self-assessment**. It catches structural problems you cannot self-identify:

- **Stub implementations** hidden behind real-looking interfaces
- **Empty handlers** that pass type checking but do nothing
- **Hardcoded values** where dynamic data should flow
- **Wiring gaps** where components exist in isolation but are not connected

When programmatic verification finds issues that your behavioral assessment missed:

> **Programmatic findings override your claims.**

You may have honestly run tests and read output. But if the stub detector found an empty handler you did not recognize as incomplete, the programmatic finding takes precedence. Address each finding — fix the issue or provide an explicit justification. Then restart the verification cycle.

## Common Failures Table

This table maps common completion claims to the evidence they actually require. "Not Sufficient" shows what agents commonly offer instead of real evidence.

| Claim | Required Evidence | Not Sufficient |
|-------|-------------------|----------------|
| "Tests pass" | Test command output showing 0 failures, non-zero exit code check | Previous run output. "Should pass." |
| "Build succeeds" | Build command output with exit code 0 | Linter passing. "Looks good in logs." |
| "Bug is fixed" | Test reproducing the original symptom now passes | "I changed the code." "It should be fixed." |
| "Feature works" | End-to-end execution demonstrating the feature with real data | "I implemented it." Component exists. |
| "Agent completed task" | VCS diff shows changes matching the task specification | Agent's self-report of "success." |
| "No regressions" | Full test suite passing, not just new tests | "I only changed one file." |
| "Error handling works" | Deliberate error injection producing correct error response | "I added a try-catch." |
| "API endpoint works" | HTTP request to endpoint returning expected response | "Route is registered." Handler exists. |

## Remediation: What To Do When The Iron Law Is Violated

If you have made a completion claim without running the gate sequence:

1. **Retract the claim immediately.** Do not add qualifiers — retract it entirely.
2. **Run the full gate sequence now.** IDENTIFY → EXECUTE → INSPECT → JUDGE → CLAIM.
3. **If verification fails, fix the issue before re-claiming.** Do not re-claim with caveats ("works except for..."). Fix first, verify second, claim third.
4. **Do not blame time pressure.** Running verification takes less time than debugging a false completion claim that breaks downstream work.

If you catch yourself about to make an unverified claim:

1. **Stop mid-sentence.** It is better to pause than to make a false claim.
2. **Run the gate sequence.** Then complete the sentence with evidence.

## Rationalization Prevention Table

| # | Rationalization | Reality |
|---|----------------|---------|
| 1 | "Tests should pass based on my changes" | Run the tests. "Should" is not evidence. Agents frequently misjudge side effects, import chains, and runtime behavior. |
| 2 | "I'm confident this works" | Confidence is not verification. Execute the gate sequence. Confidence correlates with familiarity, not correctness. |
| 3 | "The change is too simple to need verification" | Simple changes have simple verifications. Run them. "Simple" changes cause a disproportionate share of incidents because they bypass review. |
| 4 | "I already verified a similar change earlier" | Each change gets its own verification. Prior evidence is stale. Code changes interact — a verification that passed before may fail after a subsequent edit. |
| 5 | "The tests are slow and I already know the result" | Slow tests exist for a reason. Run them fully. Speed of verification does not determine its necessity. |
| 6 | "I'll verify at the end after all changes are done" | Verify after each logical unit. Deferred verification compounds risk — debugging interleaved changes becomes archaeology. |
| 7 | "Different words so the rule doesn't apply" | The spirit of verification applies regardless of framing. Rephrasing "completion" as "ready for review" or "initial implementation" does not exempt you. |
| 8 | "The build passed so everything works" | Build success ≠ functional correctness. Builds verify compilation and static analysis, not runtime behavior or user-facing correctness. |

## Red-Flag Language Patterns

Monitor your own output for these signals that an unverified claim is about to be made:

- **"Should"** — "This should work" → Stop. Run the gate sequence.
- **"Probably"** — "This probably handles the edge case" → Stop. Write a test for the edge case.
- **"Seems to"** — "The output seems correct" → Stop. Define what "correct" means quantitatively and verify.
- **"I believe"** — "I believe this is complete" → Stop. What specific evidence supports the belief?
- **"Based on my understanding"** — This phrase is a confession that no verification has been performed.
- **"Looks good"** — Looking is not testing. Run the verification.
- **"It works"** — How do you know? What command did you run? What was the output?

## What This Skill Does NOT Do

- It does NOT replace domain-specific testing (use `test-driven-development` for TDD workflow)
- It does NOT define what to test (that comes from the task plan's verification section)
- It does NOT perform debugging (use `systematic-debugging` when verification reveals failures)
- It does NOT reduce the need for code review (verification and review serve different purposes)

This skill answers ONE question: "Is your completion claim backed by evidence?" Everything else is downstream.
