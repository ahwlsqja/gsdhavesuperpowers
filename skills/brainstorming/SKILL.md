---
name: brainstorming
description: "Use when starting a new feature, new project, design decision, or any work that requires design before implementation. Triggers: 'build X', 'create X', 'add feature', 'new project', 'redesign', 'refactor architecture', any request that implies building something new. If there is even a 1% chance the work needs design exploration first, invoke this skill."
---

# Brainstorming

## Hard Gate

```
DO NOT invoke any implementation skill, write any code, scaffold any project,
or take any implementation action until you have presented a design and
the user has approved it.

This applies to EVERY project regardless of perceived simplicity.
```

This is a **hard gate** — a structural barrier in the methodology pipeline. No exceptions. No "just this once." No "it's too simple to need design."

**Gate violation = lying.** If you skip this gate, you are not "saving time" or "being efficient." You are lying about the readiness of your implementation — building on assumptions that have not been examined, validated, or approved. Every project that skips design and "turns out fine" teaches the wrong lesson. Every project that skips design and fails wastes all the implementation time.

## Why Every Project Needs This

Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work because:

- You assume the user wants X, but they want Y
- You assume the existing architecture supports your approach, but it doesn't
- You assume the scope is small, but edge cases expand it
- You assume requirements are clear, but ambiguity hides in the gaps

The brainstorming protocol surfaces these assumptions before you invest implementation time in them.

## The 9-Step Design Exploration Protocol

Complete these steps in order. Do not skip steps. Do not reorder steps.

### Step 1: Explore Project Context

Before proposing anything, understand what exists:

- Read the project structure, existing code, and conventions
- Identify constraints from the technology stack
- Note existing patterns that the design should follow
- Understand the user's goals from their request and any project documentation

### Step 2: Offer Visual Companion (When Applicable)

For UI work, offer to create a visual reference:

- Mockup, wireframe, or diagram that illustrates the proposed approach
- This is NOT implementation — it is a communication tool for design alignment
- Skip this step for non-visual work (APIs, backend logic, configuration)

### Step 3: Ask Clarifying Questions

Ask questions one at a time. Prefer multiple-choice when possible.

- Each question targets a specific ambiguity or decision point
- Do NOT batch all questions together — ask, wait for answer, then ask the next
- Frame questions around tradeoffs: "Option A gives us X at the cost of Y; Option B gives us Y at the cost of X. Which matters more for your case?"
- Stop when you have enough clarity to propose approaches. Do not over-question.

### Step 4: Propose 2–3 Approaches with Tradeoffs

Present concrete approaches, not abstract options:

- Each approach has a name, a one-sentence summary, and explicit tradeoffs
- Tradeoffs are honest — every approach has downsides. State them clearly.
- Include a recommendation with rationale, but do not assume the user will accept it
- If only one reasonable approach exists, state that with reasoning for why alternatives were considered and rejected

### Step 5: Present Design in Sections Scaled to Complexity

Scale the design document to the complexity of the work:

- **Simple work** (1–3 files, clear scope): Brief description of approach, key decisions, file list
- **Medium work** (4–10 files, some ambiguity): Structured design with sections for each component, data flow, and integration points
- **Complex work** (10+ files, significant ambiguity): Full design specification with architecture diagrams, component contracts, data flow, error handling strategy, and phased implementation plan

### Step 6: Write Design Document

Write the design to a persistent location so it survives context resets:

- Location: `docs/specs/YYYY-MM-DD-<topic>-design.md` (or project-specific spec directory)
- The spec is the source of truth for what was agreed. Implementation must match it.
- Include: problem statement, chosen approach with rationale, component breakdown, key decisions with reasoning, open questions (if any remain)

### Step 7: Design Self-Review

Before presenting the spec to the user, review it yourself:

- **Placeholder scan:** Search for "TBD," "TODO," "to be determined," "placeholder," "will be defined later." Every one of these is an unresolved design decision. Resolve them or flag them explicitly as open questions.
- **Internal consistency:** Do component names match across sections? Do data types align at boundaries? Do error handling strategies cover all integration points?
- **Scope check:** Does the design match the user's request, or has it grown? If it has grown, justify the additions or trim back.
- **Ambiguity check:** Could two different developers read this spec and build different things? If yes, the ambiguous sections need more specificity.

### Step 8: User Reviews Written Spec

Present the written spec to the user for approval. This is the gate condition.

- The user may approve as-is, request changes, or reject the approach
- If changes are requested, revise the spec and re-present
- If rejected, return to Step 4 with new approaches informed by the rejection
- **Do NOT proceed past this step without explicit user approval**

### Step 9: Transition to Planning

The terminal state of brainstorming is invoking the `writing-plans` skill.

- Do NOT invoke `frontend-design`, `executing-plans`, `subagent-driven-development`, or any other implementation skill directly from brainstorming
- The ONLY skill you invoke after brainstorming is `writing-plans`
- The design spec becomes the input to the planning phase

## Sub-Project Decomposition

If the request describes multiple independent subsystems, flag this immediately:

- Do NOT spend questions refining details of a project that needs decomposition first
- Present the decomposition: "This project has N independent subsystems. I recommend brainstorming each separately."
- Get user agreement on the decomposition before diving into any subsystem
- Each sub-project goes through its own brainstorming cycle

## Rationalization Prevention Table

| # | Thought Pattern | Correction |
|---|----------------|------------|
| 1 | "This is too simple to need design" | Simple projects are where unexamined assumptions waste the most time. Brainstorm it. |
| 2 | "I already know what to build" | Knowing what to build and having the user validate your understanding are different things. Present the design. |
| 3 | "The user just wants it done quickly" | Building the wrong thing quickly wastes more time than 10 minutes of design. Brainstorm first, then build fast. |
| 4 | "The requirements are completely clear" | Requirements that seem clear often hide ambiguity in edge cases, error handling, and integration points. The brainstorming protocol surfaces these. |
| 5 | "I'll figure out the design as I code" | Emergent design works for experts in familiar domains. For AI agents working in unfamiliar codebases, upfront design prevents costly backtracking. |
| 6 | "This is just a bug fix, not a feature" | Bug fixes that change behavior need design validation. If the fix is truly mechanical (typo, off-by-one), brainstorming is fast. If it is not, you need it. |
| 7 | "The user already told me exactly what they want" | What the user said and what the user meant may differ. The design step confirms alignment before you invest implementation time. |
| 8 | "I can always refactor later" | Refactoring is rework. Design prevents rework. The cost of design is always less than the cost of redesign. |

## What This Skill Does NOT Do

- It does NOT write code
- It does NOT create files (except the design spec document)
- It does NOT make implementation decisions (those happen in planning)
- It does NOT scaffold projects
- It does NOT invoke implementation skills

Brainstorming produces ONE output: an approved design specification. Everything else happens in downstream skills.

## Anti-Pattern: Skipping Brainstorming for "Implementation-Only" Tasks

Even tasks that seem purely implementational benefit from a brief design check:

- "Add a button" → Where? What does it do? What state does it affect? What happens on error?
- "Create an API endpoint" → What is the contract? What are the error responses? How does auth work?
- "Write a migration" → What data transforms? What is the rollback strategy? What about existing data?

If the answers are truly obvious (< 1 minute to confirm), brainstorming is fast. If they are not obvious, you just proved why brainstorming is needed.
