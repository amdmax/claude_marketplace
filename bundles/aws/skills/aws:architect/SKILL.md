---
name: aws:architect
description: Provide expert guidance on AWS deployments following the AWS Well-Architected Framework. Help design, review, and optimize cloud architectures across all six pillars.
author: "@thesolutionarchitect"
email: maksym.diabin@gmail.com
---

# AWS Well-Architected Framework Architect

## Purpose

Provide expert guidance on AWS deployments following the AWS Well-Architected Framework. Help design, review, and optimize cloud architectures across all six pillars to ensure production-ready, scalable, secure, and cost-effective solutions.

## Core Principles

This skill embodies AWS Well-Architected Framework best practices across six pillars:

### 1. Operational Excellence
Run and monitor systems to deliver business value and continually improve processes and procedures.

**Key Focus:**
- Infrastructure as Code (IaC)
- Automated deployments
- Observability and monitoring
- Incident response procedures
- Continuous improvement

### 2. Security
Protect information, systems, and assets while delivering business value through risk assessments and mitigation strategies.

**Key Focus:**
- Identity and Access Management (IAM)
- Detective controls
- Infrastructure protection
- Data protection
- Incident response

### 3. Reliability
Recover from infrastructure or service disruptions, dynamically acquire computing resources to meet demand, and mitigate disruptions.

**Key Focus:**
- Fault tolerance and high availability
- Backup and disaster recovery
- Auto-scaling and elasticity
- Change management
- Failure recovery automation

### 4. Performance Efficiency
Use computing resources efficiently to meet system requirements and maintain that efficiency as demand changes and technologies evolve.

**Key Focus:**
- Service selection and sizing
- Global infrastructure utilization
- Serverless architectures
- Database optimization
- Caching strategies

### 5. Cost Optimization
Avoid unnecessary costs, optimize resource utilization, and understand spending patterns.

**Key Focus:**
- Right-sizing resources
- Reserved capacity and savings plans
- Serverless adoption
- Cost monitoring and allocation
- Lifecycle management

### 6. Sustainability
Minimize environmental impact of cloud workloads through energy-efficient designs and resource optimization.

**Key Focus:**
- Region selection based on carbon footprint
- Resource efficiency
- Sustainable scaling patterns
- Hardware utilization optimization

## When to Use This Skill

Automatically engage when:
- Designing new AWS architectures
- Reviewing existing deployments
- Discussing infrastructure changes
- Optimizing performance or costs
- Preparing for production deployment
- Conducting architecture reviews
- Planning disaster recovery
- Evaluating AWS service selection
- Discussing security implementations
- Analyzing cost patterns

## Architecture Review Process

When reviewing or designing AWS architectures, systematically evaluate across all pillars:

### 1. Operational Excellence Review

**Questions:**
- Is infrastructure defined as code (CDK, CloudFormation, Terraform)?
- Are deployments automated with CI/CD?
- Is comprehensive monitoring and logging in place (CloudWatch, X-Ray)?
- Are runbooks documented for common operational tasks?
- Is there a process for continuous improvement?

**Best Practices:**
- Use AWS CDK or CloudFormation for all infrastructure
- Implement automated testing for IaC
- Set up CloudWatch dashboards and alarms
- Enable AWS X-Ray for distributed tracing
- Use AWS Systems Manager for operational tasks

### 2. Security Review

**Questions:**
- Is least-privilege IAM enforced throughout?
- Are all data stores encrypted at rest and in transit?
- Is network segmentation implemented (VPCs, security groups)?
- Are detective controls enabled (CloudTrail, GuardDuty, Config)?
- Is there an incident response plan?

**Best Practices:**
- Use IAM roles instead of long-lived credentials
- Enable encryption by default on all services
- Implement VPC with private subnets for workloads
- Enable AWS CloudTrail in all regions
- Use AWS Secrets Manager for credentials
- Implement multi-factor authentication (MFA)

### 3. Reliability Review

**Questions:**
- Is the architecture multi-AZ or multi-region?
- Are automated backups configured?
- Is auto-scaling implemented for variable loads?
- Are health checks and automatic recovery configured?
- Is there a tested disaster recovery plan?

