#!/usr/bin/env bash
# Regression tests for setup.sh.
#
# Usage:
#   tests/run.sh
#
# Verifies:
#   - fresh install copies agents, skills, docs, openspec config, AGENTS.md template
#   - idempotency (second run is a no-op)
#   - non-destructive (existing AGENTS.md, openspec/config.yaml, user files are kept)
#   - self-install is rejected
#   - setup.sh never writes through symlinks (.pi, docs, openspec, AGENTS.md)
#   - owned leaf dirs (.pi/agents, .pi/skills, docs/agentcraft) self-heal symlinks
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
SETUP="$SRC/setup.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0

ok()  { PASS=$((PASS+1)); echo "ok   - $1"; }
bad() { FAIL=$((FAIL+1)); echo "FAIL - $1"; }

new_target() { mktemp -d "$WORK/${1:-target}.XXXXXX"; }

expect_success() {
  local desc="$1" target="$2"
  if "$SETUP" "$target" >"$WORK/log" 2>&1; then
    ok "$desc"
  else
    bad "$desc (setup.sh exited non-zero)"
    sed 's/^/       /' "$WORK/log" >&2
  fi
}

expect_failure() {
  local desc="$1" target="$2"
  if "$SETUP" "$target" >"$WORK/log" 2>&1; then
    bad "$desc (setup.sh unexpectedly succeeded)"
  else
    ok "$desc"
  fi
}

assert_exists() {
  if [ -e "$2" ]; then ok "$1"; else bad "$1 ($2 missing)"; fi
}

assert_eq_file() {
  if cmp -s "$2" "$3"; then ok "$1"; else bad "$1 ($3 != $2)"; fi
}

assert_real_dir() {
  if [ -d "$2" ] && [ ! -L "$2" ]; then ok "$1"; else bad "$1 ($2 is not a real directory)"; fi
}

# --- fresh install ---------------------------------------------------------
t="$(new_target fresh)"
expect_success "fresh install copies assets" "$t"
assert_exists   "  agent analyst.md present" "$t/.pi/agents/analyst.md"
assert_eq_file  "  agent analyst.md content" "$SRC/agents/analyst.md" "$t/.pi/agents/analyst.md"
assert_exists   "  skill code-review present" "$t/.pi/skills/code-review/SKILL.md"
assert_exists   "  docs workflow.md present" "$t/docs/agentcraft/workflow.md"
assert_exists   "  openspec config present" "$t/openspec/config.yaml"
assert_eq_file  "  AGENTS.md is the template" "$SRC/templates/AGENTS.md" "$t/AGENTS.md"

# --- idempotency -----------------------------------------------------------
expect_success "second run is a no-op" "$t"
assert_eq_file "  AGENTS.md unchanged after second run" "$SRC/templates/AGENTS.md" "$t/AGENTS.md"

# --- non-destructive --------------------------------------------------------
t="$(new_target keep)"
mkdir -p "$t/.pi/agents" "$t/openspec"
printf 'custom AGENTS\n' > "$t/AGENTS.md"
printf 'custom config\n' > "$t/openspec/config.yaml"
printf 'user agent\n'    > "$t/.pi/agents/custom.md"
printf 'custom AGENTS\n' > "$WORK/custom-agents"
printf 'custom config\n' > "$WORK/custom-config"
printf 'user agent\n'    > "$WORK/custom-agent"

expect_success "non-destructive install" "$t"
assert_eq_file  "  existing AGENTS.md preserved" "$WORK/custom-agents" "$t/AGENTS.md"
assert_eq_file  "  existing openspec/config.yaml preserved" "$WORK/custom-config" "$t/openspec/config.yaml"
assert_eq_file  "  user file in .pi/agents preserved" "$WORK/custom-agent" "$t/.pi/agents/custom.md"
assert_exists   "  AgentCraft assets still added" "$t/.pi/agents/analyst.md"

# --- self-install rejection --------------------------------------------------
expect_failure "self-install rejected" "$SRC"

# --- symlinked parents / ambiguous paths are refused ------------------------
t="$(new_target pi)"
outside="$(mktemp -d "$WORK/outside-pi.XXXXXX")"
ln -s "$outside" "$t/.pi"
expect_failure "refuses symlinked .pi" "$t"
if [ ! -e "$outside/agents" ]; then ok "  no write through .pi symlink"; else bad "  wrote through .pi symlink"; fi

t="$(new_target docs)"
outside="$(mktemp -d "$WORK/outside-docs.XXXXXX")"
ln -s "$outside" "$t/docs"
expect_failure "refuses symlinked docs" "$t"
if [ ! -e "$outside/agentcraft" ]; then ok "  no write through docs symlink"; else bad "  wrote through docs symlink"; fi

t="$(new_target openspec)"
outside="$(mktemp -d "$WORK/outside-openspec.XXXXXX")"
ln -s "$outside" "$t/openspec"
expect_failure "refuses symlinked openspec" "$t"
if [ ! -e "$outside/config.yaml" ]; then ok "  no write through openspec symlink"; else bad "  wrote through openspec symlink"; fi

t="$(new_target agentsmd)"
outside_file="$(mktemp "$WORK/agents-md.XXXXXX")"
printf 'do not touch\n' > "$outside_file"
ln -s "$outside_file" "$t/AGENTS.md"
expect_failure "refuses symlinked AGENTS.md" "$t"
if grep -q 'do not touch' "$outside_file" && [ -L "$t/AGENTS.md" ]; then
  ok "  AGENTS.md symlink and target left untouched"
else
  bad "  AGENTS.md symlink was modified or replaced"
fi

# --- owned leaf dirs self-heal ----------------------------------------------
t="$(new_target agents)"
mkdir -p "$t/.pi"
outside="$(mktemp -d "$WORK/outside-agents.XXXXXX")"
ln -s "$outside" "$t/.pi/agents"
expect_success "self-heals symlinked .pi/agents" "$t"
assert_real_dir "  .pi/agents is a real directory" "$t/.pi/agents"
assert_exists   "  analyst.md copied into real dir" "$t/.pi/agents/analyst.md"

t="$(new_target skills)"
mkdir -p "$t/.pi"
outside="$(mktemp -d "$WORK/outside-skills.XXXXXX")"
ln -s "$outside" "$t/.pi/skills"
expect_success "self-heals symlinked .pi/skills" "$t"
assert_real_dir "  .pi/skills is a real directory" "$t/.pi/skills"
assert_exists   "  code-review skill copied" "$t/.pi/skills/code-review/SKILL.md"

t="$(new_target agentcraft-docs)"
mkdir -p "$t/docs"
outside="$(mktemp -d "$WORK/outside-agentcraft-docs.XXXXXX")"
ln -s "$outside" "$t/docs/agentcraft"
expect_success "self-heals symlinked docs/agentcraft" "$t"
assert_real_dir "  docs/agentcraft is a real directory" "$t/docs/agentcraft"
assert_exists   "  workflow.md copied into real dir" "$t/docs/agentcraft/workflow.md"

# --- summary -----------------------------------------------------------------
echo
echo "passed: $PASS, failed: $FAIL"
[ "$FAIL" -eq 0 ]
