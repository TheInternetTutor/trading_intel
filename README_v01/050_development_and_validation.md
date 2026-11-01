# Development and Validation Cycle

For each authorized change:

1. Inspect the current source, repository status, and relevant open work item.
2. Identify the smallest logical change and the appropriate existing validation command.
3. Make only the authorized change; do not run ahead into unrelated fixes.
4. Validate syntax and behavior with the available checks and relevant test data. Record what was and was not actually tested.
5. Review `git diff` and `git status --short`; confirm that only intended files changed.
6. Discuss unexpected differences or unresolved behavior before proceeding.
7. Commit only when explicitly authorized. Permission to edit is not automatically permission to commit, package, publish, or overwrite a persistent artifact.

Use the incremental test-data workflow where applicable. `make tp` is described as a test pipeline that does not update data, while `make plinu` processes lot data without updates; inspect their prerequisites in the current environment before relying on them. The `make flpp` workflow fetches lots and positions and processes them, so treat it as a data-acquisition workflow, not a routine validation command.
