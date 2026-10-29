# Trading Intel V11 — Issues to Resolve

This is a prioritized work list based on the initial review of Trading Intel V11. The items are recorded for later investigation and resolution; no source-code fixes are implied by this document.

## 1. Prevent invalid prices from entering inventory calculations

- Review `py/ibkr_position_inventory.py` and its historical-price fallback behavior.
- The current code can substitute a zero price when historical retrieval fails.
- Define explicit handling for unavailable prices so zero is not mistaken for a valid market price or propagated into downstream inventory and valuation calculations.
- Add or identify a test for missing, failed, and valid price retrieval.

## 2. Repair and verify jq filter line endings

- The `.jq` files contain carriage-return characters that cause jq parsing errors in the current environment.
- Normalize the files to a consistent line-ending format appropriate for the project.
- Re-run the affected filters against the bundled sample data and verify expected record counts and output structure.

## 3. Restore and verify market-open detection

- In `py/ibkr_position_inventory.py`, `is_market_open()` currently returns `False` immediately, leaving the intended market-time logic unreachable.
- Determine the intended market-hours and timezone behavior, then restore or replace the detection logic.
- Test both market-open and market-closed cases, including boundary times and unavailable live data.

## 4. Make Git bundle creation and application agree

- `create_git_bundle()` in `sh/lib.sh` creates `update.bundle`, while `apply_bundle()` expects `transport.bundle` and a related checksum marker.
- Choose one documented bundle filename and checksum convention and apply it consistently to creation, validation, and application.
- Verify the complete transfer cycle using a disposable repository or copy before relying on it for project updates.

## 5. Separate the source manifest from Git internals

- The `zr` workflow currently includes files under `.git/` in `files.manifest`.
- Git object files change as repository history changes, making the manifest noisy and potentially stale.
- Decide whether the manifest should list project source/data files only or serve a separate archival purpose; keep Git repository packaging separate if both are needed.
- Regenerate the manifest and verify its inclusion and exclusion rules.

## 6. Clarify Make target dependencies and refresh-trigger handling

- Dry runs of `fli` and `pli` showed missing temporary trigger files reaching the generic unknown-target rule and printing errors.
- Review how refresh triggers are created, consumed, and represented as Make prerequisites.
- Distinguish expected absent triggers from genuine unknown targets, and verify the dependency graph with dry runs and test data.
- Do not run production acquisition or data-changing targets until their side effects and prerequisites are understood.

## 7. Establish a repeatable end-to-end test baseline

- After the issues above are addressed, run the test-data pipeline and capture its expected outputs, record counts, and validation checks.
- Verify lot reconstruction and position reconciliation before attempting a production update.
- Keep production-data acquisition separate from routine validation wherever practical.
