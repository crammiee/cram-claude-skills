#!/usr/bin/env bash
# Removes the cram-* skill symlinks this repo installed from ~/.claude/skills/.
# Only removes symlinks that point back into this repo; leaves anything else alone.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

for skill_path in "$SKILLS_SRC"/*/; do
  skill_name="$(basename "$skill_path")"
  dest="$SKILLS_DEST/$skill_name"

  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "${skill_path%/}")" ]; then
    rm "$dest"
    echo "Removed $dest"
  fi
done
