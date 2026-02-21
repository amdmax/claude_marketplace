# Responsive Design & Breakpoints

Mobile-first approach, breakpoint strategy, and responsive patterns.

---

## Mobile-First Philosophy

### Why Mobile-First?

**Benefits:**
1. **Simpler base styles** - Mobile styles are typically simpler
2. **Progressive enhancement** - Add complexity for larger screens
3. **Better performance** - Mobile users load minimal CSS
4. **Forces prioritization** - Essential content/features come first

**Traditional approach (desktop-first):**
```css
/* Start with complex desktop styles */
.card-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--space-8);
  padding: var(--space-10);
}

/* Override with simpler mobile styles */
@media (width <= 768px) {
  .card-grid {
    grid-template-columns: 1fr;
    gap: var(--space-4);
    padding: var(--space-4);
  }
}
```

**Mobile-first approach (recommended):**
```css
/* Start with simple mobile styles */
.card-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--space-4);
  padding: var(--space-4);
}

/* Enhance for larger screens */
@media (width >= 768px) {
  .card-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: var(--space-6);
  }
}

@media (width >= 1024px) {
  .card-grid {
    grid-template-columns: repeat(3, 1fr);
    gap: var(--space-8);
    padding: var(--space-10);
  }
}
```

---

## Breakpoint Strategy

### Standard Breakpoints

**This project uses one primary breakpoint:**

```css
/* Mobile: Base styles (no media query) */
/* Tablet/Desktop: 769px and up */

@media (width <= 768px) {
  /* Mobile-specific adjustments */
}
```

**Why single breakpoint?**
- Simpler maintenance
- Course content works well at 2 sizes (mobile/desktop)
- Reduces CSS complexity
- Fluid typography handles intermediate sizes

### Industry Standard Breakpoints

**If you need more granular control:**

```css
/* Extra small devices (phones, portrait) */
@media (width <= 575px) { }

/* Small devices (phones, landscape) */
@media (width >= 576px) { }

/* Medium devices (tablets) */
@media (width >= 768px) { }

/* Large devices (desktops) */
@media (width >= 1024px) { }

/* Extra large devices (large desktops) */
@media (width >= 1440px) { }
```

### Tailwind-Inspired Breakpoints

```css
/* sm: Small devices */
@media (width >= 640px) { }

/* md: Medium devices */
@media (width >= 768px) { }

/* lg: Large devices */
@media (width >= 1024px) { }

/* xl: Extra large devices */
@media (width >= 1280px) { }

/* 2xl: 2x extra large devices */
@media (width >= 1536px) { }
```

---

## Media Query Syntax

### Modern Range Syntax (Used in This Project)

**Better readability:**
```css
/* Max-width */
@media (width <= 768px) {
  /* Mobile styles */
}

/* Min-width */
@media (width >= 1024px) {
  /* Desktop styles */
}

/* Range */
@media (768px < width < 1024px) {
  /* Tablet styles */
}
```

### Legacy Syntax (Still Valid)

```css
/* Max-width */
@media (max-width: 768px) {
  /* Mobile styles */
}

/* Min-width */
@media (min-width: 1024px) {
  /* Desktop styles */
}

/* Range */
@media (min-width: 768px) and (max-width: 1023px) {
  /* Tablet styles */
}
```

**Note:** Modern syntax is cleaner and easier to read.

---

## Responsive Patterns

### Pattern 1: Fluid Typography

**Use clamp() for responsive text without media queries:**

```css
h1 {
  /* Scales from 36px to 48px based on viewport */
  font-size: clamp(2.25rem, 1.75rem + 2.5vw, 3rem);
}

p {
  /* Scales from 16px to 18px */
  font-size: clamp(1rem, 0.95rem + 0.25vw, 1.125rem);
}
```

**Benefits:**
- Smooth scaling between breakpoints
- No media queries needed
- Better UX (gradual size changes)

### Pattern 2: Container Queries (Future)

**Not used in this project, but emerging:**

