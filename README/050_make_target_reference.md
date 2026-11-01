# Make Target Reference

The exact available targets are printed by `make` (or `make h`). The current help and implementation include these aliases:

| Target | Purpose |
|---|---|
| `make itd` | Initialize temporary refresh-trigger dependencies. |
| `make h` | Display self-documenting help. |
| `make i` | Display project information. |
| `make dfm` | Regenerate/display the project file manifest; review changes before keeping them. |
| `make sgu` | Show Git author/committer identity and repository-local configuration. |
| `make ugu` | Remove repository-local Git `user.name` and `user.email` overrides. |
| `make ite` | Report whether the test-environment marker exists. |
| `make td` | Toggle between production and test data/environment. |
| `make fli` / `make fpi` | Fetch open-lot / live-position data; inspect side effects before use. |
| `make pli` / `make nli` | Process / normalize lot inventory. |
| `make tp` / `make plinu` | Run the test pipeline / process lots without updates, subject to prerequisites. |
| `make ab` | Apply the root-level `update.bundle`; repository-changing and authorization-gated. |
| `make cgb` | Create and verify an incremental `update.bundle`; may replace a same-named bundle in the repository root. |
| `make zr` | Create a complete repository ZIP according to the current Makefile implementation. |
| `make gcf` | Concatenate tracked Git files to standard output. |
| `make ds` | Display source sections delimited by `<disec>` and `</disec>` tags. |

Targets that fetch or process data can have dependencies and environmental assumptions. The presence of a target in help does not mean that it has been validated in the current environment. The Makefile is authoritative for actual behavior; inspect its current rules before relying on this summary.
