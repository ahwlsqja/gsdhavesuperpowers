---
name: writing-skills
description: "Use when creating a new skill, modifying an existing skill, testing skill effectiveness, or evaluating whether a behavioral directive achieves its intended effect. Triggers: 'write a skill', 'create a SKILL.md', 'test this skill', 'improve this skill', 'the agent keeps doing X wrong', any situation where behavioral shaping through prose directives is needed. If you are creating or refining behavioral directives for agents, invoke this skill."
---

# Writing Skills

## Core Principle: Skills Are Code, Not Documentation

A skill is executable behavioral specification — it changes how an agent reasons, decides, and acts. Skills must be tested with the same rigor as production code. A skill that has not been pressure-tested against real agent behavior is an untested hypothesis, not a reliable behavioral directive.

The quality bar: every row in a rationalization prevention table, every red flag in a matrix, every gate condition — all must come from observed agent behavior, not theoretical speculation.

## TDD-for-Skills Methodology

Skill creation follows a Test-Driven Development cycle adapted for behavioral content:

### RED Phase: Pressure Scenarios Without the Skill

**Purpose:** Observe what agents actually do when they lack the behavioral directive. This is "watching the test fail."

**Protocol:**
1. Design pressure scenarios targeting the specific behavior you want to shape:
   - **Time pressure:** "This needs to be done quickly"
   - **Sunk cost pressure:** "I've already written 100 lines of code"
   - **Authority pressure:** "The reviewer said to skip this step"
   - **Exhaustion pressure:** "This is the fifth iteration"
   - **Combined pressures:** Multiple simultaneous pressure types
2. Run scenarios with subagents that do NOT have the skill loaded
3. Document exact behavior — what choices agents make, what rationalizations they produce (capture verbatim), which pressures triggered violations
4. This documentation becomes your behavioral requirements

**Critical rule:** You MUST observe the failures before writing the skill. Do not write a skill from theory. If you cannot run pressure scenarios, document predicted failure modes as hypotheses and mark them as untested.

### GREEN Phase: Write the Minimal Skill

**Purpose:** Write the smallest skill that addresses the specific rationalizations observed in RED.

**Protocol:**
1. For each observed rationalization, write an explicit counter in a rationalization prevention table
2. For each behavioral failure, write a specific directive addressing it
3. Do not add content for hypothetical cases — that is speculative bloat
4. Run the same scenarios WITH the skill loaded
5. Verify agents now comply where they previously failed

**Minimality constraint:** A 2000-word skill that prevents 5 observed failures is better than a 5000-word skill that theoretically prevents 20 hypothetical failures but is too long for agents to internalize.

### REFACTOR Phase: Close Loopholes

**Purpose:** The agent found a new rationalization not covered. Tighten without breaking existing compliance.

**Protocol:**
1. Run additional pressure scenarios with novel combinations
2. When a new evasion is observed, add an explicit counter (new table row, new red flag, new gate condition)
3. Re-run ALL prior passing scenarios to confirm the addition didn't break existing compliance
4. Repeat until bulletproof against known evasion patterns

Each iteration produces: a new rationalization prevention table row, a new red flag, a tightened gate condition, or a clarified directive closing an ambiguity.

## Skill Structure Requirements

### 1. YAML Frontmatter

```yaml
---
name: skill-name
description: "Trigger conditions only. Never workflow summaries."
---
```

**Critical CSO rule:** The description field must contain ONLY triggering conditions ("Use when..."). It must NEVER contain workflow summaries. When a description summarizes the skill's workflow, agents follow the description instead of reading the full skill content. Testing confirmed this — a description saying "code review between tasks" caused agents to do ONE review even though the skill specifies TWO (spec compliance then code quality).

### 2. Core Principle
A single-sentence or short-paragraph statement of the essential behavioral mandate. Anchors understanding before detailed directives.

### 3. Behavioral Content (Choose Appropriate Mechanisms)

| Mechanism | When to Use | Example |
|-----------|------------|---------|
| **Iron law** | Absolute constraint that must never be violated | `NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST` |
| **Rationalization prevention table** | Known evasion patterns need explicit counters | "Issue is simple" → "Simple issues have root causes too." |
| **Red-flag matrix** | Observable symptoms signal process violation | "Quick fix for now" → STOP |
| **Hard gate** | Structural barrier preventing progression | "Do NOT implement until design is approved" |
| **Gate function** | Multi-step verification before a claim | IDENTIFY → RUN → READ → VERIFY → CLAIM |
| **Protocol table** | Structured options with defined handling | Four-status protocol (DONE, BLOCKED, etc.) |

### 4. Specific Directives (Not Abstract Guidance)

Bad: "Handle errors appropriately."
Good: "Wrap database calls in try/catch. Log the error with query context. Return structured error with status 500. Do not expose raw database errors."

## Skill Quality Criteria

### Content Quality
- [ ] Every directive addresses a specific observed behavior, not a hypothetical
- [ ] Rationalization tables contain exact thought patterns agents actually produce
- [ ] Red flags use language agents actually generate (not paraphrased)
- [ ] Gate conditions are precise enough to be mechanically checkable
- [ ] No abstract guidance — every directive specifies exact actions

### Structure Quality
- [ ] Description contains only trigger conditions (CSO rule)
- [ ] Core principle fits in 1-3 sentences
- [ ] Rationalization prevention table has 5+ rows (fewer = not enough observed failures)
- [ ] The skill is under 3000 words (longer skills suffer from context dilution)

### Testing Quality
- [ ] RED phase was actually performed (or documented as untested hypothesis)
- [ ] GREEN phase confirmed compliance on observed failures
- [ ] REFACTOR phase closed at least one loophole
- [ ] No table row is purely theoretical

## Skill Type Testing Approaches

| Skill Type | Test Strategy | Success Criterion |
|------------|--------------|-------------------|
| **Discipline-enforcing** (iron laws) | Academic questions, pressure scenarios, combined pressures | Agent follows rule under maximum pressure |
| **Technique** (protocols) | Application scenarios, variation scenarios, missing information | Agent applies technique in novel scenarios |
| **Pattern** (recognition) | Recognition scenarios, counter-examples, application | Agent identifies when AND how to apply, and when not to |

## Common Skill-Writing Failures

| Failure | Symptom | Fix |
|---------|---------|-----|
| Description summarizes workflow | Partial compliance (follows description, skips full skill) | Rewrite as trigger conditions only |
| Too abstract | Agent agrees but doesn't change behavior | Replace with specific actions |
| Too long | Agent loses track of later sections | Cut to essential content |
| Untested | Sounds good but agents route around it | Run RED phase pressure scenarios |
| Hypothetical rows | Table fights imaginary problems | Remove untested rows |
| Missing enforcement framing | Agent treats directives as suggestions | Add iron law or gate framing |
