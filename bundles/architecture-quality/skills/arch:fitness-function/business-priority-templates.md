# Business Priority Templates

Pre-defined priority matrices for common business types. Use these as starting points, then validate with stakeholders.

---

## E-commerce / Retail

**Typical Characteristics**:
- High traffic variability (seasonal peaks)
- Consumer-facing (B2C)
- Payment processing
- Conversion rate critical

**Priority Order**:
1. **Performance** (CRITICAL) - Slow pages = lost sales
   - Page load time < 2s (p75)
   - Checkout latency < 200ms (p99)
   - Mobile performance parity
2. **Reliability** (CRITICAL) - Downtime = direct revenue loss
   - 99.9% uptime SLA
   - Payment gateway resilience
3. **Security & Compliance** (HIGH) - PCI-DSS mandatory
   - No payment data in logs
   - HTTPS everywhere
   - Regular vulnerability scans
4. **Accessibility** (MEDIUM) - Legal requirement + market expansion
   - WCAG 2.0 Level AA
   - Keyboard navigation
5. **Cost Optimization** (MEDIUM) - Handle traffic spikes efficiently
   - Auto-scaling
   - CDN caching
6. **User Experience** (MEDIUM) - Reduce cart abandonment
   - ≤5 clicks to checkout (95th percentile)
   - Mobile-first design

**Common Fitness Functions**:
- Checkout latency p99 < 200ms
- Homepage load time p75 < 2s
- Payment success rate > 99.5%
- Zero PCI-DSS violations
- WCAG 2.0 Level AA compliance

---

## Financial Services / Fintech

**Typical Characteristics**:
- Highly regulated (SOC 2, PCI-DSS, local regulations)
- Trust is critical
- Data accuracy paramount
- Consumer or enterprise facing

**Priority Order**:
1. **Security & Compliance** (CRITICAL) - Regulatory requirement
   - SOC 2 Type II
   - PCI-DSS for payments
   - Data encryption at rest + in transit
   - Audit logging
2. **Reliability** (CRITICAL) - Financial transactions must succeed
   - 99.95% uptime SLA
   - Zero data loss
   - Transaction idempotency
3. **Data Accuracy** (CRITICAL) - Financial correctness
   - Balance calculations verified
   - Transaction reconciliation
4. **Performance** (HIGH) - User trust depends on speed
   - API latency p99 < 100ms
   - Real-time balance updates
5. **Accessibility** (MEDIUM) - Consumer-facing services
   - WCAG 2.0 Level AA
6. **Operability** (MEDIUM) - Incident response critical
   - Comprehensive monitoring
   - Runbooks for all failure modes

**Common Fitness Functions**:
- Zero CRITICAL/HIGH security vulnerabilities
- API latency p99 < 100ms
- Transaction success rate > 99.99%
- SOC 2 compliance checks
- Audit log completeness
- Balance calculation accuracy tests

---

## Healthcare / Medical

**Typical Characteristics**:
- HIPAA compliance mandatory
- Patient safety critical
- Mix of internal and consumer users
- Integration with legacy systems

**Priority Order**:
1. **Security & Compliance** (CRITICAL) - HIPAA violations = massive fines
   - HIPAA compliance
   - PHI encryption
   - Access audit logs
   - BAA agreements
2. **Reliability** (CRITICAL) - Patient care depends on availability
   - 99.95% uptime
   - Data backup + recovery
3. **Data Accuracy** (CRITICAL) - Patient safety
   - Medical record integrity
   - Prescription accuracy
4. **Performance** (HIGH) - Clinical workflows time-sensitive
   - EHR load time < 3s
   - Lab result retrieval < 1s
5. **Accessibility** (HIGH) - ADA requirement for patient portals
   - WCAG 2.0 Level AA
   - Screen reader support
6. **Operability** (MEDIUM) - Support clinical staff
   - 24/7 monitoring
   - Incident escalation

**Common Fitness Functions**:
- Zero PHI in logs
- HIPAA audit trail completeness
- EHR response time p95 < 3s
- Data backup success rate 100%
- WCAG 2.0 Level AA compliance
- Zero unencrypted PHI transmission

---

## B2B SaaS / Enterprise Software

**Typical Characteristics**:
- Enterprise customers
- SOC 2 often required
- Uptime critical (customer SLAs)
- Multi-tenancy

**Priority Order**:
1. **Reliability** (CRITICAL) - Customer SLAs contractual
   - 99.9% or 99.95% uptime
   - Multi-region failover
   - Tenant isolation
2. **Security & Compliance** (CRITICAL) - Enterprise procurement requirement
   - SOC 2 Type II
   - SSO (SAML, OAuth)
   - RBAC
3. **Performance** (HIGH) - Enterprise users have high expectations
   - API latency p99 < 200ms
   - Dashboard load < 2s
4. **Operability** (HIGH) - Support enterprise customers
   - Monitoring + alerting
   - SLA reporting
5. **Data Accuracy** (MEDIUM) - Analytics + reporting correctness
   - Report accuracy tests
6. **Cost Optimization** (MEDIUM) - Per-tenant cost visibility
   - Resource utilization monitoring

**Common Fitness Functions**:
- API latency p99 < 200ms
- Uptime > 99.9%
- Zero SOC 2 control failures
- Tenant isolation verified
- SSO integration tests
- SLA compliance metrics

---

## B2C SaaS / Consumer Software

**Typical Characteristics**:
- High user volume
- Freemium or low-cost
- Mobile + web
- Rapid feature iteration

**Priority Order**:
1. **Performance** (CRITICAL) - User retention depends on speed
   - Page load time < 2s (p75)
   - Mobile app startup < 1s
2. **User Experience** (CRITICAL) - Low barrier to entry
   - Onboarding < 3 minutes
   - Core journeys ≤ 5 clicks (95%)
