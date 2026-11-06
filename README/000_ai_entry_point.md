# README — AI Quick Reference

**Purpose:** Compact operational context for an AI joining or resuming work on the Trading Intel repository. This AI-oriented entry point is generated from `README/000_ai_entry_point.md` with `make grr`. The `README/` directory contains the detailed, human-readable project documentation; those modules are also authoritative working references for AI agents. Read the relevant documents there before performing substantive work.

## Roles and workflows

- **Architect:** generally the human who owns the repository and directs the work.
- **Engineer:** generally the AI or another human who inspects, implements, validates, and returns authorized changes.
- **Data Interchange Cycle (`-dic-`):** transfers or synchronizes repository state between Architect and Engineer.
- **Iterative Development Cycle (`-idc-`):** investigates and changes the code through repeatable runs and consecutive output snapshots.
- The cycles are complementary but independent. Do not make one a prerequisite of the other.

## Data Interchange Cycle (`-dic-`)

Choose the transfer method according to repository state:

- Use a **complete repository transfer** when the Engineer's workspace is new, unavailable, wiped, or untrustworthy. Include `.git/` when history must be preserved.
- Use **incremental Git bundles** for routine exchange when both repositories share compatible history.

For a new Engineer workspace:

1. Obtain and extract the repository or the agreed incoming bundle; work from the repository root.
2. Verify `git rev-parse --show-toplevel`, `git status --short`, and `git log -1`.
3. Run `make itd` to initialize temporary refresh-trigger dependencies before Make targets that rely on them.
4. Run `make ugu` to remove repository-local identity overrides before configuring the global identity; local values can otherwise override the global values.
5. Configure your own global Git identity in your development environment. Set `user.name` and `user.email` to the identity you use when contributing, whether you are a human developer or an AI operating independently. For example: `git config --global user.name "Your Name"` and `git config --global user.email "you@example.com"`. Use an identity that belongs to you; never attribute commits to another person or contributor.
6. Verify identity and configuration origin with `git config --show-origin --get user.name`, `git config --show-origin --get user.email`, `git var GIT_AUTHOR_IDENT`, and `git var GIT_COMMITTER_IDENT`. Confirm that the effective values identify you as the contributor, not another person.
7. Do not commit until the effective author and committer identities are correct.

For routine bundle exchange:

- Incoming bundle: inspect and protect local changes; verify with `git bundle verify update.bundle`; compare `sha256sum update.bundle` with `.update.bundle.sha256` when the marker exists; inspect the intended changes. `make ab` applies incoming additions, modifications, and rename destinations since the common Git ancestor; it preserves paths absent from the bundle and does not apply deletions. It aborts on staged changes or conflicting local modifications/untracked destination files. Obtain explicit authorization before running it.
- Outgoing bundle: ensure authorized work is validated and committed; confirm the configured base commit in `sh/lib.sh` exists and is an ancestor of `HEAD`; run `make cgb`; inspect `update.bundle` and its hash. Then inspect the destination and select the next available filename using the general collision rule: `update.bundle`, then `update(1).bundle`, `update(2).bundle`, and so on. Do not rely on automatic duplicate naming or timestamps. Upload additively to `/finances/030_trading_intel/`; never overwrite or delete existing bundles. The Engineer's `/mnt/data/` workspace is private and inaccessible to the Architect; a sandbox link is not delivery. Verify and report the exact Library path, size, and SHA-256 hash.
- A complete archive transfer must preserve `.git/` when history is required. After extraction, verify the repository root, `.git/HEAD`, expected latest commit, and working-tree state.

## Iterative Development Cycle (`-idc-`)

The cycle is iterative. There is no permanently fixed original snapshot: every new snapshot becomes the baseline for the next iteration. Always compare the two most recent snapshots.

### Initialize the local test path

1. Run `make itd` to initialize temporary refresh-trigger dependencies. This is not a general network-disable switch.
2. Run `make ite` to check whether test mode is active.
3. If `make ite` reports `false`, run `make td` once, then verify with `make ite` again. If it reports `true`, do not run `make td`: it is a toggle and would switch back to production mode.
4. Inspect the relevant tracked source sections with `make gcf | make ds` when useful.

### Generate viewer data and capture a snapshot

1. Run `make tp` to execute the test pipeline and prepare the data consumed by the viewer. It requires test mode and suppresses the pipeline's normal standard output; it does **not** generate the viewer report snapshot.
2. Invoke the viewer independently of Make rules and batch functions. The viewer consumes prepared JSONL data and checks whether its input file exists. A missing-input error is not a valid snapshot.
3. For this project, source `sh/view_lots.sh` and call `generate_lots_report`; redirect its standard output to the next snapshot. Default input example:

   `source sh/view_lots.sh >/dev/null && generate_lots_report > 010.diff`

   To use another JSONL input, pass its path when sourcing the script:

   `source sh/view_lots.sh /path/to/view_lots.jsonl >/dev/null && generate_lots_report > 010.diff`

4. Confirm successful viewer execution and inspect the captured output.

### Iterate: edit, capture, compare, analyze, and conclude

Repeat the following sequence after each controlled modification:

`edit -> inspect source -> make tp -> invoke viewer -> capture next snapshot -> compare previous vs. next`

Use three-digit snapshot numbers in increments of ten: `010.diff`, `020.diff`, `030.diff`, `040.diff`, and so on. Compare consecutive snapshots only. Example:

`diff -Bydaw --suppress-common-lines -W115 010.diff 020.diff`

Then compare `020.diff` with `030.diff`, then `030.diff` with `040.diff`, and continue. Do not overwrite earlier snapshots or create pair-named comparison files unless explicitly required.

During comparison and analysis, inspect actual differences; distinguish intended behavior changes from unexpected changes, missing records, ordering changes, formatting noise, and environmental effects. Keep inputs, filters, environment, viewer options, and formatting consistent where practical. If the result is inconclusive, improve diagnostics and capture another snapshot. If a change worsens behavior, preserve the evidence and restore or revise the source. The newest snapshot becomes the baseline for the next iteration.

## Safety and working rules

- Inspect the current repository state before acting; preserve unrelated changes.
- Read the current Makefile rules before running targets with acquisition, repository, or other side effects. A target's presence in help does not prove it is safe or validated in the current environment.
- Do not run production acquisition, apply an incoming bundle, commit, push, or overwrite persistent artifacts without the required authorization.
- Stage only files belonging to the authorized change. Do not add a remote or push unless explicitly authorized.
- Keep execution evidence, source changes, validation, commits, user acceptance, packaging, and persistent delivery distinct. Report only what was actually performed and verified.

## Project landmarks

- `makefile` — project entry point and Make orchestration.
- `mk/` — included Make rules.
- `sh/` — shell utilities, including `view_lots.sh` and shared functions.
- `jq/` — jq filters and utilities.
- `py/` — Python processing code.
- `data/` — inventory data and test fixtures.
- `work_items/open/` and `work_items/completed/` — work-item tracking.
- `README/` — detailed modular documentation for humans and AI agents; consult the relevant documents before substantive work.
- `.git/` — repository history and metadata; preserve when transferring the complete repository.

**Documentation source:** maintain the AI-oriented content in `README/000_ai_entry_point.md` and regenerate this root file with `make grr`. The numbered documents under `README/` contain the detailed explanations, procedures, and rationale; `README/010_overview.md` explains the documentation hierarchy.

**Path assumption:** current Makefile path logic expects the checkout directory to be named `trading_intel` directly under its workspace root. Verify the actual checkout location and configured data paths before running the pipeline or viewer.
