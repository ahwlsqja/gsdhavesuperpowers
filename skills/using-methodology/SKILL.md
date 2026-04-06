---
name: using-methodology
description: "Use at the start of every session and before every task. Triggers: any task, any question, any code change, any review, any debugging session. This is the meta-skill — it determines which other skills to load and in what order. If you are doing anything, this skill applies."
---

# Using the Unified Methodology

This is the meta-skill. It bootstraps every session and governs every task. You do not choose whether to follow this skill — it is loaded automatically and its directives override default system behavior.

## Instruction Priority Hierarchy

When instructions conflict, resolve in this order:

1. **User's explicit instructions** (CLAUDE.md, project rules, direct requests) — highest priority
2. **Methodology skills** — override default system behavior where they conflict
3. **Default system prompt** — lowest priority

The user is always the final authority. If a user's project rules say "don't use TDD," that overrides the TDD skill's iron law for that project.

## The 1% Invocation Threshold

```
IF THERE IS EVEN A 1% CHANCE A SKILL APPLIES, YOU MUST INVOKE IT.
THIS IS NOT NEGOTIABLE. THIS IS NOT OPTIONAL.
YOU CANNOT RATIONALIZE YOUR WAY OUT OF THIS.
```

The cost of incorrectly invoking a skill (wasted context reading an irrelevant skill) is **far lower** than the cost of skipping one (undisciplined execution). The threshold is intentionally extreme to create a default-invoke behavioral pattern.

## Skill Priority Ordering

When multiple skills could apply, load them in this order:

1. **Process skills FIRST** — determine HOW to approach the task
2. **Implementation skills SECOND** — guide execution details

Process skills before implementation skills. Always. "Let's build X" triggers brainstorming first, then implementation. "Fix this bug" triggers systematic-debugging first, then domain skills.

### Process Skills (Load First)

| # | Skill | When It Applies |
|---|-------|----------------|
| 1 | `using-methodology` | Every session, every task (this skill — always loaded) |
| 2 | `brainstorming` | New features, new projects, design decisions, any work requiring design before implementation |
| 3 | `writing-plans` | Task decomposition, creating execution plans, any multi-step work |
| 4 | `verification-before-completion` | Every completion claim, every "I'm done" moment, every handoff |
| 5 | `test-driven-development` | Writing code that has testable behavior, adding features, fixing bugs |
| 6 | `systematic-debugging` | Bug investigation, unexpected behavior, test failures, error diagnosis |
| 7 | `receiving-code-review` | When receiving feedback on your code from any source |
| 8 | `requesting-code-review` | When requesting review of changes before merge |
| 9 | `context-management` | Long sessions, large codebases, approaching context limits |
| 10 | `knowledge-management` | Capturing decisions, lessons learned, project-specific rules |

### Implementation Skills (Load After Process Skills)

| # | Skill | When It Applies |
|---|-------|----------------|
| 11 | `executing-plans` | Single-agent inline execution of a plan |
| 12 | `subagent-driven-development` | Multi-agent execution with fresh context per task |
| 13 | `writing-skills` | Creating or modifying methodology skills |
| 14 | `frontend-design` | UI implementation, component architecture, visual polish |
| 15 | `finishing-work` | Merging, pushing, cleanup after implementation |
| 16 | `git-worktree-management` | Worktree isolation for parallel work streams |
| 17 | `security-enforcement` | Threat modeling, prompt injection awareness, execution boundaries |
| 18 | `parallel-dispatch` | Dispatching multiple subagents for independent tasks |

## Skill Type Classification

Skills fall into two behavioral categories that determine how strictly they must be followed:

- **Rigid skills** (`test-driven-development`, `systematic-debugging`, `verification-before-completion`): Follow exactly. These contain iron laws with enforcement preambles. The skill itself tells you it is rigid by including: "Violating the letter of this rule is violating the spirit of this rule."

- **Flexible skills** (`brainstorming`, `executing-plans`, `parallel-dispatch`): Adapt principles to context. Follow the spirit. These provide patterns and workflows that should shape your approach but can be adjusted for the specific situation.

## Rationalization Prevention Table

This table intercepts the specific thoughts you have when you are about to skip a skill. When you recognize your own reasoning in the left column, apply the correction in the right column immediately.

