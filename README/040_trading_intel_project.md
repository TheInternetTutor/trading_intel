# Trading Intel Project

## Project purpose

Trading Intel is a Make-driven toolkit for reconstructing and processing Interactive Brokers (IBKR) trading-lot inventory and position data. It combines GNU Make, Bash, AWK, jq, and Python. The project emphasizes inspectable transformations, repeatable processing, and a clear boundary between data preparation and presentation.

The lowercase root-level `makefile` and its included `mk/*.mk` files define the available workflows. Inspect the relevant rules before running commands that fetch data, toggle environments, or modify repository contents.

## Repository layout

- `makefile` — project entry point and Make orchestration.
- `mk/` — included Make rules and workflow definitions.
- `sh/` — shell and AWK utilities, including shared functions and the lot viewer.
- `jq/` — jq filters and shared jq utilities.
- `py/` — Python processing code.
- `data/` — inventory data and test fixtures.
- `work_items/open/` — issues and tasks requiring investigation, implementation, or verification.
- `work_items/completed/` — work items whose completion criteria have been verified.
- `README/` — current modular documentation source.
- `README_v01/` — historical documentation archive, not the current source.
- `.git/` — Git history and repository metadata; preserve it when transferring the complete repository.

## Processing and viewer boundary

The lot-processing pipeline prepares JSONL data consumed by `sh/view_lots.sh`. The viewer is a separate presentation and reporting layer: it reads prepared data, checks that its input file exists, and renders terminal views or reports. It does not replace the Make pipeline that creates the data.

The viewer's default input is configured in the script as `data/view_lots.jsonl` relative to the resolved project root. An alternate JSONL path can be supplied as the script's first argument. The Makefile derives `dir_tidata` as `<workspace-root>/trading_intel/data`, so its current path logic expects the checkout to be named `trading_intel` and placed directly under its workspace root. Confirm this layout and the actual path produced by the active Make configuration before invoking the viewer.

## Documentation

The root `README.md` is the AI-oriented entry point generated from `README/000_ai_entry_point.md`. The remaining numbered modules under `README/` provide detailed explanations and procedures for both human readers and AI agents. See `README/010_overview.md` for the documentation hierarchy and module map.

## Trading Intel-specific Rotational Cycle configuration

This section supplies the project-specific settings required by the generic procedure in `README/030_iterative_development_cycle.md`. When reusing the generic IDC documentation in another project, replace this configuration section with that project's commands and output contract.

### Initialization and source inspection

- Run `make itd` to initialize temporary refresh-trigger dependencies.
- Run `make ite` to check test mode. If it reports `false`, run `make td` once and verify again. If it reports `true`, do not toggle it.
- Use `make gcf | make ds` to display tracked source sections enclosed by `<disec>` and `</disec>` markers when useful.

### Data preparation

Run `make tp` to execute the test pipeline and prepare the data consumed by the Data Generator. It requires test mode and suppresses the pipeline's normal standard output. It prepares the input data; it does not create the numbered snapshot.

### Data Generator

The Trading Intel Data Generator is the `render_lots_view` Bash function defined by `sh/view_lots.sh`. It renders the prepared lots JSONL input as a pipe-delimited, analysis-ready lots dataset. It is a data-generation interface for inspection and AI-assisted analysis, not a general report-generation command.

With the default input path, capture a snapshot using:

`set -o pipefail && source sh/view_lots.sh >/dev/null && render_lots_view | LC_ALL=C sort > 010.diff`

To use another JSONL input, pass its path when sourcing the script:

`set -o pipefail && source sh/view_lots.sh /path/to/view_lots.jsonl >/dev/null && render_lots_view | LC_ALL=C sort > 010.diff`

`set -o pipefail` ensures a failure in the rendering pipeline is returned instead of being masked by a successful final command. `LC_ALL=C sort` gives the records a stable, locale-independent order. Sorting is mandatory before capturing every snapshot. Increase the three-digit snapshot number by ten for each new execution; never overwrite a prior snapshot.

