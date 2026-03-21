---
name: add-content-image
description: Automatically process and add the most recent screenshot from src/images to the appropriate course materials. Analyzes the image content, determines the correct week and topic, moves the file, and adds properly sized markdown references. Invokable with /add-content-image or /add-image.
---

# Add Content Image

## Overview

This skill automates the process of integrating new screenshots into course materials. It identifies the most recent image in `src/images/`, analyzes its content to determine relevance, moves it to the appropriate week folder, and adds properly formatted markdown references with optimized sizing.

## Workflow

### 1. Find Most Recent Image

```bash
# Locate the newest image in src/images/
ls -lt src/images/ | head -2
```

**Actions:**
- Identify the most recently added image file
- Note the filename and timestamp
- Prepare to read and analyze the image

### 2. Analyze Image Content

**Read the image** using the Read tool to visually understand:
- What tool or platform is shown (CodeRabbit, Claude Code, GitHub, etc.)
- What feature or concept is demonstrated
- What specific topic it relates to (code review, testing, workflows, etc.)
- Any visible text, UI elements, or diagrams

**Key Questions:**
- What is the primary subject of this screenshot?
- Which course week does this relate to? (Week 1-6)
- Which specific topic/section would benefit from this visual?
- Is this a UI demonstration, workflow diagram, or example output?

### 3. Determine Placement

**Course Structure:**
- **Week 1**: Introduction, Tokens, Context Window, Prompt Engineering, Reasoning, Fine-tuning, Agents
- **Week 2**: Philosophy, Cursor, Claude Code, Kilo, Planning Modes, MCP, Essential MCP Servers
- **Week 3**: Methodologies (No Method, Spec-Driven, BMAD), Anti-Patterns, Context Management
- **Week 4**: (Content TBD)
- **Week 5**: Observability, Cost Management, Large Codebases, AI Code Review, Team Collaboration, Local LLM
- **Week 6**: Agent Skills, Frontend, Hooks, Multi-Agent Orchestration, Workflows

**Decision Process:**
1. Match image content to course topics
2. Identify the most relevant markdown file (e.g., `ai-code-review.md`, `cursor.md`)
3. Read the target markdown file
4. Find the best section to insert the image

### 4. Create Descriptive Filename

**Naming Convention:**
```
{tool-name}-{feature-or-concept}.png
```

