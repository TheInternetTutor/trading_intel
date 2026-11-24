# Preserve Original Git Commit Identity and Shared History

## Purpose

Ensure that applying an incoming Git bundle preserves the original Git commit objects and shared commit history whenever the repositories have compatible ancestry. The transfer process must not silently replace incoming commits with newly reconstructed commits that merely copy selected metadata and file changes.

## Background

The current `apply_bundle()` implementation imports the incoming bundle commit and identifies its common ancestor with the receiving repository. It then reconstructs the incoming file changes in the receiving worktree and creates a new local commit. The implementation copies the incoming commit message and author name, author email, and author date, but the receiving repository creates a different commit object with its own committer identity and committer date. The reconstructed commit therefore has a different commit ID and does not preserve the incoming commit's original ancestry as the receiving branch's history.

This is materially different from integrating the incoming Git commit itself. Git bundles carry Git objects and commit history; the application workflow should preserve those objects and their relationships when safe to do so.

The existing shared-baseline and incremental bundle strategy is covered separately by the open work item `261101_1344_define_git_bundle_baseline_and_rollup.md`. Coordinate with that work so the baseline remains a known common commit and is not confused with the receiving branch's current tip.

## Scope

Review `apply_bundle()` in `sh/lib.sh`, the `make ab` target, the outgoing bundle creation workflow, and the related Translational Cycle documentation. Focus on preserving commit identity and ancestry during bundle application, without broadening the work into unrelated bundle naming or baseline changes.

## Required Work

- Trace the complete incoming-bundle flow, from bundle verification and object import through branch update and post-application verification.
- Confirm exactly which original commit objects are imported and which references are updated by the current implementation.
- Evaluate fast-forward integration when the receiving `HEAD` is an ancestor of the incoming commit. In that case, prefer advancing the receiving branch to the original incoming commit rather than rebuilding its changes as a new commit.
- Define safe behavior when the repositories have diverged. Preserve both sides' existing commits and changes; do not silently overwrite, reset, or reconstruct one side's history. Determine whether a merge commit is appropriate or whether the operation should stop and require an explicit integration decision.
- Account for local working-tree changes, staged changes, untracked files, deletions, renames, and conflicts. Retain the current safety guarantees or replace them with equally explicit and tested safeguards.
- Preserve the original commit IDs, parent relationships, author metadata, committer metadata, timestamps, and commit messages for incoming commits whenever those commits are integrated unchanged.
- Make any newly created merge commit explicit: its identity and purpose should be clear, and it must not be presented as the original incoming commit.
- Verify that repeated application is idempotent and that bundle/checksum bookkeeping does not falsely report success after a failed integration.
- Test both transfer directions using disposable repositories with shared history, including a fast-forward case and divergent-history cases. Include cases with multiple incoming commits and file additions, modifications, deletions, and renames.
- Update the relevant documentation to describe the actual history-preserving behavior and the conditions under which application stops for manual intervention.
- Coordinate shared-baseline assumptions and roll-up behavior with work item `261101_1344_define_git_bundle_baseline_and_rollup.md`.

## Completion Evidence

- A fast-forward test demonstrates that the receiving branch points to the exact original incoming commit ID after application.
- Verification confirms original author and committer identities, dates, messages, parent relationships, and reachable history are preserved for incoming commits.
- Divergent-history tests demonstrate that both repositories' commits and changes remain recoverable and that conflicts or unsafe states stop without destructive changes.
- Bidirectional transfer tests pass in disposable repositories.
- Reapplying an already integrated bundle does not create duplicate commits or alter history.
- The implementation, Make target behavior, and documentation agree on the integration policy.
- No Git history is rewritten, discarded, or silently replaced during routine bundle application.
