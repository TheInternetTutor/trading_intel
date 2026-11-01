# Development Cycle (`-dc-`)

## Purpose

The Development Cycle provides a repeatable method for investigating and changing a codebase. Each iteration produces a numbered output snapshot and compares it with the immediately preceding snapshot. The latest snapshot becomes the baseline for the next iteration; there is no permanently fixed original snapshot.

## Initialization

Run `make itd` to initialize the repository's temporary refresh-trigger dependencies. This makes the trigger files current for the local run so refresh checks do not treat them as stale. It is not a general network-disable switch; avoid invoking unrelated acquisition or external-service workflows during local validation.

Check the environment with `make ite`:

- If it reports `true`, test mode is already active; continue.
- If it reports `false`, run `make td` once to toggle into test mode, then verify with `make ite` again.

`make td` is a toggle, not a one-way setter. Running it while test mode is already active switches back to production mode.

## Establish the first snapshot

1. Inspect the current repository state and the source relevant to the behavior being investigated.
2. Use `make gcf | make ds` to display tracked source sections enclosed by `<disec>` and `</disec>` markers. Repeat this inspection after source changes when useful.
3. Run `make tp` to execute the test pipeline. This target requires test mode. It invokes the no-update lot-processing path and suppresses the pipeline's normal standard output; it generates or refreshes the data consumed by the viewer, not the report snapshot itself.
4. Invoke the viewer independently after the pipeline has run. The viewer consumes its prepared JSONL input and checks whether that input file exists. If the file is missing, it reports the missing path and returns an error.
5. Capture the viewer's report output as the first snapshot, normally `010.diff`.

For this project, `sh/view_lots.sh` defines the viewer functions. It can be sourced by a Bash process; `generate_lots_report` writes the terminal report to standard output, which can be redirected to the snapshot file. The script accepts an optional first argument specifying the input JSONL path; otherwise it uses its configured default path. With the default input path, invoke it with `source sh/view_lots.sh >/dev/null && generate_lots_report > 010.diff`. To use another input file, pass its path when sourcing the script, for example `source sh/view_lots.sh /path/to/view_lots.jsonl >/dev/null`, then run the report function and redirect its output.

The viewer is deliberately separate from Make rules and batch functions. The data pipeline prepares the viewer's input; the viewer renders that input. Do not treat a missing-input message as a valid report snapshot. Confirm successful execution and inspect the resulting output before accepting the snapshot.

## Iterative development

After the first snapshot, repeat this sequence:

1. **Modify:** make one controlled, purposeful change to the repository.
2. **Inspect:** review the relevant source sections, including `make gcf | make ds` when appropriate.
3. **Generate:** run `make tp` to prepare the viewer data.
4. **Capture:** invoke the viewer and save its output as the next numbered snapshot.
5. **Compare, Analyze, and Conclude (`-cac-`):** compare the new snapshot with the immediately preceding snapshot, examine the actual differences, and decide whether the modification produced the intended result.
6. **Continue:** use the newest snapshot as the baseline for the next modification.

Use three-digit snapshot names in increments of ten: `010.diff`, `020.diff`, `030.diff`, `040.diff`, and so on. Compare consecutive snapshots only: `010` with `020`, then `020` with `030`, then `030` with `040`.

The project's comparison command is:

`diff -Bydaw --suppress-common-lines -W115 010.diff 020.diff`

Substitute the two most recent snapshot filenames for each subsequent comparison. Do not create pair-named comparison files unless a separate requirement calls for them; the numbered files identify individual executions.

## Analyze and conclude

Review the actual differences, not merely the comparison command's exit status. Distinguish expected behavior changes from unexpected changes, missing records, ordering changes, formatting noise, and environmental effects. Keep inputs, filters, environment, viewer options, and output formatting consistent between consecutive runs whenever practical.

If the result is inconclusive, improve the diagnostics or isolate the relevant stage, then capture another numbered snapshot. If a change makes the result worse, preserve the snapshots and restore or revise the source using the available version-control history. Do not proceed as though a change passed when its behavior remains unexplained.

A successful comparison is evidence about the behavior exercised by those runs; it is not proof that the entire application is correct or authorization to commit, package, publish, or replace a persistent artifact.
