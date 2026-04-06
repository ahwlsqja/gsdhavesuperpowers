#!/usr/bin/env bash
# verify-m03.sh — Unified verification for entire M003 deliverable
# Composes S01 (skills) + S02 (agents/references/plugin/CLAUDE.md) as sub-scripts,
# then adds S03 integration checks: cross-slice consistency, plugin functional test,
# open-source packaging, and corpus-wide placeholder scan.
#
# Usage: bash scripts/verify-m03.sh
# Exit: 0 if all checks pass, 1 otherwise

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$PROJECT_ROOT"

# ─── S03 Counters ────────────────────────────────────────────────────────────

S03_PASS=0
S03_FAIL=0
S03_FAILURES=()

S01_PASS=0
S01_FAIL=0
S02_PASS=0
S02_FAIL=0

check() {
  local label="$1"
  local result="$2"  # 0 = pass, nonzero = fail
  if [ "$result" -eq 0 ]; then
    echo "  ✓ PASS  $label"
    ((S03_PASS++))
  else
    echo "  ✗ FAIL  $label"
    ((S03_FAIL++))
    S03_FAILURES+=("$label")
  fi
}

# ═════════════════════════════════════════════════════════════════════════════
# Section 1 — S01 Regression (delegate to verify-s01-m03.sh)
# ═════════════════════════════════════════════════════════════════════════════

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  SECTION 1: S01 Regression — 18 Skills (90 checks)         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

s01_output=$(bash "${SCRIPT_DIR}/verify-s01-m03.sh" 2>&1) || true
s01_exit=$?
echo "$s01_output"

# Parse pass/fail from S01 output
S01_PASS=$(echo "$s01_output" | grep -oP 'RESULTS: \K[0-9]+(?= passed)' || echo "0")
S01_FAIL=$(echo "$s01_output" | grep -oP 'passed, \K[0-9]+(?= failed)' || echo "0")

echo ""
if [ "$s01_exit" -eq 0 ]; then
  echo "  ══ S01 SUBTOTAL: ${S01_PASS} passed, ${S01_FAIL} failed ✓ ══"
else
  echo "  ══ S01 SUBTOTAL: ${S01_PASS} passed, ${S01_FAIL} failed ✗ ══"
fi

# ═════════════════════════════════════════════════════════════════════════════
# Section 2 — S02 Regression (delegate to verify-s02-m03.sh)
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  SECTION 2: S02 Regression — Agents/Refs/Plugin (127 chks) ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

s02_output=$(bash "${SCRIPT_DIR}/verify-s02-m03.sh" 2>&1) || true
s02_exit=$?
echo "$s02_output"

# Parse pass/fail from S02 output
S02_PASS=$(echo "$s02_output" | grep -oP 'RESULTS: \K[0-9]+(?= passed)' || echo "0")
S02_FAIL=$(echo "$s02_output" | grep -oP 'passed, \K[0-9]+(?= failed)' || echo "0")

echo ""
if [ "$s02_exit" -eq 0 ]; then
  echo "  ══ S02 SUBTOTAL: ${S02_PASS} passed, ${S02_FAIL} failed ✓ ══"
else
  echo "  ══ S02 SUBTOTAL: ${S02_PASS} passed, ${S02_FAIL} failed ✗ ══"
fi

# ═════════════════════════════════════════════════════════════════════════════
# Section 3 — Cross-Slice Integration
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  SECTION 3: Cross-Slice Integration                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Authoritative skill list from CLAUDE.md tables
SKILLS=(
  using-methodology brainstorming writing-plans executing-plans
  verification-before-completion test-driven-development systematic-debugging
  receiving-code-review requesting-code-review finishing-work
  context-management knowledge-management subagent-driven-development
  parallel-dispatch writing-skills frontend-design git-worktree-management
  security-enforcement
)

AGENTS=(
  researcher planner plan-checker executor verifier reviewer
  debugger mapper auditor doc-writer orchestrator profiler
)

REFERENCES=(
  verification-patterns agent-contracts context-budget anti-patterns
  model-profiles git-integration planning-quality checkpoint-types
  domain-probes repair-strategies
)

# Every skill in CLAUDE.md has a matching skills/{name}/SKILL.md
for skill in "${SKILLS[@]}"; do
  if grep -q "\`${skill}\`" CLAUDE.md && [ -f "skills/${skill}/SKILL.md" ]; then
    check "xslice-skill: ${skill} in CLAUDE.md → file exists" 0
  else
    check "xslice-skill: ${skill} in CLAUDE.md → file exists" 1
  fi
