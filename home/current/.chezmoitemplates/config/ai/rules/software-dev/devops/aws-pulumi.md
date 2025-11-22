---
rule_id: aws-pulumi-implementations
title: "AWS Infrastructure with Pulumi"
date-created: 2025-11-21
date-updated: 2025-11-21
tags: [aws, pulumi, infrastructure-as-code, iac, typescript]
aliases: [pulumi-aws, aws-pulumi-examples]
---

# AWS Infrastructure with Pulumi

This file contains all Pulumi (TypeScript) implementations for AWS best practices. For Terraform examples, see `aws-terraform.md`.

## VPC Gateway Endpoints for S3

```typescript
import * as aws from "@pulumi/aws";

// Create a Gateway Endpoint for S3
const s3Endpoint = new aws.ec2.VpcEndpoint("s3", {
  vpcId: vpc.id,
  serviceName: aws.getAvailabilityZones().then(azs => 
    `com.amazonaws.${aws.getRegion().name}.s3`
  ),
  routeTableIds: [
    privateRouteTable.id,
    publicRouteTable.id,
  ],
});

// Optional: Restrict endpoint access with a policy
const s3EndpointPolicy = new aws.ec2.VpcEndpointPolicy("s3", {
  vpcEndpointId: s3Endpoint.id,
  policy: {
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Principal: "*",
        Action: "s3:*",
        Resource: "*",
      },
    ],
  },
});
```

## Cost Anomaly Detection Setup

```typescript
import * as aws from "@pulumi/aws";

// Create SNS topic for cost alerts
const costAlertsTopic = new aws.sns.Topic("cost-alerts", {
  tags: {
    Name: "Cost Anomaly Alerts",
    Environment: "production",
  },
});

// Subscribe email to SNS topic
const emailSubscription = new aws.sns.TopicSubscription("cost-alerts-email", {
  topic: costAlertsTopic,
  protocol: "email",
  endpoint: "your-email@example.com",
});

// Create Cost Anomaly Detection monitor
const anomalyMonitor = new aws.ce.AnomalyMonitor("all-services", {
  monitorType: "DIMENSIONAL",
  monitorDimension: "SERVICE",
  tags: {
    Name: "All Services Anomaly Monitor",
    Environment: "production",
  },
});

// Create Cost Anomaly Detection alert
const anomalySubscription = new aws.ce.AnomalySubscription("all-services", {
  threshold: 100,  // Alert on $100+ anomalies
  frequency: "DAILY",
  monitorArn: anomalyMonitor.arn,
  snsTopicArns: [costAlertsTopic.arn],
  tags: {
    Name: "All Services Anomaly Alert",
    Environment: "production",
  },
});

// Optional: Create a more sensitive monitor for NAT Gateway
const natGatewayMonitor = new aws.ce.AnomalyMonitor("nat-gateway", {
  monitorType: "DIMENSIONAL",
  monitorDimension: "SERVICE",
  tags: {
    Name: "NAT Gateway Anomaly Monitor",
    Environment: "production",
  },
});

const natGatewaySubscription = new aws.ce.AnomalySubscription("nat-gateway", {
  threshold: 50,  // Lower threshold for NAT Gateway
  frequency: "DAILY",
  monitorArn: natGatewayMonitor.arn,
  snsTopicArns: [costAlertsTopic.arn],
  tags: {
    Name: "NAT Gateway Anomaly Alert",
    Environment: "production",
  },
});
```

## AWS Organizations Setup

