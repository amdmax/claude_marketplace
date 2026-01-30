# CSS Patterns & Conventions

Naming patterns, CSS variable strategies, GSAP animation integration, theme mapping, and spacing/shadow usage.

---

## CSS Variable Naming Patterns

### Primitive Variables

**Primitives are the raw design tokens** that form the foundation of your design system.

**Gray Scale Pattern:**
```css
/* 00-variables.css */
:root {
  /* 12-step scale from darkest to lightest */
  --gray-1: #0a0a0b;    /* Darkest background */
  --gray-2: #111113;    /* Primary background */
  --gray-3: #18181b;    /* Secondary background */
  --gray-7: #3a3a40;    /* Borders */
  --gray-11: #b4b4bf;   /* Secondary text */
  --gray-12: #eeeeef;   /* Primary text */
}
```

**Naming convention:**
- `--{color}-{step}` where step is 1-12
- Lower numbers = darker (dark theme)
- Higher numbers = lighter (dark theme)
- Inverted in light theme

**Accent Color Pattern:**
```css
:root {
  /* Brand accent (cyan/turquoise) */
  --cyan-8: #00BF8A;
  --cyan-9: #00E6A8;   /* Primary accent */
  --cyan-10: #1AE6B0;  /* Hover accent */
  --cyan-11: #4DE6BD;  /* Links */
  --cyan-12: #80E6CA;  /* Lightest accent */
}
```

**Semantic Colors Pattern:**
```css
:root {
  /* Status colors */
  --green-9: #22c55e;  /* Success */
  --yellow-9: #eab308; /* Warning */
  --red-9: #ef4444;    /* Error */
}
```

**Spacing Pattern (8px Grid):**
```css
:root {
  /* Spacing follows 8px base unit */
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-3: 0.75rem;  /* 12px */
  --space-4: 1rem;     /* 16px */
  --space-6: 1.5rem;   /* 24px */
  --space-8: 2rem;     /* 32px */
  --space-12: 3rem;    /* 48px */
  --space-16: 4rem;    /* 64px */
}
```

**Typography Scale Pattern (Fluid):**
```css
:root {
  /* Fluid typography using clamp() */
  --text-xs: clamp(0.75rem, 0.7rem + 0.25vw, 0.875rem);
  --text-sm: clamp(0.875rem, 0.8rem + 0.375vw, 1rem);
  --text-base: clamp(1rem, 0.95rem + 0.25vw, 1.125rem);
  --text-lg: clamp(1.125rem, 1rem + 0.625vw, 1.25rem);
  --text-xl: clamp(1.25rem, 1.1rem + 0.75vw, 1.5rem);
  --text-2xl: clamp(1.5rem, 1.3rem + 1vw, 1.875rem);
  --text-3xl: clamp(1.875rem, 1.5rem + 1.875vw, 2.25rem);
  --text-4xl: clamp(2.25rem, 1.75rem + 2.5vw, 3rem);
}
```

**Benefits of clamp():**
- Responsive without media queries
- Smooth scaling between min and max sizes
- Formula: `clamp(min, preferred, max)`

**Shadow Pattern:**
```css
:root {
  /* Shadows sized xs to xl */
  --shadow-xs: 0 1px 2px 0 rgb(0 0 0 / 40%);
  --shadow-sm: 0 2px 4px -1px rgb(0 0 0 / 50%);
  --shadow-md: 0 4px 6px -2px rgb(0 0 0 / 60%);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 70%);
  --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 80%);
}
```

**Transition Pattern:**
```css
:root {
  /* Duration + easing combined */
  --transition-fast: 100ms cubic-bezier(0.4, 0, 0.2, 1);
  --transition-base: 200ms cubic-bezier(0.4, 0, 0.2, 1);
  --transition-slow: 300ms cubic-bezier(0.4, 0, 0.2, 1);
}
```

**Border Radius Pattern:**
```css
:root {
  /* Size scale for rounded corners */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
}
```

---

## Semantic Variables

