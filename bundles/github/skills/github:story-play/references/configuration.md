# Configuration

## Required: `.claude/story-workflow-config.json`

```json
{
  "storyWorkflow": {
    "projectId": "{{GITHUB_PROJECT_ID}}",
    "fieldIds": {
      "status": "PVTSSF_...",
      "priority": "PVTSSF_...",
      "size": "PVTSSF_...",
      "itemType": "PVTSSF_...",
      "techSpecStatus": "PVTSSF_..."
    },
    "optionIds": {
      "status": {
        "ready": "61e4505c",
        "inProgress": "47fc9ee4",
        "backlog": "f75ad846"
      },
      "priority": {
        "p0": "79628723",
        "p1": "0a877460",
        "p2": "da944a9c"
      }
    }
  }
}
```

## Optional Settings

```json
{
  "storyWorkflow": {
    "defaultNFRs": {
      "performance": {
        "dailyActiveUsers": "100-1000",
        "maxResponseTime": "<2s"
      }
    },
    "skipADRForLabels": ["bug", "chore", "docs"],
    "autoCreateBranch": true,
    "branchPrefix": "feature/"
  }
}
```

Find `projectId` and field/option IDs with:
```bash
gh project view {{PROJECT_NUMBER}} --owner {{ORG}} --format json
```