```typescript
import * as aws from "@pulumi/aws";

// Create AWS Organization
const org = new aws.organizations.Organization("main", {
  awsServiceAccessPrincipals: [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
  ],
  enabledPolicyTypes: [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
  ],
  featureSet: "ALL",
});

// Create Organizational Units
const productionOU = new aws.organizations.OrganizationalUnit("production", {
  parentId: org.roots[0].id,
});

const developmentOU = new aws.organizations.OrganizationalUnit("development", {
  parentId: org.roots[0].id,
});

const sharedServicesOU = new aws.organizations.OrganizationalUnit("shared-services", {
  parentId: org.roots[0].id,
});

// Create Production Account
const productionAccount = new aws.organizations.Account("production", {
  name: "Production",
  email: "aws-prod@example.com",
  parentId: productionOU.id,
  iamUserAccessToBilling: "ALLOW",
});

// Create Development Account
const developmentAccount = new aws.organizations.Account("development", {
  name: "Development",
  email: "aws-dev@example.com",
  parentId: developmentOU.id,
  iamUserAccessToBilling: "ALLOW",
});

// Create Logging Account
const loggingAccount = new aws.organizations.Account("logging", {
  name: "Logging",
  email: "aws-logging@example.com",
  parentId: sharedServicesOU.id,
  iamUserAccessToBilling: "ALLOW",
});

// Create Service Control Policy to prevent dangerous actions
const denyRootPolicy = new aws.organizations.Policy("deny-root-actions", {
  type: "SERVICE_CONTROL_POLICY",
  content: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Deny",
        Action: [
          "iam:CreateAccessKey",
          "iam:CreateUser",
          "iam:CreateLoginProfile",
          "iam:AttachUserPolicy",
        ],
        Resource: "arn:aws:iam::*:root",
      },
    ],
  }),
});

// Attach SCP to prevent EC2 in non-approved regions
const restrictRegionsPolicy = new aws.organizations.Policy("restrict-regions", {
  type: "SERVICE_CONTROL_POLICY",
  content: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Deny",
        Action: "ec2:*",
        Resource: "*",
        Condition: {
          StringNotEquals: {
            "aws:RequestedRegion": ["us-east-1", "us-west-2", "eu-west-1"],
          },
        },
      },
    ],
  }),
});

// Export account IDs
export const organizationId = org.id;
export const productionAccountId = productionAccount.id;
export const developmentAccountId = developmentAccount.id;
export const loggingAccountId = loggingAccount.id;
```

## Resource Tagging

```typescript
import * as aws from "@pulumi/aws";
import * as pulumi from "@pulumi/pulumi";

const config = new pulumi.Config();
const environment = config.require("environment");

// Define common tags
const commonTags: Record<string, string> = {
  // Technical
  Purpose: "Core",
  App: "job-aide",
  Service: "api",
  Version: "1.2.3",
  Environment: environment,
  SLA: "99.9",
  DeployingIndividual: "pulumi-automation",
  DeployingDepartment: "DevOps",
  Pattern: "microservice-on-ecs",
  
  // Business
  RequestingDepartmentManager: "engineering-manager",
  RequestingIndividual: "product-owner",
  RequestingDepartment: "Engineering",
  Product: "job-aide-platform",
  
  // Governance
  PIILevel: "High",
  ComplianceRequired: "SOC2,PCI-DSS",
  SecurityClassification: "Confidential",
  RetireDate: "2027-12-31",
  CostCenter: "ENG-001",
  Tenancy: "internal",
  
  // Lineage
  CreatedDate: new Date().toISOString().split('T')[0],
  ManagedBy: "pulumi",
};

// Create EC2 instance with tags
const instance = new aws.ec2.Instance("app", {
  ami: "ami-0c55b159cbfafe1f0",
  instanceType: "t3.micro",
  tags: {
    Name: "job-aide-api-instance",
    ...commonTags,
  },
});

// Create S3 bucket with tags
const dataBucket = new aws.s3.Bucket("data", {
  bucket: `job-aide-data-${environment}`,
  tags: {
    Name: "job-aide-data-bucket",
    PIILevel: "High",
    ...commonTags,
  },
});

// Create RDS cluster with tags
const database = new aws.rds.Cluster("database", {
  clusterIdentifier: `job-aide-db-${environment}`,
  tags: {
    Name: "job-aide-database",
    PIILevel: "High",
    ComplianceRequired: "SOC2,PCI-DSS,HIPAA",
    ...commonTags,
  },
});
```

## Tag Enforcement with AWS Config

```typescript
import * as aws from "@pulumi/aws";

// Require specific tags on all resources
const requiredTagsRule = new aws.cfg.ConfigRule("required-tags", {
  source: {
    owner: "AWS",
    sourceIdentifier: "REQUIRED_TAGS",
  },
  inputParameters: JSON.stringify({
    tag1Key: "Environment",
    tag2Key: "App",
    tag3Key: "CostCenter",
    tag4Key: "ComplianceRequired",
    tag5Key: "SecurityClassification",
  }),
});

// Remediation: Tag non-compliant resources automatically
const tagRemediationConfig = new aws.cfg.RemediationConfigurations("tag-resources", {
  configRuleName: requiredTagsRule.name,
  resourceType: "AWS::EC2::Instance",
  targetType: "SSM_DOCUMENT",
  targetIdentifier: "AWS-TagResource",
  targetVersion: "1",
  automatic: true,
  maximumAutomaticAttempts: 100,
  automaticRemediationBeforeCompliance: false,
  parameters: [
    {
      staticValue: "Environment",
      name: "Tag1Key",
    },
    {
      staticValue: "production",
      name: "Tag1Value",
    },
  ],
});
```

