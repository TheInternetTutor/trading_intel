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
