---
name: test-driven-development
description: "Use when writing new code, adding features, fixing bugs, or refactoring existing code where tests are applicable. Triggers: 'implement', 'add feature', 'fix bug', 'write function', 'create endpoint', 'build component', 'refactor', any code change where the language and framework support automated testing. If you are about to write production code and a testing framework exists, invoke this skill."
---

# Test-Driven Development

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.
```

**Violating the letter of this rule is violating the spirit of this rule.**

There is no "spirit of TDD" that lets you write code first and tests later. There is no context in which "I'll add tests after" achieves the same goal. The letter IS the spirit. Tests-first means tests-first. If you find yourself constructing an argument for why this particular case is different, you are rationalizing — stop, delete the production code, and write the test.

## Why Tests-First Is Non-Negotiable

Tests written after implementation answer a fundamentally different question:

- **Tests-first** ask: "What should this code do?" — They define the contract before implementation.
- **Tests-after** ask: "What does this code do?" — They describe existing behavior, including bugs and accidents.

Tests-after cement whatever the implementation happens to do. Tests-first force you to think about what the implementation *should* do before you are anchored by what it *actually* does. This is not a style preference — it is a structural difference in the quality of the design feedback loop.

The Codified Expert Knowledge study documented a 206% quality improvement when agents work within a codified methodology. TDD is the sharpest embodiment of that finding: the test is the codified specification that constrains the implementation.

## When TDD Applies

TDD applies when **all three conditions** are met:

1. **A testing framework exists** for the language and project
2. **The code has testable behavior** — it produces observable outputs, changes state, or has side effects that can be asserted against
3. **The code is not purely declarative** — configuration files, static markup, type definitions, and CSS do not require TDD (but their effects should be tested at the integration level)

When TDD does not apply, you still write tests — you just write them alongside the implementation rather than strictly before it. The iron law applies to the vast majority of production code.

## The Red-Green-Refactor Flow

### 🔴 RED: Write a Failing Test

1. Write a test that describes the behavior you want to implement
2. The test must target a **specific, named behavior** — not "test the function" but "test that search returns matching results sorted by relevance"
3. Run the test. **It must fail.** If it passes, either:
   - The behavior already exists (your test is not testing anything new)
   - The test is not testing what you think it is (fix the test)

```
VERIFY: Run the test. See it fail. Read the failure message.
If it does not fail, do NOT proceed. The test is wrong.
```

### 🟢 GREEN: Write Minimal Code to Pass

1. Write the **minimum** production code that makes the failing test pass
2. "Minimum" means: no extra features, no premature abstractions, no "while I'm here" additions
3. Run the test. **It must pass.** If it does not:
   - Read the failure message carefully
   - Fix the production code (not the test, unless the test had a bug)
   - Run again

```
VERIFY: Run the test. See it pass. Confirm no other tests broke.
If other tests broke, your change has unintended side effects — investigate.
```

### 🔵 REFACTOR: Improve Without Changing Behavior

1. Clean up the code — extract functions, rename variables, remove duplication
2. Run all tests after each refactoring step. **All must still pass.**
3. If any test fails during refactoring, **undo the refactoring** — you changed behavior, not just structure

```
VERIFY: Run ALL tests after each refactor step.
Refactoring that breaks tests is not refactoring — it is a behavior change.
```

### Then Repeat

Return to RED for the next behavior. Each cycle adds one behavior to the system. The accumulation of small, verified increments produces a system that is correct by construction.

## Remediation: What To Do When The Iron Law Is Violated

If you have written production code without a failing test first:

**Delete it. Start over. No exceptions.**

- **Do NOT keep it as "reference."** Looking at existing code anchors your thinking to its accidental structure. Delete means delete.
- **Do NOT "adapt" it while writing tests.** You will rationalize the existing implementation into the tests rather than letting the tests drive a clean implementation.
- **Do NOT look at it.** Seriously. Close the file. The code was written without the design pressure of tests-first, which means its structure reflects implementation convenience, not behavioral correctness.
- **Delete means delete.** Then write the failing test. Then write the minimal code to pass it. The code you produce will be different — and better.

If the code-before-test was a large volume of work:

1. **Delete it anyway.** Sunk cost fallacy is the strongest rationalization for keeping untested code. The more you wrote, the more damage untested code can do.
2. **Decompose the work into smaller test cycles.** If you wrote a lot of code at once, the tests-first approach will naturally break it into smaller, verified increments.
3. **Consider this a learning moment.** The pain of deleting work is the behavioral feedback that prevents the next violation.

## The 12-Row Rationalization Prevention Table

| # | Rationalization | Correction |
|---|----------------|------------|
| 1 | "I'll write tests after I get the implementation working" | Tests-after ask "what does this do?" Tests-first ask "what should this do?" These are fundamentally different questions. Write the test first. |
| 2 | "This code is too simple to need tests" | Simple code has simple tests. If it is truly simple, the test takes 30 seconds to write. If it takes longer, the code is not as simple as you thought. |
| 3 | "I need to explore the implementation approach first" | Write the test first. The test defines what the code should do — it does not constrain how. Exploration happens in the GREEN phase. |
| 4 | "The testing framework isn't set up yet" | Setting up the testing framework IS the first task. Do it now. No production code until the test runner works. |
| 5 | "Tests after achieve the same goals" | Tests-after describe existing behavior including bugs. Tests-first define intended behavior. The design feedback loop is structurally different, not just temporally different. |
| 6 | "Deleting X hours of work is wasteful" | Sunk cost fallacy. Keeping unverified code is technical debt with interest. The cost of keeping it compounds; the cost of deleting it is fixed and immediate. |
| 7 | "I can see that this code is correct" | Visual inspection catches syntax errors, not logic errors. You cannot see race conditions, off-by-one errors, or edge cases by reading code. Run a test. |
| 8 | "TDD slows me down" | TDD slows down the first 10 minutes. Debugging untested code slows down the next 10 hours. The total development time with TDD is consistently shorter. |
| 9 | "This is prototype/spike code, not production" | If the code will influence the production implementation, it must be tested. If it truly will not (you will delete it before writing production code), then it is not production code and the iron law does not apply — but you must actually delete it. |
| 10 | "I just need to see if this approach works" | Write a test that defines what "works" means. If you cannot write that test, you do not have a clear enough understanding of what you are building. The test forces clarity. |
| 11 | "The test is too hard to write for this code" | If the code is too hard to test, the code has a design problem. Testability is a design quality. Hard-to-test code is hard-to-maintain code. Redesign it. |
| 12 | "I'm just wiring things together, there's no logic to test" | Wiring has correctness conditions: the right components are connected, data flows in the expected direction, error propagation works. Write an integration test. |

## Negative Tests: What to Test Beyond the Happy Path

Do not stop at "it works when given correct input." Test the failure modes:

- **Invalid inputs:** What happens with null, undefined, empty strings, negative numbers, impossibly large values?
- **Missing dependencies:** What happens when the database is down, the API returns 500, the file does not exist?
- **Edge cases:** Empty collections, single-element collections, boundary values, unicode, concurrent access
- **Error messages:** Are error messages helpful? Do they include enough context to diagnose the problem without reading the source code?

Each negative test follows the same RED-GREEN-REFACTOR cycle. Write the test that expects the correct error behavior. Watch it fail. Implement the error handling. Watch it pass.

## TDD with Existing Code (Refactoring Legacy)

When modifying existing code that has no tests:

1. **Write a characterization test first.** This test captures the current behavior — correct or not. It serves as a safety net for your changes.
2. **Then write the test for the new behavior.** This test should fail against the current code.
3. **Then modify the code.** The characterization test ensures you did not break existing behavior. The new test ensures you achieved the desired behavior.
4. **Do NOT skip the characterization test.** "I understand what this code does" is not a substitute for a test that proves it.

## What This Skill Does NOT Do

- It does NOT define verification of completion claims (use `verification-before-completion`)
- It does NOT define debugging methodology (use `systematic-debugging`)
- It does NOT prescribe specific testing frameworks or libraries
- It does NOT apply to purely declarative artifacts (config, markup, type definitions)

This skill answers ONE question: "Is your production code driven by tests that existed before the code did?" Everything else is downstream.
