# Domain Probes

## Content Scope

This reference provides domain-specific probing questions that surface hidden assumptions and trade-offs during the discuss/brainstorm phase of project initiation. Questions are organized by technology domain and are designed to be selected contextually — agents pick the 2–3 most relevant probes based on what the user mentions, not run through them as a checklist.

**What belongs here:** Domain-organized probe tables mapping user mentions to follow-up questions, usage guidelines for contextual selection, and coverage across common technology domains.

**What does NOT belong here:** Agent behavioral specifications (those are in agent specs), planning methodology (that is in the `using-methodology` skill), or technology evaluation criteria (those emerge from the brainstorming process).

---

## Usage Pattern

When the user mentions a technology area during the discuss or brainstorm phase, the agent:

1. Identifies the relevant domain category from the tables below
2. Selects the 2–3 most relevant probes based on the specific context
3. Asks follow-up questions that surface hidden requirements, unstated assumptions, and trade-offs
4. Uses the answers to inform requirement capture and planning scope

The goal is insight, not interrogation. Probes should feel like an experienced architect asking the right questions, not a form being filled out.

---

## Domain Categories

### Authentication and Authorization

User mentions of "login", "auth", "users", "accounts", "sessions", "roles", "permissions", or "API keys" trigger probes about: OAuth provider selection, MFA requirements, password reset flows, session duration and refresh strategy, RBAC vs. ABAC models, and API key rotation patterns.

### Real-Time and Communication

User mentions of "real-time", "live updates", "notifications", "collaboration", "chat", or "streaming" trigger probes about: transport mechanism selection (WebSocket, SSE, polling), conflict resolution strategy, reconnection behavior, message persistence, and typing/presence indicators.

### Dashboard and Analytics

User mentions of "dashboard", "charts", "metrics", "admin panel", or "mobile/responsive" trigger probes about: data source architecture, refresh strategy (real-time vs. polling vs. on-demand), interactive vs. static visualization, drill-down capability, and export formats.

### API Design

User mentions of "API", "endpoints", "pagination", "rate limiting", or "errors" trigger probes about: paradigm selection (REST, GraphQL, RPC), versioning strategy, cursor vs. offset pagination, rate limit scoping (per-user, per-IP, per-key), and structured error format design.

### Database and Storage

User mentions of "database", "ORM", "migrations", "seeding", or "scale" trigger probes about: SQL vs. NoSQL selection rationale, migration tooling and rollback strategy, seed data approach, read/write ratio analysis, and connection pooling configuration.

### Search and Discovery

User mentions of "search", "filtering", "autocomplete", "indexing", or "fuzzy matching" trigger probes about: dedicated search engine vs. database-level search, faceted filtering dimensionality, debounce strategy, index update frequency, and typo tolerance requirements.

### File Management

User mentions of "upload", "images", "size limits", "CDN", or "documents" trigger probes about: storage backend selection (local vs. cloud), processing pipeline (resize, compress, thumbnail), per-user storage limits, CDN cache invalidation strategy, and virus scanning requirements.

### Caching Strategy

User mentions of "caching", "invalidation", "stale data", "Redis", or "edge" trigger probes about: cache layer selection (browser, CDN, application, query), invalidation strategy (TTL, event-driven, manual), acceptable staleness window, cache topology, and edge caching for dynamic content.

### Testing Strategy

User mentions of "testing", "mocking", "CI", "coverage", or "E2E" trigger probes about: unit/integration/E2E balance, mock strategy (service mocks vs. test containers), CI pipeline configuration, coverage targets and gating policy, and browser testing framework selection.

### Deployment and Infrastructure

User mentions of "deploy", "CI/CD", "environments", "rollback", or "secrets" trigger probes about: hosting model (container, serverless, managed platform), deployment trigger policy, environment count and parity, rollback strategy (blue-green, canary), and secret management approach.

---

## Cross-References

- **Researcher agent spec:** §Domain Exploration uses these probes during initial project understanding
- **Planner agent spec:** §Discuss Phase loads this reference for facilitation guidance
- **`using-methodology` skill:** The discuss/brainstorm phase references this as the domain probe library
- **`planning-quality` reference:** Probe coverage across relevant domains is a planning quality dimension
