# Editorial Standards for Educational Technical Content

## Voice & Tone

### Professional Yet Accessible

**Do:**
- Use clear, direct language
- Explain technical concepts without condescension
- Balance formality with approachability
- Address reader as "you" (second person)

**Don't:**
- Use overly casual slang or memes
- Talk down to readers
- Use corporate buzzwords without substance
- Switch between formal and informal tone

### Active Voice Priority

**Preferred:** "The compiler optimizes your code"
**Avoid:** "Your code is optimized by the compiler"

**Exception:** Passive voice acceptable when:
- The actor is unknown or irrelevant
- Describing technical processes: "The data is cached in memory"
- Focusing on the object rather than the subject

### Technical Precision

- Define acronyms on first use: "Large Language Model (LLM)"
- Use consistent terminology (don't alternate between synonyms)
- Provide context for numbers: "10K tokens (~7,500 words)"
- Link to external sources for controversial or evolving information

## Formatting Conventions

### Headings

```markdown
# H1: Document Title (one per document)

## H2: Major Sections

### H3: Subsections

**Bold**: Emphasis within paragraphs
*Italic*: Terms or concepts being introduced
```

**Capitalization:**
- Title Case for H1
- Sentence case for H2-H6
- Consistent across all documents

### Lists

**Unordered lists:** Related items without hierarchy
```markdown
- Item one
- Item two
  - Nested item (use sparingly)
```

**Ordered lists:** Sequential steps or ranked items
```markdown
1. First step
2. Second step
3. Third step
```

**Definition lists:** Term-explanation pairs
```markdown
**Term**: Explanation of the term
**Another term**: Its explanation
```

### Code Formatting

**Inline code:** Use `backticks` for:
- Variable names: `apiKey`
- Function names: `getUserData()`
- File paths: `src/index.ts`
- Short code snippets: `const x = 42`
- Command-line tools: `npm install`

**Code blocks:** Use triple backticks with language identifier:

````markdown
```typescript
function greet(name: string): string {
  return `Hello, ${name}!`;
}
```
````

**Always include:**
- Language identifier for syntax highlighting
- Comments for non-obvious code
- Complete, runnable examples when possible

### Emphasis

**Bold (`**text**`)**: Use for:
- Important concepts on first introduction
- Warnings or critical information
- Section labels in lists

**Italic (`*text*`)**: Use for:
- Terms being defined
- Book or article titles
- Subtle emphasis

**Avoid:**
- ALL CAPS (unless acronyms)
- Excessive exclamation marks!!!
- Overuse of bold/italic (diminishes impact)

## Code Example Best Practices

### Complete and Runnable

```markdown
✓ Good:
```python
import requests

def fetch_data(url: str) -> dict:
    """Fetch JSON data from API endpoint."""
    response = requests.get(url)
    response.raise_for_status()
    return response.json()
```

✗ Bad:
```python
# Fetch data
fetch_data(url)
```
```

### Realistic Context

```markdown
✓ Good: Real-world scenario
```typescript
// Authenticate user and retrieve dashboard data
async function loadUserDashboard(userId: string) {
  const user = await authenticateUser(userId);
  const metrics = await fetchMetrics(user.id);
  return { user, metrics };
}
```

✗ Bad: Toy example
```typescript
function add(a, b) {
  return a + b;
}
```
```

### Progressive Complexity

**Start simple:**
```python
# Basic example
print("Hello World")
```

**Build up:**
```python
# With variables
message = "Hello World"
print(message)
```

**Add complexity:**
```python
# With functions
def greet(name: str) -> None:
    message = f"Hello {name}"
    print(message)

greet("World")
```

### Comment Strategy

**Good comments explain WHY, not WHAT:**
```python
# Retry failed requests to handle transient network issues
max_retries = 3

# Cache results for 5 minutes to reduce API costs
cache_ttl = 300
```

**Bad comments repeat the code:**
```python
# Set max retries to 3
max_retries = 3

# Set cache TTL to 300
cache_ttl = 300
```

## Common Writing Pitfalls

### 1. Assuming Knowledge

❌ **Bad:** "Use the embeddings API with cosine similarity for semantic search."

✓ **Good:** "Embeddings convert text into numerical vectors representing meaning. By calculating cosine similarity between these vectors, you can find semantically similar content—even if the words are completely different."

### 2. Vague Language

❌ **Bad:** "This can improve performance significantly."

✓ **Good:** "Caching reduces API latency from 200ms to 10ms (20x faster)."

### 3. Unsubstantiated Claims

❌ **Bad:** "This is the best approach for production systems."

✓ **Good:** "Companies like Stripe and Shopify use this approach for high-traffic production systems, handling 10K+ requests/second."

### 4. Missing Context

❌ **Bad:**
```markdown
## Step 3: Configure the API

Set your API key in the environment.
```

✓ **Good:**
```markdown
## Step 3: Configure the API

Before making API calls, you need to authenticate. Set your API key as an environment variable so it's not hardcoded in your source code:

```bash
export OPENAI_API_KEY="sk-..."
```
```

### 5. Information Overload

❌ **Bad:** Dense paragraph with 10 concepts
```
Context windows determine how much information an LLM can process, with recent models supporting 128K, 200K, or even 1M+ tokens, though effective context can degrade with fill percentage, requiring strategies like RAG, prompt compression, context window management, token counting, sliding windows, and hierarchical summarization to maximize effectiveness while managing costs and latency implications across different model providers.
```

✓ **Good:** One concept at a time
```
Context windows determine how much information an LLM can process at once. Modern models vary significantly:

- GPT-4 Turbo: 128K tokens
- Claude 3.5: 200K tokens
- Gemini 1.5 Pro: 1M+ tokens

However, larger contexts don't always mean better results. Beyond 80% capacity, LLMs may struggle to recall information effectively—a phenomenon called "context degradation."
```

### 6. Weak Openings

❌ **Bad:** "In this section, we will discuss context windows."

✓ **Good:** "Running out of context when analyzing a 50,000 line codebase? Context windows are your bottleneck—here's how to work around them."

### 7. Jargon Overload

❌ **Bad:** "Leverage the SDK's RAG capabilities with vector embeddings for semantic retrieval."

✓ **Good:** "The SDK includes Retrieval-Augmented Generation (RAG), which searches your documents by meaning rather than keywords. It works by converting text to vectors (numbers representing meaning) and finding mathematically similar content."

## Structural Patterns

### Problem → Solution → Example

```markdown
**Problem**: LLMs forget earlier parts of long conversations.

**Solution**: Summarize old messages and keep only recent context.

**Example**: After 20 messages, compress the first 10 into a summary like "User requested OAuth implementation for Node.js API, we discussed security best practices."
```

### Concept → Explanation → Application

```markdown
**Prompt engineering** is the practice of crafting inputs to LLMs to get desired outputs.

Well-engineered prompts include context, examples, and constraints. For instance, instead of "Write code," use "Write a TypeScript function that validates email addresses using regex, with error handling for invalid inputs."
```

### Before → After Comparisons

```markdown
**Before (generic prompt):**
"Help me with authentication"

**After (specific prompt):**
"I need to add JWT authentication to a Next.js app. Users should log in with email/password, receive a JWT token, and include it in subsequent API requests. Show me the complete implementation with error handling."
```

## Quality Checklist

Before publishing content, verify:

### Clarity
- [ ] Every technical term defined on first use
- [ ] No unexplained jargon or acronyms
- [ ] Complex concepts broken into steps
- [ ] Active voice used (passive only where appropriate)

### Examples
- [ ] Code examples are complete and runnable
- [ ] Examples show realistic scenarios (not toy problems)
- [ ] Progressive complexity (simple → advanced)
- [ ] Comments explain WHY, not WHAT

### Structure
- [ ] Logical flow from simple to complex
- [ ] Clear headings and section divisions
- [ ] Appropriate use of lists vs. paragraphs
- [ ] Cross-references to related content

### Engagement
- [ ] Opening hooks reader's attention
- [ ] Concrete examples throughout
- [ ] Avoids walls of text (broken up with code, lists, headings)
- [ ] Explains "so what" (why readers should care)

### Consistency
- [ ] Terminology consistent throughout
- [ ] Code style matches project conventions
- [ ] Heading capitalization consistent
- [ ] Tone matches other sections

### Accessibility
- [ ] Prerequisite knowledge stated upfront
- [ ] Learning objectives clear
- [ ] Difficulty level appropriate for placement
- [ ] Alternative explanations for complex concepts
