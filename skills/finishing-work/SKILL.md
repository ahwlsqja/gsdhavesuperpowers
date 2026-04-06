---
name: finishing-work
description: "Use when completing a development task, wrapping up a feature branch, preparing to merge or deliver work, or transitioning out of an implementation phase. Triggers: 'finish this up', 'ready to merge', 'wrap up', 'commit and push', task completion, branch finalization, any transition from active development to delivery. If you are done implementing and need to close out the work cleanly, invoke this skill."
---

# Finishing Work

## Core Principle: Completion Is a Protocol, Not a Feeling

"Done" is not when you think the code works. "Done" is when verification proves the code works, the artifacts are clean, and the next person who touches this codebase will find it in good order. Finishing work is a structured protocol that prevents the common failure of declaring victory prematurely and leaving a mess for the future.

## The Completion Protocol

### Step 1: Verify Tests Pass

Before anything else, run the full test suite relevant to your changes. Not just the tests you wrote — all tests that could be affected.

```
Run: full test command for the project
Expected: 0 failures, 0 errors
```

If tests fail:
- **Your tests fail:** Fix them. Non-negotiable.
- **Existing tests fail:** Your changes broke something. Fix the regression before proceeding.
- **Flaky tests:** Note the flaky test, but verify your changes aren't the cause. Run the failing test 3 times — if it passes at least once with no code changes, it's pre-existing.

Do NOT proceed past this step with failing tests. The verification-before-completion iron law applies here.

### Step 2: Run Linting and Type Checks

If the project has a linter, formatter, or type checker, run them:
- Fix all errors your changes introduced
- Do not fix pre-existing issues in files you didn't modify (scope creep)
- Format only files you touched

### Step 3: Review Your Changes

Review with fresh eyes before presenting:

1. **Read the diff.** Not your mental model — the actual `git diff`.
2. **Check for debug artifacts.** console.log statements, commented-out code, TODO comments you intended to resolve, hardcoded test values.
3. **Check for incomplete work.** Functions returning placeholder values, error handlers swallowing silently, UI with placeholder text.
4. **Check for sensitive data.** API keys, passwords, personal data, internal URLs that shouldn't be in the codebase.

### Step 4: Present Options

After verification passes, present exactly these options (adapt to environment):

| Option | When to Use | Action |
|--------|------------|--------|
| **Merge locally** | Feature branch ready to integrate | Merge to main/target branch |
| **Push and create PR** | Team review required or CI must run | Push branch, create pull request |
| **Keep as-is** | Complete but not ready to integrate | Leave branch, note what's pending |
| **Discard** | Exploratory work or rejected approach | Delete branch and changes (requires confirmation) |

Do not assume which option is correct. Present and let the human decide.

### Step 5: Worktree Cleanup

If working in a git worktree:
1. Verify all changes are committed (no uncommitted work)
2. Return to the main working directory
3. Remove the worktree only if work is merged or discarded
4. Do NOT remove worktrees with unmerged branches — that's data loss

### Step 6: Update Knowledge Artifacts

If you learned something during this work that future tasks should know:

- **KNOWLEDGE.md:** Append non-obvious rules, recurring gotchas, useful patterns. Only entries that would save future agents from repeating your investigation.
- **DECISIONS.md:** Append architectural, pattern, library, or observability decisions. Only meaningful choices.

### Step 7: Write the Summary

Every completed unit of work needs a summary capturing:
- What was accomplished (one sentence)
- What was verified and how (specific commands and outcomes)
- What deviated from the plan (if applicable)
- What issues remain (if any)
- Key files created or modified

The summary is the handoff artifact. If someone reads only the summary, they should understand what happened and what state the codebase is in.

## Common Finishing Failures

| Failure | Consequence | Prevention |
|---------|------------|------------|
| Skipping test verification | Broken code reaches main branch | Step 1 is non-negotiable |
| Leaving debug artifacts | console.logs in production, commented code | Step 3 diff review catches these |
| Not updating knowledge | Next agent repeats your debugging | Step 6 — if you struggled, document why |
| Premature worktree deletion | Unmerged work lost | Step 5 — verify merge status first |
| Vague summary | Next person can't understand what happened | Step 7 — specific commands and outcomes |
| Force-pushing without checking | Overwriting teammate's work | Check remote state before force operations |

## The Discard Safety Protocol

Discarding work requires explicit confirmation because it is irreversible:

1. Verify the work is truly meant to be discarded (not just paused)
2. Check for valuable discoveries or knowledge that should be preserved even if code is discarded
3. Require the word "discard" to be explicitly confirmed
4. Delete the branch and clean up the worktree
5. Note what was discarded and why — future agents may attempt the same approach

Do not silently discard work. Discarding is an intentional act, not housekeeping.
