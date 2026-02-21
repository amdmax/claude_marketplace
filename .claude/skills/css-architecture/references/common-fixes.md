# Common Stylelint Errors & Solutions

Quick reference for the 15+ most common stylelint errors with explanations and fixes.

---

## 1. Missing Space Before Opening Brace

**Error:**
```
block-opening-brace-space-before: Expected single space before "{"
```

**Problem:**
```css
.card{ /* ❌ No space */
  background: var(--bg-secondary);
}
```

**Solution:**
```css
.card { /* ✓ Space added */
  background: var(--bg-secondary);
}
```

**Auto-fixable:** Yes (`npm run lint:css:fix`)

---

## 2. Missing Space After Colon

**Error:**
```
declaration-colon-space-after: Expected single space after ":"
```

**Problem:**
```css
.card {
  background:var(--bg-secondary); /* ❌ No space after : */
}
```

**Solution:**
```css
.card {
  background: var(--bg-secondary); /* ✓ Space added */
}
```

**Auto-fixable:** Yes

---

## 3. Missing Semicolon

**Error:**
```
declaration-block-trailing-semicolon: Expected semicolon
```

**Problem:**
```css
.card {
  background: var(--bg-secondary) /* ❌ Missing ; */
  padding: var(--space-6);
}
```

**Solution:**
```css
.card {
  background: var(--bg-secondary); /* ✓ Semicolon added */
  padding: var(--space-6);
}
```

**Auto-fixable:** Yes

---

## 4. Duplicate Selectors

**Error:**
```
no-duplicate-selectors: Unexpected duplicate selector ".card"
```

**Problem:**
```css
.card {
  background: var(--bg-secondary);
}

/* ... 50 lines later ... */

.card {
  padding: var(--space-6); /* ❌ Duplicate! */
}
```

**Solution:** Merge into one selector:
```css
.card {
  background: var(--bg-secondary);
  padding: var(--space-6);
}
```

**Auto-fixable:** No (manual merge required)

**Why this matters:** Duplicate selectors cause confusion about which styles apply. Later declarations override earlier ones, making code hard to debug.

---

## 5. Empty Block

**Error:**
```
block-no-empty: Unexpected empty block
```

**Problem:**
```css
.card {
  /* ❌ Empty, no declarations */
}
```

**Solution:** Remove empty rule or add declarations:
```css
/* Option 1: Remove */
/* (delete the rule) */

/* Option 2: Add declarations */
.card {
  background: var(--bg-secondary);
  padding: var(--space-6);
}
```

**Auto-fixable:** No

---

## 6. Unknown Property

**Error:**
```
property-no-unknown: Unexpected unknown property "colour"
```

**Problem:**
```css
.card {
  colour: var(--text-primary); /* ❌ Should be 'color' */
}
```

**Solution:**
```css
.card {
  color: var(--text-primary); /* ✓ Correct spelling */
}
```

**Auto-fixable:** No

**Common typos:**
- `colour` → `color`
- `centre` → `center`
- `grey` → `gray` (in variable names)

---

## 7. Invalid Hex Color

**Error:**
```
color-no-invalid-hex: Unexpected invalid hex color "#gggggg"
```

**Problem:**
```css
.card {
  background: #gggggg; /* ❌ Invalid hex (g is not 0-9 or a-f) */
}
```

**Solution:**
```css
.card {
  background: var(--gray-6); /* ✓ Use variable */
  /* or */
  background: #2e2e33; /* ✓ Valid hex */
}
```

**Auto-fixable:** No

---

## 8. Hex Color Length

**Error:**
```
color-hex-length: Expected short hex notation "#fff" instead of "#ffffff"
```

**Problem:**
```css
.card {
  background: #ffffff; /* ❌ Long notation */
}
```

**Solution:**
```css
.card {
  background: #fff; /* ✓ Short notation */
}
```

**Auto-fixable:** Yes

**Note:** Only applies when short form is possible (e.g., `#ffffff` → `#fff`, but `#f0f0f0` stays long)

---

## 9. Zero Unit

**Error:**
```
length-zero-no-unit: Unexpected unit "px" for zero length
```

**Problem:**
```css
.card {
  margin: 0px; /* ❌ Unit not needed for zero */
}
```

**Solution:**
```css
.card {
  margin: 0; /* ✓ No unit */
}
```

**Auto-fixable:** Yes

---

## 10. Number Leading Zero

**Error:**
```
number-leading-zero: Expected leading zero for ".5"
```

**Problem:**
```css
.card {
  opacity: .5; /* ❌ Missing leading zero */
}
```

**Solution:**
```css
.card {
  opacity: 0.5; /* ✓ Leading zero added */
}
```

**Auto-fixable:** Yes

---

