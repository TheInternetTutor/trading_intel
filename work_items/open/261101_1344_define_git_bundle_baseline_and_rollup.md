# Define Git Bundle Baseline and Roll-Up Procedure

## Purpose

Document and eventually implement a reliable procedure for maintaining the shared Git commit used as the base of incremental bundles exchanged between the user's repository and the assistant's workbench repository.

## Background

The current bundle workflow intentionally uses a hardcoded Git commit as the common baseline between the two repositories. The current baseline is:

`056b2aa4d60d5be5be9c5d40bc3e8da0eab83f79`

This is a deliberate design choice, not an accidental hardcoded value. Bundles are generated relative to this shared commit. The approach is sufficient while the resulting bundles remain small; the latest exchanged bundle was under 20 KB.

The agreed plan is to retain this fixed baseline for now. When bundle size or accumulated history makes it worthwhile, the baseline will be advanced to a newer commit that is known to exist in both repositories. This periodically rolls up the exchange history and keeps subsequent bundles manageable.

The existing `.update.bundle.sha256` file records the checksum of the most recently applied bundle. It identifies the applied bundle, but it does not independently establish or update the shared Git baseline.

## Scope

When this item is addressed, review the Git bundle producer and consumer in `sh/lib.sh`, their Make targets, and the metadata used to track bundle application and the shared baseline.

## Required Work

- Preserve the current fixed-baseline approach until there is a practical reason to roll it forward.
- Define how both repositories confirm that a candidate baseline commit is common and available before adopting it.
- Define an explicit roll-up procedure that advances the baseline to the selected common commit.
- Decide whether the shared baseline should be stored separately from `.update.bundle.sha256`, and define its format and update rules.
- Ensure bundle creation uses the agreed baseline and bundle application does not silently change it.
- Document the operational sequence for integrating each side's changes, committing the agreed state, generating the next bundle, applying it, and confirming the resulting shared baseline.
- Review relevant Make targets and scripts only to the extent needed to support that workflow.
- Test normal incremental exchanges and a baseline roll-up using disposable repository copies before changing the active workflow.

## Completion Evidence

- The shared-baseline concept is clearly distinguished from the last-applied-bundle checksum.
- Both repositories can independently verify the selected baseline commit.
- The roll-up procedure is documented and successfully tested.
- Existing incremental bundle exchanges continue to work without losing either side's changes.
- The fixed baseline is not advanced until both repositories have the selected replacement commit.
