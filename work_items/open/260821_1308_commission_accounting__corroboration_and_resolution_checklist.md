
# Commission Accounting — Corroboration and Resolution Checklist

1. Inspect the header and records of `ibkr_lot_inventory.csv` to determine whether the IBKR Flex Query already returns any explicit commission, fee, or transaction-cost fields relevant to individual open lots.

2. Trace the raw `ibkr_lot_inventory.csv` fields through the complete normalization and Make pipeline to determine:
   - which raw cost-basis fields are used,
   - how `cost_basis_price` is created,
   - whether any commission-related information is preserved,
   - whether any commission-related information is discarded.

3. Verify the exact accounting semantics of IBKR's `cost_basis_price` for the specific Flex Query and accounting method being used:
   - determine whether opening commissions are already incorporated into the reported cost basis,
   - determine whether other transaction costs are incorporated,
   - distinguish IBKR's documented general behavior from the actual behavior of our downloaded data.

4. Verify how `fifo_pnl_unrealized` is obtained and maintained throughout the pipeline:
   - identify its original source in the IBKR data,
   - identify where it is recalculated,
   - determine whether its calculation is implicitly commission-inclusive through `cost_basis_price`.

5. Confirm whether the existing Lots Inventory (LI) already contains sufficient information to determine the commission associated with each individual lot, either:
   - explicitly through a commission field, or
   - implicitly through IBKR's cost-basis accounting.

6. Confirm that the Aggregated Live Inventory (ALI) does not provide commission information useful for lot-level accounting, and document any limitations caused by its aggregated, current-session nature.

7. Compare the commission semantics of LI and ALI to determine whether current-session purchases or sales introduce commission information that is missing from the reconciled lot snapshot.

8. Determine whether the current HVT aggregation formula:

   `commission_allowance = commission_per_transaction × (lot_count + 1)`

   would double-count historical opening commissions already embedded in `cost_basis_price` or `fifo_pnl_unrealized`.

9. If opening commissions are already included in the lot economics, redesign the HVT commission adjustment so that only costs not already represented in the lot P&L are deducted, potentially including only the estimated future closing transaction.

10. If per-lot commission data is available but not currently preserved, decide where it should enter the canonical pipeline and whether it should become a permanent field in the LI JSONL records.

11. If neither explicit commission data nor commission-inclusive cost basis is sufficient, modify the IBKR Flex Query to request the necessary commission or transaction-cost field, provided IBKR supports it for the relevant report.

12. After the above is resolved, define one canonical commission-accounting rule for the pipeline and ensure that:
    - individual lot P&L,
    - HVT aggregation,
    - symbol-level summaries,
    - and future adjacent-snapshot reconciliation

    all use the same rule without double-counting or silently mixing gross and net P&L.

13. Document the final conclusion explicitly:
    - what IBKR already includes,
    - what the pipeline calculates,
    - what the pipeline estimates,
    - and which commissions remain external or unavailable.

14. Add validation cases using known lots and transactions where the expected commission treatment can be independently corroborated against IBKR reporting.
