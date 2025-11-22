---
rule_id: aws-terraform-implementations
title: "AWS Infrastructure with Terraform"
date-created: 2025-11-21
date-updated: 2025-11-21
tags: [aws, terraform, infrastructure-as-code, iac]
aliases: [terraform-aws, aws-terraform-examples]
---

# AWS Infrastructure with Terraform

This file contains all Terraform implementations for AWS best practices. For Pulumi examples, see `aws-pulumi.md`.

## VPC Gateway Endpoints for S3

```hcl
# Create a Gateway Endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  
  # Associate with route tables
  route_table_ids = [
    aws_route_table.private.id,
    aws_route_table.public.id
  ]
}

# Optional: Restrict endpoint access with a policy
resource "aws_vpc_endpoint_policy" "s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Principal = "*"
        Action   = "s3:*"
        Resource = "*"
      }
    ]
  })
}
```

## Cost Anomaly Detection Setup

```hcl
# Create SNS topic for cost alerts
resource "aws_sns_topic" "cost_alerts" {
  name = "aws-cost-anomaly-alerts"
  
  tags = {
    Name        = "Cost Anomaly Alerts"
    Environment = "production"
  }
}

# Subscribe email to SNS topic
resource "aws_sns_topic_subscription" "cost_alerts_email" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"
}

# Create Cost Anomaly Detection monitor
resource "aws_ce_anomaly_monitor" "all_services" {
  name              = "all-services-anomaly-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
  
  tags = {
    Name        = "All Services Anomaly Monitor"
    Environment = "production"
  }
}

# Create Cost Anomaly Detection alert
resource "aws_ce_anomaly_subscription" "all_services" {
  name            = "all-services-anomaly-alert"
  threshold       = 100  # Alert on $100+ anomalies
  frequency       = "DAILY"
  monitor_arn     = aws_ce_anomaly_monitor.all_services.arn
  sns_topic_arns  = [aws_sns_topic.cost_alerts.arn]
  
  tags = {
    Name        = "All Services Anomaly Alert"
    Environment = "production"
  }
}

# Optional: Create a more sensitive monitor for NAT Gateway specifically
resource "aws_ce_anomaly_monitor" "nat_gateway" {
  name              = "nat-gateway-anomaly-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
  
  # Filter to only EC2 (which includes NAT Gateway costs)
  tags = {
    Name        = "NAT Gateway Anomaly Monitor"
    Environment = "production"
  }
}

resource "aws_ce_anomaly_subscription" "nat_gateway" {
  name            = "nat-gateway-anomaly-alert"
  threshold       = 50  # Lower threshold for NAT Gateway
  frequency       = "DAILY"
  monitor_arn     = aws_ce_anomaly_monitor.nat_gateway.arn
  sns_topic_arns  = [aws_sns_topic.cost_alerts.arn]
  
  tags = {
    Name        = "NAT Gateway Anomaly Alert"
    Environment = "production"
  }
}
```

## AWS Organizations Setup

```hcl
# Create AWS Organization
resource "aws_organizations_organization" "main" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
  ]
  
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
  ]
  
  feature_set = "ALL"
}

# Create Organizational Units
resource "aws_organizations_organizational_unit" "production" {
  name      = "Production"
  parent_id = aws_organizations_organization.main.roots[0].id
}

resource "aws_organizations_organizational_unit" "development" {
  name      = "Development"
  parent_id = aws_organizations_organization.main.roots[0].id
}

resource "aws_organizations_organizational_unit" "shared_services" {
  name      = "Shared Services"
  parent_id = aws_organizations_organization.main.roots[0].id
}

# Create Production Account
resource "aws_organizations_account" "production" {
  name              = "Production"
  email             = "aws-prod@example.com"
  parent_id         = aws_organizations_organizational_unit.production.id
  iam_user_access_to_billing = "ALLOW"
}

# Create Development Account
resource "aws_organizations_account" "development" {
  name              = "Development"
  email             = "aws-dev@example.com"
  parent_id         = aws_organizations_organizational_unit.development.id
  iam_user_access_to_billing = "ALLOW"
}

# Create Logging Account
resource "aws_organizations_account" "logging" {
  name              = "Logging"
  email             = "aws-logging@example.com"
  parent_id         = aws_organizations_organizational_unit.shared_services.id
  iam_user_access_to_billing = "ALLOW"
}

# Create Service Control Policy to prevent dangerous actions
resource "aws_organizations_policy" "deny_root_account_actions" {
  name    = "DenyRootAccountActions"
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = [
          "iam:CreateAccessKey",
          "iam:CreateUser",
          "iam:CreateLoginProfile",
          "iam:AttachUserPolicy",
        ]
        Resource = "arn:aws:iam::*:root"
      }
    ]
  })
}

# Attach SCP to prevent EC2 in non-approved regions
resource "aws_organizations_policy" "restrict_regions" {
  name    = "RestrictRegions"
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = "ec2:*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = ["us-east-1", "us-west-2", "eu-west-1"]
          }
        }
      }
    ]
  })
}
```

