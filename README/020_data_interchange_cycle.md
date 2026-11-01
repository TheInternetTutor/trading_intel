# Data Interchange Cycle (`-dic-`)

## Purpose

The Data Interchange Cycle transfers and synchronizes repository state between the Architect and Engineer. It is concerned with repository availability, Git identity, and the controlled exchange of changes. It does not prescribe how implementation work is developed or validated.

## Choose the transfer method

- **Complete repository transfer:** use when the Engineer's workspace is new, has been wiped, or no longer contains a trustworthy current repository. Preserve the `.git/` directory when history is required.
- **Incremental bundle exchange:** use for routine collaboration when both sides have a compatible repository history. Transfer only the commits and Git objects needed to update the receiving repository.

Git remains the authoritative development history. A complete ZIP is a recovery or bootstrap transfer, not the routine substitute for incremental exchange.

## Establish the Engineer's repository

1. Obtain the complete repository or the agreed incoming bundle.
2. Work from the repository root, where the project Makefile and `.git/` directory reside.
3. Verify the repository root and current state with `git rev-parse --show-toplevel`, `git status --short`, and `git log -1`.
4. In a newly created execution environment, run `make itd` before other Make targets that rely on refresh triggers. This initializes the temporary trigger dependencies declared by the included Make modules.
5. Configure the Engineer's intended global Git identity, using the Engineer's own name and email:
   - `git config --global user.name "Your Name"`
   - `git config --global user.email "you@example.com"`
6. Run `make ugu` to remove repository-local `user.name` and `user.email` overrides.
7. Verify the effective identity and its source with `git config --show-origin --get user.name`, `git config --show-origin --get user.email`, `git var GIT_AUTHOR_IDENT`, and `git var GIT_COMMITTER_IDENT`.
8. Do not create commits until the intended author and committer identities have been verified.

## Receive an incremental bundle

The current transfer filename is `update.bundle`; `.update.bundle.sha256` records the last applied bundle hash when present.

Before applying an incoming bundle:

- inspect `git status --short` and protect any existing local changes;
- run `git bundle verify update.bundle`;
- calculate its hash with `sha256sum update.bundle` and compare it with `.update.bundle.sha256` when that marker exists;
- inspect the intended changes and confirm that the bundle is the expected transfer.

The project apply target is `make ab`. Applying a bundle changes the repository: the current implementation copies incoming source files into the repository and stages changes, and may create a local commit. It preserves the incoming author identity and author date when it creates that commit; the receiving repository's configured identity is the committer. Do not run the apply target without explicit authorization.

A bundle that changes the bundle-application function cannot use its own new implementation to apply itself. Verify such a change through a subsequent bundle application.

## Send an incremental bundle

1. Ensure the requested work has been validated and committed with the required authorization.
2. Confirm that the configured base commit in `sh/lib.sh` exists and is an ancestor of `HEAD`.
3. Run `make cgb` to create and verify `update.bundle` in the Engineer's workspace.
4. Inspect the resulting bundle and calculate its hash before delivery.
5. Copy the bundle into the Architect's persistent workbench Library at `/030_trading_intel/`. This is the shared transport location the Architect can access; the Engineer's `/mnt/data/` workspace is private to the execution environment and is not a delivery location.
6. Upload additively. Never overwrite or delete an existing Library bundle. If `update.bundle` already exists, allow the Library to assign a duplicate-safe name such as `update(6).bundle` and report the exact resulting path.
7. Verify that the uploaded Library item exists and that its size matches the locally verified bundle. Report its Library path and hash to the Architect.

A sandbox link or a path under the Engineer's `/mnt/data/` is not a substitute for placing the artifact in the Architect's Library. A bundle carries the relevant Git objects and commits, allowing the receiving repository to apply the incremental update without receiving the entire source tree again.

## Complete repository transfer

When a complete transfer is necessary, create or obtain an archive of the project root that includes `.git/` if history must be preserved. After extraction, verify that `.git/HEAD` exists, `git rev-parse --show-toplevel` resolves to the extracted project root, `git log -1` returns the expected commit, and `git status --short` reflects the expected state.

Do not assume a previous virtual workspace survived a conversation refresh or a change of execution environment. Verify the repository and its history before continuing.
