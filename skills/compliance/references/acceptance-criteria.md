# Acceptance Criteria Validation

> **Reference for:** compliance skill - Phase 4
> **Context:** Extracting and validating acceptance criteria from PRDs

## Overview

This phase validates that implementation meets documented business requirements by extracting acceptance criteria from PRDs and cross-referencing with code.

**Input:** PRD markdown files (`docs/archive/root/PRD-*.md`)
**Output:** Compliance report (`docs/compliance-report.md`)

## Process

### Step 1: Extract Acceptance Criteria

Parse PRD markdown files for acceptance criteria sections:

**Supported patterns:**

```markdown
## Acceptance Criteria

**Must Have (P0):**
- [ ] All Lambda functions use TypeScript strict mode
- [ ] API responses match OpenAPI schemas
- [ ] Test coverage reaches 80% for all modules

**Should Have (P1):**
- [ ] JSDoc comments on all public APIs
- [ ] Performance benchmarks maintain baseline

**Could Have (P2):**
- [ ] Automated API documentation generation
```

**Alternative patterns:**

```markdown
### Success Criteria
- All endpoints return valid JSON
- Authentication required for protected routes
- Rate limiting enforced (100 req/min)

### Constraints
- Lambda cold start < 500ms
- Bundle size < 1MB
- No environment variables (Lambda@Edge)
```

**Extraction code:**

```typescript
import fs from 'fs';

function extractAcceptanceCriteria(prdPath: string): AcceptanceCriterion[] {
  const content = fs.readFileSync(prdPath, 'utf8');
  const criteria: AcceptanceCriterion[] = [];

  // Pattern 1: Must Have (P0)
  const mustHaveMatch = content.match(/\*\*Must Have \(P0\):\*\*([\s\S]*?)(?=\n\*\*|$)/);
  if (mustHaveMatch) {
    const lines = mustHaveMatch[1].split('\n');
    lines.forEach((line) => {
      const match = line.match(/^-\s+\[\s*\]\s+(.+)$/);
      if (match) {
        criteria.push({
          priority: 'P0',
          description: match[1].trim(),
          source: prdPath,
        });
      }
    });
  }

  // Pattern 2: Should Have (P1)
  const shouldHaveMatch = content.match(/\*\*Should Have \(P1\):\*\*([\s\S]*?)(?=\n\*\*|$)/);
  if (shouldHaveMatch) {
    const lines = shouldHaveMatch[1].split('\n');
    lines.forEach((line) => {
      const match = line.match(/^-\s+\[\s*\]\s+(.+)$/);
      if (match) {
        criteria.push({
          priority: 'P1',
          description: match[1].trim(),
          source: prdPath,
        });
      }
    });
  }

  return criteria;
}
```

### Step 2: Search Codebase for Implementation

For each criterion, search for implementation evidence:

```typescript
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

async function findImplementationEvidence(criterion: AcceptanceCriterion): Promise<Evidence> {
  // Extract keywords from criterion
  const keywords = extractKeywords(criterion.description);
  // e.g., "API responses match OpenAPI schemas" → ["API", "responses", "OpenAPI", "schemas"]

  const evidence: Evidence = {
    implemented: false,
    tested: false,
    files: [],
    tests: [],
  };

  // Search for implementation
  for (const keyword of keywords) {
    const { stdout } = await execAsync(`git grep -i "${keyword}" -- '*.ts' '*.js' | head -20`);
    if (stdout) {
      evidence.files.push(...parseGrepOutput(stdout));
      evidence.implemented = true;
    }
  }

  // Search for tests
  for (const keyword of keywords) {
    const { stdout } = await execAsync(`git grep -i "${keyword}" -- '**/__tests__/*.ts' | head -20`);
    if (stdout) {
      evidence.tests.push(...parseGrepOutput(stdout));
      evidence.tested = true;
    }
  }

  return evidence;
}

function extractKeywords(description: string): string[] {
  // Remove common words and extract significant terms
  const stopWords = ['the', 'a', 'an', 'all', 'for', 'to', 'of', 'in', 'on'];
  const words = description
    .toLowerCase()
    .split(/\W+/)
    .filter((w) => w.length > 3 && !stopWords.includes(w));

  return [...new Set(words)]; // Deduplicate
}
```

### Step 3: Calculate Compliance Score

Score each criterion based on implementation and testing:

```typescript
function calculateComplianceScore(criterion: AcceptanceCriterion, evidence: Evidence): ComplianceScore {
  let score = 0;

  // Scoring rubric:
  // - Implemented: 50 points
  // - Tested: 50 points
  // Total: 100 points

  if (evidence.implemented) {
    score += 50;
  }

  if (evidence.tested) {
    score += 50;
  }

  return {
    criterion,
    evidence,
    score,
    status: score >= 100 ? 'met' : score >= 50 ? 'partial' : 'not met',
  };
}
```

### Step 4: Generate Compliance Report

Create markdown report with findings:

