# Superpowers Architecture Analysis

A deep analysis of Superpowers (v5.0.7) — a behavioral shaping system that controls AI agent quality through carefully-tuned prose directives embedded as skill documents. Where GSD provides programmatic infrastructure for agent orchestration, Superpowers provides the psychology of agent compliance — iron laws, rationalization prevention tables, red-flag matrices, and TDD-adapted skill testing.

---

## 1. Design Philosophy

Superpowers operates from a fundamentally different premise than most AI agent tooling. Rather than constraining agents programmatically through code-level guardrails, it shapes agent behavior through carefully-tuned natural language directives. The system treats skills as "code that shapes agent behavior" — not documentation, not guidelines, but executable behavioral specifications that must be tested with the same rigor as production code.

The contributor guidelines (`CLAUDE.md`, `AGENTS.md`) make this philosophy explicit with extraordinary bluntness: the repo has a "94% PR rejection rate" and the maintainers close low-quality PRs with public comments like "This pull request is slop that's made of lies." PRs that restructure or reword skills to "comply" with Anthropic's published skill-writing guidance are rejected without extensive eval evidence, because "our internal skill philosophy differs from Anthropic's published guidance." The bar for modifying behavior-shaping content is very high — skills are treated as tuned instruments, not prose.

Three principles define the system:

1. **Zero Dependencies** — `package.json` contains only `name`, `version`, `type`, and `main`. No dependencies, no devDependencies, no build step. The entire system is 14 skill files, 1 agent, 3 commands, 1 hook script, and platform manifests. This is a deliberate architectural choice reinforced in contributor guidelines: "Superpowers is a zero-dependency plugin by design."

2. **Human Partner Framing** — The system consistently uses "your human partner" instead of "the user" throughout all skills. This is explicitly documented as a deliberate, non-interchangeable terminology choice. The framing positions the agent as a collaborative partner rather than a tool serving commands, which shapes how agents interpret and respond to instructions.

3. **Behavioral Testing Over Static Analysis** — Skills are validated through adversarial pressure testing with subagents, not through human review or structural linting. The `writing-skills` skill adapts TDD methodology to skill creation: write pressure scenarios (tests), run them without the skill (watch them fail), write the skill (production code), verify agents comply (watch them pass), then close loopholes (refactor).

---

## 2. Skill System Architecture

### The Meta-Skill: `using-superpowers`

The entire skill system bootstraps from a single meta-skill (`skills/using-superpowers/SKILL.md`) that establishes the invocation protocol. This skill is injected at session start via the `hooks/session-start` bash script, which reads the using-superpowers content, JSON-escapes it, and outputs it as `additionalContext` in the platform-appropriate format (nested `hookSpecificOutput` for Claude Code, `additional_context` for Cursor, top-level `additionalContext` for Copilot CLI and others).

The meta-skill's core behavioral mandate uses typographic emphasis as a compliance mechanism:

> "If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill. IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT. This is not negotiable. This is not optional. You cannot rationalize your way out of this."

This creates a default-invoke behavioral pattern — the cost of incorrectly invoking a skill (wasted context reading an irrelevant skill) is far lower than the cost of skipping one (undisciplined execution), so the 1% threshold biases heavily toward invocation.

### Skill Loading Protocol

The meta-skill defines a priority hierarchy for instruction resolution:

1. **User's explicit instructions** (CLAUDE.md, GEMINI.md, AGENTS.md, direct requests) — highest priority
2. **Superpowers skills** — override default system behavior where they conflict
3. **Default system prompt** — lowest priority

This hierarchy is critical because it means Superpowers positions itself as a middle layer — it overrides platform defaults but never overrides the user. A user's CLAUDE.md saying "don't use TDD" takes precedence over the TDD skill's iron law.

### Skill Type Classification

Skills are classified into two behavioral categories that determine how strictly they must be followed:

