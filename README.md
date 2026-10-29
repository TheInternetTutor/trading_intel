# Trading Intel

Trading Intel is a Make-driven toolkit for reconstructing and processing Interactive Brokers (IBKR) trading-lot inventory and position data. It combines GNU Make, Bash, AWK, jq, and Python scripts. The Makefile and its included `mk/*.mk` files define the available workflows; inspect them before running commands that fetch data or modify the repository.

## Getting started

### 1. Expand the complete repository

Work from the repository root—the directory containing `makefile`, `mk/`, `sh/`, `jq/`, `py/`, `data/`, and `.git/`. Preserve `.git/` when transferring the full repository so its history and configuration remain available.

After extracting or restoring the repository in a new environment, **the first Make rule to execute is `itd`**:

`make itd`

This initializes the refresh-period (CRP) trigger file(s) in the temporary directory. Run it before any other Make target that may depend on refresh triggers. In the current configuration, the trigger is `/tmp/crp_260706065936.tmp`; temporary files may need to be initialized again when the environment is recreated.

### 2. Inspect the available commands and repository state

Run `make` (or `make h`) to print the self-documenting target list. Run `make i` for project information. Review `git status --short`, `git log -1`, the relevant Makefile fragments, and `ISSUES_TO_RESOLVE.md` before selecting a workflow.

Do not assume that every listed target is safe for every environment. In particular, inspect the prerequisites and side effects of acquisition, processing, debug-toggle, bundle, and packaging targets before running them.

### 3. Configure Git identity for the current collaborator

Set the intended collaborator identity in the home/global Git configuration. Replace the example values with that collaborator's own identity:

- `git config --global user.name "Your Name"`
- `git config --global user.email "you@example.com"`

Then remove any repository-local identity overrides with the project's Make rule:

`make ugu`

Verify the effective identity and where it comes from:

- `git config --show-origin --get user.name`
- `git config --show-origin --get user.email`
- `git var GIT_AUTHOR_IDENT`
- `git var GIT_COMMITTER_IDENT`

Git's local settings override global settings, which is why `make ugu` is part of setup. Do not create commits until the effective author and committer identities have been checked. Each human or AI collaborator should configure their own intended identity; do not blindly reuse another collaborator's identity.

### 4. Review incoming changes before applying a bundle

The bundle exchange filename used by the current scripts is `update.bundle`, with `.update.bundle.sha256` recording the last applied bundle hash. Place or replace the incoming `update.bundle` at the repository root only when it is the intended transfer artifact.

Before applying it, inspect the repository status and incoming bundle. For example:

- `git status --short`
- `git bundle verify update.bundle`
- `sha256sum update.bundle`
- Compare the resulting hash with `.update.bundle.sha256`, if that marker exists.

The project's apply rule is `make ab`. **Do not run it merely because a bundle is present.** Review what it will change and obtain explicit authorization before applying it. The current `apply_bundle()` function verifies the bundle, copies its source files into the repository, and stages changes. If it creates a local commit, it uses the incoming commit message and preserves the incoming commit author name, email, and author date; the receiving repository’s configured identity remains the committer. It then updates the hash marker. Applying a bundle is therefore a repository-changing operation, not just a read-only import. A bundle that introduces a change to `apply_bundle()` cannot use that new logic to apply itself; verify the changed behavior with a later bundle application.

### 5. Development and validation cycle

For each authorized change:

1. Inspect the current source, repository status, and relevant issue entry.
2. Identify the smallest logical change and the appropriate existing validation command.
3. Make only the authorized change; do not run ahead into unrelated fixes.
4. Validate syntax and behavior with the available checks and relevant test data. Record what was and was not actually tested.
5. Review `git diff` and `git status --short`; confirm that only intended files changed.
6. Discuss unexpected differences or unresolved behavior before proceeding.
7. Commit only when explicitly authorized. A change request or permission to edit is not automatically permission to commit, package, publish, or overwrite a persistent artifact.

