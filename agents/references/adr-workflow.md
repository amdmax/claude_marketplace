# ADR Workflow

## When to Create an ADR

Create an ADR if the story introduces any of:
- A new AWS service not currently in the stack
- A new architectural pattern or significant deviation from existing patterns
- A security-relevant change (new auth mechanism, data exposure surface)

## How to Create

1. Run `/arch:create-adr`
2. Document: the decision being made, alternatives considered, and rationale
3. ADR is written to `docs/adr/` automatically

## When NOT to Create

- Routine feature work that follows established patterns
- Changes that clearly trace to existing ADRs
- Minor configuration tweaks
