---
name: security-review
description: OWASP Top 10 + API security vulnerability scanner
---

# Security Review

## Overview

Comprehensive security analysis focusing on **OWASP Top 10 2025** (246+ CWEs) and **OWASP API Security Top 10 2023**. Use this skill before committing to identify critical security vulnerabilities including injection attacks, broken authentication, cryptographic failures, and supply chain risks.

**Coverage:** 30+ vulnerability categories across web applications and APIs.

## Workflow

### 1. Get Changed Files

```bash
git diff --name-only HEAD
# Or for staged files: git diff --cached --name-only
# Or compare branches: git diff --name-only master...HEAD
```

### 2. Analyze Each File

For each changed file, systematically check against the OWASP security checklists below using:
- **Read** tool to examine code
- **Grep** tool to search for vulnerable patterns (e.g., `eval\(`, `exec\(`, `innerHTML\s*=`)
- **Contextual analysis** to understand data flow and identify logic flaws

### 3. Report Findings

**Format (matches CI/CD):**

```
🔴 CRITICAL | 🟠 MAJOR | 🟡 MINOR

File: path/to/file.ts
Line(s): 42-45
Problem: [Brief explanation of vulnerability and impact]
Fix: [REQUIRED for CRITICAL/MAJOR] - Specific code example or remediation steps
```

**Severity Assignment:**

- **🔴 CRITICAL**: Directly exploitable, high impact (data breach, RCE, authentication bypass)
- **🟠 MAJOR**: Exploitable with moderate effort, significant impact (privilege escalation, XSS, CSRF)
- **🟡 MINOR**: Defense-in-depth issues, low immediate risk (missing headers, weak validation)

### 4. Summary

```
Total security issues: X (CRITICAL: Y, MAJOR: Z, MINOR: W)
Files reviewed: N
Most common issues: [top 3 vulnerability types found]

⚠️ Critical findings require immediate remediation before commit.
```

## OWASP Top 10 2025 Checklist

### A01:2025 - Broken Access Control (40 CWEs - Maximum)

**Path Traversal:**
- [ ] CWE-22: Directory traversal (`../`, absolute paths in file operations)
- [ ] CWE-23: Relative path traversal
- [ ] CWE-36: Absolute path traversal
- [ ] CWE-59: Improper link resolution before file access
- [ ] CWE-65: Windows path traversal (`\..\\`)

**Pattern Search:**
```
fs\.readFile.*req\.(query|body|params)
path\.join.*req\.(query|body|params)
\.\.\/
```

**Information Disclosure:**
- [ ] CWE-200: Exposure of sensitive information (stack traces, debug info)
- [ ] CWE-201: Information disclosure through sent data
- [ ] CWE-219: Storage of files in web root
- [ ] CWE-359: Exposure of private information
- [ ] CWE-497: Exposure of system data to unauthorized control sphere

**Access Control Failures:**
- [ ] CWE-284: Improper access control
- [ ] CWE-285: Improper authorization
- [ ] CWE-352: Cross-Site Request Forgery (CSRF) - missing tokens
- [ ] CWE-862: Missing authorization checks
- [ ] CWE-863: Incorrect authorization
- [ ] CWE-918: Server-Side Request Forgery (SSRF)

**Application-Level Checks:**
- [ ] IDOR (Insecure Direct Object References) - user ID in URL without validation
- [ ] Forced browsing - admin routes accessible without role check
- [ ] CORS misconfiguration - `Access-Control-Allow-Origin: *` with credentials
- [ ] JWT tampering - no signature verification or algorithm confusion (`alg: none`)

**Pattern Search:**
```
Access-Control-Allow-Origin:\s*\*
jwt\.decode\((?!.*verify)
if.*\.role\s*==\s*['"]admin['"].*// missing else/default deny
```

**🔴 CRITICAL Example:**
```typescript
// VULNERABLE: IDOR without authorization
app.get('/api/users/:id/profile', (req, res) => {
  const profile = db.getProfile(req.params.id); // No check if user owns this profile
  res.json(profile);
});

// FIX: Verify ownership
app.get('/api/users/:id/profile', authenticate, (req, res) => {
  if (req.user.id !== req.params.id && !req.user.isAdmin) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  const profile = db.getProfile(req.params.id);
  res.json(profile);
});
```

### A02:2025 - Security Misconfiguration (16 CWEs)

**Configuration Issues:**
- [ ] CWE-16: Configuration flaws (default passwords, unnecessary features enabled)
- [ ] CWE-611: Improper restriction of XML External Entity (XXE)
- [ ] CWE-13: ASP.NET misconfiguration (passwords in config files)
- [ ] CWE-489: Debug code in production
- [ ] CWE-526: Exposure of environment variables
- [ ] CWE-614: Sensitive cookie without 'HttpOnly' flag

