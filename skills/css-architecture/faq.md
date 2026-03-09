# Frequently Asked Questions

Common questions about the 5-layer architecture, module ordering, and design decisions.

---

## Architecture Questions

### Q: Why 5 layers instead of a simpler structure?

**A:** The 5-layer architecture provides:

1. **Clear separation of concerns**
   - Foundation (tokens) separate from content (typography)
   - Layout separate from components
   - Utilities override everything predictably

2. **Predictable cascade**
   - Variables load before usage
   - Utilities load last to override components
   - No specificity wars

3. **Maintainability**
   - Know exactly where to add styles
   - Easy to find and modify existing styles
   - Scales well as project grows

4. **Team collaboration**
   - Multiple developers can work in different layers
   - Clear conventions reduce conflicts
   - Self-documenting structure

**Visual representation:**

```
┌─────────────────────────────────┐
│ Layer 5: Utilities              │ ← Animations, responsive
├─────────────────────────────────┤
│ Layer 4: Components             │ ← Buttons, cards, forms
├─────────────────────────────────┤
│ Layer 3: Content                │ ← Typography, tables, lists
├─────────────────────────────────┤
│ Layer 2: Layout                 │ ← Header, grid, sidebar
├─────────────────────────────────┤
│ Layer 1: Foundation             │ ← Variables, theme, reset
└─────────────────────────────────┘
```

### Q: Can I use a different architecture pattern?

**A:** You can, but don't mix patterns in this project.

**This project uses:** Layered CSS architecture (custom)

**Alternatives:**
- ITCSS (Inverted Triangle CSS)
- CUBE CSS
- Atomic CSS
- CSS Modules (component-scoped)
- Tailwind (utility-first)

**Stick with the project's pattern** for consistency. Converting would require refactoring all CSS files and the build system.

### Q: Why not use Tailwind or CSS-in-JS?

**A:** Design decisions for this project:

**Why not Tailwind:**
- Educational project demonstrating vanilla CSS architecture
- Want students to learn CSS fundamentals
- Custom design system with theme switching
- Minimal dependencies (no build pipeline complexity)

**Why not CSS-in-JS:**
- Static HTML site (no React/Vue)
- Simpler build process (just concatenate + minify)
- Better caching (styles.css cached separately)
- Easier to inspect and learn from

**When you might choose differently:**
- React app → CSS-in-JS (styled-components, Emotion)
- Rapid prototyping → Tailwind
- Design system → CSS Modules + Storybook

### Q: Why css-modules.json instead of @import?

**A:** Build manifest provides better control:

**css-modules.json approach:**
- Explicit order (prevents accidental reordering)
- Single HTTP request (concatenated bundle)
- Minified output (lightningcss)
- TypeScript-driven build (asset-builder.ts)

**@import approach:**
```css
/* styles.css */
@import "00-variables.css";
@import "01-theme-light.css";
/* ... */
```

**Downsides of @import:**
- Multiple HTTP requests (slower)
- Browser parses imports at runtime
- No build-time validation
- Deprecated in favor of bundlers

---

## Layer-Specific Questions

### Q: When should I add to Layer 1 (Foundation)?

**A:** Add to Layer 1 when defining **design system primitives**.

**Add to 00-variables.css when:**
- Creating new color scale (--purple-8, --purple-9)
- Adding spacing value (--space-14)
- Defining shadow/radius/transition tokens

**Add to 01-theme-light.css when:**
- Overriding primitives for light theme
- Adjusting semantic variables for light mode

**Add to 02-reset.css when:**
- Changing base HTML/body styles
- Modifying box-sizing defaults
- Adjusting global focus styles

**Don't add component styles to Layer 1.** Those belong in Layer 4.

### Q: How do I decide between Layer 3 (Content) and Layer 4 (Components)?

**A:** Ask: "Am I styling a semantic HTML tag or a component class?"

**Layer 3 (Content):** Semantic HTML elements
```css
/* 20-typography.css */
h2 { /* Semantic <h2> tag */ }
p { /* Semantic <p> tag */ }
a { /* Semantic <a> tag */ }

/* 22-tables.css */
table { /* Semantic <table> tag */ }
th { /* Semantic <th> tag */ }
```

**Layer 4 (Components):** Component classes
```css
/* 31-forms.css */
.send-button { /* Component class */ }
.prompt-input { /* Component class */ }

/* 33-cards.css */
.card { /* Component class */ }
.card-header { /* Component class */ }
```

**Exception:** Semantic elements inside components can be styled in either layer:
```css
/* Option A: Layer 3 (if used across many components) */
.content p { }

/* Option B: Layer 4 (if specific to component) */
.card p { }
```

