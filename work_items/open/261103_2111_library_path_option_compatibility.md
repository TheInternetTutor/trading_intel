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