
# Makefile Refactoring Project

## Objective

Refactor the trading_intel Makefile to maximize readability, maintainability, modularity, and ease of debugging **without changing any existing functionality**. The current pipeline is working correctly; the purpose of this project is purely structural.

The guiding principle is:

> **Behavior must remain identical. Only the organization should change.**

---

## Current Status

The pipeline now successfully performs:

1. Download Flex Query.
2. Normalize Flex data.
3. Canonicalize lots.
4. Download live positions.
5. Normalize live positions.
6. Merge live market prices into the Flex lots.
7. Continue with the existing jq classification pipeline.

This functionality is considered the baseline and should continue to produce identical output after every refactoring step.

---

## General Refactoring Goals

* Improve readability above all else.
* Make the pipeline visually resemble the logical processing stages.
* Reduce cognitive load while reading the Makefile.
* Keep every transformation easy to locate.
* Preserve the ability to inspect intermediate files.
* Avoid premature optimization.

---

## Suggested Organization

Organize the Makefile into logical sections such as:

* Configuration
* Variables
* Helper macros
* Download rules
* Normalization rules
* Live synchronization rules
* Inventory reconciliation rules (future)
* Classification pipeline
* Rendering
* Maintenance / utility targets

---

## Pipeline Presentation

Ideally the rule should read almost like documentation:

* Download Flex
* Normalize Flex
* Canonicalize Lots
* Download Live Positions
* Normalize Live Positions
* Synchronize Market Prices
* Reconcile Quantities (future)
* Consolidate Lots
* Classification Engine
* Viewer

A reader should immediately understand the processing flow.

---

## Formatting

Adopt one consistent formatting style throughout:

* One logical processing step per block.
* Identical formatting for every jq invocation.
* Identical formatting for every AWK invocation.
* Identical formatting for shell commands.
* Consistent indentation.
* Consistent blank lines between logical sections.

---

## Repeated Patterns

Look for repeated command structures that could become helper macros or reusable Make functions.

Examples include:

* jq invocation blocks
* echo/status messages
* sleep statements
* cp --force operations
* common output formatting

Do not introduce abstractions that reduce readability.

---

## Variable Naming

Review all variable names.

Goals:

* Consistent prefixes.
* Consistent abbreviations.
* Predictable naming.
* Easy autocomplete.
* Minimize ambiguous abbreviations.

Variables representing the same concept should follow the same naming pattern throughout the project.

---

## Intermediate Files

Preserve intermediate files.

They are valuable because they:

* simplify debugging,
* allow inspection with Beyond Compare,
* make unit testing easier,
* isolate failures.

Do not eliminate intermediate files simply to reduce the number of steps.

---

## Future Expansion

Design the Makefile so future stages fit naturally:

* Quantity reconciliation
* Synthetic lot insertion
* Multi-pass reconciliation
* Additional jq transformations
* Future visualization pipeline

Adding a new processing stage should require minimal changes.

---

## Debugging

The Makefile should remain debugging-friendly.

Every major step should clearly report:

* what is being executed,
* what file is being generated,
* where the next stage begins.

---

## Refactoring Strategy

Perform the refactoring incrementally.

After every structural change:

1. Execute the entire pipeline.
2. Verify that all generated outputs are identical.
3. Continue only after correctness is confirmed.

Never mix structural refactoring with functional changes.

---

## Overall Goal

Produce a Makefile that is easy to understand months from now, where the processing pipeline is immediately visible, each stage has a single responsibility, repeated patterns are standardized, and future stages can be added naturally without increasing complexity.
