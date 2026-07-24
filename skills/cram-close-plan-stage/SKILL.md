---
name: cram-close-plan-stage
description: Close out one or more finished stages of a staged plan doc — mark each stage done in the doc using the repo's existing convention, show the full staged diff for review, and commit with a conventional-commit message (or one message per stage) describing what actually changed. Use when the user says something like "close the stage", "mark stage N done and commit", "close out the diff and commit", or "close out stages 1 and 2" after the stage(s)' implementation is already done (e.g. via cram-implement-plan-stage, or the merged combined diff cram-fan-out-stages produces). Do not use to start or implement a stage — that's cram-implement-plan-stage's job — and do not use to just "commit what I have" with no plan doc involved.
---

## Close Plan Stage

Take one or more stages that are already implemented and verified (build
passing, tests green, acceptance criteria met) and close them out: mark each
done in the plan doc matching however this repo already marks stages done,
surface the exact diff that's about to be committed, and commit it with a
real, change-describing message — not a milestone label.

### When to use this

The user asks to close out / wrap up / mark-done-and-commit one or more
stages whose implementation is already sitting in the working tree. This is
usually a single stage just finished via `cram-implement-plan-stage`, but it
can also be several stages at once — e.g. after `cram-fan-out-stages`' default
path merges multiple stages onto the branch as one combined, uncommitted
diff. If any named stage's implementation isn't actually done yet (build
failing, tests red, acceptance criteria unmet), stop and say so instead of
closing it out anyway — don't mark something done that isn't.

### Inputs

- Which plan doc + stage(s) to close (usually obvious from recent
  conversation context — a single stage after `cram-implement-plan-stage`, or
  an explicit list after `cram-fan-out-stages`; ask if genuinely ambiguous).

### Steps

1. **Confirm every named stage is actually done.** Re-check (or trust very
   recent in-session verification of) build + test status against each
   stage's own acceptance-criteria list in the doc. If anything's unverified
   or failing for any stage, stop and report that instead of proceeding —
   don't close out the stages that did pass while silently dropping the one
   that didn't; surface it and ask how to proceed.

2. **Find the repo's existing "done" convention before inventing one.**
   Check whether any earlier stage in this doc (or a sibling doc in the
   same plans directory) is already marked done, and how — `git log`
   for a prior stage-closing commit is often the fastest way to find the
   exact marker used (e.g. a heading suffix like `✅ Done`, a `Status:`
   line, a checklist). Match that exactly. If no prior stage has ever
   been marked and there's truly no established convention, ask the
   user how they want it indicated rather than guessing a new one.

3. **Edit the plan doc** to mark every target stage done in one pass, using
   whatever convention step 2 found. Don't touch other stages' status,
   and don't add commentary beyond the marker itself.

4. **If closing more than one stage, decide commit granularity before
   staging anything:**
   - **Default — one combined commit** covering every closed stage, with a
     body line per stage. This is the right default when the stages arrived
     together as a single merged diff (the `cram-fan-out-stages` default
     path) — they were already treated as one unit through merge and test.
   - **Per-stage commits** — offer this instead when the user wants separable
     git history. Partition the working-tree diff using each stage's target
     files — pull them from the backtick-quoted paths inline in that
     stage's own Work/Acceptance bullets in the plan doc (not a separate
     labeled section), cross-checked against `git diff`'s file list. If a
     file's scope genuinely overlaps two stages and the diff can't be
     cleanly attributed, say so plainly and ask rather than guessing a
     split.
   - Single-stage closes skip this step entirely — there's only one
     commit to make.

5. **Stage exactly what belongs** — the plan-doc edit(s) plus the
   implementation/test files for the stage(s) in this commit. Use
   `git status`/`git diff` to confirm scope; stage files by name (never a
   blanket `git add -A`/`git add .`). If something unrelated is sitting
   modified in the tree, leave it out and say so.

6. **Show the full staged diff** (`git diff --cached`) before
   committing — this is the review step the user is asking for, not
   optional. Skim it for anything that shouldn't be there (stray debug
   code, unrelated formatting churn from a linter, files that don't
   belong to this commit) and pull those out before committing rather
   than after. Repeat steps 5–6 per commit if step 4 chose per-stage
   commits.

7. **Commit** with a conventional-commit message (`feat:`/`fix:`/
   `refactor:`/etc.) whose subject describes what actually changed in
   the code, not "finished stage N" — that tells a future reader
   nothing. For a combined commit, list each closed stage's change in the
   body. Use the body for specifics if the subject can't carry them.
   No AI co-author trailer. Do not push.

8. **Report the result**: commit hash(es), files included per commit, and
   confirm every named stage is now marked done in the doc.

### Tips

- This skill assumes each stage's actual implementation is already
  finished — it does not write code. If asked to close a stage that
  hasn't been implemented yet, say so and suggest running the
  implementation first.
- If the plan doc lives outside version control conventions this repo
  actually uses (e.g. the plans directory itself is gitignored), still
  update it, but flag that clearly in the report rather than assuming
  it's part of the commit.
- Keep the diff review and the commit as two distinct, visible steps for
  every commit made — don't silently commit without having shown its diff
  first.
- Default to the combined commit for multi-stage closes unless the user
  asks otherwise — splitting a diff that was always meant to land together
  is churn, not rigor.