```css
.card-container {
  container-type: inline-size;
}

/* Style based on container width, not viewport width */
@container (width >= 400px) {
  .card {
    grid-template-columns: repeat(2, 1fr);
  }
}
```

### Pattern 3: Responsive Grid

**Base (mobile): Single column**
```css
.card-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--space-4);
}
```

**Enhanced (desktop): Multiple columns**
```css
@media (width >= 768px) {
  .card-grid {
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  }
}
```

**Advanced: Auto-responsive (no media query)**
```css
.card-grid {
  display: grid;
  /* Automatically creates columns when space allows */
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: var(--space-6);
}
```

### Pattern 4: Responsive Spacing

**Adjust spacing for mobile:**
```css
/* Base (mobile) */
body {
  padding: var(--space-3); /* 12px */
}

.content {
  padding: var(--space-6); /* 24px */
}

/* Desktop */
@media (width >= 768px) {
  body {
    padding: var(--space-5); /* 20px */
  }

  .content {
    padding: var(--space-10); /* 40px */
  }
}
```

### Pattern 5: Hide/Show Elements

**Show navigation on desktop, hide on mobile:**
```css
/* Base (mobile): Hidden */
.desktop-nav {
  display: none;
}

.mobile-menu {
  display: block;
}

/* Desktop: Visible */
@media (width >= 768px) {
  .desktop-nav {
    display: flex;
  }

  .mobile-menu {
    display: none;
  }
}
```

### Pattern 6: Layout Restructure

**Stack sidebar below content on mobile:**
```css
/* Base (mobile): Vertical stack */
.container {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--space-5);
}

.sidebar {
  /* Sidebar appears after content in DOM order */
}

/* Desktop: Side-by-side */
@media (width >= 768px) {
  .container {
    grid-template-columns: 250px 1fr;
    gap: var(--space-8);
  }
}
```

### Pattern 7: Responsive Images

**Ensure images scale:**
```css
img {
  max-width: 100%;
  height: auto;
}

/* Adjust chart sizes on mobile */
@media (width <= 768px) {
  .chart-container canvas {
    max-height: 300px;
  }
}
```

---

## Project-Specific Responsive Styles

### Location: 41-responsive.css

**What gets adjusted on mobile:**

#### 1. Body Padding
```css
@media (width <= 768px) {
  body {
    padding: var(--space-3); /* Reduce from default */
  }
}
```

#### 2. Container Layout
```css
@media (width <= 768px) {
  .container {
    grid-template-columns: 1fr; /* Single column */
    gap: var(--space-5);
  }
}
```

#### 3. Sidebar Position
```css
@media (width <= 768px) {
  .sidebar {
    position: static; /* Remove sticky positioning */
    backdrop-filter: none; /* Remove blur effect */
  }
}
```

#### 4. Content Padding
```css
@media (width <= 768px) {
  .content {
    padding: var(--space-6); /* Reduce padding */
  }
}
```

#### 5. Heading Sizes
```css
@media (width <= 768px) {
  h1 {
    font-size: var(--text-3xl); /* Smaller on mobile */
  }
}
```

#### 6. Chart Containers
```css
@media (width <= 768px) {
  .chart-container canvas {
    max-height: 300px; /* Constrain height */
  }
}
```

#### 7. YouTube Embeds
```css
@media (width <= 768px) {
  .youtube-container {
    padding: var(--space-4); /* Reduce padding */
  }

  .youtube-link-container {
    flex-direction: column; /* Stack vertically */
    text-align: center;
    padding: var(--space-6);
  }
}
```

---

## Testing Responsive Styles

### Browser DevTools

**Chrome/Edge/Safari:**
1. Open DevTools (F12 or Cmd+Option+I)
2. Click device toggle icon (Cmd+Shift+M)
3. Select device preset or custom dimensions
4. Test interactions (hover, focus, scroll)

**Useful dimensions to test:**
- **Mobile:** 375x667 (iPhone SE)
- **Tablet:** 768x1024 (iPad)
- **Desktop:** 1920x1080 (common desktop)

### Responsive Design Mode (Firefox)

