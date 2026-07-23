#!/bin/sh
# Installs the cram-* skills into ~/.claude/skills/ as symlinks, so edits
# made through Claude Code (which writes directly into ~/.claude/skills/)
# land back in this repo and can be committed/pushed.
#
# Works two ways:
#   1. Local checkout:  ./install.sh   (or `bash install.sh`)
#   2. Bootstrap:        script="$(curl -fsSL https://raw.githubusercontent.com/crammiee/cram-claude-skills/main/install.sh)" && sh -c "$script"
#      In this mode there's no local checkout to find, so it clones one.
#      (Use the `script=... && sh -c "$script"` form, not `sh -c "$(curl ...)"` —
#      the latter swallows curl's exit status and silently no-ops on failure.)
set -eu

REPO_URL="${CRAM_SKILLS_REPO_URL:-https://github.com/crammiee/cram-claude-skills.git}"
REPO_DIR="${CRAM_SKILLS_REPO_DIR:-$HOME/dev/skills/cram-claude-skills}"

# $0 is a real path to this file when run as `./install.sh` / `bash install.sh`,
# but not when piped into `sh -c "$(curl ...)"` (no file on disk) — in that
# case fall through to cloning REPO_URL instead.
if [ -f "$0" ] && [ -d "$(dirname "$0")/skills" ]; then
  REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
elif [ -d "$REPO_DIR/.git" ]; then
  git -C "$REPO_DIR" pull --ff-only
else
  echo "Cloning $REPO_URL to $REPO_DIR"
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$REPO_URL" "$REPO_DIR"
fi

SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

mkdir -p "$SKILLS_DEST"

for skill_path in "$SKILLS_SRC"/*/; do
  skill_name=$(basename "$skill_path")
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