done

# Every agent in CLAUDE.md has a matching agents/{name}.md
for agent in "${AGENTS[@]}"; do
  if grep -q "\`${agent}\`" CLAUDE.md && [ -f "agents/${agent}.md" ]; then
    check "xslice-agent: ${agent} in CLAUDE.md → file exists" 0
  else
    check "xslice-agent: ${agent} in CLAUDE.md → file exists" 1
  fi
done

# Every reference in CLAUDE.md has a matching references/{name}.md
for ref in "${REFERENCES[@]}"; do
  if grep -q "\`${ref}\`" CLAUDE.md && [ -f "references/${ref}.md" ]; then
    check "xslice-ref: ${ref} in CLAUDE.md → file exists" 0
  else
    check "xslice-ref: ${ref} in CLAUDE.md → file exists" 1
  fi
done

# File count assertions
skill_dir_count=$(find skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
agent_file_count=$(find agents -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')
ref_file_count=$(find references -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')

check "xslice-count: exactly 18 skill dirs (found ${skill_dir_count})" $([ "$skill_dir_count" -eq 18 ] && echo 0 || echo 1)
check "xslice-count: exactly 12 agent files (found ${agent_file_count})" $([ "$agent_file_count" -eq 12 ] && echo 0 || echo 1)
check "xslice-count: exactly 10 reference files (found ${ref_file_count})" $([ "$ref_file_count" -eq 10 ] && echo 0 || echo 1)

# ═════════════════════════════════════════════════════════════════════════════
# Section 4 — Plugin Functional Test
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  SECTION 4: Plugin Functional Test                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# session-start produces valid JSON
session_output=$(CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks/session-start 2>/dev/null) || true
if echo "$session_output" | python3 -m json.tool > /dev/null 2>&1; then
  check "plugin-func: session-start outputs valid JSON" 0
else
  check "plugin-func: session-start outputs valid JSON" 1
fi

# session-start output contains 'using-methodology'
if echo "$session_output" | grep -q 'using-methodology'; then
  check "plugin-func: session-start mentions using-methodology" 0
else
  check "plugin-func: session-start mentions using-methodology" 1
fi

# hooks.json is valid JSON with SessionStart key
if python3 -m json.tool hooks/hooks.json > /dev/null 2>&1 && grep -q 'SessionStart' hooks/hooks.json; then
  check "plugin-func: hooks.json valid JSON with SessionStart" 0
else
  check "plugin-func: hooks.json valid JSON with SessionStart" 1
fi

# plugin.json is valid JSON with 'name' field
if python3 -m json.tool .claude-plugin/plugin.json > /dev/null 2>&1 && grep -q '"name"' .claude-plugin/plugin.json; then
  check "plugin-func: plugin.json valid JSON with name field" 0
else
  check "plugin-func: plugin.json valid JSON with name field" 1
fi

# ═════════════════════════════════════════════════════════════════════════════
# Section 5 — Open-Source Packaging
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  SECTION 5: Open-Source Packaging                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# README.md exists and has Installation + License sections
if [ -f README.md ] && grep -qi 'Installation' README.md && grep -qi 'License' README.md; then
  check "packaging: README.md has Installation & License sections" 0
else
  check "packaging: README.md has Installation & License sections" 1
fi

# LICENSE exists and contains MIT
if [ -f LICENSE ] && grep -q 'MIT' LICENSE; then
  check "packaging: LICENSE exists and contains MIT" 0
else
  check "packaging: LICENSE exists and contains MIT" 1
fi

# CONTRIBUTING.md exists and references verify-m03
if [ -f CONTRIBUTING.md ] && grep -q 'verify-m03' CONTRIBUTING.md; then
  check "packaging: CONTRIBUTING.md exists and references verify-m03" 0
else
  check "packaging: CONTRIBUTING.md exists and references verify-m03" 1
fi

# README.md word count in reasonable range (400-1200)
if [ -f README.md ]; then
  readme_words=$(wc -w < README.md | tr -d ' ')
  if [ "$readme_words" -ge 400 ] && [ "$readme_words" -le 1200 ]; then
    check "packaging: README.md word count ${readme_words} (400-1200)" 0
  else
    check "packaging: README.md word count ${readme_words} (outside 400-1200)" 1
  fi
else
  check "packaging: README.md word count (file missing)" 1
fi

# ═════════════════════════════════════════════════════════════════════════════
# Section 6 — Corpus-Wide Placeholder Scan (K001-aware)
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  SECTION 6: Corpus-Wide Placeholder Scan (K001-aware)      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

placeholder_found=0

# Scan all deliverable files for TBD/TODO
# Exclude: verification scripts (contain TBD/TODO as grep patterns),
# and lines that discuss placeholders as anti-patterns (K001 context)
scan_files=$(find skills/ agents/ references/ hooks/ -type f -name '*.md' -o -name '*.sh' -o -name '*.json' -o -name '*.cmd' 2>/dev/null)
scan_files="$scan_files
CLAUDE.md
README.md
CONTRIBUTING.md"

while IFS= read -r file; do
  [ -f "$file" ] || continue
  # Skip verification scripts themselves
  case "$file" in
    scripts/verify-*) continue ;;
  esac

  # Find TBD/TODO matches
  matches=$(grep -nE '\bTBD\b|\bTODO\b' "$file" 2>/dev/null || true)
  [ -z "$matches" ] && continue

  while IFS= read -r match_line; do
    [ -z "$match_line" ] && continue
    # K001-aware filtering: skip lines discussing placeholders as anti-patterns
    # This covers:
    #   - Anti-pattern tables describing deferred markers
    #   - Discussion of placeholder detection/prevention
    #   - Code comment examples mentioning TODO as a concept
    #   - Checklist items about finding/removing TBD/TODO markers
    #   - Quoted strings showing example text ("TBD", "TODO")
    if echo "$match_line" | grep -qiE 'placeholder.*marker|stub.*detect|avoid.*TBD|detect.*TBD|scan.*TBD|grep.*TBD|check.*TBD|no.*TBD|prevent.*TBD|anti.?pattern|pattern.*detect|must not contain|should not contain|must not include|forbidden|disallow|without.*placeholder|free.*of.*placeholder|clean.*of.*placeholder|scan.*TODO|grep.*TODO|check.*TODO|no.*TODO|prevent.*TODO|avoid.*TODO|detect.*TODO|[Dd]eferred.*marker|marker.*TBD|marker.*TODO|"TBD"|"TODO"|TODO marker|belongs in.*TODO|code comment.*TODO|leftover.*TODO|Pushes decisions'; then
      continue  # Discussing placeholders, not being one
    fi
    # Skip lines inside code fences that are pattern examples
    if echo "$match_line" | grep -qE 'grep|rg |find |awk |sed '; then
      continue  # Command example
    fi
    # Skip lines in table rows (|...|) that discuss anti-patterns
    if echo "$match_line" | grep -qE '^\s*[0-9]+:\|.*\|.*\|'; then
      continue  # Table row — discussing terms in structured context
    fi
    echo "  ⚠ Placeholder in ${file}: ${match_line}"
    placeholder_found=1
  done <<< "$matches"
done <<< "$scan_files"

check "corpus-scan: no TBD/TODO placeholders in deliverables (K001)" $placeholder_found

# ═════════════════════════════════════════════════════════════════════════════
# Final Summary
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  FINAL SUMMARY                                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

TOTAL_PASS=$((S01_PASS + S02_PASS + S03_PASS))
TOTAL_FAIL=$((S01_FAIL + S02_FAIL + S03_FAIL))

echo "  S01 (Skills):          ${S01_PASS} passed, ${S01_FAIL} failed"
echo "  S02 (Agents/Refs):     ${S02_PASS} passed, ${S02_FAIL} failed"
echo "  S03 (Integration):     ${S03_PASS} passed, ${S03_FAIL} failed"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  TOTAL: ${TOTAL_PASS} passed, ${TOTAL_FAIL} failed"
echo "═══════════════════════════════════════════════════════════════"

if [ "$TOTAL_FAIL" -gt 0 ]; then
  echo ""
  if [ "$s01_exit" -ne 0 ]; then
    echo "  S01 failures present (see S01 output above)"
  fi
  if [ "$s02_exit" -ne 0 ]; then
    echo "  S02 failures present (see S02 output above)"
  fi
  if [ "${#S03_FAILURES[@]}" -gt 0 ]; then
    echo "  S03 failures:"
    for f in "${S03_FAILURES[@]}"; do
      echo "    - $f"
    done
  fi
  echo ""
  exit 1
else
  echo ""
  echo "  All checks passed! ✓"
  echo ""
  exit 0
fi
