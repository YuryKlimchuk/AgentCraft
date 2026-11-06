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

# 0. Never write through symlinks.
#    - Refuse symlinked parents, files, and ambiguous paths (likely user-owned):
#      .pi, docs, openspec, AGENTS.md.
#    - Replace a stray symlink with a real directory only for leaf directories
#      that AgentCraft fully owns: .pi/agents, .pi/skills, docs/agentcraft.
#    Everything below is additive: it adds AgentCraft's assets, never overwrites
#    existing same-named files, and never deletes the target's own content.
refuse_symlink() {
  local p="$1"
  if [ -L "$p" ]; then
    echo "Error: refusing to write through symlink: $p" >&2
    echo "       Remove the symlink or run setup.sh against a real directory." >&2
    exit 1
  fi
}

ensure_real_dir() {
  local d="$1"
  if [ -L "$d" ]; then
    rm -f "$d"
  fi
  mkdir -p "$d"
}

refuse_symlink "$TARGET/.pi"
refuse_symlink "$TARGET/docs"
refuse_symlink "$TARGET/openspec"
refuse_symlink "$TARGET/AGENTS.md"

ensure_real_dir "$TARGET/.pi/agents"
ensure_real_dir "$TARGET/.pi/skills"
ensure_real_dir "$TARGET/docs/agentcraft"

# 1. Agents (.pi/agents)
cp -R -n "$SRC/agents/." "$TARGET/.pi/agents/"

# 2. Skills (.pi/skills)
cp -R -n "$SRC/skills/." "$TARGET/.pi/skills/"

# 3. Documentation (docs/agentcraft/)
for f in "$SRC"/docs/*.md; do
  [ -e "$f" ] || continue
  cp -n "$f" "$TARGET/docs/agentcraft/$(basename "$f")"
done

# 4. OpenSpec config (preserve existing)
if [ -f "$TARGET/openspec/config.yaml" ]; then
  echo "  skip openspec/config.yaml (already exists)"
else
  mkdir -p "$TARGET/openspec"
  cp "$SRC/openspec/config.yaml" "$TARGET/openspec/config.yaml"
fi

# 5. AGENTS.md — copy the generic template only when the target has none.
#    An existing AGENTS.md is left untouched (it may already define its own workflow).
AGENTS_TEMPLATE="$SRC/templates/AGENTS.md"

if [ -f "$TARGET/AGENTS.md" ]; then
  if cmp -s "$TARGET/AGENTS.md" "$SRC/AGENTS.md"; then
    # Migration: an older setup.sh copied AgentCraft's own AGENTS.md by mistake.
    cp "$AGENTS_TEMPLATE" "$TARGET/AGENTS.md"
    echo "  replaced miscopied AgentCraft AGENTS.md with the target template"
  else
    echo "  skip AGENTS.md (already exists)"
  fi
else
  cp "$AGENTS_TEMPLATE" "$TARGET/AGENTS.md"
  echo "  copied AGENTS.md template"
fi

echo "Done. Review .pi/agents, .pi/skills, docs/agentcraft/, openspec/, AGENTS.md."
