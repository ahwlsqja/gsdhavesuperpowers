#!/usr/bin/env bash
# S03 Verification Script — Agent Definitions & Reference Document Specifications
# Runs in partial mode: only validates files that exist.
# Final pass in T04 validates everything.

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
AGENT_DIR="$BASE_DIR/design/agent-specs"
REF_DIR="$BASE_DIR/design/reference-specs"

PASS=0
FAIL=0
SKIP=0
ERRORS=()

# --- Helpers ---

count_words() {
  wc -w < "$1" | tr -d ' '
}

count_sections() {
  grep -c '^##' "$1" 2>/dev/null || echo 0
}

check_placeholders() {
  local file="$1"
  # Context-aware grep: match standalone TBD/TODO markers but not analytical
  # text that discusses stub detection or placeholder concepts.
  # Exclude lines containing: "detect", "scan", "pattern", "marker", "signal",
  # "flag", "stub", "placeholder text", "deferral phrase", "deferred-work"
  local hits
  hits=$(grep -n -i -E '^\s*(TBD|TODO)\s*$|:\s*(TBD|TODO)\s*$|\b(TBD|TODO)\b' "$file" \
    | grep -v -i -E 'detect|scan|pattern|marker|signal|flag|stub|placeholder text|deferral phrase|deferred-work|comment-based|category|hardcoded|empty impl|wiring|false.positive|analytical|discussing|mentions|refers to|describes|labeled' \
    || true)
  if [ -n "$hits" ]; then
    echo "$hits"
    return 1
  fi
  return 0
}

