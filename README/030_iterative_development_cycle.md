# Iterative Development Cycle (`-idc-`)

## Purpose

The Iterative Development Cycle provides a controlled, repeatable method for investigating and changing a codebase. Each iteration produces a numbered output snapshot and compares it with the immediately preceding snapshot. The latest snapshot becomes the baseline for the next iteration; there is no permanently fixed original snapshot.

The cycle is designed to make cause and effect visible. A small controlled change, consistent execution conditions, and preserved outputs allow the Engineer to distinguish the behavior caused by a modification from unrelated changes or noise. The cycle is independent of the Data Interchange Cycle: development and validation can proceed without transferring repository state after every iteration.

## Initialization

Run `make itd` to initialize the repository's temporary refresh-trigger dependencies. This makes the trigger files current for the local run so refresh checks do not treat them as stale. It is not a general network-disable switch; avoid invoking unrelated acquisition or external-service workflows during local validation.

Check the environment with `make ite`:

- If it reports `true`, test mode is already active; continue.
- If it reports `false`, run `make td` once to toggle into test mode, then verify with `make ite` again.

`make td` is a toggle, not a one-way setter. Running it while test mode is already active switches back to production mode.

## Establish the first snapshot

1. Inspect the current repository state and the source relevant to the behavior being investigated.
2. Use `make gcf | make ds` to display tracked source sections enclosed by `<disec>` and `</disec>` markers. Repeat this inspection after source changes when useful.
3. Run `make tp` to execute the test pipeline. This target requires test mode. It invokes the no-update lot-processing path and suppresses the pipeline's normal standard output; it generates or refreshes the data consumed by the viewer, not the viewer snapshot itself.
4. Invoke the viewer independently after the pipeline has run. The viewer consumes its prepared JSONL input and checks whether that input file exists. If the file is missing, it reports the missing path and returns an error.
5. Sort the rendered records with `LC_ALL=C sort` and capture the sorted output as the first snapshot, normally `010.diff`.

For this project, `sh/view_lots.sh` defines the viewer functions. It can be sourced by a Bash process; `render_lots_view` writes the rendered lots view to standard output, which can be redirected to the snapshot file. The script accepts an optional first argument specifying the input JSONL path; otherwise it uses its configured default path. With the default input path, invoke it with `set -o pipefail && source sh/view_lots.sh >/dev/null && render_lots_view | LC_ALL=C sort > 010.diff`. To use another input file, pass its path when sourcing the script, for example `source sh/view_lots.sh /path/to/view_lots.jsonl >/dev/null`, then call `render_lots_view`, pipe its output through `LC_ALL=C sort`, and redirect the sorted output. Always sort the rendered records before saving a snapshot. The fixed `C` locale makes ordering consistent across environments, so comparisons focus on record changes rather than incidental output order.

The viewer is deliberately separate from Make rules and batch functions. The data pipeline prepares the viewer's input; the viewer renders that input. Do not treat a missing-input message as a valid snapshot. Confirm successful execution and inspect the resulting output before accepting the snapshot.

## Iterative stages and why they exist

After the first snapshot, repeat the following stages for each controlled modification:

1. **Modify — introduce one intentional variable.** Make one purposeful, logically bounded change. Keeping changes small makes it possible to attribute observed behavior to a known modification rather than a bundle of unrelated edits.
2. **Inspect — establish what will be executed.** Review the relevant source sections, configuration, dependencies, and input assumptions. Use `make gcf | make ds` when appropriate. This catches accidental edits and helps ensure the next run actually exercises the intended implementation.
3. **Generate — execute the same processing path.** Run `make tp` to prepare the viewer data under the established test conditions. Repeatable execution is necessary for a meaningful comparison; do not silently change inputs or environment between snapshots.
4. **Capture — preserve the observed result.** Invoke the viewer, pipe its output through `LC_ALL=C sort`, and save the sorted output as a new numbered snapshot. Sorting is mandatory: it gives records a stable order across runs and prevents incidental ordering changes from obscuring substantive differences. The snapshot is evidence of one execution. Preserve prior snapshots rather than overwriting them.
5. **Compare — identify what changed.** Compare the new snapshot with the immediately preceding snapshot, not with a permanently fixed original. Consecutive comparison isolates the effect of the latest iteration and keeps the reasoning chain incremental.
6. **Analyze — explain the differences.** Inspect actual changes and classify them as intended, unexpected, missing, reordered, formatting-only, or environmentally induced. Confirm that inputs, filters, execution conditions, viewer options, and formatting were sufficiently consistent for the comparison to be meaningful. A difference is an observation, not yet a conclusion.
7. **Conclude — make an evidence-based decision.** Decide whether the modification achieved its stated objective. If successful, record the conclusion and proceed. If unsuccessful or inconclusive, preserve the evidence, improve diagnostics, investigate, and revise or roll back as appropriate. Never label unexplained behavior as a pass.
8. **Continue — carry forward the evidence chain.** Use the newest snapshot as the comparison baseline for the next modification, regardless of whether the previous change was accepted or needs further work. This prevents stale-baseline comparisons and makes each iteration's context explicit.

## Snapshot naming and comparison

Use three-digit snapshot names in increments of ten: `010.diff`, `020.diff`, `030.diff`, `040.diff`, and so on. Compare consecutive snapshots only: `010` with `020`, then `020` with `030`, then `030` with `040`.

The project's comparison command is:

`diff -Bydaw --suppress-common-lines -W115 010.diff 020.diff`

Substitute the two most recent snapshot filenames for each subsequent comparison. Do not create pair-named comparison files unless a separate requirement calls for them; the numbered files identify individual executions.

## Completion and limits

A successful comparison is evidence about the behavior exercised by those runs; it is not proof that the entire application is correct. Record what was tested, what was not tested, and any remaining uncertainty. Validation does not itself authorize a commit, bundle creation, publication, or replacement of a persistent artifact; those are separate actions governed by authorization and the Data Interchange Cycle.
