# Environment Setup

## Restore the complete repository

Work from the repository root—the directory containing `makefile`, `mk/`, `sh/`, `jq/`, `py/`, `data/`, and `.git/`. Preserve `.git/` when transferring the complete repository so its history and configuration remain available.

## Initialize refresh triggers

After extracting or restoring the repository in a new environment, the first Make rule to execute is:

`make itd`

This initializes the refresh-period (CRP) trigger file(s) in the temporary directory. Run it before any other Make target that may depend on refresh triggers. In the configuration documented by the original README, the trigger was `/tmp/crp_260706065936.tmp`; temporary files may need to be initialized again when the environment is recreated.

## Inspect commands and repository state

- Run `make` (or `make h`) to print the self-documenting target list.
- Run `make i` for project information.
- Review `git status --short`, `git log -1`, the relevant Makefile fragments, and the open work items before selecting a workflow.

Do not assume that every listed target is safe for every environment. Inspect the prerequisites and side effects of acquisition, processing, debug-toggle, and bundle targets before running them.
