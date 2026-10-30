# Incremental Git Bundle Exchange

The bundle exchange filename used by the current scripts is `update.bundle`, with `.update.bundle.sha256` recording the last applied bundle hash. Place or replace the incoming `update.bundle` at the repository root only when it is the intended transfer artifact.

## Review and apply an incoming bundle

Before applying a bundle, inspect the repository state and incoming bundle:

- `git status --short`
- `git bundle verify update.bundle`
- `sha256sum update.bundle`
- Compare the resulting hash with `.update.bundle.sha256`, if that marker exists.

The project's apply rule is `make ab`. Do not run it merely because a bundle is present. Review what it will change and obtain explicit authorization before applying it.

The current `apply_bundle()` function verifies the bundle, copies its source files into the repository, and stages changes. If it creates a local commit, it uses the incoming commit message and preserves the incoming commit author name, email, and author date; the receiving repository's configured identity remains the committer. Applying a bundle is a repository-changing operation, not just a read-only import.

A bundle that introduces a change to `apply_bundle()` cannot use that new logic to apply itself; verify the changed behavior with a later bundle application.

## Create and deliver an outgoing bundle

After authorized changes have been validated and committed, `make cgb` invokes `create_git_bundle()` to create and verify `update.bundle` relative to the base commit configured in `sh/lib.sh`. Check that the configured base commit exists and is an ancestor of `HEAD`, and inspect the generated bundle before delivery. Bundle creation may replace `update.bundle` in the working repository, so preserve any bundle that must remain available before running the rule.

A Git bundle carries the relevant Git objects and commits, allowing collaborators to transfer incremental repository changes without repeatedly transferring the complete source tree.

## Complete repository ZIP transfer

A complete repository ZIP is a temporary transfer mechanism used when the receiving workbench has been wiped or the repository is otherwise unavailable. It must include the `.git/` directory when preserving project history is required. ZIP files are not maintained as a sequence of project versions; Git is the authoritative development history. The ZIP is not a substitute for incremental bundle exchange during normal collaboration.

When work resumes after a refresh or a change of AI execution environment, do not assume the previous virtual workspace persisted. Obtain the current complete repository transfer or the agreed incremental bundle, verify its contents and Git state, and repeat the setup checks—especially `make itd` as the first Make rule in a new environment.
