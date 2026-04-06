---
name: context-management
description: "Use during long sessions, when working on large codebases, or when approaching context window limits. Triggers: context budget warnings, 'running low on context', large file reads, sessions exceeding 20 tool calls, noticing degraded output quality, 'let me summarize', any sign of context pressure. If the session is getting long or the codebase is large, invoke this skill."
---

# Context Management

## Core Principle: Context Is the Primary Engineering Investment

What information reaches you, when, and in what form determines your output quality more than any other factor. A capable model with poor context produces worse results than a standard model with excellent context. This is empirically demonstrated, not theoretical.

Context management is not an afterthought triggered by running low on space. It is an active engineering discipline that shapes every decision about what to read, how deeply to read it, and when to checkpoint your understanding.

## The Three-Tier Memory Model

All information belongs in one of three tiers. Loading information at the wrong tier wastes context budget or causes information gaps.

| Tier | Name | Loading Strategy | Examples |
|------|------|-----------------|----------|
| **Hot** | Always loaded | Injected at session start, present on every turn | Iron laws, project brief, current task context |
| **Warm** | Loaded per task | Loaded on demand when the task requires it, unloaded when done | Skill files, agent definitions, task-specific knowledge entries |
| **Cold** | Queried on demand | Retrieved only when a specific question arises | Reference documents, historical decisions, knowledge base entries not related to current task |

### Tier Placement Rules

- **Hot tier must be compact.** Everything in hot tier consumes context budget on every turn. If hot-tier content exceeds ~2000 tokens, audit it — something should be demoted to warm.
- **Warm tier is task-scoped.** Load warm content when starting a task, unload it when the task changes. Do not accumulate warm content across tasks.
- **Cold tier requires explicit retrieval.** Do not pre-load cold content "in case we need it." Load it when a specific question demands it.

## Context Budget Degradation Tiers

Your context window has a finite capacity. As it fills, your ability to process new information and maintain coherence degrades. The degradation is not linear — it follows a stepped pattern with distinct behavioral thresholds.

### PEAK (>60% remaining)

**Status:** Full capacity. No constraints.

**Behavioral adjustments:** None. Read files fully. Load warm-tier content freely. Explore broadly when investigating.

**Read depth:** Full files. Complete function bodies. All test cases.

### GOOD (35–60% remaining)

**Status:** Healthy but approaching limits. Begin economizing.

**Behavioral adjustments:**
- Prefer targeted reads over full-file reads. Use line ranges when you know what you're looking for.
- Summarize completed work before starting new work. Write intermediate results to disk rather than holding them in context.
- Prioritize high-value context. If a file has one relevant function among 500 lines, read just that function.
- Stop loading "nice to have" context. Only load what the current task requires.

**Read depth:** Targeted sections. Function-level reads. Relevant test cases only.

### DEGRADING (15–35% remaining)

**Status:** Context pressure is real. Active management required.

**Behavioral adjustments:**
- **Checkpoint now.** Write a summary of current understanding and progress to disk. If the session crashes or context resets, this checkpoint enables continuation.
- **Minimize reads.** Only read files that are directly required for the current step. No exploratory reading.
- **Write before reading.** If you have output to produce, write it before loading new input. This ensures your work is persisted even if context is exhausted.
- **Close completed work.** Mentally release (and avoid re-referencing) completed tasks. Focus exclusively on the current task.
- **Use tools for memory.** Write intermediate results to scratch files rather than tracking them in conversation. Let the filesystem be your working memory.
- **Avoid large outputs.** Produce concise, dense results. This is not the time for verbose explanations.

**Read depth:** Minimal. Signatures and key logic only. Grep for specific patterns rather than reading whole files.

### POOR (<15% remaining)

**Status:** Critical. Finish current work or checkpoint immediately.

