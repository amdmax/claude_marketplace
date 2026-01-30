# CSS Variable Naming Conventions

Comprehensive guide to variable naming strategies, patterns, and best practices.

---

## Variable Types

### 1. Primitive Variables

**Definition:** Raw design tokens that form the foundation of the design system.

**Location:** `00-variables.css` (Layer 1)

**Purpose:** Reusable across entire project, theme-aware, system-level values.

---

## Color Variables

### Gray Scale (12-Step)

**Pattern:** `--gray-{step}` where step is 1-12

**Dark theme (default):**
```css
:root {
  --gray-1: #0a0a0b;   /* Step 1: Darkest - background (pitch black) */
  --gray-2: #111113;   /* Step 2: Primary background */
  --gray-3: #18181b;   /* Step 3: Secondary background (cards) */
  --gray-4: #1f1f23;   /* Step 4: Tertiary background */
  --gray-5: #27272a;   /* Step 5: Hover background */
  --gray-6: #2e2e33;   /* Step 6: Active background */
  --gray-7: #3a3a40;   /* Step 7: Borders (primary) */
  --gray-8: #48484f;   /* Step 8: Borders (hover) */
  --gray-9: #5a5a63;   /* Step 9: Solid backgrounds */
  --gray-10: #6e6e79;  /* Step 10: Muted text */
  --gray-11: #b4b4bf;  /* Step 11: Secondary text */
  --gray-12: #eeeeef;  /* Step 12: Lightest - primary text */
}
```

**Light theme (inverted):**
```css
html[data-theme="light"] {
  --gray-1: #fff;      /* Step 1: Lightest - background (white) */
  --gray-2: #f8f9fa;   /* Step 2: Primary background */
  --gray-3: #f1f3f5;   /* Step 3: Secondary background */
  --gray-4: #e9ecef;   /* Step 4: Tertiary background */
  --gray-5: #dee2e6;   /* Step 5: Hover background */
  --gray-6: #ced4da;   /* Step 6: Active background */
  --gray-7: #adb5bd;   /* Step 7: Borders (primary) */
  --gray-8: #868e96;   /* Step 8: Borders (hover) */
  --gray-9: #495057;   /* Step 9: Solid backgrounds */
  --gray-10: #343a40;  /* Step 10: Muted text */
  --gray-11: #212529;  /* Step 11: Secondary text */
  --gray-12: #0a0a0b;  /* Step 12: Darkest - primary text */
}
```

**Usage guidelines:**
- **1-3:** Backgrounds (darkest to lighter)
- **4-6:** Interactive backgrounds (hover, active)
- **7-8:** Borders and dividers
- **9:** Solid UI elements
- **10-12:** Text colors (muted to primary)

### Accent Colors (Cyan Brand)

**Pattern:** `--cyan-{step}` where step is 8-12

**Dark theme:**
```css
:root {
  --cyan-8: #00BF8A;   /* Step 8: Darker accent */
  --cyan-9: #00E6A8;   /* Step 9: Primary accent (buttons, links) */
  --cyan-10: #1AE6B0;  /* Step 10: Hover accent */
  --cyan-11: #4DE6BD;  /* Step 11: Link text */
  --cyan-12: #80E6CA;  /* Step 12: Lightest accent */
}
```

**Light theme (darker for contrast):**
```css
html[data-theme="light"] {
  --cyan-8: #0d9488;   /* Darker for light background */
  --cyan-9: #0f766e;   /* Primary accent */
  --cyan-10: #115e59;  /* Hover accent */
  --cyan-11: #134e4a;  /* Link text */
  --cyan-12: #0f766e;  /* Lightest accent */
}
```

**Usage guidelines:**
- **--cyan-9:** Primary actions (buttons, active states)
- **--cyan-10:** Hover states
- **--cyan-11:** Link text, secondary accents
- **--cyan-12:** Light accent highlights

### Semantic Colors

**Pattern:** `--{color}-9` (single step for each semantic color)

```css
:root {
  /* Success */
  --green-9: #22c55e;

  /* Warning */
  --yellow-9: #eab308;

  /* Error/Danger */
  --red-9: #ef4444;
}
```

