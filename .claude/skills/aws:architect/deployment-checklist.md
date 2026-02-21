# AWS Production Deployment Checklist

Use this checklist before deploying workloads to production. Each item maps to Well-Architected Framework best practices.

---

## 1. Operational Excellence

### Infrastructure as Code
- [ ] All infrastructure is defined as code (CloudFormation/CDK/Terraform)
- [ ] Infrastructure code is stored in version control
- [ ] Infrastructure code has been peer-reviewed
- [ ] Deployment process is documented
- [ ] Rollback procedure is documented and tested

### CI/CD Pipeline
- [ ] Automated deployment pipeline is configured
- [ ] Pipeline includes automated testing
- [ ] Pipeline includes security scanning
- [ ] Deployment to production requires approval
- [ ] Pipeline can automatically rollback on failure

### Monitoring and Logging
- [ ] CloudWatch Logs are enabled for all services
- [ ] Log retention policies are configured appropriately
- [ ] CloudWatch dashboards are created for key metrics
- [ ] CloudWatch Alarms are configured for critical metrics
- [ ] Alarm notifications route to appropriate teams (SNS/PagerDuty)
- [ ] AWS X-Ray tracing is enabled (if using distributed services)

### Operational Procedures
- [ ] Runbooks are created for common operational tasks
- [ ] On-call rotation is defined
- [ ] Incident response procedures are documented
- [ ] Disaster recovery procedures are documented
- [ ] Change management process is in place

---

## 2. Security

### Identity and Access Management
- [ ] Root account MFA is enabled
- [ ] Root account is not used for daily operations
- [ ] IAM users have MFA enabled
- [ ] Service accounts use IAM roles (not access keys)
- [ ] IAM policies follow principle of least privilege
- [ ] IAM Access Analyzer has reviewed all policies
- [ ] Unused IAM users/roles have been removed
- [ ] Password policy is strong and enforced
- [ ] Access keys are rotated regularly (or not used)

### Network Security
- [ ] Resources are deployed in VPC (not default VPC)
- [ ] Subnets are properly segmented (public/private/data)
- [ ] Security groups follow least privilege (minimal ports/protocols)
- [ ] Network ACLs are configured if needed
- [ ] VPC Flow Logs are enabled
- [ ] Resources use private subnets where possible
- [ ] NAT Gateway is configured for private subnet internet access
- [ ] VPC endpoints are used for AWS service access (S3, DynamoDB)

### Data Protection
- [ ] All data at rest is encrypted (S3, EBS, RDS, DynamoDB)
- [ ] All data in transit uses TLS 1.2 or higher
- [ ] AWS KMS customer managed keys are used (if required)
- [ ] KMS key rotation is enabled
- [ ] S3 buckets have encryption enabled
- [ ] S3 buckets block public access (unless intentionally public)
- [ ] S3 bucket versioning is enabled for critical data
- [ ] RDS databases have encryption enabled
- [ ] Secrets are stored in Secrets Manager or Parameter Store (encrypted)

### Detective Controls
- [ ] AWS CloudTrail is enabled in all regions
- [ ] CloudTrail logs are stored in secure S3 bucket
- [ ] CloudTrail log file integrity validation is enabled
- [ ] AWS Config is enabled
- [ ] AWS GuardDuty is enabled
- [ ] AWS Security Hub is enabled
- [ ] AWS Macie is enabled (if handling sensitive data)
- [ ] Amazon Inspector is configured (for EC2/containers)

### Application Security
- [ ] Application dependencies are up to date
- [ ] Known vulnerabilities have been remediated
- [ ] Input validation is implemented
- [ ] Output encoding is implemented
- [ ] SQL injection protection is in place
- [ ] Cross-site scripting (XSS) protection is in place
- [ ] CSRF protection is implemented (for web apps)
- [ ] Authentication and authorization are properly implemented
- [ ] Sensitive data is not logged

---

## 3. Reliability

### High Availability
- [ ] Application is deployed across multiple Availability Zones
- [ ] Database is configured for Multi-AZ (RDS) or multi-region (DynamoDB)
- [ ] Load balancer distributes traffic across multiple AZs
- [ ] Application can tolerate AZ failure
- [ ] Single points of failure have been eliminated
- [ ] For critical workloads, multi-region deployment is considered