```markdown
# Compliance Report - 2026-02-06

## Summary
- **Overall Score:** 92% (23/25 criteria met)
- **Must Have (P0):** 8/9 met (89%)
- **Should Have (P1):** 15/16 met (94%)

---

## PRD: TypeScript Conversion

**Source:** docs/archive/root/PRD-TYPESCRIPT-CONVERSION.md

### Must Have (P0) - 8/9 criteria met

✅ **All Lambda functions use TypeScript strict mode**
- **Evidence:**
  - Implementation: `tsconfig.json:5` - `"strict": true`
  - Tests: `infrastructure/__tests__/typescript-config.test.ts:12`
- **Status:** Met (100%)

✅ **API responses match OpenAPI schemas**
- **Evidence:**
  - Implementation: `lambda/admin/index.ts:45-67`
  - Tests: `lambda/admin/__tests__/contract.test.ts:18-42`
- **Status:** Met (100%)

❌ **Custom type declarations for all dependencies**
- **Evidence:**
  - Implementation: Not found
  - Missing: @types/markdown-it-anchor, @types/markdown-it-toc-done-right
- **Status:** Not Met (0%)
- **Recommendation:** Create custom .d.ts files or update packages

✅ **Test coverage reaches 80% for all modules**
- **Evidence:**
  - Implementation: Jest coverage reports show 85% overall
  - Tests: All test suites passing
- **Status:** Met (100%)

---

### Should Have (P1) - 15/16 criteria met

✅ **JSDoc comments on all public APIs**
- **Evidence:**
  - Implementation: 95% of exported functions have JSDoc
  - Tests: ESLint rule `require-jsdoc` enforced
- **Status:** Met (100%)

⚠️ **Performance benchmarks maintain baseline**
- **Evidence:**
  - Implementation: Benchmarks exist in `infrastructure/__tests__/performance.test.ts`
  - Gap: Lambda cold start increased by 12%
- **Status:** Partial (50%)
- **Recommendation:** Optimize bundle size, enable tree-shaking

---

## Recommendations

### High Priority

1. **Create custom type declarations**
   - Files needed:
     - `src/types/markdown-it-anchor.d.ts`
     - `src/types/markdown-it-toc-done-right.d.ts`
   - Estimated effort: 2 hours
   - Criteria: AC-05

2. **Optimize Lambda cold start performance**
   - Current: 612ms (baseline: 500ms)
   - Target: < 550ms
   - Actions:
     - Analyze bundle size with webpack-bundle-analyzer
     - Enable tree-shaking
     - Remove unused dependencies
   - Estimated effort: 6 hours
   - Criteria: AC-16

---

## Overall Assessment

**Status:** ✅ **COMPLIANT** (92% score, threshold: 90%)

All critical (P0) business requirements met except custom type declarations. One P1 requirement (performance) partially met. Clear remediation path identified.

**Ready for production release:** Pending type declarations fix.
```

### Step 5: GitHub Integration (Optional)

Create GitHub issues for missing criteria:

```bash
# Create issue for missing criterion
gh issue create \
  --title "AC-05: Create custom type declarations" \
  --body "**Acceptance Criterion:** Custom type declarations for all dependencies

**Status:** Not Met

**Evidence:** Missing type declarations:
- @types/markdown-it-anchor
- @types/markdown-it-toc-done-right

**Recommendation:** Create custom .d.ts files in src/types/

**Source:** docs/archive/root/PRD-TYPESCRIPT-CONVERSION.md

**Estimated Effort:** 2 hours" \
  --label "compliance,P0"
```

## Scoring Rubric

| Evidence | Score | Status |
|----------|-------|---------|
| Implemented + Tested | 100 | ✅ Met |
| Implemented only | 50 | ⚠️ Partial |
| Not implemented | 0 | ❌ Not Met |

## Search Patterns

**Common keyword mappings:**

| Criterion | Keywords | Files to search |
|-----------|----------|-----------------|
| "TypeScript strict mode" | `strict`, `tsconfig` | `tsconfig.json`, `**/tsconfig.json` |
| "OpenAPI schemas" | `openapi`, `schema`, `ajv` | `docs/api/*.yaml`, `**/__tests__/contract.test.ts` |
| "Test coverage 80%" | `coverage`, `threshold` | `jest.config.js`, `package.json` |
| "JSDoc comments" | `jsdoc`, `@param`, `@returns` | `**/*.ts` (exclude tests) |
| "Lambda cold start" | `cold start`, `performance`, `benchmark` | `**/__tests__/performance.test.ts` |

## Tips

**1. Use specific keywords**
- Extract technical terms from criteria
- Avoid generic words (e.g., "all", "should")

**2. Search both implementation and tests**
- Implementation proves feature exists
- Tests prove feature works

**3. Document evidence with file paths and line numbers**
- Makes verification easy
- Links criteria to code

**4. Provide actionable recommendations**
- Don't just report gaps
- Suggest how to fix them

**5. Prioritize by P0/P1/P2**
- Focus on Must Have (P0) first
- Should Have (P1) next
- Could Have (P2) last

## Troubleshooting

**Issue: No criteria extracted**
- **Cause:** PRD uses different format
- **Fix:** Add extraction pattern for PRD format

**Issue: False positives (criterion marked met but not actually implemented)**
- **Cause:** Keyword search too broad
- **Fix:** Use more specific keywords or manual verification

**Issue: False negatives (criterion marked not met but actually implemented)**
- **Cause:** Implementation uses different terminology
- **Fix:** Add synonyms to keyword search

## Next Steps

After generating compliance report:

1. Review with stakeholders
2. Create GitHub issues for gaps
3. Track compliance over time
4. Update PRDs as requirements evolve
