
# PROJECT: Adjacent-Day Lots Reconciliation Engine

## PURPOSE

I want to create a deterministic command-line tool that compares two adjacent-day JSONL snapshots of my IBKR lots data and calculates what changed between the two snapshots.

The purpose is to replace manual comparison of the human-readable IBKR Lots Reports.

The human-readable reports are generated from the JSONL data. The JSONL files are therefore the authoritative machine-readable input and should be used directly by the reconciliation tool.

The basic concept is:

    Lots_JSONL_A + Lots_JSONL_B
                |
                v
       Snapshot Reconciliation
                |
                v
       Changes / P&L / Events
                |
                v
          Report / JSON output

Where:

- A = previous reconciled snapshot
- B = subsequent reconciled snapshot

The reports are generated after IBKR's overnight reconciliation, so adjacent snapshots should represent stable account states before the next trading session.

---

# OBJECTIVE

Determine, as accurately and deterministically as possible, what happened between snapshot A and snapshot B.

The engine should distinguish between changes caused by:

1. New purchases / new lots
2. Sales / removed lots
3. Partial lot changes
4. Quantity changes
5. Cost-basis changes
6. Realized gains
7. Realized losses
8. Net realized P&L
9. Changes in unrealized P&L
10. Market-price effects
11. Changes in total portfolio P&L
12. Other identifiable lot-state transitions
13. Reconciliation anomalies or unexplained differences

The ultimate goal is to make the result useful both for human analysis and for future quantitative/portfolio analysis.

---

# IMPORTANT ARCHITECTURAL PRINCIPLE

Do NOT parse the human-readable IBKR report unless we later determine that a particular field exists only there.

The JSONL files are the primary source.

The human-readable report is only a presentation of the underlying data.

The new project should therefore first inspect and understand the actual JSONL schema before any implementation decisions are made.

---

# EXISTING LOT-ENGINE CONTEXT

This project is related to my existing LIFO trading-lots system.

Relevant terminology and assumptions already established:

- Lots are tracked per symbol.
- The system is bi-directional LIFO.
- BUY opens long inventory.
- SELL closes the most-recent long lot first.
- If a SELL exceeds available long inventory, the excess opens short inventory.
- A subsequent BUY can close short inventory using LIFO.
- Trade quantity is signed:
  - BUY = positive
  - SELL = negative
- Trades are processed chronologically by `date_time`, not `trade_date`.

Previously established transaction fields include:

- `symbol`
- `date_time`
- `trade_date`
- `buy_sell`
- `quantity`
- `trade_price`
- `trade_id`
- `fifo_pnl_realized`

Previously established lot concepts include:

- `lot_id`
- `symbol`
- `open_datetime`
- `entry_price`
- `original_quantity`
- `remaining_quantity`
- `direction`
- `holding_days`

Do NOT assume that the new JSONL files contain exactly these fields. Inspect the actual files first and determine what is actually available.

---

# EXPECTED OPERATING MODEL

The eventual command should conceptually allow something like:

    reconciliation_tool snapshot_A.jsonl snapshot_B.jsonl

The exact command name, options, output formats, and architecture are to be determined during requirements analysis.

The tool should preferably be deterministic and suitable for integration into my existing report-generation workflow.

I generally prefer backend processing and machine-readable output.

SQLite is preferred when it materially improves maintainability, querying, debugging, reconciliation, or integration with the existing lots/metrics system.

Do not automatically choose AWK merely because the source is JSONL. Determine the most appropriate implementation after understanding the data and requirements.

---

# CRITICAL ACCOUNTING QUESTION

Do not assume:

    P&L_B - P&L_A = realized P&L

because changes in total P&L can contain multiple components.

The engine should attempt to separate:

    realized P&L
    unrealized P&L change
    market-price effect
    inventory/position changes
    other identifiable effects

The methodology must be derived from the actual JSONL fields and the semantics of those fields.

If an exact decomposition is mathematically impossible from the available data, explicitly identify the limitation rather than inventing a calculation.

---

# DESIRED OUTPUT

The final tool should ideally be capable of producing information such as:

## Snapshot Summary

- Snapshot A date/time
- Snapshot B date/time
- Elapsed interval
- Symbols affected
- Lots affected
- Total inventory change

## Trading Activity

- New lots
- Removed lots
- Increased lots
- Reduced lots
- Closed lots
- Partially closed lots
- New symbols
- Removed symbols

## Realized P&L

- Gross realized gains
- Gross realized losses
- Net realized P&L
- Realized P&L by symbol
- Realized P&L by lot where possible

## Unrealized P&L