**Checks:**
- [ ] Default credentials (`admin/admin`, `root/root`)
- [ ] Unnecessary features enabled (directory listing, unused endpoints)
- [ ] Stack traces leaked to users
- [ ] Missing security headers (CSP, X-Frame-Options, HSTS, X-Content-Type-Options)
- [ ] Debug mode enabled in production
- [ ] Verbose error messages exposing internals

**Pattern Search:**
```
console\.log.*password
res\.json\(error\.stack\)
app\.use\(cors\(\)\).*// no options
Set-Cookie:.*(?!HttpOnly)(?!Secure)
```

**🟠 MAJOR Example:**
```typescript
// VULNERABLE: Missing security headers
app.use(express.json());

// FIX: Add security headers
import helmet from 'helmet';
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"], // Minimize unsafe-inline
      styleSrc: ["'self'", "'unsafe-inline'"]
    }
  },
  hsts: { maxAge: 31536000, includeSubDomains: true }
}));
```

### A03:2025 - Software Supply Chain Failures (5 CWEs) - NEW

**Dependency Risks:**
- [ ] CWE-1035: Components with known vulnerabilities
- [ ] CWE-1104: Use of unmaintained third-party components
- [ ] CWE-1329: Reliance on component that is not updateable
- [ ] CWE-447: Unimplemented or unsupported feature in UI (obsolete functions)
- [ ] CWE-1357: Reliance on insufficiently trustworthy component

**Checks:**
- [ ] Outdated dependencies (`npm outdated`, `npm audit`)
- [ ] Missing SBOM (Software Bill of Materials)
- [ ] No integrity checks for CDN resources (missing SRI hashes)
- [ ] Unsigned packages or artifacts
- [ ] Dependencies from unverified sources
- [ ] No supply chain attack detection (vendor compromise monitoring)

**Pattern Search:**
```
<script src="https://cdn.*(?!integrity=)
npm install.*--ignore-scripts
package\.json.*"dependencies".*\^0\.|~0\.
```

**🟠 MAJOR Example:**
```html
<!-- VULNERABLE: CDN without integrity check -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"></script>

<!-- FIX: Add SRI hash -->
<script
  src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"
  integrity="sha384-abc123..."
  crossorigin="anonymous"
></script>
```

### A04:2025 - Cryptographic Failures

**Encryption Issues:**
- [ ] Weak algorithms (MD5, SHA1 for passwords, DES, RC4)
- [ ] Hardcoded secrets (API keys, passwords, encryption keys in code)
- [ ] Insecure storage (plaintext passwords, unencrypted PII)
- [ ] Missing encryption (sensitive data transmitted over HTTP)
- [ ] Weak key generation (predictable seeds, insufficient entropy)
- [ ] Broken crypto implementations (custom algorithms, ECB mode)

**Pattern Search:**
```
password\s*=\s*['"][^'"]+['"]
api[_-]?key\s*=\s*['"][^'"]+['"]
createHash\(['"]md5['"]
createHash\(['"]sha1['"].*password
http://.*(?=password|token|api[_-]?key)
```

**🔴 CRITICAL Example:**
```typescript
// VULNERABLE: Hardcoded secret
const JWT_SECRET = "my-secret-key-123";

// FIX: Use environment variables
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable must be set');
}

// VULNERABLE: Weak password hashing
const hash = crypto.createHash('md5').update(password).digest('hex');

// FIX: Use bcrypt with sufficient cost factor
import bcrypt from 'bcrypt';
const hash = await bcrypt.hash(password, 12);
```

### A05:2025 - Injection (37 CWEs)

**SQL Injection (CWE-89):**
- [ ] String concatenation in SQL queries
- [ ] Unsanitized user input in database operations
- [ ] ORM bypasses with raw queries

