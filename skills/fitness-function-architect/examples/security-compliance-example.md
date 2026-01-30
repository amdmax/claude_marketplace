# Security & Compliance Fitness Function Example: OWASP Top 10

Reference implementation for the NFR: **"Zero CRITICAL or HIGH severity OWASP Top 10:2025 vulnerabilities"**

---

## Business Context

- **Business Type**: Fintech
- **User Base**: Enterprise customers + consumers
- **Risk Profile**: Security breaches
- **Compliance**: SOC 2, PCI-DSS
- **NFR Priority**: Security & Compliance (CRITICAL)

---

## Good News: Already Implemented! ✅

Your project **already has comprehensive OWASP Top 10:2025 security review** integrated into the code review process!

**Existing Implementation**:
- `.github/CODE_REVIEW_PROCESS.md` - 4-phase review process
- `.github/code-review/prompts/01-security-review.md` - **15 OWASP categories**
- `.github/workflows/claude-code-review.yml` - Automated security review on PRs
- `.github/code-review/config/review-config.yml` - Configuration (blocking for CRITICAL/HIGH)

---

## Fitness Function Definition

**File**: `.claude/fitness-functions/fitness-functions/security/owasp-compliance.yml`

```yaml
fitness_function:
  id: "sec-001"
  name: "owasp_top10_2025_compliance"
  category: "security"
  nfr_description: "Zero CRITICAL or HIGH severity OWASP Top 10:2025 vulnerabilities"

  business_context:
    priority: "CRITICAL"
    rationale: "Security breaches lead to financial loss, regulatory fines, and reputational damage"
    stakeholder: "CISO / VP of Engineering"
    compliance_requirement: "SOC 2 (CC6.1, CC6.6, CC6.7)"

  measurement:
    type: "vulnerability_count"
    source: "Claude Code Review + npm audit + Semgrep"
    categories:
      - "Broken Access Control (A01:2025)"
      - "Cryptographic Failures (A02:2025)"
      - "Injection (A03:2025)"
      - "Insecure Design (A04:2025)"
      - "Security Misconfiguration (A05:2025)"
      - "Vulnerable and Outdated Components (A06:2025)"
      - "Identification and Authentication Failures (A07:2025)"
      - "Software and Data Integrity Failures (A08:2025)"
      - "Security Logging and Monitoring Failures (A09:2025)"
      - "Server-Side Request Forgery (A10:2025)"
    severity_levels:
      - "CRITICAL"
      - "HIGH"
      - "MEDIUM"
      - "LOW"

  threshold:
    critical: 0  # Zero tolerance for CRITICAL
    high: 0      # Zero tolerance for HIGH
    medium: 5    # Up to 5 MEDIUM findings acceptable (with remediation plan)
    low: 20      # Up to 20 LOW findings acceptable

  test_implementation:
    automated:
      - type: "code_review"
        framework: "Claude Code Review"
        file: ".github/code-review/prompts/01-security-review.md"
        trigger: "PR opened/updated"
        stage: "Phase 1 (Security Review)"
      - type: "dependency_scan"
        framework: "npm audit"
        command: "npm audit --audit-level=moderate"
        trigger: "PR to master"
      - type: "static_analysis"
        framework: "Semgrep"
        rules: "OWASP Top 10"
        trigger: "PR to master"
    manual:
      - type: "penetration_testing"
        frequency: "Quarterly"
        provider: "External security firm"
      - type: "code_audit"
        frequency: "Pre-release"
        reviewer: "Security team"

  ci_cd_gate:
    stage: "pre-merge"
    blocking: true  # Blocks PR for CRITICAL/HIGH
    failure_action: "Block PR merge, create security issue, notify security team"
    success_criteria: "Zero CRITICAL or HIGH vulnerabilities"

  remediation:
    guidance: |
      If this fitness function fails (CRITICAL or HIGH vulnerability found):

      **Immediate Actions**:
      1. Do NOT merge PR
      2. Create security issue in GitHub (private)
      3. Notify security team via Slack
      4. Assess if production is affected

      **Remediation by Category**:

      **A01 - Broken Access Control**:
      - Implement proper authorization checks
      - Use least-privilege principle
      - Test with non-admin users

      **A02 - Cryptographic Failures**:
      - Use TLS 1.2+ for all connections
      - Encrypt sensitive data at rest (AWS KMS)
      - Never log secrets or PII

      **A03 - Injection (SQL, NoSQL, Command)**:
      - Use parameterized queries
      - Validate and sanitize all inputs
      - Use ORM/ODM libraries

      **A04 - Insecure Design**:
      - Implement threat modeling
      - Add security requirements to PRD
      - Review architecture with security team

      **A05 - Security Misconfiguration**:
      - Disable debug mode in production
      - Remove default credentials
      - Harden server configurations

      **A06 - Vulnerable Components**:
      - Update dependencies immediately
      - Run `npm audit fix`
      - Check for security patches

      **A07 - Auth Failures**:
      - Implement MFA where possible
      - Use secure session management
      - Add rate limiting on auth endpoints

      **A08 - Integrity Failures**:
      - Use SRI for CDN resources
      - Verify package integrity
      - Sign critical artifacts

      **A09 - Logging Failures**:
      - Log all authentication events
      - Never log sensitive data
      - Set up alerting for suspicious activity

      **A10 - SSRF**:
      - Validate and sanitize URLs
      - Use allowlists for external services
      - Disable unnecessary network protocols

      **Escalation**:
      - CRITICAL: Immediate fix required, security incident declared
      - HIGH: Fix within 24 hours, block release
      - MEDIUM: Fix within 1 week
      - LOW: Fix within 1 month or accept risk
```

