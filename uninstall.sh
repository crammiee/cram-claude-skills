#!/bin/sh
# Removes the cram-* skill symlinks this repo installed from ~/.claude/skills/.
# Only removes symlinks that point back into this repo; leaves anything else alone.
set -eu

REPO_DIR="${CRAM_SKILLS_REPO_DIR:-$HOME/dev/skills/cram-claude-skills}"
if [ -f "$0" ] && [ -d "$(dirname "$0")/skills" ]; then
  REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

for skill_path in "$SKILLS_SRC"/*/; do
  skill_name=$(basename "$skill_path")
  dest="$SKILLS_DEST/$skill_name"

  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "${skill_path%/}")" ]; then
    rm "$dest"
    echo "Removed $dest"
  fi
done
