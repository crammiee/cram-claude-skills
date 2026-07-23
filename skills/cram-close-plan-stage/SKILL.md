---
name: cram-close-plan-stage
description: Close out a finished stage of a staged plan doc — mark the stage done in the doc using the repo's existing convention, show the full staged diff for review, and commit with a conventional-commit message describing what actually changed. Use when the user says something like "close the stage", "mark stage N done and commit", or "close out the diff and commit" after a stage's implementation is already done (e.g. via cram-implement-plan-stage). Do not use to start or implement a stage — that's cram-implement-plan-stage's job — and do not use to just "commit what I have" with no plan doc involved.
---

## Close Plan Stage

Take a stage that's already been implemented and verified (build passing,
tests green, acceptance criteria met — typically just finished via
`implement-plan-stage`) and close it out: mark it done in the plan doc
matching however this repo already marks stages done, surface the exact
diff that's about to be committed, and commit it with a real,
change-describing message — not a milestone label.

### When to use this

The user asks to close out / wrap up / mark-done-and-commit a stage
whose implementation is already sitting in the working tree. If the
stage's implementation isn't actually done yet (build failing, tests
red, acceptance criteria unmet), stop and say so instead of closing it
out anyway — don't mark something done that isn't.

### Inputs

- Which plan doc + stage to close (usually obvious from recent
  conversation context; ask if genuinely ambiguous).

### Steps

1. **Confirm the stage is actually done.** Re-check (or trust very
   recent in-session verification of) build + test status against the
   stage's own acceptance-criteria list in the doc. If anything's
   unverified or failing, stop and report that instead of proceeding.

2. **Find the repo's existing "done" convention before inventing one.**
   Check whether any earlier stage in this doc (or a sibling doc in the
   same plans directory) is already marked done, and how — `git log`
   for a prior stage-closing commit is often the fastest way to find the
   exact marker used (e.g. a heading suffix like `✅ Done`, a `Status:`
   line, a checklist). Match that exactly. If no prior stage has ever
   been marked and there's truly no established convention, ask the
   user how they want it indicated rather than guessing a new one.

3. **Edit the plan doc** to mark just the target stage done, using
   whatever convention step 2 found. Don't touch other stages' status,
   and don't add commentary beyond the marker itself.

4. **Stage exactly what belongs to this stage** — the plan-doc edit plus
   the implementation/test files that make up the stage's actual work.
   Use `git status`/`git diff` to confirm scope; stage files by name
   (never a blanket `git add -A`/`git add .`). If something unrelated
   is sitting modified in the tree, leave it out and say so.

5. **Show the full staged diff** (`git diff --cached`) before
   committing — this is the review step the user is asking for, not
   optional. Skim it for anything that shouldn't be there (stray debug
   code, unrelated formatting churn from a linter, files that don't
   belong to this stage) and pull those out before committing rather
   than after.

6. **Commit** with a conventional-commit message (`feat:`/`fix:`/
   `refactor:`/etc.) whose subject describes what actually changed in
   the code, not "finished stage N" — that tells a future reader
   nothing. Use the body for specifics if the subject can't carry them.
   No AI co-author trailer. Do not push.

7. **Report the result**: commit hash, files included, and confirm the
   stage is now marked done in the doc.

### Tips

- This skill assumes the stage's actual implementation is already
  finished — it does not write code. If asked to close a stage that
  hasn't been implemented yet, say so and suggest running the
  implementation first.
- If the plan doc lives outside version control conventions this repo
  actually uses (e.g. the plans directory itself is gitignored), still
  update it, but flag that clearly in the report rather than assuming
  it's part of the commit.
- Keep the diff review and the commit as two distinct, visible steps —
  don't silently commit without having shown the diff first.
