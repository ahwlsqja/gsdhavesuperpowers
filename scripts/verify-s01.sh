#!/usr/bin/env bash
# S01 Verification Script — Architecture & Core Systems Specification
# Checks all 4 design documents for existence, word count, section structure,
# and absence of placeholder markers.
#
# Exit codes:
#   0 — All checks passed
#   1 — One or more checks failed

set -euo pipefail

PASS=0
FAIL=0
TOTAL=0

check() {
  local description="$1"
  local result="$2"  # 0 = pass, non-zero = fail
  TOTAL=$((TOTAL + 1))
  if [ "$result" -eq 0 ]; then
    PASS=$((PASS + 1))
    echo "  ✅ $description"
  else
    FAIL=$((FAIL + 1))
    echo "  ❌ $description"
  fi
}

echo "=== S01 Design Document Verification ==="
echo ""

# --- Document 1: Architecture Overview (T01) ---
echo "📄 design/architecture-overview.md"

if [ -f "design/architecture-overview.md" ]; then
  check "File exists" 0

  wc=$(wc -w < design/architecture-overview.md)
  if [ "$wc" -gt 2000 ]; then
    check "Word count > 2000 (actual: $wc)" 0
  else
    check "Word count > 2000 (actual: $wc)" 1
  fi

  sections=$(grep -c '^## ' design/architecture-overview.md || true)
  if [ "$sections" -ge 5 ]; then
    check "Section count >= 5 (actual: $sections)" 0
  else
    check "Section count >= 5 (actual: $sections)" 1
  fi

  # Check for required sections
  for section in "Unified Vocabulary" "Execution Modes" "Component Map" "Information Flow" "Pipeline Stages"; do
    if grep -q "^## .*${section}" design/architecture-overview.md; then
      check "Has section: $section" 0
    else
      check "Has section: $section" 1
    fi
  done

  # Check for placeholder markers (literal stub strings that indicate incomplete content)
  if grep -qiE '\b(TBD|TODO|FIXME|PLACEHOLDER|COMING SOON)\b' design/architecture-overview.md; then
    check "No placeholder markers" 1
  else
    check "No placeholder markers" 0
  fi
else
  check "File exists" 1
  echo "  (skipping remaining checks — file not found)"
fi

echo ""

# --- Document 2: Tiered State System (T02) ---
echo "📄 design/tiered-state-system.md"

if [ -f "design/tiered-state-system.md" ]; then
  check "File exists" 0

  wc=$(wc -w < design/tiered-state-system.md)
  if [ "$wc" -gt 1500 ]; then
    check "Word count > 1500 (actual: $wc)" 0
  else
    check "Word count > 1500 (actual: $wc)" 1
  fi

  sections=$(grep -c '^## ' design/tiered-state-system.md || true)
  if [ "$sections" -ge 4 ]; then
    check "Section count >= 4 (actual: $sections)" 0
  else
    check "Section count >= 4 (actual: $sections)" 1
  fi

  if grep -qi 'feasibility' design/tiered-state-system.md; then
    check "Contains feasibility assessment" 0
  else
    check "Contains feasibility assessment" 1
  fi

  if grep -qiE '\b(TBD|TODO|FIXME|PLACEHOLDER|COMING SOON)\b' design/tiered-state-system.md; then
    check "No placeholder markers" 1
  else
    check "No placeholder markers" 0
  fi
else
  check "File exists — NOT YET CREATED (expected from T02)" 1
  echo "  (skipping remaining checks — file not found, will be created by T02)"
fi

echo ""

# --- Document 3: Verification Pipeline (T03) ---
echo "📄 design/verification-pipeline.md"

if [ -f "design/verification-pipeline.md" ]; then
  check "File exists" 0

  wc=$(wc -w < design/verification-pipeline.md)
  if [ "$wc" -gt 1500 ]; then
    check "Word count > 1500 (actual: $wc)" 0
  else
    check "Word count > 1500 (actual: $wc)" 1
  fi

  sections=$(grep -c '^## ' design/verification-pipeline.md || true)
  if [ "$sections" -ge 4 ]; then
    check "Section count >= 4 (actual: $sections)" 0
  else
    check "Section count >= 4 (actual: $sections)" 1
  fi

  if grep -qiE '\b(TBD|TODO|FIXME|PLACEHOLDER|COMING SOON)\b' design/verification-pipeline.md; then
    check "No placeholder markers" 1
  else
    check "No placeholder markers" 0
  fi
else
  check "File exists — NOT YET CREATED (expected from T03)" 1
  echo "  (skipping remaining checks — file not found, will be created by T03)"
fi

echo ""

# --- Document 4: Core Principles (T04) ---
echo "📄 design/core-principles.md"

if [ -f "design/core-principles.md" ]; then
  check "File exists" 0

  wc=$(wc -w < design/core-principles.md)
  if [ "$wc" -gt 1000 ]; then
    check "Word count > 1000 (actual: $wc)" 0
  else
    check "Word count > 1000 (actual: $wc)" 1
  fi

  sections=$(grep -c '^## ' design/core-principles.md || true)
  if [ "$sections" -ge 4 ]; then
    check "Section count >= 4 (actual: $sections)" 0
  else
    check "Section count >= 4 (actual: $sections)" 1
  fi

  if grep -qiE '\b(TBD|TODO|FIXME|PLACEHOLDER|COMING SOON)\b' design/core-principles.md; then
    check "No placeholder markers" 1
  else
    check "No placeholder markers" 0
  fi
else
  check "File exists — NOT YET CREATED (expected from T04)" 1
  echo "  (skipping remaining checks — file not found, will be created by T04)"
fi

echo ""

# --- Cross-Reference Checks ---
echo "📋 Cross-Reference Consistency"

if [ -f "design/architecture-overview.md" ]; then
  # Check that architecture overview references the other three documents
  if grep -q 'tiered-state-system' design/architecture-overview.md; then
    check "Architecture references tiered-state-system.md" 0
  else
    check "Architecture references tiered-state-system.md" 1
  fi

  if grep -q 'verification-pipeline' design/architecture-overview.md; then
    check "Architecture references verification-pipeline.md" 0
  else
    check "Architecture references verification-pipeline.md" 1
  fi

  if grep -q 'core-principles' design/architecture-overview.md; then
    check "Architecture references core-principles.md" 0
  else
    check "Architecture references core-principles.md" 1
  fi

  # Check that skill catalog has entries
  skill_count=$(grep -c '| [0-9]' design/architecture-overview.md || true)
  if [ "$skill_count" -ge 15 ]; then
    check "Skill catalog has >= 15 entries (actual: $skill_count)" 0
  else
    check "Skill catalog has >= 15 entries (actual: $skill_count)" 1
  fi

  # Check that agent registry has entries
  agent_mentions=$(grep -c '`researcher`\|`planner`\|`executor`\|`verifier`' design/architecture-overview.md || true)
  if [ "$agent_mentions" -ge 4 ]; then
    check "Agent registry has core agents (found: $agent_mentions mentions)" 0
  else
    check "Agent registry has core agents (found: $agent_mentions mentions)" 1
  fi
fi

echo ""
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
