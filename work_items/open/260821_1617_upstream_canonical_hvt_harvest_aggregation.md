# Upstream Canonical HVT Harvest Aggregation

## Purpose

Enhance the canonical Lots Inventory (LI) pipeline so that harvestable lots can be aggregated by symbol.

The purpose of the aggregation is to convert multiple individual HVT lots under the same symbol into a compact, actionable harvesting record that allows the trader to quickly determine:

- how many shares can be harvested;
- how many individual lots are involved;
- the conservative minimum price at which all included lots remain profitable;
- the total gross unrealized P&L available for harvesting;
- the temporarily commission-adjusted harvestable amount;
- and which symbols currently represent the largest harvesting opportunities.

The individual lot records must remain unchanged and available in the canonical LI.

The aggregation adds derived records; it does not replace or modify the underlying lots.

---

## Scope

This enhancement applies only to lots classified as:

`10.HVT`

All HVT lots belonging to the same symbol are treated as one harvestable group for aggregation purposes.

Non-HVT lots must not participate in the aggregate.

---

## Aggregation Rules

For each symbol:

1. Select all individual lots whose lock/classification state is `10.HVT`.

2. Group those lots by `symbol`.

3. Calculate the total harvestable quantity:

   `aggregate_quantity = sum(quantity)`

   This represents the total number of shares that can be harvested from the included HVT lots.

4. Calculate the number of individual lots:

   `lot_count = count(included HVT lots)`

5. Calculate the gross harvestable P&L:

   `gross_harvest_pnl = sum(fifo_pnl_unrealized)`

6. Determine the conservative harvest price using the highest cost basis among the included lots:

   `harvest_price = max(cost_basis_price)`

   The harvest price must **not** be calculated as an average.

   Using the highest cost basis ensures that, if the aggregate quantity is sold at or above the aggregate harvest price, every included lot is at or above its individual cost basis.

7. Apply the current temporary commission allowance:

   `commission_allowance = 1.12`

   The value represents the current average commission estimate derived from approximately four years of trading activity.

   For the current implementation, this amount is deducted **once per aggregated symbol**, not once per lot.

8. Calculate the temporary net harvestable P&L:

   `net_harvest_pnl = gross_harvest_pnl - commission_allowance`

---

## Commission Rule — Current Temporary Model

The `$1.12` commission allowance is a temporary conservative estimate.

The system must not assume that this is the final commission-accounting model.

A separate commission-accounting investigation remains pending to determine:

- whether IBKR already incorporates commissions into cost basis;
- whether commissions are already reflected in `fifo_pnl_unrealized`;
- whether explicit commission data exists in the raw Flex Query;
- whether commission data should be preserved in the canonical LI;
- and whether the current temporary deduction could eventually result in double-counting.

Until that investigation is completed, the HVT aggregation uses:

`commission_allowance = 1.12`

once per aggregated symbol.

---

## Required Aggregate Information

Each HVT aggregate must contain sufficient information to support both machine processing and human reporting.

At minimum, the aggregate must represent:

- aggregate record identity/type;
- symbol;
- HVT lot count;
- aggregate quantity;
- conservative harvest price;
- gross harvestable P&L;
- commission allowance;
- net harvestable P&L.

Field names should follow the naming conventions already established by the canonical LI pipeline.

The aggregate should remain clearly distinguishable from an individual lot record.

---

## Example

Given these HVT lots:

`PLTR | quantity: 2 | cost_basis_price: 169.510 | fifo_pnl_unrealized: 19.430`

`PLTR | quantity: 3 | cost_basis_price: 171.133 | fifo_pnl_unrealized: 24.275`

The aggregate becomes conceptually:

- symbol: `PLTR`
- lot_count: `2`
- aggregate_quantity: `5`
- harvest_price: `171.133`
- gross_harvest_pnl: `43.705`
- commission_allowance: `1.120`
- net_harvest_pnl: `42.585`

The important rule is:

`harvest_price = max(169.510, 171.133) = 171.133`

Therefore, selling all five shares at or above `171.133` conservatively ensures that all aggregated HVT lots are at or above their individual cost basis.

---

## Report Behavior

The individual HVT lots may continue to be displayed when detailed lot inspection is useful.

However, the HVT aggregate records must allow the report to present harvesting opportunities without requiring the trader to manually combine adjacent lots.

The primary ordering for aggregated HVT opportunities should be:

`net_harvest_pnl descending`

This allows the trader to immediately see the largest available harvesting opportunities first.

The objective is to prioritize:

> the amount of money that can currently be harvested,

rather than simply presenting opportunities alphabetically by symbol.

---

## Architectural Rule

The aggregation belongs upstream in the canonical LI processing pipeline.

The report should consume the resulting aggregate information rather than independently reconstructing the aggregation logic.

This ensures that:

- the aggregate is available to all downstream consumers;
- the calculation exists in one authoritative location;
- report logic remains presentation-oriented;
- future analytics and snapshot reconciliation can reuse the same aggregate data;
- and the meaning of an HVT aggregate remains consistent throughout the system.

---

## Future Extensions

The initial implementation should remain focused on the current harvesting workflow.

Future work may extend the aggregate with additional information, including:

- fully reconciled commission accounting;
- more exact net proceeds;
- additional harvesting thresholds;
- realized harvesting history;
- adjacent-snapshot comparison;
- capital released through harvesting;
- and higher-level analysis of harvesting behavior.

Those extensions must not complicate or delay the current implementation.
