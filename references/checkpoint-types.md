# Checkpoint Types

## Content Scope

This reference defines the taxonomy of human interaction points within the execution pipeline. Checkpoints formalize where human judgment is required — verification of visual/functional correctness, architectural decisions, and authentication gates. The core principle is that agents automate everything with CLI and API; checkpoints exist only for activities that genuinely require human judgment.

**What belongs here:** Checkpoint type definitions, usage frequency ratios, placement guidelines, auto-mode bypass rules, and the authentication gate protocol.

**What does NOT belong here:** Agent behavioral specifications (those are in agent specs), verification pipeline logic (that is in `verification-patterns`), or repair operator decisions (that is in `repair-strategies`).

---

## The Golden Rule

If the agent can automate it, the agent must automate it. Checkpoints are for verification and decisions, not manual work.

---

## Checkpoint Type Taxonomy

### checkpoint:human-verify (90% of all checkpoints)

**When:** The agent has completed automated work and a human confirms it works correctly.

**Use for:** Visual UI checks (layout, styling, responsiveness), interactive flow testing, functional verification of features, audio/video playback quality, animation smoothness, and accessibility evaluation.

**Structure:** The checkpoint declares what was built, provides exact verification steps with URLs and expected behavior, and specifies the resume signal format. The agent must start any required servers or services before presenting the checkpoint — a broken verification environment is never acceptable.

### checkpoint:decision (9% of all checkpoints)

**When:** A human must make a choice that affects implementation direction.

**Use for:** Technology selection (auth providers, databases), architecture decisions (monorepo vs. separate repos), design choices (color schemes, layout approaches), feature prioritization, and data model decisions.

**Structure:** The checkpoint presents 2–3 concrete options with pros, cons, and trade-offs. Each option has an identifier for selection. Context explains why the decision matters and what depends on it.

### checkpoint:human-action (1% of all checkpoints — rare)

**When:** An action has no CLI/API equivalent and requires human-only interaction, or the agent hit an authentication gate during automation.

**Use for:** Email verification links, SMS 2FA codes, manual account approvals, credit card 3D Secure flows, and OAuth app approvals in browser.

**Critical distinction:** Human-action checkpoints are created dynamically when agents encounter authentication errors during automation. They are not pre-planned as manual work steps. The pattern is: agent tries automation → auth error → creates checkpoint → human authenticates → agent retries → continues.

---

## Auto-Mode Bypass Rules

When executing in fully autonomous mode (auto-chain active or auto-advance enabled):

- **human-verify:** Auto-approves — verification is skipped, execution continues
- **decision:** Auto-selects the first option — the planner should place the recommended option first
- **human-action:** Execution stops — authentication gates cannot be automated safely

This means the planner must ensure that auto-mode-safe plans either avoid human-action checkpoints entirely or handle authentication proactively.

---

## Placement Guidelines

Checkpoints are placed **after** automation completes, not before. One checkpoint at the end of a related task group is preferred over individual checkpoints after each task. Checkpoints must never present a broken verification environment — if a server needs to be running, the agent starts it in a prior automated task.

**Correct placement pattern:** Build task → build task → start server task → verification checkpoint.

**Incorrect patterns:** Checkpoint before automation work, checkpoint per individual task, checkpoint asking users to run CLI commands, checkpoint with vague verification steps.

---

## Cross-References

- **Planner agent spec:** §Plan Authoring uses this reference for checkpoint placement decisions
- **Executor agent spec:** §Checkpoint Protocol implements the display and wait behavior
- **Orchestrator agent spec:** §Auto-Mode Execution applies the bypass rules
- **`planning-quality` reference:** Checkpoint frequency and placement are quality dimensions
- **`verification-patterns` reference:** Programmatic verification reduces the need for human-verify checkpoints
