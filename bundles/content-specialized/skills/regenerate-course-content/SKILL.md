---
name: regenerate-course-content
description: Rebuild the course HTML from markdown sources and report what was generated. Useful after content updates to verify the build succeeds and see what changed. Invokable with /regenerate-course-content or /rebuild.
---

# Regenerate Course Content

## Overview

This skill rebuilds the static HTML course site from markdown sources using the TypeScript build system. It runs the build process, reports what was generated, and provides guidance on verification steps.

Use this skill whenever:
- Content markdown files are updated
- Images are added or modified
- Templates or styles change
- You need to verify the build succeeds
- You want a quick summary of what's in the course

## Workflow

### 1. Run the Build

```bash
npm run build
```

**What this does:**
- Converts all markdown files in `content/week_*/` to HTML
- Processes Chart.js charts and Mermaid diagrams
- Minifies CSS and JavaScript assets
- Copies images from `content/week_X/images/` to `output/week_X/images/`
- Validates course structure
- Generates navigation links

**Expected output:**
- Build progress with checkmarks (✓) for each file
- Asset minification reports
- Image copy confirmations (📸)
- Course structure validation
- Final success message with file count

### 2. Parse Build Results

**Extract key information from build output:**

**Success indicators:**
```
✨ Built X HTML files successfully!
```

**Files generated:**
- Count of HTML files created
- Which weeks were processed
- Any validation warnings

**Assets processed:**
- CSS/JS minification results (file size reductions)
- Images copied (with week/path info)
- Logo assets copied

**Validation results:**
- Week structure validation (topics accounted for)
- Any files not listed in index.md (warnings)
- Any structural issues found

### 3. Analyze What Changed

If the user made recent changes, correlate them with build output:

**Recent file changes:**
```bash
# Check what markdown files were recently modified
git status content/
```

**Cross-reference with build:**
- Which HTML files were regenerated from changed markdown
- Which images were copied
- Whether validation passed

### 4. Report Summary

Provide a concise summary to the user:

```markdown
✓ Course rebuilt successfully

**Build Results:**
- **Files Generated:** X HTML files across Y weeks
- **Assets Minified:** Z CSS/JS files (total size reduction: XX%)
- **Images Copied:** N images

**Course Structure:**
- Week 1: X topics
- Week 2: Y topics
- Week 3: Z topics
- Week 4: A topics
- Week 5: B topics
- Week 6: C topics

**Validation:**
- ✓ All weeks validated
- ⚠️ Week X: Files not listed in index.md (will be appended): file1.md, file2.md

**Output Location:** `output/`

**Next Steps:**
- Open `output/index.html` in browser to view
- Or open specific week: `output/week_X/topic.html`
- Verify charts render correctly
- Test theme switcher (light/dark modes)
```

### 5. Handle Build Errors

If the build fails:

**Common errors:**
- TypeScript compilation errors
- Markdown parsing errors
- Missing image references
- Invalid Chart.js/Mermaid syntax

**Error reporting:**
```markdown
❌ Build failed

**Error Output:**
[Show relevant error messages from npm run build]

**Common Causes:**
- Invalid markdown syntax
- Missing image files referenced in markdown
- Malformed chart configuration
- TypeScript errors in build script

**Troubleshooting:**
1. Check the error message for file/line references
2. Verify all image paths exist
3. Validate chart JSON syntax
4. Check markdown formatting
```

### 6. Optional: Open in Browser

**If user wants to view immediately:**

Provide instructions based on platform:

**macOS:**
```bash
open output/index.html
```

**Linux:**
```bash
xdg-open output/index.html
```

**Windows:**
```bash
start output/index.html
```

**Or provide the file path:**
```
File location: file:///Users/.../output/index.html
```

## Verification Checklist

After building, suggest these verification steps:

### Visual Verification
- [ ] **Homepage loads** - `output/index.html` displays correctly
- [ ] **Navigation works** - Links to weeks and topics function
- [ ] **Theme switcher** - Light/dark mode toggles correctly
- [ ] **Charts render** - Chart.js visualizations display
- [ ] **Mermaid diagrams** - Diagrams render correctly
- [ ] **Images display** - All screenshots and images load
- [ ] **Syntax highlighting** - Code blocks have proper colors

### Content Verification
- [ ] **Recent changes appear** - Modified content is updated
- [ ] **New images show** - Recently added images display
- [ ] **Links work** - Internal links navigate correctly
- [ ] **No broken references** - No missing images or broken links

### Technical Verification
- [ ] **Build completed without errors** - No red ❌ messages
- [ ] **All images copied** - Look for "📸 Copied image" messages
- [ ] **Validation passed** - Week structure validated
- [ ] **Assets minified** - CSS/JS size reductions reported

## Build Performance

**Typical build times:**
- Full rebuild: 3-5 seconds
- 44 HTML files (current course size)
- Minification: ~50-70% size reduction for JS files

**Watch mode (optional):**
```bash
npm run dev
```
- Development server with automatic rebuilds on file changes
- Faster incremental builds
- Good for active content development

