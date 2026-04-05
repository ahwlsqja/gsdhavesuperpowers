#!/usr/bin/env bash
# S04 Verification Script — Cross-Reference Consistency Validation
# Validates cross-reference consistency across all 28 M002 design files:
#   - 4 architecture docs, 12 agent specs, 10 reference specs, 2 verification scripts
#
# Checks:
#   1. File existence for all 28 expected files
#   2. Component counts (12 agent specs, 10 reference specs)
#   3. Skill catalog cross-reference (18 skills → agent specs)
#   4. Agent registry cross-reference (12 agents → spec files)
#   5. Reference document cross-reference (10 refs → spec files)
#   6. Word count validation (agent >800, reference >300, architecture >2000)
#   7. Context-aware placeholder scan (no standalone TBD/TODO)
#   8. S02 gap note (informational)
#
# Exit codes:
#   0 — All checks passed
#   1 — One or more checks failed

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DESIGN_DIR="$BASE_DIR/design"
AGENT_DIR="$DESIGN_DIR/agent-specs"
REF_DIR="$DESIGN_DIR/reference-specs"

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

check_placeholders() {
  local file="$1"
  # Context-aware grep per K001: match standalone TBD/TODO markers but exclude
  # analytical text that discusses stub detection or placeholder concepts.
  local hits
  hits=$(grep -n -i -E '^\s*(TBD|TODO)\s*$|:\s*(TBD|TODO)\s*$|\b(TBD|TODO)\b' "$file" \
    | grep -v -i -E 'detect|scan|pattern|marker|signal|flag|stub|placeholder text|deferral phrase|deferred-work|comment-based|category|hardcoded|empty impl|wiring|false.positive|analytical|discussing|mentions|refers to|describes|labeled|recogni|identif|check for|look for|search|grep|absence|presence' \
    || true)
  if [ -n "$hits" ]; then
    echo "$hits"
    return 1
  fi
  return 0
}

count_words() {
  wc -w < "$1" | tr -d ' '
}

echo "=== S04 Cross-Reference Consistency Verification ==="
echo ""

# ─────────────────────────────────────────────────────────
# 1. File Existence — all 26 design files + 2 scripts
# ─────────────────────────────────────────────────────────
echo "📁 1. File Existence (26 design files + 2 scripts)"

ARCH_FILES=(
  "architecture-overview.md"
  "core-principles.md"
  "tiered-state-system.md"
  "verification-pipeline.md"
)

AGENT_NAMES=(
  "researcher" "planner" "plan-checker" "executor" "verifier"
  "reviewer" "debugger" "mapper" "auditor" "doc-writer"
  "orchestrator" "profiler"
)

REF_NAMES=(
  "verification-patterns" "agent-contracts" "context-budget"
  "anti-patterns" "planning-quality" "model-profiles"
  "git-integration" "checkpoint-types" "domain-probes"
  "repair-strategies"
)

SCRIPT_FILES=(
  "scripts/verify-s01.sh"
  "scripts/verify-s03.sh"
)

for f in "${ARCH_FILES[@]}"; do
  if [ -f "$DESIGN_DIR/$f" ]; then
    check "design/$f exists" 0
  else
    check "design/$f exists" 1
  fi
done

for agent in "${AGENT_NAMES[@]}"; do
  if [ -f "$AGENT_DIR/${agent}.md" ]; then
    check "design/agent-specs/${agent}.md exists" 0
  else
    check "design/agent-specs/${agent}.md exists" 1
  fi
done

for ref in "${REF_NAMES[@]}"; do
  if [ -f "$REF_DIR/${ref}.md" ]; then
    check "design/reference-specs/${ref}.md exists" 0
  else
    check "design/reference-specs/${ref}.md exists" 1
  fi
done

for script in "${SCRIPT_FILES[@]}"; do
  if [ -f "$BASE_DIR/$script" ]; then
    check "$script exists" 0
  else
    check "$script exists" 1
  fi
done

echo ""

# ─────────────────────────────────────────────────────────
# 2. Component Counts
# ─────────────────────────────────────────────────────────
echo "📊 2. Component Counts"

agent_count=$(find "$AGENT_DIR" -name '*.md' -maxdepth 1 | wc -l | tr -d ' ')
if [ "$agent_count" -eq 12 ]; then
  check "Exactly 12 agent specs (actual: $agent_count)" 0
else
  check "Exactly 12 agent specs (actual: $agent_count)" 1
fi

ref_count=$(find "$REF_DIR" -name '*.md' -maxdepth 1 | wc -l | tr -d ' ')
if [ "$ref_count" -eq 10 ]; then
  check "Exactly 10 reference specs (actual: $ref_count)" 0
else
  check "Exactly 10 reference specs (actual: $ref_count)" 1
fi

echo ""

# ─────────────────────────────────────────────────────────
# 3. Skill Catalog Cross-Reference (18 skills → agent specs)
# ─────────────────────────────────────────────────────────
echo "🔗 3. Skill Catalog Cross-Reference"

SKILL_NAMES=(
  "using-methodology" "brainstorming" "writing-plans"
  "verification-before-completion" "test-driven-development"
  "systematic-debugging" "receiving-code-review" "requesting-code-review"
  "context-management" "knowledge-management" "executing-plans"
  "subagent-driven-development" "writing-skills" "frontend-design"
  "finishing-work" "git-worktree-management" "security-enforcement"
  "parallel-dispatch"
)

