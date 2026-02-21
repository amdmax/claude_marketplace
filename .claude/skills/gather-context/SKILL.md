---
name: gather-context
description: Gather technical context from multiple sources including docs, code analysis, architecture files, and user input. Appends comprehensive context to active story for informed decision-making. Invokable with /gather-context.
---

# Gather Technical Context

## Overview

This skill collects comprehensive technical context for a story by searching multiple information sources. It:

1. **Searches documentation** (`docs/`) for related technical specs and guidelines
2. **Analyzes codebase** using Explore agent to find related implementations
3. **Reviews architecture docs** (`{{ARCHITECTURE_DOCS_DIR}}/`) for architectural decisions
4. **Checks existing ADRs** (`{{ADR_DIR}}/`) for precedents
5. **Asks user questions** for dependencies, constraints, and preferences
6. **Appends context** to `{{ACTIVE_STORY_FILE}}` for ADR generation

Context gathering informs architectural decisions and helps avoid reinventing existing patterns.

## Context Sources

### 1. Documentation (`docs/`)

**What to search for:**
- Technical specifications
- Development workflows
- API documentation
- Deployment guides
- Testing strategies

**Search strategy:**
```bash
# Extract key terms from story title
STORY_TITLE="Implement payment checkout"
KEYWORDS="payment checkout stripe billing"

# Search documentation
Grep: pattern="payment|checkout|billing|stripe", path="docs/", output_mode="files_with_matches"

# Review relevant files
Read: docs/DEVELOPMENT_WORKFLOW.md
Read: docs/API_GUIDELINES.md
# etc.
```

**What to capture:**
- Relevant guidelines or patterns
- Existing API endpoints to integrate with
- Testing requirements
- Deployment considerations

### 2. Codebase Analysis

**What to search for:**
- Related implementations (similar features)
- Integration patterns (API clients, database access)
- Authentication/authorization patterns
- Error handling approaches
- Testing patterns

**Search strategy:**

Use the Explore agent for comprehensive code analysis:

```
Task(Explore, thoroughness="medium"):
"Find existing payment/checkout implementation code.
Search for:
- API integrations with external payment services (Stripe, PayPal)
- Lambda functions handling payment workflows
- DynamoDB schemas for payment/transaction data
- Authentication patterns for sensitive operations
- Error handling and retry logic for payments

Identify:
- File paths of relevant implementations
- Reusable patterns and helper functions
- Testing approaches
- Configuration patterns"
```

**What to capture:**
- Paths to relevant files
- Reusable components (auth, validation, error handling)
- Integration patterns (how APIs are called)
- Data models (DynamoDB tables, schemas)

### 3. Architecture Documentation (`{{ARCHITECTURE_DOCS_DIR}}/`)

**What to search for:**
- Product briefs
- Architecture documents
- Technical specifications
- UX designs
- Epics and stories

**Search strategy:**
```bash
# Search architecture docs
Glob: pattern="{{ARCHITECTURE_DOCS_DIR}}/**/*architecture*.md"
Glob: pattern="{{ARCHITECTURE_DOCS_DIR}}/**/*tech-spec*.md"

# Search for payment-related docs
Grep: pattern="payment|billing|checkout", path="{{ARCHITECTURE_DOCS_DIR}}/", output_mode="files_with_matches"

# Read relevant docs
Read: {{ARCHITECTURE_DOCS_DIR}}/payment-referral-architecture.md
Read: {{ARCHITECTURE_DOCS_DIR}}/phase3-tech-spec.md
```

**What to capture:**
- Architectural patterns to follow
- Technology choices already made
- Integration points with other features
- Non-functional requirements from architecture

### 4. Existing ADRs (`{{ADR_DIR}}/`)

**What to search for:**
- Related architectural decisions
- Technology selections
- Pattern choices
- Lessons learned

