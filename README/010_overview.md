# Project Collaboration Overview

This documentation describes a reusable collaboration model for developing and maintaining a software repository. It defines two related but independently usable workflows: Data Interchange and Development.

## Roles

- **Architect** — generally a human. Responsible for architectural direction, project coordination, and repository ownership.
- **Engineer** — generally an AI or another human. Responsible for engineering tasks, implementation, testing, and returning changes.

These names describe responsibilities, not employment titles. One person may perform both roles when appropriate.

## The two workflows

### Data Interchange Cycle (`-dic-`)

The Data Interchange Cycle governs how the Architect and Engineer exchange repository state and completed work. The Architect generally supplies the complete repository when the Engineer's workspace is new or unavailable. During routine collaboration, the Engineer generally returns incremental Git bundles containing authorized changes.

The cycle can be used independently of the Development Cycle. Its concern is repository transfer and synchronization, not how code changes are designed or tested.

### Development Cycle (`-dc-`)

The Development Cycle governs how the Engineer investigates, modifies, executes, and evaluates the software. It uses repeatable runs and a sequence of numbered output snapshots. Each new snapshot is compared with the immediately preceding snapshot; the newest snapshot then becomes the baseline for the next iteration.

The cycle can be used independently of Data Interchange. Its concern is controlled development and evidence-based validation, not transferring repository state.

## Relationship

The workflows are complementary but not dependent on one another. Data Interchange may occur before or after development when repository state must be transferred or synchronized. Development may proceed through many iterations without an interchange operation between each iteration.