**Examples:**
- `coderabbit-review-example.png` (CodeRabbit PR review)
- `cursor-inline-editing.png` (Cursor's inline edit feature)
- `claude-code-planning-mode.png` (Claude Code planning interface)
- `github-copilot-suggestions.png` (Copilot autocomplete)

**Guidelines:**
- Lowercase, hyphen-separated
- Descriptive and specific
- Indicate tool and feature shown
- Keep under 50 characters

### 5. Move Image to Target Location

```bash
# Move and rename image
mv "src/images/Screenshot YYYY-MM-DD at HH.MM.SS.png" \
   content/week_X/images/{descriptive-name}.png
```

**Ensure:**
- Target `content/week_X/images/` directory exists
- Filename follows naming convention
- Original file is removed from `src/images/`

### 6. Determine Image Sizing

**Default sizes based on content type:**

**Full-width examples** (workflow diagrams, dashboards, comprehensive UIs):
```markdown
![Description](images/filename.png)
```
*No size specified = full content width*

**Large screenshots** (tool interfaces, detailed examples):
```markdown
<img src="images/filename.png" alt="Description" width="800">
```
*800px width for detailed visibility while maintaining readability*

**Medium screenshots** (specific features, code snippets with UI):
```markdown
<img src="images/filename.png" alt="Description" width="600">
```
*600px width for feature demonstrations*

**Small screenshots** (UI elements, buttons, small dialogs):
```markdown
<img src="images/filename.png" alt="Description" width="400">
```
*400px width for focused UI elements*

**Sizing Guidelines:**
- **Full-width**: Complex diagrams, workflow visualizations, multi-panel screenshots
- **800px**: Full application interfaces, comprehensive examples
- **600px**: Single feature demonstrations, code review comments, settings panels
- **400px**: Small UI elements, individual buttons, compact dialogs
- Consider the information density: more detail = larger size

### 7. Add Markdown Reference

**Read the target markdown file** and identify the optimal insertion point:
- After introducing the tool/concept
- Before or after a related explanation
- In an "Example" or "Visual Guide" section

**Insertion format:**

**For full-width or large images:**
```markdown
**Example: {Tool Name Feature}**:

![Descriptive Alt Text](images/filename.png)

*Caption explaining what the image shows and why it's relevant.*
```

**For medium/small images:**
```markdown
**Example: {Tool Name Feature}**:

<img src="images/filename.png" alt="Descriptive Alt Text" width="600">

*Caption explaining what the image shows and why it's relevant.*
```

**Caption Guidelines:**
- Explain what the screenshot demonstrates
- Highlight key elements to notice
- Connect to surrounding text
- Keep to 1-2 sentences

### 8. Rebuild HTML

After adding the image reference:

```bash
npm run build
```

**Verify:**
- Build completes successfully
- Image is copied to output directory (look for "📸 Copied image" message)
- No broken image references

### 9. Report Results

Provide a summary to the user:

```markdown
✓ Image added to Week X materials

**Image:** {descriptive-name}.png
**Location:** content/week_X/images/
**Added to:** content/week_X/{topic}.md (line XXX)
**Size:** {width}px (or full-width)
**Section:** "{Section Name}"

**Analysis:**
- **Depicts:** {what the screenshot shows}
- **Relevance:** {why it fits this topic}

You can view it at: output/week_X/{topic}.html
```

## Analysis Best Practices

### Visual Analysis Checklist

When analyzing the screenshot, systematically identify:

**Tool Identification:**
- Look for logos, branding, distinctive UI elements
- Check for tool names in headers, titles, or URLs
- Identify platform (GitHub, IDE, CLI, web interface)

**Feature/Concept:**
- What functionality is being demonstrated?
- What workflow or process is shown?
- What problem does this solve?

**Content Quality:**
- Is the screenshot clear and readable?
- Does it show a complete, coherent example?
- Are there any sensitive data or credentials visible? (reject if yes)

**Educational Value:**
- What concept does this reinforce?
- How does it complement the text content?
- Will it help students understand the topic better?

### Placement Decision Tree

```
1. Does this show a specific tool?
   Yes → Which tool? → Find tool's dedicated section
   No → Proceed to #2

2. Does this show a workflow or process?
   Yes → Which week covers this process? → Find workflow section
   No → Proceed to #3

3. Does this show a code review, testing, or quality concept?
   Yes → Week 5 (AI Code Review, Team Collaboration, etc.)
   No → Proceed to #4

4. Does this show agent/automation features?
   Yes → Week 6 (Agent Skills, Workflows, etc.)
   No → Proceed to #5

5. Does this show development environment setup?
   Yes → Week 2 (Cursor, Claude Code, MCP)
   No → Ask user for clarification
```

### Sizing Decision Criteria

**Consider these factors:**

**Information Density:**
- High density (lots of text, UI panels, data) → Larger (800px or full-width)
- Medium density (single panel, feature) → Medium (600px)
- Low density (button, small UI element) → Smaller (400px)

**Readability Requirements:**
- Text must be readable → Size up if text is small
- Code snippets must be legible → Prefer 600-800px
- Diagrams with connections → Full-width or 800px

**Page Context:**
- Is this the primary visual for the section? → Larger
- Is this a supplementary example? → Medium
- Is this one of several examples? → Smaller

**Aspect Ratio:**
- Wide screenshots (16:9, panoramic) → Consider full-width
- Tall screenshots (vertical) → May need width constraint (600-800px)
- Square screenshots → Usually work well at 600px

## Common Scenarios

### Scenario 1: Code Review Screenshot

**Example:** CodeRabbit PR review interface

**Analysis:**
- Tool: CodeRabbit
- Topic: AI Code Review
- Week: 5
- File: `ai-code-review.md`

**Actions:**
1. Rename: `coderabbit-pr-review-interface.png`
2. Move to: `content/week_5/images/`
3. Find "CodeRabbit" section in `ai-code-review.md`
4. Size: 800px (detailed interface with multiple panels)
5. Add after tool description

### Scenario 2: IDE Feature Screenshot

**Example:** Cursor inline code editing

**Analysis:**
- Tool: Cursor
- Topic: Cursor IDE features
- Week: 2
- File: `cursor.md`

**Actions:**
1. Rename: `cursor-inline-editing.png`
2. Move to: `content/week_2/images/`
3. Find "Inline Editing" or "Features" section in `cursor.md`
4. Size: 600px (single feature demonstration)
5. Add in relevant feature section

### Scenario 3: CLI Output Screenshot

**Example:** Claude Code terminal output

**Analysis:**
- Tool: Claude Code
- Topic: CLI usage
- Week: 2
- File: `claude-code.md`

**Actions:**
1. Rename: `claude-code-terminal-output.png`
2. Move to: `content/week_2/images/`
3. Find "Usage" or "Examples" section
4. Size: Full-width (terminal output benefits from width)
5. Add in examples section

## Error Handling

### No Recent Images

If `src/images/` is empty:
```
No images found in src/images/. Please add a screenshot to process.
```

### Unable to Determine Topic

If the image content is unclear or doesn't match course topics:
```
⚠️ Unable to automatically determine the best location for this image.

**Image analyzed:** {filename}
**Content observed:** {description of what was seen}

**Suggested action:** Please specify which week and topic this relates to:
- Week number (1-6)
- Topic/markdown file name
```

### Security/Privacy Concerns

If sensitive information is visible:
```
❌ This screenshot contains potentially sensitive information:
- API keys, tokens, or credentials
- Personal information
- Internal URLs or infrastructure details

Please crop or redact the sensitive areas before adding to course materials.
```

## Integration Notes

### Build System Integration

The HTML builder automatically:
- Detects image references in markdown
- Copies images from `content/week_X/images/` to `output/week_X/images/`
- Preserves relative paths
- Reports copied images: "📸 Copied image: week_X/images/filename.png"

**No additional configuration needed** - just add markdown references and rebuild.

### Image Format Support

**Supported formats:**
- PNG (preferred for screenshots)
- JPG/JPEG (acceptable, but PNG preferred for UI screenshots)
- GIF (for animations)

**Recommendations:**
- PNG for screenshots with text (lossless)
- JPG for photos or images without text
- Keep file sizes reasonable (<500KB if possible)

## Tips for Best Results

1. **Always analyze before placing** - Don't guess the topic, read the image
2. **Check existing images** - Ensure you're not duplicating content
3. **Read the target markdown** - Find the perfect insertion point
4. **Write descriptive captions** - Explain what to notice in the image
5. **Verify the build** - Always rebuild and check for the "📸 Copied image" message
6. **Consider mobile** - Large images (800px+) may need scrolling on mobile
7. **Maintain consistency** - Use similar sizing for similar types of screenshots in the same document