**Search strategy:**
```bash
# List all ADRs
Glob: pattern="{{ADR_DIR}}/*.md"

# Search for payment-related ADRs
Grep: pattern="payment|stripe|checkout|billing", path="{{ADR_DIR}}/", output_mode="files_with_matches"

# Read relevant ADRs
Read: {{ADR_DIR}}/0001-stripe-payment-processor.md
Read: {{ADR_DIR}}/0005-lambda-edge-auth.md
```

**What to capture:**
- Technology choices (and why)
- Patterns to follow (or avoid)
- Lessons learned from past decisions
- Superseded decisions

### 5. User Clarification

**What to ask:**
- Dependencies on other systems/features
- Integration requirements
- Special constraints (AWS limits, cost, performance)
- Preferred implementation approach
- Known issues or gotchas

**Question examples:**

```
Q1: Does this feature depend on any other systems or features?
Multi-select:
  □ Authentication system
  □ User profile service
  □ Notification system
  □ Analytics/tracking
  □ External APIs (specify)
  □ None

Q2: Are there any specific AWS service constraints we should be aware of?
Text input / Multiple choice:
  • Lambda timeout limits
  • DynamoDB throughput limits
  • API Gateway rate limits
  • No specific constraints

Q3: What is your preferred implementation approach?
Multiple choice (if multiple valid approaches):
  • Approach A: [description] (pros/cons)
  • Approach B: [description] (pros/cons)
  • No preference - recommend based on context
```

## Workflow

### Step 1: Verify Active Story and NFRs Exist

```bash
STORY_FILE="$CLAUDE_PROJECT_DIR/{{ACTIVE_STORY_FILE}}"
if [ ! -f "$STORY_FILE" ]; then
  echo "❌ No active story found"
  echo "   Expected: $CLAUDE_PROJECT_DIR/{{ACTIVE_STORY_FILE}}"
  echo "   Run /fetch-story first"
  exit 1
fi
```

**Check NFRs:**
```javascript
const story = JSON.parse(fs.readFileSync('{{ACTIVE_STORY_FILE}}', 'utf-8'));

if (!story.nfrs || Object.keys(story.nfrs).length === 0) {
  console.log('⚠️  NFRs not yet collected');
  console.log('   Recommend running /gather-nfr first for better context');
  // Proceed anyway, but note this in output
}
```

### Step 2: Extract Search Terms from Story

**Parse story:**
```javascript
const title = story.title.toLowerCase();
const body = story.body.toLowerCase();
const labels = story.labels;

// Extract key technical terms
const keywords = extractKeywords(title, body);
// Example: ["payment", "checkout", "stripe", "billing"]
```

**Keyword extraction logic:**
```javascript
function extractKeywords(title, body) {
  // 1. Extract nouns from title (payment, checkout, user, profile)
  // 2. Identify technology terms (Stripe, DynamoDB, Lambda)
  // 3. Remove stop words (implement, add, create, update)
  // 4. Include domain terms from body

  const stopWords = ['implement', 'add', 'create', 'update', 'fix', 'improve'];
  const techs = ['stripe', 'paypal', 'dynamodb', 'lambda', 's3', 'cognito'];

  // Simple extraction (can be more sophisticated)
  const words = (title + ' ' + body).toLowerCase()
    .split(/\s+/)
    .filter(w => w.length > 3)
    .filter(w => !stopWords.includes(w));

  return [...new Set(words)].slice(0, 5); // Top 5 unique keywords
}
```

### Step 3: Search Documentation

**Execute searches:**

```bash
# Search for keyword matches in docs/
Grep: pattern="payment|checkout|stripe", path="docs/", output_mode="files_with_matches"

# Common doc files to always check
Read: docs/DEVELOPMENT_WORKFLOW.md
Read: docs/CLAUDE.md
```

**Process results:**
```javascript
const relatedDocs = [];

for (const docFile of foundDocs) {
  // Read file
  const content = fs.readFileSync(docFile, 'utf-8');

  // Check relevance (keyword density, section matches)
  if (isRelevant(content, keywords)) {
    relatedDocs.push({
      path: docFile,
      summary: extractRelevantSections(content, keywords)
    });
  }
}
```

