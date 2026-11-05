## Issue: jq Script Line-Ending Compatibility

### Problem
Several jq scripts used CRLF (Windows) line endings.

This introduced unnecessary compatibility and maintenance concerns when processing the scripts in the Unix environment.

### Solution
Normalize the affected `.jq` files from CRLF to LF (Unix) line endings.

### Suggested Method
Use Git or a line-ending conversion utility such as `dos2unix`.

For example:
`dos2unix jq/*.jq`

Alternatively, use Git's line-ending configuration and normalization mechanisms.

### Validation
- Verify that the affected files use LF line endings.
- Run `git diff --check`.
- Execute the relevant jq filters.
- Ensure that normalization does not introduce unintended source changes.
