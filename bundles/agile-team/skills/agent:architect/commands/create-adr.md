# Command: create-adr

Focused ADR creation. Delegates to the `/arch:create-adr` skill with story context pre-loaded.

## Workflow

1. Read `WORKSPACE_DIR/active-story.yaml` if it exists — extract story title and context to inform the ADR
2. Read existing ADRs in `WORKSPACE_DIR/adr/` to determine the next sequence number and check for precedents
3. Run `/arch:create-adr` with the remaining ARGUMENTS (after stripping `create-adr`) as the decision context/title
4. Ensure the ADR is written to `WORKSPACE_DIR/adr/`
5. Report the ADR file path and title to the user

## File Boundary

Write only to `WORKSPACE_DIR/adr/*.md`.