**Capture:**
```json
{
  "relatedDocs": [
    {
      "path": "docs/DEVELOPMENT_WORKFLOW.md",
      "summary": "Mentions payment testing requirements and PCI-DSS compliance"
    },
    {
      "path": "docs/API_GUIDELINES.md",
      "summary": "Defines error handling patterns for external API integrations"
    }
  ]
}
```

### Step 4: Analyze Codebase with Explore Agent

**Launch Explore agent:**

```
Task(Explore, thoroughness="medium", description="Search for payment-related code"):
"
Story: #${story.issueNumber} - ${story.title}

Find existing implementations related to: ${keywords.join(', ')}

Search for:
1. API integrations with external services (${keywords})
2. Lambda functions handling similar workflows
3. DynamoDB schemas for related data models (tables, indexes)
4. Authentication/authorization patterns for sensitive operations
5. Error handling, retry logic, and validation patterns
6. Test fixtures and mocking strategies

Identify:
- File paths of relevant implementations
- Reusable components (helpers, utilities, middleware)
- Integration patterns (how external APIs are called)
- Configuration approaches (environment variables, parameter store)
- Data models and schemas

Summarize findings with:
- File paths
- Key patterns to reuse
- Gotchas or known issues (from comments, TODOs)
"
```

**Process agent output:**

```javascript
// Agent returns file paths and analysis
const agentResult = await taskOutput;

const relatedCode = parseAgentResults(agentResult);
// Extract:
// - File paths
// - Pattern descriptions
// - Reusable components
```

**Capture:**
```json
{
  "relatedCode": [
    {
      "path": "lambda/payment-handler/index.ts",
      "description": "Stripe API integration with retry logic and idempotency",
      "reusablePatterns": [
        "Exponential backoff for API retries",
        "Idempotency key generation",
        "Webhook signature verification"
      ]
    },
    {
      "path": "infrastructure/payment-stack.ts",
      "description": "CDK stack for payment Lambda and DynamoDB table",
      "reusablePatterns": [
        "Lambda environment variable configuration",
        "DynamoDB table with GSI for user lookups",
        "IAM policies for least-privilege access"
      ]
    }
  ]
}
```

### Step 5: Review Architecture Documentation

**Search architecture docs:**

```bash
# Find architecture files
Glob: pattern="{{ARCHITECTURE_DOCS_DIR}}/**/*architecture*.md"
Glob: pattern="{{ARCHITECTURE_DOCS_DIR}}/**/*tech-spec*.md"

# Search by keywords
Grep: pattern="payment|checkout", path="{{ARCHITECTURE_DOCS_DIR}}/", output_mode="files_with_matches"
```

**Read relevant files:**

```bash
for file in $FOUND_FILES; do
  Read: $file
  # Extract relevant sections
done
```

**Capture:**
```json
{
  "relatedArchitecture": [
    {
      "path": "{{ARCHITECTURE_DOCS_DIR}}/payment-referral-architecture.md",
      "relevantSections": [
        "Payment processing using Stripe Checkout",
        "DynamoDB schema for transactions",
        "Lambda@Edge auth for payment endpoints"
      ],
      "decisions": [
        "Stripe Checkout chosen over custom form (PCI compliance)",
        "Transactions stored in DynamoDB (not RDS) for scalability"
      ]
    }
  ]
}
```

### Step 6: Check Existing ADRs

**List and search ADRs:**

```bash
# List all ADRs
Glob: pattern="{{ADR_DIR}}/*.md"

# Search for relevant ADRs
Grep: pattern="payment|stripe|checkout", path="{{ADR_DIR}}/", output_mode="files_with_matches"
```

**Read relevant ADRs:**

```bash
for adr in $FOUND_ADRS; do
  Read: $adr
  # Extract decision, rationale, consequences
done
```

