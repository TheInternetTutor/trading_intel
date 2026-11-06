# Align Git Bundle Creation and Application

## Purpose

Make Git bundle creation, validation, and application use one consistent documented bundle filename and checksum convention.

## Scope

Review `create_git_bundle()` and `apply_bundle()` in `sh/lib.sh`, including the Make targets that invoke them and the associated checksum marker.

## Current issue

The original issue register reports that `create_git_bundle()` creates `update.bundle`, while `apply_bundle()` expects `transport.bundle` and a related checksum marker. Confirm the current implementation before changing it; the repository may have evolved since this issue was recorded.

## Required work

- Inspect current creation, validation, and application behavior.
- Select one bundle filename and checksum convention.
- Apply the convention consistently to creation, validation, and application.
- Review the corresponding Make targets and documentation.
- Verify the complete transfer cycle using a disposable repository or copy before relying on it for project updates.

## Completion evidence

- Creation, validation, and application agree on the same documented convention.
- The full transfer cycle succeeds in a disposable test repository or copy.
- The test confirms expected Git content and metadata behavior.