- **Rigid skills** (TDD, systematic-debugging, verification-before-completion): Follow exactly. These are discipline-enforcing skills with iron laws, rationalization prevention tables, and red-flag matrices. The skill itself tells you it is rigid by including language like "Violating the letter of the rules is violating the spirit of the rules."

- **Flexible skills** (brainstorming, dispatching-parallel-agents): Adapt principles to context. These provide patterns and workflows that should be followed in spirit but can be adjusted to fit the specific situation.

### Skill Priority Ordering

When multiple skills could apply, the meta-skill establishes execution ordering:

1. **Process skills first** (brainstorming, systematic-debugging) — determine HOW to approach the task
2. **Implementation skills second** (frontend-design, mcp-builder) — guide execution details

This ordering prevents a common agent failure mode: jumping directly to implementation without design or investigation. "Let's build X" triggers brainstorming first, then implementation skills. "Fix this bug" triggers systematic-debugging first, then domain-specific skills.

### The Red Flags Table

The meta-skill contains a 12-row rationalization prevention table — a behavioral mechanism designed to intercept the specific thoughts an agent has when it is about to skip a skill:

| Thought Pattern | Counter |
|----------------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |

Each row targets a specific rationalization pattern observed in real agent sessions. The table works as a lookup — when the agent recognizes its own thought in the left column, the right column provides the corrective behavior.

---

## 3. Behavioral Shaping Mechanisms

Superpowers uses five distinct behavioral shaping mechanisms across its skills. These are the core technical innovation of the system — the mechanisms by which prose directives achieve reliable behavioral compliance.

### Iron Laws

Three skills define absolute behavioral constraints using the "Iron Law" pattern — a single-sentence imperative rendered in a code block for visual emphasis:

- **TDD:** `NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST`
- **Systematic Debugging:** `NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST`
- **Verification Before Completion:** `NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE`

Each iron law is accompanied by an enforcement preamble: "Violating the letter of this rule is violating the spirit of this rule." This single sentence preemptively closes the most common agent escape hatch — the "I'm following the spirit" rationalization that allows agents to technically comply while fundamentally violating the constraint.

The iron laws also specify explicit remediation for violations. TDD's response to code-before-test: "Delete it. Start over. No exceptions: Don't keep it as 'reference'. Don't 'adapt' it while writing tests. Don't look at it. Delete means delete." The enumeration of specific evasion tactics ("keep as reference," "adapt while writing tests") reveals that these were observed in real agent behavior and plugged one by one.

### Rationalization Prevention Tables

Seven skills contain explicit rationalization prevention tables — two-column tables mapping specific excuses to corrections. These are the behavioral equivalent of unit tests: each row captures a failure mode observed in real agent sessions and provides the corrective response.

The `systematic-debugging` skill contains an 8-row table:

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |

The `verification-before-completion` skill contains an 8-row table with entries like:

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Different words so rule doesn't apply" | Spirit over letter |

The `test-driven-development` skill contains a 12-row table — the largest — covering sophisticated rationalizations like "Tests after achieve same goals" (countered with "Tests-after = 'what does this do?' Tests-first = 'what should this do?'") and "Deleting X hours of work is wasteful" (countered with "Sunk cost fallacy. Keeping unverified code is technical debt.").

The mechanism works because it transforms a vague behavioral guideline ("follow TDD") into a lookup table that the agent can match against its own internal reasoning. When the agent is about to rationalize, the table intercepts the specific thought pattern and replaces it with the corrective behavior.

### Red-Flag Matrices

Distinct from rationalization tables, red-flag matrices are lists of observable behavioral symptoms that indicate a process violation is in progress. The `systematic-debugging` skill lists 12 red flags:

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "It's probably X, let me fix that"
- "Pattern says X but I'll adapt it differently"
- "One more fix attempt" (when already tried 2+)

Each entry ends with: "ALL of these mean: STOP. Return to Phase 1." The matrix functions as a self-diagnostic checklist — the agent scans its own reasoning against the list and, upon recognizing a match, interrupts the current action.