**Semantic variables map primitive tokens to component-specific purposes.**

**Background Mapping:**
```css
/* 00-variables.css */
:root {
  /* Semantic backgrounds */
  --bg-primary: var(--gray-2);     /* Main container background */
  --bg-secondary: var(--gray-3);   /* Secondary container background */
}
```

**Text Color Mapping:**
```css
:root {
  /* Semantic text colors */
  --text-primary: var(--gray-12);   /* Main text */
  --text-secondary: var(--gray-11); /* Muted text */
}
```

**Border Mapping:**
```css
:root {
  /* Semantic borders */
  --border-color: var(--gray-7);
}
```

**Accent Mapping:**
```css
:root {
  /* Semantic accent */
  --accent-color: var(--cyan-9);
}
```

**Layout-Specific Variables:**
```css
:root {
  /* Header/sidebar backgrounds with transparency */
  --header-bg: rgb(24 24 27 / 95%);
  --sidebar-bg: rgb(24 24 27 / 80%);

  /* Layout constraints */
  --content-max-width: 1200px;
}
```

**Component-Specific Variables:**
```css
/* 33-cards.css (example) */
.card {
  /* Component-level semantic variables */
  --card-padding: var(--space-6);
  --card-border-radius: var(--radius-md);
  --card-bg: var(--bg-secondary);

  padding: var(--card-padding);
  border-radius: var(--card-border-radius);
  background: var(--card-bg);
}
```

**Why Semantic Variables?**
- **Clarity:** Purpose-driven names (--bg-primary vs --gray-2)
- **Flexibility:** Change primitive mapping without editing components
- **Theme Support:** Easy to override for light/dark themes
- **Maintainability:** Single source of truth for color roles

---

## Class Naming Patterns

### BEM-Inspired Component Classes

**Block-Element-Modifier pattern (loosely applied):**

**Block (component):**
```css
.card { /* Block */ }
.modal { /* Block */ }
.playground { /* Block */ }
```

**Element (part of block):**
```css
.card-header { /* Element of card */ }
.card-title { /* Element of card */ }
.card-description { /* Element of card */ }

.modal-overlay { /* Element of modal */ }
.modal-content { /* Element of modal */ }
.modal-close { /* Element of modal */ }
```

**Modifier (variant):**
```css
.button { /* Base */ }
.button-primary { /* Modifier */ }
.button-secondary { /* Modifier */ }
```

**Real examples from codebase:**
```css
/* Playground component */
.chutes-playground { }
.playground-controls { }
.playground-input { }
.playground-output { }

/* Form components */
.model-selector { }
.prompt-input { }
.send-button { }
.clear-button { }
```

### Naming Conventions

**Use kebab-case for all classes:**
```css
/* Good */
.card-header { }
.model-selector { }
.youtube-container { }

/* Bad */
.cardHeader { }
.modelSelector { }
.YouTubeContainer { }
```

**Descriptive names over generic:**
```css
/* Good - specific purpose */
.send-button { }
.prompt-input { }

/* Bad - too generic */
.btn { }
.input { }
```

**Avoid presentational names:**
```css
/* Good - semantic */
.card-title { }
.text-secondary { }

/* Bad - presentational */
.big-text { }
.blue-box { }
```

---

## GSAP Animation Integration

### CSS Variables for Animation

**GSAP animates CSS custom properties for performance and flexibility.**

**H2/H3 Underline Animation:**
```css
/* 20-typography.css */
h2 {
  --underline-scale: 1; /* GSAP animation property */
  position: relative;
}

h2::after {
  content: '';
  display: block;
  height: 2px;
  background: var(--cyan-9);
  margin-top: var(--space-2);
  transform: scaleX(var(--underline-scale)); /* Animated via GSAP */
  transform-origin: left;
}
```

**JavaScript side (gsap-animations.js):**
```javascript
// Animates --underline-scale from 0 to 1
gsap.from('h2', {
  scrollTrigger: {
    trigger: 'h2',
    start: 'top 85%',
    once: true
  },
  '--underline-scale': '0',
  duration: 1.75,
  ease: 'power2.out'
});
```

