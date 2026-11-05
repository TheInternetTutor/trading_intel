# Data Interchange Cycle (`-dic-`)

## Purpose

The Data Interchange Cycle transfers and synchronizes repository state between the Architect and Engineer. It governs workspace availability, Git identity, and controlled exchange of changes. It does not prescribe how implementation work is developed or validated.

Git history is the authoritative development record. A complete archive is a bootstrap or recovery mechanism; incremental Git bundles are the routine exchange mechanism when both repositories share compatible history.

## Establish the Engineer's repository

1. Obtain the complete repository or the agreed incoming bundle.
2. Work from the repository root, where the project `makefile` and `.git/` directory reside.
3. Verify the repository root and current state with `git rev-parse --show-toplevel`, `git status --short`, and `git log -1`.
4. In a newly created execution environment, run `make itd` before other Make targets that rely on refresh triggers. This initializes temporary trigger dependencies declared by the included Make modules.
5. Run `make ugu` to remove repository-local `user.name` and `user.email` overrides. Do this before configuring the global identity because local values can override global values.
6. Configure your own global Git identity in your development environment. Set `user.name` and `user.email` to the identity you use when contributing, whether you are a human developer or an AI operating independently. For example: `git config --global user.name "Your Name"` and `git config --global user.email "you@example.com"`. Use an identity that belongs to you; never attribute commits to another person or contributor.
7. Verify the effective identity and its source with `git config --show-origin --get user.name`, `git config --show-origin --get user.email`, `git var GIT_AUTHOR_IDENT`, and `git var GIT_COMMITTER_IDENT`. Confirm that the effective values identify you as the contributor, not another person.
8. Do not create commits until the intended author and committer identities have been verified.

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

1. Complete and validate the authorized changes.
2. Review `git status --short` and `git diff`; commit only the intended files with the required authorization.
3. Confirm that the base commit configured in `create_git_bundle()` in `sh/lib.sh` exists and is an ancestor of `HEAD`.
4. Ensure there are no uncommitted source changes. The local `.update.bundle.sha256` marker is receiver-specific state and is excluded from the outgoing bundle cleanliness check.
5. Run `make cgb` to create and verify `update.bundle` in the Engineer's workspace.
6. Inspect the resulting bundle and calculate its SHA-256 hash before delivery.
7. Copy the bundle additively into the Architect's persistent Library at `/030_trading_intel/`. The Engineer's `/mnt/data/` workspace is private to the execution environment and is not a delivery location.
8. Never overwrite or delete an existing Library bundle. Allow duplicate-safe names such as `update(6).bundle`, and report the exact resulting Library path, size, and hash.

A sandbox link or a path under the Engineer's `/mnt/data/` is not a substitute for placing the artifact in the Architect's Library.

## Complete repository transfer

When a complete transfer is necessary, create or obtain an archive of the project root that includes `.git/` if history must be preserved. After extraction, verify that `.git/HEAD` exists, `git rev-parse --show-toplevel` resolves to the extracted project root, `git log -1` returns the expected commit, and `git status --short` reflects the expected state.

Do not assume a previous virtual workspace survived a conversation refresh or a change of AI execution environment. Verify the repository and its history before continuing.
