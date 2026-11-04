#!/usr/bin/env bash
# AgentCraft — lightweight setup/update script.
# Distributes AgentCraft assets into a target repository.
#
# Usage:
#   ./setup.sh [target-directory]   # default: current directory
set -euo pipefail

TARGET="${1:-.}"
SRC="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "$TARGET" ]; then
  echo "Error: target directory does not exist: $TARGET" >&2
  exit 1
fi

echo "AgentCraft setup → $(cd "$TARGET" && pwd)"

# 0. Cleanup: remove target assets that no longer exist in the source
cleanup_stale() {
  local target_dir="$1" src_dir="$2" name
  [ -d "$target_dir" ] || return 0
  for d in "$target_dir"/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    [ -d "$src_dir/$name" ] || { echo "  remove stale asset: $name"; rm -rf "$d"; }
  done
}

cleanup_stale "$TARGET/.pi/agents" "$SRC/agents"
cleanup_stale "$TARGET/.pi/skills" "$SRC/skills"

# 1. Agents (.pi/agents)
mkdir -p "$TARGET/.pi/agents"
cp -R "$SRC/agents/." "$TARGET/.pi/agents/"

# 2. Skills (.pi/skills)
mkdir -p "$TARGET/.pi/skills"
cp -R "$SRC/skills/." "$TARGET/.pi/skills/"

# 3. Documentation (docs/)
mkdir -p "$TARGET/docs"
for f in workflow.md quality-gates.md orchestrator.md openspec.md; do
  cp "$SRC/docs/$f" "$TARGET/docs/$f"
done

# 4. OpenSpec config (preserve existing)
if [ -f "$TARGET/openspec/config.yaml" ]; then
  echo "  skip openspec/config.yaml (already exists)"
else
  mkdir -p "$TARGET/openspec"
  cp "$SRC/openspec/config.yaml" "$TARGET/openspec/config.yaml"
fi

# 5. AGENTS.md — use the generic target template; patch an existing file, never overwrite
AGENTS_TEMPLATE="$SRC/templates/AGENTS.md"
AGENTS_MARKER="<!-- AgentCraft workflow (installed by setup.sh) -->"

if [ -f "$TARGET/AGENTS.md" ]; then
  if grep -qF "$AGENTS_MARKER" "$TARGET/AGENTS.md"; then
    echo "  skip AGENTS.md (AgentCraft workflow already present)"
  elif cmp -s "$TARGET/AGENTS.md" "$SRC/AGENTS.md"; then
    # Migration: an older setup.sh copied AgentCraft's own AGENTS.md by mistake.
    cp "$AGENTS_TEMPLATE" "$TARGET/AGENTS.md"
    echo "  replaced miscopied AgentCraft AGENTS.md with the target template"
  else
    {
      printf '\n%s\n' "$AGENTS_MARKER"
      printf '%s\n' 'This repository follows the **AgentCraft** development workflow (8 stages, quality gates).'
      printf '%s\n' 'See `docs/workflow.md`, `docs/orchestrator.md`, and `docs/quality-gates.md`.'
    } >> "$TARGET/AGENTS.md"
    echo "  appended AgentCraft workflow to existing AGENTS.md"
  fi
else
  cp "$AGENTS_TEMPLATE" "$TARGET/AGENTS.md"
  echo "  copied AGENTS.md template"
fi

echo "Done. Review .pi/agents, .pi/skills, docs/, openspec/, AGENTS.md."
