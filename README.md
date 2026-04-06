# Unified Development Methodology

A Claude Code plugin providing **18 skills**, **12 agents**, and **10 references** for disciplined software engineering — from brainstorming through verification and delivery.

## Overview

The Unified Development Methodology encodes structured engineering practices into behavioral directives that guide AI coding assistants. Rather than relying on ad-hoc prompting, the methodology provides:

- **Skills** — Behavioral protocols that activate on-demand. Each skill defines iron laws, rationalization prevention tables, and gate functions that enforce disciplined practices.
- **Agents** — Specialized subagents that run in isolated context windows with their own skill references and behavioral contracts. Each agent has a focused role: research, planning, execution, verification, or review.
- **References** — Engineering knowledge documents covering verification patterns, anti-patterns, context management, and recovery strategies. Skills and agents consult these when they need domain-specific guidance.

The three-layer architecture ensures that behavioral directives (skills) drive action, specialized workers (agents) execute focused tasks, and shared knowledge (references) provides consistent engineering standards.

## Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/unified-methodology/unified-methodology.git
   ```

2. **Add to Claude Code plugin configuration:**

   In Claude Code, navigate to **Settings → Plugins → Add Plugin** and provide the path to the cloned repository.

3. **Start a session:**

   The `session-start` hook automatically loads the `using-methodology` skill, which bootstraps the full methodology. No manual configuration is needed after the plugin path is registered.

## Quick Start

**Automatic invocation:** The `using-methodology` skill (loaded at session start) analyzes your current task and determines which skills apply. Skills activate automatically when your request matches their trigger conditions — no explicit invocation needed for common workflows.

**Manual skill invocation:** Invoke any skill directly using the `Skill` tool:

```
Skill brainstorming
Skill test-driven-development
Skill verification-before-completion
```

**Agent dispatch:** Spawn specialized agents using the `subagent` tool:

```
subagent researcher   # investigate approaches and analyze codebase
subagent planner      # create verified task decompositions
subagent executor     # execute plan tasks and produce artifacts
subagent verifier     # independently verify results
```

## What's Included

### Skills (18)

#### Process Skills (10)

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

#### Implementation Skills (8)

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

### Agents (12)

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

### References (10)

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

## Architecture

**CLAUDE.md** is the methodology entry point. It defines the three iron laws (verification before completion, test-driven development, systematic debugging), lists the skill/agent/reference catalogs, and establishes the invocation protocol.

The **session-start hook** (`hooks/session-start`) bootstraps the methodology by injecting the `using-methodology` skill into every new session. This skill analyzes the current task context and determines which other skills apply.

**Skills** are invoked on-demand via the `Skill` tool. Each skill file (`skills/*/SKILL.md`) contains behavioral protocols — not descriptions, but directives the agent follows.

**Agents** run in isolated context windows via the `subagent` tool. Each agent (`agents/*.md`) carries its own skill references and behavioral contract, ensuring focused execution without context contamination.

**References** (`references/*.md`) encode engineering knowledge that skills and agents consult when they need detailed guidance on verification, planning, debugging, or recovery.

## File Structure

```
├── CLAUDE.md                       # Methodology entry point
├── .claude-plugin/
│   └── plugin.json                 # Plugin metadata
├── hooks/
│   ├── hooks.json                  # Hook registration
│   ├── run-hook.cmd                # Cross-platform hook runner
│   └── session-start               # Session bootstrap script
├── skills/
│   └── {skill-name}/
│       └── SKILL.md                # Behavioral skill directive
├── agents/
│   └── {agent-name}.md             # Agent behavioral contract
└── references/
    └── {reference-name}.md         # Engineering knowledge document
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding skills, agents, and references.

## License

[MIT](LICENSE)
