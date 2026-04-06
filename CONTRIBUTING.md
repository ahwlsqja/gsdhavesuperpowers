# Contributing to Unified Development Methodology

Thank you for your interest in contributing. This guide covers how to add skills, agents, and references to the methodology, and how to verify your changes.

## Adding a New Skill

1. Create a directory under `skills/` with your skill name:

   ```
   skills/your-skill-name/SKILL.md
   ```

2. Include YAML frontmatter with required fields:

   ```yaml
   ---
   name: your-skill-name
   description: >-
     One-paragraph description including trigger conditions.
     Specify when this skill should activate — what keywords,
     task types, or contexts cause invocation.
   ---
   ```

3. Write behavioral content — protocols the agent follows, not descriptions of what the skill does. Include:
   - **Iron law text** (verbatim when referencing the three iron laws)
   - **Protocol tables** with numbered steps
   - **Rationalization prevention** tables with thought-pattern/correction rows
   - **Gate functions** that define pass/fail criteria
   - **Cross-references** to other skills or references when needed

4. Reference existing skills as examples. `verification-before-completion` and `systematic-debugging` demonstrate the full pattern.

5. Add an entry to the appropriate skill table in `CLAUDE.md` (Process Skills or Implementation Skills).

6. Run verification before submitting:

   ```bash
   bash scripts/verify-m03.sh
   ```

## Adding a New Agent

1. Create an agent file under `agents/`:

   ```
   agents/your-agent-name.md
   ```

2. Include YAML frontmatter:

   ```yaml
   ---
   name: your-agent-name
   description: One-line description of the agent's role
   model_tier: standard
   skills_used:
     - skill-name-1
     - skill-name-2
   references_used:
     - reference-name-1
   ---
   ```

3. Write the agent's behavioral contract:
   - **Capability contract** — what the agent can and cannot do
   - **Behavioral directives** — protocols the agent follows during execution
   - **Input/output interface** — what the agent expects and produces

4. Ensure every entry in `skills_used` matches an existing `skills/*/SKILL.md` file. The verification script checks cross-references.

5. Add the agent to the Agent Catalog table in `CLAUDE.md`.

6. Run verification:

   ```bash
   bash scripts/verify-m03.sh
   ```

## Adding a New Reference

1. Create a reference file under `references/`:

   ```
   references/your-reference-name.md
   ```

2. Start with a clean `# Title` header. References do not require YAML frontmatter.

3. Write content that encodes engineering knowledge usable by agents and skills. Focus on:
   - Concrete patterns and strategies (not abstract theory)
   - Decision criteria and trade-offs
   - Examples and anti-patterns
   - Cross-references to related skills or other references

4. Add the reference to the Reference Documents table in `CLAUDE.md`.

5. Run verification:

   ```bash
   bash scripts/verify-m03.sh
   ```

## Updating CLAUDE.md

When adding skills, agents, or references, you must also update `CLAUDE.md`:

- **Skills** — Add a row to the Process Skills or Implementation Skills table with the skill name and a one-line purpose description.
- **Agents** — Add a row to the Agent Catalog table with the agent name and its role.
- **References** — Add a row to the Reference Documents table with the reference name and scope.

Keep `CLAUDE.md` under **2,000 words**. It serves as the methodology entry point, not as comprehensive documentation. Each catalog entry should be a single line.

## Verification

Always run the verification script before submitting changes:

```bash
bash scripts/verify-m03.sh
```

The script validates:

- **Structural integrity** — All expected files exist with correct naming conventions
- **Cross-references** — Agent `skills_used` entries match actual skill directories; CLAUDE.md catalogs match file system contents
- **Content quality** — No placeholder text, minimum content thresholds met, required sections present
- **Counts** — Expected number of skills (18), agents (12), and references (10)

All checks must pass before changes are accepted.

## Style Conventions

- **Behavioral-first content** — Skills contain protocols and directives, not descriptions. Write what the agent should do, not what the skill is about.
- **No placeholder text** — Never include unfinished markers or "to be determined" stubs. All content must be complete and actionable.
- **Iron law verbatim rule** — When referencing the three iron laws (verification before completion, test-driven development, systematic debugging), use the exact text from CLAUDE.md.
- **Rationalization prevention** — Use numbered thought-pattern/correction row format: column 1 is the rationalization pattern, column 2 is the correction that overrides it.
- **Consistent naming** — Skill directories use kebab-case (`my-skill-name`). Agent and reference files use kebab-case with `.md` extension.
- **Cross-reference format** — Reference other files by name in backticks: "see `verification-patterns` reference" or "invoke `brainstorming` skill."
