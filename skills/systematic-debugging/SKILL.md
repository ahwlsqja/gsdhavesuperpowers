---
name: systematic-debugging
description: "Use when encountering bugs, test failures, unexpected behavior, errors, crashes, or any situation where code does not work as expected. Triggers: 'fix bug', 'debug', 'not working', 'error', 'failing test', 'unexpected behavior', 'crash', 'broken', stack traces, error messages, assertion failures. If something is wrong and you do not know why, invoke this skill."
---

# Systematic Debugging

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.
```

**Violating the letter of this rule is violating the spirit of this rule.**

There is no "spirit of debugging" that lets you try a fix before understanding the problem. There is no urgency that justifies guess-and-check over investigation. The letter IS the spirit. Investigation first, fix second. Always. If you find yourself reaching for a code change before you can articulate why the bug occurs, you are guessing — stop and investigate.

## Why Root-Cause-First Is Non-Negotiable

Guess-and-check debugging has three failure modes that systematic investigation avoids:

1. **Symptom fixing.** You fix the visible symptom without understanding the underlying cause. The root cause manifests again through a different symptom, and you have now made the system harder to debug because the obvious symptom is gone.

2. **Thrashing.** You try fix after fix, each one changing the system state, until eventually something appears to work — but you do not know which change actually fixed it, whether the other changes introduced new bugs, or whether the fix is correct or merely coincidental.

3. **Cargo culting.** You find a Stack Overflow answer or similar fix that resolved the same symptom in a different context. You apply it without understanding why it works. It may work, or it may mask the problem, or it may introduce a different problem that manifests later.

Systematic debugging is **faster** than guess-and-check. It feels slower because investigation does not produce visible code changes, and agents (like humans) mistake activity for progress. But a 10-minute investigation that identifies the root cause produces a 2-minute fix, while 30 minutes of guess-and-check may never converge.

## The Excuse / Reality Table

| # | Excuse | Reality |
|---|--------|---------|
| 1 | "The issue is simple, I don't need a process" | Simple issues have root causes too. And issues that look simple often are not — the simplicity is a surface illusion over a deeper problem. Investigate anyway. |
| 2 | "It's an emergency, there's no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. The emergency makes process more important, not less. Panicked changes to production code are how incidents escalate. |
| 3 | "Let me just try this one thing first, then investigate" | The first fix sets the pattern. If you start with guessing, you will continue guessing. The investigation must happen BEFORE the first fix attempt, not after the third failed attempt. |
| 4 | "I've seen this exact error before, I know the fix" | Same error ≠ same cause. The error message describes the symptom, not the root cause. Verify that the root cause matches your memory before applying the fix from memory. |
| 5 | "The fix is obvious from the stack trace" | Stack traces show where the error manifested, not where it originated. The obvious fix addresses the manifestation point. The correct fix may be several layers deeper. |
| 6 | "I'll investigate after I apply this quick patch" | Quick patches become permanent. Once the symptom is gone, the urgency to investigate evaporates. Investigate first, patch second, or the investigation never happens. |
| 7 | "The user needs a fix now, I can't spend time investigating" | Shipping a wrong fix is worse than shipping no fix. A fix that masks the symptom gives false confidence while the root cause continues to operate. Investigate, then fix correctly. |
| 8 | "I already know what the problem is" | If you already know, the investigation will be fast — it will confirm your hypothesis in minutes. If you are wrong, the investigation will save you hours of working on the wrong problem. Either way, investigate. |

## The 12 Red Flags

When you notice yourself doing any of the following, **STOP immediately and return to Phase 1 (Gather Evidence)**. Each red flag signals that you have left systematic investigation and entered guess-and-check territory.

🚩 **Red Flag 1:** "Quick fix for now, investigate later"
— "Later" never comes. Investigate now.

🚩 **Red Flag 2:** "Just try changing X and see if it works"
— "Try and see" is guessing. Form a hypothesis first, then test it specifically.

🚩 **Red Flag 3:** "It's probably X, let me fix that"
— "Probably" means unverified. Verify before fixing.

🚩 **Red Flag 4:** "Let me revert to a known good state and start over"
— Reverting without understanding what went wrong means you will reproduce the same bug. Understand first.

🚩 **Red Flag 5:** "The pattern says X but I'll adapt it differently"
— If you are deviating from the debugging process, you need a reason. "I feel like it" is not a reason.

🚩 **Red Flag 6:** "One more fix attempt" (when you have already tried 2+)
— Three failed fixes means your mental model is wrong. Stop fixing. Start investigating.

🚩 **Red Flag 7:** "This is a different problem now"
— It may be the same root cause manifesting differently because your prior fix attempts changed the system state. Investigate whether your changes created new symptoms.

🚩 **Red Flag 8:** "I don't need to read the full error — I can see the issue"
— Read the full error. Every time. The part you skipped often contains the actual cause.

🚩 **Red Flag 9:** "Let me add some logging and see what happens"
— Adding logging is investigation infrastructure, not investigation itself. Form a hypothesis about what the logging should reveal before adding it.

🚩 **Red Flag 10:** "The docs say this should work"
— Documentation describes intended behavior. Your code may be using the API incorrectly, hitting a version mismatch, or encountering an undocumented edge case. Test reality, not documentation.

🚩 **Red Flag 11:** "I'll clean this up later once it works"
— "It works" without understanding why is not debugging — it is coincidence. And code written during thrashing accumulates accidental complexity. Understand the fix before keeping it.

🚩 **Red Flag 12:** "Let me ask for help / search online"
— Searching is appropriate AFTER you have gathered evidence and formed a hypothesis. Searching before investigation means you are looking for someone else's root-cause analysis of a different symptom in a different codebase. Gather your own evidence first.

**ALL of these mean: STOP. Return to Phase 1.**

## The Structured Investigation Protocol

### Phase 1: Gather Evidence

Before forming any hypothesis, collect facts:

1. **Reproduce the bug.** Find the minimal steps that trigger the failure. If you cannot reproduce it, you cannot verify any fix.
2. **Read the full error output.** Every line. Exit code, stdout, stderr, stack trace, warning messages — all of it.
3. **Identify what changed.** What was the last working state? What changed between then and now? Git diff, dependency changes, configuration changes, environment changes.
4. **Check the scope.** Is this one failure or multiple failures? Are they related? Does the failure happen consistently or intermittently?
5. **Record the evidence.** Write down what you observed, not what you interpreted. "Exit code 1, stderr contains 'Connection refused on port 5432'" is evidence. "The database is down" is interpretation.

### Phase 2: Form Hypotheses

Based on the evidence — not before gathering it — form specific, testable hypotheses:

1. **Each hypothesis must be falsifiable.** "Something is wrong with the database" is not falsifiable. "The database connection string points to a non-running instance" is falsifiable — you can check it.
2. **Rank hypotheses by likelihood AND testability.** Start with the hypothesis that is both plausible and quick to test. Do not start with the most complex hypothesis.
3. **List at least 2 hypotheses.** If you can only think of one, you have not investigated enough. Return to Phase 1.
4. **Distinguish "I know" from "I assume."** Observable facts (the error says X, the log shows Y) are strong evidence. Assumptions (this library should work this way, this config should be correct) need verification.

### Phase 3: Test Hypotheses

Test one hypothesis at a time. **Change one variable at a time.**

1. **Design the test.** What specific action will confirm or refute this hypothesis? Not "try a fix" — a diagnostic action.
2. **Execute the test.** Run the diagnostic action and observe the result.
3. **Evaluate the result.** Does the observation confirm the hypothesis, refute it, or neither?
4. **If refuted, move to the next hypothesis.** Do NOT continue down a refuted path. Abandon it and test the next hypothesis.
5. **If confirmed, proceed to Phase 4.** You now have a root cause.
6. **If neither confirmed nor refuted, refine the hypothesis.** Make it more specific and test again.

### Phase 4: Fix the Root Cause

Only after you have a confirmed root cause — not a suspected cause, not a probable cause, a **confirmed** cause — do you write a fix.

1. **Write the fix for the root cause, not the symptom.** If the root cause is a missing null check three layers deep, do not add a null check at the top level where the error manifests.
2. **Write a test that reproduces the original failure.** This test should fail before your fix and pass after it. (See `test-driven-development` skill.)
3. **Apply the fix.** Make the minimal change that addresses the root cause.
4. **Verify the fix.** Run the reproduction test. Run the full test suite. Verify no regressions.
5. **Verify you understand why the fix works.** If you cannot explain why the fix resolves the root cause, you do not have the root cause. Return to Phase 2.

### Phase 5: Verify and Learn

After the fix is applied and verified:

1. **Run the full test suite.** Not just the test for this bug. The full suite. Your fix may have side effects.
2. **Check for related occurrences.** If the root cause was a pattern (e.g., missing null checks on API responses), search for the same pattern elsewhere.
3. **Document the finding.** If the root cause was non-obvious, add it to `KNOWLEDGE.md` so future sessions do not repeat the investigation.

## Remediation: What To Do When The Iron Law Is Violated

If you have applied a fix without investigating the root cause:

1. **Revert the fix.** Do not build on top of an ununderstood change.
2. **Return to Phase 1.** Gather evidence in the current state (before the reverted fix).
3. **Follow the full protocol.** Investigate, hypothesize, test, then fix.
4. **Compare your investigation fix with the reverted fix.** If they are different, the reverted fix was masking the symptom, not addressing the root cause. If they are the same, the investigation confirmed the fix — now you know WHY it works, which makes the fix maintainable.

If you have been thrashing (3+ fix attempts without convergence):

1. **Stop.** Do not attempt another fix.
2. **List what you know for certain.** Observable facts only — error messages, stack traces, git diffs.
3. **List what you have ruled out.** Which hypotheses were tested and refuted?
4. **Form fresh hypotheses from the remaining space.** Your mental model is wrong — the root cause is something you have not considered yet.
5. **If still stuck after fresh hypothesis testing, decompose.** The problem may be a composition of multiple smaller problems. Isolate and address each independently.

## Anti-Thrashing Directives

Thrashing is the debugging antipattern where you make rapid changes without understanding, testing, or evaluating each change independently. To prevent thrashing:

- **One change at a time.** Make one change. Test it. Observe the result. Then decide the next action. Multiple simultaneous changes mean you cannot attribute what worked.
- **Pause after each change.** Read the output fully before deciding the next step. Do not chain changes without observing intermediate results.
- **Track your attempts.** Maintain a mental or written log: "Attempt 1: changed X → result Y. Attempt 2: changed Z → result W." If you cannot recall your previous attempts, you are thrashing.
- **Escalate at 3 failed attempts.** Three failed fix attempts means your model of the problem is wrong. Do not try a fourth fix — return to evidence gathering with fresh eyes.

## What This Skill Does NOT Do

- It does NOT replace test-driven development (use `test-driven-development` for writing new tests)
- It does NOT define verification of completion (use `verification-before-completion` after the fix)
- It does NOT prescribe specific debugging tools (use whatever tools are available in the project)
- It does NOT apply to known, mechanical fixes (typos, import paths, config values with an obvious correct answer)

This skill answers ONE question: "Do you understand WHY the bug occurs before attempting to fix it?" Everything else is downstream.
