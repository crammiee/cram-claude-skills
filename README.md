# cram-claude-skills

Personal Claude Code skills for working through staged implementation plans:
writing them, implementing a stage, fanning stages out to parallel subagents,
and closing them out. Packaged here so they can be installed on any machine
running Claude Code.

## Install

```bash
git clone git@github.com:crammiee/cram-claude-skills.git ~/dev/skills/cram-claude-skills
~/dev/skills/cram-claude-skills/install.sh
```

Or bootstrap directly without cloning first — the script clones itself to
`~/dev/skills/cram-claude-skills` (override with `CRAM_SKILLS_REPO_DIR`) if it
doesn't find a local checkout next to it:

```bash
script="$(curl -fsSL https://raw.githubusercontent.com/crammiee/cram-claude-skills/main/install.sh)" && sh -c "$script"
```

Note this is *not* the same as `sh -c "$(curl -fsSL url)"` — that form throws
away curl's exit status inside the command substitution, so a failed download
(network blip, repo made private again, wrong URL) silently runs `sh -c ""`
and reports success having done nothing. `script=$(curl ...) && sh -c "$script"`
actually fails loudly when the download fails.

`.github/workflows/test-install-arch.yml` runs both forms on a fresh Arch
Linux container on every push, so a broken install is caught in CI.

`install.sh` symlinks each skill in `skills/` into `~/.claude/skills/`. Because
it's a symlink (not a copy), any edit Claude Code makes to a skill — it writes
directly into `~/.claude/skills/<name>/SKILL.md` — lands back in this repo, so
`git status` / `git diff` / `git commit` here picks it up.

If a skill of the same name already exists in `~/.claude/skills/` and isn't a
symlink, `install.sh` backs it up (`<name>.bak.<timestamp>`) before linking.

To remove the symlinks this repo installed:

```bash
~/dev/skills/cram-claude-skills/uninstall.sh
```

## Skills

| Skill | Purpose |
| --- | --- |
| [cram-plan-feature](skills/cram-plan-feature/SKILL.md) | Write a full masterplan + roadmap + per-phase docs, staged and acceptance-gated, before any code is written. |
| [cram-implement-plan-stage](skills/cram-implement-plan-stage/SKILL.md) | Research, implement, and test a single stage of an existing staged plan doc end-to-end. |
| [cram-fan-out-stages](skills/cram-fan-out-stages/SKILL.md) | Fan out multiple explicitly-chosen stages to parallel subagents, each in its own git worktree. |
| [cram-preflight-coverage-check](skills/cram-preflight-coverage-check/SKILL.md) | Cheap check for how much of a stage's required behavior/tests already exist, used internally by the two skills above. |
| [cram-close-plan-stage](skills/cram-close-plan-stage/SKILL.md) | Mark one or more finished stages done in the plan doc, show the diff, and commit with a conventional-commit message (combined or per-stage). |

### Typical flow

1. `cram-plan-feature` — write the masterplan/roadmap/phase docs for a new feature.
2. `cram-implement-plan-stage` (or `cram-fan-out-stages` for several stages at once) — implement a stage.
3. `cram-close-plan-stage` — close it out and commit.

## Updating

Skills are edited in place by Claude Code, which writes straight into
`~/.claude/skills/<name>/SKILL.md`. Since that's a symlink into this repo,
just `cd` here and commit:

```bash
cd ~/dev/skills/cram-claude-skills
git add -A
git commit -m "docs: update cram skill wording"
git push
```

## Adding a new skill to this repo

```bash
mkdir -p skills/<new-skill-name>
cp ~/.claude/skills/<new-skill-name>/SKILL.md skills/<new-skill-name>/SKILL.md
./install.sh   # re-links everything, including the new one
```