**Best Practices:**
- Deploy across multiple Availability Zones
- Use RDS automated backups with point-in-time recovery
- Implement Application Load Balancer with health checks
- Use Auto Scaling Groups for EC2 workloads
- Test disaster recovery procedures quarterly

### 4. Performance Efficiency Review

**Questions:**
- Are services right-sized for workloads?
- Is caching implemented where appropriate?
- Are global users served via CloudFront?
- Is the database optimized (indexes, query patterns)?
- Are compute options evaluated (Lambda vs. Fargate vs. EC2)?

**Best Practices:**
- Use CloudFront for static content and edge caching
- Implement ElastiCache for frequently accessed data
- Choose serverless (Lambda) for variable, bursty workloads
- Use DynamoDB for low-latency, high-scale workloads
- Monitor with CloudWatch metrics and optimize bottlenecks

### 5. Cost Optimization Review

**Questions:**
- Are resources tagged for cost allocation?
- Is right-sizing analysis performed regularly?
- Are Reserved Instances or Savings Plans used?
- Is unused infrastructure cleaned up automatically?
- Are cost budgets and alerts configured?

**Best Practices:**
- Implement mandatory tagging strategy (project, env, owner)
- Use AWS Cost Explorer for cost analysis
- Purchase Reserved Instances for steady-state workloads
- Use AWS Lambda for intermittent workloads
- Enable S3 lifecycle policies
- Set up AWS Budgets with alerts

### 6. Sustainability Review

**Questions:**
- Are resources in regions with lower carbon intensity?
- Is scaling based on actual demand?
- Are resources utilizing latest, more efficient hardware?
- Is data retention optimized to avoid unnecessary storage?

**Best Practices:**
- Choose AWS regions with renewable energy commitments
- Use serverless to avoid idle resources
- Implement auto-scaling to match demand
- Use S3 Intelligent-Tiering for automatic optimization
- Leverage Graviton processors for better efficiency

## Service-Specific Deployment Recommendations

### AWS Lambda

**Best Practices:**
- Set appropriate memory allocation (test for cost/performance balance)
- Use provisioned concurrency for predictable latency
- Configure reserved concurrency to prevent throttling
- Enable X-Ray for tracing
- Use Lambda Layers for shared dependencies
- Set appropriate timeout values
- Implement dead letter queues (DLQ) for error handling

**Performance:**
- Keep deployment packages small (<10MB)
- Use environment variables for configuration
- Minimize cold starts with provisioned concurrency
- Optimize for warm start performance

**Cost:**
- Right-size memory allocation
- Use ARM architecture (Graviton2) for cost savings
- Avoid overprovisioning concurrency

### Amazon ECS/Fargate

**Best Practices:**
- Use Fargate for simplified operations (no EC2 management)
- Implement health checks at container and load balancer levels
- Use ECR with vulnerability scanning
- Configure auto-scaling based on CloudWatch metrics
- Implement proper logging to CloudWatch Logs

**Performance:**
- Right-size task CPU and memory
- Use Application Load Balancer for HTTP/HTTPS
- Implement connection draining
- Use ECR caching for faster deployments

**Cost:**
- Use Fargate Spot for fault-tolerant workloads (70% savings)
- Right-size task definitions
- Implement auto-scaling to match demand

### Amazon RDS

**Best Practices:**
- Enable automated backups with appropriate retention
- Use Multi-AZ for production databases
- Enable encryption at rest
- Use IAM database authentication where possible
- Configure appropriate backup window
- Enable Enhanced Monitoring
- Use read replicas for read-heavy workloads

**Performance:**
- Choose appropriate instance type
- Use Provisioned IOPS for consistent performance
- Implement connection pooling
- Monitor slow query logs
- Create appropriate indexes

**Cost:**
- Use Reserved Instances for steady workloads
- Consider Aurora Serverless for variable loads
- Enable automatic minor version upgrades
- Use appropriate storage auto-scaling

### Amazon S3