**Capture:**
```json
{
  "relatedADRs": [
    {
      "path": "{{ADR_DIR}}/0001-stripe-payment-processor.md",
      "decision": "Use Stripe Checkout for payment processing",
      "rationale": "PCI compliance handled by Stripe, faster implementation, good developer experience",
      "consequences": "Less UI customization, vendor lock-in to Stripe",
      "status": "accepted"
    },
    {
      "path": "{{ADR_DIR}}/0005-lambda-edge-auth.md",
      "decision": "Use Lambda@Edge for authentication",
      "rationale": "CloudFront integration, low latency, no cold starts",
      "consequences": "Size limits (<1MB), no environment variables",
      "status": "accepted",
      "relevance": "Payment endpoints need authentication"
    }
  ]
}
```

### Step 7: Ask User Clarifying Questions

**Question 1: Dependencies**

```
AskUserQuestion:
  question: "Does this feature depend on any existing systems or features?"
  multiSelect: true
  options:
    - label: "Authentication system"
      description: "Requires user to be logged in"
    - label: "User profile service"
      description: "Needs user data (email, name, etc.)"
    - label: "Notification system"
      description: "Sends emails/SMS for events"
    - label: "Analytics/tracking"
      description: "Tracks user actions for metrics"
    - label: "External APIs"
      description: "Integrates with third-party services (specify which)"
    - label: "None"
      description: "Self-contained feature"
```

**Question 2: Constraints**

```
AskUserQuestion:
  question: "Are there specific technical constraints we should be aware of?"
  multiSelect: true
  options:
    - label: "AWS Lambda timeout (30s max)"
      description: "Long-running operations need alternative approach"
    - label: "Lambda@Edge size limit (1MB)"
      description: "Code must be optimized for edge deployment"
    - label: "DynamoDB throughput limits"
      description: "High write volume may need provisioned capacity"
    - label: "API Gateway rate limits"
      description: "Need to handle throttling"
    - label: "Cost constraints"
      description: "Budget-conscious implementation required"
    - label: "No specific constraints"
      description: "Standard implementation acceptable"
```

**Question 3: Implementation Approach (conditional)**

Only ask if multiple valid approaches exist:

```javascript
// Detect if multiple approaches are possible
if (hasMultipleApproaches(story, relatedCode, relatedArchitecture)) {
  AskUserQuestion({
    question: "Multiple implementation approaches are possible. Which do you prefer?",
    multiSelect: false,
    options: [
      {
        label: "Approach A: Stripe Checkout (Hosted)",
        description: "Pros: PCI compliance, fast. Cons: Less customization, redirects away from site"
      },
      {
        label: "Approach B: Stripe Elements (Embedded)",
        description: "Pros: Full UI control, stays on site. Cons: More code, PCI responsibility"
      },
      {
        label: "No preference",
        description: "Recommend based on NFRs and context"
      }
    ]
  });
}
```

**Question 4: Known Issues**

```
AskUserQuestion:
  question: "Are there any known issues, gotchas, or special considerations?"
  type: "text"
  default: "None"
  examples: [
    "Existing payment code has race condition bug",
    "Stripe test mode must be used in dev environment",
    "Need to handle duplicate webhook deliveries"
  ]
```

**Capture user responses:**
```json
{
  "dependencies": ["Authentication system", "User profile service", "Notification system"],
  "constraints": ["AWS Lambda timeout (30s max)", "Cost constraints"],
  "preferredApproach": "Stripe Checkout (Hosted)",
  "knownIssues": "Stripe test mode must be used in dev. Need to handle duplicate webhook deliveries."
}
```

### Step 8: Extract Patterns and Best Practices

**Analyze collected context:**

