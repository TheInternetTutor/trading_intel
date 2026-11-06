# Clarify Make Target Dependencies and Refresh Triggers

## Purpose

Ensure expected absent refresh-trigger files are handled deliberately and are not confused with genuine unknown Make targets.

## Scope

Review refresh-trigger creation and consumption, Make prerequisites, the generic unknown-target rule, and the `fli` and `pli` dry-run behavior described in the original issue register.

## Current issue

Dry runs of `fli` and `pli` reportedly allowed missing temporary trigger files to reach the generic unknown-target rule and print errors.

## Required work

- Trace how refresh triggers are created, consumed, and represented as Make prerequisites.
- Determine why expected absent triggers reach the generic unknown-target rule.
- Distinguish expected absent triggers from genuine unknown targets.
- Verify the dependency graph with dry runs and test data.
- Do not run production acquisition or data-changing targets until their side effects and prerequisites are understood.

## Completion evidence

- Expected trigger absence is handled without misleading unknown-target errors.
- Genuine unknown targets remain detectable.
- Relevant dry runs and test-data checks demonstrate the intended dependency behavior.
- Production side effects have not been triggered as part of routine validation without explicit authorization.
