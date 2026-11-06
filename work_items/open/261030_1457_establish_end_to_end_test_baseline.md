# Establish a Repeatable End-to-End Test Baseline

## Purpose

Establish a repeatable test-data baseline for the inventory pipeline and verify lot reconstruction and position reconciliation before any production update is attempted.

## Scope

The test-data pipeline, its expected outputs and record counts, validation checks, lot reconstruction, and position reconciliation.

## Prerequisites

This baseline is intended to follow resolution of the preceding technical issues in the original issue register. Do not treat this work item as authorization to acquire or modify production data.

## Required work

- Run the test-data pipeline after the relevant issues have been addressed.
- Capture expected outputs, record counts, and validation checks.
- Verify lot reconstruction.
- Verify position reconciliation.
- Keep production-data acquisition separate from routine validation wherever practical.

## Completion evidence

- The test-data workflow can be repeated with documented expected outputs and checks.
- Lot reconstruction and position reconciliation pass the established validations.
- Production acquisition remains separate from the routine test baseline.