## Tag-Based Cost Allocation

```typescript
import * as aws from "@pulumi/aws";

// Enable Cost Allocation Tags
const departmentCostCategory = new aws.ce.CostCategoryDefinition("department", {
  ruleVersion: "CostCategoryExpression_v1",
  rules: [
    {
      rule: 'WHEN tags.RequestingDepartment IN ("Engineering")',
      value: "Engineering",
    },
    {
      rule: 'WHEN tags.RequestingDepartment IN ("Finance")',
      value: "Finance",
    },
  ],
});

// Create SNS topic for budget alerts
const budgetAlertsTopic = new aws.sns.Topic("budget-alerts");

// Create budget alert by cost center
const engineeringBudget = new aws.budgets.Budget("engineering", {
  budgetType: "COST",
  limitUnit: "USD",
  limitValue: 10000,
  timePeriodStart: "2025-01-01",
  timePeriodEnd: "2087-12-31",
  timeUnit: "MONTHLY",
  costFilters: {
    TagKeyValue: ["CostCenter$ENG-001"],
  },
  notifications: [
    {
      comparisonOperator: "GREATER_THAN",
      notificationType: "FORECASTED",
      threshold: 80,
      thresholdType: "PERCENTAGE",
      notificationArns: [budgetAlertsTopic.arn],
    },
  ],
});
```

## Data Processing Accounts

```typescript
import * as aws from "@pulumi/aws";

// Create Data Processing OU
const dataProcessingOU = new aws.organizations.OrganizationalUnit("data-processing", {
  parentId: org.roots[0].id,
});

// Create Ingestion Account
const ingestionAccount = new aws.organizations.Account("data-ingestion", {
  name: "Data Ingestion",
  email: "aws-data-ingestion@example.com",
  parentId: dataProcessingOU.id,
  iamUserAccessToBilling: "ALLOW",
});

// Create Processing Account
const processingAccount = new aws.organizations.Account("data-processing", {
  name: "Data Processing",
  email: "aws-data-processing@example.com",
  parentId: dataProcessingOU.id,
  iamUserAccessToBilling: "ALLOW",
});

// Create Consumption Account
const consumptionAccount = new aws.organizations.Account("data-consumption", {
  name: "Data Consumption",
  email: "aws-data-consumption@example.com",
  parentId: dataProcessingOU.id,
  iamUserAccessToBilling: "ALLOW",
});

// SCP: Prevent expensive compute in Ingestion account
const ingestionRestrictionsPolicy = new aws.organizations.Policy("ingestion-restrictions", {
  type: "SERVICE_CONTROL_POLICY",
  content: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Deny",
        Action: [
          "ec2:RunInstances",
          "emr:RunJobFlow",
          "glue:CreateJob",
        ],
        Resource: "*",
        Condition: {
          StringEquals: {
            "aws:RequestedRegion": ["us-east-1"],
          },
        },
      },
    ],
  }),
});

// SCP: Prevent data export from Ingestion account
const ingestionDataProtectionPolicy = new aws.organizations.Policy("ingestion-data-protection", {
  type: "SERVICE_CONTROL_POLICY",
  content: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Deny",
        Action: [
          "s3:GetObject",
          "s3:GetObjectVersion",
        ],
        Resource: "arn:aws:s3:::*-raw-data/*",
        Condition: {
          StringNotEquals: {
            "aws:PrincipalOrgID": org.id,
          },
        },
      },
    ],
  }),
});

// Cross-account role: Processing account can read from Ingestion
const ingestionReaderRole = new aws.iam.Role("ingestion-reader", {
  assumeRolePolicy: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Principal: {
          AWS: pulumi.interpolate`arn:aws:iam::${processingAccount.id}:root`,
        },
        Action: "sts:AssumeRole",
      },
    ],
  }),
});

const ingestionReaderPolicy = new aws.iam.RolePolicy("ingestion-reader-policy", {
  role: ingestionReaderRole.id,
  policy: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "s3:GetObject",
          "s3:ListBucket",
        ],
        Resource: [
          "arn:aws:s3:::*-raw-data",
          "arn:aws:s3:::*-raw-data/*",
        ],
      },
    ],
  }),
});

// Cross-account role: Consumption account can read from Processing
const processingReaderRole = new aws.iam.Role("processing-reader", {
  assumeRolePolicy: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Principal: {
          AWS: pulumi.interpolate`arn:aws:iam::${consumptionAccount.id}:root`,
        },
        Action: "sts:AssumeRole",
      },
    ],
  }),
});

const processingReaderPolicy = new aws.iam.RolePolicy("processing-reader-policy", {
  role: processingReaderRole.id,
  policy: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "s3:GetObject",
          "s3:ListBucket",
        ],
        Resource: [
          "arn:aws:s3:::*-processed-data",
          "arn:aws:s3:::*-processed-data/*",
        ],
      },
    ],
  }),
});

// Export account IDs
export const ingestionAccountId = ingestionAccount.id;
export const processingAccountId = processingAccount.id;
export const consumptionAccountId = consumptionAccount.id;
```

