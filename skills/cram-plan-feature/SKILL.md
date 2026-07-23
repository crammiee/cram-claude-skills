---
name: cram-plan-feature
description: Write a full masterplan + roadmap + per-phase docs (staged, acceptance-gated, and labeled for parallel work across multiple Claude instances) for a new feature before any code is written. Use for substantial new work with independent failure surfaces or that benefits from splitting across parallel instances — not for a small bugfix or one-file change. Pairs with cram-implement-plan-stage (to execute each stage once written).
---

## Plan Feature

Produce a complete, upfront documentation set for a new feature: a
masterplan, a roadmap, and one detail doc per phase — each phase broken
into stages with explicit acceptance criteria, and parallel-safe stages
labeled so the user can hand different stages to different Claude
instances and have one reviewer merge the results. Write the full set
now, not "as each phase starts" — a half-finished doc plan defeats the
point.

### When to use this

Substantial new capability with more than one genuinely independent
failure surface (e.g. "a new algorithm" + "a new I/O/export layer" + "a
new integration point" are each things that can break separately and be
tested separately) — or work large/independent enough that the user
wants to parallelize it across multiple Claude instances. Skip this for
a small bugfix, a one-file change, or anything with one obvious
implementation path — the ceremony isn't worth it there.

### Steps

1. **Understand the repo's existing conventions before writing anything.**
   Look for an existing plan-docs directory (commonly `docs/plans/`,
   sometimes elsewhere) and read at least one full masterplan + roadmap +
   phase-doc set if one exists, to match section names, tone, and level
   of detail. If the repo already has an established indexing scheme
   (e.g. a flat, globally-numbered sequence of files), default to
   continuing it for a new masterplan/roadmap pair *unless* the user
   asks for a self-contained per-feature folder instead (e.g. because
   they want the same convention portable to other repos, or the new
   work doesn't fit the existing versioning scheme). If there's no
   existing convention at all, default to a self-contained
   `docs/plans/<feature-slug>/` folder — it's the more portable choice
   and doesn't depend on a repo-specific running counter.

2. **Confirm scope before writing.** Don't draft a masterplan from a
   one-line request. Make sure you actually understand: the concrete
   problem/motivating use case, the goal, explicit non-goals, and why
   this needs its own scoped plan rather than being folded into existing
   work. If genuinely unclear, ask — don't guess and write 2000 words
   around a wrong assumption.

3. **Write the masterplan** (`00_masterplan.md`, or continuing the
   repo's existing numbering): problem statement grounded in a real
   scenario (not abstract), why it deserves independent scoping, goals,
   explicit non-goals, an architecture sketch (ASCII diagram of new
   modules/files and how they connect to existing code), a key-decisions
   table (decision → one-line rationale each), any environment/
   constraint notes, and a pointer to the roadmap doc.

4. **Write the roadmap** (`01_roadmap.md`): a phase table (phase name,
   one-line goal, detail-doc filename), a gate-criteria table (what must
   be true to move from phase N to phase N+1 — concrete and checkable,
   not "looks good"), and a **parallelization guide**: identify which
   phase (usually the first) defines the shared contract(s) — a type,
   schema, or file format — that later phases build against. Once that
   contract is frozen, name explicitly which phases/stages share no code
   dependency and can run concurrently in separate Claude instances
   (built and tested against a fixture matching the frozen contract,
   not against another track's in-progress code), and which final
   stage must be serial — integration, real end-to-end validation, and
   a go/no-go, done by one reviewing instance after every track merges.

5. **Write one detail doc per phase**, broken into stages. Every stage
   gets explicit, checkable acceptance criteria before the next stage
   can start. Any stage identified in the roadmap's parallelization
   guide as parallel-safe gets labeled inline, e.g. `[PARALLEL-SAFE with
   Phase 3 Stage 3.1]`, naming the exact shared contract it depends on —
   so a second instance picking up that stage doesn't need to read the
   other track's doc to know it's safe to start. Mark every doc's status
   line (`Status: NOT STARTED`) since this is planning, not a
   retrospective — update it in place as real work happens rather than
   leaving it stale.

6. **Add a pointer, not a narrative, to the repo's main doc index** (e.g.
   `CLAUDE.md`/`README.md`) if one exists and references other plan
   docs — one or two sentences pointing at the new plan set and its
   current status. Save the detailed narrative for after phases actually
   complete, matching how completed work is usually documented in that
   file already.

### Tips

- Prefer a concrete architecture sketch over prose — a small ASCII
  diagram showing new files/modules and their data flow answers more
  reviewer questions per word than a paragraph does.
- The gate criteria and stage acceptance criteria are the actual value
  of this process — they're what lets a second Claude instance (or a
  human reviewer) know a stage is really done without re-reading all its
  code. Don't let them collapse into "tests pass" if the phase also has
  a real-world/manual-review component (e.g. anything touching real
  media, real API output, or a UI) — say so explicitly.
- If a phase or stage reuses/depends on work already sketched elsewhere
  in the repo (a prior candidate doc, an open TODO, a known limitation
  write-up), cite it directly rather than re-deriving the same
  reasoning — it's both faster and keeps the rationale traceable to
  where it was first found.
- Don't inflate a one-phase feature into an artificial multi-phase plan
  just to use this structure — if there's really only one failure
  surface and no parallelization opportunity, a single well-written
  masterplan (skip the roadmap/phase-doc split) is the right amount of
  ceremony.
