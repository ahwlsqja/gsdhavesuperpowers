# M002 Design Corpus

This directory contains the complete design output from Milestone M002: a unified AI coding methodology merging GSD's infrastructure-driven orchestration with Superpowers' behavioral-first skill system. The design spans 26 Markdown specification files totaling ~56,000 words.

## Reading Order

For a developer encountering this corpus for the first time, the recommended reading sequence is:

1. **`architecture-overview.md`** — Start here. The master specification defining the two-layer architecture (behavioral + infrastructure), execution modes, component map, 6-stage pipeline, and design constraints. (~6,750 words)
2. **`core-principles.md`** — The 7 design principles grounding every decision, with research traceability to their empirical sources. (~6,980 words)
3. **`tiered-state-system.md`** — Companion spec defining the 3 state tiers (stateless → lightweight → full orchestration) that scale methodology overhead to project complexity. (~6,170 words)
4. **`verification-pipeline.md`** — Companion spec detailing the 2-layer verification model (behavioral gate functions + programmatic independent checking) and failure recovery. (~5,760 words)
5. **Agent specs** (`agent-specs/`) — 12 agent definitions specifying roles, tool permissions, model tiers, skill assignments, and completion markers.
6. **Reference specs** (`reference-specs/`) — 10 shared knowledge documents loaded into agent context to provide domain-specific information.

## File Index

### Architecture Files (4)

| File | Words | Scope |
|------|------:|-------|
| `architecture-overview.md` | ~6,750 | Master spec: vocabulary, execution modes, component map, pipeline stages, design constraints |
| `core-principles.md` | ~6,980 | 7 design principles with research grounding and traceability |
| `tiered-state-system.md` | ~6,170 | 3 state tiers: Tier 0 (stateless), Tier 1 (lightweight), Tier 2 (full orchestration) |
| `verification-pipeline.md` | ~5,760 | 2-layer verification: behavioral gates + programmatic checking, failure recovery |

### Agent Specs (12) — `agent-specs/`

| File | Role |
|------|------|
| `auditor.md` | Security (STRIDE), UI (6-pillar visual audit), and integration checks |
| `debugger.md` | Systematic debugging with root-cause-first investigation and structured failure recovery |
| `doc-writer.md` | Generate and maintain project documentation from execution artifacts |
| `executor.md` | Execute plan tasks — write code, run tests, produce artifacts, report deviations |
| `mapper.md` | Analyze existing codebase: technology stack, architecture patterns, conventions |
| `orchestrator.md` | Coordinate multi-agent pipeline: wave analysis, agent spawning, state management |
| `plan-checker.md` | Verify plans against structural quality dimensions before execution |
| `planner.md` | Create verified, execution-ready task decompositions from research output |
| `profiler.md` | Analyze user behavioral patterns across sessions for methodology adaptation |
| `researcher.md` | Investigate implementation approaches, analyze codebase, identify risks |
| `reviewer.md` | Code quality review with anti-sycophancy protocol and YAGNI checks |
| `verifier.md` | Independently verify execution results with distrust mindset |

### Reference Specs (10) — `reference-specs/`

| File | Content Scope |
|------|---------------|
| `agent-contracts.md` | Agent capability contracts, input/output specifications, spawning protocol |
| `anti-patterns.md` | Known failure modes and rationalization patterns to detect and prevent |
| `checkpoint-types.md` | Checkpoint taxonomy for state persistence and recovery |
| `context-budget.md` | Context window budget allocation and degradation strategies |
| `domain-probes.md` | Domain-specific investigation probes for codebase analysis |
| `git-integration.md` | Git workflow patterns, worktree management, commit conventions |
| `model-profiles.md` | Model capability profiles and tier assignment criteria |
| `planning-quality.md` | Plan quality dimensions and structural verification criteria |
| `repair-strategies.md` | Node repair operators for failed pipeline stages |
| `verification-patterns.md` | Verification pattern catalog for different artifact types |

## Component Summary

| Component | Count | Defined In |
|-----------|------:|------------|
| Skills | 18 | `architecture-overview.md` § Skill Catalog |
| Agents | 12 | `agent-specs/` (one file each) |
| References | 10 | `reference-specs/` (one file each) |
| Pipeline stages | 6 | `architecture-overview.md` § Pipeline Stages |
| State tiers | 3 | `tiered-state-system.md` |
| Execution modes | 2 | `architecture-overview.md` § Execution Modes |

## S02 Gap Note

The 18 skills cataloged in `architecture-overview.md` § Skill Catalog were designed with names, one-line descriptions, research grounding, and traceability — but were not written as separate behavioral specification files. Skill behavioral content (iron laws, gate functions, rationalization prevention tables) is specified inline within the architecture overview and cross-referenced throughout the 12 agent specs via `skills_used` fields. This was a deliberate scope decision: the skill catalog provides sufficient specification for implementation without requiring 18 additional files that would largely duplicate content already present in the master spec.

## Verification

Three verification scripts validate cross-reference consistency across the design corpus:

```bash
# S01: Architecture file structure and word counts (27 checks)
bash scripts/verify-s01.sh

# S03: Agent and reference spec structure (22 checks)
bash scripts/verify-s03.sh

# S04: Full cross-reference validation across all 28 files (119 checks)
bash scripts/verify-s04.sh
```

All three scripts output `VERDICT: PASS` when the design corpus is internally consistent. Run `verify-s04.sh` for the most comprehensive validation — it covers file existence, component counts, skill/agent/reference cross-references, word count thresholds, and placeholder scanning.