---

## Existing Implementation: Claude Code Review

Your project already has a comprehensive security review process!

**Phase 1: Security Review** (`.github/code-review/prompts/01-security-review.md`)

Covers **15 OWASP categories**:
1. Broken Access Control
2. Cryptographic Failures
3. Injection (SQL, NoSQL, Command)
4. Insecure Design
5. Security Misconfiguration
6. Vulnerable Components
7. Authentication Failures
8. Data Integrity Failures
9. Logging Failures
10. SSRF
11. XSS
12. CSRF
13. Path Traversal
14. Unvalidated Redirects
15. Security Headers

**Workflow**: `.github/workflows/claude-code-review.yml`
```yaml
security-review:
  runs-on: ubuntu-latest
  steps:
    - uses: anthropics/claude-code-action@v1
      with:
        prompt_file: .github/code-review/prompts/01-security-review.md
        github_token: ${{ secrets.GITHUB_TOKEN }}
```

**Configuration**: `.github/code-review/config/review-config.yml`
```yaml
review_stages:
  - name: security
    priority: 1
    blocking: true  # Blocks for CRITICAL/HIGH findings
    confidence_threshold: 75
    max_findings: 15
```

---

## Additional: npm audit Integration

Add dependency vulnerability scanning to CI/CD.

**File**: `.github/workflows/security-scan.yml`

```yaml
name: Security Scanning (Fitness Functions)

on:
  pull_request:
    branches: [master]
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday
  workflow_dispatch:

jobs:
  npm-audit:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Run npm audit
        run: |
          npm audit --audit-level=moderate --json > audit-results.json || true

      - name: Parse audit results
        id: audit
        run: |
          CRITICAL=$(jq '.metadata.vulnerabilities.critical' audit-results.json)
          HIGH=$(jq '.metadata.vulnerabilities.high' audit-results.json)
          MEDIUM=$(jq '.metadata.vulnerabilities.medium' audit-results.json)
          LOW=$(jq '.metadata.vulnerabilities.low' audit-results.json)

          echo "critical=$CRITICAL" >> $GITHUB_OUTPUT
          echo "high=$HIGH" >> $GITHUB_OUTPUT
          echo "medium=$MEDIUM" >> $GITHUB_OUTPUT
          echo "low=$LOW" >> $GITHUB_OUTPUT

          echo "### npm Audit Results" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Severity | Count | Threshold | Status |" >> $GITHUB_STEP_SUMMARY
          echo "|----------|-------|-----------|--------|" >> $GITHUB_STEP_SUMMARY
          echo "| CRITICAL | $CRITICAL | 0 | $([ $CRITICAL -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL") |" >> $GITHUB_STEP_SUMMARY
          echo "| HIGH | $HIGH | 0 | $([ $HIGH -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL") |" >> $GITHUB_STEP_SUMMARY
          echo "| MEDIUM | $MEDIUM | 5 | $([ $MEDIUM -le 5 ] && echo "✅ PASS" || echo "⚠️ WARNING") |" >> $GITHUB_STEP_SUMMARY
          echo "| LOW | $LOW | 20 | $([ $LOW -le 20 ] && echo "✅ PASS" || echo "ℹ️ INFO") |" >> $GITHUB_STEP_SUMMARY

      - name: Check fitness function (BLOCKING)
        run: |
          CRITICAL=${{ steps.audit.outputs.critical }}
          HIGH=${{ steps.audit.outputs.high }}

          if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
            echo "❌ FAILED: Found $CRITICAL CRITICAL and $HIGH HIGH vulnerabilities"
            echo ""
            echo "Remediation: Run 'npm audit fix' to automatically fix vulnerabilities"
            echo "If auto-fix fails, manually update vulnerable packages"
            exit 1
          else
            echo "✅ PASSED: No CRITICAL or HIGH vulnerabilities found"
          fi

      - name: Comment on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const critical = ${{ steps.audit.outputs.critical }};
            const high = ${{ steps.audit.outputs.high }};
            const medium = ${{ steps.audit.outputs.medium }};
            const low = ${{ steps.audit.outputs.low }};

            const passed = critical === 0 && high === 0;

            const body = `## Security Fitness Function: npm Audit

            | Severity | Count | Threshold | Status |
            |----------|-------|-----------|--------|
            | CRITICAL | ${critical} | 0 | ${critical === 0 ? '✅ PASS' : '❌ FAIL'} |
            | HIGH | ${high} | 0 | ${high === 0 ? '✅ PASS' : '❌ FAIL'} |
            | MEDIUM | ${medium} | 5 | ${medium <= 5 ? '✅ PASS' : '⚠️ WARNING'} |
            | LOW | ${low} | 20 | ${low <= 20 ? '✅ PASS' : 'ℹ️ INFO'} |

            ${passed ? '✅ No critical vulnerabilities found!' : '❌ Vulnerabilities found - PR blocked'}

            **Remediation**: Run \`npm audit fix\` to automatically fix vulnerabilities.`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: body
            });
