#!/usr/bin/env bash
# AgentCraft — lightweight setup/update script.
# Distributes AgentCraft assets into a target repository.
#
# Usage:
#   ./setup.sh [--update] [target-directory]   # default: current directory
#
#   --update  overwrite AgentCraft-managed files (.pi/agents, .pi/skills,
#             docs/agentcraft) and refresh the version stamp. AGENTS.md and
#             openspec/config.yaml are never overwritten.
#   Default   additive: adds missing files, never overwrites.
set -euo pipefail

usage() {
  echo "Usage: ./setup.sh [--update] [target-directory]" >&2
  echo "  --update  overwrite AgentCraft-managed files (default: additive)" >&2
}

UPDATE=0
TARGET="."
while [ $# -gt 0 ]; do
  case "$1" in
    --update|-u) UPDATE=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Error: unknown option: $1" >&2; usage; exit 1 ;;
    *) TARGET="$1" ;;
  esac
  shift
done

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
#    Below, copying is additive by default (adds missing files, never overwrites);
#    with --update it overwrites AgentCraft-managed files. Either way setup.sh
#    never deletes the target's own content.
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

# Copy helpers: --update overwrites, default is additive.
copy_tree() {
  if [ "$UPDATE" -eq 1 ]; then
    cp -R "$1" "$2"
  else
    cp -R -n "$1" "$2"
  fi
}
copy_file() {
  if [ "$UPDATE" -eq 1 ]; then
    cp "$1" "$2"
  else
    cp -n "$1" "$2"
  fi
}

# 1. Agents (.pi/agents)
copy_tree "$SRC/agents/." "$TARGET/.pi/agents/"

# 2. Skills (.pi/skills)
copy_tree "$SRC/skills/." "$TARGET/.pi/skills/"

# 3. Documentation (docs/agentcraft/)
for f in "$SRC"/docs/*.md; do
  [ -e "$f" ] || continue
  copy_file "$f" "$TARGET/docs/agentcraft/$(basename "$f")"
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

# 6. Version stamp — record what was installed (refreshed on --update).
write_version_stamp() {
  local commit="unknown"
  if command -v git >/dev/null 2>&1 && git -C "$SRC" rev-parse --verify HEAD >/dev/null 2>&1; then
    commit="$(git -C "$SRC" rev-parse HEAD)"
  fi
  {
    echo "agentcraft-commit: $commit"
    echo "installed-at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } > "$TARGET/.pi/agentcraft-version"
}
write_version_stamp

echo "Done. Review .pi/agents, .pi/skills, docs/agentcraft/, openspec/, AGENTS.md."