```javascript
// From code analysis
const patterns = extractPatterns(relatedCode);
// Example:
// - "API Gateway + Lambda pattern"
// - "DynamoDB single-table design"
// - "Exponential backoff for retries"
// - "Error handling via dead-letter queue"

// From architecture docs
const architecturalPatterns = extractArchPatterns(relatedArchitecture);
// Example:
// - "Lambda@Edge for auth"
// - "CloudFront + S3 for static content"
// - "Cognito for user management"

// From ADRs
const establishedDecisions = extractDecisions(relatedADRs);
// Example:
// - "Stripe Checkout for payments"
// - "DynamoDB over RDS for transactions"
// - "TypeScript strict mode"
```

**Capture:**
```json
{
  "patterns": [
    "API Gateway + Lambda pattern for endpoints",
    "DynamoDB single-table design with GSIs",
    "Exponential backoff for external API retries",
    "Error handling via CloudWatch alarms + SNS",
    "Lambda@Edge for authentication",
    "TypeScript strict mode for type safety"
  ]
}
```

### Step 9: Append Context to Active Story

**Read existing story:**
```javascript
const story = JSON.parse(fs.readFileSync('{{ACTIVE_STORY_FILE}}', 'utf-8'));
```

**Merge context:**
```javascript
story.context = {
  relatedDocs: [...],
  relatedCode: [...],
  relatedArchitecture: [...],
  relatedADRs: [...],
  dependencies: [...],
  constraints: [...],
  preferredApproach: "...",
  knownIssues: "...",
  patterns: [...]
};
```

**Write updated story:**
```javascript
fs.writeFileSync('{{ACTIVE_STORY_FILE}}', JSON.stringify(story, null, 2));
```

### Step 10: Report Summary

**Output:**

```
✓ Technical Context Collected

Documentation:
  • docs/DEVELOPMENT_WORKFLOW.md - Payment testing requirements
  • docs/API_GUIDELINES.md - Error handling patterns

Codebase Analysis:
  • lambda/payment-handler/index.ts - Stripe integration with retries
  • infrastructure/payment-stack.ts - CDK stack for payment Lambda

Architecture:
  • {{ARCHITECTURE_DOCS_DIR}}/payment-referral-architecture.md - Payment processing design

Existing ADRs:
  • ADR-0001: Stripe payment processor (accepted)
  • ADR-0005: Lambda@Edge auth (accepted)

Dependencies:
  • Authentication system
  • User profile service
  • Notification system

Constraints:
  • AWS Lambda timeout (30s max)
  • Cost constraints

Established Patterns:
  • API Gateway + Lambda pattern
  • DynamoDB single-table design
  • Exponential backoff for retries
  • Lambda@Edge authentication

Preferred Approach:
  Stripe Checkout (hosted page)

Known Issues:
  • Stripe test mode must be used in dev
  • Handle duplicate webhook deliveries

✓ Context saved to {{ACTIVE_STORY_FILE}}

Next steps:
  Run /create-adr to generate Architecture Decision Record
  Or run /play-story to continue the full workflow
```

## Error Handling

### No Active Story

```
❌ No active story found

Please run /fetch-story first to select a story.
```

### Context Already Exists

```
⚠️  Context already exists for this story

Current context:
  • 2 related docs
  • 3 code files
  • 1 architecture doc
  • 2 ADRs

Options:
  [1] Keep existing context (cancel)
  [2] Re-collect context (overwrite)
  [3] View full existing context

Choice:
```

### No Related Documentation Found

```
ℹ️  No related documentation found

Searched: docs/ for keywords [payment, checkout, stripe]

This is not necessarily an error - the feature may be novel.

Continue with code analysis and user questions? [Y/n]
```

### Explore Agent Failed

```
⚠️  Code analysis incomplete

The Explore agent encountered an error or timeout.

Partial results available:
  • lambda/payment-handler/index.ts

Continue with partial results? [Y/n]
```

### No Related ADRs Found

```
ℹ️  No related ADRs found

Searched: {{ADR_DIR}}/ for keywords [payment, checkout, stripe]

This may be the first architectural decision in this area.

Continue with documentation and code context? [Y/n]
```

## Implementation Details

### Thoroughness Levels

