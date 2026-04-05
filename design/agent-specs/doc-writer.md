# Agent Specification: Doc-Writer

**Name:** `doc-writer`
**Role:** Generate and maintain project documentation from execution artifacts
**Modes:** Both (interactive and orchestrated)
**Model Tier:** Standard
**Preserves:** GSD's `gsd-doc-writer` with template-driven documentation generation, 4 operation modes, and doc-tooling adaptation

---

## Capability Contract

### What This Agent Does

The doc-writer agent generates and maintains project documentation by exploring the live codebase and extracting facts — documentation is produced from execution artifacts and code inspection, not written from scratch or from the developer's description. This principle prevents documentation drift: docs reflect what the code actually does, not what someone remembers it doing.

The doc-writer operates in 4 modes (create, update, supplement, fix) that handle different documentation lifecycle stages. It writes documentation directly to the project's doc directory and returns confirmation only — doc content is not passed through the orchestrator to avoid bloating coordination context.

### Completion Markers

```
## DOC COMPLETE
**Type:** {doc_type}
**Mode:** {create | update | supplement | fix}
**Path:** {output file path}
**Sections:** {count}
**Claims Verified:** {count} ({pass} pass, {unverifiable} marked for review)
```

### Input/Output Contract

| Direction | Artifact | Format |
|-----------|----------|--------|
| **Input** | Doc assignment | Type (readme, architecture, getting-started, development, testing, api, configuration, deployment, contributing, custom), mode, project context |
| **Input** | Existing content (update/supplement/fix modes) | Current file content for revision or supplementation |
| **Input** | Failure list (fix mode) | Array of `{line, claim, expected, actual}` from reviewer's doc verification |
| **Output** | Documentation file | Markdown written directly to the project's doc directory |
| **Output** | Verification markers | `<!-- VERIFY: {claim} -->` annotations on claims that cannot be verified from the repository |

### Handoff Schema

- **Orchestrator → Doc-Writer:** Doc assignment with type, mode, and project context. The orchestrator determines which documentation needs creation or updating based on the milestone's documentation requirements.
- **Reviewer → Doc-Writer (via Orchestrator):** In fix mode, the reviewer's doc verification results (failed claims with line numbers, expected values, and actual values) are forwarded to the doc-writer for surgical correction.
- **Doc-Writer → Reviewer:** After writing documentation, the reviewer can verify factual claims against the codebase (doc verification mode).

---

## Behavioral Specification

### Governing Skills

| Skill | How It Governs |
|-------|---------------|
| `finishing-work` | The doc-writer is part of the finishing-work skill's documentation phase. This skill governs when documentation is generated (after implementation is complete, not before) and what documentation is required for a milestone to be considered done. |
| `context-management` | Governs how much codebase content the doc-writer explores during fact-gathering. Large projects can exhaust context during exploration; degradation tiers guide when to write with available facts rather than continuing to explore. |
| `knowledge-management` | Directs the doc-writer to check KNOWLEDGE.md for project-specific conventions, gotchas, and setup requirements that should be reflected in documentation. |

### Active Iron Laws

- **Explore, then write — never fabricate.** Every factual claim in generated documentation must be verified through codebase inspection (Read, Grep, Glob). File paths, command names, function references, and dependency claims are checked against the live codebase. Fabricated claims produce documentation that misleads developers.
- **Surgical precision in fix mode.** When correcting failed claims, the doc-writer modifies only the lines listed in the failure array. It does not "improve," reorganize, or rephrase other content. Fix mode is a scalpel, not a rewrite.
- **Supplement mode preserves existing content.** When adding missing sections to hand-written documentation, the doc-writer appends new sections without modifying, reordering, or rephrasing any existing line. The file remains user-owned; the doc-writer is adding to it, not rewriting it.

---

## Operation Modes

### Create Mode

Write documentation from scratch. The doc-writer:

1. Selects the template for the assigned document type (readme, architecture, testing, etc.)
2. Explores the codebase using file system tools to gather accurate facts
3. Fills the template with verified findings
4. Marks unverifiable claims (infrastructure URLs, server configs, external service details) with `<!-- VERIFY: {claim} -->` annotations
5. Writes the file with a `<!-- generated-by: doc-writer -->` marker on the first line

### Update Mode

Revise existing generated documentation. The doc-writer:

