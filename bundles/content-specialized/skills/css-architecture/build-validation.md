# Build & Validation

Understanding the build system, validation tools, and quality enforcement.

---

## How css-modules.json Works

The `css-modules.json` file is the **build manifest**. It defines:
1. **Module order:** Sequential load order for concatenation
2. **Cascade dependencies:** Variables load before usage
3. **Build input:** Which files to include in the final bundle

**Structure:**
```json
{
  "modules": [
    "00-variables.css",    // Must load first (defines primitives)
    "01-theme-light.css",  // Must load after variables
    "02-reset.css",        // Base styles
    "10-header.css",       // Layout layer
    "11-layout.css",
    "12-scrollbar.css",
    "20-typography.css",   // Content layer
    "21-code.css",
    "22-tables.css",
    "23-lists.css",
    "30-media.css",        // Components layer
    "31-forms.css",
    "32-playground.css",
    "40-animations.css",   // Utilities layer
    "41-responsive.css"    // Utilities (responsive overrides)
  ]
}
```

### Why Order Matters

**CSS cascade rules:**
1. Variables must be defined before usage
2. Later rules override earlier rules (same specificity)
3. Utilities should load last to override components

**Example dependency:**
```css
/* 00-variables.css - Must load first */
:root {
  --cyan-9: #00E6A8;
}

/* 31-forms.css - Uses variable defined above */
.send-button {
  background: var(--cyan-9); /* Depends on 00-variables.css */
}
```

**If modules load out of order:**
```css
/* 31-forms.css loads BEFORE 00-variables.css */
.send-button {
  background: var(--cyan-9); /* ❌ Undefined! */
}
```

### Safe vs. Unsafe Reordering

**Safe (independent modules within layer):**
```json
{
  "modules": [
    "30-media.css",
    "32-playground.css",  // ✓ Can swap with 31-forms.css
    "31-forms.css"        // ✓ If they don't depend on each other
  ]
}
```

**Unsafe (layer reordering):**
```json
{
  "modules": [
    "20-typography.css",
    "00-variables.css"  // ❌ Variables load after usage!
  ]
}
```

**Never reorder without understanding dependencies.**

---

## Build Process

The build process is handled by `src/builders/asset-builder.ts`.

### Build Flow

```
1. Read css-modules.json
   ↓
2. Resolve file paths (src/styles/{module}.css)
   ↓
3. Read each module's content
   ↓
4. Concatenate in order
   ↓
5. Minify with lightningcss
   ↓
6. Write to output/styles.css
```

### Build Script Details

**Location:** `src/builders/asset-builder.ts`

**Key steps:**
1. **Read manifest:** Parse `css-modules.json`
2. **Concatenate:** Combine modules sequentially
3. **Minify:** Use `lightningcss` for compression
4. **Output:** Write to `output/styles.css`

**Compression stats:**
- Source (concatenated): ~28KB
- Minified: ~19KB
- Compression: 30.6%

### Build Commands

**Standard build:**
```bash
npm run build
```
- Builds HTML and CSS
- Minifies CSS
- Outputs to `output/` directory

**Watch mode (auto-rebuild):**
```bash
npm run dev
```
- Watches for file changes
- Auto-rebuilds on save
- Useful during development

**Clean output:**
```bash
npm run clean
```
- Deletes `output/` directory
- Recreates empty `output/` folder
- Useful for fresh builds

---

## npm Scripts

### Linting Scripts

**Check for errors:**
```bash
npm run lint:css
```
- Runs `stylelint 'src/styles/**/*.css'`
- Reports errors and warnings
- Does not modify files
- Exit code 1 if errors found

**Auto-fix issues:**
```bash
npm run lint:css:fix
```
- Runs `stylelint 'src/styles/**/*.css' --fix`
- Automatically fixes formatting issues
- Reports unfixable errors
- Modifies files in-place

**What gets auto-fixed:**
- Missing spaces (before `{`, after `:`)
- Extra blank lines
- Hex color case (lowercase preferred)
- Zero units (removes `px` from `0px`)
- Indentation

**What requires manual fixing:**
- Duplicate selectors
- Descending specificity issues
- Invalid property values
- Missing semicolons
- Syntax errors

### Building Scripts

**Full build:**
```bash
npm run build
```
- Runs `tsx src/build-html.ts`
- Builds HTML from markdown
- Builds CSS from modules
- Minifies assets

**Development mode:**
```bash
npm run dev
```
- Runs build in watch mode
- Auto-rebuilds on file changes
- Does not minify (faster builds)