## 11. String Quotes

**Error:**
```
string-quotes: Expected double quotes around string
```

**Problem:**
```css
.card {
  font-family: 'Monaco', 'Menlo'; /* ❌ Single quotes */
}
```

**Solution:**
```css
.card {
  font-family: "Monaco", "Menlo"; /* ✓ Double quotes */
}
```

**Auto-fixable:** Yes

**Note:** stylelint-config-standard prefers double quotes for consistency.

---

## 12. Declaration Block Single Line Max

**Error:**
```
declaration-block-single-line-max-declarations: Expected no more than 1 declaration in single-line block
```

**Problem:**
```css
.card { background: var(--bg-secondary); padding: var(--space-6); } /* ❌ Multiple on one line */
```

**Solution:**
```css
/* Option 1: Multi-line (preferred) */
.card {
  background: var(--bg-secondary);
  padding: var(--space-6);
}

/* Option 2: Single declaration */
.card { background: var(--bg-secondary); }
```

**Auto-fixable:** No

---

## 13. Selector Type No Unknown

**Error:**
```
selector-type-no-unknown: Unexpected unknown type selector "input-button"
```

**Problem:**
```css
input-button { /* ❌ Not a valid HTML element */
  padding: var(--space-3);
}
```

**Solution:**
```css
.input-button { /* ✓ Use class selector */
  padding: var(--space-3);
}

/* Or if targeting <button> inside <input> (rare) */
input button {
  padding: var(--space-3);
}
```

**Auto-fixable:** No

---

## 14. At-Rule Empty Line Before

**Error:**
```
at-rule-empty-line-before: Expected empty line before at-rule
```

**Problem:**
```css
.card {
  padding: var(--space-6);
}
@media (width <= 768px) { /* ❌ No empty line before @media */
  .card {
    padding: var(--space-4);
  }
}
```

**Solution:**
```css
.card {
  padding: var(--space-6);
}

@media (width <= 768px) { /* ✓ Empty line added */
  .card {
    padding: var(--space-4);
  }
}
```

**Auto-fixable:** Yes

---

## 15. Declaration Block Semicolon Newline After

**Error:**
```
declaration-block-semicolon-newline-after: Expected newline after ";"
```

**Problem:**
```css
.card {
  background: var(--bg-secondary); padding: var(--space-6); /* ❌ No newline */
}
```

**Solution:**
```css
.card {
  background: var(--bg-secondary);
  padding: var(--space-6); /* ✓ Newline added */
}
```

**Auto-fixable:** Yes

---

## 16. Indentation

**Error:**
```
indentation: Expected indentation of 2 spaces
```

**Problem:**
```css
.card {
    background: var(--bg-secondary); /* ❌ 4 spaces (or tab) */
}
```

**Solution:**
```css
.card {
  background: var(--bg-secondary); /* ✓ 2 spaces */
}
```

**Auto-fixable:** Yes

---

## 17. Max Empty Lines

**Error:**
```
max-empty-lines: Expected no more than 1 empty line
```

**Problem:**
```css
.card {
  background: var(--bg-secondary);
}


/* ❌ 3 empty lines */

.button {
  padding: var(--space-3);
}
```

**Solution:**
```css
.card {
  background: var(--bg-secondary);
}

/* ✓ 1 empty line */
.button {
  padding: var(--space-3);
}
```

**Auto-fixable:** Yes

---

## 18. No Eol Whitespace

**Error:**
```
no-eol-whitespace: Unexpected whitespace at end of line
```

**Problem:**
```css
.card {
  background: var(--bg-secondary);   /* ❌ Trailing spaces */
}
```

**Solution:**
```css
.card {
  background: var(--bg-secondary); /* ✓ No trailing spaces */
}
```

**Auto-fixable:** Yes

**Note:** Invisible in most editors. Enable "show whitespace" to see.

---

## 19. No Missing End of Source Newline

**Error:**
```
no-missing-end-of-source-newline: Expected newline at end of file
```

**Problem:**
```css
.card {
  background: var(--bg-secondary);
}/* ❌ No newline at end of file */
```

**Solution:**
```css
.card {
  background: var(--bg-secondary);
}
/* ✓ Newline at end (cursor on next line) */
```

**Auto-fixable:** Yes

---

## 20. Selector Pseudo-Class No Unknown

**Error:**
```
selector-pseudo-class-no-unknown: Unexpected unknown pseudo-class selector ":hoverr"
```

**Problem:**
```css
.button:hoverr { /* ❌ Typo */
  background: var(--cyan-10);
}
```

**Solution:**
```css
.button:hover { /* ✓ Correct spelling */
  background: var(--cyan-10);
}
```

**Auto-fixable:** No