Use the incremental test-data workflow where applicable. `make tp` is described as a test pipeline that does not update data, while `make plinu` processes lot data without updates; inspect their prerequisites in the current environment before relying on them. The `make flpp` workflow fetches lots and positions and processes them, so treat it as a data-acquisition workflow, not a routine validation command.

### 6. Useful Make targets

The exact available targets are printed by `make`. The current help includes these aliases:

| Target | Purpose |
|---|---|
| `make itd` | Initialize refresh-period trigger files; run first in a new environment. |
| `make h` | Display self-documenting help. |
| `make i` | Display project information. |
| `make dfm` | Regenerate/display the project file manifest. Review changes before keeping them. |
| `make sgu` | Show Git identity/configuration information. |
| `make ugu` | Remove repository-local Git `user.name` and `user.email` overrides. |
| `make fli` / `make fpi` | Fetch open-lot / live-position data; inspect side effects before use. |
| `make pli` / `make nli` | Process / normalize lot inventory. |
| `make tp` / `make plinu` | Test pipeline / process lots without updates, subject to prerequisites. |
| `make ab` | Apply the root-level `update.bundle`; repository-changing and authorization-gated. |
| `make cgb` | Create and verify an incremental `update.bundle`; may replace a same-named bundle in the repository root. |
| `make zr` | Create a ZIP containing tracked project files and Git database material. Inspect its naming and contents before distributing it. |

Targets that fetch or process data can have dependencies and environmental assumptions. The presence of a target in help does not mean it has been validated in the current environment.

### 7. Create and deliver an incremental bundle

After authorized changes have been validated and committed, `make cgb` invokes `create_git_bundle()` to create and verify `update.bundle` relative to the base commit configured in `sh/lib.sh`. Check that the configured base commit exists and is an ancestor of `HEAD`, and inspect the generated bundle before delivery. Bundle creation may replace `update.bundle` in the working repository, so preserve any bundle that must remain available before running the rule.

A Git bundle carries the relevant Git objects and commits, allowing a collaborator to transfer incremental repository changes without repeatedly transferring the entire source tree. It is different from a complete repository ZIP: a bundle is intended for the project's defined update workflow, while a ZIP may carry the full project directory and `.git/` database.

Agree on the delivery method and destination with the receiving collaborator; the README intentionally does not prescribe a user-specific delivery location. When saving a bundle or archive to persistent storage, **never overwrite an existing persistent bundle or archive**. Save a separate copy and allow the storage system to assign a duplicate-safe name/version, such as a `(1)` suffix, when needed.

### 8. Receive the next bundle and resume work

When a collaborator supplies the next bundle, first review the repository state, then place or replace the intended `update.bundle` at the repository root. Verify it and inspect its hash before applying it. Use the appropriate available Make rule—currently `make ab`—only after reviewing the proposed changes and obtaining authorization. Re-run `make itd` first if this is a newly created or reinitialized environment.

If work resumes after several days, a refresh, or a change of AI execution environment, do not assume the previous virtual workspace persisted. Obtain the latest complete repository or the agreed update artifact, verify its contents and Git state, and repeat the setup checks—especially `make itd` as the first Make rule in a new environment.

## Known issues

`ISSUES_TO_RESOLVE.md` is the separate checklist for technical issues that still need investigation or resolution. Keep detailed issue descriptions there rather than duplicating them in this README. Remove an issue from that checklist only after the fix has been implemented and verified; update the checklist as development progresses.

## Safety and change control

- Inspect before executing; prefer read-only inspection before workflows with side effects.
- Do not run production acquisition, apply a bundle, create a commit, generate a release archive, or overwrite a persistent artifact without the required authorization.
- Keep source changes, test results, commits, user acceptance, and persistent delivery as distinct states.
- Report accurately which commands ran, what they changed, and which checks passed or remain outstanding.