- Unrealized P&L at A
- Unrealized P&L at B
- Change in unrealized P&L
- Unrealized change by symbol
- Unrealized change by lot where possible

## Reconciliation

- Total P&L change
- Explained P&L change
- Unexplained residual
- Reconciliation status

## Useful Diagnostics

- Lots appearing unexpectedly
- Lots disappearing unexpectedly
- Quantity mismatches
- Price mismatches
- Duplicate identifiers
- Missing identifiers
- Ambiguous lot matches
- Other anomalies

This list is provisional. Improve it if analysis of the actual data reveals better or more useful measures.

---

# VERY IMPORTANT: DO NOT CODE YET

Before generating any code, perform requirements analysis.

I want the coding process to follow this sequence:

1. Inspect the available JSONL structure.
2. Identify the fields and their semantics.
3. Establish how snapshots can be matched.
4. Determine how lots can be uniquely identified across snapshots.
5. Determine how purchases, sales, partial closures, and other transitions can be detected.
6. Determine exactly which P&L quantities can be calculated from the data.
7. Identify any quantities that cannot be calculated reliably.
8. Establish the desired output.
9. Establish the implementation architecture.
10. Only after all requirements are settled, ask for permission to generate code.

Do not generate implementation code prematurely.

---

# QUESTIONS

Ask me the following questions sequentially, one at a time.

After I answer each question, ask whether I want to proceed to the next question.

Do not ask all questions simultaneously during the interactive requirements phase.

## Question 1

Please provide the actual JSONL file(s) that generate the IBKR Lots Report, or identify the existing file/schema if already available.

We need to inspect the real structure before deciding how the reconciliation engine should work.

## Question 2

What exactly constitutes a "snapshot"?

Is each JSONL file a complete account-wide snapshot of all currently known lots, or does it contain only a subset of the account?

## Question 3

What field or combination of fields uniquely identifies a lot across two adjacent snapshots?

If no explicit persistent lot identifier exists, determine whether one can be constructed reliably.

## Question 4

How are closed lots represented?

Specifically, does the JSONL retain historical closed lots, or does a lot disappear once completely closed?

This is critical for distinguishing sales from other changes.

## Question 5

What price/P&L fields are present in each JSONL record?

Determine whether the snapshot contains enough information to calculate unrealized P&L independently, or whether unrealized P&L must be derived from other fields.

## Question 6

How should realized P&L be treated?

Determine whether the JSONL contains an authoritative realized-P&L field, whether realized P&L must be reconstructed from lot entry/exit information, or whether both approaches are possible and should be cross-validated.

## Question 7

What should happen when a lot cannot be matched between A and B?

Possible categories include:

- definitely new
- definitely removed
- partially changed
- ambiguous
- data error

Establish the desired behavior.

## Question 8

How should partial lot changes be represented?

For example:

    100 shares -> 60 shares

Should this be reported as:

    40 shares closed

while retaining the surviving 60-share lot as the same lot?

## Question 9

Should the engine calculate results by:

- account
- symbol
- lot
- all three

I expect all three to be useful, but establish the requirement explicitly.

## Question 10

What output formats should the tool produce?

At minimum consider:

- human-readable CLI report
- JSON
- JSONL
- CSV
- SQLite

Determine which are actually useful rather than generating unnecessary formats.

## Question 11

Should the tool maintain a persistent reconciliation database, or should each invocation simply compare two files and produce an independent result?

Consider that this tool may eventually become part of my existing report-generation pipeline.

## Question 12

How should commissions and other transaction costs be handled?

Determine whether they are present in the JSONL and whether realized P&L should be reported gross, net, or both.

## Question 13

How should corporate actions or other non-trading lot changes be handled?

For example:

- splits
- mergers
- symbol changes
- transfers
- adjustments
- other IBKR inventory changes

These should not automatically be interpreted as ordinary BUY/SELL activity.

## Question 14

What level of reconciliation tolerance should be allowed for floating-point differences?

The engine should distinguish harmless numerical differences from genuine accounting discrepancies.

## Question 15

What should the final report emphasize?

The primary purpose is to understand:

    "What changed between yesterday's reconciled account state and today's reconciled account state?"

Determine which metrics should be considered essential versus diagnostic.

---

# DESIGN PRINCIPLES

The resulting implementation should favor:

- deterministic behavior
- transparent calculations
- reproducibility
- inspectable intermediate results
- explicit assumptions
- minimal hidden logic
- useful diagnostics
- machine-readable output
- integration with existing financial tooling

Do not silently "fix" inconsistent data.

If the source data cannot support a conclusion, report that limitation explicitly.

The objective is not merely to produce numbers.

The objective is to produce a **reliable reconciliation of two adjacent financial states**.