**Best Practices:**
- Enable versioning for critical data
- Use S3 Lifecycle policies for data tiering
- Enable server-side encryption (SSE-S3 or SSE-KMS)
- Block public access by default
- Enable MFA Delete for extra protection
- Use S3 Object Lock for compliance requirements

**Performance:**
- Use S3 Transfer Acceleration for global uploads
- Implement multipart uploads for large objects
- Use CloudFront for frequently accessed content
- Use S3 Select for querying subsets of data

**Cost:**
- Use S3 Intelligent-Tiering for automatic optimization
- Implement lifecycle policies to move to cheaper tiers
- Delete incomplete multipart uploads
- Use S3 Storage Lens for visibility

### Amazon DynamoDB

**Best Practices:**
- Use on-demand billing for unpredictable workloads
- Enable point-in-time recovery for critical tables
- Implement Global Tables for multi-region access
- Use DynamoDB Streams for change data capture
- Enable encryption at rest
- Use TTL to automatically delete expired items

**Performance:**
- Design partition keys to avoid hot partitions
- Use GSIs (Global Secondary Indexes) sparingly
- Implement exponential backoff for throttling
- Use DAX (DynamoDB Accelerator) for read-heavy workloads

**Cost:**
- Choose on-demand vs. provisioned capacity appropriately
- Use auto-scaling for provisioned capacity
- Archive old data to S3 using DynamoDB exports

## Common Architecture Patterns

### Serverless API

```
API Gateway → Lambda → DynamoDB
     ↓
 CloudWatch Logs
     ↓
   X-Ray
```

**Recommendations:**
- Use API Gateway with request validation
- Implement Lambda authorizers for authentication
- Use DynamoDB for low-latency data access
- Enable API Gateway caching for read operations
- Implement throttling and quota limits

### Microservices on ECS

```
Route 53 → ALB → ECS Fargate Services → RDS/DynamoDB
                    ↓
              CloudWatch Logs
                    ↓
              Service Discovery
```

**Recommendations:**
- Use Application Load Balancer with path-based routing
- Implement service discovery with AWS Cloud Map
- Use separate task definitions per service
- Configure auto-scaling per service
- Implement centralized logging

### Data Processing Pipeline

```
S3 → EventBridge → Lambda → Process → Store (S3/RDS/DynamoDB)
                      ↓
                   SQS/SNS (for failures)
```

**Recommendations:**
- Use S3 event notifications to trigger processing
- Implement SQS for reliable message delivery
- Use Step Functions for complex workflows
- Configure DLQs for error handling
- Use Glue for ETL at scale

## Performance Optimization Strategies

### Caching Layers

1. **CloudFront** (Edge caching)
   - TTL configuration based on content type
   - Cache control headers
   - Regional edge caches

2. **ElastiCache** (In-memory caching)
   - Redis for complex data structures
   - Memcached for simple key-value
   - Appropriate node sizing

3. **DynamoDB DAX** (Database caching)
   - Microsecond latency for reads
   - Automatic cache invalidation
   - No application changes needed

### Database Optimization

- **Indexing**: Create indexes on frequently queried fields
- **Query optimization**: Analyze slow query logs
- **Connection pooling**: Reduce connection overhead
- **Read replicas**: Offload read traffic
- **Caching**: Implement application-level caching

### Network Optimization

- **VPC design**: Minimize cross-AZ data transfer
- **PrivateLink**: For service-to-service communication
- **Global Accelerator**: For global low-latency access
- **Direct Connect**: For high-bandwidth hybrid scenarios

## Security Best Practices

### Identity & Access Management

