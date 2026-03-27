# The 5 Layers Guide

Deep dive into each layer's purpose, responsibility, and usage patterns.

---

## Layer 1: Foundation (Variables & Reset)

**Purpose:** Establish design system primitives and base styles.

**Modules:**
- **00-variables.css** - CSS custom properties (colors, typography, spacing, shadows, transitions)
- **01-theme-light.css** - Light theme overrides for `[data-theme="light"]`
- **02-reset.css** - CSS reset and base body/html styles

### Responsibility

- Define the design system's vocabulary (colors, spacing, typography scales)
- Provide theme-aware color/typography/spacing tokens
- Reset browser defaults for consistency
- Establish global styles (body, html, :root)

### When to Extend

- Adding new design tokens (new color scale, spacing value, shadow level)
- Creating theme-specific overrides for new components
- Adjusting base typography or layout defaults

### When to Create New Module

**Never.** Foundation layer is complete. Use existing modules:
- Variables → `00-variables.css`
- Theme overrides → `01-theme-light.css`
- Base styles → `02-reset.css`

### Example: Adding a New Color Variable

```css
/* 00-variables.css */
:root {
  /* Existing gray scale... */
  --gray-1: #0a0a0b;
  --gray-12: #eeeeef;

  /* Add new accent color */
  --purple-8: #9333ea;
  --purple-9: #a855f7;
  --purple-10: #c084fc;
}
```

### Common Mistakes

