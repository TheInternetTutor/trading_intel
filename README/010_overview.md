# Project Collaboration Overview

This documentation defines the collaboration model and the authoritative documentation structure for Trading Intel. It describes two related but independently usable workflows: Data Interchange and Iterative Development.

## Roles

- **Architect** — generally the human who owns the repository and directs work, architecture, and authorization.
- **Engineer** — generally an AI or another human who inspects, implements, validates, and returns authorized changes.

These names describe responsibilities, not employment titles. One person may perform both roles when appropriate.

## Documentation hierarchy

The repository has one root entry point and one detailed documentation source:

1. **Root `README.md`:** the concise, AI-oriented entry point. It is generated from `README/000_ai_entry_point.md` by `make grr`. It orients an AI, identifies operating rules, and links to the detailed modules.
2. **`README/` directory:** the current modular documentation source. The numbered Markdown documents provide the detailed explanations, procedures, rationale, and reference material for humans and AI agents. Read the relevant modules before performing work; the root README is not a substitute for them.
3. **`README_v01/`:** historical archive retained for comparison and recovery. It is not the current source of documentation.

The root `README.md` is the only recognized root documentation entry point; no parallel reference document is maintained. The source file `README/000_ai_entry_point.md` is the maintained AI-oriented content; regenerate the root copy after editing it.

The Makefile and current source code remain authoritative for actual command behavior. Documentation should explain purpose, assumptions, risks, and expected outcomes, and should be updated when implementation changes.

## The two workflows

### Data Interchange Cycle (`-dic-`)

The Data Interchange Cycle governs how the Architect and Engineer exchange repository state and completed work. The Architect generally supplies a complete repository when the Engineer's workspace is new or unavailable. During routine collaboration, the Engineer generally returns incremental Git bundles containing authorized, committed changes.

The cycle can be used independently of the Iterative Development Cycle. Its concern is repository transfer and synchronization, not how code changes are designed or tested. See [Data Interchange Cycle](020_data_interchange_cycle.md).

### Iterative Development Cycle (`-idc-`)

The Iterative Development Cycle governs how the Engineer investigates, modifies, executes, and evaluates the software. It uses a project-configured Data Generator to produce standardized analysis data, controlled changes, repeatable runs, and numbered output snapshots. Each new snapshot is compared with the immediately preceding snapshot; the newest snapshot then becomes the baseline for the next iteration. After every successful Git commit, the IDC also requires a verified and durably persisted repository archive checkpoint.

The cycle can be used independently of Data Interchange. Its concern is controlled development and evidence-based validation, not transferring repository state. See [Iterative Development Cycle](030_iterative_development_cycle.md).

## Relationship

The workflows are complementary but not dependent on one another. Data Interchange may occur before or after development when repository state must be transferred or synchronized. Development may proceed through many iterations without an interchange operation between each iteration.