### Testing Scripts

**Run all tests:**
```bash
npm run test
```
- Tests links, charts, diagrams, YouTube embeds
- Validates HTML output
- Checks for broken references

**Test specific features:**
```bash
npm run test:charts    # Chart.js validation
npm run test:diagrams  # Mermaid diagram validation
npm run test:youtube   # YouTube embed validation
```

---

## Pre-Commit Hook Behavior

### How It Works

The project uses **git pre-commit hooks** to enforce code quality.

**Hook location:** `.git/hooks/pre-commit`

**What it does:**
1. Runs `npm run lint:css` before commit
2. Checks for CSS validation errors
3. **Blocks commit** if errors exist
4. Allows commit if no errors

### When Hook Blocks Commit

**Example scenario:**
```bash
$ git commit -m "Add card component"

Running pre-commit hook...
✖ npm run lint:css

src/styles/33-cards.css
  12:3  ✖  Unexpected duplicate selector ".card"

✖ 1 error found
❌ Pre-commit hook failed. Commit blocked.
```

### How to Fix When Blocked

**Step 1: Read the error**
```
src/styles/33-cards.css
  12:3  ✖  Unexpected duplicate selector ".card"
```
- File: `src/styles/33-cards.css`
- Line: 12, column 3
- Issue: Duplicate `.card` selector

**Step 2: Fix the issue**
```css
/* Before (wrong) - two .card selectors */
.card {
  background: var(--bg-secondary);
}

.card {
  padding: var(--space-6);
}

/* After (correct) - merged into one */
.card {
  background: var(--bg-secondary);
  padding: var(--space-6);
}
```

**Step 3: Auto-fix if possible**
```bash
npm run lint:css:fix
```

**Step 4: Re-stage fixed files**
```bash
git add src/styles/33-cards.css
```

**Step 5: Retry commit**
```bash
git commit -m "Add card component"
```

### Bypassing the Hook (Not Recommended)

**When you might need to bypass:**
- Emergency hotfix (with plan to fix later)
- WIP commit (work-in-progress, not for production)
- Known validation issue being addressed separately

**How to bypass:**
```bash
git commit --no-verify -m "WIP: Card component (fix validation later)"
```

**Important:** Only bypass when you understand the risk. Invalid CSS can break the site.

---

## CI Validation

### GitHub Actions Workflow

The project validates CSS on every pull request.

**Workflow file:** `.github/workflows/validate.yml` (example)

**What CI checks:**
1. CSS validation (`npm run lint:css`)
2. Build succeeds (`npm run build`)
3. Tests pass (`npm run test:ci`)

### CI Workflow Steps

```
1. Checkout code
   ↓
2. Install dependencies (npm install)
   ↓
3. Run lint:css
   ↓
4. Run build
   ↓
5. Run tests
   ↓
6. Report results
```

**If any step fails:**
- ❌ PR cannot merge
- Developer notified via GitHub
- Must fix errors and push updates

**If all steps pass:**
- ✅ PR can be merged
- Code quality verified
- Safe to deploy

### Benefits of CI Validation

**Prevents bad code from entering main branch:**
- Catches errors before deployment
- Enforces consistent code quality
- Reduces production bugs

**Automated enforcement:**
- No manual review required for style issues
- Reduces reviewer burden
- Consistent standards across team

**Fast feedback:**
- Developers notified within minutes
- Can fix issues immediately
- Reduces context switching

---

## Stylelint Configuration

### Config File

**Location:** `.stylelintrc.json`

**Contents:**
```json
{
  "extends": "stylelint-config-standard",
  "rules": {
    "selector-class-pattern": null,
    "custom-property-pattern": null,
    "declaration-block-no-redundant-longhand-properties": null,
    "no-descending-specificity": null,
    "property-no-vendor-prefix": null,
    "value-no-vendor-prefix": null,
    "selector-pseudo-class-no-unknown": [
      true,
      { "ignorePseudoClasses": ["global"] }
    ]
  }
}
```

### Extends: stylelint-config-standard

**What it includes:**
- Formatting rules (spaces, newlines, indentation)
- Best practices (no duplicates, valid properties)
- CSS syntax validation

**Example rules from standard:**
- `block-opening-brace-space-before`: Require space before `{`
- `color-hex-length`: Prefer short hex codes (`#fff` not `#ffffff`)
- `length-zero-no-unit`: No unit for zero (`0` not `0px`)
- `no-duplicate-selectors`: Prevent duplicate selectors in same file

