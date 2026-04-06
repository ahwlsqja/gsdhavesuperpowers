---
name: requesting-code-review
description: "Use when requesting review of code changes before merge, after completing a task in subagent-driven development, or after finishing a major feature. Triggers: 'ready for review', 'please review', 'PR ready', 'merge request', task completion in subagent workflow, any moment where code should be evaluated by another agent or human before proceeding. If changes are about to be merged or handed off, invoke this skill."
---

# Requesting Code Review

## When to Request Review

Review is not optional in these situations:

1. **After each task in subagent-driven development** — Every task completion triggers the two-stage review protocol (spec compliance → code quality). No exceptions.
2. **After completing a major feature** — Before merging feature work to the main branch.
3. **Before merge to main** — Every merge to main passes through review, regardless of change size.
4. **After fixing critical bugs** — Bug fixes that touch core logic or data paths must be reviewed to prevent regression.
5. **After security-sensitive changes** — Authentication, authorization, data validation, or encryption changes always require review.

Review is optional but recommended for:
- Config changes that don't affect runtime behavior
- Documentation-only changes
- Dependency version bumps (minor/patch)

## The Structured Review Request

Every review request must provide sufficient context for the reviewer to evaluate the changes without needing to ask clarifying questions. Use this template:

### Review Request Template

```markdown
## Review Request

### References
- **Base commit:** [git SHA of the branch point / before changes]
- **Head commit:** [git SHA of the latest change]
- **Plan reference:** [path to PLAN.md or task description being implemented]
- **Requirements:** [specific requirements from the plan that this change addresses]

### What Was Implemented
[2-3 sentence summary of what changed and why. Be specific — "implemented search endpoint" not "made changes."]

### Files Changed
[List of files modified with one-line description of each change]

### Verification Status
- [ ] Tests pass: `[exact test command]` → [result]
- [ ] Build succeeds: `[exact build command]` → [result]
- [ ] Lint clean: `[exact lint command]` → [result]

### Focus Areas
[Where the reviewer should pay closest attention. Be specific:]
- "The caching logic in `src/cache.ts:45-82` — concerned about race conditions under concurrent access"
- "The SQL query in `src/queries/search.ts` — unsure about index usage with the LIKE clause"
- "Error handling in the webhook handler — not sure all failure modes are covered"

### Known Limitations
[What this implementation does NOT handle, deliberately. This prevents the reviewer from flagging known gaps as issues.]
- "Does not handle pagination — deferred to Task 4"
- "Error messages are generic — will be refined in the polish phase"

### Testing Approach
[How the changes were tested. What edge cases were considered.]
```

### Why Each Field Matters

| Field | Purpose | What Happens Without It |
|-------|---------|------------------------|
| Base/head commits | Reviewer can `git diff` the exact changes | Reviewer must guess which changes are new vs. pre-existing |
| Plan reference | Reviewer evaluates against the specification | Reviewer evaluates against their own assumptions |
| What was implemented | Sets reviewer expectations | Reviewer may focus on the wrong aspects |
| Files changed | Scopes the review | Reviewer may miss changed files or review unchanged ones |
| Verification status | Shows what was already checked | Reviewer wastes time re-running basic checks |
| Focus areas | Directs attention to high-risk code | Reviewer spreads attention evenly, potentially missing critical issues |
| Known limitations | Prevents false-positive findings | Reviewer flags known gaps, creating noise |
| Testing approach | Shows verification depth | Reviewer cannot assess test coverage quality |

## Review Scope Guidance

### What to Include in a Single Review

A review request should cover **one logical change**. If you find yourself writing "Also, I refactored X and fixed Y while I was in there," split into separate reviews.

Appropriate single-review scope:
- One task from a plan
- One feature (may span multiple files)
- One bug fix with its test
- One refactoring with verification that behavior is unchanged

Inappropriate single-review scope:
- Multiple unrelated features in one diff
- A feature implementation plus an unrelated refactoring
- Bug fixes for 3 different issues in one commit

### Self-Review Before Requesting

Before requesting review from another agent or human, perform a self-review:

1. **Diff review**: Read your own `git diff` as if you're seeing the code for the first time. Are there leftover debug statements? Commented-out code? TODO markers?
2. **Plan alignment**: Does every change trace back to a requirement in the plan? Is anything extra?
3. **Test coverage**: Does every new code path have a corresponding test? Are edge cases covered?
4. **Naming consistency**: Do new identifiers follow the codebase's existing conventions?
5. **Import cleanup**: Are all imports used? Are there missing imports that happen to work due to transitive dependencies?

## Two-Stage Review Protocol

When working within the subagent-driven-development workflow, review happens in two mandatory stages:

### Stage 1: Spec Compliance Review

The first reviewer checks: **Did the implementer build what was requested?**

- Does the implementation match every requirement in the task specification?
- Is anything missing that the spec requires?
- Is anything extra that the spec does not require?
- Are verification commands passing?

The review request for spec compliance should emphasize: plan reference, requirements coverage, and verification status.

### Stage 2: Code Quality Review

The second reviewer checks: **Is the implementation well-built?**

- Code clarity, naming, structure
- Error handling completeness
- Test quality and coverage
- Performance characteristics
- Security considerations

The review request for code quality should emphasize: focus areas, testing approach, and known limitations.

### Review Loops

If a reviewer finds issues:

1. Fix the issues
2. Update the review request (new head commit, updated verification status)
3. Request re-review

**Do not skip re-review.** A fix that was not reviewed is an unverified change. The re-review confirms the fix addresses the issue without introducing new problems.

## Requesting Review from Human Partners

When requesting review from a human developer rather than an agent reviewer:

- **Be explicit about what you need** — "Please review the error handling logic" is better than "Please review"
- **Provide context proportional to their familiarity** — A developer who wrote the original code needs less context than one seeing it for the first time
- **Highlight decisions you're uncertain about** — "I chose X over Y because of Z, but I'm not confident about this tradeoff"
- **Respect their time** — A focused review request on specific concerns gets better feedback than "review everything"

## Rationalization Prevention Table

| # | Thought Pattern | Correction |
|---|----------------|------------|
| 1 | "This change is too small to need review" | Small changes cause production incidents precisely because they bypass review. If it changes behavior, it needs review. |
| 2 | "I already tested it thoroughly" | Your testing proves it works. Review proves it's correct, maintainable, and aligned with the spec. These are different things. |
| 3 | "The reviewer will just approve it anyway" | Then the review is quick. But if they find something, you avoided shipping a problem. The expected value of review is always positive. |
| 4 | "I'm blocking on this, review will slow me down" | Shipping broken code to unblock yourself creates a larger block downstream. Review catches problems when they're cheap to fix. |
| 5 | "I'll get review on the next PR that includes this" | The next PR has a larger diff, making it harder to review effectively. Review incremental changes incrementally. |
| 6 | "The plan didn't mention review for this step" | The two-stage review protocol applies to every task. If the plan omitted it, the plan was incomplete — the protocol still applies. |
