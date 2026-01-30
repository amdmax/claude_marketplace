# {{SKILL_NAME}}

<!-- Replace {{SKILL_NAME}} with your skill name -->

**Category:** {{CATEGORY}}
<!-- Categories: Core Workflow, Development, Architecture, Quality, Content, Specialized, Documentation, Configuration -->

**Priority:** {{PRIORITY}}
<!-- Tiers: 1 (Critical), 2 (High), 3 (Medium), 4 (Low) -->

## Purpose

{{Brief description of what this skill does and why it's useful}}

## Key Features

- {{Feature 1}}
- {{Feature 2}}
- {{Feature 3}}
- {{Add more as needed}}

## Configuration

This skill requires the following configuration in `config.yaml`:

### Required Variables

```yaml
# Project Identity
project:
  prefix: "{{PROJECT_PREFIX}}"          # Your project prefix (e.g., MYAPP)
  name: "{{PROJECT_NAME}}"              # Full project name

# Repository
repository:
  slug: "{{REPO_SLUG}}"                 # GitHub repository (e.g., owner/repo)
  owner: "{{REPO_OWNER}}"               # Repository owner
  name: "{{REPO_NAME}}"                 # Repository name
  default_branch: "{{DEFAULT_BRANCH}}"  # Default branch (e.g., main)

# Add skill-specific required variables here
```

### Optional Configuration

```yaml
# Feature Flags
features:
  {{feature_name}}: {{true/false}}     # Description of feature

# Paths (relative to project root)
paths:
  {{path_name}}: "{{PATH}}"            # Description of path

# Commands
commands:
  {{command_name}}: "{{COMMAND}}"      # Description of command
```

### Template Variables Reference

| Variable | Purpose | Example Value | Required |
|----------|---------|---------------|----------|
| `{{PROJECT_PREFIX}}` | Project identifier prefix | MYAPP | Yes |
| `{{REPO_SLUG}}` | GitHub repository | owner/repo | Yes |
| `{{VARIABLE_NAME}}` | Description | value | Yes/No |

## Usage

### Basic Usage

Invoke this skill with:

```
/{{skill-name}}
```

Or in natural language:

```
{{Natural language example of how to invoke this skill}}
```

### Advanced Usage

{{Describe advanced usage scenarios, if applicable}}

#### Example 1: {{Scenario Name}}

```
{{Example command or invocation}}
```

Expected behavior:
- {{Behavior 1}}
- {{Behavior 2}}

#### Example 2: {{Another Scenario}}

```
{{Example command or invocation}}
```

## Feature Flags

This skill supports the following feature flags in `config.yaml`:

### `{{feature_name}}`

**Default:** `{{true/false}}`

**Description:** {{What this feature does}}

**When to enable:**
- {{Use case 1}}
- {{Use case 2}}

**When to disable:**
- {{Use case 1}}
- {{Use case 2}}

**Example:**
```yaml
features:
  {{feature_name}}: true
```

## Workflows

### Workflow 1: {{Workflow Name}}

{{Description of this workflow}}

**Steps:**
1. {{Step 1}}
2. {{Step 2}}
3. {{Step 3}}

**Configuration:**
```yaml
features:
  workflow: "{{workflow-name}}"
```

### Workflow 2: {{Another Workflow}}

{{Description of alternative workflow}}

**Steps:**
1. {{Step 1}}
2. {{Step 2}}

## Examples

### Example 1: {{Example Scenario}}

**Scenario:** {{Describe the scenario}}

**Configuration:**
```yaml
project:
  prefix: "EXAMPLE"
  name: "Example Project"

repository:
  slug: "example/project"

features:
  {{feature_name}}: true
```

**Invocation:**
```
/{{skill-name}}
```

**Result:**
{{Describe what happens}}

### Example 2: {{Another Example}}

**Scenario:** {{Describe the scenario}}

**Configuration:**
```yaml
# Specific configuration for this example
```

**Result:**
{{Describe what happens}}

## Integration

### With Other Skills

This skill integrates with:

- **{{skill-name}}** - {{How they integrate}}
- **{{skill-name}}** - {{How they integrate}}

### With Hooks

This skill can be used in hooks:

```yaml
# .claude/hooks.yaml
on:
  {{event}}:
    - skill: {{skill-name}}
      config:
        {{config_key}}: {{config_value}}
```

## Troubleshooting

### Issue: {{Common Issue}}

**Symptoms:**
- {{Symptom 1}}
- {{Symptom 2}}

**Solution:**
{{How to fix it}}

```yaml
# Correct configuration
{{corrected_config}}
```

### Issue: {{Another Common Issue}}

**Symptoms:**
- {{Symptom}}

**Solution:**
{{How to fix it}}

## Implementation Details

### How It Works

{{Technical explanation of how the skill operates}}

**Process:**
1. {{Step 1 - what the skill does internally}}
2. {{Step 2}}
3. {{Step 3}}

### Dependencies

This skill requires:
- {{Dependency 1}} - {{Why it's needed}}
- {{Dependency 2}} - {{Why it's needed}}

### Files Created/Modified

This skill may create or modify:
- `{{file_path}}` - {{Purpose}}
- `{{file_path}}` - {{Purpose}}

## Customization

### Extending This Skill

To add custom behavior:

1. {{Step 1}}
2. {{Step 2}}

### Creating Variants

To create a variant of this skill:

```bash
cp -r .claude/skills/{{skill-name}} .claude/skills/{{skill-name}}-custom
# Edit SKILL.md and config.yaml
```

## Migration Notes

{{If this skill was migrated from another project, document:}}
- **Source Project:** {{project name}}
- **Original Prefix:** {{OLDPREFIX}}
- **Changes Made:** {{What was abstracted}}
- **Variations Merged:** {{Any variations that were combined}}

## Version History

- **v1.0.0** - {{Initial version description}}
- **v1.1.0** - {{What changed}}

## See Also

- [{{Related Skill}}](../{{related-skill}}/SKILL.md) - {{Why it's related}}
- [Configuration Reference](../../docs/configuration-reference.md)
- [Abstraction Guide](../../docs/abstraction-guide.md)

## Notes

{{Any additional notes, warnings, or important information}}

---

**Invoke:** `/{{skill-name}}`

**Configuration File:** [config.yaml](config.yaml)

**Example Configuration:** [config.example.yaml](config.example.yaml)
