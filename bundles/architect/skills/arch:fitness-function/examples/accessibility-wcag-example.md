# Accessibility Fitness Function Example: WCAG 2.0 Level AA

Reference implementation for the NFR: **"100% of pages must pass WCAG 2.0 Level AA compliance"**

---

## Business Context

- **Business Type**: Government / Public Sector (also applicable to B2C, Education)
- **User Base**: General public including users with disabilities
- **Risk Profile**: Legal compliance (Section 508, ADA)
- **Compliance**: WCAG 2.0 Level AA (mandatory)
- **NFR Priority**: Accessibility (CRITICAL for government, HIGH for consumer-facing)

---

## Good News: Already Implemented! ✅

Your project **already has comprehensive WCAG 2.0 Level AA accessibility testing** with Pa11y-CI!

**Existing Implementation**:
- `.pa11yci.json` - Configuration with axe + htmlcs runners
- `.github/workflows/accessibility-check.yml` - Automated testing on PRs
- Tests **6 pages**: index.html, contact.html, learning.html, products.html, blog.html, eval-arena.html
- Currently **non-blocking** (reports issues but doesn't block PRs)

---

## Fitness Function Definition

**File**: `.claude/fitness-functions/fitness-functions/accessibility/wcag-aa.yml`

```yaml
fitness_function:
  id: "a11y-001"
  name: "wcag_2_0_level_aa_compliance"
  category: "accessibility"
  nfr_description: "100% of pages must pass WCAG 2.0 Level AA compliance with zero violations"

  business_context:
    priority: "CRITICAL"  # For government; HIGH for commercial
    rationale: "Legal requirement (Section 508, ADA); ensures all users can access services"
    stakeholder: "Chief Accessibility Officer / VP of Product"
    compliance_requirement: "Section 508, ADA, WCAG 2.0 Level AA"

  measurement:
    type: "accessibility_violations"
    source: "Pa11y-CI with axe + htmlcs runners"
    wcag_principles:
      - "Perceivable (WCAG 1)"
      - "Operable (WCAG 2)"
      - "Understandable (WCAG 3)"
      - "Robust (WCAG 4)"
    tested_pages:
      - "index.html (Homepage)"
      - "contact.html (Contact Form)"
      - "learning.html (Learning Page)"
      - "products.html (Products)"
      - "blog.html (Blog)"
      - "eval-arena.html (Eval Arena)"

  threshold:
    error: 0        # Zero tolerance for errors (WCAG violations)
    warning: 5      # Up to 5 warnings acceptable (best practices, not strict violations)
    notice: 20      # Informational notices OK

  test_implementation:
    automated:
      - type: "accessibility_scan"
        framework: "Pa11y-CI"
        file: ".pa11yci.json"
        runners: ["axe", "htmlcs"]
        trigger: "PR to master (HTML/CSS changes)"
        workflow: ".github/workflows/accessibility-check.yml"
    manual:
      - type: "screen_reader_testing"
        frequency: "Pre-release"
        tools: ["NVDA", "JAWS", "VoiceOver"]
      - type: "keyboard_navigation"
        frequency: "Pre-release"
        file: "tests/manual/keyboard-navigation.md"

  ci_cd_gate:
    stage: "pre-merge"
    blocking: false  # Currently non-blocking; consider making blocking
    failure_action: "Comment on PR with violations and remediation guidance"
    success_criteria: "Zero WCAG 2.0 Level AA errors across all pages"
    future_state: "Make blocking once team is confident in remediation process"

  remediation:
    guidance: |
      If this fitness function fails (WCAG violations found):

      **By WCAG Principle**:

      **1. Perceivable (users must perceive information)**:
      - Missing alt text on images → Add descriptive alt attributes
      - Low color contrast → Adjust colors (4.5:1 for normal text, 3:1 for large)
      - Missing captions on videos → Add captions/transcripts
      - Form inputs without labels → Add <label> elements

      **2. Operable (users must operate the interface)**:
      - Keyboard traps → Ensure all interactive elements are keyboard accessible
      - Missing focus indicators → Add :focus styles (visible outline)
      - Time limits without warning → Add warnings and extension options
      - Missing skip links → Add "Skip to main content" link

      **3. Understandable (users must understand information and UI)**:
      - Missing or incorrect lang attribute → Add lang="en" to <html>
      - Unclear error messages → Provide specific, actionable error text
      - Inconsistent navigation → Standardize navigation across pages
      - Missing form instructions → Add clear instructions before forms

      **4. Robust (content must work with assistive technologies)**:
      - Invalid HTML → Validate and fix HTML errors
      - Missing ARIA labels → Add aria-label or aria-labelledby
      - Incorrect ARIA roles → Use semantic HTML or correct ARIA roles
      - Name/role/value missing → Ensure all interactive elements have accessible names

      **Common Quick Fixes**:
      ```html
      <!-- Images -->
      <img src="logo.png" alt="Company Logo">

      <!-- Form labels -->
      <label for="email">Email Address:</label>
      <input type="email" id="email" name="email">

      <!-- Buttons -->
      <button type="submit">Submit Form</button>
      <!-- NOT: <div onclick="submit()">Submit</div> -->

      <!-- Skip link -->
      <a href="#main-content" class="skip-link">Skip to main content</a>

      <!-- Language -->
      <html lang="en">

      <!-- Focus styles -->
      button:focus {
        outline: 2px solid #005fcc;
        outline-offset: 2px;
      }

      <!-- Color contrast -->
      /* Bad: #777 on white (3.4:1) */
      /* Good: #595959 on white (4.5:1) */
      color: #595959;
      ```

      **Escalation**:
      - ERROR (WCAG violation): Fix before merge (if blocking) or within 1 week
      - WARNING (best practice): Fix within 2 weeks
      - NOTICE (informational): Address in future sprint
```

---

## Existing Implementation: Pa11y-CI

Your project already has automated accessibility testing!

**Configuration**: `.pa11yci.json`
```json
{
  "defaults": {
    "runners": ["axe", "htmlcs"],
    "standard": "WCAG2AA",
    "timeout": 10000,
    "wait": 1000,
    "chromeLaunchConfig": {
      "args": ["--no-sandbox", "--disable-setuid-sandbox"]
    }
  },
  "urls": [
    "http://localhost:8000/index.html",
    "http://localhost:8000/contact.html",
    "http://localhost:8000/learning.html",
    "http://localhost:8000/products.html",
    "http://localhost:8000/blog.html",
    "http://localhost:8000/eval-arena.html"
  ]
}
```

**Workflow**: `.github/workflows/accessibility-check.yml`
```yaml
name: Accessibility Check

on:
  pull_request:
    branches: [master]
    paths:
      - '**.html'
      - '**.css'
  push:
    branches: [master]
    paths:
      - '**.html'
      - '**.css'

jobs:
  accessibility:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Start local server
        run: npm run serve &

      - name: Wait for server
        uses: iFaxity/wait-on-action@v1
        with:
          resource: http://localhost:8000
          timeout: 30000

      - name: Run Pa11y-CI
        run: npm run a11y:check
        continue-on-error: true  # Non-blocking currently

      - name: Comment on PR
        if: github.event_name == 'pull_request'
        # ... (comments with results)
```

---

## Making Accessibility Fitness Function Blocking (Optional)

To make the accessibility checks **blocking** (fail PR if violations found):

**Modify**: `.github/workflows/accessibility-check.yml`

```yaml
      - name: Run Pa11y-CI
        run: npm run a11y:check
        # REMOVE: continue-on-error: true
        # This will now fail the workflow if violations are found

      - name: Check fitness function (BLOCKING)
        if: failure()
        run: |
          echo "❌ FAILED: WCAG 2.0 Level AA violations found"
          echo ""
          echo "Remediation: Review Pa11y-CI output above"
          echo "Fix all ERROR-level violations before merging"
          exit 1
```

**Note**: Only make blocking after:
1. All current violations are fixed
2. Team is trained on accessibility best practices
3. Remediation process is established

---

## Manual Testing: Screen Reader

**File**: `tests/manual/screen-reader-testing.md`

```markdown
# Screen Reader Testing Procedure

**NFR ID**: a11y-001
**Fitness Function**: WCAG 2.0 Level AA compliance
**Frequency**: Pre-release (major versions)

## Prerequisites

- Screen reader software installed:
  - **Windows**: NVDA (free) or JAWS (paid)
  - **Mac**: VoiceOver (built-in)
  - **Mobile**: TalkBack (Android) or VoiceOver (iOS)
- Staging environment access
- Test scenarios prepared

## NVDA Setup (Windows)

1. Download NVDA: https://www.nvaccess.org/download/
2. Install and restart
3. Press NVDA+N to open menu
4. Configure speech rate (comfortable pace)

## Test Scenarios

### Scenario 1: Homepage Navigation

1. Start NVDA
2. Navigate to https://staging.aigensa.com
3. Press H key to jump through headings
   - ✅ Verify: All headings announced in logical order
   - ✅ Verify: Heading levels (H1, H2, H3) correct
4. Press Tab to navigate through links
   - ✅ Verify: All links have meaningful text
   - ✅ Verify: "Click here" or "Read more" are avoided
5. Press D to jump through landmarks
   - ✅ Verify: Header, nav, main, footer present

### Scenario 2: Contact Form Completion

1. Navigate to contact form: https://staging.aigensa.com/contact.html
2. Press F to jump to form
3. Tab through form fields
   - ✅ Verify: Each field has label announced
   - ✅ Verify: Required fields indicated
   - ✅ Verify: Error messages announced clearly
4. Fill out form with test data
5. Submit form
   - ✅ Verify: Success message announced
   - ✅ Verify: Focus moved to confirmation

### Scenario 3: Keyboard-Only Navigation

1. Disable mouse (unplug or software disable)
2. Navigate entire site using only keyboard
3. Tab through all interactive elements
   - ✅ Verify: Visible focus indicator on all elements
   - ✅ Verify: No keyboard traps (can Tab out of all elements)
   - ✅ Verify: Logical tab order (left-to-right, top-to-bottom)
4. Use Enter/Space to activate buttons and links
   - ✅ Verify: All interactive elements respond to Enter or Space

### Scenario 4: Mobile Screen Reader (VoiceOver iOS)

1. Enable VoiceOver: Settings → Accessibility → VoiceOver
2. Navigate to mobile site
3. Swipe right to move through elements
   - ✅ Verify: All content accessible
   - ✅ Verify: Images have alt text
   - ✅ Verify: Buttons have clear labels
4. Double-tap to activate elements
   - ✅ Verify: All interactive elements work

## Common Issues & Remediation

| Issue | Remediation |
|-------|-------------|
| "Link" announced without text | Add aria-label or visible text |
| "Button" without name | Add text content or aria-label |
| Form field not labeled | Add <label for="field-id"> |
| Heading order skipped (H1 → H3) | Fix heading hierarchy |
| Image announced as filename | Add descriptive alt text |
| No skip link | Add "Skip to main content" link |

## Pass/Fail Criteria

✅ **PASS**: All scenarios complete without accessibility barriers
❌ **FAIL**: Any scenario blocked by accessibility issue

## Sign-off

- Tester: _______________
- Screen Reader: ☐ NVDA  ☐ JAWS  ☐ VoiceOver
- Date: _______________
- Result: ☐ PASS  ☐ FAIL
- Issues Found: _______________
```

---

## Manual Testing: Keyboard Navigation

**File**: `tests/manual/keyboard-navigation.md`

```markdown
# Keyboard Navigation Testing

**NFR ID**: a11y-001
**Fitness Function**: WCAG 2.0 Level AA - Operable

## Test Procedure

### Prerequisites
- Disable mouse or unplug it
- Open browser (Chrome, Firefox, or Safari)

### Test Steps

1. Navigate to https://staging.aigensa.com
2. Press Tab key repeatedly
   - ✅ All interactive elements receive focus
   - ✅ Focus indicator clearly visible (outline, border, highlight)
   - ✅ Tab order follows logical flow (left-to-right, top-to-bottom)
3. Press Shift+Tab to go backward
   - ✅ Focus moves backward correctly
4. Press Enter on links
   - ✅ Links navigate correctly
5. Press Space on buttons
   - ✅ Buttons activate correctly
6. Press Escape on modals (if any)
   - ✅ Modals close correctly
7. Test skip link
   - ✅ First Tab shows "Skip to main content" link
   - ✅ Pressing Enter skips to main content

## Checklist

- [ ] All pages are keyboard navigable
- [ ] Focus indicators are visible (2px outline minimum)
- [ ] No keyboard traps (can Tab out of all elements)
- [ ] Skip links present on all pages
- [ ] Enter activates links
- [ ] Space activates buttons
- [ ] Form fields accessible via Tab
- [ ] Dropdowns navigable with arrow keys (if any)

## Pass/Fail

✅ **PASS**: All checklist items complete
❌ **FAIL**: Any keyboard barrier found
```

---

## Verification Checklist

- [x] Fitness function definition created (this document)
- [x] Pa11y-CI already configured (`.pa11yci.json`)
- [x] CI/CD workflow already configured (`.github/workflows/accessibility-check.yml`)
- [x] Tests 6 pages automatically
- [ ] Consider making blocking (currently non-blocking)
- [ ] Screen reader testing procedure documented
- [ ] Keyboard navigation testing procedure documented
- [ ] Manual testing executed pre-release
- [ ] Team trained on accessibility remediation

---

## Success Metrics

After implementation:
- ✅ 100% of PRs undergo accessibility testing (already happening!)
- ✅ Zero WCAG 2.0 Level AA violations in production
- ✅ Pre-release manual testing (screen reader + keyboard) completed
- ✅ Legal compliance maintained (Section 508, ADA)
- ✅ User satisfaction improved for users with disabilities
- ✅ Future: Make blocking once team is confident
