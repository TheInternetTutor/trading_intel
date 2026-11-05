# Repair and Verify jq Filter Line Endings

## Purpose

Resolve jq parsing errors caused by carriage-return characters in `.jq` files and verify the affected filters against project sample data.

## Scope

The `.jq` files identified as containing carriage-return characters, the project's expected line-ending convention, and the affected sample-data executions.

## Required work

- Identify the affected `.jq` files and confirm the carriage-return issue.
- Normalize those files to one consistent line-ending format appropriate for the project.
- Run the affected filters against the bundled sample data.
- Verify expected record counts and output structure.

## Completion evidence

- Affected files use the selected consistent line-ending format.
- The affected jq filters parse and execute successfully.
- Record counts and output structure match the expected results for the sample data.
