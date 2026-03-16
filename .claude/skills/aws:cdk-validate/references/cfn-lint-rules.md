# cfn-lint Rules Reference

> **Reference for:** cdk-validate skill
> **Context:** CloudFormation syntax and property validation

## Overview

cfn-lint validates CloudFormation templates against AWS specifications. It checks syntax, resource properties, and template structure.

**Rule format:** `{Severity}{Number}`
- **E**: Error (will fail deployment)
- **W**: Warning (may cause issues)
- **I**: Info (best practice)

## Common Rules

### Template Structure

#### E1001: Invalid Template Structure

**Description:** Template does not match CloudFormation schema.

**Examples:**
- Missing required properties
- Invalid JSON/YAML syntax
- Incorrect template sections

**Fix:**
```yaml
# ✅ Good
Resources:
  MyBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: my-bucket

# ❌ Bad (missing Type)
Resources:
  MyBucket:
    Properties:
      BucketName: my-bucket
```

---

#### E1010: Invalid Template Version

**Description:** AWSTemplateFormatVersion is invalid.

**Fix:**
```yaml
# ✅ Good
AWSTemplateFormatVersion: '2010-09-09'

# ❌ Bad
AWSTemplateFormatVersion: '2020-01-01'
```

---

### Resource Properties

#### E3001: Invalid Resource Property

**Description:** Resource property does not match AWS specification.

**Examples:**
- Typo in property name
- Invalid property type
- Missing required property

**Fix:**
```yaml
# ✅ Good
Resources:
  MyTable:
    Type: AWS::DynamoDB::Table
    Properties:
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH

# ❌ Bad (missing KeySchema)
Resources:
  MyTable:
    Type: AWS::DynamoDB::Table
    Properties:
      BillingMode: PAY_PER_REQUEST
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
```

---

#### E3002: Invalid Property Value

**Description:** Property value is outside allowed range or enum values.

**Examples:**
- Invalid enum value
- Number out of range
- Wrong data type

**Fix:**
```yaml
# ✅ Good
Resources:
  MyFunction:
    Type: AWS::Lambda::Function
    Properties:
      Runtime: nodejs20.x
      Timeout: 30  # Valid: 1-900 seconds

# ❌ Bad
Resources:
  MyFunction:
    Type: AWS::Lambda::Function
    Properties:
      Runtime: nodejs99.x  # Invalid runtime
      Timeout: 1000  # Exceeds max (900)
```

---

### References

#### E1020: Invalid Ref

**Description:** `!Ref` references non-existent resource or parameter.

**Fix:**
```yaml
# ✅ Good
Parameters:
  BucketName:
    Type: String

Resources:
  MyBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Ref BucketName

# ❌ Bad (references non-existent parameter)
Resources:
  MyBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Ref NonExistentParam
```

---

#### E1025: Invalid GetAtt

**Description:** `!GetAtt` references non-existent attribute.

**Fix:**
```yaml
# ✅ Good
Resources:
  MyBucket:
    Type: AWS::S3::Bucket

  MyRole:
    Type: AWS::IAM::Role
    Properties:
      Policies:
        - PolicyName: BucketAccess
          PolicyDocument:
            Statement:
              - Effect: Allow
                Action: s3:GetObject
                Resource: !GetAtt MyBucket.Arn

# ❌ Bad (Bucket has no "Name" attribute)
Resources:
  MyRole:
    Type: AWS::IAM::Role
    Properties:
      Policies:
        - PolicyName: BucketAccess
          PolicyDocument:
            Statement:
              - Effect: Allow
                Action: s3:GetObject
                Resource: !GetAtt MyBucket.Name  # Invalid
```

---

### Outputs

#### E6001: Invalid Output

**Description:** Output definition is invalid.

**Examples:**
- Missing Value
- Invalid Export name

**Fix:**
```yaml
# ✅ Good
Outputs:
  BucketArn:
    Description: S3 bucket ARN
    Value: !GetAtt MyBucket.Arn
    Export:
      Name: !Sub '${AWS::StackName}-BucketArn'

# ❌ Bad (missing Value)
Outputs:
  BucketArn:
    Description: S3 bucket ARN
    Export:
      Name: MyBucketArn
```

