---
name: cram-implement-plan-stage
description: Research, implement, and test a single stage of an existing staged plan doc end-to-end. Asks the user before assuming whenever multiple viable options exist; otherwise loops implement/build/test/fix autonomously until the stage's acceptance criteria are met. Delegates low-level search/grep to a cheap model, keeps all code writes on the primary model, and stops short of committing so the user can manually QA. Use when the user names a plan doc plus a stage/phase number and wants it actually executed — not designed from scratch (use cram-plan-feature for that). Pairs with cram-preflight-coverage-check (run before the research/implement loop, to size how much of the stage is actually left to do) and cram-close-plan-stage (to close out after).
---

## Implement Plan Stage

Take one already-written stage from a staged plan doc (the kind
`cram-plan-feature` produces: numbered stages, each with explicit acceptance
criteria) and carry it from research through a green test suite, without
committing. This skill is about *execution discipline*, not about writing
the plan.

### When to use this

The user points at a specific plan doc and a specific stage/phase ("do
stage 1 of `docs/plans/NN_foo-plan.md`", "implement phase 2"). Skip this
for open-ended feature work with no plan doc yet — write the plan first
(`cram-plan-feature`), then invoke this skill per stage.

### Inputs

- Path to the plan doc.
- Which stage/phase to execute (if the user just says "start the plan",
  execute the first not-yet-done stage).

### Steps

1. **Read the whole plan doc, not just the target stage.** Staged plans
   put shared context — architecture decisions, rejected alternatives,
   cross-stage dependencies, the permission/acceptance matrix — in
   sections above the stage list; a stage's bullet points assume that
   context. Confirm any prior stages this one depends on are actually
   done in the code (check git log / read the relevant files) — don't
   trust the doc's own checkmarks blindly, verify against real state.

2. **Run the `cram-preflight-coverage-check` skill for this stage before
   any deep research or writing.** Invoke it (via the `Skill` tool) and
   apply its classification:
   - **Already fully covered**: skip the research/implement loop
     (steps 4–6) below. Just confirm the stage's acceptance criteria
     actually pass as-is (run the real build/test commands), patch any
     single, explicitly-named remaining gap directly, and go straight to
     reporting (step 8) — call out plainly that the bulk of the stage was
     already done by earlier work, not this run, and name which earlier
     commit/phase did it.
   - **Partially covered**: continue to steps 3–6, but scope your own
     research and implementation to the specific named gap instead of the
     stage's full bullet list.
   - **Not covered**: continue normally, full scope, from step 3.

3. **Research the current code state before writing anything.** For
   low-level lookups — grepping for a symbol, finding which files
   reference something, locating existing tests, checking a pattern used
   elsewhere in the repo — delegate to a subagent running on a cheap/fast
   model (e.g. pass `model: "haiku"` on the `Agent` call, or use the
   `Explore` subagent type) rather than doing it inline yourself. Batch
   independent lookups in parallel. Reserve your own direct tool calls
   for things that need judgment (reading the plan doc itself, deciding
   what the research means).

   Structure each delegated prompt with XML tags rather than one prose
   paragraph — a cheap/fast model is more likely to blend "what you
   already know" into "the question" if it's all one paragraph:

   ```
   <context>
   {what you already know — file paths, relevant facts from the plan doc
   or prior research — so the subagent doesn't re-derive it}
   </context>

   <question>
   {the exact, narrow question(s) needing an answer}
   </question>

   <output_format>
   {e.g. "File paths only, one-line note each. No code snippets, no analysis."}
   </output_format>
   ```

4. **Never assume when there's more than one reasonable option.** If the
   plan doc is ambiguous about an implementation detail, if an acceptance
   criterion could be satisfied more than one defensible way, or if the
   research surfaces a fork the plan didn't anticipate, stop and ask the
   user directly (`AskUserQuestion` if it's a discrete choice) instead of
   picking one and continuing. This overrides the "keep going
   autonomously" default below — ambiguity is the one thing that pauses
   the loop.

5. **All actual code changes are written by you, the primary model —
   never delegate `Edit`/`Write` calls to a subagent.** Subagents in this
   workflow are for research and search only; implementation quality and
   judgment stay with the model the user is directly paying for/talking
   to. Follow the repo's existing conventions (check `CLAUDE.md` and
   neighboring files) for style, DTO/test patterns, etc.

6. **Loop implement → build → test → fix autonomously**, without
   returning to the user between iterations, until every acceptance
   criterion listed for the stage is met. Run the repo's real build/test
   commands yourself (don't ask the user to run them). If a test failure
   reveals a genuine design ambiguity rather than a plain bug, that's
   another trigger for step 4 — stop and ask rather than guessing your
   way past it.

7. **Stop before committing.** Once the stage's acceptance criteria are
   green, stop there. Do not `git add`/`commit`/`push` anything — leave
   the working tree as-is for the user to manually QA and commit
   themselves, unless they explicitly say otherwise for this run.

8. **Report what's verified vs. what still needs a human.** Summarize
   which acceptance criteria you confirmed automatically (build passed,
   unit suite green, specific assertions) versus which ones the plan
   marks as manual/live verification (curl matrices, UI walkthroughs)
   that only the user can actually do — don't claim those as done.

### Tips

- If the plan doc's stage has its own "Acceptance criteria (gate to next
  stage)" list, treat that list as the literal definition of done for
  this run — don't stop earlier and don't scope-creep into the next
  stage's work.
- Update tests/specs alongside the implementation in the same loop
  iteration, not as a separate afterthought pass.
- If the stage touches files also owned by another in-flight track (per
  the plan's parallelization notes, if any), re-check those files are
  still in the state the plan assumed before editing — a parallel stage
  may have already landed changes.
- Keep subagent research prompts self-contained and tagged per step 3's
  template — a cheap-model subagent has no memory of this conversation.