### Custom Rule Overrides

**Why rules are disabled:**

| Rule | Disabled | Reason |
|------|----------|--------|
| `selector-class-pattern` | ✓ | Allow flexible naming (BEM, utility classes) |
| `custom-property-pattern` | ✓ | Allow diverse variable naming (semantic + primitive) |
| `declaration-block-no-redundant-longhand-properties` | ✓ | Prefer explicit properties for clarity |
| `no-descending-specificity` | ✓ | Allow intentional overrides (theme-specific) |
| `property-no-vendor-prefix` | ✓ | Support older browsers (`-webkit-`) |
| `value-no-vendor-prefix` | ✓ | Support older browsers (`-webkit-`) |

**Example: Why `no-descending-specificity` is disabled**

```css
/* This would fail with no-descending-specificity */
.button {
  background: var(--gray-9); /* More specific than .button:hover */
}

.button:hover {
  background: var(--cyan-9); /* Less specific, but intentional */
}

/* But this pattern is intentional and valid */
```

### Enabled Rules (From Standard)

**Formatting:**
- Consistent spacing (before `{`, after `:`)
- Proper indentation (2 spaces)
- Newlines between rules
- Trailing semicolons

**Best Practices:**
- No duplicate selectors
- No empty rules
- Valid property names
- Valid values

**Syntax:**
- Valid selectors
- Proper nesting
- Correct at-rule usage

---

## Validation Workflow

### Development Cycle

```
1. Edit CSS file
   ↓
2. Save file
   ↓
3. Run npm run lint:css:fix (optional, recommended)
   ↓
4. Run npm run build
   ↓
5. Test in browser
   ↓
6. Git commit (pre-commit hook validates)
   ↓
7. Git push
   ↓
8. GitHub Actions validates
   ↓
9. PR review
   ↓
10. Merge to main
```

### When to Validate

**During development:**
- Before committing (pre-commit hook does this automatically)
- After adding new styles
- After modifying existing styles

**Before pull request:**
- Run `npm run lint:css` manually
- Fix all errors
- Run `npm run build` to verify
- Test in browser

**In CI (automatic):**
- On every push to PR
- On every commit to main
- Nightly builds (optional)

### Quick Validation Commands

**Check for errors:**
```bash
npm run lint:css
```

**Fix auto-fixable errors:**
```bash
npm run lint:css:fix
```

**Verify build works:**
```bash
npm run build
```

**Full validation (lint + build + test):**
```bash
npm run lint:css && npm run build && npm run test
```

---

## Troubleshooting Build Issues

### Build Fails: Module Not Found

**Error:**
```
Error: Module not found: src/styles/33-cards.css
```

**Cause:** Module in `css-modules.json` doesn't exist.

**Solution:**
1. Check filename spelling in `css-modules.json`
2. Create missing module file
3. Remove module from manifest if no longer needed

### Build Fails: CSS Syntax Error

**Error:**
```
Error: Failed to parse CSS
  src/styles/33-cards.css:12:5
```

**Cause:** Invalid CSS syntax (missing semicolon, invalid property, etc.)

**Solution:**
1. Run `npm run lint:css` to find errors
2. Fix syntax errors
3. Rebuild

### Build Succeeds, But Styles Not Applying

**Cause:** Module not in `css-modules.json`, or loaded in wrong order.

**Solution:**
1. Check `css-modules.json` includes your module
2. Verify module order (variables first, utilities last)
3. Hard refresh browser (Cmd+Shift+R)

### Lint Fails: Too Many Errors

**Scenario:** After major changes, lint reports hundreds of errors.

**Solution:**
1. Run `npm run lint:css:fix` (fixes most formatting issues)
2. Review remaining errors
3. Fix manually or selectively disable rules
4. Re-run `npm run lint:css`

**Example selective disable:**
```css
/* stylelint-disable-next-line no-descending-specificity */
.button:hover {
  /* Intentional specificity override */
}
```

---

## Summary

**Key validation tools:**
- `npm run lint:css` - Check for errors
- `npm run lint:css:fix` - Auto-fix issues
- `npm run build` - Verify build works
- Pre-commit hook - Enforces validation
- GitHub Actions - CI validation

**Validation workflow:**
1. Edit CSS
2. Auto-fix (`npm run lint:css:fix`)
3. Build (`npm run build`)
4. Test in browser
5. Commit (hook validates)
6. Push (CI validates)

**Remember:** Validation catches errors early, before they reach production.
