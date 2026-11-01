# Make Target Reference

The exact available targets are printed by `make`. The current help includes these aliases:

| Target | Purpose |
|---|---|
| `make itd` | Initialize refresh-period trigger files; run first in a new environment. |
| `make h` | Display self-documenting help. |
| `make i` | Display project information. |
| `make dfm` | Regenerate/display the project file manifest. Review changes before keeping them. |
| `make sgu` | Show Git identity/configuration information. |
| `make ugu` | Remove repository-local Git `user.name` and `user.email` overrides. |
| `make fli` / `make fpi` | Fetch open-lot / live-position data; inspect side effects before use. |
| `make pli` / `make nli` | Process / normalize lot inventory. |
| `make tp` / `make plinu` | Test pipeline / process lots without updates, subject to prerequisites. |
| `make ab` | Apply the root-level `update.bundle`; repository-changing and authorization-gated. |
| `make cgb` | Create and verify an incremental `update.bundle`; may replace a same-named bundle in the repository root. |
| `make zr` | Create a complete repository ZIP according to the current Makefile implementation. |

Targets that fetch or process data can have dependencies and environmental assumptions. The presence of a target in help does not mean it has been validated in the current environment. Inspect the current Makefile rules before relying on this reference; the Makefile is authoritative for actual behavior.
