# design-story — Story-Level Architectural Design

## Purpose

Produce three artefacts for the active story:

1. **C4 container diagram** — when the story is infrastructure-significant
2. **ADR with rationale** — formal architecture decision record
3. **Implementation brief** — written to `WORKSPACE_DIR/active-story.json`

---

## Infrastructure Detection

A story is **infrastructure-significant** if any of the following are true:

**Keywords in ACs or story description:**
`deploy`, `database`, `schema`, `migration`, `API`, `endpoint`, `service`, `queue`,
`lambda`, `S3`, `RDS`, `cache`, `auth`, `gateway`, `integration`, `container`,
`CDK`, `CloudFormation`, `terraform`

**Infra files present in the repo:**
`cdk.json`, `*.tf`, `docker-compose*.yml`, `CloudFormation/`, `infrastructure/`

---

## Workflow

### Step 1: Load Story Context

1. Read `WORKSPACE_DIR/active-story.json` — story title, ACs, NFRs, storyId
2. Read `WORKSPACE_DIR/architecture-overview.md` if it exists (existing container inventory)

### Step 2: Gather Code Context

1. Run `/gather-context` to find related code, patterns, existing implementations
2. Review existing ADRs in `WORKSPACE_DIR/adr/` for precedents and current numbering

### Step 3: Infrastructure Detection

Evaluate ACs and story description against the detection criteria above.

- If **infrastructure-significant** → proceed to Step 4, then Step 5
- If **not infrastructure-significant** → skip Step 4, proceed to Step 5

### Step 4: C4 Container Diagram (infra-significant stories only)

Generate a Mermaid `C4Container` diagram showing:
- Existing containers affected by the story (highlight with `Boundary`)
- New containers introduced (if any)
- Communication paths changed or added
- External systems touched

**Diagram conventions:**
- Use Mermaid `C4Container` syntax (not flowchart)
- Label each container with: name, technology, and one-line description
- Show only containers relevant to the story scope — no full system maps

**Write to:** `WORKSPACE_DIR/diagrams/story-{storyId}-c4.md`

File structure:

```markdown
## C4 Container Diagram — {Story Title}

> Scope: containers created or modified by this story.

\`\`\`mermaid
C4Container
  title {Story Title}

  Person(user, "User", "Description")

  System_Boundary(sys, "System Name") {
    Container(api, "API Service", "Node.js / Express", "Handles requests")
    ContainerDb(db, "Database", "PostgreSQL", "Stores records")
  }

  System_Ext(ext, "External Service", "Third-party dependency")

  Rel(user, api, "Uses", "HTTPS")
  Rel(api, db, "Reads/writes", "SQL")
  Rel(api, ext, "Calls", "REST")
\`\`\`

**Legend:** Highlighted containers are new or modified by this story.
```

Ensure `WORKSPACE_DIR/diagrams/` exists before writing.

### Step 5: ADR with Rationale

Run `/arch:create-adr` with context from the story and (if generated) the C4 diagram.

The ADR **must** include a **Rationale** section (after Decision Outcome) that answers:
- Why this approach over the next-best alternative
- What constraints ruled out other options
- What trade-offs the team is accepting

Write to `WORKSPACE_DIR/adr/`.

### Step 6: Implementation Brief

For each AC and applicable NFR, determine:
- Files to change, function signatures, data flow
- NFR mapping (which code path addresses which NFR)
- Test strategy (unit / integration / e2e)
- New dependencies if any

Update `WORKSPACE_DIR/active-story.json` under `teamState.implementationBrief`:

```json
{
  "teamState": {
    "implementationBrief": {
      "filesToChange": ["path/to/file.ts"],
      "interfaceContracts": [
        {
          "file": "path/to/file.ts",
          "function": "functionName",
          "signature": "functionName(param: Type): ReturnType",
          "behavior": "Brief description of expected behavior"
        }
      ],
      "nfrMapping": [
        {
          "nfr": "NFR-001",
          "codePath": "path/to/file.ts:functionName",
          "how": "How this NFR is addressed"
        }
      ],
      "testStrategy": {
        "unit": "What unit tests should cover",
        "integration": "What integration tests should cover",
        "e2e": "What e2e tests should cover (if applicable)"
      },
      "dependencies": ["any new packages needed"]
    },
    "risks": [
      { "type": "business", "description": "One line" },
      { "type": "implementation", "description": "One line" },
      { "type": "security", "description": "One line" }
    ]
  }
}
```

### Step 7: Report to User

Output:
- Whether story was classified as infra-significant (and why / why not)
- Diagram path (if generated)
- ADR path and decision title
- Implementation brief summary: files to change, key interfaces, test strategy

---

## File Boundaries

| Artefact             | Path                                          |
|----------------------|-----------------------------------------------|
| C4 diagram           | `WORKSPACE_DIR/diagrams/story-{storyId}-c4.md` |
| ADR                  | `WORKSPACE_DIR/adr/*.md`                      |
| Implementation brief | `WORKSPACE_DIR/active-story.json` (`teamState`) |