3. **Reliability** (HIGH) - Avoid churn from outages
   - 99.9% uptime
   - Graceful degradation
4. **Cost Optimization** (HIGH) - Margins often thin
   - Serverless-first architecture
   - Auto-scaling
5. **Security** (MEDIUM) - GDPR for EU users
   - User data encryption
   - GDPR compliance
6. **Accessibility** (MEDIUM) - Market expansion
   - WCAG 2.0 Level AA

**Common Fitness Functions**:
- Homepage load time p75 < 2s
- Mobile app startup p90 < 1s
- Onboarding completion rate > 80%
- Core journey ≤ 5 clicks (95%)
- API cost per request < $0.001
- Zero GDPR violations

---

## Consulting / Professional Services

**Typical Characteristics**:
- Internal tools or client-facing
- Smaller user base
- Project-based
- Budget-conscious

**Priority Order**:
1. **Cost Optimization** (CRITICAL) - Budget constraints
   - Serverless architecture
   - Minimal always-on resources
2. **Operability** (HIGH) - Small team, limited ops capacity
   - Simple deployment
   - Automated monitoring
3. **Reliability** (MEDIUM) - Important but not life-or-death
   - 99% uptime acceptable
   - Manual failover OK
4. **Performance** (MEDIUM) - Internal users are patient
   - Page load < 5s acceptable
5. **Security** (MEDIUM) - Client data protection
   - Basic encryption
   - Access controls
6. **Accessibility** (LOW) - Unless client-facing
   - Best-effort

**Common Fitness Functions**:
- Monthly AWS cost < $500
- Deployment automation
- Basic monitoring alerts
- HTTPS everywhere
- Backup success rate > 95%

---

## Media / Content Platform

**Typical Characteristics**:
- High traffic (viral content)
- Content delivery critical
- Global audience
- Ad revenue depends on performance

**Priority Order**:
1. **Performance** (CRITICAL) - Page views = revenue
   - TTFB < 200ms
   - Video startup < 2s
   - CDN hit rate > 95%
2. **Scalability** (CRITICAL) - Handle viral traffic
   - Auto-scaling
   - Multi-region CDN
3. **Reliability** (HIGH) - Uptime = engagement
   - 99.9% uptime
   - Content availability
4. **Cost Optimization** (HIGH) - CDN + storage costs significant
   - Efficient caching
   - Storage tiering
5. **User Experience** (MEDIUM) - Engagement metrics
   - Content discovery ≤ 3 clicks
   - Smooth video playback
6. **Security** (MEDIUM) - Protect user accounts
   - GDPR compliance
   - DDoS protection

**Common Fitness Functions**:
- TTFB p90 < 200ms
- Video startup time p75 < 2s
- CDN hit rate > 95%
- Auto-scaling response time < 5min
- Content discovery ≤ 3 clicks (90%)
- DDoS mitigation active

---

## Government / Public Sector

**Typical Characteristics**:
- FedRAMP or equivalent required
- Strict compliance
- Accessibility mandatory
- Public-facing

**Priority Order**:
1. **Security & Compliance** (CRITICAL) - FedRAMP/security clearance
   - FedRAMP compliance
   - ATO (Authority to Operate)
   - Audit trail completeness
2. **Accessibility** (CRITICAL) - Section 508 / WCAG 2.0 Level AA mandatory
   - WCAG 2.0 Level AA
   - Screen reader support
   - Keyboard navigation
3. **Reliability** (HIGH) - Public services must be available
   - 99.9% uptime
   - Disaster recovery plan
4. **Operability** (MEDIUM) - Support public users
   - Monitoring + incident response
5. **Performance** (MEDIUM) - User patience higher than commercial
   - Page load < 3s acceptable
6. **Cost Optimization** (MEDIUM) - Taxpayer funds
   - Cost visibility + reporting

**Common Fitness Functions**:
- Zero FedRAMP control failures
- WCAG 2.0 Level AA compliance (100%)
- Keyboard navigation complete
- Audit log retention 7 years
- Uptime > 99.9%
- Security scan frequency weekly

---

## Education / EdTech

**Typical Characteristics**:
- Students + educators
- Accessibility critical (students with disabilities)
- Seasonal traffic (academic calendar)
- Often COPPA/FERPA compliance

**Priority Order**:
1. **Accessibility** (CRITICAL) - Legal requirement + mission
   - WCAG 2.0 Level AA
   - Screen reader support
   - Assistive technology compatibility
2. **Security & Compliance** (CRITICAL) - COPPA/FERPA for student data
   - FERPA compliance
   - COPPA (if under 13)
   - Parental consent flows
3. **Reliability** (HIGH) - Exam periods critical
   - 99.9% uptime during exams
   - Load handling for peaks
4. **Performance** (MEDIUM) - Educators + students patient
   - Page load < 3s
   - Video lectures smooth playback
5. **User Experience** (MEDIUM) - Varied technical literacy
   - Simple navigation
   - Mobile-friendly
6. **Cost Optimization** (MEDIUM) - Educational budgets limited
   - Efficient resource usage

**Common Fitness Functions**:
- WCAG 2.0 Level AA compliance (100%)
- Zero FERPA violations
- Uptime > 99.9% during exam weeks
- Video playback success rate > 95%
- Course navigation ≤ 4 clicks (90%)
- Screen reader compatibility verified

---

## How to Use These Templates

1. **Select the closest match** to your business type
2. **Customize** based on stakeholder interview responses
3. **Validate** priority order with stakeholders
4. **Adjust thresholds** based on specific business constraints
5. **Iterate** as business priorities evolve

Remember: These are **starting points**, not prescriptions. Always validate with stakeholders.
