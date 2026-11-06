#!/usr/bin/env bash
# AgentCraft — lightweight setup/update script.
# Distributes AgentCraft assets into a target repository.
#
# Usage:
#   ./setup.sh [--update] [target-directory]   # default: current directory
#
#   --update  overwrite only files AgentCraft itself installed (tracked in
#             .pi/agentcraft-manifest); locally modified or foreign files are
#             skipped with a warning. AGENTS.md and openspec/config.yaml are
#             never overwritten.
#   Default   additive: adds missing files, never overwrites.
set -euo pipefail

usage() {
  echo "Usage: ./setup.sh [--update] [target-directory]" >&2
  echo "  --update  overwrite AgentCraft-installed files only (default: additive)" >&2
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

# Manifest: records, for each managed file, the sha256 of the installed content.
# --update overwrites a file only when its current hash matches what a previous
# AgentCraft install recorded, so a locally modified or foreign same-named file
# is never clobbered.
MANIFEST="$TARGET_ABS/.pi/agentcraft-manifest"
NEW_MANIFEST="$TARGET_ABS/.pi/agentcraft-manifest.tmp"
trap 'rm -f "$NEW_MANIFEST"' EXIT
: > "$NEW_MANIFEST"

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d' ' -f1
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$1" | awk '{print $NF}'
  else
    echo "Error: no sha256 tool available (sha256sum, shasum, or openssl required)" >&2
    exit 1
  fi
}

manifest_hash() {
  local key="$1"
  [ -f "$MANIFEST" ] || return 0
  awk -v k="$key" '$2 == k { print $1; exit }' "$MANIFEST"
}

manifest_add() {
  printf '%s %s\n' "$1" "$2" >> "$NEW_MANIFEST"
}

install_one() {
  local src="$1" dest="$2" key="$3"
  local src_hash dest_hash old_hash

  # Never write through a symlink inside a managed tree.
  if [ -L "$dest" ]; then
    echo "  skip (symlink): $key" >&2
    old_hash="$(manifest_hash "$key")"
    [ -n "$old_hash" ] && manifest_add "$old_hash" "$key"
    return 0
  fi

  src_hash="$(hash_file "$src")"

  if [ ! -e "$dest" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    manifest_add "$src_hash" "$key"
    return 0
  fi

  old_hash="$(manifest_hash "$key")"
  dest_hash="$(hash_file "$dest")"

  # Already identical to the source: claim it as AgentCraft-managed.
  if [ "$dest_hash" = "$src_hash" ]; then
    manifest_add "$src_hash" "$key"
    return 0
  fi

  # Differs from source.
  if [ "$UPDATE" -eq 1 ] && [ -n "$old_hash" ] && [ "$dest_hash" = "$old_hash" ]; then
    # Unmodified AgentCraft content → overwrite with the new version.
    cp "$src" "$dest"
    manifest_add "$src_hash" "$key"
  else
    # Additive install, or a locally modified / foreign file: leave it alone.
    [ -n "$old_hash" ] && manifest_add "$old_hash" "$key"
    if [ "$UPDATE" -eq 1 ]; then
      echo "  skip (locally modified or foreign): $key" >&2
    fi
  fi
}

install_tree() {
  local src_dir="$1" dest_dir="$2" prefix="$3"
  local f rel
  while IFS= read -r -d '' f; do
    rel="${f#"$src_dir"/}"
    install_one "$f" "$dest_dir/$rel" "$prefix/$rel"
  done < <(find "$src_dir" -type f -print0)
}

# 1. Agents (.pi/agents)
install_tree "$SRC/agents" "$TARGET_ABS/.pi/agents" ".pi/agents"

# 2. Skills (.pi/skills)
install_tree "$SRC/skills" "$TARGET_ABS/.pi/skills" ".pi/skills"

# 3. Documentation (docs/agentcraft/)
install_tree "$SRC/docs" "$TARGET_ABS/docs/agentcraft" "docs/agentcraft"

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

# 6. Version stamp and manifest — record what was installed.
write_version_stamp() {
  local commit="unknown"
  if command -v git >/dev/null 2>&1 && git -C "$SRC" rev-parse --verify HEAD >/dev/null 2>&1; then
    commit="$(git -C "$SRC" rev-parse HEAD)"
  fi
  {
    echo "agentcraft-commit: $commit"
    echo "installed-at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } > "$TARGET_ABS/.pi/agentcraft-version"
}
write_version_stamp
sort -k2 "$NEW_MANIFEST" > "$MANIFEST"
rm -f "$NEW_MANIFEST"

echo "Done. Review .pi/agents, .pi/skills, docs/agentcraft/, openspec/, AGENTS.md."