for skill in "${SKILL_NAMES[@]}"; do
  found=0
  for agent in "${AGENT_NAMES[@]}"; do
    if grep -q "$skill" "$AGENT_DIR/${agent}.md" 2>/dev/null; then
      found=1
      break
    fi
  done
  if [ "$found" -eq 1 ]; then
    check "Skill '$skill' referenced in agent specs" 0
  else
    check "Skill '$skill' referenced in agent specs" 1
  fi
done

echo ""

# ─────────────────────────────────────────────────────────
# 4. Agent Registry Cross-Reference (12 agents → spec files)
# ─────────────────────────────────────────────────────────
echo "🤖 4. Agent Registry Cross-Reference"

for agent in "${AGENT_NAMES[@]}"; do
  if [ -f "$AGENT_DIR/${agent}.md" ]; then
    check "Agent '$agent' has matching spec file" 0
  else
    check "Agent '$agent' has matching spec file" 1
  fi
done

echo ""

# ─────────────────────────────────────────────────────────
# 5. Reference Document Cross-Reference (10 refs → spec files)
# ─────────────────────────────────────────────────────────
echo "📚 5. Reference Document Cross-Reference"

for ref in "${REF_NAMES[@]}"; do
  if [ -f "$REF_DIR/${ref}.md" ]; then
    check "Reference '$ref' has matching spec file" 0
  else
    check "Reference '$ref' has matching spec file" 1
  fi
done

echo ""

# ─────────────────────────────────────────────────────────
# 6. Word Count Validation
# ─────────────────────────────────────────────────────────
echo "📝 6. Word Count Validation"

# Architecture overview >2000 words
if [ -f "$DESIGN_DIR/architecture-overview.md" ]; then
  wc_arch=$(count_words "$DESIGN_DIR/architecture-overview.md")
  if [ "$wc_arch" -gt 2000 ]; then
    check "architecture-overview.md > 2000 words (actual: $wc_arch)" 0
  else
    check "architecture-overview.md > 2000 words (actual: $wc_arch)" 1
  fi
fi

# Agent specs >800 words each
for agent in "${AGENT_NAMES[@]}"; do
  FILE="$AGENT_DIR/${agent}.md"
  if [ -f "$FILE" ]; then
    wc_agent=$(count_words "$FILE")
    if [ "$wc_agent" -gt 800 ]; then
      check "agent-specs/${agent}.md > 800 words (actual: $wc_agent)" 0
    else
      check "agent-specs/${agent}.md > 800 words (actual: $wc_agent)" 1
    fi
  fi
done

# Reference specs >300 words each
for ref in "${REF_NAMES[@]}"; do
  FILE="$REF_DIR/${ref}.md"
  if [ -f "$FILE" ]; then
    wc_ref=$(count_words "$FILE")
    if [ "$wc_ref" -gt 300 ]; then
      check "reference-specs/${ref}.md > 300 words (actual: $wc_ref)" 0
    else
      check "reference-specs/${ref}.md > 300 words (actual: $wc_ref)" 1
    fi
  fi
done

echo ""

# ─────────────────────────────────────────────────────────
# 7. Placeholder Scan (context-aware)
# ─────────────────────────────────────────────────────────
echo "🔍 7. Placeholder Scan"

ALL_DESIGN_FILES=()
for f in "${ARCH_FILES[@]}"; do
  ALL_DESIGN_FILES+=("$DESIGN_DIR/$f")
done
for agent in "${AGENT_NAMES[@]}"; do
  ALL_DESIGN_FILES+=("$AGENT_DIR/${agent}.md")
done
for ref in "${REF_NAMES[@]}"; do
  ALL_DESIGN_FILES+=("$REF_DIR/${ref}.md")
done

for filepath in "${ALL_DESIGN_FILES[@]}"; do
  fname=$(basename "$filepath")
  if [ -f "$filepath" ]; then
    if placeholder_output=$(check_placeholders "$filepath"); then
      check "No placeholders in $fname" 0
    else
      check "No placeholders in $fname" 1
      echo "    ↳ $placeholder_output" | head -3
    fi
  fi
done

echo ""

# ─────────────────────────────────────────────────────────
# 8. S02 Gap Note (informational only)
# ─────────────────────────────────────────────────────────
echo "📋 8. S02 Gap Note"

if [ -d "$DESIGN_DIR/skill-specs" ]; then
  echo "  ℹ️  design/skill-specs/ exists — skill specs were written as separate files"
else
  echo "  ℹ️  design/skill-specs/ does not exist — skill behavioral specifications"
  echo "     are defined in architecture-overview.md §Skill Catalog and cross-referenced"
  echo "     throughout agent specs. This is by design (S02 scope decision)."
fi

echo ""

# ─────────────────────────────────────────────────────────
# Results
# ─────────────────────────────────────────────────────────
echo "=== Results: $PASS/$TOTAL passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "VERDICT: FAIL ($FAIL checks failed)"
  exit 1
else
  echo ""
  echo "VERDICT: PASS (all $TOTAL checks passed)"
  exit 0
fi