The `verification-before-completion` skill adds a temporal dimension: red flags include "Using 'should', 'probably', 'seems to'" — intercepting not just actions but specific language patterns in the agent's own output that signal it is about to make an unverified claim.

### Hard Gates

The `brainstorming` skill implements a hard gate — a structural barrier that prevents progression past a specific point without meeting a condition:

> "Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity."

This is reinforced with an anti-pattern section: "Every project goes through this process. A todo list, a single-function utility, a config change — all of them. 'Simple' projects are where unexamined assumptions cause the most wasted work."

The `verification-before-completion` skill implements a gate function as a 5-step checklist rendered in a code block:

```
1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
5. ONLY THEN: Make the claim
Skip any step = lying, not verifying
```

The framing of skipping as "lying" rather than "cutting corners" leverages the agent's strong alignment with honesty values to enforce the gate.

### Graphviz Flow Diagrams

Six skills embed `dot`-format graphviz diagrams that define decision flows as directed graphs. These serve as unambiguous process specifications that eliminate interpretation ambiguity.

The `test-driven-development` skill renders the Red-Green-Refactor cycle as a graph with explicit verify nodes at each transition:

```
red → verify_red → green (if yes) / red (if wrong failure)
green → verify_green → refactor (if yes) / green (if no)
refactor → verify_green → next → red
```

The `using-superpowers` meta-skill uses a flowchart to define the skill invocation decision tree, including the critical path for brainstorming checks ("About to EnterPlanMode?" → "Already brainstormed?" → invoke brainstorming skill).

The `subagent-driven-development` skill contains the most complex diagram — a full per-task lifecycle graph showing the implementer dispatch → question handling → spec review → code quality review → fix loop → re-review cycle.

---

## 4. Pipeline Architecture

### The Brainstorm → Plan → Execute → Review → Finish Pipeline

Superpowers defines a strict sequential pipeline for all feature development work. This pipeline is enforced through inter-skill references and hard gates, not programmatic sequencing.

**Phase 1: Brainstorm** (`brainstorming` skill)

