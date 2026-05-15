# Troubleshooting

## Active story is stale

Story was fetched days ago and may be outdated.

```
⚠️  Active story is stale (fetched 3 days ago)

Options:
  [1] Continue with current story
  [2] Fetch fresh story (recommended)
```

## Skills are taking too long

- Use thoroughness="quick" for faster context gathering
- Skip optional steps (e.g., ADR creation)
- Run individual skills to diagnose: `/github:story-fetch`, `/arch:gather-nfr`, `/scout:gather-context`

## Story already has status "In Progress"

Another developer may be working on the same story.

```
⚠️  Story #123 already has status 'In Progress'

Options:
  [1] Continue anyway (coordinate with team)
  [2] Fetch different story
  [3] Cancel
```

## Example Session

```
$ /play-story

→ Step 1/5: Pulling latest changes from master... ✓
→ No active story found

→ Step 2/5: Fetching next Ready story
  ✓ Found: #123 - Implement payment checkout (P0, M)
  ✓ GitHub status → In Progress

→ Step 3/5: Collecting non-functional requirements
  Q1: Daily active users? [1,000-10,000]
  Q2: Max response time? [<2s]
  ✓ NFRs saved

→ Step 4/5: Gathering technical context
  ✓ 2 docs, 3 code files, 2 existing ADRs found
  ✓ Context saved

→ Step 5/5: Creating ADR
  ✓ ADR-0012: stripe-payment-integration

[Final summary displayed — see output-format.md]

What would you like to do next?
  [1] Start implementation
  [2] Review ADR
  [3] View story in browser
  [4] Create feature branch
  [5] Nothing
```
