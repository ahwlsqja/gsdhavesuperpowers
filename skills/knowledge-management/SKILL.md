---
name: knowledge-management
description: "Use when capturing decisions, lessons learned, project-specific rules, recurring gotchas, or any discovery that should survive the current session. Triggers: 'that's good to know', 'we should remember this', 'let me write that down', discovering a non-obvious rule, making an architectural decision, hitting a recurring issue, any moment where knowledge would prevent future agents or sessions from repeating your investigation. If you learned something that matters beyond this session, invoke this skill."
---

# Knowledge Management

## Core Principle: Knowledge Must Be Persistent and Structured

Knowledge that exists only in your context window dies when the session ends. Every non-obvious discovery, every architectural decision, every recurring gotcha — if it's not written to disk in a structured format, it will be re-discovered from scratch in the next session. This re-discovery is not just wasteful; it's actively harmful when the re-discovery reaches a different conclusion than the original, creating inconsistent code.

Knowledge management is not documentation. Documentation explains what exists. Knowledge management captures what was learned — the rules, patterns, and constraints that are invisible in the code itself but critical for working with it correctly.

## The Append-Only KNOWLEDGE.md Protocol

KNOWLEDGE.md is the project's learning register. It follows one absolute rule:

```
APPEND ONLY. NEVER EDIT OR DELETE EXISTING ENTRIES.
```

### Why Append-Only

1. **Accidental deletion prevention.** If editing is allowed, a well-intentioned cleanup can destroy knowledge that a future session desperately needs. The cost of a redundant entry is a few lines of text. The cost of a missing entry is hours of re-investigation.

2. **Historical context.** Even superseded knowledge has value — it explains why the codebase evolved the way it did. "K003 supersedes K001" tells a story. Deleting K001 erases that story.

3. **Conflict detection.** If two entries contradict each other, that contradiction is signal — it means something changed between the two discoveries. Editing the first to match the second hides this signal.

### When Entries Are Wrong

When a knowledge entry is discovered to be incorrect or outdated:

- **Do not edit the original entry.**
- **Add a new entry** that explicitly supersedes it: "K015 supersedes K003 — the ESM loader issue from K003 was resolved in Node 22.x. The `--experimental-vm-modules` flag is no longer required."
- The superseding entry provides both the new knowledge and the historical context of what changed.

### Entry Format

Every KNOWLEDGE.md entry follows this structure:

```markdown
## K[NNN]: [Short descriptive title]

**When:** [Date or session identifier]
**Context:** [What were you doing when you discovered this?]
**Rule/Pattern:** [The concrete, actionable rule. Specific enough that an agent with zero context can follow it.]
**Why it matters:** [What goes wrong if this rule is ignored? Be specific — name the error, the failure mode, or the wasted time.]
```

### What Makes a Good Entry

A good KNOWLEDGE.md entry passes the **zero-context test**: an agent that has never seen this codebase should be able to read the entry and immediately act on it without needing to investigate further.

| Good Entry | Bad Entry | Why |
|-----------|-----------|-----|
| "Tests must run with `--experimental-vm-modules` because the project uses ESM imports in test files. Without this flag: `ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING`" | "Tests need a special flag" | Good: names the flag, explains the trigger, gives the exact error. Bad: unactionable. |
| "The `user.profile` field is guaranteed non-null after auth middleware. Don't add null checks — they create unreachable error paths that confuse future readers." | "Profile is always there" | Good: names the field, explains the guarantee source, explains the harm of violation. Bad: vague, no actionable guidance. |
| "PostgreSQL connections use pool `db/pool.ts`. Max 10 connections. Creating direct connections outside the pool causes connection exhaustion under load." | "Use the connection pool" | Good: names the file, states the limit, describes the failure mode. Bad: no specifics. |

### What Does NOT Belong in KNOWLEDGE.md

- **Obvious things.** "JavaScript uses `===` for strict equality" — not project-specific.
- **Implementation details that are clear from the code.** "The UserService has a `getById` method" — read the code.
- **Temporary workarounds without context.** "Added a `setTimeout(100)` to fix the race condition" — this belongs in a code comment with a TODO, not in the knowledge register.
- **Opinion without evidence.** "I think we should use React Query" — this belongs in DECISIONS.md if it's been decided, or in a design discussion if it hasn't.

## The DECISIONS.md Convention

Decisions are a specific category of knowledge with their own register. Use DECISIONS.md for architectural choices, technology selections, and design tradeoffs — anything where the *rationale* is as important as the *choice*.

### Decision Format

```markdown
| # | When | Scope | Decision | Choice | Rationale | Revisable? |
|---|------|-------|----------|--------|-----------|------------|
| D001 | [date] | [scope] | [what was decided] | [what was chosen] | [why this choice over alternatives] | [yes/no + conditions] |
```

### Decision vs. Knowledge

| If you're recording... | Use... | Because... |
|----------------------|--------|------------|
| A choice between alternatives with tradeoffs | DECISIONS.md | The rationale and revisability matter for future decision-making |
| A discovered rule or pattern about how the codebase works | KNOWLEDGE.md | This is a fact about the system, not a choice |
| A gotcha or non-obvious requirement | KNOWLEDGE.md | This is a constraint discovery, not a design choice |
| A technology selection | DECISIONS.md | Future sessions need to know WHY to evaluate if the choice is still valid |
| A debugging discovery about system behavior | KNOWLEDGE.md | This is empirical knowledge about how things work |

