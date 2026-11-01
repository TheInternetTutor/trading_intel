# Safety and Change Control

- Inspect before executing; prefer read-only inspection before workflows with side effects.
- Do not run production acquisition, apply a bundle, create a commit, or overwrite a persistent artifact without the required authorization.
- Treat data acquisition and processing as workflows with possible side effects, not as routine validation.
- Keep source changes, test results, commits, user acceptance, and persistent delivery as distinct states.
- Report accurately which commands ran, what they changed, and which checks passed or remain outstanding.
- Review `git diff` and `git status --short` before finalizing an authorized change.
