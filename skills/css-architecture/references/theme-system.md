# Theme System Reference

Theme switching mechanics, adding variables, creating new themes, and theme-aware patterns.

---

## Theme Architecture

### How Theme Switching Works

**Flow:**
```
1. User clicks theme toggle button
   ↓
2. theme-switcher.js toggles data-theme attribute
   ↓
3. Browser detects [data-theme="light"] selector
   ↓
4. CSS overrides variables in 01-theme-light.css
   ↓
5. Components using variables automatically update
   ↓
6. Preference saved to localStorage
```

**JavaScript (theme-switcher.js):**
```javascript
// Get current theme
const currentTheme = document.documentElement.getAttribute('data-theme');

// Toggle theme
const newTheme = currentTheme === 'dark' ? 'light' : 'dark';

// Apply theme
document.documentElement.setAttribute('data-theme', newTheme);

// Save preference
localStorage.setItem('theme', newTheme);
```

**CSS (01-theme-light.css):**
```css
/* Overrides apply when data-theme="light" */
html[data-theme="light"] {
  --gray-1: #fff;
  --gray-12: #0a0a0b;
  /* ... more overrides */
}
```

**Component (automatic adaptation):**
```css
.card {
  background: var(--gray-2); /* Uses theme-specific value */
  color: var(--gray-12);
}
```

---

## Default Theme (Dark)

### Location: 00-variables.css

**Dark theme is the default** (no attribute required).

**Key characteristics:**
- Dark backgrounds (--gray-1 to --gray-6)
- Light text (--gray-11, --gray-12)
- Bright accents (--cyan-9, --cyan-10)
- Strong shadows (higher opacity)

**Color philosophy:**
```css
:root {
  /* Backgrounds: Dark shades */
  --gray-1: #0a0a0b;   /* Darkest background */
  --gray-2: #111113;   /* Primary background */
  --gray-3: #18181b;   /* Secondary background */

  /* Text: Light shades */
  --gray-11: #b4b4bf;  /* Secondary text */
  --gray-12: #eeeeef;  /* Primary text */

  /* Accents: Bright cyan */
  --cyan-9: #00E6A8;   /* Primary accent */
  --cyan-10: #1AE6B0;  /* Hover accent */
}
```

---

## Light Theme Overrides

### Location: 01-theme-light.css

**Strategy: Invert the gray scale**

**Dark theme:**
- --gray-1 = darkest
- --gray-12 = lightest

**Light theme:**
- --gray-1 = lightest
- --gray-12 = darkest

**Full override set:**
```css
html[data-theme="light"] {
  /* Gray Scale - Inverted */
  --gray-1: #fff;      /* Lightest background (was darkest) */
  --gray-2: #f8f9fa;   /* Primary background */
  --gray-3: #f1f3f5;   /* Secondary background */
  --gray-4: #e9ecef;   /* Tertiary background */
  --gray-5: #dee2e6;   /* Hover background */
  --gray-6: #ced4da;   /* Active background */
  --gray-7: #adb5bd;   /* Borders */
  --gray-8: #868e96;   /* Borders (hover) */
  --gray-9: #495057;   /* Solid backgrounds */
  --gray-10: #343a40;  /* Muted text */
  --gray-11: #212529;  /* Secondary text (was light, now dark) */
  --gray-12: #0a0a0b;  /* Primary text (was light, now dark) */

  /* Accent Colors - Darker for contrast */
  --cyan-8: #0d9488;
  --cyan-9: #0f766e;   /* Primary accent (darker) */
  --cyan-10: #115e59;  /* Hover accent */
  --cyan-11: #134e4a;  /* Link text */
  --cyan-12: #0f766e;

  /* Semantic Colors - Darker variants */
  --green-9: #16a34a;  /* Success (darker) */
  --yellow-9: #ca8a04; /* Warning (darker) */
  --red-9: #dc2626;    /* Error (darker) */

  /* Shadows - Softer for light backgrounds */
  --shadow-xs: 0 1px 2px 0 rgb(0 0 0 / 5%);   /* 40% → 5% */
  --shadow-sm: 0 2px 4px -1px rgb(0 0 0 / 10%); /* 50% → 10% */
  --shadow-md: 0 4px 6px -2px rgb(0 0 0 / 15%); /* 60% → 15% */
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 20%); /* 70% → 20% */
  --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 25%); /* 80% → 25% */

  /* Layout backgrounds */
  --header-bg: rgb(248 249 250 / 95%);  /* Light with transparency */
  --sidebar-bg: rgb(248 249 250 / 80%);
}
```