**Blockquote Border Animation:**
```css
/* 21-code.css */
blockquote {
  --border-width: 4px; /* GSAP animation property */
  border-left: var(--border-width) solid var(--cyan-9);
  transition: border-width var(--transition-base);
}
```

**JavaScript side:**
```javascript
gsap.from('blockquote', {
  scrollTrigger: {
    trigger: 'blockquote',
    start: 'top 85%',
    once: true
  },
  '--border-width': '0px',
  duration: 1.75,
  ease: 'power2.out'
});
```

**Code Block Accent Animation:**
```css
/* 21-code.css */
pre {
  --accent-scale: 1; /* GSAP animation property */
  position: relative;
}

pre::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: var(--cyan-9);
  transform: scaleX(var(--accent-scale));
  transform-origin: left;
}
```

**List Marker Animation:**
```css
/* 23-lists.css */
li::marker {
  --marker-opacity: 1; /* GSAP animation property */
  color: var(--cyan-9);
  opacity: var(--marker-opacity);
}
```

**JavaScript side:**
```javascript
gsap.from('ul, ol', {
  scrollTrigger: {
    trigger: 'ul, ol',
    start: 'top 85%',
    once: true
  },
  '--marker-opacity': '0',
  duration: 1.4
});
```

### Pattern: CSS Variable + GSAP

**Benefits:**
1. **Clean separation:** CSS defines appearance, JS defines animation
2. **Performance:** CSS custom properties are highly optimized
3. **Fallback:** Variables have default values if JS doesn't load
4. **Accessibility:** `.no-animations` class can override

**Accessibility Override:**
```css
/* 40-animations.css */
.no-animations h2::after {
  transform: scaleX(1) !important; /* Skip animation */
}

.no-animations blockquote {
  border-left-width: 4px !important; /* Skip animation */
}
```

**When user prefers reduced motion:**
```javascript
// gsap-animations.js
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

if (prefersReducedMotion) {
  document.documentElement.classList.add('no-animations');
  return; // Skip GSAP animations
}
```

---

## Theme Mapping Strategy

### Primitive Inversion (Layer 1)

**Dark theme (default):**
```css
/* 00-variables.css */
:root {
  --gray-1: #0a0a0b;  /* Darkest */
  --gray-12: #eeeeef; /* Lightest */
}
```

**Light theme (inverted):**
```css
/* 01-theme-light.css */
html[data-theme="light"] {
  --gray-1: #fff;     /* Lightest */
  --gray-12: #0a0a0b; /* Darkest */
}
```

**Result:** Components using `--gray-1` and `--gray-12` automatically adapt.

### Semantic Variable Approach

**Define semantic variables once:**
```css
/* 00-variables.css */
:root {
  --bg-primary: var(--gray-2);
  --text-primary: var(--gray-12);
}
```

**Override primitives per theme:**
```css
/* Dark theme (default in 00-variables.css) */
--gray-2: #111113; /* Dark background */
--gray-12: #eeeeef; /* Light text */

/* Light theme (01-theme-light.css) */
html[data-theme="light"] {
  --gray-2: #f8f9fa; /* Light background */
  --gray-12: #0a0a0b; /* Dark text */
}
```

**Component uses semantic variable:**
```css
.card {
  background: var(--bg-primary); /* Automatically theme-aware */
  color: var(--text-primary);
}
```

### Component-Specific Theme Overrides

**When component needs special treatment:**
```css
/* 31-forms.css */
.clear-button {
  background: var(--gray-2);
  border: 1px solid var(--gray-6);
}

/* Dark theme needs special hover */
[data-theme="dark"] .clear-button:hover {
  background: var(--gray-6);
  border-color: var(--gray-8);
}
```

**Use sparingly:** Prefer semantic variable approach for maintainability.

---

## Spacing Usage Patterns