1. Reads the existing content and identifies sections that are inaccurate or missing
2. Explores the codebase to verify current facts
3. Rewrites only the inaccurate or missing sections, preserving accurate user-authored prose
4. Ensures the generated-by marker is present

### Supplement Mode

Append missing sections to hand-written documentation. The doc-writer:

1. Extracts all `##` headings from the existing content
2. Compares against the required sections for the document type
3. For each missing section only: explores the codebase and generates content
4. Appends missing sections to the end — never modifies existing lines
5. Does not add the generated-by marker (file remains user-owned)

### Fix Mode

Correct specific failed claims identified by the reviewer's doc verification. The doc-writer:

1. Reads the failure array with line numbers, incorrect claims, expected values, and actual values
2. For each failure: locates the line, explores the codebase to find the correct value, replaces only the incorrect claim
3. If the correct value cannot be determined, replaces the claim with a `<!-- VERIFY: {claim} -->` marker
4. Modifies nothing outside the failure list

---

## Document Type Templates

Each document type has a required sections list and content discovery protocol. The doc-writer selects the template matching its assignment and follows the discovery steps to gather facts from the codebase.

| Document Type | Required Sections | Primary Discovery Sources |
|--------------|-------------------|--------------------------|
| `readme` | Title, installation, quick start, usage examples, license | `package.json`, `src/index.*`, `examples/`, `LICENSE` |
| `architecture` | System overview, component diagram, data flow, key abstractions, directory rationale | `src/` directory structure, import patterns, entry points |
| `getting-started` | Prerequisites, installation steps, first run, common setup issues, next steps | `package.json` engines, `.nvmrc`, `.env.example`, scripts |
| `development` | Dev environment setup, development workflow, debugging, common tasks | Scripts, config files, test commands |
| `testing` | Test setup, running tests, writing new tests, coverage requirements | Test config, existing test files, CI config |
| `api` | Endpoint inventory, authentication, request/response formats, error codes | Route files, middleware, API handlers |
| `configuration` | Environment variables, config files, feature flags, deployment config | `.env.example`, config directory, constants |
| `deployment` | Build process, deployment targets, CI/CD pipeline, monitoring | CI config, Dockerfile, deployment scripts |
| `contributing` | Code style, PR process, commit conventions, review process | Linting config, git hooks, CONTRIBUTING.md template |
| `custom` | As specified in the assignment description | As directed by the assignment |

---

## Verification Markers

Claims that cannot be verified from the repository alone receive `<!-- VERIFY: {claim} -->` markers. These mark infrastructure-dependent facts (server URLs, cloud configuration, external service endpoints) that require human verification.

The reviewer's doc verification mode processes these markers: it skips them during automated verification (they are already flagged) and reports them as items requiring human review.

---

## Mode-Specific Behavior

### Interactive Mode

In interactive mode, the primary agent loads the `finishing-work` skill's documentation requirements. The developer can request specific document generation or updates.

Key characteristics:
- The developer can guide documentation scope and emphasis
- Documentation can be generated incrementally (one document at a time) based on developer priorities
- The developer provides implicit verification by reviewing generated documentation
- Fix mode can be triggered by the developer identifying specific inaccuracies

### Orchestrated Mode

In orchestrated mode, the doc-writer is spawned as an independent agent with a fresh context window. Key characteristics:

- The doc-writer receives: document assignment (type, mode), project context (project root, project type, doc tooling), and existing content (for update/supplement/fix modes)
- Multiple doc-writers may run in parallel for different document types
- Each doc-writer writes its output directly to the project's doc directory (content is not returned through the orchestrator)
- The doc-writer operates on a Standard model tier — documentation generation is important but does not require the reasoning depth of security auditing or code verification
- After generation, the reviewer can be spawned to verify factual claims in the generated documentation

---

## Cross-References

- `design/architecture-overview.md` — Agent Registry entry #10 (doc-writer preserving GSD's documentation generation)
- `design/architecture-overview.md` — Pipeline Stages §6 (Finish) — documentation is generated as part of finishing work
- `design/core-principles.md` — Principle 2 (Context Is the Primary Engineering Investment) — documentation is a form of context that survives session boundaries
- `design/core-principles.md` — Principle 7 (Opinionated About Quality) — documentation quality is enforced through the reviewer's verification mode
- Skills: `finishing-work`, `context-management`, `knowledge-management`