**Features:**
- Multiple viewports side-by-side
- Touch simulation
- Network throttling
- Screenshot entire page

**Shortcut:** Cmd+Option+M (macOS) or Ctrl+Shift+M (Windows/Linux)

### Real Device Testing

**Test on actual devices when possible:**
- Mobile Safari (iOS)
- Chrome Mobile (Android)
- Different screen sizes
- Portrait and landscape orientations

---

## Accessibility Considerations

### Viewport Meta Tag

**Required for responsive design:**
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

**What it does:**
- Sets viewport width to device width
- Prevents zooming on iOS
- Enables responsive CSS

### Touch Targets

**Minimum size for mobile buttons:**
```css
.button {
  /* Minimum 44x44px for touch targets */
  min-height: 44px;
  min-width: 44px;
  padding: var(--space-3) var(--space-5);
}
```

### Text Readability

**Ensure readable font sizes on mobile:**
```css
/* Avoid font-size < 16px to prevent iOS zoom on focus */
input,
textarea {
  font-size: 16px; /* Minimum */
}
```

### Reduced Motion

**Respect user preferences:**
```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## Performance Tips

### 1. Minimize Media Queries

**Instead of:**
```css
@media (width <= 768px) {
  .card { padding: var(--space-4); }
}

@media (width <= 768px) {
  .button { margin: var(--space-2); }
}
```

**Combine:**
```css
@media (width <= 768px) {
  .card { padding: var(--space-4); }
  .button { margin: var(--space-2); }
}
```

### 2. Use Fluid Typography

**Instead of multiple breakpoints:**
```css
/* Avoid */
h1 { font-size: 24px; }

@media (width >= 768px) {
  h1 { font-size: 30px; }
}

@media (width >= 1024px) {
  h1 { font-size: 36px; }
}

@media (width >= 1440px) {
  h1 { font-size: 48px; }
}
```

**Use clamp():**
```css
/* Better */
h1 {
  font-size: clamp(1.5rem, 1.3rem + 1vw, 3rem);
}
```

### 3. Avoid Loading Unused Styles

**Conditional loading (advanced):**
```html
<!-- Mobile-specific styles -->
<link rel="stylesheet" href="mobile.css" media="(max-width: 768px)">

<!-- Desktop-specific styles -->
<link rel="stylesheet" href="desktop.css" media="(min-width: 769px)">
```

**Note:** This project uses single bundled CSS for simplicity.

---

## Common Responsive Issues

### Issue 1: Fixed Widths Break Layout

**Problem:**
```css
.card {
  width: 800px; /* ❌ Breaks on mobile */
}
```

**Solution:**
```css
.card {
  max-width: 800px;
  width: 100%;
}
```

### Issue 2: Overflow on Mobile

**Problem:**
```css
.table {
  /* Table overflows viewport on mobile */
}
```

**Solution:**
```css
.table-container {
  overflow-x: auto; /* Horizontal scroll */
  -webkit-overflow-scrolling: touch; /* Smooth iOS scroll */
}
```

### Issue 3: Small Touch Targets

**Problem:**
```css
.button {
  padding: 4px 8px; /* ❌ Too small for touch */
}
```

**Solution:**
```css
.button {
  padding: var(--space-3) var(--space-5); /* ✓ 12px 20px */
  min-height: 44px;
}
```

---

## Quick Reference

**Mobile-first approach:**
- Base styles = mobile
- Add complexity with min-width media queries
- Use fluid typography (clamp)

**Breakpoints:**
- Primary: 768px (mobile vs desktop)
- Can add more as needed (576px, 1024px, 1440px)

**Modern syntax:**
```css
@media (width <= 768px) { /* max-width */ }
@media (width >= 1024px) { /* min-width */ }
```

**Key responsive patterns:**
- Fluid typography (clamp)
- Responsive grid (auto-fit, minmax)
- Flexible images (max-width: 100%)
- Hide/show elements
- Adjust spacing
- Restructure layout

**Testing:**
- Browser DevTools device mode
- Real devices when possible
- Test portrait and landscape
- Verify touch targets (44px minimum)