A 9-step checklist that must be completed in order: explore project context → offer visual companion → ask clarifying questions (one at a time, multiple choice preferred) → propose 2-3 approaches with tradeoffs → present design in sections scaled to complexity → write design doc to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` → spec self-review (placeholder scan, internal consistency, scope check, ambiguity check) → user reviews written spec → transition to writing-plans skill.

The terminal state is explicitly constrained: "The terminal state is invoking writing-plans. Do NOT invoke frontend-design, mcp-builder, or any other implementation skill. The ONLY skill you invoke after brainstorming is writing-plans."

The skill includes a sub-project decomposition protocol for large scopes: "If the request describes multiple independent subsystems, flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first."

**Phase 2: Write Plans** (`writing-plans` skill)

Plans are written assuming "the engineer has zero context for our codebase and questionable taste." This phrase establishes the documentation bar — every plan must be self-contained and explicit.

Task granularity is specified as bite-sized (2-5 minutes per step), and each step follows a strict TDD template:
1. Write the failing test (with actual test code, not a description)
2. Run it to verify it fails (with exact command and expected output)
3. Implement minimal code (with actual implementation code)
4. Run tests to verify pass (with exact command)
5. Commit (with exact git commands)

The plan header template includes a required sub-skill reference: "REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task." This wires the next phase into the plan document itself.

A "No Placeholders" section enumerates specific plan failures: deferred-marker strings like "to be determined" or "to do," vague directives like "Add appropriate error handling," cross-references like "Similar to Task N" (with the counter: "repeat the code — the engineer may be reading tasks out of order"), and "Steps that describe what to do without showing how."

The self-review checklist covers spec coverage, placeholder scan, and type consistency across tasks — catching cases where a function is called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7.

**Phase 3: Execute** (`executing-plans` or `subagent-driven-development` skill)

Two execution modes are offered:

- **Inline execution** (`executing-plans`): Load plan → review critically → create TodoWrite per task → execute each step exactly → invoke `finishing-a-development-branch`. This skill explicitly notes it works "much better with access to subagents" and recommends `subagent-driven-development` when subagents are available.

- **Subagent-driven** (`subagent-driven-development`): Fresh subagent per task with a two-stage review after each (spec compliance review → code quality review). This is the recommended path.

**Phase 4: Review** (integrated into `subagent-driven-development`)

Two-stage review after each task:
1. **Spec compliance review** — Verify the implementer built what was requested, nothing more, nothing less. The spec reviewer prompt template includes: "The implementer finished suspiciously quickly. Their report may be incomplete, inaccurate, or optimistic. You MUST verify everything independently."
2. **Code quality review** — Verify the implementation is clean, tested, and maintainable. Only dispatched after spec compliance passes.

Review loops are enforced: "reviewer found issues = implementer fixes = review again. Don't skip the re-review."

**Phase 5: Finish** (`finishing-a-development-branch` skill)

A structured completion protocol: verify tests pass → present exactly 4 options (merge locally, push and create PR, keep as-is, discard) → execute the chosen option → clean up worktree. Discarding requires typed "discard" confirmation to prevent accidental data loss.

### Git Worktree Integration

The `using-git-worktrees` skill provides isolation infrastructure for the pipeline. It follows a systematic directory selection priority: check existing directories (`.worktrees/` preferred over `worktrees/`) → check CLAUDE.md for preferences → ask user.

A safety verification step uses `git check-ignore` to ensure worktree directories are in `.gitignore` before creation. If not ignored, the skill mandates adding the entry and committing — citing a project rule to "fix broken things immediately."

After worktree creation, the skill auto-detects the project type (package.json → npm install, Cargo.toml → cargo build, requirements.txt → pip install, go.mod → go mod download) and runs baseline tests to ensure a clean starting point.

---

## 5. Subagent Patterns

### Fresh Agent Per Task

The `subagent-driven-development` skill's core principle is: "Fresh subagent per task + two-stage review = high quality, fast iteration." Each implementer subagent gets:

- **Isolated context** — The subagent never inherits the coordinator's session history. The coordinator constructs exactly what context the subagent needs, providing the full task text directly rather than making the subagent read the plan file.
- **Complete task text** — All tasks are extracted from the plan upfront. The subagent receives the full task description, not a reference to read.
- **Scene-setting context** — Where the task fits in the overall architecture, what dependencies exist, and what architectural decisions are relevant.
- **Question protocol** — Subagents can ask questions before starting work. The coordinator must answer clearly and completely before letting them proceed.

### Model Selection by Complexity

The skill prescribes cost-optimal model selection:

- **Cheap/fast model**: Mechanical implementation tasks — isolated functions, clear specs, touching 1-2 files. "Most implementation tasks are mechanical when the plan is well-specified."
- **Standard model**: Integration and judgment tasks — multi-file coordination, pattern matching, debugging.
- **Most capable model**: Architecture, design, and review tasks — broad codebase understanding, design judgment.

### Four-Status Implementer Protocol

Implementer subagents report one of four statuses, each with a defined handling protocol:

- **DONE**: Proceed to spec compliance review.
- **DONE_WITH_CONCERNS**: Read concerns before proceeding. Correctness/scope concerns must be addressed; observational concerns (e.g., "this file is getting large") are noted and the process continues.
- **NEEDS_CONTEXT**: Provide missing context and re-dispatch with the same model.
- **BLOCKED**: Assess whether the blocker is a context problem (provide more context), a reasoning problem (re-dispatch with a more capable model), a scope problem (break into smaller pieces), or a plan problem (escalate to the human).

The red flag: "Never ignore an escalation or force the same model to retry without changes."

### Parallel Dispatch

The `dispatching-parallel-agents` skill covers when and how to run multiple subagents simultaneously. The decision criteria are explicit:

- **Use when**: 3+ independent problems, no shared state, each can be understood in isolation.
- **Don't use when**: Failures are related, need full system state, or agents would interfere (editing same files, same resources).

Agent prompts follow a specific structure: focused scope (one test file or subsystem), clear goal (make these tests pass), constraints (don't change other code), and expected output (summary of findings and fixes).

### Code Review Protocol

Two complementary skills define a two-sided review protocol:

**Requesting reviews** (`requesting-code-review`): The requesting skill provides a structured template requiring git SHAs (base and head), the plan/requirements being verified against, and a description of what was implemented. Reviews are mandatory after each task in subagent-driven development, after completing major features, and before merge to main.

**Receiving reviews** (`receiving-code-review`): This skill addresses a specific agent behavioral failure — sycophantic agreement. It explicitly forbids responses like "You're absolutely right!", "Great point!", and "Thanks for catching that!" Instead, agents must: restate the technical requirement in their own words, verify against codebase reality, evaluate whether the suggestion is technically sound for THIS codebase, and push back with technical reasoning when the reviewer is wrong.

The skill includes a YAGNI check: when a reviewer suggests "implementing properly," the agent should grep the codebase for actual usage. If nothing calls the endpoint, the response is: "This endpoint isn't called. Remove it (YAGNI)?"

The push-back protocol includes an escape hatch for discomfort: "Signal if uncomfortable pushing back out loud: 'Strange things are afoot at the Circle K'" — a cultural reference that serves as a code phrase for agents that find it difficult to disagree with reviewer authority.

---

## 6. Quality Methodology

### TDD-for-Skills

The `writing-skills` skill adapts Test-Driven Development methodology to skill creation. This is the most sophisticated behavioral shaping mechanism in the system — it treats skills themselves as code that must be tested.

The TDD mapping:

| TDD Concept | Skill Equivalent |
|-------------|-----------------|
| Test case | Pressure scenario with subagent |
| Production code | Skill document (SKILL.md) |
| Test fails (RED) | Agent violates rule without skill |
| Test passes (GREEN) | Agent complies with skill present |
| Refactor | Close loopholes while maintaining compliance |

**RED phase**: Run pressure scenarios with subagents WITHOUT the skill loaded. Document the exact behavior — what choices agents make, what rationalizations they use (captured verbatim), which pressures triggered violations. This is "watching the test fail" — you must see what agents naturally do before writing the skill.

**GREEN phase**: Write the minimal skill that addresses those specific rationalizations. Don't add content for hypothetical cases. Run the same scenarios WITH the skill and verify agents now comply.

**REFACTOR phase**: The agent found a new rationalization not covered by the skill. Add an explicit counter. Re-test until bulletproof. Each iteration adds a row to the rationalization prevention table.

Pressure types include: time pressure, sunk cost ("I already wrote 100 lines"), authority pressure ("the reviewer said to skip it"), exhaustion ("this is the 5th iteration"), and combined pressures (multiple simultaneous pressure types).

### Claude Search Optimization (CSO)

The `writing-skills` skill contains a critical discovery about skill description fields: when a description summarizes the skill's workflow, agents may follow the description instead of reading the full skill content. Testing revealed that a description saying "code review between tasks" caused agents to do ONE review, even though the skill's flowchart specified TWO reviews (spec compliance then code quality).

The solution: descriptions must contain only triggering conditions ("Use when..."), never workflow summaries. This is a behavioral bug in AI agents that Superpowers explicitly documents and works around.

### Skill Type Testing

Different skill types require different test approaches:

- **Discipline-enforcing skills**: Academic questions (do they understand?), pressure scenarios (do they comply under stress?), combined pressures (time + sunk cost + exhaustion). Success: agent follows rule under maximum pressure.
- **Technique skills**: Application scenarios, variation scenarios, missing information tests. Success: agent successfully applies technique to new scenarios.
- **Pattern skills**: Recognition scenarios, application scenarios, counter-examples. Success: agent correctly identifies when/how to apply pattern.
- **Reference skills**: Retrieval scenarios, application scenarios, gap testing. Success: agent finds and correctly applies reference information.

### Verification Chain

The `verification-before-completion` skill closes the quality loop with an iron law derived from "24 failure memories." It establishes a gate function that must be executed before any claim of completion, and provides a Common Failures table mapping claims to their required evidence:

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Agent completed | VCS diff shows changes | Agent reports "success" |

The "Agent completed" row is noteworthy: it explicitly establishes that an agent's self-reported success is not evidence of completion. Independent verification of VCS diffs is required. This creates a recursive trust verification protocol — agents must verify other agents' claims rather than trusting them.

---

## 7. Distribution System

### Multi-Platform Plugin Architecture

Superpowers distributes as a single npm package (`superpowers@5.0.7`) with platform-specific manifests:

**Claude Code** (`.claude-plugin/plugin.json`): Standard Claude plugin manifest with name, description, version, author, homepage, repository, license, and keywords. The SessionStart hook (`hooks/hooks.json`) injects the using-superpowers skill content as additional context.

**Cursor** (`.cursor-plugin/plugin.json`): Extended manifest including explicit directory pointers: `"skills": "./skills/"`, `"agents": "./agents/"`, `"commands": "./commands/"`, `"hooks": "./hooks/hooks-cursor.json"`. The Cursor hooks file uses a simpler format: `{ "version": 1, "hooks": { "sessionStart": [{ "command": "./hooks/session-start" }] } }`.

**Gemini** (`gemini-extension.json`): Minimal manifest with `"contextFileName": "GEMINI.md"`. The `GEMINI.md` file force-loads the using-superpowers skill and a gemini-specific tool reference file via `@` syntax.

**OpenCode** (`.opencode/INSTALL.md`): Installation via `opencode.json` plugin array with git URL. Supports version pinning via git tags. The main entry point is `.opencode/plugins/superpowers.js` (referenced by `package.json`'s `main` field).

**Codex** (`.codex/INSTALL.md`): Clone and symlink-based installation. Skills are symlinked from `~/.codex/superpowers/skills` to `~/.agents/skills/superpowers` for native skill discovery.

### SessionStart Hook

The session-start hook (`hooks/session-start`) is a bash script that serves as the system's bootstrap mechanism. It:

1. Determines the plugin root directory from the script's location.
2. Checks for legacy skill directories (`~/.config/superpowers/skills`) and generates a migration warning if found.
3. Reads the using-superpowers skill content and JSON-escapes it using bash parameter substitution (explicitly noted as "orders of magnitude faster than the character-by-character loop this replaces").
4. Wraps the content in `<EXTREMELY_IMPORTANT>` tags with the framing: "You have superpowers."
5. Detects the platform by checking environment variables (`CURSOR_PLUGIN_ROOT`, `CLAUDE_PLUGIN_ROOT`, `COPILOT_CLI`) and outputs the JSON in the correct format for each platform.
6. Uses `printf` instead of heredoc "to work around bash 5.3+ heredoc hang" — a specific compatibility fix with an issue reference.

A cross-platform polyglot wrapper (`hooks/run-hook.cmd`) enables Windows compatibility. The file functions as both a batch script (cmd.exe runs the batch portion) and a bash script (the shell ignores the batch portion). On Windows, it searches for Git for Windows bash in standard locations before falling back to PATH.

### Zero-Dependency Philosophy

The `package.json` is striking in its minimalism: `{ "name": "superpowers", "version": "5.0.7", "type": "module", "main": ".opencode/plugins/superpowers.js" }`. No dependencies, no scripts, no devDependencies, no build configuration. The contributor guidelines enforce this: "PRs that add optional or required dependencies on third-party projects will not be accepted unless they are adding support for a new harness."

This zero-dependency approach means the entire system is portable — it can be installed on any platform that supports reading markdown files and running bash scripts. There is no build step, no compilation, no package resolution. The system's "runtime" is the AI agent itself, which reads the skill files and changes its behavior accordingly.

### Agent Definition

Superpowers ships exactly one agent: `code-reviewer` (`agents/code-reviewer.md`). It is defined as a "Senior Code Reviewer with expertise in software architecture, design patterns, and best practices." The agent performs plan alignment analysis, code quality assessment, architecture and design review, documentation standards checking, and issue identification with priority categorization (Critical/Important/Suggestions).

The agent definition uses `model: inherit` in its frontmatter, meaning it runs on whatever model the parent session is using rather than requiring a specific model tier.

### Commands

Three commands are defined in `commands/`, all deprecated in favor of skills:

- `brainstorm.md`: "Deprecated - use the superpowers:brainstorming skill instead"
- `execute-plan.md`: Deprecated equivalent for executing-plans skill
- `write-plan.md`: Deprecated equivalent for writing-plans skill

These represent the system's migration from command-based invocation to skill-based invocation — the behavioral content moved into skills that can be invoked across platforms, while the commands remain as legacy redirects.

---

## 8. Architectural Implications for Unified Methodology

### Mechanisms Worth Preserving

**Iron Laws with Rationalization Prevention**: The combination of an absolute behavioral constraint with a pre-enumerated table of excuses and their counters is the most effective behavioral shaping mechanism in the system. The tables are built empirically through adversarial testing, not theoretically. Each row represents a real evasion observed in agent behavior.

**TDD-for-Skills**: The insight that skills are code and must be tested like code — with red-green-refactor cycles, pressure testing, and loophole closure — provides a quality methodology for any behavioral directive system.

**Gate Functions**: The verification-before-completion gate function and the brainstorming hard gate demonstrate how to create structural barriers in prose-only systems. The framing of gate violations as "lying" rather than "shortcuts" is a specific behavioral lever.

**Anti-Sycophancy Protocol**: The receiving-code-review skill's explicit prohibition of performative agreement and its requirement for technical pushback addresses a fundamental agent behavioral failure. The specific forbidden phrases ("You're absolutely right!", "Great point!", "Thanks for catching that!") are precise targets derived from observed behavior.

**CSO Discovery**: The finding that skill descriptions should never summarize workflows (because agents will follow the summary instead of reading the full skill) is a fundamental discovery about AI agent behavior that affects any system using skill descriptions or tool descriptions.

### Mechanisms to Adapt

**Human Partner Framing**: The "your human partner" terminology is effective but may need adaptation in fully autonomous contexts where no human is present. The collaborative framing works well for interactive development but less so for batch processing.

**Plan Granularity**: The 2-5 minute task granularity in writing-plans is tuned for AI agent context management. This may need adjustment based on the specific agent's context window size and the complexity of the work.

**Model Selection**: The cheap/standard/capable model tier system is a cost optimization that assumes varying model capabilities. This needs to be adapted to whatever model portfolio is available in the unified system.

### Contrasts with GSD

Where GSD provides 21 agents, 60 workflows, and 16K lines of TypeScript SDK to orchestrate agent behavior programmatically, Superpowers achieves comparable behavioral control with 14 skill files and zero code. GSD constrains through infrastructure (file locks, state machines, verification pipelines). Superpowers constrains through psychology (iron laws, rationalization prevention, gate functions).

GSD's verification is programmatic — the verifier agent checks SUMMARY.md against PLAN.md against phase goals. Superpowers' verification is behavioral — the agent must run the verification command, read the output, and only then make the claim. Both achieve the same end (verified work), but through fundamentally different mechanisms.

GSD handles state management, context engineering, and multi-agent orchestration — capabilities Superpowers lacks entirely. Superpowers handles behavioral compliance, quality methodology, and rationalization prevention — capabilities GSD approaches only through reference documents (universal-anti-patterns.md, verification-patterns.md) rather than the targeted behavioral shaping that Superpowers provides.

The unified methodology's opportunity lies in combining GSD's programmatic infrastructure with Superpowers' behavioral precision — using GSD's state management and agent orchestration to provide the machinery, while using Superpowers' iron laws and rationalization prevention to ensure that machinery produces quality output.
