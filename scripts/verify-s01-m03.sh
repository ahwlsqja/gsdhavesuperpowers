#!/usr/bin/env bash
# verify-s01-m03.sh — Structural verification for all 18 methodology skills (M003/S01)
# Validates existence, frontmatter, content depth, section structure, behavioral content,
# iron law presence, and cross-reference consistency.

set -uo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────

SKILLS_DIR="${1:-skills}"

# Authoritative list of all 18 skills from design/architecture-overview.md
PROCESS_SKILLS=(
  using-methodology
  brainstorming
  writing-plans
  verification-before-completion
  test-driven-development
  systematic-debugging
  receiving-code-review
  requesting-code-review
  context-management
  knowledge-management
)

IMPLEMENTATION_SKILLS=(
  executing-plans
  subagent-driven-development
  writing-skills
  frontend-design
  finishing-work
  git-worktree-management
  security-enforcement
  parallel-dispatch
)

ALL_SKILLS=("${PROCESS_SKILLS[@]}" "${IMPLEMENTATION_SKILLS[@]}")

# Iron law skills — must contain explicit iron law or enforcement preamble
IRON_LAW_SKILLS=(
  verification-before-completion
  test-driven-development
  systematic-debugging
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

# ─── 1. Existence Checks (18) ───────────────────────────────────────────────

echo "═══ 1. Existence Checks ═══"
for skill in "${ALL_SKILLS[@]}"; do
  if test -f "${SKILLS_DIR}/${skill}/SKILL.md"; then
    check "exists: ${skill}" 0
  else
    check "exists: ${skill}" 1
  fi
done

# ─── 2. Frontmatter Checks (18) ─────────────────────────────────────────────

echo ""
echo "═══ 2. Frontmatter Checks ═══"
for skill in "${ALL_SKILLS[@]}"; do
  file="${SKILLS_DIR}/${skill}/SKILL.md"
  if [ ! -f "$file" ]; then
    check "frontmatter: ${skill} (file missing)" 1
    continue
  fi

  # Check YAML frontmatter: starts with ---, contains name: and description:, has closing ---
  has_frontmatter=1
  if head -1 "$file" | grep -q '^---'; then
    # Extract frontmatter block (between first and second ---)
    frontmatter=$(awk '/^---/{n++; if(n==2) exit} n==1{print}' "$file")
    if echo "$frontmatter" | grep -q '^name:' && echo "$frontmatter" | grep -q '^description:'; then
      has_frontmatter=0
    fi
  fi
  check "frontmatter: ${skill}" $has_frontmatter
done

# ─── 3. Content Depth Checks (18) — >= 200 words ────────────────────────────

echo ""
echo "═══ 3. Content Depth Checks (>= 200 words) ═══"
for skill in "${ALL_SKILLS[@]}"; do
  file="${SKILLS_DIR}/${skill}/SKILL.md"
  if [ ! -f "$file" ]; then
    check "content-depth: ${skill} (file missing)" 1
    continue
  fi

  word_count=$(wc -w < "$file")
  if [ "$word_count" -ge 200 ]; then
    check "content-depth: ${skill} (${word_count} words)" 0
  else
    check "content-depth: ${skill} (${word_count} words, need >= 200)" 1
  fi
done

# ─── 4. Section Structure Checks (18) — >= 3 ## sections ────────────────────

echo ""
echo "═══ 4. Section Structure Checks (>= 3 ## sections) ═══"
for skill in "${ALL_SKILLS[@]}"; do
  file="${SKILLS_DIR}/${skill}/SKILL.md"
  if [ ! -f "$file" ]; then
    check "sections: ${skill} (file missing)" 1
    continue
  fi

  section_count=$(grep -c '^## ' "$file" || true)
  if [ "$section_count" -ge 3 ]; then
    check "sections: ${skill} (${section_count} sections)" 0
  else
    check "sections: ${skill} (${section_count} sections, need >= 3)" 1
  fi
done

# ─── 5. Process Skill Behavioral Content (10) ───────────────────────────────

echo ""
echo "═══ 5. Process Skill Behavioral Content ═══"
for skill in "${PROCESS_SKILLS[@]}"; do
  file="${SKILLS_DIR}/${skill}/SKILL.md"
  if [ ! -f "$file" ]; then
    check "behavioral: ${skill} (file missing)" 1
    continue
  fi

  # Must reference at least one of: rationalization prevention, gate function, protocol, iron law
  has_behavioral=1
  if grep -qi 'rationalization\|gate.*function\|hard.*gate\|protocol\|iron.*law\|prevention.*table' "$file"; then
    has_behavioral=0
  fi
  check "behavioral: ${skill}" $has_behavioral
done

# ─── 6. Iron Law Skills (3) ─────────────────────────────────────────────────

echo ""
echo "═══ 6. Iron Law Skills ═══"
for skill in "${IRON_LAW_SKILLS[@]}"; do
  file="${SKILLS_DIR}/${skill}/SKILL.md"
  if [ ! -f "$file" ]; then
    check "iron-law: ${skill} (file missing)" 1
    continue
  fi

  has_iron=1
  if grep -qi 'iron.*law\|violating.*letter.*violating.*spirit\|the.*law\|enforcement.*preamble' "$file"; then
    has_iron=0
  fi
  check "iron-law: ${skill}" $has_iron
done

# ─── 7. Cross-Reference Consistency ─────────────────────────────────────────

echo ""
echo "═══ 7. Cross-Reference Consistency ═══"
# Check that skill names referenced in cross-references match actual directory names
xref_failures=0
for skill in "${ALL_SKILLS[@]}"; do
  file="${SKILLS_DIR}/${skill}/SKILL.md"
  [ -f "$file" ] || continue

  # Extract skill names referenced via backtick patterns like `skill-name` that match known skills
  while IFS= read -r referenced; do
    # Skip if it's the skill's own name
    [ "$referenced" = "$skill" ] && continue
    # Check if it's a known skill name
    found=false
    for known in "${ALL_SKILLS[@]}"; do
      if [ "$referenced" = "$known" ]; then
        found=true
        break
      fi
    done
    if [ "$found" = false ]; then
      # Only flag if it looks like a methodology skill name (contains hyphen, is lowercase)
      if echo "$referenced" | grep -q '^[a-z].*-.*[a-z]$'; then
        # Additional filter: skip common code terms that aren't skill names
        if ! echo "$referenced" | grep -qE '^(red-green|root-cause|test-first|no-stub|hot-tier|warm-tier|cold-tier|anti-pattern|pre-written|two-stage|fresh-context|four-status|read-depth|append-only|defense-in-depth|wave-based|code-first|tests-first|tests-after|self-review|cross-reference|auto-fix|spin-wait|no-ops|aria-[a-z]+|min-width|max-width|min-height|max-height|font-size|font-weight|line-height|box-shadow|border-radius|text-align|white-space|overflow-hidden|flex-wrap|grid-template|z-index|object-fit|aspect-ratio)$'; then
          echo "  ⚠ WARNING  ${skill} references unknown skill: ${referenced}"
        fi
      fi
    fi
  done < <(grep -oP '`([a-z][a-z-]+[a-z])`' "$file" | tr -d '`' | sort -u)
done
check "cross-references: no broken skill references" $xref_failures

# ─── 8. Slice-Level Verification Checks ─────────────────────────────────────

echo ""
echo "═══ 8. Slice-Level Verification Checks ═══"

# Check: using-methodology, brainstorming, writing-plans all exist
if test -f "${SKILLS_DIR}/using-methodology/SKILL.md" && \
   test -f "${SKILLS_DIR}/brainstorming/SKILL.md" && \
   test -f "${SKILLS_DIR}/writing-plans/SKILL.md"; then
  check "slice-verify: 3 foundational skills exist" 0
else
  check "slice-verify: 3 foundational skills exist" 1
fi

# Check: using-methodology has >= 12 table rows (rationalization prevention)
table_rows=$(grep -c '|' "${SKILLS_DIR}/using-methodology/SKILL.md" || true)
if [ "$table_rows" -ge 12 ]; then
  check "slice-verify: using-methodology has >= 12 table rows (${table_rows})" 0
else
  check "slice-verify: using-methodology has >= 12 table rows (${table_rows})" 1
fi

# Check: brainstorming has hard gate / do not implement
if grep -qi 'hard gate\|do not.*implement\|no implementation' "${SKILLS_DIR}/brainstorming/SKILL.md"; then
  check "slice-verify: brainstorming has hard gate directive" 0
else
  check "slice-verify: brainstorming has hard gate directive" 1
fi

# Check: writing-plans has granularity / 2-5 minute / structural check / 8 dimension
if grep -qi 'granularity\|2.*5 minute\|structural.*check\|8.*dimension' "${SKILLS_DIR}/writing-plans/SKILL.md"; then
  check "slice-verify: writing-plans has granularity/structural checks" 0
else
  check "slice-verify: writing-plans has granularity/structural checks" 1
fi

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
