# Define Codebase Scope and Inspection Boundaries

## Purpose

Make the boundaries of the Trading Intel implementation explicit so that a new AI engineer can inspect the executable codebase efficiently without treating every project directory or supporting document as implementation source.

## Scope

Review the repository's current top-level files and directories, including the Makefile system, source modules, data, documentation, work items, notes, and auxiliary directories. Establish which paths constitute the implementation codebase and which provide supporting context, project records, test/input data, generated output, or other resources.

## Required work

- Identify the directories and root-level files that constitute the implementation codebase.
- Identify directories that are supporting materials rather than implementation source, including (where present) `README/`, `work_items/`, `Notes/`, and `@/`.
- Clarify the role of data, test fixtures, generated artifacts, configuration, and build/orchestration files; do not classify them as source code or exclude them without explanation.
- Add a concise **Codebase Scope and Inspection Boundaries** section to the AI-oriented README source, `README/000_ai_entry_point.md`.
- Explain that codebase inspection should trace execution and dependencies through the implementation, using supporting documentation and work items when relevant rather than reading every supporting document by default.
- Regenerate the root `README.md` using the documented `make grr` workflow.
- Verify that the generated README accurately reflects the defined boundaries and that the paths named in it exist.

## Completion evidence

- The implementation scope is explicitly identified by path.
- Supporting directories and their purposes are distinguished from implementation source.
- Root-level build and configuration files are accounted for.
- The AI-oriented README source and generated root README agree.
- A new engineer can determine where to begin a codebase inspection without having to infer the scope from directory names.