---

## Adding Theme-Aware Variables

### Strategy 1: Primitive Override (Recommended)

**Add primitive to 00-variables.css:**
```css
/* 00-variables.css */
:root {
  --purple-9: #a855f7; /* Dark theme value */
}
```

**Add light theme override to 01-theme-light.css:**
```css
/* 01-theme-light.css */
html[data-theme="light"] {
  --purple-9: #7e22ce; /* Light theme value (darker) */
}
```

**Use in component:**
```css
.badge-premium {
  background: var(--purple-9); /* Automatically theme-aware */
}
```

### Strategy 2: Semantic Variable (Most Flexible)

**Define semantic variable in 00-variables.css:**
```css
/* 00-variables.css */
:root {
  /* Primitives */
  --purple-9: #a855f7;
  --purple-10: #c084fc;

  /* Semantic mapping */
  --badge-bg: var(--purple-9);
  --badge-text: var(--gray-1);
}
```

**Override in light theme if needed:**
```css
/* 01-theme-light.css */
html[data-theme="light"] {
  --purple-9: #7e22ce; /* Primitive changes */
  /* Semantic variable automatically adapts */
}
```

**Use in component:**
```css
.badge {
  background: var(--badge-bg);
  color: var(--badge-text);
}
```

### Strategy 3: Component-Specific Override (Rare)

**Use when component needs special treatment in light theme:**
```css
/* 33-cards.css */
.card {
  background: var(--bg-secondary);
}

/* Special override for light theme */
[data-theme="light"] .card {
  background: var(--gray-1);
  box-shadow: var(--shadow-sm);
  border: 1px solid var(--gray-5);
}
```

**When to use:**
- Component has unique light theme requirements
- Can't be solved by primitive overrides
- Need to add properties that don't exist in dark theme

---

## Creating Additional Themes

### Example: High Contrast Theme

**Step 1: Create theme file**
```css
/* 03-theme-high-contrast.css */
html[data-theme="high-contrast"] {
  /* Extreme contrast */
  --gray-1: #000;      /* Pure black */
  --gray-12: #fff;     /* Pure white */
  --gray-7: #fff;      /* White borders */

  /* Brighter accents */
  --cyan-9: #00ffff;   /* Maximum cyan */

  /* No shadows (reduce distraction) */
  --shadow-xs: none;
  --shadow-sm: none;
  --shadow-md: none;
  --shadow-lg: none;
  --shadow-xl: none;

  /* Stronger borders */
  --border-color: #fff;
}
```

**Step 2: Add to css-modules.json**
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

**Step 3: Update theme-switcher.js**
```javascript
const themes = ['dark', 'light', 'high-contrast'];
let currentIndex = themes.indexOf(currentTheme);
currentIndex = (currentIndex + 1) % themes.length;
const newTheme = themes[currentIndex];
```

### Example: Sepia Theme

**Warm, low-contrast theme for reading:**
```css
/* 04-theme-sepia.css */
html[data-theme="sepia"] {
  /* Warm backgrounds */
  --gray-1: #f4ecd8;   /* Cream background */
  --gray-2: #ede4cf;   /* Slightly darker cream */
  --gray-3: #e5dcc3;

  /* Warm text */
  --gray-11: #5b4e3b;  /* Brown text */
  --gray-12: #3c3022;  /* Dark brown */

  /* Warm accent */
  --cyan-9: #c17817;   /* Amber accent */
  --cyan-10: #d38d1f;

  /* Soft shadows */
  --shadow-md: 0 4px 6px -2px rgb(60 48 34 / 20%);
}
```

