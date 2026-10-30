# Separate the Source Manifest from Git Internals

**Status:** Open

## Purpose

Keep the project source manifest stable and useful by preventing Git's internal database files from being listed as ordinary project source files.

## Scope

Review the `zr` workflow and the rules that generate `files.manifest`. The original issue notes that `.git/` files are currently included and that Git object files change as repository history changes.

## Required work

- Inspect the current manifest-generation workflow and its consumers.
- Decide whether `files.manifest` should list project source/data files only or serve a separate archival purpose.
- Keep Git repository packaging separate if both source manifests and repository archives are needed.
- Regenerate the manifest using the chosen rules.
- Verify the inclusion and exclusion behavior.

## Completion evidence

- The manifest's purpose and inclusion rules are explicit.
- Git internals are excluded from a source/data manifest, or a separately justified archival design is documented.
- Regeneration produces the expected file set without noisy Git-object entries.
