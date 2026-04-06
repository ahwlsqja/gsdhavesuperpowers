#!/usr/bin/env bash
# verify-s02-m03.sh — Structural verification for S02 outputs (M003)
# Validates 12 agent files, 10 reference files, plugin infrastructure,
# CLAUDE.md completeness, and cross-references between all artifacts.

set -uo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────

AGENTS_DIR="${1:-agents}"
REFS_DIR="${2:-references}"
SKILLS_DIR="${3:-skills}"

# Authoritative lists
AGENTS=(
  auditor
  debugger
  doc-writer
  executor
  mapper
  orchestrator
  plan-checker
  planner
  profiler
  researcher
  reviewer
  verifier
)

REFERENCES=(
  agent-contracts
  anti-patterns
  checkpoint-types
  context-budget
  domain-probes
  git-integration
  model-profiles
  planning-quality
  repair-strategies
  verification-patterns
)

SKILLS=(
  brainstorming
  context-management
  executing-plans
  finishing-work
  frontend-design
  git-worktree-management
  knowledge-management
  parallel-dispatch
  receiving-code-review
  requesting-code-review
  security-enforcement
  subagent-driven-development
  systematic-debugging
  test-driven-development
  using-methodology
  verification-before-completion
  writing-plans
  writing-skills
)

# ─── Counters ────────────────────────────────────────────────────────────────

PASS=0
FAIL=0
FAILURES=()

# ─── Helpers ─────────────────────────────────────────────────────────────────

check() {
  local label="$1"
  local result="$2"  # 0 = pass, nonzero = fail
  if [ "$result" -eq 0 ]; then
    echo "  ✓ PASS  $label"
    ((PASS++))
  else
    echo "  ✗ FAIL  $label"
    ((FAIL++))
    FAILURES+=("$label")
  fi
}

# ─── 1. Reference File Existence & Non-Empty (10) ───────────────────────────

echo "═══ 1. Reference File Existence (≥100 words) ═══"
for ref in "${REFERENCES[@]}"; do
  file="${REFS_DIR}/${ref}.md"
  if [ ! -f "$file" ]; then
    check "ref-exists: ${ref}" 1
    continue
  fi
  word_count=$(wc -w < "$file")
  if [ "$word_count" -ge 100 ]; then
    check "ref-exists: ${ref} (${word_count} words)" 0
  else
    check "ref-exists: ${ref} (${word_count} words, need ≥100)" 1
  fi
done

# ─── 2. Agent File Existence & Non-Empty (12) ───────────────────────────────

echo ""
echo "═══ 2. Agent File Existence (≥200 words) ═══"
for agent in "${AGENTS[@]}"; do
  file="${AGENTS_DIR}/${agent}.md"
  if [ ! -f "$file" ]; then
    check "agent-exists: ${agent}" 1
    continue
  fi
  word_count=$(wc -w < "$file")
  if [ "$word_count" -ge 200 ]; then
    check "agent-exists: ${agent} (${word_count} words)" 0
  else
    check "agent-exists: ${agent} (${word_count} words, need ≥200)" 1
  fi
done

# ─── 3. Agent YAML Frontmatter (12) ─────────────────────────────────────────