## Integration with Content Workflow

**Typical workflow:**

1. **Edit markdown content:**
   ```bash
   # Edit course materials
   vim content/week_1/reasoning.md
   ```

2. **Add/update images:**
   ```bash
   # Use /add-image skill or manually move to content/week_X/images/
   ```

3. **Rebuild course:**
   ```bash
   /regenerate-course-content
   ```

4. **Verify in browser:**
   ```bash
   open output/week_1/reasoning.html
   ```

5. **Commit changes:**
   ```bash
   git add content/week_1/reasoning.md
   /commit
   ```

## Build System Details

**Key files:**
- `src/build-html.ts` - Main build script
- `src/templates/` - Eta HTML templates
- `src/markdown-processor.ts` - Markdown-it configuration
- `src/chart-processor.ts` - Chart.js integration
- `src/mermaid-processor.ts` - Mermaid diagram handling

**Build process:**
1. Scans `content/week_*/` for markdown files
2. Validates course structure via `index.md` files
3. Converts markdown → HTML using markdown-it
4. Processes special blocks (```chart, ```mermaid)
5. Applies Eta templates
6. Minifies CSS/JS with lightningcss/esbuild
7. Copies images and assets to output/
8. Generates navigation structure

**Output structure:**
```
output/
├── index.html (homepage)
├── assets/
│   ├── styles.css (minified)
│   ├── *.js (minified)
│   └── logo.png
├── week_1/
│   ├── index.html
│   ├── topic.html
│   └── images/
├── week_2/
│   └── ...
```

## Error Recovery

### Build Fails on Chart Syntax

**Example error:**
```
Error parsing chart in content/week_1/reasoning.md
SyntaxError: Unexpected token
```

**Solution:**
1. Open the file mentioned
2. Find the ```chart block
3. Validate JSON syntax (use JSONLint or IDE)
4. Common issues:
   - Missing commas
   - Trailing commas
   - Unquoted keys
   - String callback functions (must be quoted)

### Missing Image Reference

**Example error:**
```
Warning: Image not found: content/week_5/images/missing.png
```

**Solution:**
1. Check if image file exists
2. Verify path is correct (relative to week directory)
3. Check filename spelling/case
4. Re-add image if deleted accidentally

### TypeScript Compilation Error

**Example error:**
```
src/build-html.ts:123:45 - error TS2339: Property 'foo' does not exist
```

**Solution:**
1. This is a build script error (not content)
2. May need to fix TypeScript code
3. Or restore from git if broken
4. Check recent changes to `src/`

## Best Practices

### When to Rebuild

**Always rebuild after:**
- ✅ Content changes (markdown edits)
- ✅ Adding/updating images
- ✅ Modifying templates or styles
- ✅ Chart or diagram updates

**Don't need to rebuild for:**
- ❌ Infrastructure changes (CDK code)
- ❌ Lambda function changes
- ❌ Git operations
- ❌ Documentation changes (unless they're course content)

### Verification Tips

1. **Check the specific page you changed** - Don't just trust the build succeeded
2. **Test in both themes** - Light and dark mode may render differently
3. **Verify charts** - Some chart updates require hard refresh (Cmd+Shift+R)
4. **Check mobile view** - Large images may have layout issues

### Performance Tips

1. **Use watch mode for active development** - `npm run dev`
2. **Build is fast** - Don't hesitate to rebuild frequently
3. **Git status before building** - Know what you changed

## Troubleshooting

### Issue: "Build succeeds but changes don't appear"

**Cause:** Browser caching

**Solution:**
```bash
# Hard refresh the page
# macOS: Cmd+Shift+R
# Windows/Linux: Ctrl+Shift+R

# Or clear browser cache for file:// URLs
```

### Issue: "Images show in markdown but not HTML"

**Cause:**
- Incorrect path in markdown
- Image not in `content/week_X/images/`
- Build didn't copy image

**Solution:**
1. Check image path in markdown (should be `images/filename.png`)
2. Verify image is in correct `content/week_X/images/` folder
3. Look for "📸 Copied image" message in build output
4. Rebuild with `npm run build`

### Issue: "Charts don't render"

**Cause:**
- Invalid JSON in chart configuration
- Missing Chart.js library
- JavaScript errors

**Solution:**
1. Validate chart JSON syntax
2. Check browser console for errors (F12)
3. Verify chart type is supported
4. Check `options` object structure

### Issue: "Build is slow"

**Cause:**
- Large number of files
- Large images
- Complex charts/diagrams

**Solution:**
- Normal build: 3-5 seconds for ~44 files
- If slower: Check for very large images (>1MB)
- Consider optimizing images before adding

## Summary

The `/regenerate-course-content` skill provides a quick way to:

✅ **Rebuild the course** - Regenerate all HTML from markdown
✅ **Verify build success** - Check for errors and warnings
✅ **See what changed** - Summary of generated files and assets
✅ **Get next steps** - Guidance on verification and testing

Use `/regenerate-course-content` (or `/rebuild`) after content updates to ensure everything builds correctly!
