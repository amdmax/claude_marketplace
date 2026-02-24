# Troubleshooting Guide

Solutions for common CSS issues: styles not applying, theme switching problems, validation errors, and performance issues.

---

## Styles Not Applying

### Issue: New CSS Not Showing in Browser

**Symptom:** You added styles but they don't appear in browser.

**Possible causes and solutions:**

#### 1. Module Not in css-modules.json

**Check:**
```bash
cat css-modules.json
```

**Solution:** Add your module to the manifest:
```json
{
  "modules": [
    "30-media.css",
    "31-forms.css",
    "32-playground.css",
    "33-your-new-module.css"  // Add here
  ]
}
```

**Rebuild:**
```bash
npm run build
```

#### 2. Browser Cache Issue

**Solution:** Hard refresh the browser
- **macOS:** `Cmd + Shift + R`
- **Windows/Linux:** `Ctrl + Shift + R`
- **Alternative:** Open DevTools > Network > Disable cache

#### 3. Build Failed Silently

**Check build output:**
```bash
npm run build
```

**Look for errors:**
```
Error: Module not found: src/styles/33-cards.css
```

**Solution:** Fix the error (typo in filename, missing file, etc.)

#### 4. CSS Syntax Error

**Check for syntax errors:**
```bash
npm run lint:css
```

**Common syntax errors:**
```css
/* Missing semicolon */
.card {
  background: var(--bg-secondary)  /* ❌ Missing ; */
  padding: var(--space-6);
}

/* Missing closing brace */
.card {
  background: var(--bg-secondary);
  /* ❌ Missing } */

/* Invalid property */
.card {
  colour: red; /* ❌ Should be 'color' */
}
```

#### 5. Specificity Issue

**Your styles are overridden by more specific selectors.**

**Check in browser DevTools:**
1. Inspect element
2. Look for crossed-out styles
3. Check which selector is winning

**Solution:** Increase specificity or use `!important` (last resort)
```css
/* Before (too generic) */
.button {
  background: var(--cyan-9);
}

/* After (more specific) */
.chutes-playground .send-button {
  background: var(--cyan-9);
}
```

#### 6. Module Loading Order

**Later modules override earlier ones.**

**Example problem:**
```json
{
  "modules": [
    "31-forms.css",      // Defines .button
    "20-typography.css"  // Overrides .button (wrong order!)
  ]
}
```

**Solution:** Ensure correct layer order:
```json
{
  "modules": [
    "20-typography.css",  // Layer 3: Content
    "31-forms.css"        // Layer 4: Components
  ]
}
```

---

## Theme Switching Problems

### Issue: Colors Don't Change with Theme

**Symptom:** Theme toggle button switches, but some colors stay the same.

#### 1. Hard-Coded Colors

**Problem:**
```css
.card {
  background: #111113; /* ❌ Hard-coded, won't change */
  color: #eeeeef;
}
```

**Solution:** Use CSS variables:
```css
.card {
  background: var(--gray-2); /* ✓ Theme-aware */
  color: var(--gray-12);
}
```

#### 2. Missing Light Theme Override

**Problem:** Variable not overridden in light theme.

**Check `01-theme-light.css`:**
```css
html[data-theme="light"] {
  --gray-2: #f8f9fa; /* ✓ Overridden */
  --gray-3: #f1f3f5;
  /* ❌ Missing --gray-7 override */
}
```

**Solution:** Add missing override:
```css
html[data-theme="light"] {
  --gray-7: #adb5bd; /* ✓ Now overridden */
}
```

#### 3. Component Uses Wrong Variable

**Problem:** Component uses primitive instead of semantic variable.

**Before:**
```css
.card {
  background: var(--gray-2); /* Works but not semantic */
}
```

**Better:**
```css
/* 00-variables.css */
:root {
  --bg-primary: var(--gray-2); /* Semantic mapping */
}

/* Component */
.card {
  background: var(--bg-primary); /* ✓ Semantic, theme-aware */
}
```

#### 4. Theme Attribute Not Applied

**Check in browser DevTools:**
```html
<html data-theme="light">  <!-- Should be present -->
```

**If missing:** Check theme-switcher.js is loaded and working.

#### 5. Cached Styles

**Solution:** Clear browser cache and hard refresh.

---

## Validation Errors

### Issue: Stylelint Reports Errors

#### Error: Duplicate Selectors