### Snapshot naming and comparison

Use three-digit snapshot names in increments of ten: `010.diff`, `020.diff`, `030.diff`, and so on. Compare consecutive snapshots with:

`diff -Bydaw --suppress-common-lines -W115 010.diff 020.diff`

Substitute the two most recent snapshot filenames for each subsequent comparison. Preserve earlier snapshots and do not create pair-named comparison files.

### Post-commit recovery archive

Immediately after every successful Git commit in the IDC, run:

`make zr`

The target creates `trading_intel.zip` in the repository root. Its current `zip_repository()` implementation packages Git-tracked working-tree files together with `.git/`. It reads tracked path names from `git ls-files` and includes the current working-tree contents of those paths. Therefore, modified tracked files that remain uncommitted can appear in the archive; inspect `git status --short` and understand that state before packaging. Untracked and ignored files are not included. In particular, numbered `*.diff` snapshots are ignored and are not preserved by this ZIP target.

The target creates `trading_intel.zip` in the project root and replaces that project-local ZIP each time it runs. Run `make zr` immediately after every successful Git commit. Verify the ZIP with `unzip -t trading_intel.zip` and confirm that it contains the project files and `.git/` database. Do not continue the Rotational Cycle until this checkpoint has been created and verified. If archive creation or validation fails, the commit remains valid but the recovery checkpoint is incomplete; resolve the failure and retry `make zr` without making another commit.

The archive is assembled from Git-tracked working-tree files plus `.git/`. It includes the current contents of tracked files, not necessarily only the committed versions. Therefore, to make the archive represent exactly the latest commit, verify that the tracked working tree is clean before running `make zr`. Tracked modifications present at archive time are included; untracked and ignored files are excluded, including numbered `*.diff` snapshots. Ensure that any file required for recovery is tracked before relying on this archive. This is a complete tracked-repository recovery checkpoint, not an incremental Git bundle.

### Workbench persistence and restoration

The Engineer's workbench under `/mnt/data` is an ephemeral execution environment. Project files, temporary dependencies, and the Git database may disappear after a pause, reset, or reinitialization. Do not assume that an existing checkout or its `.git/` directory will remain available. The Architect's persistent Library remains the durable project store; the workbench archive is the recovery mechanism for rebuilding the Engineer's working copy.

The initial complete archive downloaded from the Library is kept outside the project directory as `trading_intel(10).zip`. Treat that archive as an unchanged bootstrap copy; do not overwrite it. Once development has produced a committed state and `make zr` has created a verified project-local `trading_intel.zip`, the project-local archive becomes the current workbench recovery point. Each later successful commit followed by a successful `make zr` replaces that recovery point with a newer one. Incremental Git bundles are for repository interchange and must not be treated as the immediate substitute for this post-commit recovery archive; bundles in the workbench may themselves be lost.

Observed workbench behavior indicates that ZIP archives have persisted in `/mnt/data`, including at the project-directory level, even when other workbench files have disappeared. Treat this as the tested recovery behavior for this workflow, not as a guarantee that arbitrary workbench files persist.

To restore the latest archived project after the checkout and Git database have disappeared:

1. Locate the latest `trading_intel.zip` that was created by `make zr` inside the project directory.
2. Move or copy that ZIP one level up, outside the project directory, so extraction does not target the archive's former location.
3. Extract the ZIP into `/mnt/data`. The archive contains a top-level `trading_intel/` directory, so extraction recreates the project directory and its `.git/` database.
4. Verify the restored repository root, `.git/HEAD`, latest commit, working-tree state, and ZIP integrity before continuing. Use `git rev-parse --show-toplevel`, `git log -1`, and `git status --short` from the restored project root.

Do not use the unchanged `trading_intel(10).zip` as the latest recovery point after newer committed work exists. It remains an initial fallback only. The current project-local `trading_intel.zip` is the archive to use for restoring the latest checkpoint.
