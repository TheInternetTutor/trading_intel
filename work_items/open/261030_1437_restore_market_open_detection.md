# Restore and Verify Market-Open Detection

## Purpose

Restore or replace market-open detection so that it reflects the intended market-hours and timezone behavior rather than always reporting the market as closed.

## Scope

Review `is_market_open()` in `py/ibkr_position_inventory.py`. The current issue description reports that the function immediately returns `False`, leaving the intended market-time logic unreachable.

## Required work

- Inspect the current function and the unreachable logic.
- Determine the intended market-hours and timezone behavior.
- Restore or replace the detection logic without assuming undocumented behavior.
- Test market-open and market-closed cases.
- Include boundary-time cases and behavior when live data is unavailable.

## Completion evidence

- The implemented behavior follows the determined market-hours and timezone rules.
- Tests cover open, closed, boundary, and unavailable-live-data cases.