**Quick (thoroughness="quick"):**
- Search only common doc files
- Skip Explore agent (use simple Grep)
- Check only ADR titles
- Minimal user questions (1-2)
- **Use case:** Simple bug fixes, small changes

**Medium (thoroughness="medium"):** [Default]
- Search all documentation
- Use Explore agent with medium depth
- Read relevant ADRs
- Standard user questions (3-4)
- **Use case:** Standard features, typical stories

**Thorough (thoroughness="thorough"):**
- Exhaustive documentation search
- Use Explore agent with high depth
- Deep ADR analysis
- Comprehensive user questions (5-6)
- **Use case:** Complex features, major architectural changes

### Keyword Extraction Strategies

**Simple (current approach):**
```javascript
// Split on whitespace, filter stop words
const keywords = title.split(/\s+/).filter(w => !stopWords.includes(w));
```

**Advanced (future enhancement):**
```javascript
// Use NLP or LLM to extract entities and technical terms
const keywords = await extractEntities(title, body);
// Returns: ["Stripe API", "payment checkout", "DynamoDB transaction table"]
```

### Pattern Extraction

**From code:**
```javascript
// Analyze imports, function signatures, comments
function extractPatterns(codeFiles) {
  const patterns = [];

  for (const file of codeFiles) {
    // Check for common patterns
    if (file.content.includes('exponential backoff')) {
      patterns.push('Exponential backoff for retries');
    }
    if (file.content.includes('DynamoDB.DocumentClient')) {
      patterns.push('DynamoDB single-table design');
    }
    // etc.
  }

  return patterns;
}
```

**From ADRs:**
```javascript
// Parse MADR sections
function extractDecisions(adrFiles) {
  const decisions = [];

  for (const adr of adrFiles) {
    const decision = parseMADR(adr.content).decision;
    decisions.push({
      adr: adr.path,
      decision,
      status: parseMADR(adr.content).status
    });
  }

  return decisions.filter(d => d.status === 'accepted');
}
```

## Integration with Other Skills

### Called by /play-story

```
/play-story
  ↓
1. /fetch-story → Get story
2. /gather-nfr → Collect NFRs
3. /gather-context → Collect context (this skill)
4. /create-adr → Generate ADR
```

### Output Used by /create-adr

**Context feeds directly into ADR generation:**

- **Related ADRs** → "Links" section
- **Patterns** → "Implementation Notes" section
- **Constraints** → "Decision Drivers" section
- **Dependencies** → "Context and Problem Statement"
- **Preferred approach** → "Decision Outcome"

## Best Practices

### Context Gathering

**✅ Do:**
- Cast a wide net (search multiple sources)
- Filter for relevance (not everything is useful)
- Capture file paths (for later reference)
- Summarize findings (don't dump raw data)

**❌ Don't:**
- Read every file (too slow, too much noise)
- Ignore user input (they have valuable context)
- Assume existing patterns are correct (verify)
- Overwhelm with information (summarize)

### User Questions

**✅ Do:**
- Ask open-ended questions when needed
- Provide multiple choice when possible
- Explain why each question matters
- Allow "No preference" options

**❌ Don't:**
- Ask obvious questions (evident from code)
- Force answers (allow "N/A")
- Ask too many questions (respect time)

### Pattern Recognition

**Look for:**
- Consistent naming conventions
- Repeated code structures
- Common error handling
- Standard testing approaches

**Capture:**
- What patterns exist
- Where they're used (file paths)
- Why they're used (from comments/ADRs)
- How to apply them (examples)

## Summary

The `/gather-context` skill provides comprehensive context by:

✅ **Multi-source search** - Docs, code, architecture, ADRs
✅ **Intelligent analysis** - Uses Explore agent for deep code understanding
✅ **User collaboration** - Asks targeted clarifying questions
✅ **Pattern extraction** - Identifies reusable approaches
✅ **ADR-ready output** - Structured for decision record generation

Use `/gather-context` to gather everything needed for informed architectural decisions!