**Error message:**
```
src/styles/33-cards.css
  12:3  ✖  Unexpected duplicate selector ".card"  no-duplicate-selectors
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

#### Error: Missing Space Before Opening Brace

**Error message:**
```
25:5  ✖  Expected single space before "{"  block-opening-brace-space-before
```

**Problem:**
```css
.card{ /* ❌ Missing space */
  background: var(--bg-secondary);
}
```

**Solution:**
```css
.card { /* ✓ Space added */
  background: var(--bg-secondary);
}
```

**Auto-fix:**
```bash
npm run lint:css:fix
```

#### Error: Missing Semicolon

**Error message:**
```
10:30  ✖  Expected semicolon  declaration-block-trailing-semicolon
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

#### Error: Descending Specificity

**Error message:**
```
15:1  ✖  Expected selector ".button" to come before ".button:hover"  no-descending-specificity
```

**Note:** This rule is disabled in our config, but if enabled:

**Problem:**
```css
.button:hover {
  background: var(--cyan-10);
}

.button { /* ❌ Less specific after more specific */
  background: var(--cyan-9);
}
```

**Solution:** Reorder selectors:
```css
.button { /* ✓ Base first */
  background: var(--cyan-9);
}

.button:hover { /* ✓ Modifier second */
  background: var(--cyan-10);
}
```

#### Error: Empty Rule

**Error message:**
```
20:1  ✖  Unexpected empty block  block-no-empty
```

**Problem:**
```css
.card {
  /* ❌ Empty, no declarations */
}
```

**Solution:** Remove empty rule or add declarations.

---

## Build Errors

### Issue: Build Fails with Module Not Found

**Error:**
```
Error: Module not found: src/styles/33-cards.css
```

**Causes:**
1. Typo in filename
2. File doesn't exist
3. Wrong path

**Solution:**
```bash
# Check file exists
ls src/styles/33-cards.css

# Check spelling in css-modules.json
cat css-modules.json | grep "33-cards"

# Fix typo or create missing file
```

### Issue: Build Fails with CSS Parse Error

**Error:**
```
Error: Failed to parse CSS
  src/styles/33-cards.css:12:5
```

**Cause:** Syntax error at line 12, column 5.

**Solution:**
```bash
# View file around error line
sed -n '10,15p' src/styles/33-cards.css

# Fix syntax error
# Common issues: missing }, missing ;, invalid property
```

### Issue: Build Succeeds but Output is Broken

**Cause:** Module loaded in wrong order (variables after usage).

**Check css-modules.json order:**
```json
{
  "modules": [
    "00-variables.css",  // Must be first
    "01-theme-light.css",
    "02-reset.css",
    // ... rest in layer order
  ]
}
```

**Solution:** Reorder modules to respect layer dependencies.

---

## Performance Issues

### Issue: Slow Page Load

#### 1. CSS File Too Large

**Check size:**
```bash
ls -lh output/styles.css
```

**If >50KB (minified):**
- Split large modules
- Remove unused styles
- Optimize selectors

#### 2. Too Many Animations

**Symptom:** Page feels sluggish on scroll.

**Solution:** Reduce animation complexity:
```javascript
// gsap-animations.js
// Reduce number of animated elements
gsap.from('.content > p', { /* Animates many paragraphs */ });

// Better: Animate containers instead
gsap.from('.content', { /* Animates one container */ });
```

#### 3. Expensive Selectors

**Problem:**
```css
/* ❌ Expensive: universal + descendant */
* + * {
  margin-top: var(--space-4);
}

/* ❌ Expensive: deep nesting */
.container .sidebar .nav ul li a span {
  color: var(--cyan-9);
}
```

**Solution:** Use simpler selectors:
```css
/* ✓ Specific class */
.nav-link-text {
  color: var(--cyan-9);
}
```

#### 4. Unnecessary Repaints

**Problem:** Animating properties that trigger layout/paint.

**Avoid animating:**
- `width`, `height`
- `top`, `left`, `right`, `bottom`
- `margin`, `padding`
- `border-width`

**Prefer animating:**
- `transform` (translate, scale, rotate)
- `opacity`
- CSS custom properties (for GSAP animations)

**Example:**
```css
/* ❌ Bad: Triggers layout */
.card:hover {
  margin-top: -5px;
}

/* ✓ Good: Uses transform */
.card:hover {
  transform: translateY(-5px);
}
```

---

## GSAP Animation Issues

### Issue: Animations Not Running

#### 1. GSAP Not Loaded

**Check browser console:**
```
GSAP or ScrollTrigger not loaded. Animations disabled.
```

**Solution:** Verify GSAP CDN links in HTML template.

#### 2. Prefers Reduced Motion Active

**Check console:**
```
Animations disabled: prefers-reduced-motion is active
```

