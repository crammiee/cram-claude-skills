#!/usr/bin/env bash
# Installs the cram-* skills into ~/.claude/skills/ as symlinks, so edits
# made through Claude Code (which writes directly into ~/.claude/skills/)
# land back in this repo and can be committed/pushed.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

mkdir -p "$SKILLS_DEST"

for skill_path in "$SKILLS_SRC"/*/; do
  skill_name="$(basename "$skill_path")"
  dest="$SKILLS_DEST/$skill_name"

  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    backup="$dest.bak.$(date +%s)"
    echo "Existing non-symlink skill found, backing up: $dest -> $backup"
    mv "$dest" "$backup"
  fi

  ln -s "${skill_path%/}" "$dest"
  echo "Linked $skill_name -> $dest"
done

echo "Done. Installed skills:"
ls "$SKILLS_SRC"
