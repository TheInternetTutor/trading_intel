# Prevent Invalid Prices from Entering Inventory Calculations

**Status:** Open
**Priority:** As listed in the original Trading Intel issue register

## Purpose

Prevent unavailable or failed historical-price retrieval from being represented as a valid zero market price or propagated into inventory and valuation calculations.

## Scope

Review `py/ibkr_position_inventory.py` and its historical-price fallback behavior. This work item does not prescribe a particular replacement strategy before the existing behavior and downstream expectations are examined.

## Required work

- Review the historical-price retrieval and fallback paths.
- Identify where a zero price can be substituted after retrieval fails.
- Define explicit handling for unavailable prices so they remain distinguishable from valid market prices.
- Determine how unavailable prices should affect downstream inventory and valuation calculations.
- Add or identify tests covering missing, failed, and valid price retrieval.

## Completion evidence

- The handling of unavailable prices is explicit and does not silently treat failure as a valid zero price.
- Tests demonstrate the behavior for missing, failed, and valid price retrieval.
- Relevant downstream calculations are checked for unintended propagation.