**Expected behavior:** Respects user's accessibility preference.

**To test animations:** Disable reduced motion in OS settings.

#### 3. ScrollTrigger Not Refreshing

**Symptom:** Animations fire at wrong scroll positions.

**Cause:** DOM height changes after page load (images, charts load).

**Solution:** Refresh ScrollTrigger:
```javascript
// After content loads
setTimeout(() => {
  ScrollTrigger.refresh();
}, 500);
```

### Issue: Animation CSS Variable Not Working

**Problem:**
```css
h2 {
  --underline-scale: 1; /* GSAP animates this */
}

h2::after {
  transform: scaleX(var(--underline-scale)); /* Not animating */
}
```

**Check:**
1. Variable name matches in CSS and JS
2. GSAP syntax is correct:
```javascript
gsap.from('h2', {
  '--underline-scale': '0', // ✓ String value
  duration: 1.75
});
```

**Fallback for no-animations:**
```css
.no-animations h2::after {
  transform: scaleX(1) !important; /* Skip animation */
}
```

---

## Theme System Issues

### Issue: Theme Toggle Not Working

**Check browser console for errors:**
```javascript
// Look for theme-switcher.js errors
```

**Common issues:**
1. theme-switcher.js not loaded
2. Button selector wrong
3. localStorage blocked (private browsing)

**Debug:**
```javascript
// In browser console
console.log(document.documentElement.getAttribute('data-theme'));
// Should log "dark" or "light"

// Toggle manually
document.documentElement.setAttribute('data-theme', 'light');
```

### Issue: Theme Not Persisting

**Symptom:** Theme resets to dark on page reload.

**Cause:** localStorage not saving theme preference.

**Check:**
```javascript
// Browser console
localStorage.getItem('theme');
// Should return "dark" or "light"
```

**Solution:** Ensure theme-switcher.js saves preference:
```javascript
localStorage.setItem('theme', selectedTheme);
```

---

## Responsive Issues

### Issue: Mobile Layout Broken

#### 1. Viewport Meta Tag Missing

**Check HTML:**
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

**If missing:** Add to HTML template.

#### 2. Breakpoint Not Applied

**Check css-modules.json includes responsive module:**
```json
{
  "modules": [
    // ...
    "41-responsive.css"  // Must be last
  ]
}
```

**Check breakpoint syntax:**
```css
/* ✓ Correct */
@media (width <= 768px) {
  .card { padding: var(--space-4); }
}

/* ❌ Wrong */
@media (max-width: 768px) {
  .card { padding: var(--space-4); }
}
```

#### 3. Fixed Widths Breaking Layout

**Problem:**
```css
.card {
  width: 800px; /* ❌ Fixed, breaks on mobile */
}
```

**Solution:**
```css
.card {
  max-width: 800px; /* ✓ Flexible */
  width: 100%;
}
```

---

## Debugging Checklist

**When styles aren't working:**
- [ ] Module in css-modules.json?
- [ ] Build succeeded without errors?
- [ ] Hard refresh browser (Cmd+Shift+R)?
- [ ] Check browser DevTools > Elements > Styles
- [ ] Run `npm run lint:css` for validation errors
- [ ] Check console for JS errors
- [ ] Verify CSS variables are defined
- [ ] Check specificity in DevTools
- [ ] Test in incognito mode (rules out extensions)

**When animations aren't working:**
- [ ] GSAP loaded? (check console)
- [ ] Prefers reduced motion active? (check console)
- [ ] CSS variables match JS code?
- [ ] ScrollTrigger refreshed after content loads?
- [ ] `.no-animations` fallback styles present?

**When theme switching broken:**
- [ ] theme-switcher.js loaded?
- [ ] `data-theme` attribute present on `<html>`?
- [ ] Light theme overrides in `01-theme-light.css`?
- [ ] Components use CSS variables, not hard-coded colors?
- [ ] localStorage working? (check browser console)

---

## Quick Fixes Reference

| Issue | Quick Fix |
|-------|-----------|
| Styles not applying | Hard refresh: `Cmd+Shift+R` |
| Build failed | `npm run build` and check errors |
| Lint errors | `npm run lint:css:fix` |
| Module not found | Add to `css-modules.json` |
| Theme not switching | Use CSS variables, not hard-coded colors |
| Animations not running | Check console for GSAP errors |
| Mobile broken | Check `41-responsive.css` loaded last |
| Slow performance | Reduce animations, simplify selectors |
| Variables undefined | Check `00-variables.css` loads first |
| Specificity conflict | Inspect in DevTools, increase specificity |