```

---

## Manual Testing: Penetration Testing

**File**: `tests/manual/penetration-testing-procedure.md`

```markdown
# Penetration Testing Procedure

**NFR ID**: sec-001
**Fitness Function**: Zero CRITICAL/HIGH OWASP Top 10 vulnerabilities
**Frequency**: Quarterly + Pre-release (major versions)

## Prerequisites

- Staging environment with production-like configuration
- External security firm engaged (or internal pentest team)
- Scope defined and approved by stakeholders

## Scope

### In-Scope
- Contact form submission (Lambda function)
- All user-facing HTML pages
- API endpoints (if any)
- Authentication mechanisms (if any)

### Out-of-Scope
- DDoS attacks
- Physical security
- Social engineering

## OWASP Top 10 Test Cases

### A01: Broken Access Control
- [ ] Test for unauthorized data access
- [ ] Test for privilege escalation
- [ ] Test for IDOR (Insecure Direct Object References)

### A02: Cryptographic Failures
- [ ] Verify TLS 1.2+ enforced
- [ ] Check for sensitive data in logs
- [ ] Verify encryption at rest

### A03: Injection
- [ ] SQL injection (if applicable)
- [ ] NoSQL injection (if applicable)
- [ ] Command injection
- [ ] HTML injection / XSS

### A04: Insecure Design
- [ ] Review threat model
- [ ] Check for security requirements in design

### A05: Security Misconfiguration
- [ ] Check for debug mode in production
- [ ] Verify security headers present
- [ ] Check for default credentials

### A06: Vulnerable Components
- [ ] Run dependency scan (npm audit)
- [ ] Check for outdated libraries

### A07: Authentication Failures
- [ ] Test password policies (if applicable)
- [ ] Test session management (if applicable)
- [ ] Test MFA implementation (if applicable)

### A08: Integrity Failures
- [ ] Verify SRI tags on external resources
- [ ] Check package integrity

### A09: Logging Failures
- [ ] Verify security events are logged
- [ ] Verify no sensitive data in logs

### A10: SSRF
- [ ] Test for server-side request forgery
- [ ] Verify URL validation

## Deliverables

- Penetration test report (PDF)
- List of vulnerabilities by severity
- Remediation recommendations
- Executive summary

## Pass/Fail Criteria

✅ **PASS**: Zero CRITICAL or HIGH findings
❌ **FAIL**: Any CRITICAL or HIGH findings

## Sign-off

- Pentester: _______________
- Date: _______________
- CRITICAL Findings: _____
- HIGH Findings: _____
- Result: ☐ PASS  ☐ FAIL
```

---

## Verification Checklist

- [x] Fitness function definition created (this document)
- [x] Claude Code Review already configured (`.github/code-review/`)
- [x] OWASP Top 10 prompts already exist (15 categories!)
- [x] CI/CD workflow already configured (`.github/workflows/claude-code-review.yml`)
- [ ] npm audit workflow added (`.github/workflows/security-scan.yml`)
- [ ] Manual pentest procedure documented
- [ ] Quarterly pentest scheduled
- [ ] Security team onboarded to process

---

## Success Metrics

After implementation:
- ✅ 100% of PRs undergo security review (already happening!)
- ✅ Zero CRITICAL/HIGH vulnerabilities in production
- ✅ Quarterly pentests completed
- ✅ Security incidents reduced by 50%
- ✅ SOC 2 compliance maintained
