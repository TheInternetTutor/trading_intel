## Issue: jq Library Path Option Compatibility

### Problem
The Makefile pipeline used the long option `--library-path` when invoking jq.

The installed jq version (1.7) did not recognize this option, resulting in:
`jq: Unknown option --library-path`

### Cause
The compatible option for specifying jq module/library search paths is `-L`.

### Solution
Replace all occurrences of `--library-path` with `-L` in:
`mk/pipeline_jq.mk`

Example:
`jq -L jq/pipeline_jq -L jq ...`

### Validation
- Confirm no remaining occurrences of `--library-path`.
- Execute the affected jq commands.
- Verify successful execution and correct module resolution.