**Prefer Layer 3 for semantic HTML,** Layer 4 for custom classes.

### Q: Why is there no Layer 0?

**A:** Layer 1 is the foundation. There's nothing below it.

**Numbering convention:**
- Layer 1: `0X` prefix (00, 01, 02)
- Layer 2: `1X` prefix (10, 11, 12)
- Layer 3: `2X` prefix (20, 21, 22)
- Layer 4: `3X` prefix (30, 31, 32)
- Layer 5: `4X` prefix (40, 41, 42)

**Starting at 0 provides:**
- Room for 10 modules per layer (0-9)
- Clear visual grouping
- Alphabetical sorting works naturally

---

## Module Ordering Questions

### Q: What happens if I load modules out of order?

**A:** CSS cascade issues and broken styles.

**Example problem:**
```json
{
  "modules": [
    "31-forms.css",      // Uses --cyan-9
    "00-variables.css"   // Defines --cyan-9 (WRONG ORDER!)
  ]
}
```

**Result:**
```css
/* 31-forms.css loads first */
.send-button {
  background: var(--cyan-9); /* ❌ Undefined! Falls back to nothing */
}

/* 00-variables.css loads second */
:root {
  --cyan-9: #00E6A8; /* Defined too late */
}
```

**Always load in layer order:** 1 → 2 → 3 → 4 → 5

### Q: Can I reorder modules within the same layer?

**A:** Yes, if they're independent.

**Safe reordering (no dependencies):**
```json
{
  "modules": [
    "30-media.css",
    "32-playground.css",  // ✓ Can swap with 31-forms.css
    "31-forms.css"        // ✓ No cross-dependencies
  ]
}
```

**Unsafe reordering (dependencies):**
```json
{
  "modules": [
    "01-theme-light.css",  // ❌ Depends on 00-variables.css
    "00-variables.css"     // Must come first!
  ]
}
```

**Rule of thumb:** Keep layer order intact. Only reorder within layer if you're certain there are no dependencies.

### Q: Why do utilities load last?

**A:** Utilities override components predictably.

**Example:**
```css
/* Layer 4: Components */
.card {
  padding: var(--space-6);
}

/* Layer 5: Utilities (responsive) */
@media (width <= 768px) {
  .card {
    padding: var(--space-4); /* ✓ Overrides component */
  }
}
```

**If utilities loaded first:**
```css
/* Layer 5: Utilities (wrong order) */
@media (width <= 768px) {
  .card {
    padding: var(--space-4);
  }
}

/* Layer 4: Components (loaded after) */
.card {
  padding: var(--space-6); /* ❌ Overrides utility! */
}
```

**Result:** Mobile styles don't work.

---

## Variable Questions

### Q: When should I use semantic variables vs. primitives?

**A:** Depends on scope and reusability.

**Use primitives directly:**
```css
.card {
  padding: var(--space-6);        /* ✓ Spacing scale is universal */
  border-radius: var(--radius-md); /* ✓ Radius scale is universal */
  box-shadow: var(--shadow-md);    /* ✓ Shadow scale is universal */
}
```

**Use semantic variables:**
```css
/* For colors (theme-aware) */
.card {
  background: var(--bg-secondary);  /* ✓ Theme-aware */
  color: var(--text-primary);       /* ✓ Theme-aware */
  border: 1px solid var(--border-color); /* ✓ Theme-aware */
}
```

**Create component-specific variables:**
```css
.card {
  --card-padding: var(--space-6);
  --card-bg: var(--bg-secondary);

  padding: var(--card-padding);
  background: var(--card-bg);
}
```

**Why component-specific variables?**
- Easy to override for card variants
- Single source of truth for card styles
- Self-documenting code

### Q: How do I add a new color to the design system?

**A:** Add to `00-variables.css` following the 12-step scale.

**Example: Adding purple accent**
```css
/* 00-variables.css */
:root {
  /* Existing cyan scale... */

  /* Purple accent scale */
  --purple-8: #9333ea;
  --purple-9: #a855f7;  /* Primary purple */
  --purple-10: #c084fc; /* Hover purple */
  --purple-11: #d8b4fe; /* Light purple */
  --purple-12: #e9d5ff; /* Lightest purple */
}
```

**Add light theme overrides:**
```css
/* 01-theme-light.css */
html[data-theme="light"] {
  /* Darker purples for light background */
  --purple-8: #7e22ce;
  --purple-9: #6b21a8;
  --purple-10: #581c87;
  --purple-11: #4c1d95;
  --purple-12: #5b21b6;
}
```

