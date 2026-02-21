# Common Workflows

Step-by-step guided workflows for 7 common CSS tasks.

---

## Task 1: Add Styles to Existing Component

**Scenario:** You need to add hover effects to the `.send-button` in the playground.

### Steps

1. **Identify the module:** Buttons are in `31-forms.css` (Layer 4: Components)

2. **Read the existing code:**
   ```bash
   # Use Read tool or open in editor
   cat src/styles/31-forms.css
   ```

3. **Add your styles:**
   ```css
   /* 31-forms.css */
   .send-button:hover:not(:disabled) {
     background: var(--cyan-10);
     box-shadow: var(--shadow-sm);
     transform: translateY(-1px); /* Add this */
   }
   ```

4. **Validate:**
   ```bash
   npm run lint:css:fix
   npm run build
   ```

5. **Test in browser:**
   - Open `output/index.html`
   - Test hover effect
   - Check dark/light theme switching

6. **Commit:**
   ```bash
   /commit
   ```

**Decision point:** If your change affects multiple components, consider if it should be a utility class in Layer 5 instead.

---

## Task 2: Add New Component Class

**Scenario:** You need to create a `.card` component for displaying course modules.

### Steps

1. **Ask decision questions:**
   - Is this a new component or extension of existing? → New component
   - Does it fit in existing modules? → No, it's distinct from forms/media/playground
   - What layer? → Layer 4 (Components)

2. **Decide module strategy:**
   - **Option A:** Add to existing module if closely related (e.g., add to `30-media.css` if card is primarily for media)
   - **Option B:** Create new module `33-cards.css` if it's a distinct pattern

3. **Create the module (Option B):**
   ```css
   /* 33-cards.css */
   /* ============================================
      LAYER 4: COMPONENTS - CARDS
      Card container for course modules
      ============================================ */

   .card {
     background: var(--bg-secondary);
     border: 1px solid var(--border-color);
     border-radius: var(--radius-md);
     padding: var(--space-6);
     margin: var(--space-4) 0;
     transition: all var(--transition-base);
   }

   .card:hover {
     border-color: var(--cyan-9);
     box-shadow: var(--shadow-md);
   }

   .card-title {
     font-size: var(--text-xl);
     font-weight: var(--font-semibold);
     color: var(--text-primary);
     margin-bottom: var(--space-3);
   }

   .card-description {
     color: var(--text-secondary);
     font-size: var(--text-base);
     line-height: var(--leading-relaxed);
   }
   ```

4. **Update `css-modules.json`:**
   ```json
   {
     "modules": [
       // ...
       "31-forms.css",
       "32-playground.css",
       "33-cards.css",  // <-- Add here
       "40-animations.css",
       "41-responsive.css"
     ]
   }
   ```

5. **Validate and test:**
   ```bash
   npm run lint:css:fix
   npm run build
   # Open output/index.html and test
   ```

6. **Commit:**
   ```bash
   /commit
   ```

**Common mistakes:**
- ❌ Forgetting to update `css-modules.json` (build will fail)
- ❌ Adding to wrong layer (cards are components, not content)
- ❌ Using hard-coded colors instead of CSS variables

---

## Task 3: Add CSS Variable

**Scenario:** You need a new spacing value `--space-14` for a specific layout.

### Steps

1. **Check if it already exists:**
   ```bash
   grep "space-14" src/styles/00-variables.css
   ```

2. **If not, add to `00-variables.css`:**
   ```css
   /* 00-variables.css */
   :root {
     /* Spacing - 8px grid */
     --space-1: 0.25rem;
     --space-2: 0.5rem;
     // ...
     --space-12: 3rem;
     --space-14: 3.5rem; /* Add this */
     --space-16: 4rem;
   }
   ```

3. **Consider naming convention:**
   - Spacing uses 8px grid: 1 = 4px, 2 = 8px, 4 = 16px, etc.
   - `--space-14` = 3.5rem = 56px (valid for 8px grid)