---

## Warnings

### W3005: DependsOn Not Required

**Description:** Explicit DependsOn is unnecessary (CloudFormation infers from !Ref/!GetAtt).

**Fix:**
```yaml
# ✅ Good (implicit dependency)
Resources:
  MyBucket:
    Type: AWS::S3::Bucket

  MyFunction:
    Type: AWS::Lambda::Function
    Properties:
      Environment:
        Variables:
          BUCKET_NAME: !Ref MyBucket

# ⚠️  Unnecessary DependsOn
Resources:
  MyFunction:
    Type: AWS::Lambda::Function
    DependsOn: MyBucket  # Not needed
    Properties:
      Environment:
        Variables:
          BUCKET_NAME: !Ref MyBucket
```

---

### W3011: Hardcoded Partition

**Description:** Hardcoded `aws` partition instead of using `!Ref AWS::Partition`.

**Fix:**
```yaml
# ✅ Good
Resources:
  MyRole:
    Type: AWS::IAM::Role
    Properties:
      Policies:
        - PolicyName: S3Access
          PolicyDocument:
            Statement:
              - Effect: Allow
                Action: s3:GetObject
                Resource: !Sub 'arn:${AWS::Partition}:s3:::my-bucket/*'

# ⚠️  Hardcoded partition
Resources:
  MyRole:
    Type: AWS::IAM::Role
    Properties:
      Policies:
        - PolicyName: S3Access
          PolicyDocument:
            Statement:
              - Effect: Allow
                Action: s3:GetObject
                Resource: 'arn:aws:s3:::my-bucket/*'  # Should use !Ref AWS::Partition
```

---

## Ignoring Rules

### Command Line

```bash
# Ignore specific rule
cfn-lint template.json --ignore-checks E3001

# Ignore multiple rules
cfn-lint template.json --ignore-checks E3001,W3005
```

### Inline Comments

```yaml
# cfn-lint: disable=E3001
Resources:
  MyResource:
    Type: AWS::S3::Bucket
    Properties:
      CustomProperty: value  # Known to trigger E3001 but required
```

### Configuration File

Create `.cfnlintrc`:

```yaml
ignore_checks:
  - E3001
  - W3005

regions:
  - us-east-1

ignore_templates:
  - cdk.out/asset.*  # Ignore CDK assets
```

---

## CDK-Specific Considerations

### Generated Templates

CDK generates CloudFormation templates in `cdk.out/`. Some patterns are expected:

**CDK asset references:**
```yaml
# CDK generates references like:
Code:
  S3Bucket: !Ref AssetParametersABC123
  S3Key: !Ref AssetParametersABC123S3VersionKey
```

**Metadata sections:**
```yaml
Metadata:
  aws:cdk:path: MyStack/MyResource/Resource
  aws:asset:path: asset.abc123
```

### Filter CDK Noise

```bash
# Ignore CDK asset warnings
cfn-lint cdk.out/*.template.json --ignore-checks W3011
```

---

## Integration with cdk-validate

The skill automatically runs cfn-lint on generated templates:

```bash
cd infrastructure
npx cdk synth --quiet
cfn-lint cdk.out/*.template.json
```

**Configuration:**

```yaml
# .claude/skills/cdk-validate/config.yaml
tools:
  cfn_lint:
    enabled: true
    ignore_rules:
      - E3001  # Add rules to ignore
```

---

## Troubleshooting

### "Template does not exist"

CDK templates are generated after `cdk synth`. Run synth first:

```bash
cd infrastructure
npx cdk synth
cfn-lint cdk.out/*.template.json
```

### "Resource type not found"

Update cfn-lint to get latest AWS resource specs:

```bash
pip install --upgrade cfn-lint
```

### Too Many False Positives

Add ignore rules to config.yaml or use inline comments in CDK code.

---

## Resources

- **cfn-lint GitHub:** https://github.com/aws-cloudformation/cfn-lint
- **Rule Catalog:** https://github.com/aws-cloudformation/cfn-lint/blob/main/docs/rules.md
- **CloudFormation Specs:** https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-resource-specification.html
