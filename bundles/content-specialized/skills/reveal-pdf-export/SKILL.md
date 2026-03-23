---
name: reveal-pdf-export
description: >
  Export a Reveal.js HTML presentation to a pixel-perfect PDF using Chrome CDP
  (no Puppeteer/Playwright dependency). Handles all known Reveal.js 4.x
  print-pdf rendering bugs: padding zeroed by reveal.css, extra blank trailing
  page from page-break-after:always on .pdf-page, and speaker notes inflating
  slide height. Use when the user asks to export, print, or generate a PDF from
  a Reveal.js presentation, or when building a Reveal.js slide deck that needs
  PDF output.
---

# Reveal.js PDF Export

## Export

Copy `scripts/export-pdf.mjs` next to the presentation, then run:

```bash
node export-pdf.mjs [presentation.html] [output.pdf]
```

Defaults: input = `presentation.html` in CWD, output = `<basename>.pdf`.

**Env overrides:**
| Variable | Default | Purpose |
|----------|---------|---------|
| `CHROME` | macOS default Chrome path | Chrome binary |
| `WIDTH`  | `1280` | Slide width in px |
| `HEIGHT` | `720`  | Slide height in px |

Kill stale headless Chrome before re-running:
```bash
pkill -f "headless.*9223"
```

## Required HTML Fixes (Reveal.js 4.x print-pdf bugs)

Apply these to any Reveal.js 4.x presentation before exporting.

### 1. CSS — add inside `<style>`

```css
/* Full-width slides: padding lives on an inner div, not the section.
   Reveal.js reveal.css zeroes section padding in print-pdf mode with
   specificity 0,3,2, overriding any !important on the section. */
.slide-inner {
  padding: 40px 60px;
  box-sizing: border-box;
  overflow: hidden;
  height: 100%;
}

/* Title slide: inner wrapper carries padding + flex centering. */
.slide-title-inner {
  padding: 40px 70px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  height: 100%;
}

/* Speaker notes inflate section height in print-pdf (Reveal.js adds
   margin-top:70px to aside.notes), causing extra pages. */
html.print-pdf .reveal aside.notes {
  display: none !important;
}

/* Belt-and-suspenders: CSS :last-child isn't applied before print fires,
   so the JS fix below is the real fix. Keep both for safety. */
html.print-pdf .reveal .slides .pdf-page:last-child {
  page-break-after: auto !important;
  break-after: auto !important;
}
```

### 2. JS — add after `Reveal.initialize({...})`

```js
// Reveal.js sets page-break-after:always on every .pdf-page including the
// last one, producing a blank trailing page. CSS :last-child isn't applied
// before Chrome fires Page.printToPDF; inline style override is reliable.
if (location.search.includes('print-pdf')) {
  Reveal.on('ready', () => {
    setTimeout(() => {
      const pages = document.querySelectorAll('.reveal .slides .pdf-page');
      if (pages.length > 0) {
        const last = pages[pages.length - 1];
        last.style.pageBreakAfter = 'auto';
        last.style.breakAfter = 'auto';
      }
    }, 500);
  });
}
```

### 3. Slide structure — inner wrapper pattern

`reveal.css` forces `section { padding: 0 !important }` in print-pdf.
Move padding to a non-section child div.

**Full-width slides** (no photo panel):
```html
<section class="slide-body">
  <div class="slide-inner">           <!-- padding lives here -->
    <div class="slide-header">...</div>
    <!-- main content -->
  </div>
  <div class="slide-footer"></div>    <!-- stays outside; position:absolute -->
</section>
```

**Photo-panel slides** already work: `.slide-main` carries the padding.

**Title slide**:
```html
<section class="slide-title">         <!-- background, overflow:hidden only -->
  <div class="slide-title-inner">     <!-- padding + flex centering -->
    <!-- all content -->
  </div>
  <div class="slide-footer"></div>
</section>
```

## Debugging page count

To inspect `.pdf-page` heights, temporarily add before `Reveal.initialize`:

```js
if (location.search.includes('print-pdf')) {
  window.addEventListener('load', () => {
    setTimeout(() => {
      const pages = document.querySelectorAll('.reveal .slides .pdf-page');
      document.title = `PAGES:${pages.length} | ` +
        Array.from(pages).map((p, i) =>
          `Page ${i+1}: ${Math.round(p.getBoundingClientRect().height)}px`
        ).join(' | ');
    }, 6000);
  });
}
```

Read `document.title` via CDP after navigation. Expected: all pages ≤ HEIGHT px,
count = number of slides.

**Root causes of extra pages:**
1. Speaker notes not hidden (most common — adds 70px+ margin per slide)
2. `page-break-after:always` on last `.pdf-page` (fix: JS snippet above)
3. Genuine content overflow (reduce content or font size on that slide)