**Common typos:**
- `:hoverr` → `:hover`
- `:focuss` → `:focus`
- `:activ` → `:active`

---

## Disabled Rules in This Project

### These errors won't appear (disabled in .stylelintrc.json):

#### selector-class-pattern
**Reason:** Allow flexible naming (BEM, utility classes)

**Would error on:**
```css
.send-button { } /* PascalCase, camelCase patterns */
```

**Allowed in this project:** Any class naming pattern

#### custom-property-pattern
**Reason:** Allow diverse variable naming (semantic + primitive)

**Would error on:**
```css
--bg-primary { } /* Doesn't match a specific pattern */
```

**Allowed in this project:** Any variable naming pattern

#### no-descending-specificity
**Reason:** Allow intentional overrides (theme-specific)

**Would error on:**
```css
.button:hover { } /* More specific */
.button { } /* Less specific after more specific */
```

**Allowed in this project:** Descending specificity for intentional overrides

#### property-no-vendor-prefix / value-no-vendor-prefix
**Reason:** Support older browsers (`-webkit-`)

**Would error on:**
```css
.scrollbar {
  -webkit-overflow-scrolling: touch; /* Vendor prefix */
}
```

**Allowed in this project:** Vendor prefixes for browser support

---

## Quick Fix Workflow

**Step 1: Run lint**
```bash
npm run lint:css
```

**Step 2: Auto-fix what you can**
```bash
npm run lint:css:fix
```

**Step 3: Check remaining errors**
```bash
npm run lint:css
```

**Step 4: Manual fixes**
- Duplicate selectors → Merge
- Empty blocks → Remove or fill
- Unknown properties → Fix typo
- Invalid values → Correct syntax

**Step 5: Verify build**
```bash
npm run build
```

---

## Common Patterns to Avoid

### Pattern 1: Multiple Selectors, One Line
```css
/* ❌ Bad */
.card { background: var(--bg-secondary); padding: var(--space-6); border: 1px solid var(--border-color); }

/* ✓ Good */
.card {
  background: var(--bg-secondary);
  padding: var(--space-6);
  border: 1px solid var(--border-color);
}
```

### Pattern 2: Inconsistent Spacing
```css
/* ❌ Bad */
.card{
  background:var(--bg-secondary);
  padding :var(--space-6);
}

/* ✓ Good */
.card {
  background: var(--bg-secondary);
  padding: var(--space-6);
}
```

### Pattern 3: Mixed Quotes
```css
/* ❌ Bad */
.card {
  font-family: 'Monaco', "Menlo";
}

/* ✓ Good */
.card {
  font-family: "Monaco", "Menlo";
}
```

### Pattern 4: Hard-Coded Values
```css
/* ❌ Bad (not linting error, but bad practice) */
.card {
  background: #18181b;
  padding: 24px;
  color: #eeeeef;
}

/* ✓ Good */
.card {
  background: var(--gray-3);
  padding: var(--space-6);
  color: var(--gray-12);
}
```

---

## Error Severity

**Errors (fail build):**
- Missing semicolons
- Duplicate selectors
- Unknown properties
- Invalid values

**Warnings (don't fail build, but should fix):**
- Spacing issues
- Formatting inconsistencies
- Descending specificity (if enabled)

---

## Debugging Tips

**Tip 1: Check line numbers**
```
src/styles/33-cards.css
  12:3  ✖  Error message
```
Line 12, column 3 is the problem location.

**Tip 2: Use editor extensions**
- VS Code: Stylelint extension (shows errors inline)
- Sublime: SublimeLinter-stylelint
- Vim: ALE with stylelint

**Tip 3: Isolate the problem**
```bash
# Lint specific file
npx stylelint src/styles/33-cards.css
```

**Tip 4: Check config**
```bash
# View active rules
npx stylelint --print-config src/styles/33-cards.css
```

---

## Quick Reference Table

| Error | Auto-Fix | Severity |
|-------|----------|----------|
| Missing space before `{` | Yes | Error |
| Missing space after `:` | Yes | Error |
| Missing semicolon | Yes | Error |
| Duplicate selectors | No | Error |
| Empty block | No | Error |
| Unknown property | No | Error |
| Invalid hex color | No | Error |
| Hex color length | Yes | Warning |
| Zero unit | Yes | Warning |
| Number leading zero | Yes | Warning |
| String quotes | Yes | Warning |
| Single-line max declarations | No | Warning |
| Unknown type selector | No | Error |
| Empty line before at-rule | Yes | Warning |
| Semicolon newline after | Yes | Warning |
| Indentation | Yes | Warning |
| Max empty lines | Yes | Warning |
| EOL whitespace | Yes | Warning |
| Missing end of source newline | Yes | Warning |
| Unknown pseudo-class | No | Error |
