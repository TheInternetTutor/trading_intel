# Make Target Reference

The exact available targets are printed by `make` (or `make h`). The following targets are documented from the current Makefile and included modules. The Makefile remains authoritative; inspect its prerequisites and recipes before relying on any target, especially when it can acquire data or change repository state.

| Target | Purpose |
|---|---|
| `make itd` | Initialize temporary refresh-trigger dependencies; run first in a new execution environment before dependent Make targets. |
| `make h` | Display self-documenting help. |
| `make i` | Display project information. |
| `make grr` | Generate the root AI-oriented `README.md` from `README/000_ai_entry_point.md`. |
| `make dfm` | Display the project file manifest. |
| `make dfmf` | Regenerate `files.manifest`; review the result before committing it. |
| `make sgu` | Show Git author/committer identity and repository-local configuration. |
| `make ugu` | Remove repository-local Git `user.name` and `user.email` overrides. |
| `make ite` | Report whether the test-environment marker exists. |
| `make td` | Toggle between production and test data/environment; it is not an idempotent setter. |
| `make fli` / `make fpi` | Fetch open-lot / live-position data; inspect side effects before use. |
| `make pli` / `make nli` | Process / normalize lot inventory. |
| `make tp` / `make plinu` | Run the test pipeline / process lots without updates, subject to prerequisites. |
| `make ab` | Apply incoming additions, modifications, and rename destinations from root-level `update.bundle`; preserves incoming deletions and is authorization-gated. |
| `make egb` / `make extract_git_bundle` | Extract the source tree from root-level `update.bundle` into `dir/` using a temporary Git repository; the Bash function also accepts an optional destination argument and leaves the receiving repository unchanged. |
| `make cgb` | Create and verify an incremental `update.bundle`; refuses to package uncommitted source changes and may replace a same-named bundle in the repository root. |
| `make zr` | Create `trading_intel.zip` from Git-tracked working-tree files plus `.git`; the current target replaces the prior project-root ZIP. This is the required post-commit workbench recovery checkpoint. Untracked and ignored files are excluded. |
| `make gcf` | Concatenate tracked Git files to standard output. |
| `make ds` | Display source sections delimited by `<disec>` and `</disec>` tags. |

Targets that fetch or process data can have dependencies and environmental assumptions. The presence of a target in help does not mean it has been validated in the current environment. The Makefile and Bash functions are authoritative for actual behavior; inspect their current definitions before relying on this summary.
