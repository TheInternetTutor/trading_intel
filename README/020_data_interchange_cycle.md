# Translational Cycle — Data Interchange Cycle (DIC)

## Purpose

The Translational Cycle transfers and synchronizes repository state between the Architect and Engineer. It governs workspace availability, Git identity, and controlled exchange of changes. It does not prescribe how implementation work is developed or validated. When an exchange carries completed development work, confirm that it has reached its authorized handoff point through the Rotational Cycle; this document governs only the transfer.

Git history is the authoritative development record. A complete archive is a bootstrap or recovery mechanism; incremental Git bundles are the routine exchange mechanism when both repositories share compatible history.

## Establish the Engineer's repository

1. Obtain the complete repository or the agreed incoming bundle.
2. Work from the repository root, where the project `makefile` and `.git/` directory reside.
3. Verify the repository root and current state with `git rev-parse --show-toplevel`, `git status --short`, and `git log -1`.
4. In a newly created execution environment, run `make itd` before other Make targets that rely on refresh triggers. This initializes temporary trigger dependencies declared by the included Make modules.
5. Verify the repository-local Git identity. Sage's established identity is `Sage (ChatGPT) <sage@chatgpt.invalid>`. If it is absent or incorrect, configure it with `git config --local user.name "Sage (ChatGPT)"` and `git config --local user.email "sage@chatgpt.invalid"`.
6. Keep Sage's identity repository-local; do not change the Architect's global Git identity or use the Architect's name/email for Sage-authored commits. `make ugu` removes repository-local overrides, so if it is run during initialization, restore the established Sage identity immediately afterward.
7. Verify the effective identity and its source with `git config --show-origin --get user.name`, `git config --show-origin --get user.email`, `git var GIT_AUTHOR_IDENT`, and `git var GIT_COMMITTER_IDENT`. Do not create a Sage-authored commit until both author and committer resolve to the established Sage identity.

## Choose a transfer method

- **Complete repository transfer:** use when the Engineer's workspace is new, has been wiped, or no longer contains a trustworthy current repository. Preserve `.git/` when history is required.
- **Incremental bundle exchange:** use for routine collaboration when both sides have compatible repository history. A Git bundle transfers the commits and Git objects needed to update the receiving repository.

## Receive an incremental bundle

The current transfer filename is `update.bundle`; `.update.bundle.sha256` records the last successfully applied bundle hash when present.

Before applying an incoming bundle:

- inspect `git status --short` and protect existing local changes;
- run `git bundle verify update.bundle`;
- calculate its hash with `sha256sum update.bundle` and compare it with `.update.bundle.sha256` when that marker exists;
- inspect the intended changes and confirm that the bundle is the expected transfer.

The project apply target is `make ab`. Applying a bundle changes the repository and may create a local commit. The current `apply_bundle()` function determines incoming scope relative to the common Git ancestor and applies only additions, modifications, and rename/copy destinations. It intentionally does not apply incoming deletions: existing paths absent from the bundle, including the source side of a rename, remain in the receiving repository until their removal is separately authorized. Files outside the incoming changed-path set remain untouched.

Before copying, the function checks every incoming destination. It aborts if a destination has uncommitted local changes or would overwrite an untracked local file; it also refuses to proceed when staged changes already exist. The conflict checks occur before incoming source files are copied. The receiver's `.update.bundle.sha256` marker is local state: it is updated after successful application and is not copied from the sender. When a local commit is created, the incoming commit message, author identity, and author date are retained; the receiving repository's configured identity is the committer. Do not run the apply target without explicit authorization.

A bundle that changes `apply_bundle()` cannot use its own new implementation to apply itself. Verify that behavior with a subsequent bundle application in a controlled repository.

## Create and deliver an outgoing bundle

1. This outgoing handoff is mandatory after every successful commit; it is not conditional on a separate transfer request. Complete and validate the authorized changes under the Rotational Cycle.
2. Review `git status --short` and `git diff`; commit only the intended files with the required authorization. Preserve and isolate unrelated changes so the post-commit packaging worktree can be clean; restore them after the bundle is created and delivered.
3. Confirm that the base commit configured in `create_git_bundle()` in `sh/lib.sh` exists and is an ancestor of `HEAD`.
4. Ensure there are no uncommitted source changes. The local `.update.bundle.sha256` marker is receiver-specific state and is excluded from the outgoing bundle cleanliness check.
5. Run `make cgb` to create and verify `update.bundle` in the Engineer's workspace.
6. Inspect the resulting bundle and calculate its SHA-256 hash before delivery.
7. Before delivery, inspect the actual destination directory and apply the general file-naming collision rule: keep `update.bundle` when available; otherwise use the next integer suffix in parentheses (`update(1).bundle`, `update(2).bundle`, and so on). Determine the next number from the highest existing suffix for that exact basename and extension. Do not rely on automatic duplicate naming, timestamps, or stale listings.
8. Copy the bundle additively into the Architect's persistent Library at `/finances/030_trading_intel/`. The Engineer's `/mnt/data/` workspace is private to the execution environment and is not a delivery location. Never overwrite, rename, or delete an existing Library bundle.
9. Verify the exact resulting Library filename, path, size, and SHA-256 hash, and report them.

A sandbox link or a path under the Engineer's `/mnt/data/` is not a substitute for placing the artifact in the Architect's Library. If unrelated local changes prevent `make cgb` from running, preserve them safely and isolate them from the clean packaging worktree; never discard them.

## Complete repository transfer

When a complete transfer is necessary, create or obtain an archive of the project root that includes `.git/` if history must be preserved. After extraction, verify that `.git/HEAD` exists, `git rev-parse --show-toplevel` resolves to the extracted project root, `git log -1` returns the expected commit, and `git status --short` reflects the expected state.

Do not assume a previous virtual workspace survived a conversation refresh or a change of AI execution environment. Verify the repository and its history before continuing.