4. **Validate:**
   ```bash
   npm run lint:css
   npm run build
   ```

5. **Use in your component:**
   ```css
   .my-component {
     margin-top: var(--space-14);
   }
   ```

6. **Commit:**
   ```bash
   /commit
   ```

### Decision Point: Primitive vs. Semantic Variable

**Should this be a primitive variable (--space-X) or semantic variable (--component-margin)?**

- **Primitive:** Reusable across multiple components → Add to `00-variables.css`
- **Semantic:** Component-specific → Define in component's module

**Example of semantic variable:**
```css
/* 33-cards.css */
.card {
  --card-padding: var(--space-6);
  --card-gap: var(--space-4);

  padding: var(--card-padding);
  gap: var(--card-gap);
}
```

---

## Task 4: Create Theme Override

**Scenario:** The `.card` component needs different colors in light theme.

### Steps

1. **Check current dark theme styles:**
   ```css
   /* 33-cards.css */
   .card {
     background: var(--bg-secondary); /* --gray-3 in dark */
     border: 1px solid var(--border-color); /* --gray-7 in dark */
   }
   ```

2. **Add light theme override to `01-theme-light.css`:**
   ```css
   /* 01-theme-light.css */
   html[data-theme="light"] {
     /* Existing overrides... */

     /* Card component overrides */
     --bg-secondary: var(--gray-1);
     --border-color: var(--gray-5);
   }
   ```

3. **Alternative: Component-specific override:**
   ```css
   /* 33-cards.css */
   [data-theme="light"] .card {
     background: var(--gray-1);
     border-color: var(--gray-5);
     box-shadow: var(--shadow-sm);
   }
   ```

4. **Test theme switching:**
   - Open `output/index.html`
   - Click theme toggle button
   - Verify card colors change appropriately

5. **Validate:**
   ```bash
   npm run lint:css
   npm run build
   ```

6. **Commit:**
   ```bash
   /commit
   ```

**Best practice:** Prefer semantic variables (--bg-secondary) over direct overrides. This keeps theme logic centralized in Layer 1.

---

## Task 5: Fix Stylelint Error

**Scenario:** You run `npm run lint:css` and get errors.

### Steps

1. **Run lint to see errors:**
   ```bash
   npm run lint:css
   ```

   Example output:
   ```
   src/styles/33-cards.css
     12:3  ✖  Unexpected duplicate selector ".card"  no-duplicate-selectors
     25:5  ✖  Expected single space before "{"       block-opening-brace-space-before
   ```

2. **Understand the error:**
   - **no-duplicate-selectors:** You defined `.card` twice in the same file
   - **block-opening-brace-space-before:** Missing space before `{`

3. **Fix the issues:**
   ```css
   /* Before (wrong) */
   .card{
     background: var(--bg-secondary);
   }

   .card {
     padding: var(--space-6);
   }

   /* After (correct) */
   .card {
     background: var(--bg-secondary);
     padding: var(--space-6);
   }
   ```

4. **Auto-fix (if possible):**
   ```bash
   npm run lint:css:fix
   ```

5. **Re-run lint:**
   ```bash
   npm run lint:css
   ```

6. **Build and test:**
   ```bash
   npm run build
   ```

7. **Commit:**
   ```bash
   /commit
   ```

**For detailed error solutions:** See `references/common-fixes.md`

---

## Task 6: Add Responsive Styles

**Scenario:** Your `.card` component needs to stack vertically on mobile.

### Steps

1. **Identify the module:** Responsive styles go in `41-responsive.css` (Layer 5: Utilities)

2. **Check existing breakpoints:**
   ```css
   /* 41-responsive.css */
   @media (width <= 768px) {
     /* Tablet/mobile styles */
   }
   ```

3. **Add your responsive styles:**
   ```css
   /* 41-responsive.css */
   @media (width <= 768px) {
     /* Existing responsive styles... */

     /* Card responsive adjustments */
     .card {
       padding: var(--space-4);
       margin: var(--space-3) 0;
     }

     .card-grid {
       grid-template-columns: 1fr; /* Stack cards */
     }
   }
   ```