### Backup and Recovery
- [ ] Automated backups are enabled for all stateful services
- [ ] Backup retention period is appropriate for business needs
- [ ] Backups are tested and verified
- [ ] Point-in-time recovery is configured (if applicable)
- [ ] Disaster recovery plan is documented
- [ ] Disaster recovery procedures have been tested
- [ ] Recovery Time Objective (RTO) is defined and achievable
- [ ] Recovery Point Objective (RPO) is defined and achievable
- [ ] Cross-region backup is configured (for critical data)

### Auto-Scaling and Load Balancing
- [ ] Auto Scaling Groups are configured for EC2 workloads
- [ ] Scaling policies are based on appropriate metrics
- [ ] Minimum instance count ensures availability
- [ ] Maximum instance count prevents runaway costs
- [ ] Application Load Balancer or Network Load Balancer is configured
- [ ] Health checks are properly configured
- [ ] Connection draining/deregistration delay is configured
- [ ] Sticky sessions are configured if needed

### Change Management
- [ ] All changes go through automated deployment
- [ ] Blue/green or canary deployment strategy is used
- [ ] Rollback plan is defined and tested
- [ ] Database migrations are tested
- [ ] Database migrations have rollback plan
- [ ] Feature flags are used for risky changes

### Service Limits and Quotas
- [ ] Current usage is monitored against service quotas
- [ ] Service quota increases have been requested if needed
- [ ] Application handles throttling gracefully
- [ ] Trusted Advisor checks service limits

---

## 4. Performance Efficiency

### Compute Selection
- [ ] Appropriate compute type is selected (EC2/Lambda/Fargate/Batch)
- [ ] Instance types are appropriately sized
- [ ] Compute Optimizer recommendations have been reviewed
- [ ] Graviton processors are considered for cost/performance
- [ ] Serverless is used for variable workloads
- [ ] Lambda memory allocation is optimized
- [ ] Lambda timeout is appropriate

### Database Selection and Optimization
- [ ] Appropriate database engine is selected
- [ ] Database instance is appropriately sized
- [ ] Database indexes are created for frequent queries
- [ ] Query performance has been analyzed
- [ ] Read replicas are configured (if needed for read-heavy workload)
- [ ] Connection pooling is implemented
- [ ] RDS Performance Insights is enabled
- [ ] Database slow query log is enabled and monitored

### Caching Strategy
- [ ] CloudFront is configured for static content
- [ ] CloudFront cache behaviors are optimized
- [ ] ElastiCache is configured for frequently accessed data
- [ ] Application-level caching is implemented
- [ ] DynamoDB DAX is used (if applicable for DynamoDB)
- [ ] Cache invalidation strategy is defined
- [ ] Cache hit rates are monitored

### Network Optimization
- [ ] CloudFront is used for global distribution
- [ ] VPC endpoints are used for AWS service access
- [ ] PrivateLink is used for service-to-service communication
- [ ] Data transfer costs have been optimized
- [ ] Compression is enabled where appropriate

### Load Testing
- [ ] Performance requirements are defined
- [ ] Load testing has been performed
- [ ] Bottlenecks have been identified and addressed
- [ ] System performs within SLA under expected load
- [ ] System handles peak load scenarios
- [ ] Graceful degradation is tested

---

## 5. Cost Optimization

### Resource Tagging
- [ ] All resources have required tags (Environment, Project, Owner, CostCenter)
- [ ] Tag policy is enforced
- [ ] Cost allocation tags are activated in Billing Console
- [ ] Resources can be tracked by business unit/project

### Right-Sizing
- [ ] Resources are appropriately sized (not overprovisioned)
- [ ] Compute Optimizer recommendations are reviewed regularly
- [ ] Unused or underutilized resources are identified
- [ ] Resources are downsized or terminated as appropriate

### Commitment Discounts
- [ ] Reserved Instances or Savings Plans are purchased for steady workloads
- [ ] Coverage for RI/Savings Plans is >70% for production
- [ ] Reserved capacity is appropriate for actual usage
- [ ] Convertible RIs are considered for flexibility
- [ ] Savings Plans utilization is monitored

### Cost Monitoring
- [ ] AWS Cost Explorer is reviewed monthly
- [ ] AWS Budgets are configured with alerts
- [ ] Cost anomaly detection is enabled
- [ ] Cost optimization recommendations from Trusted Advisor are reviewed
- [ ] Showback or chargeback is implemented (if multi-team)