**Behavioral adjustments:**
- **Stop starting new tasks.** Complete or checkpoint the current task. Do not begin anything new.
- **Write everything to disk.** Any understanding, any progress, any partial result — write it to a file. Your context will be exhausted imminently.
- **Request a handoff.** If working in orchestrated mode, produce a structured handoff artifact (what's done, what's remaining, what's the current state of investigation). If working interactively, suggest the human start a fresh session with a summary.
- **Do not attempt large file reads.** If you need information from a file, use grep or read specific line ranges. Full-file reads at this tier are actively harmful — they consume the remaining budget without proportional benefit.
- **Favor action over analysis.** If you have enough understanding to produce output, produce it now. Do not spend remaining context on further analysis.

**Read depth:** Grep results and line-specific reads only. No full files. No exploration.

## Read-Depth Scaling by Window Size

Context window sizes vary by model. Adjust your default read behavior based on available capacity:

| Context Window | Default Read Strategy | File Size Threshold for Targeted Read |
|---------------|----------------------|--------------------------------------|
| 200K tokens | Targeted reads for files > 500 lines. Full reads for smaller files. | 500 lines |
| 500K tokens | Full reads for files up to 1000 lines. Targeted for larger. | 1000 lines |
| 1M+ tokens | Full reads for most files. Targeted only for very large files (>2000 lines). | 2000 lines |

These are starting heuristics, not rigid rules. Adjust based on the actual degradation tier as the session progresses. A 1M-token window at DEGRADING tier should follow DEGRADING rules, not the 1M default.

## Checkpoint Triggers

Write a checkpoint to disk when any of the following occur:

1. **Entering DEGRADING tier** — Summarize understanding and progress before context pressure degrades output quality.
2. **Completing a logical unit of work** — After finishing a function, a file, or a task step. Don't wait until the end to summarize.
3. **Before a large context-consuming operation** — Before reading a large file or running a command with verbose output, write your current state first.
4. **After a discovery that changes your approach** — If investigation reveals something unexpected, write it down immediately. Don't rely on remembering it through subsequent tool calls.
5. **At the 30-minute mark** (approximately 15-20 tool calls) — Even if context budget looks healthy, checkpoint. Long sessions accumulate implicit context (assumptions, decisions, partial understanding) that should be made explicit.

### Checkpoint Format

```markdown
## Checkpoint: [timestamp or step identifier]

### Current State
[What am I currently working on? What step of the plan am I in?]

### Completed
[What has been done so far? Key files modified. Key decisions made.]

### Understanding
[What do I now know about the codebase/problem that wasn't obvious at the start?]

### Next Steps
[What should the next action be? What's the remaining plan?]

### Open Questions
[What am I unsure about? What needs investigation?]
```

## Cache-Friendly Ordering

When loading multiple context documents, order them for maximum retention:

1. **Most important first.** The first items loaded into context have the strongest influence on subsequent reasoning. Load iron laws, task requirements, and critical constraints first.
2. **Most referenced in the middle.** Content you'll refer back to during work belongs in the stable middle of the context window.
3. **Least critical last.** Background information, historical context, and nice-to-have references go last. If context pressure forces trimming, these are shed first.

This ordering interacts with how transformer attention patterns work in long contexts — information at the beginning and end of the context window receives more attention than information in the middle (the "lost in the middle" phenomenon). Place the most critical behavioral directives at the beginning and the most critical task-specific information near the current conversation turn.

## Context Density Principles

Not all context tokens are equal. A token of iron law content has more behavioral impact than a token of background explanation. Optimize for information density:

- **Skill descriptions contain only trigger conditions.** Never workflow summaries. This prevents agents from following the summary instead of reading the full skill (the CSO discovery).
- **Tables over prose.** A rationalization prevention table packs 10x more behavioral content per token than the equivalent prose explanation.
- **Concrete over abstract.** "Run `npm test`" is denser than "execute the appropriate test suite for the project." Specific commands, file paths, and error messages are higher density than general descriptions.
- **Imperatives over explanations.** "Delete it. Start over." is denser than "You should consider removing the existing code and beginning fresh." Save explanations for when the *why* is genuinely non-obvious.
- **Examples over rules.** A concrete example of correct behavior often communicates more effectively in fewer tokens than an abstract rule. Use both when space permits; favor examples when space is tight.

## State-Tier-Aware Behavior

Context management behavior adapts based on the active state tier:

| Behavior | Tier 0 (Stateless) | Tier 1 (Lightweight) | Tier 2 (Full) |
|----------|-------------------|---------------------|---------------|
| Checkpoint destination | Suggest fresh session to human | Write to KNOWLEDGE.md or project notes | Write to structured handoff artifact |
| Knowledge persistence | Lost at session end | Append to KNOWLEDGE.md | Append to KNOWLEDGE.md + structured summaries |
| Context recovery | Not possible — start fresh | Re-read Tier 1 artifacts | Resume from HANDOFF.json |
| Budget monitoring | Self-monitored via degradation tiers | Self-monitored + manual checkpoints | Infrastructure-monitored via context-monitor hook with automated warnings |
| Cross-session continuity | None | PROJECT.md + KNOWLEDGE.md + DECISIONS.md loaded at start | Full state reconstruction from milestone artifacts |

## Rationalization Prevention Table

| # | Thought Pattern | Correction |
|---|----------------|------------|
| 1 | "I have plenty of context left" | Check your actual degradation tier. Perceived capacity and actual capacity diverge — you feel fine until you're suddenly POOR. |
| 2 | "I need to read this whole file to understand it" | No you don't. Read the function signatures first. Read the specific function you need. Full-file reads are for PEAK tier only. |
| 3 | "I'll checkpoint later" | Checkpoint now. If you could checkpoint later, you wouldn't need to — context wouldn't be a concern. The fact that you're deferring checkpointing means you're already under pressure. |
| 4 | "This information might be useful later" | Don't pre-load. Cold tier exists for this. Load it when you actually need it, not when you might need it. |
| 5 | "I need all the context to do good work" | You need the RIGHT context, not ALL context. A focused 50K context produces better work than a diffuse 200K context. |
| 6 | "The context budget warnings are conservative" | They're calibrated from observed degradation patterns. Trust the tiers, not your self-assessment. |
| 7 | "I'll just quickly read one more file" | At DEGRADING or POOR, every read has an opportunity cost. Is this file more valuable than the context budget it consumes? Make the tradeoff explicit. |