---

## Theme-Aware Component Patterns

### Pattern 1: Auto-Adapting Components

**Component uses only CSS variables:**
```css
.card {
  background: var(--bg-secondary);
  color: var(--text-primary);
  border: 1px solid var(--border-color);
}
```

**Result:** Works in all themes automatically.

### Pattern 2: Conditional Overrides

**Different behavior per theme:**
```css
/* Base (dark theme) */
.button {
  background: var(--cyan-9);
  box-shadow: var(--shadow-sm);
}

/* Light theme: Add border */
[data-theme="light"] .button {
  border: 1px solid var(--cyan-10);
}

/* High contrast: Remove shadow */
[data-theme="high-contrast"] .button {
  box-shadow: none;
  border: 2px solid var(--cyan-9);
}
```

### Pattern 3: Theme-Specific Classes

**Different component variants per theme:**
```css
.card {
  background: var(--bg-secondary);
}

/* Dark theme: Glass effect */
[data-theme="dark"] .card-glass {
  backdrop-filter: var(--blur-md);
  background: rgb(24 24 27 / 80%);
}

/* Light theme: Elevated card */
[data-theme="light"] .card-glass {
  box-shadow: var(--shadow-lg);
  background: var(--gray-1);
}
```

---

## Testing Theme Switching

### Manual Testing

**Checklist:**
- [ ] Click theme toggle button
- [ ] All colors invert properly
- [ ] Text remains readable (sufficient contrast)
- [ ] Borders visible in both themes
- [ ] Shadows appropriate for theme
- [ ] Accents stand out
- [ ] No hard-coded colors breaking theme
- [ ] Images/logos work in both themes
- [ ] Charts update colors (if using Chart.js)

### Browser DevTools

**Force theme state:**
```css
/* In DevTools > Elements > Add attribute */
data-theme="light"
data-theme="dark"
```

**Check computed styles:**
```javascript
// In DevTools console
getComputedStyle(document.documentElement).getPropertyValue('--gray-1');
// Should return different values per theme
```

### Accessibility Testing

**Check contrast ratios:**
- WCAG AA: 4.5:1 (normal text), 3:1 (large text)
- WCAG AAA: 7:1 (normal text), 4.5:1 (large text)