**Use in components:**
```css
.badge-premium {
  background: var(--purple-9);
  color: var(--gray-1);
}
```

### Q: Why do variable names have numbers (--gray-7, --cyan-9)?

**A:** Numbered scales provide consistent gradations.

**Benefits:**
1. **Predictable naming:** --gray-1 (darkest) to --gray-12 (lightest)
2. **Easy to interpolate:** Need something between --gray-7 and --gray-9? Use --gray-8
3. **Theme inversion:** Swap numbers in light theme (--gray-1 becomes lightest)
4. **Industry standard:** Radix Colors, Tailwind use similar scales

**Alternative naming (not used here):**
```css
/* Descriptive names (less scalable) */
--gray-darkest
--gray-darker
--gray-dark
--gray-medium
--gray-light
--gray-lighter
--gray-lightest
```

**Problem with descriptive names:**
- Hard to add more granular steps
- Theme inversion requires renaming
- No clear middle value

---

## Theme Questions

### Q: How does theme switching work?

**A:** JavaScript toggles `data-theme` attribute on `<html>`.

**Flow:**
```
1. User clicks theme toggle button
   ↓
2. JavaScript (theme-switcher.js) toggles data-theme
   ↓
3. CSS detects [data-theme="light"] selector
   ↓
4. Overrides variables in 01-theme-light.css
   ↓
5. Components using variables automatically update
```

**Example:**
```javascript
// theme-switcher.js
document.documentElement.setAttribute('data-theme', 'light');
```

```css
/* 01-theme-light.css */
html[data-theme="light"] {
  --gray-1: #fff;      /* Override dark theme's --gray-1 */
  --gray-12: #0a0a0b;  /* Override dark theme's --gray-12 */
}
```

```css
/* Component automatically adapts */
.card {
  background: var(--gray-2); /* Uses theme-specific value */
}
```

### Q: Can I add a third theme (e.g., high contrast)?

**A:** Yes. Create a new theme file.

**Steps:**

1. **Create theme file:**
```css
/* 03-theme-high-contrast.css */
html[data-theme="high-contrast"] {
  /* High contrast overrides */
  --gray-1: #000;
  --gray-12: #fff;
  --cyan-9: #00ffff;
  /* More aggressive contrast */
}
```

2. **Add to css-modules.json:**
```json
{
  "modules": [
    "00-variables.css",
    "01-theme-light.css",
    "03-theme-high-contrast.css",  // Add here
    "02-reset.css",
    // ...
  ]
}
```

3. **Update theme-switcher.js:**
```javascript
const themes = ['dark', 'light', 'high-contrast'];
// Add toggle logic for 3 themes
```

### Q: Why invert the gray scale instead of creating new variables?

**A:** Reusing primitives makes themes easier to maintain.

**Approach 1: Invert primitives (used in this project)**
```css
/* Dark theme (default) */
--gray-1: #0a0a0b;  /* Dark */
--gray-12: #eeeeef; /* Light */

/* Light theme (inverted) */
html[data-theme="light"] {
  --gray-1: #fff;     /* Light */
  --gray-12: #0a0a0b; /* Dark */
}
```

**Benefit:** Components don't need theme-specific styles.

**Approach 2: Theme-specific variables (not used)**
```css
/* Dark theme */
--bg-dark: #0a0a0b;
--text-dark: #eeeeef;

/* Light theme */
--bg-light: #fff;
--text-light: #0a0a0b;

/* Component needs theme logic */
.card {
  background: var(--bg-dark);
}

[data-theme="light"] .card {
  background: var(--bg-light);
}
```

**Drawback:** Every component needs theme-specific overrides.

---

## Animation Questions

### Q: Why use CSS variables for GSAP animations?

**A:** Clean separation of concerns and better fallbacks.

**Benefits:**

1. **CSS defines appearance:**
```css
h2::after {
  transform: scaleX(var(--underline-scale));
  background: var(--cyan-9);
}
```

2. **JavaScript defines animation:**
```javascript
gsap.from('h2', {
  '--underline-scale': '0',
  duration: 1.75
});
```

3. **Fallback if JS fails:**
```css
h2 {
  --underline-scale: 1; /* Default value (no animation) */
}
```

4. **Accessibility override:**
```css
.no-animations h2::after {
  transform: scaleX(1) !important; /* Skip animation */
}
```

### Q: Why respect prefers-reduced-motion?

**A:** Accessibility requirement for users with vestibular disorders.

**Some users experience:**
- Motion sickness from animations
- Difficulty focusing with movement
- Disorientation from parallax effects