### Consistent Spacing Grid

**Use spacing scale for all margins/padding:**
```css
/* Good - uses spacing scale */
.card {
  padding: var(--space-6);
  margin-bottom: var(--space-4);
  gap: var(--space-3);
}

/* Bad - magic numbers */
.card {
  padding: 24px;
  margin-bottom: 18px;
  gap: 13px;
}
```

### Spacing Scale Guidelines

**Small spacing (1-3):**
- UI element gaps (icon + text)
- Tight layouts
- Inline spacing

```css
.icon-with-text {
  gap: var(--space-2); /* 8px */
}
```

**Medium spacing (4-6):**
- Component padding
- Element margins
- List item spacing

```css
.card {
  padding: var(--space-6); /* 24px */
  margin-bottom: var(--space-4); /* 16px */
}
```

**Large spacing (8-16):**
- Section spacing
- Major layout gaps
- Vertical rhythm

```css
h2 {
  margin-top: var(--space-12); /* 48px */
  margin-bottom: var(--space-5); /* 20px */
}
```

---

## Shadow Usage Patterns

### Shadow Scale Guidelines

**Extra Small (xs):**
- Subtle depth
- Form inputs
- Minor elevation

```css
.input {
  box-shadow: var(--shadow-xs);
}
```

**Small (sm):**
- Button hover states
- Slight elevation
- Interactive elements

```css
.button:hover {
  box-shadow: var(--shadow-sm);
}
```

**Medium (md):**
- Cards
- Dropdowns
- Modals

```css
.card {
  box-shadow: var(--shadow-md);
}
```

**Large (lg):**
- Major containers
- Popovers
- Overlays

```css
.modal-overlay {
  box-shadow: var(--shadow-lg);
}
```

**Extra Large (xl):**
- Hero sections
- Full-screen modals
- Major UI overlays

```css
.modal-content {
  box-shadow: var(--shadow-xl);
}
```

### Theme-Specific Shadows

**Dark theme needs stronger shadows:**
```css
/* 00-variables.css */
:root {
  --shadow-md: 0 4px 6px -2px rgb(0 0 0 / 60%); /* Darker */
}
```

**Light theme uses softer shadows:**
```css
/* 01-theme-light.css */
html[data-theme="light"] {
  --shadow-md: 0 4px 6px -2px rgb(0 0 0 / 15%); /* Softer */
}
```

---

## Transition Patterns

### Standard Transitions

**Fast transitions (100ms):**
- Hover states
- Focus indicators
- Quick feedback

```css
a {
  transition: color var(--transition-fast);
}
```

**Base transitions (200ms):**
- Button interactions
- Theme switching
- Standard UI feedback

```css
.button {
  transition: all var(--transition-base);
}
```

**Slow transitions (300ms):**
- Complex animations
- Layout shifts
- Delayed feedback

```css
.modal {
  transition: opacity var(--transition-slow);
}
```

### Property-Specific Transitions

**Better performance:**
```css
/* Good - animates specific properties */
.button {
  transition:
    background var(--transition-base),
    box-shadow var(--transition-base),
    transform var(--transition-base);
}

/* Avoid - animates all properties */
.button {
  transition: all var(--transition-base);
}
```

---

## Quick Reference: Pattern Checklist

**When adding styles:**
- [ ] Use CSS variables, not hard-coded values
- [ ] Follow spacing scale (8px grid)
- [ ] Use semantic variables for colors
- [ ] Add GSAP animation variables if animating
- [ ] Use BEM-inspired naming (block-element)
- [ ] Test theme switching (dark/light)
- [ ] Use appropriate shadow scale
- [ ] Use transition timing constants

**Common mistakes:**
- ❌ Hard-coded colors: `color: #00E6A8` → Use `color: var(--cyan-9)`
- ❌ Magic numbers: `padding: 23px` → Use `padding: var(--space-6)`
- ❌ Generic names: `.btn` → Use `.send-button`
- ❌ Missing theme support: Only works in dark mode