## Cost Attribution for Data Processing

```typescript
import * as aws from "@pulumi/aws";

// Create cost categories for data pipeline
const dataPipelineCostCategory = new aws.ce.CostCategoryDefinition("data-pipeline", {
  ruleVersion: "CostCategoryExpression_v1",
  rules: [
    {
      rule: 'WHEN tags.Account IN ("data-ingestion")',
      value: "Ingestion",
    },
    {
      rule: 'WHEN tags.Account IN ("data-processing")',
      value: "Processing",
    },
    {
      rule: 'WHEN tags.Account IN ("data-consumption")',
      value: "Consumption",
    },
  ],
});

// Budget alert for Processing account (usually highest cost)
const dataProcessingBudget = new aws.budgets.Budget("data-processing", {
  budgetType: "COST",
  limitUnit: "USD",
  limitValue: 50000,  // Adjust based on your workload
  timePeriodStart: "2025-01-01",
  timePeriodEnd: "2087-12-31",
  timeUnit: "MONTHLY",
  costFilters: {
    TagKeyValue: ["Account$data-processing"],
  },
  notifications: [
    {
      comparisonOperator: "GREATER_THAN",
      notificationType: "FORECASTED",
      threshold: 80,
      thresholdType: "PERCENTAGE",
      notificationArns: [budgetAlertsTopic.arn],
    },
  ],
});
```

## IAM Best Practices

### EC2 Instance with IAM Role

```typescript
import * as aws from "@pulumi/aws";

// Create IAM role for EC2
const ec2Role = new aws.iam.Role("ec2-application-role", {
  assumeRolePolicy: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Principal: {
          Service: "ec2.amazonaws.com",
        },
        Action: "sts:AssumeRole",
      },
    ],
  }),
});

// Attach policy to role
const ec2S3Policy = new aws.iam.RolePolicy("ec2-s3-access", {
  role: ec2Role.id,
  policy: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "s3:GetObject",
          "s3:PutObject",
        ],
        Resource: "arn:aws:s3:::my-bucket/*",
      },
    ],
  }),
});

// Create instance profile
const ec2Profile = new aws.iam.InstanceProfile("ec2-application-profile", {
  role: ec2Role,
});

// Launch EC2 with role
const instance = new aws.ec2.Instance("app", {
  ami: "ami-0c55b159cbfafe1f0",
  instanceType: "t3.micro",
  iamInstanceProfile: ec2Profile,
});
```

### Permission Boundaries

```typescript
import * as aws from "@pulumi/aws";

// Create permission boundary
const developerBoundary = new aws.iam.Policy("developer-permission-boundary", {
  policy: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "ec2:*",
          "s3:*",
          "logs:*",
          "cloudwatch:*",
        ],
        Resource: "*",
      },
      {
        Effect: "Deny",
        Action: [
          "iam:*",
          "organizations:*",
          "billing:*",
        ],
        Resource: "*",
      },
    ],
  }),
});

// Create developer role with boundary
const developerRole = new aws.iam.Role("developer-role", {
  permissionsBoundary: developerBoundary.arn,
  assumeRolePolicy: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Principal: {
          AWS: "arn:aws:iam::123456789012:root",
        },
        Action: "sts:AssumeRole",
      },
    ],
  }),
});
```

### MFA Requirement

```typescript
import * as aws from "@pulumi/aws";

// Create IAM user
const developer = new aws.iam.User("john.doe");

// Require MFA via policy
const requireMfaPolicy = new aws.iam.UserPolicy("require-mfa", {
  user: developer.name,
  policy: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Deny",
        Action: "aws:*",
        Resource: "*",
        Condition: {
          BoolIfExists: {
            "aws:MultiFactorAuthPresent": "false",
          },
        },
      },
    ],
  }),
});
```

### Access Analyzer

