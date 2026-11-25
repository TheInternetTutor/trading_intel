# Simplify `view_lots.sh` with a jq-Driven Query Engine

## Status

Open — deferred. This work item is recorded for later implementation and is not the current priority.

## Origin and intent

Emilio proposed simplifying `view_lots.sh`, or potentially developing a new version of the script, because its current responsibilities and implementation have become candidates for consolidation.

The intended direction is to make **jq responsible for querying and transforming the lot data**, while keeping the shell viewer focused on presentation. The objective is not merely to shorten the script; it is to establish a clearer division of responsibility, reduce duplicated filtering and sorting logic, and make the data transformations easier to inspect, reuse, and validate.

## Current observations

The restored project currently contains:

- `sh/view_lots.sh`
- The four demonstration functions `vlr_demo_1` through `vlr_demo_4` in that script.
- `work_items/open/260918_1817_portfolio_decision_training_ground_data.psv`, the previously referenced example dataset.

The current script already uses jq for field selection and then passes data through AWK for rendering. Other operations still rely on combinations of Bash, `grep`, `sort`, and AWK. These include symbol/state/date filtering, ordering, and aggregation.

The four demos exercise different grouping or partitioning behaviors:

- `vlr_demo_1`: P&L ranges.
- `vlr_demo_2`: calendar-day age ranges.
- `vlr_demo_3`: approximate trading-day age ranges, using a 7/5 conversion.
- `vlr_demo_4`: week-based partitions aligned to weekdays.

The PSV example should be inspected when this work resumes to establish its exact columns, group boundaries, ordering, and output expectations. The current restored files must be treated as the source of truth; earlier observations that the PSV file was unavailable are obsolete.

## Proposed direction

Establish a data-processing layer in jq that can perform the applicable operations, such as:

- Selecting and filtering lots by symbol, classification/state, date, and other supported criteria.
- Sorting records using explicitly defined keys and ordering rules.
- Grouping and partitioning records, including the behaviors demonstrated by `vlr_demo_1` through `vlr_demo_4`.
- Calculating or aggregating values where those calculations properly belong in the query/transformation layer.
- Producing well-defined output datasets for downstream display or reuse, using an agreed representation such as JSON, JSONL, or PSV.

Keep `view_lots.sh` as a thin orchestration and presentation layer. It should request or invoke the required jq transformation and display the resulting dataset; it should not independently reimplement the filtering, grouping, or sorting rules.

A possible conceptual flow is:

`canonical lot data -> jq query/transform -> grouped or filtered dataset -> presentation viewer`

This is a direction to evaluate, not a finalized architecture. The precise input contract, output format, and boundary between jq, Bash, and AWK remain to be decided.

## Required work when resumed

1. Inspect the current `sh/view_lots.sh`, including all four `vlr_demo_*` functions and their callers.
2. Inspect the actual `260918_1817_portfolio_decision_training_ground_data.psv` and identify the structure and semantics of its records and groupings.
3. Trace the existing data source(s) used by the viewer and establish which is the canonical lot dataset for this workflow. Do not assume that a live-position JSONL file is interchangeable with the canonical lot data.
4. Inventory the current filtering, sorting, grouping, partitioning, and aggregation operations, identifying which are implemented in jq, Bash, AWK, `grep`, or `sort`.
5. Compare the existing behavior with the intended results represented by the four demos and the PSV example.
6. Agree on the data contracts and responsibility boundaries before implementation.
7. Design a jq-driven query/transformation layer and a presentation-focused viewer. Prefer reusable, composable jq functions and deterministic output over duplicated shell pipelines.
8. Preserve useful existing viewer behavior unless a deliberate replacement is agreed upon. Define compatibility expectations before changing report output.
9. Validate the new behavior against representative existing data and the demo cases. Retain inspectable intermediate results where useful for debugging and comparison.

## Clarification questions for the implementation session

These questions are intentionally deferred. The first reflects the question already raised in the original discussion; the remaining questions are proposed follow-ups to complete the requirements before implementation.

1. **Source data and example semantics:** Provide/confirm the actual `260918_1817_portfolio_decision_training_ground_data.psv` as the reference example. What are its precise columns, group boundaries, ordering rules, and intended meaning? The file is now present in the restored repository and should be inspected directly when this work resumes.
2. **Output and compatibility:** Should the redesigned viewer preserve the current terminal report's layout and behavior, or may its output be redesigned? Which existing reports, aliases, filters, and sort orders must remain compatible?
3. **Responsibility boundaries:** Should jq own all record selection, filtering, sorting, grouping, partitioning, and aggregation, with Bash limited to orchestration and AWK limited to final formatting/rendering? Identify any operations that should remain outside jq and why.
4. **Interface and execution model:** How should the jq engine and viewer communicate—stdin/stdout pipelines, named intermediate JSON/JSONL/PSV artifacts, or a combination? Should users invoke the viewer through its existing aliases/functions, or should the redesign introduce a clearer query interface? Define how intermediate outputs and demo cases should be run and inspected.

## Constraints and change control

- This work item is a record of planned work only. No implementation is authorized by creating it.
- Do not generate or modify code until the requirements have been discussed and Emilio explicitly authorizes implementation.
- Do not assume that jq must replace every use of AWK or Bash; establish the responsibility boundary based on the actual data and presentation requirements.
- Do not discard existing demos or report behavior before understanding and validating what they represent.
- Do not conflate static lot inventory data with live position snapshots; establish the correct canonical input for this workflow.
- Keep this item open until the design questions are answered, an implementation approach is agreed upon, and the resulting behavior is validated.

## Expected outcome

A simpler, more maintainable lot viewer in which data querying and transformation rules are centralized and deterministic, while the shell-facing viewer is primarily responsible for presenting the prepared results. The four demos and the PSV example provide concrete behavioral references for evaluating the design.