**Implementation:**
```javascript
// gsap-animations.js
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

if (prefersReducedMotion) {
  document.documentElement.classList.add('no-animations');
  return; // Skip all animations
}
```

```css
/* 40-animations.css */
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

**Result:** Users with reduced motion preference see instant transitions.

---

## Build System Questions

### Q: Why concatenate CSS instead of loading separate files?

**A:** Performance optimization.

**Concatenated approach (used):**
```
1 HTTP request → styles.css (19KB minified)
```

**Separate files approach:**
```
15 HTTP requests → 00-variables.css, 01-theme-light.css, ...
```

**Benefits of concatenation:**
- Fewer HTTP requests (faster load)
- Single cache entry
- Minification across entire bundle
- Guaranteed load order

**Trade-off:** Longer build time, but site is static (build once, deploy).

### Q: Can I use CSS preprocessors (Sass, Less)?

**A:** You can, but it adds complexity.

**Current approach (vanilla CSS):**
- CSS custom properties for variables
- Native CSS nesting (modern browsers)
- No build step for CSS (just concatenate + minify)

**If adding Sass:**
1. Install Sass compiler
2. Update build script (asset-builder.ts)
3. Convert .css files to .scss
4. Update css-modules.json to reference .scss files

**Benefit:** Sass features (mixins, functions, loops)

**Drawback:** More dependencies, slower builds, learning curve

**Recommendation:** Stick with vanilla CSS unless you need advanced Sass features.

---

## Maintenance Questions

### Q: How do I know when to split a module?

**A:** When it exceeds ~200 lines or has multiple responsibilities.

**Signs you should split:**
- Module is >200 lines
- Multiple distinct patterns (buttons + forms + checkboxes)
- Hard to find specific styles
- Team members editing same file (merge conflicts)

**Example split:**
```
Before: 31-forms.css (300 lines)
  - Inputs (80 lines)
  - Buttons (120 lines)
  - Checkboxes (100 lines)

After:
  - 31-inputs.css (80 lines)
  - 32-buttons.css (120 lines)
  - 33-checkboxes.css (100 lines)
```

**Update css-modules.json after splitting.**

### Q: How do I deprecate old styles?

**A:** Comment, mark deprecated, remove after verification.

**Step 1: Mark deprecated**
```css
/* 31-forms.css */

/* DEPRECATED: Use .send-button instead */
/* TODO: Remove after June 2026 */
.submit-btn {
  /* Old styles */
}

/* NEW: Replaces .submit-btn */
.send-button {
  /* New styles */
}
```

**Step 2: Update HTML templates**
```html
<!-- Before -->
<button class="submit-btn">Send</button>

<!-- After -->
<button class="send-button">Send</button>
```

**Step 3: Verify no usage**
```bash
grep -r "submit-btn" content/
grep -r "submit-btn" src/
```

**Step 4: Remove deprecated styles**
```css
/* Delete .submit-btn rule */
```

### Q: How do I handle legacy browser support?

**A:** Use vendor prefixes and fallbacks.

**Vendor prefixes (webkit):**
```css
.scrollbar {
  /* Webkit browsers (Safari, Chrome) */
  -webkit-overflow-scrolling: touch;
}

.text {
  /* Webkit text smoothing */
  -webkit-font-smoothing: antialiased;
}
```

**Feature detection:**
```css
/* Modern: CSS custom properties */
.card {
  background: var(--bg-secondary);
}

/* Fallback: Hard-coded color */
.card {
  background: #18181b; /* Fallback for ancient browsers */
  background: var(--bg-secondary); /* Modern override */
}
```

**Stylelint allows vendor prefixes:**
```json
{
  "rules": {
    "property-no-vendor-prefix": null,
    "value-no-vendor-prefix": null
  }
}
```

---

## Quick Reference

**Architecture:**
- 5 layers: Foundation → Layout → Content → Components → Utilities
- Layers defined by purpose, not file count
- Predictable cascade (variables first, utilities last)

**Modules:**
- Prefix by layer (0X, 1X, 2X, 3X, 4X)
- Keep under 200 lines
- Single responsibility
- Update css-modules.json when adding

**Variables:**
- Primitives: Raw tokens (--gray-7, --space-4)
- Semantics: Purpose-driven (--bg-primary, --text-secondary)
- Component-specific: Scoped to component (--card-padding)

**Themes:**
- Invert primitives, not components
- Dark theme = default
- Light theme = overrides in 01-theme-light.css

**Animations:**
- CSS variables + GSAP
- Respect prefers-reduced-motion
- Fallback values if JS disabled

**Build:**
- Concatenate + minify
- Single HTTP request
- Guaranteed load order via css-modules.json
