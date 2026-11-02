# Safety and Change Control

## Inspect before acting

- Inspect repository status, relevant documentation, Make rules, and source before executing a workflow.
- Prefer read-only inspection before commands with side effects.
- A target's presence in Make help does not establish that it is safe or validated in the current environment.

## Authorization boundaries

- Do not run production data acquisition, apply an incoming bundle, create a commit, push, or overwrite a persistent artifact without the required authorization.
- Authorization to edit does not automatically authorize committing, packaging, publishing, or persistent delivery. Follow the specific scope of the Architect's instruction.
- Do not add a Git remote or push unless explicitly authorized.

## Preserve state and evidence

- Preserve unrelated working-tree changes, untracked files, and useful historical checkpoints.
- Stage only files belonging to the authorized change. Do not include local-only state such as `.update.bundle.sha256` in a source commit unless explicitly required.
- Do not delete files merely because they are absent from an incoming bundle. Follow the documented bundle semantics and obtain separate authorization for destructive changes.
- Preserve useful test inputs, snapshots, and known-good source versions when diagnosing regressions.

## Validate and report

- Review `git diff` and `git status --short` before finalizing an authorized change.
- Keep source changes, test results, commits, user acceptance, packaging, and persistent delivery distinct.
- Report accurately which commands ran, what they changed, which checks passed, and which checks remain outstanding. Never imply that an action succeeded before verifying its result.
