# Safety and Change Control

- Inspect before executing; prefer read-only inspection before workflows with side effects.
- Do not run production acquisition, apply an incoming bundle, create a commit, or overwrite a persistent artifact without the required authorization.
- Treat data acquisition and processing as workflows with possible side effects, not as routine validation.
- Preserve unrelated working-tree changes. Stage only files that belong to the authorized change.
- Review `git diff` and `git status --short` before finalizing an authorized change.
- Keep source changes, test results, commits, user acceptance, packaging, and persistent delivery as distinct states.
- Preserve known-good source versions and useful execution snapshots when diagnosing regressions.
- Report accurately which commands ran, what they changed, which checks passed, and which checks remain outstanding.
