---
name: cram-preflight-coverage-check
description: Cheap check for how much of a plan stage's required behavior/tests already exist in the codebase, run before paying full research-and-implementation cost on that stage. Not a standalone entry point — it's invoked from within another skill's own step (currently cram-fan-out-stages, deciding whether a stage needs a dispatched subagent, and cram-implement-plan-stage, deciding how much of a stage's own work actually remains). Do not invoke directly on a bare user request; the calling skill decides what to do with the classification this returns.
---

## Pre-flight Coverage Check

Before spending a full research-and-implement cycle on a plan stage, spend a
handful of cheap tool calls checking how much of it is already done. Staged
plans — especially later phases in a series ("prove X," "add a unit spec for
Y," "document Z") — often describe behavior or coverage that an earlier
phase already built. Confirming that upfront is far cheaper than discovering
it mid-implementation, and a full research-and-implement pass has a large
fixed cost (reading the whole plan doc, exploring surrounding code, running
the test suite, iterating) regardless of how small the eventual diff turns
out to be.

### When this applies

Called from within another skill's own step, not invoked directly by a user
request. Most useful for stages phrased as verifying, extending, or
documenting already-shipped behavior — check the plan doc's own Overview for
language like that. Least useful for stages that are unambiguously net-new
features with no prior implementation to check against; skip the check there
and let the calling skill proceed straight to its normal full-scope path.

### Procedure

1. **Identify the stage's target files and concrete bullets** — pull file
   paths from the backtick-quoted tokens inline in its own Work/Acceptance
   bullets (e.g. `` `package.json` ``, `` `src/Root.tsx` ``), plus the
   specific cases/behaviors those bullets describe (not just the stage
   title). Plan docs name files this way in prose, not under a dedicated
   labeled section — grep the bullets for backtick-quoted paths rather than
   hunting for a separate "scope" heading.

2. **Check existing coverage for those files:**
   - Prefer this project's `code-review-graph` MCP tools where available —
     `query_graph` with `pattern="tests_for"` on the relevant function/class,
     or `semantic_search_nodes` — per the repo's own CLAUDE.md, this is the
     token-efficient way to see what already tests a symbol without reading
     the file whole.
   - Otherwise, fall back to `grep -n "it(\|describe("` (or the repo's
     equivalent test syntax) on the target spec/test files, plus
     `git log --oneline -- <file>` to see which earlier commit/phase last
     touched it.

3. **Compare what exists against the stage's bullets, one by one**, and
   classify the stage as exactly one of:
   - **Already fully covered** — every bullet is already satisfied by
     existing code/tests.
   - **Partially covered** — most bullets are satisfied; a specific,
     nameable gap remains (a missing case, a missing comment, one
     uncovered file).
   - **Not covered** — little or nothing of the stage exists yet.

4. **Return that classification to the calling skill's own step** — name
   the specific gap if "partially covered." This check does not itself
   decide to skip work, narrow a prompt, or dispatch anything; the calling
   skill's step applies that decision using this classification.

### Tips

- This is a sizing decision, not a substitute for verification — even a
  "fully covered" classification should still have its stage's acceptance
  criteria (build/tests) actually re-run before anything is reported done.
- Cheap means cheap: a handful of targeted tool calls, not a second full
  research pass. If the check itself starts turning into a deep dive, stop
  and just treat the stage as "not covered" — proceeding costs less than an
  inconclusive investigation.
- A "fully covered" classification is still worth reporting explicitly
  (which earlier commit/phase actually did the work) rather than silently
  — it's useful provenance for whoever reviews the result later.
