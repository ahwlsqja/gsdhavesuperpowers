# Reference Specification: Verification Patterns

**Name:** `verification-patterns`
**Scope:** Stub detection signatures, artifact verification levels, and allowlist annotation syntax
**Loading Behavior:** Proactively loaded — this is the only reference injected into every task context regardless of task type
**Consumers:** Verifier agent (Layer 2 programmatic checks), executor agent (self-check protocol), orchestrator agent (stub detector service invocation)
**Research Grounding:** GSD's `verification-patterns.md` (the most detailed stub taxonomy in either system); SYN-01 dual-layer verification synergy

---

## Content Scope

This reference provides the shared pattern library used by the programmatic verification layer (Layer 2) to detect incomplete implementations that pass superficial inspection. It defines five categories of stub patterns, each with detection signatures, example violations, severity levels, and allowlist syntax for justified exceptions.

**What belongs here:** Detection signatures that any agent performing verification needs. Regex patterns, violation examples, severity classifications, and the annotation mechanism for suppressing false positives.

**What does NOT belong here:** The behavioral gate sequence (that is in the `verification-before-completion` skill), the distrust mindset protocol (that is in the verifier agent spec), or the repair operator logic (that is in the `repair-strategies` reference).

---

## The Core Principle: Existence Is Not Implementation

A file existing does not mean the feature works. Verification must confirm four ascending levels:

1. **Exists** — File is present at expected path, non-empty, correct structure
2. **Substantive** — Content is real implementation, not scaffolding or placeholder
3. **Wired** — Connected to the rest of the system (imports used, exports consumed, routes registered)
4. **Functional** — Actually works end-to-end with real data

Levels 1–3 are checked programmatically by the stub detector. Level 4 requires runtime verification (executing commands and observing behavior). The stub detector focuses primarily on Level 2 (substantive) detection because this is where agents most commonly produce incomplete work that looks complete.

---

## Five Stub Detection Categories

### Category 1 — Comment-Based Markers

**Severity:** Warning (isolated) / Critical (clustered — 3+ in one file)

Detects marker comments signaling incomplete implementation. Includes deferred-work flags, attention-needed annotations, and workaround markers that indicate known gaps.

**Detection signatures:**
- Deferred-work markers and attention-needed flags in comments
- Deferral phrases: "implement later", "arriving soon", "add logic here", "needs implementation", "will be added"
- Ellipsis comments: `// ...`, `/* ... */`, `# ...`
- Empty documentation blocks containing only filler descriptions

**Example violations:**
```javascript
// Attention: needs real validation logic here
function validate(input) { return true; }

# Arriving soon: rate limiting
def handle_request(req): pass
```

### Category 2 — Empty Implementations

**Severity:** Critical

Detects function bodies that compile or parse successfully but perform no meaningful work.

**Detection signatures:**
- Functions returning `null`, `undefined`, empty objects `{}`, or empty arrays `[]` without conditional logic
- Arrow functions with empty bodies: `() => {}`
- Functions consisting only of logging statements (console.log, print, logger.info)
- Methods that only call `super()` without adding behavior
- Error handlers that silently swallow exceptions: `catch(e) {}`
- Python `pass` statements as the sole function body

**Example violations:**
```typescript
export function processPayment(amount: number) { return null; }
const handleClick = () => {};
catch(error) { /* silently ignored */ }
```

### Category 3 — Hardcoded Values

**Severity:** Warning (display values) / Critical (business logic)

Detects static data embedded where dynamic behavior is expected.

**Detection signatures:**
- Hardcoded user IDs, entity counts, or monetary values in business logic
- Static arrays returned by functions that should query a data source
- Configuration values embedded in source code rather than loaded from environment or config files
- Date/time values as literals rather than computed expressions
- String IDs assigned directly rather than generated or queried

**Example violations:**
```typescript
function getUsers() { return [{ id: "user-1", name: "Test User" }]; }
const PRICE = 29.99; // Embedded in component, not from config/API
```

