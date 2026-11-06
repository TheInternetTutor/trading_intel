## Issue: CSV Parsing Compatibility Between GNU AWK and Mawk

### Problem
The CSV normalizer:
`sh/ibkr_lots_normalize.awk`

Relies on GNU AWK's `FPAT` extension to identify CSV fields.

The development environment uses Mawk (`mawk 1.3.4`), which does not implement GNU AWK's FPAT behavior.

Consequently, Mawk does not correctly split the CSV records according to the intended field patterns.

The normalizer can therefore generate malformed JSONL output.

A subsequent jq operation reported:
`jq: parse error: Invalid numeric literal at line 1, column 56`

### Objective
Make CSV normalization compatible with both GNU AWK and Mawk without requiring users to install additional software.

### Proposed Solutions

**Option A — Rewrite using POSIX-compatible AWK**

- Replace FPAT-dependent field extraction with portable AWK parsing logic.
- Correctly handle quoted CSV fields.
- Preserve commas inside quoted fields.
- Handle escaped quotation marks.
- Investigate whether embedded newlines in quoted fields must also be supported.

**Option B — Introduce a separate CSV parsing stage**

- Use a dedicated CSV parser to normalize the input.
- Pass the resulting records to the AWK processing stage.
- Evaluate the additional dependency and maintenance implications.

**Option C — Require GNU AWK**

- Retain the existing FPAT implementation.
- Explicitly detect GNU AWK before executing the pipeline.
- Fail with a clear diagnostic if GNU AWK is unavailable.

### Recommendation
Investigate Option A first.

Before modifying the script, inspect its existing FPAT expression and identify all CSV formatting cases it must support.

Do not assume that simple comma-separated field extraction is sufficient.

### Validation
- Test identical CSV inputs using GNU AWK and Mawk.
- Compare their normalized JSONL outputs.
- Validate the resulting JSONL using jq.
- Test quoted fields containing commas and escaped quotation marks.
- Test embedded newlines if required by the source data.
- Verify that the resulting trading-lots pipeline produces equivalent results.

### Scope Restrictions
- Preserve existing business logic.
- Avoid unrelated changes to the pipeline.
- Establish a known-good baseline before modifying the normalizer.
## Implementation investigation — 2026-11-06

Option A has been implemented in `sh/ibkr_lots_normalize.awk`:

- Replaced GNU AWK `FPAT` field splitting with a character-by-character CSV record parser using portable AWK features.
- Supports quoted fields, commas inside quoted fields, doubled quotes (`""`), and empty fields.
- Rejects an unterminated quoted field and rejects records that do not contain the expected 23 columns.
- The current IBKR export contains 449 data records and no embedded newlines inside quoted fields. The parser processes physical input lines; multiline quoted fields are not supported because they are not present in this export.

Validation performed with the installed `mawk 1.3.4`:

- Normalized all 449 data records successfully.
- Parsed the complete JSONL with `jq`; numeric output fields were verified as JSON numbers.
- Compared key fields (`report_date`, `symbol`, `conid`, `quantity`, and `description`) against all 449 source CSV records.
- Tested a description containing both a comma and escaped double quotes; passed.
- Tested empty fields; passed.
- Tested an unterminated quoted field; correctly rejected.
- Captured repeatable viewer snapshots `010.diff` and `020.diff`; their contents are identical.

Limitations / remaining validation:

- GNU AWK is not installed in this execution environment, so a same-input GNU AWK versus mawk comparison could not be performed here. The implementation no longer uses `FPAT` or other GNU AWK-specific features.
- `make tp` did not regenerate the stale JSONL during this run. The current no-update path touches files under `data/` before invoking the processing target, so the existing output can appear up-to-date to Make. The normalizer was therefore exercised directly through the shared `normalize_lot_inventory` function. End-to-end Make-target regeneration remains to be investigated separately.

The issue remains open pending GNU AWK cross-environment comparison and confirmation that the normal Make test path actually regenerates the normalized JSONL.
