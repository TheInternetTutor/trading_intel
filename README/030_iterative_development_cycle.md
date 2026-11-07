# Iterative Development Cycle (`-idc-`)

## Purpose

The Iterative Development Cycle provides a controlled, repeatable method for investigating and changing a codebase. Each iteration produces a numbered output snapshot and compares it with the immediately preceding snapshot. The latest snapshot becomes the baseline for the next iteration; there is no permanently fixed original snapshot.

The cycle is designed to make cause and effect visible. A small controlled change, consistent execution conditions, and preserved outputs allow the Engineer to distinguish behavior caused by a modification from unrelated changes or noise. The IDC is independent of the Data Interchange Cycle: development and validation can proceed without transferring repository state after every iteration.

## Project configuration boundary

The IDC procedure is generic. It does not assume that a project generates a report, renders a view, uses a particular file format, or has a particular Make target.

Each project must define its **Data Generator** in a clearly identified project-specific configuration section. That section specifies:

- any initialization and test-environment requirements;
- the command or procedure that prepares the generator's input data;
- the Data Generator command and its required arguments or environment;
- the output format and destination;
- any deterministic normalization or sorting required before a snapshot is captured; and
- the repository archive target used for the post-commit recovery checkpoint.

The Data Generator is the project-configured mechanism that emits standardized, analysis-ready data from prepared project inputs. Its purpose is to provide a consistent representation for inspection, comparison, and AI-assisted analysis. It is not necessarily a report or a user-facing visualization.

Consult the project's configuration before running the IDC. Do not substitute a remembered command or infer a generator from a similarly named function.

## Initialization

1. Inspect the current repository state, relevant source, and project-specific IDC configuration.
2. Initialize the project's local test path and verify its active mode using the procedures documented by the project.
3. Do not toggle a test/production mode without first checking its current state. A toggle is not an idempotent setter.
4. Inspect the source and dependencies that will be exercised. The project's configuration identifies any project-specific inspection commands.

## Establish the first snapshot

1. Inspect the current source and input assumptions relevant to the behavior being investigated.
2. Run the configured data-preparation or test-processing procedure under the established test conditions. This prepares the input consumed by the Data Generator; it does not necessarily create the snapshot itself.
3. Invoke the configured Data Generator independently when the project defines it as a separate operation.
4. Apply the project's specified deterministic normalization, ordering, or filtering to the generated output before capture. Preserve the full intended analysis dataset; do not add transformations that are not part of the project configuration.
5. Save the resulting output as the first numbered snapshot, normally `010` with the project's established output suffix.
6. Confirm that generation and normalization succeeded, the output exists, and the captured content is valid. A missing-input message, empty output caused by a failed upstream step, or a masked command failure is not a valid snapshot.

## Iterative stages and why they exist

After the first snapshot, repeat the following stages for each controlled modification:

1. **Modify — introduce one intentional variable.** Make one purposeful, logically bounded change. Keeping changes small makes it possible to attribute observed behavior to a known modification rather than a bundle of unrelated edits.
2. **Inspect — establish what will be executed.** Review the relevant source sections, configuration, dependencies, and input assumptions. This catches accidental edits and helps ensure the next run actually exercises the intended implementation.
3. **Generate — execute the same processing path.** Run the configured data-preparation procedure under the established test conditions. Repeatable execution is necessary for a meaningful comparison; do not silently change inputs or environment between snapshots.
4. **Capture — preserve the observed result.** Invoke the configured Data Generator, apply the same project-defined normalization and ordering, and save the output as a new numbered snapshot. Preserve prior snapshots rather than overwriting them.
5. **Compare — identify what changed.** Compare the new snapshot with the immediately preceding snapshot, not with a permanently fixed original. Consecutive comparison isolates the effect of the latest iteration and keeps the reasoning chain incremental.
6. **Analyze — explain the differences.** Inspect actual changes and classify them as intended, unexpected, missing, reordered, formatting-only, or environmentally induced. Confirm that inputs, filters, execution conditions, generator options, and formatting were sufficiently consistent for the comparison to be meaningful. A difference is an observation, not yet a conclusion.
7. **Conclude — make an evidence-based decision.** Decide whether the modification achieved its stated objective. If successful, record the conclusion and proceed. If unsuccessful or inconclusive, preserve the evidence, improve diagnostics, investigate, and revise or roll back as appropriate. Never label unexplained behavior as a pass.
8. **Continue — carry forward the evidence chain.** Use the newest snapshot as the comparison baseline for the next modification, regardless of whether the previous change was accepted or needs further work. This prevents stale-baseline comparisons and makes each iteration's context explicit.

## Snapshot naming and comparison

Use the project's configured snapshot naming convention and comparison command. A snapshot filename identifies one execution, not a comparison between two executions. Compare consecutive snapshots only: the newest snapshot against the immediately preceding snapshot. Do not create pair-named comparison files unless a separate requirement calls for them; the numbered files identify individual executions.

## Post-commit recovery archive checkpoint

A successful Git commit is the trigger for an additional recovery checkpoint within the IDC:

1. Immediately after each successful commit, run the repository's configured repository archive target. Do not defer this checkpoint until the Data Interchange Cycle or until a later development iteration.
2. Verify that archive creation succeeded and inspect its integrity and expected repository contents.
3. Follow the project's configured archive overwrite behavior. Do not add versioning or external persistence unless the project configuration explicitly requires it.
4. Record the archive's exact name, location, size, and checksum when useful for verification.

The commit remains in Git even if archive creation fails, but the IDC post-commit checkpoint is incomplete until the archive is successfully generated and validated. Resolve the failure and rerun the archive step; do not create another commit merely to retry packaging.

The project-specific configuration defines the exact archive target, its output name, overwrite behavior, and contents. Inspect those details before relying on it. In particular, distinguish tracked working-tree content from committed-only content, and identify whether untracked or ignored snapshots and generated files are excluded.

This archive checkpoint belongs to the IDC because it protects the newly committed project state against loss of the temporary development environment. It is not an incremental Git bundle and does not replace the Data Interchange Cycle.

## Completion and limits

A successful comparison is evidence about the behavior exercised by those runs; it is not proof that the entire application is correct. Record what was tested, what was not tested, and any remaining uncertainty. Validation does not itself authorize a commit, push, bundle creation, publication, or replacement of a persistent artifact. Commit authorization and incremental bundle delivery remain governed by the repository's change-control rules and the Data Interchange Cycle. The post-commit archive checkpoint is required once a commit has been made.
