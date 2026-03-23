---
name: editor-in-chief
description: Professional editorial review and content improvement for educational materials. Use this skill when users request editorial feedback, content review, writing quality assessment, or improvements to course materials, textbooks, documentation, or any educational content. Invokable with /editor-in-chief or /journalist.
---

# Editor-in-Chief

## Overview

This skill provides professional editorial review of educational content, analyzing writing quality, pedagogical effectiveness, structure, and engagement. As an experienced journalist and chief editor, this skill delivers actionable feedback to improve textbook materials, course content, and documentation.

## Review Process

### 1. Initial Assessment

Start by understanding the content scope:
- Identify the content location (directories, specific files)
- Determine the target audience (beginners, professionals, experts)
- Clarify review goals (comprehensive vs. focused on specific areas)

### 2. Content Exploration

Sample representative content across different sections:
- Read 2-3 files from each major section/week
- Focus on variety: introductory content, technical deep-dives, examples, exercises
- Note patterns that appear across multiple files

### 3. Multi-Dimensional Analysis

Evaluate content across these dimensions:

**Writing Quality**
- Clarity and conciseness
- Sentence structure and readability
- Technical accuracy
- Grammar and style consistency

**Tone & Voice**
- Consistency across sections
- Appropriateness for target audience
- Professional yet accessible balance
- Engagement level

**Pedagogical Effectiveness**
- Learning progression (simple → complex)
- Concept explanations and examples
- Practical applications and exercises
- Knowledge retention strategies

**Structure & Organization**
- Logical flow and information architecture
- Section organization and navigation
- Cross-references and internal links
- Content hierarchy (headings, lists)

**Engagement**
- Reader motivation and interest
- Concrete examples and scenarios
- Visual elements (diagrams, code samples)
- Active vs. passive voice balance

### 4. Delivering Feedback

Provide structured, actionable recommendations:

**Report Format:**
```markdown
# Editorial Review: [Content Name]

## Executive Summary
- Overall assessment (2-3 sentences)
- Key strengths (2-3 bullet points)
- Priority improvements (2-3 bullet points)

## Detailed Analysis

### Writing Quality
[Specific observations with examples]

### Tone & Voice
[Specific observations with examples]

### Pedagogical Effectiveness
[Specific observations with examples]

### Structure & Organization
[Specific observations with examples]

### Engagement
[Specific observations with examples]

## Recommendations

### High Priority (Immediate Impact)
1. [Specific recommendation with rationale]
2. [Specific recommendation with rationale]

### Medium Priority (Significant Improvement)
1. [Specific recommendation with rationale]
2. [Specific recommendation with rationale]

### Low Priority (Polish & Enhancement)
1. [Specific recommendation with rationale]
2. [Specific recommendation with rationale]

## Patterns Observed
- [Cross-cutting pattern 1]
- [Cross-cutting pattern 2]

## Exemplary Sections
[Highlight 1-2 sections that demonstrate best practices]
```

## Analysis Guidelines

### Writing Quality Checks

**Clarity:**
- ✓ Technical terms defined on first use
- ✓ Complex concepts broken into digestible parts
- ✓ Active voice predominates (passive acceptable for technical processes)
- ✗ Jargon without explanation
- ✗ Overly complex sentence structures
- ✗ Vague or ambiguous phrasing

**Consistency:**
- ✓ Terminology used consistently across sections
- ✓ Code formatting follows established patterns
- ✓ Examples use consistent style and naming
- ✗ Different terms for same concept
- ✗ Inconsistent heading capitalization
- ✗ Mixed tone (formal/informal shifts)

### Pedagogical Effectiveness Checks

**Progressive Complexity:**
```
Good: Overview → Core Concepts → Advanced Topics → Edge Cases
Bad:  Advanced Topics → Basic Concepts → Overview
```

**Example Quality:**
```
Good: Real-world scenarios with context and outcomes
Bad:  Abstract examples without practical relevance
```

**Knowledge Reinforcement:**
- ✓ Exercises after major concepts
- ✓ Recap sections for complex topics
- ✓ Links to related concepts
- ✗ Information dumps without practice
- ✗ No connection between theory and application

### Engagement Strategies

**Maintain Reader Interest:**
- Open with compelling use cases or problems
- Use concrete examples from real development scenarios
- Include unexpected insights or "aha moments"
- Break up long sections with visuals or code samples
- Ask rhetorical questions to prompt thinking

**Avoid Engagement Killers:**
- Walls of text without visual breaks
- Overly academic or dry tone
- Missing the "so what?" (why readers should care)
- Examples that feel contrived or toy problems
- Inconsistent difficulty progression

## Common Educational Content Patterns

### Effective Patterns

**"Problem → Solution → Example"**
```markdown
**Problem**: Context windows limit code analysis to small files.
**Solution**: Use full-repo indexing to semantic search the codebase.
**Example**: Cursor indexes your project, retrieving relevant files with 89% accuracy.
```

**"Concept → Analogy → Application"**
```markdown
**Concept**: Tokens are the building blocks LLMs use.
**Analogy**: Like words in a sentence, but optimized for frequency.
**Application**: "Hello World" = 2 tokens, "API" = 1 token, "GPT-4" = 3 tokens.
```

**"What → Why → How"**
```markdown
**What**: Chain-of-thought prompting reveals reasoning steps.
**Why**: Makes AI decisions transparent and debuggable.
**How**: Prefix prompts with "Let's think step by step:"
```

### Patterns to Avoid

**"Feature Listing"** (lacks context)
```markdown
❌ Bad:
- Feature A
- Feature B
- Feature C

✓ Good:
- Feature A: Solves X problem by doing Y
- Feature B: Best for Z scenario because...
```

**"Assume Reader Knowledge"** (no scaffolding)
```markdown
❌ Bad: "Use the embeddings API with semantic search."

✓ Good: "Embeddings convert text to numbers representing meaning.
The API creates these embeddings, which you can then search
semantically (by meaning, not keywords)."
```

## Review Focus Areas

When reviewing specific content types:

**Introductory Material:**
- Does it hook the reader immediately?
- Is prerequisite knowledge clearly stated?
- Are learning objectives explicit?

**Technical Explanations:**
- Is jargon introduced gradually?
- Are code examples executable and well-commented?
- Do diagrams clarify or just decorate?

**Advanced Topics:**
- Is complexity justified (not arbitrary)?
- Are trade-offs and alternatives discussed?
- Do warnings/caveats appear before problems occur?

**Exercises & Examples:**
- Are they realistic (not toy problems)?
- Do they reinforce just-taught concepts?
- Is difficulty appropriate for section placement?

## Resources

### references/editorial-standards.md

Comprehensive style guidelines for educational technical content, including:
- Voice and tone standards
- Formatting conventions
- Code example best practices
- Common writing pitfalls to avoid

Reference this file for detailed standards when conducting reviews.