## Resource Tagging

```hcl
# Define common tags
locals {
  common_tags = {
    # Technical
    Purpose             = "Core"
    App                 = "job-aide"
    Service             = "api"
    Version             = "1.2.3"
    Environment         = var.environment
    SLA                 = "99.9"
    DeployingIndividual = "terraform-automation"
    DeployingDepartment = "DevOps"
    Pattern             = "microservice-on-ecs"
    
    # Business
    RequestingDepartmentManager = "engineering-manager"
    RequestingIndividual        = "product-owner"
    RequestingDepartment        = "Engineering"
    Product                     = "job-aide-platform"
    
    # Governance
    PIILevel              = "High"
    ComplianceRequired    = "SOC2,PCI-DSS"
    SecurityClassification = "Confidential"
    RetireDate            = "2027-12-31"
    CostCenter            = "ENG-001"
    Tenancy               = "internal"
    
    # Lineage (optional, can be resource-specific)
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
    ManagedBy   = "terraform"
  }
}

# Apply tags to all resources
resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  
  tags = merge(
    local.common_tags,
    {
      Name = "job-aide-api-instance"
      # Resource-specific overrides
      Purpose = "Core"
    }
  )
}

resource "aws_s3_bucket" "data" {
  bucket = "job-aide-data-${var.environment}"
  
  tags = merge(
    local.common_tags,
    {
      Name = "job-aide-data-bucket"
      PIILevel = "High"  # Override if needed
    }
  )
}

resource "aws_rds_cluster" "database" {
  cluster_identifier = "job-aide-db-${var.environment}"
  
  tags = merge(
    local.common_tags,
    {
      Name = "job-aide-database"
      PIILevel = "High"
      ComplianceRequired = "SOC2,PCI-DSS,HIPAA"
    }
  )
}
```

## Tag Enforcement with AWS Config

```hcl
# Require specific tags on all resources
resource "aws_config_config_rule" "required_tags" {
  name = "required-tags"
  
  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }
  
  input_parameters = jsonencode({
    tag1Key = "Environment"
    tag2Key = "App"
    tag3Key = "CostCenter"
    tag4Key = "ComplianceRequired"
    tag5Key = "SecurityClassification"
  })
}

# Remediation: Tag non-compliant resources automatically
resource "aws_config_remediation_configurations" "tag_resources" {
  config_rule_name = aws_config_config_rule.required_tags.name
  
  resource_type       = "AWS::EC2::Instance"
  target_type         = "SSM_DOCUMENT"
  target_identifier   = "AWS-TagResource"
  target_version      = "1"
  automatic            = true
  maximum_automatic_attempts = 100
  automatic_remediation_before_compliance = false
  
  parameter {
    static_value = "Environment"
    name         = "Tag1Key"
  }
  
  parameter {
    static_value = var.environment
    name         = "Tag1Value"
  }
}
```

## Tag-Based Cost Allocation

```hcl
# Enable Cost Allocation Tags
resource "aws_ce_cost_category_definition" "department" {
  name         = "Department"
  rule_version = "CostCategoryExpression_v1"
  
  rule {
    rule = "WHEN tags.RequestingDepartment IN (\"Engineering\")"
    value = "Engineering"
  }
  
  rule {
    rule = "WHEN tags.RequestingDepartment IN (\"Finance\")"
    value = "Finance"
  }
}

# Create budget alert by cost center
resource "aws_budgets_budget" "engineering" {
  name              = "engineering-monthly-budget"
  budget_type       = "COST"
  limit_unit        = "USD"
  limit_value       = "10000"
  time_period_start = "2025-01-01"
  time_period_end   = "2087-12-31"
  time_unit         = "MONTHLY"
  
  cost_filter {
    name   = "TagKeyValue"
    values = ["CostCenter$ENG-001"]
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_channel_arns  = [aws_sns_topic.budget_alerts.arn]
  }
}
```

