# Unified Development Methodology

A structured development methodology providing 18 skills, 12 agents, and 10 reference documents for disciplined software engineering — from brainstorming through verification and delivery.

## Session Protocol

The `session-start` hook automatically loads the `using-methodology` skill at the beginning of every session. This meta-skill establishes the invocation protocol and determines which other skills apply to your current task. All other skills are invoked on-demand via the `Skill` tool — they are never inlined into CLAUDE.md.

## Three Iron Laws

1. **Verification before completion** — Never claim work is done without running concrete checks. Tests pass, behavior confirmed, edge cases handled.
2. **Test-driven development** — Write tests first when a testing framework exists. Tests define the contract; implementation fulfills it.
3. **Systematic debugging** — Find the root cause before changing code. Hypothesize, test one variable at a time, never shotgun-fix.

## Skill Catalog

### Process Skills (10)

| Skill | Purpose |
|-------|---------|
| `using-methodology` | Meta-skill — determines which skills to load for the current task |
| `brainstorming` | Design exploration before implementation for new features or projects |
| `writing-plans` | Decompose work into verified, executable task plans |
| `executing-plans` | Execute task plans step-by-step with deviation tracking |
| `verification-before-completion` | Final verification gate before claiming any work complete |
| `test-driven-development` | Write tests first, then implement to satisfy them |
| `systematic-debugging` | Root-cause-first investigation for bugs and failures |
| `receiving-code-review` | Process and respond to incoming code review feedback |
| `requesting-code-review` | Prepare and request review of code changes |
| `finishing-work` | Clean close-out: commit, document, hand off |

### Implementation Skills (8)

| Skill | Purpose |
|-------|---------|
| `context-management` | Manage context window budget during long sessions |
| `knowledge-management` | Capture decisions, lessons, and rules that survive sessions |
| `subagent-driven-development` | Dispatch focused subagents for multi-task execution |
| `parallel-dispatch` | Coordinate simultaneous subagent execution |
| `writing-skills` | Create and refine behavioral skill directives |
| `frontend-design` | Build polished user interfaces and components |
| `git-worktree-management` | Isolated development via git worktrees |
| `security-enforcement` | Security review for untrusted input and sensitive operations |

## Agent Catalog

| Agent | Role |
|-------|------|
| `researcher` | Investigate approaches, analyze codebase, identify risks and patterns |
| `planner` | Create verified, execution-ready task decompositions |
| `plan-checker` | Verify plan quality against structural dimensions before execution |
| `executor` | Execute plan tasks — write code, run tests, produce artifacts |
| `verifier` | Independently verify results with distrust mindset |
| `reviewer` | Code quality review with anti-sycophancy — technical pushback required |
| `debugger` | Systematic debugging with structured failure recovery |
| `mapper` | Analyze codebase: stack, architecture, conventions, quality concerns |
| `auditor` | Specialized auditing: security, UI, integration checks |
| `doc-writer` | Generate and maintain documentation from execution artifacts |
| `orchestrator` | Coordinate multi-agent pipelines: waves, spawning, state management |
| `profiler` | Analyze user behavioral patterns for methodology adaptation |

## Reference Documents

| Reference | Scope |
|-----------|-------|
| `verification-patterns` | Verification strategies, evidence standards, and completeness checks |
| `agent-contracts` | Agent interfaces, input/output contracts, and spawning protocols |
| `context-budget` | Context window management strategies and budget allocation |
| `anti-patterns` | Common failure modes and how to avoid them |
| `model-profiles` | Model capability profiles and selection criteria |
| `git-integration` | Git workflow patterns, commit conventions, branch strategies |
| `planning-quality` | Plan quality dimensions, red flags, and refinement criteria |
| `checkpoint-types` | Checkpoint formats, triggers, and restoration protocols |
| `domain-probes` | Domain analysis techniques and technology-specific probes |
| `repair-strategies` | Recovery patterns for failed tasks, stuck agents, and broken plans |

## Invocation Protocol

**Skills:** Invoke any skill by name using the `Skill` tool — e.g., `Skill brainstorming`, `Skill test-driven-development`. The `using-methodology` skill (auto-loaded at session start) determines which skills apply to your current task.

**Agents:** Agents are spawned via the `subagent` tool with the agent name — e.g., `subagent researcher`. Each agent runs in an isolated context window with its own skill references and behavioral contract. See `agent-contracts` reference for interface details.

**References:** Reference documents in the `references/` directory provide detailed guidance. Load them when a skill or agent directs you to consult one — e.g., "see verification-patterns for evidence standards."
