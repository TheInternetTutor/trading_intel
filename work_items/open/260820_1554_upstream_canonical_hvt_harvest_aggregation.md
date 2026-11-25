
# Upstream Canonical HVT Harvest Aggregation

## Objective

Modify the **upstream lot-data processing pipeline** so that the canonical `view_lots.jsonl` dataset contains additional aggregate records representing **harvestable lots grouped by symbol**.

The purpose is to move this business/analytical calculation upstream so that downstream consumers such as `view_lots.sh` and the future `view_lots.html` do not need to reconstruct it independently.

The Makefile is an **orchestrator only**. Do not place calculations or business logic directly in the Makefile. Use the existing processing architecture and the appropriate Python/jq/AWK component or new processing stage.

---

## Existing architecture

The current pipeline progressively transforms the source data into the canonical `view_lots.jsonl` dataset.

The resulting JSONL is intentionally **rich and heterogeneous**.

Individual records may have different `record_type` values and therefore different schemas. Existing records include, among others:

* `lot`
* `summary`

Additional record types may be introduced when they represent useful canonical information.

Do **not** remove or replace the existing individual lot or summary records.

The new aggregate information should be added to the canonical dataset.

---

## HVT aggregation rule

Identify records representing **HVT lots**:

`lock_state == "10.HVT"`

Group those records by:

`symbol`

For each symbol, aggregate the HVT lots belonging to that symbol.

The aggregation must retain at least:

* `symbol`
* number of HVT lots being aggregated
* aggregate quantity
* aggregate gross unrealized P&L

The exact field names should follow the existing project conventions.

---

## Commission allowance

The harvesting calculation must account for transaction commissions.

Use a configurable parameter:

`commission_per_transaction`

This represents a conservative **average commission for one transaction**, not a round-trip commission.

For an aggregate containing `N` lots:

`commission_allowance = commission_per_transaction × (N + 1)`

The `N` represents the individual historical lot transactions being represented.

The additional `+1` represents the single transaction required to sell the aggregated position.

### Important

Do **not** multiply the commission allowance by quantity.

Quantity is irrelevant to this particular approximation because the model uses an empirical average commission per transaction.

The number of lots is what determines the historical transaction count.

---

## Net harvest value

For each symbol:

`gross_harvest_pnl = sum of fifo_pnl_unrealized for the included HVT lots`

`commission_allowance = commission_per_transaction × (lot_count + 1)`

`net_harvest_pnl = gross_harvest_pnl − commission_allowance`

The aggregate record should expose the relevant values so that downstream consumers do not have to reproduce this calculation.

At minimum, I would like the aggregate record to make the following available:

* `lot_count`
* `quantity`
* `gross_pnl`
* `commission_allowance`
* `net_pnl`

Use the project's established naming conventions rather than blindly adopting these exact names.

---

## Important semantic requirement

The commission calculation is based on the **number of lots**, not the quantity of shares.

For example, if a symbol contains four HVT lots:

* Lot 1: 1 share
* Lot 2: 10 shares
* Lot 3: 100 shares
* Lot 4: 5 shares

the commission allowance is still:

`4 + 1 = 5 transactions`

therefore:

`5 × commission_per_transaction`

not:

`116 × commission_per_transaction`.

---

## Do not alter the underlying lots

The original HVT lot records must remain intact.

The new aggregation is **additional information**, not a replacement.

This allows consumers to choose between:

* individual HVT lots;
* HVT aggregated by symbol;
* future aggregate/reporting representations.

---

## Record type

Introduce an appropriate heterogeneous JSONL record type for the aggregate information.

For example, conceptually:

`record_type = "aggregate"`

with an appropriate discriminator such as:

`aggregate_type = "hvt_symbol"`

Do not assume these exact names if the existing schema conventions suggest better names.

The important requirement is that the record clearly identifies:

1. that it is an aggregate;
2. that it represents HVT;
3. that it is aggregated by symbol.

---

## Parameterization

Do not hard-code the commission assumption into business logic if the existing architecture provides a configuration mechanism.

The commission allowance must be configurable.

For example:

`commission_per_transaction = 1.20`

may be used initially, but the implementation must allow the value to be changed without rewriting the aggregation algorithm.

The current value is intended to be a **conservative estimate**, not a claim that every actual transaction costs exactly that amount.

---

## Placement in the pipeline

Place this processing stage **after HVT classification is available** and after all information required to calculate the HVT P&L is available.

Do not modify earlier stages unnecessarily.

Do not move the calculation into `view_lots.sh`.

The desired architecture is:

`raw source`

→ normalization

→ canonicalization

→ market-price processing

→ consolidation

→ lot classification

→ HVT harvest aggregation

→ canonical `view_lots.jsonl`

Then:

`view_lots.jsonl`

→ terminal viewer

and eventually:

`view_lots.jsonl`

→ HTML viewer.

---

## Preserve the existing architecture

The Makefile remains responsible for:

* orchestration;
* dependency ordering;
* resolving resources;
* passing resources/parameters to processing components.

The Makefile should **not perform the aggregation calculation itself**.

Use the existing processing conventions and modular stages.

Avoid introducing unnecessary new architecture if an existing processing mechanism can naturally perform the operation.

---

## Validation

Before modifying anything, inspect the existing pipeline and determine:

1. where HVT classification becomes authoritative;
2. where `fifo_pnl_unrealized` is authoritative;
3. where the new aggregation stage belongs;
4. how configuration parameters are currently passed through the Makefile;
5. how intermediate JSONL stages are currently represented.

Then implement the smallest coherent addition consistent with the existing architecture.

Validate that:

* existing `lot` records are unchanged;
* existing `summary` records are unchanged;
* the new aggregate records are generated correctly;
* grouping is by symbol;
* `lot_count` is correct;
* quantity aggregation is correct;
* gross P&L is correct;
* commission allowance is `(lot_count + 1) × commission_per_transaction`;
* net P&L is correct;
* multiple symbols are handled independently;
* symbols with only one HVT lot work correctly;
* symbols with multiple HVT lots work correctly.

Do not modify the terminal presentation yet.

---

### One final architectural principle

The goal is **not** to make the canonical JSONL minimal.

The goal is to make it **rich, deterministic, self-contained, and reusable**.

Storage and computation are inexpensive in this application. Prefer adding useful canonical information upstream rather than forcing every downstream consumer to reconstruct the same information independently.

The renderer should eventually be intentionally boring:

> **select → arrange → render**

The business logic belongs upstream.