**Tools:**
- Chrome DevTools > Elements > Styles > Color picker (shows contrast ratio)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Contrast Ratio Calculator](https://contrast-ratio.com/)

---

## Persistence & Loading

### localStorage Strategy

**Save theme preference:**
```javascript
localStorage.setItem('theme', newTheme);
```

**Load on page load:**
```javascript
// On page load (before styles render)
const savedTheme = localStorage.getItem('theme') || 'dark';
document.documentElement.setAttribute('data-theme', savedTheme);
```

**Prevent Flash of Unstyled Content (FOUC):**
```javascript
// Execute immediately in <head>, before body renders
<script>
  (function() {
    const theme = localStorage.getItem('theme') || 'dark';
    document.documentElement.setAttribute('data-theme', theme);
  })();
</script>
```

### Respect System Preference

**Detect OS theme preference:**
```javascript
const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
const defaultTheme = prefersDark ? 'dark' : 'light';

// Use saved theme, or fall back to system preference
const theme = localStorage.getItem('theme') || defaultTheme;
```

**Listen for system changes:**
```javascript
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
  if (!localStorage.getItem('theme')) {
    // User hasn't set preference, follow system
    const newTheme = e.matches ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', newTheme);
  }
});
```

---

## Chart.js Theme Integration

### Update Charts on Theme Change

**chart-theme.js pattern:**
```javascript
function updateChartTheme(chart, theme) {
  const isDark = theme === 'dark';

  chart.options.scales.x.ticks.color = isDark ? '#b4b4bf' : '#212529';
  chart.options.scales.y.ticks.color = isDark ? '#b4b4bf' : '#212529';
  chart.options.scales.x.grid.color = isDark ? '#3a3a40' : '#adb5bd';
  chart.options.scales.y.grid.color = isDark ? '#3a3a40' : '#adb5bd';

  chart.update();
}

// Listen for theme changes
document.addEventListener('themechange', (e) => {
  const charts = Chart.instances;
  charts.forEach((chart) => updateChartTheme(chart, e.detail.theme));
});
```

---

## Common Theme Issues

### Issue 1: Hard-Coded Colors

**Problem:**
```css
.card {
  background: #111113; /* ❌ Won't change with theme */
}
```

**Solution:**
```css
.card {
  background: var(--gray-2); /* ✓ Theme-aware */
}
```

### Issue 2: Insufficient Contrast

**Problem:**
```css
/* Light theme */
--text-secondary: #adb5bd; /* Too light on white background */
```

**Solution:**
```css
/* Light theme */
--text-secondary: #495057; /* Darker for better contrast */
```

### Issue 3: Missing Override

**Problem:**
```css
/* 00-variables.css */
--purple-9: #a855f7;

/* 01-theme-light.css */
/* ❌ Forgot to override --purple-9 */
```

**Result:** Purple is too light in light theme.

**Solution:**
```css
/* 01-theme-light.css */
html[data-theme="light"] {
  --purple-9: #7e22ce; /* ✓ Darker for light background */
}
```

### Issue 4: Theme Flash on Load

**Problem:** Page loads with default theme, then switches.

**Solution:** Set theme in `<head>` before body renders:
```html
<head>
  <script>
    const theme = localStorage.getItem('theme') || 'dark';
    document.documentElement.setAttribute('data-theme', theme);
  </script>
  <link rel="stylesheet" href="styles.css">
</head>
```

---

## Best Practices

### 1. Use CSS Variables Exclusively

**Never hard-code colors:**
```css
/* ❌ Bad */
.card {
  background: #18181b;
  color: #eeeeef;
}

/* ✓ Good */
.card {
  background: var(--gray-3);
  color: var(--gray-12);
}
```

### 2. Test Both Themes

**Always verify:**
- Components render correctly in both themes
- Text is readable (contrast)
- Borders are visible
- Accents stand out

### 3. Prefer Semantic Variables

**Better maintainability:**
```css
/* ✓ Good - semantic */
.card {
  background: var(--bg-secondary);
  color: var(--text-primary);
}

/* ❌ Okay but less flexible */
.card {
  background: var(--gray-3);
  color: var(--gray-12);
}
```

### 4. Override Primitives, Not Components

**Centralize theme logic:**
```css
/* ✓ Good - override primitive */
html[data-theme="light"] {
  --gray-3: #f1f3f5;
  /* All components using --gray-3 automatically adapt */
}

/* ❌ Bad - override every component */
[data-theme="light"] .card { background: #f1f3f5; }
[data-theme="light"] .sidebar { background: #f1f3f5; }
[data-theme="light"] .header { background: #f1f3f5; }
```

### 5. Document Theme-Specific Behavior

**Comment special cases:**
```css
/* Dark theme: Needs extra border for visibility */
[data-theme="dark"] .card {
  border: 1px solid var(--gray-7);
}

/* Light theme: Shadow provides depth */
[data-theme="light"] .card {
  border: none;
  box-shadow: var(--shadow-md);
}
```

---

## Quick Reference

**Theme mechanics:**
- Default: Dark (no attribute)
- Toggle: Change `data-theme` attribute on `<html>`
- Persist: Save to localStorage
- Override: CSS variables in theme files

**File structure:**
- `00-variables.css` - Dark theme (default)
- `01-theme-light.css` - Light theme overrides
- `0X-theme-*.css` - Additional themes

**Strategies:**
1. Primitive override (change --gray-1, etc.)
2. Semantic variable (change --bg-primary, etc.)
3. Component override (special theme behavior)

**Testing:**
- Toggle theme and verify all components
- Check contrast ratios (WCAG AA/AAA)
- Test on real devices (color rendering varies)
- Verify no hard-coded colors