**Principle of Least Privilege:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "s3:GetObject",
      "s3:PutObject"
    ],
    "Resource": "arn:aws:s3:::my-bucket/specific-prefix/*"
  }]
}
```

**Best Practices:**
- Use IAM roles instead of access keys
- Implement MFA for privileged operations
- Rotate credentials regularly
- Use IAM Access Analyzer to validate policies
- Implement SCPs (Service Control Policies) for organizations

### Data Protection

**Encryption at Rest:**
- Enable by default on all services (S3, RDS, EBS, DynamoDB)
- Use AWS KMS for key management
- Implement separate keys per environment/application
- Enable automatic key rotation

**Encryption in Transit:**
- Enforce TLS 1.2+ for all connections
- Use AWS Certificate Manager for SSL/TLS certificates
- Configure security groups to only allow HTTPS

### Network Security

**VPC Design:**
- Use private subnets for application/database tiers
- Implement NAT Gateway for outbound internet access
- Use VPC endpoints for AWS service access
- Configure security groups with minimal required rules

**Detective Controls:**
- Enable VPC Flow Logs
- Use GuardDuty for threat detection
- Enable AWS Config for compliance monitoring
- Implement CloudTrail in all regions

## Cost Optimization Strategies

### Right-Sizing

**Compute:**
- Use AWS Compute Optimizer recommendations
- Analyze CloudWatch metrics for utilization
- Downsize overprovisioned resources
- Use burstable instances (T3/T4g) for variable loads

**Storage:**
- Use S3 Intelligent-Tiering
- Implement lifecycle policies
- Delete unused EBS snapshots
- Use EBS volume types appropriately (gp3 vs. gp2)

### Commitment Discounts

**Savings Plans:**
- Compute Savings Plans (up to 66% savings)
- EC2 Instance Savings Plans (up to 72% savings)
- Analyze usage patterns first

**Reserved Instances:**
- For predictable steady-state workloads
- Standard RIs (up to 72% savings)
- Convertible RIs (up to 54% savings, with flexibility)

### Serverless Adoption

**Lambda vs. EC2:**
- Lambda for intermittent, bursty workloads
- No costs when not running
- Auto-scaling included
- Consider cold start requirements

### Cost Visibility

**Tagging Strategy:**
```
Environment: production|staging|development
Project: project-name
Owner: team-name
CostCenter: cost-center-id
```

**Tools:**
- AWS Cost Explorer for analysis
- Cost Allocation Tags for categorization
- AWS Budgets for alerts
- Trusted Advisor for recommendations

## Deployment Checklist

Before production deployment, ensure:

**Operational Excellence:**
- [ ] Infrastructure is fully defined as code
- [ ] CI/CD pipeline is configured and tested
- [ ] Monitoring dashboards are created
- [ ] Alarms are configured for critical metrics
- [ ] Runbooks are documented

**Security:**
- [ ] IAM policies follow least privilege
- [ ] All data is encrypted at rest and in transit
- [ ] Security groups are properly configured
- [ ] CloudTrail is enabled in all regions
- [ ] Secrets are stored in Secrets Manager/Parameter Store

**Reliability:**
- [ ] Multi-AZ deployment is configured
- [ ] Automated backups are enabled and tested
- [ ] Auto-scaling is configured
- [ ] Health checks are implemented
- [ ] Disaster recovery plan is documented and tested

**Performance:**
- [ ] Resources are appropriately sized
- [ ] Caching is implemented where beneficial
- [ ] Database is optimized with indexes
- [ ] Load testing is completed
- [ ] Bottlenecks are identified and resolved

**Cost:**
- [ ] Resources are tagged for cost allocation
- [ ] Cost budgets and alerts are configured
- [ ] Right-sizing analysis is complete
- [ ] Reserved capacity is evaluated
- [ ] Unused resources are cleaned up

**Sustainability:**
- [ ] Region selection considers carbon footprint
- [ ] Auto-scaling prevents over-provisioning
- [ ] Latest instance generations are used
- [ ] Data retention policies minimize storage

## Reference Documentation

For detailed information on each pillar, see:
- `well-architected-pillars.md` - Comprehensive pillar breakdown
- `deployment-checklist.md` - Pre-deployment validation checklist

## Using This Skill

This skill is automatically engaged when:
- Discussing AWS architecture design
- Reviewing infrastructure code
- Planning deployments
- Discussing AWS service selection
- Optimizing existing workloads

Always approach AWS architecture with a systematic review across all six pillars, prioritizing based on business requirements and risk profile.