**Light theme adjustments:**
```css
html[data-theme="light"] {
  --green-9: #16a34a;   /* Darker green */
  --yellow-9: #ca8a04;  /* Darker yellow */
  --red-9: #dc2626;     /* Darker red */
}
```

**Usage:**
```css
.alert-success {
  border-left: 3px solid var(--green-9);
}

.alert-warning {
  color: var(--yellow-9);
}

.alert-error {
  background: var(--red-9);
}
```

---

## Spacing Variables

### Pattern: 8px Grid System

**Formula:** `--space-{number}` where number × 4px = actual size

```css
:root {
  /* Spacing scale (8px base unit) */
  --space-1: 0.25rem;  /* 4px  - 1 × 4px */
  --space-2: 0.5rem;   /* 8px  - 2 × 4px */
  --space-3: 0.75rem;  /* 12px - 3 × 4px */
  --space-4: 1rem;     /* 16px - 4 × 4px */
  --space-5: 1.25rem;  /* 20px - 5 × 4px */
  --space-6: 1.5rem;   /* 24px - 6 × 4px */
  --space-8: 2rem;     /* 32px - 8 × 4px */
  --space-10: 2.5rem;  /* 40px - 10 × 4px */
  --space-12: 3rem;    /* 48px - 12 × 4px */
  --space-16: 4rem;    /* 64px - 16 × 4px */
}
```

**Usage guidelines:**
- **1-2:** Small gaps (icon spacing, inline elements)
- **3-4:** Component padding, element margins
- **5-6:** Section padding, card spacing
- **8-10:** Layout gaps, major component spacing
- **12-16:** Section margins, large layout gaps

**Why 8px grid?**
- Divisible by 2 (easy scaling)
- Works well for typography (16px base)
- Industry standard (Material Design, iOS HIG)
- Easier to maintain consistency

---

## Typography Variables

### Font Sizes (Fluid Typography)

**Pattern:** `--text-{size}` using `clamp(min, preferred, max)`

```css
:root {
  /* Fluid typography - responsive without media queries */
  --text-xs: clamp(0.75rem, 0.7rem + 0.25vw, 0.875rem);      /* 12px - 14px */
  --text-sm: clamp(0.875rem, 0.8rem + 0.375vw, 1rem);        /* 14px - 16px */
  --text-base: clamp(1rem, 0.95rem + 0.25vw, 1.125rem);      /* 16px - 18px */
  --text-lg: clamp(1.125rem, 1rem + 0.625vw, 1.25rem);       /* 18px - 20px */
  --text-xl: clamp(1.25rem, 1.1rem + 0.75vw, 1.5rem);        /* 20px - 24px */
  --text-2xl: clamp(1.5rem, 1.3rem + 1vw, 1.875rem);         /* 24px - 30px */
  --text-3xl: clamp(1.875rem, 1.5rem + 1.875vw, 2.25rem);    /* 30px - 36px */
  --text-4xl: clamp(2.25rem, 1.75rem + 2.5vw, 3rem);         /* 36px - 48px */
}
```

**Clamp formula breakdown:**
```css
clamp(min, preferred, max)
```
- **min:** Smallest size (mobile)
- **preferred:** Calculated size (viewport-based)
- **max:** Largest size (desktop)

**Benefits:**
- Smooth scaling between breakpoints
- No media queries needed
- Better UX (gradual size changes)

### Line Heights

**Pattern:** `--leading-{name}` (Tailwind-inspired)

```css
:root {
  --leading-tight: 1.1;      /* Headings, display text */
  --leading-snug: 1.375;     /* Subheadings */
  --leading-normal: 1.6;     /* Body text (readable) */
  --leading-relaxed: 1.75;   /* Long-form content */
}
```

**Usage:**
```css
h1 {
  line-height: var(--leading-tight);
}

p {
  line-height: var(--leading-relaxed);
}
```

### Font Weights

**Pattern:** `--font-{weight}`

```css
:root {
  --font-normal: 400;    /* Regular text */
  --font-medium: 500;    /* Slightly bold */
  --font-semibold: 600;  /* Headings, emphasis */
  --font-bold: 700;      /* Strong emphasis */
}
```

---

## Shadow Variables

**Pattern:** `--shadow-{size}` from xs to xl

