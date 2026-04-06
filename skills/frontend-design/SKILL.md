---
name: frontend-design
description: "Use when building user interfaces, implementing frontend components, creating web pages, or working on any user-visible UI. Triggers: 'build a UI', 'create a component', 'design a page', React/Vue/Svelte component work, HTML/CSS implementation, 'make it look good', responsive layout, accessibility requirements. If the task produces something a user will see and interact with, invoke this skill."
---

# Frontend Design

## Core Principle: UI Is a Contract With the User

Every interface element is a promise — a button promises an action, a loading indicator promises eventual content, an error message promises guidance toward resolution. Broken promises (buttons that do nothing, spinners that spin forever, errors that say "something went wrong") erode trust faster than missing features. Build interfaces that keep their promises.

## Component Architecture

### Component Boundaries
A component should do one thing completely. The boundary test: can you describe what this component does in one sentence without using "and"? If not, split it.

### Component Hierarchy
1. **Primitives** — Buttons, inputs, text, icons. Stateless. Accept data, render UI, emit events. No business logic.
2. **Composites** — Forms, cards, list items. Compose primitives. May hold local UI state. No API calls.
3. **Features** — Complete UI units. Manage data fetching, state, error handling. This is where business logic lives.
4. **Pages/Routes** — Layout and routing. Compose features. Handle URL state. Minimal logic.

Data flows down. Events flow up. Side effects live in features, not primitives.

### State Management Rules
- **UI state** (open/closed, hover, focus): local to the component
- **Form state** (input values, validation): local to the form feature
- **Server state** (API data): managed by a data-fetching layer (React Query, SWR). Not global state.
- **App state** (auth, theme, feature flags): global store or context — the only truly global state

If you're putting server data in a global store and synchronizing manually, you're building a broken cache.

## Accessibility Requirements

Accessibility is not optional, not a nice-to-have, and not "we'll add it later."

### Semantic HTML First

| Need | Correct Element | Wrong Approach |
|------|----------------|----------------|
| Navigation | `<a href="...">` | `<div onClick={navigate}>` |
| Action trigger | `<button>` | `<span onClick={...}>` |
| Form field | `<input>`, `<select>`, `<textarea>` | `<div contentEditable>` |
| List of items | `<ul>/<li>` or `<ol>/<li>` | Nested `<div>` elements |
| Table data | `<table>/<thead>/<tbody>` | CSS grid of divs |
| Section heading | `<h1>`–`<h6>` (in order) | `<div class="heading">` |
| Page region | `<main>`, `<nav>`, `<aside>` | `<div class="main">` |

### Keyboard Navigation
- **Tab order** follows visual order. Fix DOM order, not tabindex.
- **Focus indicators** must be visible. Never `outline: none` without a custom alternative.
- **Escape** closes modals, dropdowns, and overlays. Always.
- **Enter/Space** activates buttons and links.
- **Arrow keys** navigate within composite widgets (tabs, menus, radio groups).

### ARIA When Semantic HTML Is Insufficient
- Icon-only buttons need `aria-label`
- Dynamic content regions need `aria-live`
- Custom widgets need `role`, `aria-expanded`, `aria-selected`
- Form errors need `aria-describedby` linking error to input

**The ARIA rule:** No ARIA is better than wrong ARIA.

## Visual Polish Guidelines

### Spacing and Rhythm
Use a consistent spacing scale (4px or 8px base). Inconsistent spacing is the fastest way to make a UI look amateur.
- **Within components:** 4-8px between related elements
- **Between components:** 16-24px between distinct groups
- **Between sections:** 32-48px between major page sections

### Typography
- **Hierarchy:** 3-4 distinct text sizes. More creates visual noise.
- **Line height:** Body at 1.5-1.6, headings at 1.1-1.3.
- **Max width:** Body text max 65-75 characters (`max-width: 65ch`).

### Loading States
Every async operation needs three states:
1. **Loading:** Skeleton screens for layout, spinners for actions
2. **Error:** Specific message + what the user can do. "Something went wrong" is never acceptable.
3. **Empty:** Distinguish from loading and error. Provide guidance.

## Responsive Design

### Mobile-First
Write styles for smallest viewport first, add complexity with `min-width` queries.

### Breakpoints
- **< 640px:** Single column. Touch targets minimum 44x44px.
- **640-1024px:** Two columns where helpful. Collapsible navigation.
- **> 1024px:** Full layout with sidebars and expanded navigation.

Test at each breakpoint AND between breakpoints.

## Performance Patterns

- **Virtualize long lists.** Over ~50 items, render only visible items.
- **Lazy load below-the-fold content.** Images, components, data not visible on initial load.
- **Optimize images.** Serve appropriately sized, modern formats (WebP/AVIF). Always set `width`/`height` on `<img>`.
- **Check bundle impact.** Before adding a library: check size, consider if native code suffices, verify tree-shaking works.
- **WCAG AA contrast:** 4.5:1 for normal text, 3:1 for large text. Don't rely on color alone.