### Append-Only for Decisions Too

The same append-only rule applies to DECISIONS.md. To reverse a decision, add a new row that supersedes it:

```markdown
| D012 | 2026-04-05 | database | Supersedes D003: Switch from SQLite to PostgreSQL | PostgreSQL | Concurrent access patterns exceed SQLite's write-lock capabilities. See K008 for the evidence. | Yes — if concurrency drops below threshold |
```

## Structured Hindsight Annotations

When completing a task, capture what you would have done differently with the knowledge you now have. This is the "hindsight note" pattern — it transforms completed work into learning artifacts.

### When to Write Hindsight Annotations

- After completing a task that required significant investigation
- After debugging a problem that took more than 3 attempts to resolve
- After discovering that an approach you chose was suboptimal
- After a review reveals issues you should have caught

### Hindsight Format

```markdown
## Hindsight: [task or context identifier]

**What happened:** [Brief description of the situation]
**What I'd do differently:** [Specific alternative approach with reasoning]
**Time cost of the suboptimal approach:** [Estimate — "30 minutes debugging a race condition that a connection pool would have prevented"]
**Applicable pattern:** [If this generalizes, state the general rule]
```

Hindsight annotations are appended to KNOWLEDGE.md as regular entries. They follow the same append-only protocol.

## Drift Detection Guidance

Knowledge entries can become stale as the codebase evolves. A knowledge entry that was correct at the time of writing may become misleading after a refactoring. Drift detection is the practice of identifying and flagging stale knowledge.

### When to Check for Drift

1. **At session start** — Scan KNOWLEDGE.md for entries related to the current task. Spot-check that the referenced files, functions, and patterns still exist.
2. **After major refactoring** — If you've significantly restructured code, scan KNOWLEDGE.md for entries that reference the changed areas.
3. **When knowledge contradicts observation** — If you observe behavior that contradicts a knowledge entry, investigate. Either the entry is stale or your observation is wrong. Both cases require resolution.

### Drift Response Protocol

When drift is detected:

1. **Verify the drift.** Don't assume — check that the entry is actually stale, not that your understanding is incomplete.
2. **Add a superseding entry.** Following the append-only protocol, add a new entry that corrects the stale information and explicitly references the original.
3. **Note the drift pattern.** If the same type of drift recurs (e.g., file paths changing due to repeated restructuring), add a meta-entry about the pattern: "K045: File paths in knowledge entries are fragile across refactorings. Reference functions by name rather than path where possible."

## State-Tier-Aware Behavior

Knowledge management behavior adapts based on the active state tier:

### Tier 0 — Stateless

No persistent knowledge files exist. Knowledge discovered during the session is lost when the session ends.

**Your responsibility:**
- If you discover something non-obvious, suggest to the human that the project should adopt Tier 1 to capture it
- If the human declines, include the knowledge in your response so the human can decide whether to record it elsewhere (README, code comments, documentation)
- Do not create `.gsd/` or KNOWLEDGE.md on your own — tier escalation is a developer decision

### Tier 1 — Lightweight

KNOWLEDGE.md and DECISIONS.md exist. You can append to them directly.

**Your responsibility:**
- Append entries in the correct format (structured, zero-context-readable)
- Follow the append-only protocol — never edit existing entries
- Check for existing entries before adding duplicates
- Keep entries concise — KNOWLEDGE.md should not become a second codebase README

### Tier 2 — Full Orchestration

Full knowledge infrastructure exists. KNOWLEDGE.md + DECISIONS.md + structured summaries + milestone artifacts.

**Your responsibility:**
- Same as Tier 1 for KNOWLEDGE.md and DECISIONS.md
- Also write structured hindsight annotations in task summaries
- Cross-reference knowledge entries with milestone/slice/task identifiers when relevant
- Flag knowledge that should be escalated to hot-tier context (iron-law-level importance)

## Rationalization Prevention Table

| # | Thought Pattern | Correction |
|---|----------------|------------|
| 1 | "I'll remember this for later" | No you won't. Your context window will be reset. Write it down now. |
| 2 | "This is too minor to record" | If it took you more than 2 minutes to discover, it's not minor. Future sessions will spend those same 2+ minutes. |
| 3 | "The code is self-documenting" | The code documents WHAT. Knowledge entries document WHY and WHEN and WHAT GOES WRONG. These are different. |
| 4 | "I'll write a better entry later" | You'll forget the details. A rough entry now is infinitely more valuable than a perfect entry never written. |
| 5 | "This only matters for this session" | You don't know that. If it mattered enough to notice, it matters enough to record. |
| 6 | "Someone already knows this" | Not every agent in every future session knows this. Write it for the agent that doesn't. |
| 7 | "The knowledge register is getting long" | Long is fine. Correct is required. Growth means the project is accumulating understanding. Trim through consolidation reviews, never through deletion. |
| 8 | "I should edit K003 instead of adding a new entry" | Append-only. Add a new entry that supersedes K003. Don't edit. |
