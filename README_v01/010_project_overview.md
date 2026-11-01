# Trading Intel — Project Overview

Trading Intel is a Make-driven toolkit for reconstructing and processing Interactive Brokers (IBKR) trading-lot inventory and position data. It combines GNU Make, Bash, AWK, jq, and Python.

The lowercase root-level `makefile` and its included `mk/*.mk` files define the available workflows. Inspect those files before running commands that fetch data or modify the repository.

## Repository layout

- `makefile` — project entry point and Make orchestration.
- `mk/` — included Make rules and workflow definitions.
- `sh/` — shell and AWK utilities.
- `jq/` — jq filters and shared jq utilities.
- `py/` — Python processing code.
- `data/` — inventory data and test fixtures.
- `Work Items/` — issue and task tracking, separated into `Open/` and `Completed/`.
- `README/` — modular project documentation.
- `.git/` — Git history and repository metadata; preserve it when transferring the complete repository.

## Documentation organization

This directory contains independent documentation modules. Each module has a three-digit numeric prefix so documents can be inserted, reordered, and prioritized without renaming the entire set. The root `README.md` is intentionally retained as the pre-modularization reference copy during this transition.