4. **Test responsive behavior:**
   - Open `output/index.html`
   - Resize browser to mobile width (<768px)
   - Verify cards stack vertically

5. **Validate and build:**
   ```bash
   npm run lint:css
   npm run build
   ```

6. **Commit:**
   ```bash
   /commit
   ```

### Mobile-First Approach (Alternative)

**Better practice:** Define mobile styles first, then enhance for larger screens.

```css
/* 33-cards.css - Base mobile styles */
.card-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--space-4);
}

/* 41-responsive.css - Desktop enhancement */
@media (width >= 768px) {
  .card-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (width >= 1024px) {
  .card-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}
```

---

## Task 7: Create New Module

**Scenario:** You need to add a complex navigation sidebar with tabs, and it doesn't fit existing modules.

### Steps

1. **Ask decision questions:**
   - What layer? → Layer 2 (Layout) - it's page structure
   - Does it fit existing modules? → No, it's distinct from header/layout/scrollbar
   - What's the responsibility? → Sidebar navigation with tabbed interface

2. **Choose module number:**
   - Layer 2 uses prefix `1X`
   - Existing: `10-header.css`, `11-layout.css`, `12-scrollbar.css`
   - Next available: `13-sidebar-nav.css`

3. **Create the module:**
   ```css
   /* 13-sidebar-nav.css */
   /* ============================================
      LAYER 2: LAYOUT - SIDEBAR NAVIGATION
      Tabbed sidebar navigation component
      ============================================ */

   .sidebar-nav {
     position: sticky;
     top: var(--space-4);
     background: var(--sidebar-bg);
     border: 1px solid var(--gray-7);
     border-radius: var(--radius-lg);
     padding: var(--space-4);
   }

   .sidebar-tabs {
     display: flex;
     gap: var(--space-2);
     margin-bottom: var(--space-4);
     border-bottom: 1px solid var(--gray-7);
   }

   .sidebar-tab {
     padding: var(--space-2) var(--space-4);
     border: none;
     background: transparent;
     color: var(--gray-11);
     cursor: pointer;
     transition: all var(--transition-base);
     border-bottom: 2px solid transparent;
   }

   .sidebar-tab:hover {
     color: var(--gray-12);
   }

   .sidebar-tab.active {
     color: var(--cyan-9);
     border-bottom-color: var(--cyan-9);
   }

   .sidebar-content {
     overflow-y: auto;
     max-height: calc(100vh - 200px);
   }
   ```

4. **Update `css-modules.json`:**
   ```json
   {
     "modules": [
       "00-variables.css",
       "01-theme-light.css",
       "02-reset.css",
       "10-header.css",
       "11-layout.css",
       "12-scrollbar.css",
       "13-sidebar-nav.css",  // <-- Add here (Layer 2)
       "20-typography.css",
       // ...
     ]
   }
   ```

5. **Validate and build:**
   ```bash
   npm run lint:css:fix
   npm run build
   ```

6. **Test in browser:**
   - Verify sidebar renders correctly
   - Test tab switching
   - Check theme switching (dark/light)
   - Test responsive behavior

7. **Commit:**
   ```bash
   /commit
   ```

**Critical:** Module order in `css-modules.json` determines cascade. Insert new module in correct layer position.

---

## Quick Reference: Workflow Checklist

**For any CSS task:**
- [ ] Identify correct layer (1-5)
- [ ] Choose module (extend existing or create new)
- [ ] Use CSS variables (not hard-coded values)
- [ ] Update `css-modules.json` if creating new module
- [ ] Run `npm run lint:css:fix`
- [ ] Run `npm run build`
- [ ] Test in browser (including theme switching)
- [ ] Test responsive behavior (if applicable)
- [ ] Commit with `/commit`

**Common validation issues:**
- Forgot to update `css-modules.json`
- Module not in correct layer position
- Used hard-coded values instead of variables
- Duplicate selectors in same file
- Missing space before `{`