**Pattern Search:**
```
SELECT.*\$\{.*\}
execute\(.*\+.*req\.(query|body|params)
WHERE.*=.*req\.(query|body|params)
db\.query\([`'"].*\$\{
```

**Command Injection (CWE-77, 78):**
- [ ] `exec()`, `spawn()`, `child_process` with user input
- [ ] Shell command construction from untrusted data

**Pattern Search:**
```
exec\(.*req\.(query|body|params)
spawn\(.*req\.(query|body|params)
system\(.*\$_GET
```

**Cross-Site Scripting (CWE-79, 80, 83, 86):**
- [ ] `innerHTML`, `outerHTML`, `document.write()` with user input
- [ ] Unescaped template rendering
- [ ] DOM-based XSS through location, URL parameters

**Pattern Search:**
```
innerHTML\s*=.*req\.(query|body|params)
\.html\(.*req\.(query|body|params)
document\.write\(.*location\.
dangerouslySetInnerHTML
```

**Other Injection Types:**
- [ ] CWE-90: LDAP injection
- [ ] CWE-91: XML injection
- [ ] CWE-94: Code injection (`eval()`, `Function()`)
- [ ] CWE-98: PHP file inclusion
- [ ] CWE-917: Expression Language (EL) injection
- [ ] NoSQL injection (MongoDB `$where`, `$regex`)

**Pattern Search:**
```
eval\(
new Function\(.*req\.
\$where:.*req\.(query|body|params)
require\(.*req\.
```

**🔴 CRITICAL Example:**
```typescript
// VULNERABLE: SQL injection
const query = `SELECT * FROM users WHERE email = '${req.body.email}'`;
db.execute(query);

// FIX: Use parameterized queries
const query = 'SELECT * FROM users WHERE email = ?';
db.execute(query, [req.body.email]);

// VULNERABLE: XSS
res.send(`<h1>Welcome ${req.query.name}</h1>`);

// FIX: Escape output or use templating
import { escape } from 'html-escaper';
res.send(`<h1>Welcome ${escape(req.query.name)}</h1>`);
```

### A06:2025 - Insecure Design

**Design-Level Issues:**
- [ ] Missing security requirements in design phase
- [ ] No threat modeling performed
- [ ] Business logic flaws (race conditions, state manipulation)
- [ ] Missing rate limiting / anti-automation
- [ ] No principle of least privilege in architecture
- [ ] Trusting client-side security controls

**Checks:**
- [ ] Can users manipulate order of operations? (pay after shipping)
- [ ] Are there race conditions in concurrent operations?
- [ ] Is rate limiting present on sensitive endpoints?
- [ ] Does design assume client-side validation is sufficient?
- [ ] Are business rules enforced server-side?

**🟠 MAJOR Example:**
```typescript
// VULNERABLE: Business logic flaw - no rate limiting
app.post('/api/password-reset', async (req, res) => {
  await sendPasswordResetEmail(req.body.email);
  res.json({ success: true });
});

// FIX: Add rate limiting
import rateLimit from 'express-rate-limit';
const resetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 3, // 3 requests per window
  message: 'Too many password reset attempts, try again later'
});
app.post('/api/password-reset', resetLimiter, async (req, res) => {
  await sendPasswordResetEmail(req.body.email);
  res.json({ success: true });
});
```

### A07:2025 - Authentication Failures

**Authentication Issues:**
- [ ] Weak password policies (no length/complexity requirements)
- [ ] Credential stuffing protection missing (no account lockout)
- [ ] Session fixation vulnerabilities
- [ ] Missing multi-factor authentication (MFA)
- [ ] Predictable session IDs or tokens
- [ ] Insecure password recovery (security questions, unverified email)
- [ ] Credentials transmitted over unencrypted connections

**Pattern Search:**
```
password\.length\s*<\s*[1-7]
session\.id\s*=.*Math\.random
setCookie.*session.*(?!HttpOnly)(?!Secure)
```

**🔴 CRITICAL Example:**
```typescript
// VULNERABLE: No password complexity requirements
if (password.length >= 6) {
  createAccount(email, password);
}

// FIX: Enforce strong password policy
import passwordValidator from 'password-validator';
const schema = new passwordValidator();
schema
  .is().min(12)
  .has().uppercase()
  .has().lowercase()
  .has().digits()
  .has().symbols()
  .has().not().spaces();

if (!schema.validate(password)) {
  return res.status(400).json({
    error: 'Password must be 12+ chars with uppercase, lowercase, digit, and symbol'
  });
}
```

### A08:2025 - Software and Data Integrity Failures

**Integrity Issues:**
- [ ] Insecure deserialization (untrusted data to objects)
- [ ] Missing code signing for updates
- [ ] Auto-update without integrity verification
- [ ] CI/CD pipelines without security controls
- [ ] No verification of plugin/extension integrity
- [ ] Cache poisoning vulnerabilities

**Pattern Search:**
```
JSON\.parse.*req\.(body|query).*(?!try)
pickle\.loads?\(
unserialize\(
eval\(.*JSON\.parse
```

**🔴 CRITICAL Example:**
```typescript
// VULNERABLE: Insecure deserialization
app.post('/api/settings', (req, res) => {
  const settings = eval(`(${req.body.data})`); // RCE!
  saveSettings(settings);
});

// FIX: Use safe JSON parsing with validation
app.post('/api/settings', (req, res) => {
  try {
    const settings = JSON.parse(req.body.data);
    // Validate against schema
    if (!isValidSettings(settings)) {
      return res.status(400).json({ error: 'Invalid settings format' });
    }
    saveSettings(settings);
  } catch (e) {
    return res.status(400).json({ error: 'Invalid JSON' });
  }
});
```

### A09:2025 - Security Logging and Alerting Failures (5 CWEs)

**Logging Issues:**
- [ ] CWE-778: Insufficient logging
- [ ] CWE-117: Log injection (unsanitized data in logs)
- [ ] Missing audit logs for security events
- [ ] No alerting for suspicious activity
- [ ] Logs stored insecurely (world-readable)

**Checks:**
- [ ] Are failed login attempts logged?
- [ ] Are access control failures logged?
- [ ] Are input validation failures logged?
- [ ] Is there alerting for repeated failed attempts?
- [ ] Are logs protected from tampering?

**🟡 MINOR Example:**
```typescript
// VULNERABLE: No logging for failed authentication
if (!validatePassword(password)) {
  return res.status(401).json({ error: 'Invalid credentials' });
}

// FIX: Log security events
import logger from './logger';
if (!validatePassword(password)) {
  logger.warn('Failed login attempt', {
    email: req.body.email,
    ip: req.ip,
    timestamp: new Date().toISOString()
  });
  return res.status(401).json({ error: 'Invalid credentials' });
}
```

### A10:2025 - Mishandling of Exceptional Conditions (24 CWEs) - NEW

**Error Handling Issues:**
- [ ] Improper error handling (unhandled exceptions)
- [ ] Logical errors (off-by-one, null pointer dereference)
- [ ] Failing open (granting access on error)
- [ ] Unhandled exceptions exposing sensitive information

**Checks:**
- [ ] Are all exceptions caught and handled?
- [ ] Does error handling default to "deny" not "allow"?
- [ ] Are error messages generic to users?
- [ ] Are errors logged without exposing stack traces?

**🟠 MAJOR Example:**
```typescript
// VULNERABLE: Failing open on error
app.use(async (req, res, next) => {
  try {
    await checkAuthorization(req.user, req.path);
    next();
  } catch (err) {
    next(); // ERROR: Allows access on exception!
  }
});

// FIX: Fail closed (deny by default)
app.use(async (req, res, next) => {
  try {
    await checkAuthorization(req.user, req.path);
    next();
  } catch (err) {
    logger.error('Authorization check failed', err);
    res.status(500).json({ error: 'Authorization error' }); // Deny access
  }
});
```

## OWASP API Security Top 10 2023 Checklist

### API1:2023 - Broken Object Level Authorization

- [ ] API endpoints access objects by ID without ownership verification
- [ ] Missing authorization checks for each object access
- [ ] IDOR in REST APIs (`/api/users/{id}` accessible by any authenticated user)

**Pattern Search:**
```
\/api\/[^/]+\/:\w+(?!.*authenticate)
params\.(id|userId).*(?!.*req\.user)
```

### API2:2023 - Broken Authentication

- [ ] Weak token validation (no expiration, no signature check)
- [ ] Authentication credentials in URL
- [ ] No refresh token rotation
- [ ] Password reset tokens don't expire

### API3:2023 - Broken Object Property Level Authorization

- [ ] Mass assignment vulnerabilities (`req.body` directly to model)
- [ ] Excessive data exposure (returning full object with sensitive fields)
- [ ] No field-level authorization

**🟠 MAJOR Example:**
```typescript
// VULNERABLE: Mass assignment
app.put('/api/users/:id', (req, res) => {
  db.users.update(req.params.id, req.body); // User can set isAdmin=true!
});

// FIX: Whitelist allowed fields
app.put('/api/users/:id', (req, res) => {
  const allowedFields = ['name', 'email', 'bio'];
  const updates = {};
  for (const field of allowedFields) {
    if (req.body[field] !== undefined) {
      updates[field] = req.body[field];
    }
  }
  db.users.update(req.params.id, updates);
});
```

### API4:2023 - Unrestricted Resource Consumption

- [ ] No rate limiting on API endpoints
- [ ] No pagination limits (can request unlimited records)
- [ ] No timeout on long-running operations
- [ ] File upload size not restricted

### API5:2023 - Broken Function Level Authorization

- [ ] Admin functions accessible to regular users
- [ ] No role-based access control (RBAC)
- [ ] Authorization checks only on UI, not API

**Pattern Search:**
```
\/api\/admin\/.*(?!.*requireAdmin)
if.*isAdmin.*(?!else)
```

### API6:2023 - Unrestricted Access to Sensitive Business Flows

- [ ] No CAPTCHA on registration/payment flows
- [ ] Automated abuse possible (ticket purchasing bots, voting manipulation)
- [ ] No detection of automated tools

### API7:2023 - Server Side Request Forgery (SSRF)

- [ ] URL fetching without validation
- [ ] Internal network scanning possible
- [ ] Cloud metadata endpoints accessible

**Pattern Search:**
```
fetch\(.*req\.(query|body|params).*(?!whitelist)
axios\.get\(.*req\.(query|body|params)
http\.request\(.*req\.
```

**🔴 CRITICAL Example:**
```typescript
// VULNERABLE: SSRF - fetch arbitrary URLs
app.get('/api/proxy', async (req, res) => {
  const response = await fetch(req.query.url);
  res.send(await response.text());
});

// FIX: Whitelist allowed domains
const ALLOWED_DOMAINS = ['api.example.com', 'cdn.example.com'];
app.get('/api/proxy', async (req, res) => {
  const url = new URL(req.query.url);
  if (!ALLOWED_DOMAINS.includes(url.hostname)) {
    return res.status(400).json({ error: 'Domain not allowed' });
  }
  // Also block internal IPs
  if (url.hostname === 'localhost' || url.hostname.startsWith('192.168.') ||
      url.hostname.startsWith('10.') || url.hostname.startsWith('169.254.')) {
    return res.status(400).json({ error: 'Internal IPs not allowed' });
  }
  const response = await fetch(url);
  res.send(await response.text());
});
```

### API8:2023 - Security Misconfiguration

- [ ] Verbose error messages in API responses
- [ ] CORS misconfiguration allowing all origins
- [ ] Missing API versioning (deprecated endpoints exposed)

### API9:2023 - Improper Inventory Management

- [ ] Undocumented API endpoints
- [ ] Old API versions still accessible
- [ ] No API documentation or OpenAPI spec
- [ ] Shadow APIs (not tracked in inventory)

### API10:2023 - Unsafe Consumption of APIs

- [ ] Trusting third-party API responses without validation
- [ ] No timeout on external API calls
- [ ] SSRF through API proxying

## Examples of Common Findings

### Example 1: SQL Injection (🔴 CRITICAL)

```
File: src/api/users.ts
Line(s): 42
Problem: SQL injection vulnerability - user input directly concatenated into query allowing arbitrary SQL execution. Attacker could dump database, modify data, or bypass authentication.
Fix: Use parameterized queries:
  const query = 'SELECT * FROM users WHERE email = ?';
  db.execute(query, [req.body.email]);
```

### Example 2: Missing Rate Limiting (🟠 MAJOR)

```
File: src/api/auth.ts
Line(s): 15-20
Problem: Password reset endpoint has no rate limiting, enabling brute force attacks and email flooding.
Fix: Add express-rate-limit:
  const resetLimiter = rateLimit({ windowMs: 15*60*1000, max: 3 });
  app.post('/api/password-reset', resetLimiter, handler);
```

### Example 3: Hardcoded Secret (🔴 CRITICAL)

```
File: src/config/jwt.ts
Line(s): 5
Problem: JWT secret hardcoded in source code and likely committed to version control. Compromises all issued tokens.
Fix: Use environment variable:
  const JWT_SECRET = process.env.JWT_SECRET;
  if (!JWT_SECRET) throw new Error('JWT_SECRET required');
```

### Example 4: XSS Vulnerability (🟠 MAJOR)

```
File: src/templates/profile.ts
Line(s): 67
Problem: User-supplied bio rendered with innerHTML without sanitization, allowing XSS attacks to steal sessions or perform actions as victim.
Fix: Use textContent or sanitize:
  element.textContent = user.bio; // Safe for plain text
  // Or use DOMPurify: element.innerHTML = DOMPurify.sanitize(user.bio);
```

### Example 5: Missing Security Headers (🟡 MINOR)

```
File: src/server.ts
Line(s): 12
Problem: No Content-Security-Policy or X-Frame-Options headers, increasing risk of clickjacking and XSS attacks.
Fix: Add helmet middleware:
  import helmet from 'helmet';
  app.use(helmet());
```

## References

- **CLAUDE.md** - Project-specific security standards and AWS CDK best practices
- **OWASP Top 10 2025** - https://owasp.org/Top10/2025/
- **OWASP API Security Top 10 2023** - https://owasp.org/API-Security/editions/2023/
- **CWE Top 25** - https://cwe.mitre.org/top25/
- **Node.js Security Best Practices** - https://nodejs.org/en/docs/guides/security/