```css
:root {
  /* Dark theme shadows (stronger opacity) */
  --shadow-xs: 0 1px 2px 0 rgb(0 0 0 / 40%);
  --shadow-sm: 0 2px 4px -1px rgb(0 0 0 / 50%);
  --shadow-md: 0 4px 6px -2px rgb(0 0 0 / 60%);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 70%);
  --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 80%);
}
```

**Light theme (softer shadows):**
```css
html[data-theme="light"] {
  --shadow-xs: 0 1px 2px 0 rgb(0 0 0 / 5%);
  --shadow-sm: 0 2px 4px -1px rgb(0 0 0 / 10%);
  --shadow-md: 0 4px 6px -2px rgb(0 0 0 / 15%);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 20%);
  --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 25%);
}
```

---

## Border Radius Variables

**Pattern:** `--radius-{size}`

```css
:root {
  --radius-sm: 0.25rem;  /* 4px - Buttons, inputs */
  --radius-md: 0.375rem; /* 6px - Cards, containers */
  --radius-lg: 0.5rem;   /* 8px - Modals, large cards */
  --radius-xl: 0.75rem;  /* 12px - Hero sections */
}
```

---

## Transition Variables

**Pattern:** `--transition-{speed}` (duration + easing combined)

```css
:root {
  --transition-fast: 100ms cubic-bezier(0.4, 0, 0.2, 1);  /* Quick feedback */
  --transition-base: 200ms cubic-bezier(0.4, 0, 0.2, 1);  /* Standard UI */
  --transition-slow: 300ms cubic-bezier(0.4, 0, 0.2, 1);  /* Complex animations */
}
```

**Easing:** `cubic-bezier(0.4, 0, 0.2, 1)` is "ease-out" (fast start, slow end)

---

## Blur Variables

**Pattern:** `--blur-{size}`

```css
:root {
  --blur-sm: blur(4px);   /* Subtle glass effect */
  --blur-md: blur(12px);  /* Strong glass effect */
}
```

**Usage:**
```css
.header {
  backdrop-filter: var(--blur-md);
}
```

---

## 2. Semantic Variables

**Definition:** Variables that map primitives to purpose-driven names.

**Location:** `00-variables.css` (after primitives)

**Purpose:** Theme-aware, self-documenting, reusable across components.

### Background Mapping

```css
:root {
  /* Semantic backgrounds */
  --bg-primary: var(--gray-2);     /* Main container background */
  --bg-secondary: var(--gray-3);   /* Secondary container (cards) */
}
```

**Benefits:**
- Change primitive mapping without editing components
- Self-documenting (`--bg-primary` vs `--gray-2`)
- Theme-aware (automatically adapts when primitives change)

### Text Color Mapping

```css
:root {
  /* Semantic text colors */
  --text-primary: var(--gray-12);   /* Main text (highest contrast) */
  --text-secondary: var(--gray-11); /* Muted text (lower contrast) */
}
```

### Border Mapping

```css
:root {
  /* Semantic borders */
  --border-color: var(--gray-7);
}
```

### Accent Mapping

```css
:root {
  /* Semantic accent */
  --accent-color: var(--cyan-9);
}
```

### Layout-Specific Variables

```css
:root {
  /* Layout constraints */
  --content-max-width: 1200px;

  /* Header/sidebar backgrounds (with transparency) */
  --header-bg: rgb(24 24 27 / 95%);  /* --gray-3 with 95% opacity */
  --sidebar-bg: rgb(24 24 27 / 80%); /* --gray-3 with 80% opacity */

  /* Font stacks */
  --font-mono: "Monaco", "Menlo", "Courier New", monospace;
}
```

---

## 3. Component-Specific Variables

**Definition:** Variables scoped to a single component or module.

**Location:** Component's CSS module (e.g., `33-cards.css`)

**Purpose:** Component-level customization, easy to override for variants.

### Example: Card Component

```css
/* 33-cards.css */
.card {
  /* Component-level variables */
  --card-padding: var(--space-6);
  --card-border-radius: var(--radius-md);
  --card-bg: var(--bg-secondary);
  --card-border: 1px solid var(--border-color);

  /* Use component variables */
  padding: var(--card-padding);
  border-radius: var(--card-border-radius);
  background: var(--card-bg);
  border: var(--card-border);
}

/* Variant: Compact card */
.card-compact {
  --card-padding: var(--space-4); /* Override component variable */
}
```