## Data Processing Accounts

```hcl
# Create Data Processing OU
resource "aws_organizations_organizational_unit" "data_processing" {
  name      = "Data Processing"
  parent_id = aws_organizations_organization.main.roots[0].id
}

# Create Ingestion Account
resource "aws_organizations_account" "data_ingestion" {
  name              = "Data Ingestion"
  email             = "aws-data-ingestion@example.com"
  parent_id         = aws_organizations_organizational_unit.data_processing.id
  iam_user_access_to_billing = "ALLOW"
}

# Create Processing Account
resource "aws_organizations_account" "data_processing" {
  name              = "Data Processing"
  email             = "aws-data-processing@example.com"
  parent_id         = aws_organizations_organizational_unit.data_processing.id
  iam_user_access_to_billing = "ALLOW"
}

# Create Consumption Account
resource "aws_organizations_account" "data_consumption" {
  name              = "Data Consumption"
  email             = "aws-data-consumption@example.com"
  parent_id         = aws_organizations_organizational_unit.data_processing.id
  iam_user_access_to_billing = "ALLOW"
}

# SCP: Prevent expensive compute in Ingestion account
resource "aws_organizations_policy" "ingestion_restrictions" {
  name    = "DataIngestionRestrictions"
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = [
          "ec2:RunInstances",
          "emr:RunJobFlow",
          "glue:CreateJob",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = ["us-east-1"]  # Only allow in primary region
          }
        }
      }
    ]
  })
}

# SCP: Prevent data export from Ingestion account
resource "aws_organizations_policy" "ingestion_data_protection" {
  name    = "DataIngestionProtection"
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
        ]
        Resource = "arn:aws:s3:::*-raw-data/*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalOrgID" = data.aws_organizations_organization.main.id
          }
        }
      }
    ]
  })
}

# Cross-account role: Processing account can read from Ingestion
resource "aws_iam_role" "ingestion_reader" {
  provider = aws.ingestion
  name     = "processing-account-reader"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${aws_organizations_account.data_processing.id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ingestion_reader_policy" {
  provider = aws.ingestion
  name     = "processing-read-policy"
  role     = aws_iam_role.ingestion_reader.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::*-raw-data",
          "arn:aws:s3:::*-raw-data/*",
        ]
      }
    ]
  })
}

# Cross-account role: Consumption account can read from Processing
resource "aws_iam_role" "processing_reader" {
  provider = aws.processing
  name     = "consumption-account-reader"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${aws_organizations_account.data_consumption.id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "processing_reader_policy" {
  provider = aws.processing
  name     = "consumption-read-policy"
  role     = aws_iam_role.processing_reader.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::*-processed-data",
          "arn:aws:s3:::*-processed-data/*",
        ]
      }
    ]
  })
}
```

## Cost Attribution for Data Processing

```hcl
# Create cost categories for data pipeline
resource "aws_ce_cost_category_definition" "data_pipeline" {
  name         = "DataPipeline"
  rule_version = "CostCategoryExpression_v1"
  
  rule {
    rule = "WHEN tags.Account IN (\"data-ingestion\")"
    value = "Ingestion"
  }
  
  rule {
    rule = "WHEN tags.Account IN (\"data-processing\")"
    value = "Processing"
  }
  
  rule {
    rule = "WHEN tags.Account IN (\"data-consumption\")"
    value = "Consumption"
  }
}

# Budget alert for Processing account (usually highest cost)
resource "aws_budgets_budget" "data_processing_budget" {
  name              = "data-processing-monthly-budget"
  budget_type       = "COST"
  limit_unit        = "USD"
  limit_value       = "50000"  # Adjust based on your workload
  time_period_start = "2025-01-01"
  time_period_end   = "2087-12-31"
  time_unit         = "MONTHLY"
  
  cost_filter {
    name   = "TagKeyValue"
    values = ["Account$data-processing"]
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_channel_arns  = [aws_sns_topic.data_alerts.arn]
  }
}
```

## IAM Best Practices

### EC2 Instance with IAM Role

```hcl
# Create IAM role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "ec2-application-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy" "ec2_s3_access" {
  name = "ec2-s3-access"
  role = aws_iam_role.ec2_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = "arn:aws:s3:::my-bucket/*"
      }
    ]
  })
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-application-profile"
  role = aws_iam_role.ec2_role.name
}

# Launch EC2 with role
resource "aws_instance" "app" {
  ami                  = "ami-0c55b159cbfafe1f0"
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
}
```

