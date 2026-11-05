# Incremental Git Bundle Strategy

## Purpose

Incremental Git bundles provide a compact, repeatable way to exchange repository changes while keeping the Architect's persistent repository and the Engineer's temporary workspace synchronized. They also help preserve project continuity when an Engineer's execution environment is ephemeral.

## Small, cumulative transfers

A Git bundle can contain the commits and Git objects reachable from the current repository tip but not reachable from an agreed reference commit. Routine transfers therefore carry the changes since that shared reference rather than another complete copy of the repository.

When both repositories retain compatible history and the reference commit, each newly generated bundle can include the complete set of changes since that reference. The receiver can apply the latest bundle without needing to process every intermediate transfer bundle in sequence. Earlier bundle files are transfer artifacts, not dependencies that must all be retained or replayed.

This makes routine transfers comparatively small and keeps the exchange procedure simple. The bundle still contains Git history and objects needed for the commits in its range; it is not merely a patch file.

## Advancing the reference commit

The reference commit used by the bundle-creation function is a deliberate size-control point. As the cumulative range grows and the bundle becomes inconveniently large to upload or download, the reference can be advanced to a newer commit that is already present in both repositories.

After advancing the reference, the next bundle contains only commits newer than that reference. This starts a smaller transfer range while preserving the repositories' existing Git history. The older commits are not repeated in the new bundle because the receiving repository is expected to already have them.

Before changing the reference, verify that the selected commit exists in both repositories and is an ancestor of the current `HEAD` in each. The repositories must have synchronized through that commit; otherwise, a bundle based on it may not be usable by the receiver. Keep the reference commit explicit and inspectable in the bundle-creation function.

Advancing the reference is therefore a transfer-boundary adjustment, not a history rewrite or deletion of old commits. It should be done intentionally, when bundle size justifies it, rather than automatically after every transfer.

## Resilience to ephemeral workspaces

The Engineer's workbench may be temporary and can disappear when an execution environment is reset or reinitialized. Project continuity must therefore not depend on preserving that workbench.

The persistent repository and its Git history remain the durable record. A verified bundle can carry committed work from the temporary workspace back to the Architect's persistent repository. If the Engineer's workspace is later lost, it can be reconstructed from a complete repository transfer or another durable repository copy, then brought current using a compatible bundle.

This resilience depends on preserving the shared history and the required reference commit. A bundle whose range starts after a reference commit cannot independently reconstruct commits that precede that reference. Retain a durable repository copy or complete recovery archive; do not treat the latest incremental bundle as a substitute for the repository's entire history.

## Operational principles

- Prefer incremental bundles for routine exchange when both repositories share compatible Git history.
- Prefer a complete repository transfer when the Engineer's workspace is new, unavailable, wiped, or cannot be reconciled safely.
- Keep bundles additive in persistent storage; do not overwrite earlier transfer artifacts.
- Verify each bundle's integrity and record its size and hash before delivery.
- Advance the reference only to a commit already present in both repositories and confirmed as an ancestor of both current tips.
- Preserve at least one durable complete repository copy so ephemeral workspaces can be rebuilt independently of any single incremental bundle.
