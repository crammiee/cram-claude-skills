---
name: cram-fan-out-stages
description: Fan out multiple already-explicitly-chosen stages of a staged plan doc to parallel subagents, each running cram-implement-plan-stage in its own git worktree. By default, once every subagent finishes, merges each worktree's changes onto the tip of the branch you called it from as one combined, uncommitted diff for manual QA — no new commits ever persist. If the user opts out of merging, instead reports a per-stage table of worktree paths/branches to review manually. Use when the user names a plan doc and an explicit list of stage/phase numbers to implement concurrently — not for picking which stages are parallel-safe (that's the user's call first) and not for single-stage work (use cram-implement-plan-stage directly). Pairs with cram-implement-plan-stage (what each subagent runs), cram-preflight-coverage-check (run per-stage before dispatch), and cram-close-plan-stage (to close out afterward, whether merged or standalone).
---

## Fan Out Plan Stages

Take a staged plan doc and a user-specified set of stage/phase numbers the
user has already decided are safe to run at the same time. Dispatch one
subagent per stage — each in its own isolated git worktree, each running
`cram-implement-plan-stage` for its single assigned stage. Once every
subagent reports back, **by default merge all of their changes onto the tip
of the branch you were called from, as one combined, uncommitted diff** —
no new commits ever land on that branch. If the user opts out of merging
(asks to keep the worktrees separate instead), skip the merge and just
report worktree paths/branches for manual review.

### When to use this

The user names a plan doc and explicitly lists which stages/phases to run
in parallel ("do stages 1 and 2 of `docs/plans/NN_foo-plan.md` in parallel
worktrees"). This skill does not decide parallel-safety itself — it trusts
the user's explicit list. If the user instead asks "which stages can run in
parallel", answer that analytically first (file overlap, logical
dependency) and let them confirm before invoking this skill.

### Inputs

- Path to the plan doc.
- The explicit list of stage/phase identifiers to run concurrently (one
  subagent per stage).
- Optional: whether to skip the default merge and keep worktrees separate
  instead (see step 6).

### Steps

1. **Read the whole plan doc once, yourself** — shared architecture/context
   sections, cross-stage dependency notes, any existing parallelization
   guide. This is a sanity check, not a veto: if the doc's own notes or an
   obvious file overlap between the requested stages contradict what the
   user asked for, say so plainly and confirm before launching — don't
   silently launch agents that will collide, but don't overrule an explicit
   user instruction either. Note any overlap you find; you'll need it again
   in step 6 if a merge conflicts.

2. **Run `cram-preflight-coverage-check` for each requested stage, before
   dispatching anything.** A full subagent run has a large fixed cost
   regardless of how big the eventual diff is — only pay it where needed:
   - **Already fully covered**: skip the subagent. If there's a genuine
     small gap, make that edit yourself directly (Read + Edit + rerun the
     relevant tests). If there's nothing left, say so instead of
     dispatching a no-op agent.
   - **Partially covered**: still dispatch (step 4), but name the specific
     gap in its prompt so it doesn't re-discover what already exists.
   - **Not covered at all**: dispatch as normal, full scope.

3. **Verify the worktree base before dispatch**: confirm the local branch
   this session is on is up to date (`git status`, `git log -1`), and
   record its current commit — `git rev-parse HEAD`. You need this exact
   commit as the rollback point in step 6 if a merge happens.

4. **Launch one Agent per stage step 2 didn't resolve directly, all in a
   single message** (true parallel dispatch). For each:
   - `isolation: "worktree"`, `subagent_type: "general-purpose"`.
   - A **self-contained** prompt — the subagent has no memory of this
     conversation. Include: the plan doc path, the exact stage/phase number
     this agent owns (only this one), an instruction to invoke
     `cram-implement-plan-stage` for that stage, and an explicit reminder
     to leave its worktree's changes uncommitted — not to commit or push.
     If step 2 found the stage partially covered, name the gap here.
   - Leave `run_in_background` at its default — with several agents running
     concurrently you cannot block on one without stalling the others.

5. **Do not fabricate or predict any agent's outcome.** Wait for all
   requested stages to report back before moving to step 6.

6. **Combine or report, once every agent has finished** (plus any stage
   step 2 resolved directly):
   - **Default — merge onto the calling branch.** Working from the
     checkout you were called in, one worktree at a time (stage order,
     never all at once — a conflict must be attributable to a single
     stage's diff):
     - `cram-implement-plan-stage` leaves each worktree's changes
       uncommitted by design, and `git merge` needs commits on both sides
       — so commit the worktree's changes there first (a real
       conventional-commit message; this only needs to exist long enough
       to make the merge possible), then from the calling checkout run
       `git merge --no-ff <worktree-branch>`.
     - If a conflict surfaces (most likely the overlap flagged in step 1),
       resolve it with normal merge-conflict judgment and say plainly what
       you resolved and how — never silently pick a side.
     - Test after each merge, not after all of them, so a failure is
       traceable to one stage.
     - Once every requested worktree is merged in, run `git reset --mixed
       <the commit recorded in step 3>` on the calling checkout. This
       moves `HEAD` back to before any of the merges and unstages
       everything, but leaves the working-tree files untouched — so the
       merged-in changes remain as plain uncommitted modifications. Net
       effect: no new commits on the branch, but `git status`/`git diff`
       shows the full combined diff from every requested stage.
     - Do not run `git commit` or push on the calling branch after the
       reset, unless the user separately asks. State explicitly that the
       branch has no new commits and the combined diff is sitting
       uncommitted for manual QA.
     - Leave the source worktrees as they are (apart from their one
       throwaway commit each) — don't delete or clean them up, that's the
       user's call.
   - **Opt-out — user asked to keep worktrees separate.** Skip all of the
     above. Just report per stage: worktree path (or "resolved directly,
     see diff" for step 2 stages), branch name, which acceptance criteria
     the subagent verified vs. left for manual QA, and any blockers hit.
     Hand off: the user reviews each worktree's diff, runs
     `cram-close-plan-stage` (or a manual commit) per stage, then merges
     each branch themselves.
   - Either way, give the per-stage acceptance-criteria table (carry
     forward whatever each subagent reported — don't re-derive it).

### Tips

- If two requested stages touch the same file even non-conflictingly, still
  flag it in step 1 — it's a merge-time cost even when the agents never see
  each other's work.
- A worktree agent finishing with *no* changes gets auto-cleaned by the
  Agent tool; one that made changes (even uncommitted) keeps its path and
  branch.
- Keep each dispatched prompt narrow: one stage, one plan doc, nothing
  about the other stages running alongside it. Cross-stage awareness
  belongs in your step 1 analysis and, if relevant, a one-line caution in
  that specific agent's own prompt.
- Step 2's pre-flight check is cheapest for stages described as "add a unit
  spec for X," "prove Y," or "document Z" — language suggesting the stage
  verifies/extends earlier work. It's least useful for clearly net-new
  features with no prior implementation to check against — don't spend
  time on the check there, just dispatch.