### Permission Boundaries

```hcl
# Create permission boundary
resource "aws_iam_policy" "developer_boundary" {
  name = "developer-permission-boundary"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "logs:*",
          "cloudwatch:*",
        ]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = [
          "iam:*",
          "organizations:*",
          "billing:*",
        ]
        Resource = "*"
      }
    ]
  })
}

# Create developer role with boundary
resource "aws_iam_role" "developer" {
  name                 = "developer-role"
  permissions_boundary = aws_iam_policy.developer_boundary.arn
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
```

### MFA Requirement

```hcl
# Create IAM user
resource "aws_iam_user" "developer" {
  name = "john.doe"
}

# Require MFA via policy
resource "aws_iam_user_policy" "require_mfa" {
  name = "require-mfa"
  user = aws_iam_user.developer.name
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = "aws:*"
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
}
```

### Access Analyzer

```hcl
# Create Access Analyzer
resource "aws_accessanalyzer_analyzer" "organization" {
  analyzer_name = "organization-analyzer"
  type          = "ORGANIZATION"
}

# CloudWatch rule to alert on policy changes
resource "aws_cloudwatch_event_rule" "iam_changes" {
  name        = "iam-policy-changes"
  description = "Alert on IAM policy changes"
  
  event_pattern = jsonencode({
    source      = ["aws.iam"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "PutUserPolicy",
        "PutRolePolicy",
        "AttachUserPolicy",
        "AttachRolePolicy",
        "CreateAccessKey",
      ]
    }
  })
}
```

## Cross-Account Access

```hcl
# In Production Account: Create role that Dev can assume
resource "aws_iam_role" "cross_account_role" {
  name = "dev-cross-account-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::DEV_ACCOUNT_ID:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "unique-external-id-12345"
          }
        }
      }
    ]
  })
}

# Attach permissions to the role
resource "aws_iam_role_policy" "cross_account_policy" {
  name = "dev-cross-account-policy"
  role = aws_iam_role.cross_account_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "s3:ListBucket",
        ]
        Resource = "*"
      }
    ]
  })
}

# In Dev Account: Create policy to assume role in Production
resource "aws_iam_role_policy" "assume_prod_role" {
  name = "assume-prod-role"
  role = aws_iam_role.developer.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = "arn:aws:iam::PROD_ACCOUNT_ID:role/dev-cross-account-role"
      }
    ]
  })
}
```

## Monitoring & Compliance

### CloudTrail

```hcl
# In Logging Account: Create S3 bucket for logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "org-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# In each account: Create organization trail
resource "aws_cloudtrail" "organization" {
  name                          = "organization-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.cloudtrail_logs]
}
```

### AWS Config

```hcl
# Create Config recorder
resource "aws_config_configuration_recorder" "main" {
  name       = "main"
  role_arn   = aws_iam_role.config_role.arn
  depends_on = [aws_iam_role_policy_attachment.config_policy]
  
  recording_group {
    all_supported = true
  }
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

# Create delivery channel
resource "aws_config_delivery_channel" "main" {
  name           = "main"
  s3_bucket_name = aws_s3_bucket.config_logs.id
}
```

### GuardDuty

```hcl
# Enable GuardDuty
resource "aws_guardduty_detector" "main" {
  enable = true
  
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
  }
}

# Create CloudWatch alert for findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "guardduty-findings"
  description = "Alert on GuardDuty findings"
  
  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [7, 7.0, 7.1, 7.2, 7.3, 8, 8.0, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9, 9]
    }
  })
}
```

### Athena Tag Audit

```hcl
# Create a report of all resources and their tags
resource "aws_athena_workgroup" "tag_audit" {
  name = "tag-audit"
  
  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/results/"
    }
  }
}

# Query to find resources missing required tags
resource "aws_athena_named_query" "missing_tags" {
  name            = "resources-missing-required-tags"
  description     = "Find all resources missing Environment, App, or CostCenter tags"
  database        = "default"
  query           = <<-EOT
    SELECT
      resourceid,
      resourcetype,
      tags
    FROM aws_cloudtrail_logs
    WHERE
      (tags NOT LIKE '%Environment%' OR
       tags NOT LIKE '%App%' OR
       tags NOT LIKE '%CostCenter%')
      AND eventtime > date_format(current_date - interval '7' day, '%Y-%m-%dT%H:%i:%SZ')
  EOT
  workgroup       = aws_athena_workgroup.tag_audit.name
}
```