### Category 4 — Framework-Specific Patterns

**Severity:** Critical

Detects patterns specific to common frameworks indicating scaffolding rather than implementation.

**React/Next.js patterns:**
- Components returning minimal markup: `<div>ComponentName</div>`, `<p>Loading...</p>`
- Empty event handlers: `onClick={() => {}}`, `onChange={() => console.log('changed')}`
- `onSubmit` handlers that only call `preventDefault()` without processing form data
- Components receiving empty or mock data as hardcoded props

**API route patterns:**
- Endpoints returning empty arrays or static JSON without any data source query
- Route handlers that ignore request parameters or body
- Handlers that log input without processing: `console.log(await req.json()); return Response.json({ ok: true })`

**Database patterns:**
- Models defined without corresponding migration files
- Schemas referenced in code but never seeded or populated
- Query calls whose results are discarded or overridden by static returns

### Category 5 — Wiring Red Flags

**Severity:** Warning (unused imports) / Critical (disconnected data flow)

Detects connection failures between system components — artifacts that exist individually but are not integrated.

**Detection signatures:**
- API fetch calls that discard or ignore the response value
- State variables that are set but never rendered in JSX or used in conditions
- Event handlers that only prevent default behavior without executing business logic
- Imports declared but never referenced in the module body
- Environment variable references without corresponding `.env` entries
- Components exported but never imported by any other module
- Routes defined but not registered in the application router

**Example violations:**
```typescript
fetch('/api/messages'); // No await, no assignment, response discarded
const [data, setData] = useState([]); // data never appears in JSX
onSubmit={(e) => e.preventDefault()} // Only prevents default, no processing
```

---

## Allowlist Annotation Syntax

When a detected pattern is intentional, source code may include an explicit suppression annotation:

```
// verification:allow <category> <reason>
```

Where `<category>` is one of: `comment-marker`, `empty-impl`, `hardcoded`, `framework`, `wiring`.

**Rules governing allowlist annotations:**
- Each annotation must include a reason explaining why the pattern is intentional
- Annotations are subject to periodic audit — the auditor agent flags stale or unjustified annotations
- Annotations suppress detection for the specific line or block, not the entire file
- The presence of many annotations in a single file is itself a warning signal (threshold: 5+ per file)

**Example:**
```typescript
// verification:allow empty-impl This is a no-op handler required by the framework interface
handleDisconnect() {}
```

---

## Usage Patterns

**When loaded:** Proactively injected into every task context. This is the only reference with proactive loading — all other references are loaded on demand.

**Why proactive:** Verification applies to every task. Agents cannot self-identify stub patterns they do not recognize. Having the pattern library always available prevents the "I didn't know that was a stub" failure mode.

**How agents use it:**
- The executor agent uses these patterns in its self-check protocol before writing SUMMARY.md
- The verifier agent uses these patterns as the basis for its programmatic verification sweep
- The stub detector infrastructure service implements these patterns as automated scanners

---

## Maintenance Rules

**When to update:** When a new stub pattern is observed in real agent output that is not covered by the existing five categories. New patterns are added through the `writing-skills` methodology: observe failure → document pattern → add detection signature → verify detection works.

**Who updates:** The reviewer agent may propose new patterns based on code review findings. The verifier agent may propose patterns based on repeated detection misses. Updates require verification that the new pattern does not produce excessive false positives.

**Version discipline:** Each pattern addition must include at least one real-world example violation and a severity classification. Patterns without demonstrated real-world occurrence are deferred until observed.

---

## Cross-References

- `design/verification-pipeline.md` — Layer 2 programmatic verification that consumes these patterns
- `design/agent-specs/verifier.md` — Verifier agent's distrust mindset and 4-level verification using these patterns
- `design/agent-specs/executor.md` — Executor's self-check protocol scanning for these patterns
- Skill: `verification-before-completion` — Behavioral gate that invokes programmatic checking as its second layer