```typescript
import * as aws from "@pulumi/aws";

// Create Access Analyzer
const analyzer = new aws.accessanalyzer.Analyzer("organization", {
  analyzerName: "organization-analyzer",
  type: "ORGANIZATION",
});

// CloudWatch rule to alert on policy changes
const iamChangesRule = new aws.cloudwatch.EventRule("iam-policy-changes", {
  description: "Alert on IAM policy changes",
  eventPattern: JSON.stringify({
    source: ["aws.iam"],
    detailType: ["AWS API Call via CloudTrail"],
    detail: {
      eventName: [
        "PutUserPolicy",
        "PutRolePolicy",
        "AttachUserPolicy",
        "AttachRolePolicy",
        "CreateAccessKey",
      ],
    },
  }),
});
```

## Cross-Account Access

```typescript
import * as aws from "@pulumi/aws";
import * as pulumi from "@pulumi/pulumi";

// In Production Account: Create role that Dev can assume
const crossAccountRole = new aws.iam.Role("dev-cross-account-role", {
  assumeRolePolicy: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Principal: {
          AWS: "arn:aws:iam::DEV_ACCOUNT_ID:root",
        },
        Action: "sts:AssumeRole",
        Condition: {
          StringEquals: {
            "sts:ExternalId": "unique-external-id-12345",
          },
        },
      },
    ],
  }),
});

// Attach permissions to the role
const crossAccountPolicy = new aws.iam.RolePolicy("dev-cross-account-policy", {
  role: crossAccountRole.id,
  policy: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "ec2:DescribeInstances",
          "s3:ListBucket",
        ],
        Resource: "*",
      },
    ],
  }),
});

// In Dev Account: Create policy to assume role in Production
const assumeProdRolePolicy = new aws.iam.RolePolicy("assume-prod-role", {
  role: developerRole.id,
  policy: JSON.stringify({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: "sts:AssumeRole",
        Resource: "arn:aws:iam::PROD_ACCOUNT_ID:role/dev-cross-account-role",
      },
    ],
  }),
});
```

## Monitoring & Compliance

### CloudTrail

```typescript
import * as aws from "@pulumi/aws";

// In Logging Account: Create S3 bucket for logs
const cloudtrailBucket = new aws.s3.Bucket("cloudtrail-logs", {
  bucket: pulumi.interpolate`org-cloudtrail-logs-${aws.getCallerIdentity().then(id => id.accountId)}`,
  versioning: {
    enabled: true,
  },
});

// In each account: Create organization trail
const organizationTrail = new aws.cloudtrail.Trail("organization", {
  s3BucketName: cloudtrailBucket.id,
  includeGlobalServiceEvents: true,
  isMultiRegionTrail: true,
  enableLogFileValidation: true,
  dependsOn: [cloudtrailBucket],
});

const trailStatus = new aws.cloudtrail.TrailStatus("organization", {
  trailName: organizationTrail.name,
  isEnabled: true,
  dependsOn: [organizationTrail],
});
```

### AWS Config

```typescript
import * as aws from "@pulumi/aws";

// Create Config recorder
const configRecorder = new aws.cfg.Recorder("main", {
  roleArn: configRole.arn,
  recordingGroup: {
    allSupported: true,
  },
});

const configRecorderStatus = new aws.cfg.RecorderStatus("main", {
  name: configRecorder.name,
  isEnabled: true,
  dependsOn: [configDeliveryChannel],
});

// Create delivery channel
const configDeliveryChannel = new aws.cfg.DeliveryChannel("main", {
  s3BucketName: configBucket.id,
});
```

### GuardDuty

```typescript
import * as aws from "@pulumi/aws";

// Enable GuardDuty
const guarddutyDetector = new aws.guardduty.Detector("main", {
  enable: true,
  datasources: {
    s3Logs: {
      enable: true,
    },
    kubernetes: {
      auditLogs: {
        enable: true,
      },
    },
  },
});

// Create CloudWatch alert for findings
const guarddutyFindingsRule = new aws.cloudwatch.EventRule("guardduty-findings", {
  description: "Alert on GuardDuty findings",
  eventPattern: JSON.stringify({
    source: ["aws.guardduty"],
    detailType: ["GuardDuty Finding"],
    detail: {
      severity: [7, 7.0, 7.1, 7.2, 7.3, 8, 8.0, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9, 9],
    },
  }),
});
```

## Key Advantages of Pulumi

- **Type-safe**: Full TypeScript type checking for AWS resources
- **Reusable components**: Create functions and classes for infrastructure patterns
- **Better testing**: Unit test your infrastructure like regular code
- **IDE support**: Full IntelliSense and refactoring capabilities
- **Secrets management**: Built-in, encrypted by default
- **Automation API**: Programmatic infrastructure updates