echo ""
echo "═══ 3. Agent YAML Frontmatter ═══"
REQUIRED_FIELDS=(name description model_tier skills_used references_used)
for agent in "${AGENTS[@]}"; do
  file="${AGENTS_DIR}/${agent}.md"
  if [ ! -f "$file" ]; then
    check "frontmatter: ${agent} (file missing)" 1
    continue
  fi

  # Must start with --- and have closing ---
  if ! head -1 "$file" | grep -q '^---$'; then
    check "frontmatter: ${agent} (no opening ---)" 1
    continue
  fi

  # Extract frontmatter between first and second ---
  frontmatter=$(awk '/^---$/{n++; if(n==2) exit} n==1{print}' "$file")
  if [ -z "$frontmatter" ]; then
    check "frontmatter: ${agent} (no closing ---)" 1
    continue
  fi

  # Check required fields
  missing=()
  for field in "${REQUIRED_FIELDS[@]}"; do
    if ! echo "$frontmatter" | grep -q "^${field}:"; then
      missing+=("$field")
    fi
  done

  if [ ${#missing[@]} -eq 0 ]; then
    check "frontmatter: ${agent}" 0
  else
    check "frontmatter: ${agent} (missing: ${missing[*]})" 1
  fi
done

# ─── 4. Agent Skills Cross-Reference ────────────────────────────────────────

echo ""
echo "═══ 4. Agent Skills Cross-Reference ═══"
for agent in "${AGENTS[@]}"; do
  file="${AGENTS_DIR}/${agent}.md"
  [ -f "$file" ] || continue

  # Extract skills_used list from frontmatter
  in_skills=false
  while IFS= read -r line; do
    if echo "$line" | grep -q '^skills_used:'; then
      in_skills=true
      continue
    fi
    if [ "$in_skills" = true ]; then
      if echo "$line" | grep -q '^  - '; then
        skill_name=$(echo "$line" | sed 's/^  - //')
        if [ -d "${SKILLS_DIR}/${skill_name}" ] && [ -f "${SKILLS_DIR}/${skill_name}/SKILL.md" ]; then
          check "xref-skill: ${agent} → ${skill_name}" 0
        else
          check "xref-skill: ${agent} → ${skill_name} (skill not found)" 1
        fi
      else
        break
      fi
    fi
  done < <(awk '/^---$/{n++; if(n==2) exit} n>=1{print}' "$file")
done

# ─── 5. Agent References Cross-Reference ────────────────────────────────────

echo ""
echo "═══ 5. Agent References Cross-Reference ═══"
for agent in "${AGENTS[@]}"; do
  file="${AGENTS_DIR}/${agent}.md"
  [ -f "$file" ] || continue

  # Extract references_used list from frontmatter
  in_refs=false
  while IFS= read -r line; do
    if echo "$line" | grep -q '^references_used:'; then
      in_refs=true
      continue
    fi
    if [ "$in_refs" = true ]; then
      if echo "$line" | grep -q '^  - '; then
        ref_name=$(echo "$line" | sed 's/^  - //')
        if [ -f "${REFS_DIR}/${ref_name}.md" ]; then
          check "xref-ref: ${agent} → ${ref_name}" 0
        else
          check "xref-ref: ${agent} → ${ref_name} (reference not found)" 1
        fi
      else
        break
      fi
    fi
  done < <(awk '/^---$/{n++; if(n==2) exit} n>=1{print}' "$file")
done

# ─── 6. Plugin Infrastructure (5) ───────────────────────────────────────────

echo ""
echo "═══ 6. Plugin Infrastructure ═══"

# hooks.json exists and is valid JSON
if [ -f "hooks/hooks.json" ]; then
  if python3 -m json.tool hooks/hooks.json > /dev/null 2>&1; then
    check "plugin: hooks/hooks.json valid JSON" 0
  else
    check "plugin: hooks/hooks.json invalid JSON" 1
  fi
else
  check "plugin: hooks/hooks.json (missing)" 1
fi

# session-start exists and is executable
if [ -f "hooks/session-start" ] && [ -x "hooks/session-start" ]; then
  check "plugin: hooks/session-start exists & executable" 0
else
  check "plugin: hooks/session-start (missing or not executable)" 1
fi

# session-start references using-methodology
if [ -f "hooks/session-start" ] && grep -q 'using-methodology' hooks/session-start; then
  check "plugin: session-start references using-methodology" 0
else
  check "plugin: session-start missing using-methodology reference" 1
fi

# run-hook.cmd exists
if [ -f "hooks/run-hook.cmd" ]; then
  check "plugin: hooks/run-hook.cmd exists" 0
else
  check "plugin: hooks/run-hook.cmd (missing)" 1
fi

# plugin.json exists and is valid JSON
if [ -f ".claude-plugin/plugin.json" ]; then
  if python3 -m json.tool .claude-plugin/plugin.json > /dev/null 2>&1; then
    check "plugin: .claude-plugin/plugin.json valid JSON" 0
  else
    check "plugin: .claude-plugin/plugin.json invalid JSON" 1
  fi
else
  check "plugin: .claude-plugin/plugin.json (missing)" 1
fi

# ─── 7. CLAUDE.md Completeness ──────────────────────────────────────────────

echo ""
echo "═══ 7. CLAUDE.md Completeness ═══"

# Exists and is ≤2000 words
if [ -f "CLAUDE.md" ]; then
  claude_words=$(wc -w < CLAUDE.md)
  if [ "$claude_words" -le 2000 ]; then
    check "claude: exists & ≤2000 words (${claude_words})" 0
  else
    check "claude: too long (${claude_words} words, max 2000)" 1
  fi
else
  check "claude: CLAUDE.md missing" 1
fi

# CLAUDE.md mentions all 18 skill names
echo "  --- skill mentions ---"
for skill in "${SKILLS[@]}"; do
  if grep -q "${skill}" CLAUDE.md 2>/dev/null; then
    check "claude-skill: ${skill}" 0
  else
    check "claude-skill: ${skill} (not mentioned)" 1
  fi
done

# CLAUDE.md mentions all 12 agent names
echo "  --- agent mentions ---"
for agent in "${AGENTS[@]}"; do
  if grep -q "${agent}" CLAUDE.md 2>/dev/null; then
    check "claude-agent: ${agent}" 0
  else
    check "claude-agent: ${agent} (not mentioned)" 1
  fi
done

# CLAUDE.md mentions all 10 reference names
echo "  --- reference mentions ---"
for ref in "${REFERENCES[@]}"; do
  if grep -q "${ref}" CLAUDE.md 2>/dev/null; then
    check "claude-ref: ${ref}" 0
  else
    check "claude-ref: ${ref} (not mentioned)" 1
  fi
done

# ─── 8. No Placeholder Text ─────────────────────────────────────────────────

echo ""
echo "═══ 8. No Placeholder Text ═══"

placeholder_found=0

# Scan agent files for standalone TBD/TODO/FIXME at line start
for agent in "${AGENTS[@]}"; do
  file="${AGENTS_DIR}/${agent}.md"
  [ -f "$file" ] || continue
  # Match lines starting with TBD, TODO:, or FIXME: (not inside discussion/examples)
  matches=$(grep -nE '^(TBD|TODO:|FIXME:)' "$file" || true)
  if [ -n "$matches" ]; then
    echo "  ⚠ Placeholder in ${agent}: ${matches}"
    placeholder_found=1
  fi
done

# Scan reference files
for ref in "${REFERENCES[@]}"; do
  file="${REFS_DIR}/${ref}.md"
  [ -f "$file" ] || continue
  matches=$(grep -nE '^(TBD|TODO:|FIXME:)' "$file" || true)
  if [ -n "$matches" ]; then
    # Context-aware: skip if the match is in a code block or discussing anti-patterns
    while IFS= read -r match_line; do
      line_num=$(echo "$match_line" | cut -d: -f1)
      # Check surrounding context (2 lines before) for code fence or anti-pattern discussion
      context=$(sed -n "$((line_num > 2 ? line_num - 2 : 1)),${line_num}p" "$file")
      if echo "$context" | grep -qiE 'placeholder|anti-pattern|stub detection|example|pattern.*detect'; then
        continue  # Skip — it's discussing placeholders, not being one
      fi
      if echo "$context" | grep -q '```'; then
        continue  # Skip — inside or near a code fence
      fi
      echo "  ⚠ Placeholder in ${ref}: ${match_line}"
      placeholder_found=1
    done <<< "$matches"
  fi
done

check "no-placeholders: agent and reference files" $placeholder_found

# ─── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════"
echo "  RESULTS: ${PASS} passed, ${FAIL} failed"
echo "═══════════════════════════════════════════════"

if [ "${#FAILURES[@]}" -gt 0 ]; then
  echo ""
  echo "  Failed checks:"
  for f in "${FAILURES[@]}"; do
    echo "    - $f"
  done
  echo ""
  exit 1
else
  echo ""
  echo "  All checks passed! ✓"
  echo ""
  exit 0
fi
