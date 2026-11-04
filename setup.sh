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

TARGET_ABS="$(cd "$TARGET" && pwd)"
if [ "$TARGET_ABS" = "$SRC" ]; then
  echo "Error: target directory is the AgentCraft source itself ($SRC). Run setup.sh in a different target repository." >&2
  exit 1
fi

echo "AgentCraft setup → $TARGET_ABS"

# 0. Prepare real directories (replace any symlinks so we never write through them).
#    Everything below is additive: it adds/overwrites AgentCraft's own assets and
#    never deletes content the target repository added on its own.
ensure_real_dir() {
  local d="$1"
  if [ -L "$d" ]; then
    rm -f "$d"
  fi
  mkdir -p "$d"
}
ensure_real_dir "$TARGET/.pi/agents"
ensure_real_dir "$TARGET/.pi/skills"

# 1. Agents (.pi/agents)
cp -R "$SRC/agents/." "$TARGET/.pi/agents/"

# 2. Skills (.pi/skills)
cp -R "$SRC/skills/." "$TARGET/.pi/skills/"

# 3. Documentation (docs/)
mkdir -p "$TARGET/docs"
for f in "$SRC"/docs/*.md; do
  [ -e "$f" ] || continue
  cp "$f" "$TARGET/docs/$(basename "$f")"
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