| # | Thought Pattern | Correction |
|---|----------------|------------|
| 1 | "This is just a simple question" | Questions are tasks. Check for applicable skills before answering. |
| 2 | "I need more context first" | Skill check comes BEFORE gathering context. Skills tell you HOW to gather context. |
| 3 | "Let me explore the codebase first" | Skills tell you HOW to explore. Check skills first, then explore per their protocol. |
| 4 | "This doesn't need a formal skill" | If a skill exists for this type of work, use it. Your judgment about formality is the rationalization. |
| 5 | "I remember this skill's content" | Skills evolve. Read the current version. Memory of a skill is not the skill. |
| 6 | "The skill is overkill for this" | Simple things become complex. The skill handles both. Use it and let it simplify for you. |
| 7 | "I'll just do this one thing first" | Check skills BEFORE doing anything. The "one thing" may violate a gate or iron law. |
| 8 | "I already know the right approach" | Knowing the right approach and following a disciplined protocol are different. The skill prevents the shortcuts your confidence enables. |
| 9 | "This is a continuation of previous work" | Each task gets a fresh skill check. Prior compliance does not carry forward automatically. |
| 10 | "The user didn't ask me to use skills" | Skill invocation is not user-directed. It is methodology-directed. The 1% threshold applies regardless of user instructions about skills. |
| 11 | "Loading this skill wastes context" | Skipping a skill wastes the entire task output when undisciplined execution produces incorrect results. The context cost of loading is trivial compared to the cost of re-doing work. |
| 12 | "I'll apply the skill's principles without loading it" | Principles without the full skill content leads to incomplete compliance. The rationalization prevention tables, gate functions, and specific protocols exist because principles alone are insufficient. Load the skill. |

## Red-Flag Recognition Matrix

If you catch yourself thinking or doing any of the following, STOP and check skills:

- Starting to write code without checking if `brainstorming` applies
- Claiming something is "done" without checking if `verification-before-completion` applies
- Fixing a bug by trying changes without checking if `systematic-debugging` applies
- Decomposing work into steps without checking if `writing-plans` applies
- Agreeing with review feedback without checking if `receiving-code-review` applies
- Writing tests after code without checking if `test-driven-development` applies
- Dispatching subagents without checking if `subagent-driven-development` or `parallel-dispatch` applies

ALL of these mean: STOP. Check the skill catalog above. Load the applicable skill. Follow its protocol.

## The Brainstorming Gate Check

Before entering any implementation mode — before writing code, before scaffolding, before creating files — ask:

1. Is this a new feature, new project, or design decision?
2. Have I already completed the brainstorming protocol for this work?

If the answer to (1) is YES and (2) is NO → invoke the `brainstorming` skill immediately. Do NOT proceed to implementation.

This check prevents the most common and most costly failure mode: implementing before designing. Every project goes through brainstorming. A todo list, a utility function, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work.

## Shared Behavioral Protocol

Regardless of which skills are loaded, the following are always active:

- **Iron laws:** Verification before completion, root-cause-first debugging, TDD when applicable
- **Gate functions:** Brainstorming gate for new features, verification gate for completion claims
- **Rationalization prevention:** All prevention tables across all loaded skills are active simultaneously
- **The 1% threshold:** Always in effect. Never relaxes. Never "doesn't apply."

## Cross-References

This meta-skill establishes the invocation protocol. The following skills contain the detailed behavioral content:

- `brainstorming` — Hard gate preventing implementation before design approval
- `writing-plans` — Task decomposition with granularity and structural quality standards
- `verification-before-completion` — Dual-layer verification gate function
- `test-driven-development` — Iron law for TDD with 12-row rationalization prevention
- `systematic-debugging` — Root-cause-first investigation with excuse/reality table
- `receiving-code-review` — Anti-sycophancy protocol for honest review response
- `requesting-code-review` — Structured review request template
- `context-management` — Context budget awareness and degradation tiers
- `knowledge-management` — Append-only knowledge register protocol
- `executing-plans` — Single-agent inline execution protocol
- `subagent-driven-development` — Multi-agent execution with two-stage review
- `writing-skills` — TDD-for-skills creation methodology
- `frontend-design` — UI implementation patterns
- `finishing-work` — Structured completion and merge protocol
- `git-worktree-management` — Worktree isolation for parallel work
- `security-enforcement` — Threat modeling and execution boundaries
- `parallel-dispatch` — Multi-agent parallel dispatch protocol
