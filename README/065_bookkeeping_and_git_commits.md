# Bookkeeping Changes and Git Commits

## Include bookkeeping with substantive work

When committing a substantive implementation or documentation change, include the associated work-item bookkeeping in the same commit. This includes related work-item renames, moves between `open/` and `completed/`, status changes, and updates to work-item indexes or other bookkeeping records.

The commit should capture the complete working state associated with that substantive change. Do not split the implementation or documentation work and its related bookkeeping across separate commits.

## Do not create bookkeeping-only commits

Do not create a separate commit solely to record routine bookkeeping. The Git commit for the substantive work already records the associated bookkeeping changes implicitly. Do not create an additional commit or documentation entry merely to narrate those routine changes.

Bookkeeping-only changes are not committed unless explicitly authorized. This does not mean excluding related bookkeeping from a substantive commit; when it accompanies substantive work, include it in that same coherent commit.

## Keep commits coherent

- Keep bookkeeping changes scoped to the substantive work they accompany.
- Use a commit message that describes the substantive implementation or documentation change, rather than routine file moves, renames, status changes, or index maintenance.
- Do not include unrelated working-tree changes merely to make a commit appear complete. Preserve unrelated changes for their own authorized work.