check_skill_reference() {
  local file="$1"
  # Check that agent specs reference at least one skill name from the 18-skill catalog
  local skills=(
    "using-methodology" "brainstorming" "writing-plans"
    "verification-before-completion" "test-driven-development"
    "systematic-debugging" "receiving-code-review" "requesting-code-review"
    "context-management" "knowledge-management" "executing-plans"
    "subagent-driven-development" "writing-skills" "frontend-design"
    "finishing-work" "git-worktree-management" "security-enforcement"
    "parallel-dispatch"
  )
  for skill in "${skills[@]}"; do
    if grep -q "$skill" "$file" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

check_agent_reference() {
  local file="$1"
  # Check that reference specs reference at least one agent name
  local agents=(
    "researcher" "planner" "plan-checker" "executor" "verifier"
    "reviewer" "debugger" "mapper" "auditor" "doc-writer"
    "orchestrator" "profiler"
  )
  for agent in "${agents[@]}"; do
    if grep -q -i "\b${agent}\b" "$file" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

# --- Agent Spec Checks ---

PIPELINE_AGENTS=("researcher" "planner" "plan-checker" "executor" "verifier")
SPECIALIST_AGENTS=("reviewer" "debugger" "mapper" "auditor" "doc-writer" "orchestrator" "profiler")

echo "=== S03 Verification ==="
echo ""
echo "--- Pipeline Agent Specs (800+ words, 5+ sections) ---"

for agent in "${PIPELINE_AGENTS[@]}"; do
  FILE="$AGENT_DIR/${agent}.md"
  if [ ! -f "$FILE" ]; then
    echo "  SKIP  $agent.md (not yet created)"
    SKIP=$((SKIP + 1))
    continue
  fi

  words=$(count_words "$FILE")
  sections=$(count_sections "$FILE")
  errors_for_file=()

  if [ "$words" -lt 800 ]; then
    errors_for_file+=("word count $words < 800")
  fi
  if [ "$sections" -lt 5 ]; then
    errors_for_file+=("section count $sections < 5")
  fi
  if ! check_skill_reference "$FILE"; then
    errors_for_file+=("no skill reference found")
  fi
  if placeholder_hits=$(check_placeholders "$FILE"); [ $? -ne 0 ]; then
    errors_for_file+=("placeholder markers found")
  fi

  if [ ${#errors_for_file[@]} -eq 0 ]; then
    echo "  PASS  $agent.md ($words words, $sections sections)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $agent.md: ${errors_for_file[*]}"
    FAIL=$((FAIL + 1))
    ERRORS+=("$agent.md: ${errors_for_file[*]}")
  fi
done

echo ""
echo "--- Specialist Agent Specs (400+ words, 5+ sections) ---"

for agent in "${SPECIALIST_AGENTS[@]}"; do
  FILE="$AGENT_DIR/${agent}.md"
  if [ ! -f "$FILE" ]; then
    echo "  SKIP  $agent.md (not yet created)"
    SKIP=$((SKIP + 1))
    continue
  fi

  words=$(count_words "$FILE")
  sections=$(count_sections "$FILE")
  errors_for_file=()

  if [ "$words" -lt 400 ]; then
    errors_for_file+=("word count $words < 400")
  fi
  if [ "$sections" -lt 5 ]; then
    errors_for_file+=("section count $sections < 5")
  fi
  if ! check_skill_reference "$FILE"; then
    errors_for_file+=("no skill reference found")
  fi
  if placeholder_hits=$(check_placeholders "$FILE"); [ $? -ne 0 ]; then
    errors_for_file+=("placeholder markers found")
  fi

  if [ ${#errors_for_file[@]} -eq 0 ]; then
    echo "  PASS  $agent.md ($words words, $sections sections)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $agent.md: ${errors_for_file[*]}"
    FAIL=$((FAIL + 1))
    ERRORS+=("$agent.md: ${errors_for_file[*]}")
  fi
done

echo ""
echo "--- Core Reference Specs (500+ words, 4+ sections) ---"

CORE_REFS=("verification-patterns" "agent-contracts" "context-budget" "anti-patterns" "model-profiles")

for ref in "${CORE_REFS[@]}"; do
  FILE="$REF_DIR/${ref}.md"
  if [ ! -f "$FILE" ]; then
    echo "  SKIP  $ref.md (not yet created)"
    SKIP=$((SKIP + 1))
    continue
  fi

  words=$(count_words "$FILE")
  sections=$(count_sections "$FILE")
  errors_for_file=()

  if [ "$words" -lt 500 ]; then
    errors_for_file+=("word count $words < 500")
  fi
  if [ "$sections" -lt 4 ]; then
    errors_for_file+=("section count $sections < 4")
  fi
  if ! check_agent_reference "$FILE"; then
    errors_for_file+=("no agent reference found")
  fi
  if placeholder_hits=$(check_placeholders "$FILE"); [ $? -ne 0 ]; then
    errors_for_file+=("placeholder markers found")
  fi

  if [ ${#errors_for_file[@]} -eq 0 ]; then
    echo "  PASS  $ref.md ($words words, $sections sections)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $ref.md: ${errors_for_file[*]}"
    FAIL=$((FAIL + 1))
    ERRORS+=("$ref.md: ${errors_for_file[*]}")
  fi
done

echo ""
echo "--- Supporting Reference Specs (300+ words, 4+ sections) ---"

SUPPORTING_REFS=("git-integration" "planning-quality" "checkpoint-types" "domain-probes" "repair-strategies")

for ref in "${SUPPORTING_REFS[@]}"; do
  FILE="$REF_DIR/${ref}.md"
  if [ ! -f "$FILE" ]; then
    echo "  SKIP  $ref.md (not yet created)"
    SKIP=$((SKIP + 1))
    continue
  fi

  words=$(count_words "$FILE")
  sections=$(count_sections "$FILE")
  errors_for_file=()

  if [ "$words" -lt 300 ]; then
    errors_for_file+=("word count $words < 300")
  fi
  if [ "$sections" -lt 4 ]; then
    errors_for_file+=("section count $sections < 4")
  fi
  if ! check_agent_reference "$FILE"; then
    errors_for_file+=("no agent reference found")
  fi
  if placeholder_hits=$(check_placeholders "$FILE"); [ $? -ne 0 ]; then
    errors_for_file+=("placeholder markers found")
  fi

  if [ ${#errors_for_file[@]} -eq 0 ]; then
    echo "  PASS  $ref.md ($words words, $sections sections)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $ref.md: ${errors_for_file[*]}"
    FAIL=$((FAIL + 1))
    ERRORS+=("$ref.md: ${errors_for_file[*]}")
  fi
done

echo ""
echo "=== Results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  SKIP: $SKIP (not yet created)"

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo ""
  echo "--- Failures ---"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
fi

if [ $FAIL -gt 0 ]; then
  echo ""
  echo "VERDICT: FAIL ($FAIL issues)"
  exit 1
else
  echo ""
  echo "VERDICT: PASS (all existing files pass, $SKIP pending)"
  exit 0
fi