### Example: Button Component

```css
/* 31-forms.css */
.send-button {
  /* Component-level variables */
  --button-bg: var(--cyan-9);
  --button-bg-hover: var(--cyan-10);
  --button-text: var(--gray-1);
  --button-padding-x: var(--space-5);
  --button-padding-y: var(--space-3);

  background: var(--button-bg);
  color: var(--button-text);
  padding: var(--button-padding-y) var(--button-padding-x);
}

.send-button:hover {
  background: var(--button-bg-hover);
}
```

---

## Naming Conventions

### Pattern Rules

**Primitives:**
- Color scale: `--{color}-{step}` (e.g., `--gray-7`, `--cyan-9`)
- Spacing: `--space-{number}` (e.g., `--space-4`)
- Typography: `--text-{size}`, `--leading-{name}`, `--font-{weight}`
- Shadows: `--shadow-{size}`
- Radius: `--radius-{size}`
- Transitions: `--transition-{speed}`

**Semantics:**
- Background: `--bg-{purpose}` (e.g., `--bg-primary`)
- Text: `--text-{purpose}` (e.g., `--text-secondary`)
- Border: `--border-{purpose}` (e.g., `--border-color`)
- Accent: `--accent-color`

**Components:**
- `--{component}-{property}` (e.g., `--card-padding`, `--button-bg`)

### Case Conventions

**Use kebab-case for all variable names:**
```css
/* ✓ Good */
--bg-primary
--text-secondary
--card-padding

/* ✗ Bad */
--bgPrimary
--textSecondary
--cardPadding
```

---

## Usage Patterns

### When to Use Primitives Directly

**Use primitives for:**
- Spacing (--space-X)
- Border radius (--radius-X)
- Shadows (--shadow-X)
- Typography scale (--text-X)

**Example:**
```css
.card {
  padding: var(--space-6);              /* ✓ Universal spacing */
  border-radius: var(--radius-md);       /* ✓ Universal radius */
  box-shadow: var(--shadow-md);          /* ✓ Universal shadow */
  font-size: var(--text-lg);             /* ✓ Universal typography */
}
```

### When to Use Semantics

**Use semantics for:**
- Colors (backgrounds, text, borders, accents)
- Theme-aware properties

**Example:**
```css
.card {
  background: var(--bg-secondary);    /* ✓ Theme-aware */
  color: var(--text-primary);         /* ✓ Theme-aware */
  border: 1px solid var(--border-color); /* ✓ Theme-aware */
}
```

### When to Create Component Variables

**Create component variables when:**
- Multiple properties share same value
- Want to create variants easily
- Need to override for specific contexts

**Example:**
```css
.card {
  --card-padding: var(--space-6);
  --card-bg: var(--bg-secondary);

  padding: var(--card-padding);
  background: var(--card-bg);
}

/* Easy to create variant */
.card-compact {
  --card-padding: var(--space-4); /* Override */
}
```

---

## Quick Reference Table

| Type | Pattern | Example | Location |
|------|---------|---------|----------|
| **Color scale** | `--{color}-{step}` | `--gray-7`, `--cyan-9` | 00-variables.css |
| **Spacing** | `--space-{number}` | `--space-4`, `--space-8` | 00-variables.css |
| **Typography** | `--text-{size}` | `--text-lg`, `--text-xl` | 00-variables.css |
| **Line height** | `--leading-{name}` | `--leading-tight` | 00-variables.css |
| **Font weight** | `--font-{weight}` | `--font-semibold` | 00-variables.css |
| **Shadow** | `--shadow-{size}` | `--shadow-md` | 00-variables.css |
| **Radius** | `--radius-{size}` | `--radius-lg` | 00-variables.css |
| **Transition** | `--transition-{speed}` | `--transition-base` | 00-variables.css |
| **Semantic BG** | `--bg-{purpose}` | `--bg-primary` | 00-variables.css |
| **Semantic text** | `--text-{purpose}` | `--text-secondary` | 00-variables.css |
| **Component** | `--{component}-{prop}` | `--card-padding` | Component module |