### Lifecycle Management
- [ ] S3 lifecycle policies move data to cheaper tiers
- [ ] Old EBS snapshots are deleted automatically
- [ ] Unused AMIs are deregistered
- [ ] CloudWatch Logs retention is configured appropriately
- [ ] Development/test resources are shut down during off-hours

### Serverless Adoption
- [ ] Lambda is used for appropriate workloads
- [ ] Lambda is not used for long-running processes
- [ ] DynamoDB on-demand is used for unpredictable workloads
- [ ] Aurora Serverless is considered for variable database loads
- [ ] Step Functions is used instead of always-on orchestration

---

## 6. Sustainability

### Region Selection
- [ ] AWS regions are selected considering carbon intensity
- [ ] Proximity to users is considered to minimize data transfer
- [ ] Multi-region deployment uses sustainable regions where possible

### Resource Efficiency
- [ ] Latest instance generations are used (better performance per watt)
- [ ] Graviton processors are used where supported
- [ ] Auto-scaling prevents over-provisioning
- [ ] Serverless is adopted to eliminate idle resources
- [ ] Resources are right-sized to actual needs

### Data Management
- [ ] Data lifecycle policies minimize unnecessary storage
- [ ] Data compression is used where appropriate
- [ ] Duplicate data is identified and removed
- [ ] S3 Intelligent-Tiering optimizes storage class
- [ ] Old data is archived to cold storage tiers

### Development Efficiency
- [ ] Development and test environments are shut down when not in use
- [ ] Smaller instance types are used for non-production
- [ ] Ephemeral environments are used for testing
- [ ] CI/CD pipelines are optimized for efficiency

---

## Pre-Deployment Sign-Off

Before deploying to production, obtain sign-off from:

- [ ] **Development Team**: Code is production-ready
- [ ] **Security Team**: Security requirements are met
- [ ] **Operations Team**: Monitoring and runbooks are in place
- [ ] **Finance Team**: Cost expectations are approved
- [ ] **Architecture Team**: Design follows Well-Architected principles
- [ ] **Compliance Team**: Regulatory requirements are met (if applicable)

---

## Post-Deployment Validation

After deployment, verify:

- [ ] **Smoke Tests**: Basic functionality works
- [ ] **Monitoring**: Dashboards show expected metrics
- [ ] **Alarms**: No critical alarms are triggered
- [ ] **Logs**: Application logs show no errors
- [ ] **Performance**: Response times are within SLA
- [ ] **Cost**: Initial costs are as expected
- [ ] **Documentation**: Runbooks are updated with production details

---

## Critical Production Readiness Questions

Answer "YES" to all before production deployment:

1. **Can the system recover automatically from failures?**
2. **Is there 24/7 monitoring and alerting?**
3. **Can you restore from backup if needed?**
4. **Have you tested the disaster recovery process?**
5. **Are all credentials rotated and secured?**
6. **Is data encrypted at rest and in transit?**
7. **Can you roll back the deployment if needed?**
8. **Do you know what to do if an alarm fires at 2 AM?**
9. **Are costs being tracked and attributed?**
10. **Is there an on-call rotation defined?**

---

## Compliance and Governance

If your workload has compliance requirements (HIPAA, PCI-DSS, SOC 2, etc.):

- [ ] Compliance framework is identified
- [ ] AWS compliance documentation is reviewed
- [ ] Required controls are implemented
- [ ] Audit logging is comprehensive
- [ ] Access controls meet compliance standards
- [ ] Data retention policies comply with regulations
- [ ] Third-party security assessment is completed (if required)
- [ ] Compliance audit trail is maintained

---

## Additional Resources

- **AWS Well-Architected Tool**: Run automated reviews
- **AWS Trusted Advisor**: Check best practices
- **AWS Security Hub**: Continuous security assessment
- **AWS Compute Optimizer**: Right-sizing recommendations
- **AWS Cost Explorer**: Cost analysis and forecasting

---

## Checklist Completion

**Deployment Date**: _______________
**Workload Name**: _______________
**AWS Account ID**: _______________
**Environment**: Production / Staging / Development

**Sign-off:**
- Technical Lead: _______________
- Security Lead: _______________
- Operations Lead: _______________
- Compliance Lead: _______________

**Overall Readiness**: ☐ Ready for Production ☐ Needs Additional Work

**Outstanding Items** (if not ready):
1. _______________
2. _______________
3. _______________