- ❌ Defining component-specific variables here (put in the component's module)
- ❌ Hard-coding values in other layers (use variables for consistency)
- ❌ Creating semantic variables without mapping to primitives

---

## Layer 2: Layout System

**Purpose:** Page structure, navigation, grid systems, scrollbars.

**Modules:**
- **10-header.css** - Navigation header, logo, theme toggle button
- **11-layout.css** - Main grid container, sidebar, content area
- **12-scrollbar.css** - Custom scrollbar styling (webkit overrides)

### Responsibility

- Define page-level layout structure
- Position major landmarks (header, sidebar, content)
- Handle navigation and scrollbar aesthetics
- Establish grid systems and spacing

### When to Extend

- Adding new navigation elements (breadcrumbs, tabs)
- Modifying grid behavior for new content types
- Adjusting scrollbar styles for specific containers

### When to Create New Module

- Adding a new major layout component (footer, modal overlay, sidebar navigation)
- Use prefix `13-`, `14-`, etc., and update `css-modules.json`

### Example: Adding a Footer

```css
/* 13-footer.css */
/* ============================================
   LAYER 2: LAYOUT - FOOTER
   Page footer with copyright and links
   ============================================ */

.footer {
  margin-top: var(--space-16);
  padding: var(--space-8) var(--space-4);
  border-top: 1px solid var(--gray-7);
  text-align: center;
  color: var(--gray-11);
  font-size: var(--text-sm);
}

.footer-links {
  display: flex;
  justify-content: center;
  gap: var(--space-6);
  margin-bottom: var(--space-4);
}
```

**Update css-modules.json:**

```json
{
  "modules": [
    "00-variables.css",
    "01-theme-light.css",
    "02-reset.css",
    "10-header.css",
    "11-layout.css",
    "12-scrollbar.css",
    "13-footer.css",  // <-- Add here
    "20-typography.css",
    // ...
  ]
}
```

### Common Mistakes

- ❌ Adding component styles here (buttons, cards) → Use Layer 4
- ❌ Adding content styles (typography) → Use Layer 3
- ❌ Forgetting to update `css-modules.json`

---

## Layer 3: Content Elements

**Purpose:** Typography, code blocks, tables, lists—semantic HTML elements.

**Modules:**
- **20-typography.css** - Headings (h1-h4), paragraphs, links, emphasis
- **21-code.css** - Code blocks, pre, blockquotes, syntax highlighting
- **22-tables.css** - Table styling with hover effects
- **23-lists.css** - Unordered/ordered lists, markers

### Responsibility

- Style semantic HTML tags (h1-h6, p, a, ul, ol, table, pre, code)
- Ensure readability and visual hierarchy
- Apply theme-aware colors and spacing
- Handle typography scales and line heights

### When to Extend

- Adjusting typography scales or line heights
- Adding new semantic element styles (dl/dt/dd, figure/figcaption)
- Modifying code block or table appearance

### When to Create New Module

- Adding styles for a new content category (definition lists, figures, citations)
- Use prefix `24-`, `25-`, etc.

### Example: Styling Definition Lists

```css
/* 23-lists.css (extend existing module) */

/* Existing list styles... */

/* Add definition list styles */
dl {
  margin: var(--space-4) 0;
}

dt {
  font-weight: var(--font-semibold);
  color: var(--gray-12);
  margin-top: var(--space-3);
}

dd {
  margin-left: var(--space-6);
  color: var(--gray-11);
  margin-bottom: var(--space-2);
}
```

### Common Mistakes

- ❌ Adding component classes here (`.card`, `.button`) → Use Layer 4
- ❌ Mixing layout concerns (grid, positioning) → Use Layer 2
- ❌ Creating utility classes (`.text-center`) → Use Layer 5

---

## Layer 4: Components

**Purpose:** Self-contained UI elements with specific interactions.

**Modules:**
- **30-media.css** - Images, charts, mermaid diagrams, YouTube embeds
- **31-forms.css** - Inputs, textareas, selects, buttons
- **32-playground.css** - Chutes AI playground interface

### Responsibility

- Style interactive components with clear boundaries
- Provide consistent UI patterns (buttons, forms, media)
- Use semantic variable names (--bg-primary, --text-primary)
- Handle component states (hover, focus, disabled)

### When to Extend

- Adding new button variants or form elements
- Styling new media types (audio player, PDF viewer)
- Enhancing playground functionality

### When to Create New Module

- Adding a new component category (modals, tooltips, cards, tabs)
- Use prefix `33-`, `34-`, etc.

### Example: Adding a Modal Component

```css
/* 33-modal.css */
/* ============================================
   LAYER 4: COMPONENTS - MODAL
   Modal dialog overlay and content
   ============================================ */

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgb(0 0 0 / 60%);
  backdrop-filter: var(--blur-md);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-content {
  background: var(--bg-primary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-lg);
  padding: var(--space-8);
  max-width: 600px;
  width: 90%;
  box-shadow: var(--shadow-xl);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--space-6);
}

.modal-close {
  background: transparent;
  border: none;
  color: var(--gray-11);
  font-size: var(--text-2xl);
  cursor: pointer;
  line-height: 1;
  transition: color var(--transition-base);
}

.modal-close:hover {
  color: var(--gray-12);
}
```

**Update css-modules.json:**

```json
{
  "modules": [
    // ...
    "31-forms.css",
    "32-playground.css",
    "33-modal.css",  // <-- Add after other components
    "40-animations.css",
    "41-responsive.css"
  ]
}
```

### Common Mistakes

- ❌ Adding semantic HTML styles (h1, p) → Use Layer 3
- ❌ Adding layout structure (header, footer) → Use Layer 2
- ❌ Hard-coding colors instead of using CSS variables

---

## Layer 5: Utilities

**Purpose:** Cross-cutting concerns like animations and responsive breakpoints.

**Modules:**
- **40-animations.css** - Animation classes, transitions, FOUC prevention
- **41-responsive.css** - Media queries (tablet/mobile breakpoints)

### Responsibility

- Provide animation utilities and transition patterns
- Handle responsive layout adjustments
- Apply global utilities (hide, show, fade)
- Override component styles for specific contexts

### When to Extend

- Adding new animation classes or keyframes
- Creating responsive breakpoints for new components
- Adding utility classes for common patterns

### When to Create New Module

- Adding a new utility category (print styles, accessibility utilities, spacing utilities)
- Use prefix `42-`, `43-`, etc.

### Example: Adding a Fade-In Animation

```css
/* 40-animations.css (extend existing module) */

/* Existing animations... */

/* Add fade-in utility */
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.fade-in {
  animation: fadeIn var(--transition-slow) ease-out;
}
```

### Example: Adding Print Styles

```css
/* 42-print.css */
/* ============================================
   LAYER 5: UTILITIES - PRINT
   Print-specific styles
   ============================================ */

@media print {
  .header,
  .sidebar,
  .theme-toggle {
    display: none;
  }

  .content {
    width: 100%;
    padding: 0;
  }

  a[href]:after {
    content: " (" attr(href) ")";
  }
}
```

### Common Mistakes

- ❌ Adding component-specific styles here → Use Layer 4
- ❌ Adding semantic HTML styles → Use Layer 3
- ❌ Creating utilities that should be CSS variables

---

## Layer Summary Table

| Layer | Prefix | Purpose | Example Modules | When to Extend |
|-------|--------|---------|-----------------|----------------|
| **1: Foundation** | `0X` | Design tokens, themes, resets | variables, theme-light, reset | New design tokens, theme overrides |
| **2: Layout** | `1X` | Page structure, navigation | header, layout, scrollbar | New layout sections, grid changes |
| **3: Content** | `2X` | Semantic HTML elements | typography, code, tables, lists | New semantic elements, typography changes |
| **4: Components** | `3X` | Interactive UI patterns | media, forms, playground | New components, button variants |
| **5: Utilities** | `4X` | Animations, responsive, global utilities | animations, responsive | New animations, breakpoints, utilities |

---

## Decision: Which Layer?

Ask these questions:

1. **Am I defining design tokens?** → Layer 1 (Foundation)
2. **Am I structuring the page layout?** → Layer 2 (Layout)
3. **Am I styling semantic HTML tags?** → Layer 3 (Content)
4. **Am I building an interactive component?** → Layer 4 (Components)
5. **Am I adding animations or responsive styles?** → Layer 5 (Utilities)

**Still unsure?** Check the decision trees in the main skill documentation.
