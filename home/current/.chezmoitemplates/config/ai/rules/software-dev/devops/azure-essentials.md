# Azure Best Practices

**Document Version**: 1.0  
**Last Updated**: 2025-11-22  
**Scope**: Cloud provider abstraction library support for Microsoft Azure

## Overview

Microsoft Azure is a comprehensive cloud platform offering compute, storage, database, and networking services. This document outlines best practices for cost optimization, security, reliability, and performance when using Azure within the cloud provider abstraction library.

---

## 1. Storage Services

### Azure Blob Storage (Azure Equivalent of S3)

#### Prototyping Configuration (Minimize Cost)

- **Storage Tier**: Hot (default, lowest retrieval cost)
- **Replication**: Locally Redundant Storage (LRS) - single region
- **Versioning**: Disabled (cost savings)
- **Encryption**: Microsoft-managed encryption (default, free)
- **Lifecycle Policies**: Auto-delete after 30 days (prevents accidental long-term costs)
- **Access Logging**: Disabled ($0.50/GB equivalent cost)
- **Cost Estimate**: ~$2-5/month for typical prototyping workloads

**Disabled Features** (Cost Optimization):
- Blob versioning (saves storage)
- Access logging (saves ingestion costs)
- Geo-redundancy (saves data transfer)
- Retention policies (unnecessary for ephemeral data)

#### Testing Configuration (Full Observability)

- **Storage Tier**: Hot
- **Replication**: Geo-Redundant Storage (GRS) - automatic failover to secondary region
- **Versioning**: Enabled (for test data recovery)
- **Encryption**: Microsoft-managed encryption
- **Lifecycle Policies**: Indefinite retention (testing data needs persistence)
- **Access Logging**: Enabled (logs to Azure Monitor)
- **Monitoring**: Enabled (Azure Monitor)
- **Cost Estimate**: ~$50-100/month

#### Production Configuration (Reliability & Compliance)

- **Storage Tier**: Hot + Cool (transition after 30 days)
- **Replication**: Geo-Redundant Storage (GRS) with Read-Access (RA-GRS)
- **Versioning**: Enabled (required for compliance)
- **Encryption**: Customer-managed encryption (Azure Key Vault)
- **Lifecycle Policies**: Transition to Archive after 90 days (cost optimization)
- **Access Logging**: Enabled (required for compliance audits)
- **Monitoring**: Enabled with alarms
- **Retention Rules**: Enabled (compliance requirement)
- **Cost Estimate**: $500+/month

#### Cost Optimization Strategies

| Strategy | Savings | Trade-off |
|----------|---------|-----------|
| Hot vs. Cool | ~50% after 30 days | Early deletion fees |
| Hot vs. Archive | ~80% after 90 days | Retrieval delays (15 hours) |
| LRS vs. GRS | ~50% | No geographic redundancy |
| Disable versioning | ~30% | No rollback capability |
| Disable access logging | ~$0.50/GB | No access audit trail |

---

## 2. Database Services

### Azure SQL Database (Azure Equivalent of RDS)

#### Prototyping Configuration

- **Deployment**: Single database (no redundancy)
- **Compute Tier**: Serverless (pay-per-use, auto-scales to 0.5 vCore)
- **Backup Retention**: 7 days (minimal)
- **Encryption**: Microsoft-managed encryption
- **Monitoring**: Disabled (cost savings)
- **Automated Backups**: Enabled (required, cannot be disabled)
- **High Availability**: Disabled
- **Cost Estimate**: ~$10-20/month

**Key Features**:
- Azure SQL is fully managed (automatic patching)
- Serverless tier auto-scales and pauses when not in use
- Automated backups are mandatory
- Always encrypted (cannot be disabled)

#### Testing Configuration

- **Deployment**: Single database
- **Compute Tier**: General Purpose (2 vCores)
- **Backup Retention**: 7 days
- **Encryption**: Microsoft-managed encryption
- **Monitoring**: Enabled (Azure Monitor)
- **Automated Backups**: Enabled
- **High Availability**: Optional (for HA testing)
- **Cost Estimate**: ~$50-100/month

#### Production Configuration

- **Deployment**: Business Critical (High Availability with automatic failover)
- **Compute Tier**: Business Critical (4+ vCores)
- **Backup Retention**: 35 days
- **Encryption**: Customer-managed encryption (Azure Key Vault)
- **Monitoring**: Enabled with alarms
- **Automated Backups**: Enabled
- **High Availability**: Enabled (Always On Availability Groups)
- **Read Replicas**: Enabled (for read scaling)
- **Audit Logging**: Enabled (required for compliance)
- **Cost Estimate**: $500+/month

#### Azure SQL Advantages

- **Fully managed**: Automatic patching, backups, and maintenance
- **Serverless**: Auto-scales and pauses when not in use (cost savings)
- **High Availability**: Automatic failover to standby replica
- **Always encrypted**: Data encryption is mandatory

---

## 3. Cosmos DB (NoSQL Database)

### Azure Cosmos DB

#### Prototyping Configuration

- **API**: Core (SQL) API
- **Consistency**: Eventual (lowest cost)
- **Replication**: Single-region
- **Backup**: Automatic (daily)
- **Encryption**: Microsoft-managed encryption
- **Monitoring**: Disabled
- **Provisioned Throughput**: 400 RU/s (minimum)
- **Cost Estimate**: ~$20-30/month

**Always Free Tier**:
- 1000 RU/s provisioned throughput
- 25 GB storage
- Limited to one Azure Cosmos DB account per subscription

#### Testing Configuration

- **API**: Core (SQL) API
- **Consistency**: Session (balanced)
- **Replication**: Multi-region
- **Backup**: Automatic (daily)
- **Encryption**: Microsoft-managed encryption
- **Monitoring**: Enabled
- **Provisioned Throughput**: 1000 RU/s
- **Cost Estimate**: ~$50-100/month

#### Production Configuration

- **API**: Core (SQL) API
- **Consistency**: Strong (highest cost)
- **Replication**: Multi-region with automatic failover
- **Backup**: Automatic (daily) + manual backups
- **Encryption**: Customer-managed encryption (Azure Key Vault)
- **Monitoring**: Enabled with alarms
- **Provisioned Throughput**: 10,000+ RU/s
- **Point-in-time recovery**: Enabled
- **Cost Estimate**: $500+/month

---

## 4. Networking Services

### Azure Virtual Network (VNet)

#### Prototyping Configuration

- **Network Security Groups (NSGs)**: Disabled (cost savings)
- **Azure Firewall**: None (cost savings)
- **Load Balancer**: None (cost savings)
- **Network Segmentation**: Single subnet
- **VPN Gateway**: None
- **Cost Estimate**: ~$0/month (VNet itself is free)

**Cost Optimization**:
- Use Service Endpoints for free access to Azure services (no NAT Gateway needed)
- Avoid Azure Firewall (expensive: ~$1.25/hour)
- Use Network Security Groups instead (free)

#### Testing Configuration

- **Network Security Groups (NSGs)**: Enabled (logs to Azure Monitor)
- **Azure Firewall**: Optional (for testing DDoS protection)
- **Load Balancer**: Optional (for testing HA)
- **Network Segmentation**: Public + private subnets
- **Monitoring**: Enabled (Azure Monitor)
- **VPN Gateway**: Optional
- **Cost Estimate**: ~$32/month (Load Balancer)

#### Production Configuration

- **Network Security Groups (NSGs)**: Enabled (explicit allow rules)
- **Azure Firewall**: Enabled (DDoS protection)
- **Load Balancer**: Enabled (Standard Load Balancer for HA)
- **Network Segmentation**: Multi-tier (public, private, database)
- **VPN Gateway**: Enabled (for secure on-premises connectivity)
- **Application Gateway**: Enabled (for web application firewall)
- **DDoS Protection**: Enabled (Standard or Premium)
- **Cost Estimate**: $100+/month

---

## 5. Compute Services

### Azure Virtual Machines (VMs)

#### Prototyping Configuration (Minimize Cost)

- **VM Size**: B1s (1 vCPU, 1 GB RAM)
- **Pricing Model**: Spot instances (70%+ savings)
- **Image**: Ubuntu (free, optimized for Azure)
- **Monitoring**: Disabled (cost savings)
- **Auto-scaling**: Disabled
- **Cost Estimate**: ~$5-10/month (or free with Always Free tier)

**Spot Instances**:
- 70%+ cost savings vs. on-demand
- Can be evicted with 30-second notice
- Suitable for fault-tolerant workloads (batch processing, testing)

**Always Free Tier**:
- 1 B1s VM per month (730 hours)
- 1 TB outbound bandwidth per month
- 5 GB managed disk storage

#### Testing Configuration

- **VM Size**: Standard_B2s (2 vCPUs, 4 GB RAM)
- **Pricing Model**: On-demand
- **Image**: Ubuntu or Windows Server
- **Monitoring**: Enabled (Azure Monitor)
- **Auto-scaling**: Enabled (via Virtual Machine Scale Sets)
- **Cost Estimate**: ~$50-100/month

#### Production Configuration

- **VM Size**: Standard_D4s_v3 or larger (4+ vCPUs)
- **Pricing Model**: On-demand (for reliability)
- **Image**: Ubuntu (optimized, free)
- **Monitoring**: Enabled with alarms
- **Auto-scaling**: Enabled (via Virtual Machine Scale Sets)
- **Availability Set**: Enabled (for HA)
- **Cost Estimate**: $500+/month

#### Azure VM Advantages

- **Always Free tier**: B1s VM, 1 TB egress, 5 GB managed disk
- **Spot instances**: 70%+ savings for fault-tolerant workloads
- **Reserved instances**: Up to 72% discount for 3-year commitments
- **Hybrid Benefit**: Reuse on-premises licenses (Windows, SQL Server)

---

## 6. Security Best Practices

### Identity & Access Management (IAM)

#### Prototyping

- **Resource Groups**: Single resource group (no isolation needed)
- **Service Principals**: Default service principal
- **Roles**: Owner or Contributor (broad permissions)
- **MFA**: Optional
- **Audit Logging**: Disabled

#### Testing

- **Resource Groups**: Separate resource group for testing
- **Service Principals**: Custom service principals per component
- **Roles**: Predefined roles (Virtual Machine Contributor, Storage Account Contributor, etc.)
- **MFA**: Enabled for human users
- **Audit Logging**: Enabled (Azure Activity Log)

#### Production

- **Resource Groups**: Separate resource groups per environment/team
- **Service Principals**: Custom service principals with minimal permissions
- **Roles**: Custom roles with least-privilege access
- **MFA**: Required for all users
- **Audit Logging**: Enabled with long retention (90+ days)
- **Managed Identities**: Enabled (for Azure resource authentication)

### Encryption

#### Data at Rest

- **Prototyping**: Microsoft-managed encryption (default, free)
- **Testing**: Microsoft-managed encryption
- **Production**: Customer-managed encryption (Azure Key Vault) for compliance

#### Data in Transit

- **All Environments**: TLS 1.2+ (enforced by Azure)
- **Production**: Mutual TLS (mTLS) for service-to-service communication

### Network Security

- **Network Security Groups (NSGs)**: Explicit allow rules (deny-by-default)
- **Azure Firewall**: DDoS protection (enabled in production)
- **Web Application Firewall (WAF)**: Additional layer of security (optional)
- **Azure Defender**: Threat protection (optional)

---

## 7. Compliance & Governance

### Audit & Logging

| Component | Prototyping | Testing | Production |
|-----------|-------------|---------|------------|
| **Activity Log** | Disabled | Enabled | Enabled (90-day retention) |
| **NSG Flow Logs** | Disabled | Enabled | Enabled |
| **Azure Monitor** | Disabled | Enabled | Enabled |
| **Application Insights** | Disabled | Optional | Enabled |

### Compliance Standards

#### SOC2 Compliance

- Enable Activity Log
- Enable NSG Flow Logs
- Implement encryption at rest (Key Vault)
- Implement encryption in transit (TLS)
- Restrict public access (NSGs)
- Enable MFA for all users

#### PCI-DSS Compliance

- Encryption at rest (Azure Key Vault)
- Encryption in transit (TLS 1.2+)
- Network segmentation (VNet subnets)
- Access logging (all components)
- Audit logging (90-day retention)
- Vulnerability scanning (Azure Defender)
- DDoS protection (Azure DDoS Protection)

#### HIPAA Compliance

- Encryption at rest (customer-managed Azure Key Vault)
- Encryption in transit (mTLS)
- Audit logging (immutable, 6-year retention)
- Access controls (RBAC, MFA)
- Data residency (specific Azure regions)
- Business Associate Agreement (BAA) with Microsoft

---

## 8. Cost Optimization Strategies

### Storage Cost Optimization

1. **Use Cool/Archive tiers** for data older than 30/90 days (50-80% savings)
2. **Enable lifecycle policies** to auto-transition storage tiers
3. **Disable versioning** for non-critical data (30% savings)
4. **Use Service Endpoints** for free Azure service access (no NAT Gateway)
5. **Compress data** before storage (reduces storage and transfer costs)

### Compute Cost Optimization

1. **Use Spot instances** for fault-tolerant workloads (70%+ savings)
2. **Use Always Free tier** for eligible accounts (free compute, storage, database)
3. **Use Reserved Instances** (up to 72% discount for 3-year commitments)
4. **Use Hybrid Benefit** (reuse on-premises licenses)
5. **Schedule VMs** to stop during off-hours (for non-24/7 workloads)

### Database Cost Optimization

1. **Use Serverless tier** for variable workloads (auto-scales and pauses)
2. **Reduce backup retention** for non-critical data (7 days for prototyping)
3. **Disable High Availability** for non-critical databases (replication costs)
4. **Use Microsoft-managed encryption** instead of customer-managed Key Vault
5. **Right-size compute tier** (use smaller tiers for prototyping)

### Network Cost Optimization

1. **Use Service Endpoints** for free Azure service access (no NAT Gateway)
2. **Avoid Azure Firewall** when possible (expensive: ~$1.25/hour)
3. **Use Network Security Groups** instead (free)
4. **Use VNet Peering** instead of VPN for inter-VNet communication
5. **Avoid cross-region data transfer** (expensive: $0.02/GB)

---

## 9. Azure vs. AWS Comparison

| Feature | Azure | AWS | Notes |
|---------|-------|-----|-------|
| **Object Storage** | Blob Storage | S3 | Azure: simpler pricing; AWS: more storage classes |
| **Database** | Azure SQL | RDS | Azure: serverless option; AWS: more control |
| **Compute** | Virtual Machines | EC2 | Azure: Spot instances; AWS: spot instances |
| **Networking** | VNet | VPC | Similar functionality, different terminology |
| **Encryption** | Key Vault | KMS | Both support customer-managed keys |
| **Logging** | Activity Log | CloudTrail | Similar functionality |
| **Cost** | Generally cheaper | Higher | Azure: reserved instances available |

### Azure Advantages

1. **Always Free tier**: Generous free tier (compute, storage, database)
2. **Serverless database**: Auto-scales and pauses when not in use
3. **Hybrid Benefit**: Reuse on-premises licenses (Windows, SQL Server)
4. **Reserved instances**: Up to 72% discount for 3-year commitments
5. **Integrated DevOps**: Azure DevOps is included

### AWS Advantages

1. **Larger ecosystem**: More third-party integrations
2. **More service options**: Broader service portfolio
3. **Mature marketplace**: Larger community and documentation
4. **Spot instances**: More flexible pricing options

---

## 10. Migration Path from AWS to Azure

### Service Mapping

| AWS Service | Azure Equivalent | Migration Effort |
|-------------|------------------|-----------------|
| S3 | Blob Storage | Low (similar APIs) |
| RDS | Azure SQL Database | Medium (schema migration) |
| EC2 | Virtual Machines | Medium (image conversion) |
| VPC | Virtual Network | Low (similar concepts) |
| CloudTrail | Activity Log | Low (similar functionality) |
| KMS | Key Vault | Low (key migration) |
| CloudFront | Azure CDN | Medium (configuration migration) |
| Lambda | Azure Functions | High (code rewrite) |

### Migration Best Practices

1. **Use Azure Migrate** for VM migration
2. **Use Database Migration Service** (DMS) for database migrations
3. **Test in Azure first** (use Always Free tier for prototyping)
4. **Plan for data transfer costs** (cross-region transfer is expensive)
5. **Validate compliance** (ensure Azure regions meet data residency requirements)

---

## 11. Monitoring & Observability

### Azure Monitor & Logging

- **Metrics**: CPU, memory, disk, network (free tier: 5-minute granularity)
- **Alarms**: Threshold-based alerts (free tier: limited)
- **Dashboards**: Custom dashboards (free tier: limited)
- **Logs**: Centralized logging (Log Analytics)

### Recommended Monitoring Setup

#### Prototyping

- Minimal monitoring (cost savings)
- Basic alarms for critical failures

#### Testing

- Full monitoring (Azure Monitor)
- Alarms for performance degradation
- Log aggregation (Log Analytics)

#### Production

- Comprehensive monitoring (Azure Monitor)
- Alarms for all critical metrics
- Log aggregation with long retention (90+ days)
- Application Insights for application monitoring

---

## 12. Disaster Recovery & High Availability

### RTO/RPO Targets

| Environment | RTO | RPO | Strategy |
|-------------|-----|-----|----------|
| **Prototyping** | 24 hours | 24 hours | Manual recovery, daily backups |
| **Testing** | 4 hours | 1 hour | Automated backups, cross-region replication |
| **Production** | 1 hour | 15 minutes | HA deployment, cross-region failover |

### High Availability Architecture

#### Prototyping

- Single-region, single-zone deployment
- Daily backups (7-day retention)
- Manual recovery process

#### Testing

- Single-region, multi-zone deployment (Availability Zones)
- Automated backups (7-day retention)
- Load balancer for HA
- Auto-scaling enabled

#### Production

- Multi-region deployment
- Azure SQL High Availability (Always On Availability Groups)
- Geo-Redundant Storage (GRS) for data replication
- Azure Traffic Manager for global load balancing
- Automated failover (RTO < 1 hour)

---

## 13. Azure-Specific Features

### Always Free Tier

Azure offers a generous Always Free tier (not time-limited):

- **Compute**: 1 B1s VM per month (730 hours)
- **Storage**: 5 GB managed disk, 5 GB Blob Storage
- **Database**: 1 Azure SQL Database (20 GB)
- **Networking**: 1 TB outbound bandwidth per month

**Prototyping Benefit**: Entire prototyping infrastructure can run free on Always Free tier.

### Spot Instances

Azure's Spot instances offer:

- **Cost Savings**: 70%+ discount vs. on-demand
- **Eviction Notice**: 30-second notice before termination
- **Use Cases**: Batch processing, testing, fault-tolerant workloads

**Cost Benefit**: Significant savings for non-critical workloads.

### Reserved Instances

Azure offers discounts for multi-year commitments:

- **1-Year Commitment**: Up to 38% discount
- **3-Year Commitment**: Up to 72% discount
- **Available For**: Compute, storage, database, networking

**Production Benefit**: Long-term cost savings for stable workloads.

---

## 14. Recommended Configuration Templates

### Prototyping Stack (Minimal Cost)

```yaml
Environment: prototyping
Attributes:
  - minimize-cost
  - use-always-free-tier

Components:
  Storage: Blob Storage (Hot, LRS, 30-day auto-delete)
  Database: Azure SQL (Serverless, Microsoft-managed encryption)
  Compute: Virtual Machines (B1s Spot, Ubuntu)
  Networking: VNet with Service Endpoints (free Azure service access)

Estimated Cost: $0-5/month (or free with Always Free tier)
```

### Testing Stack (Full Observability)

```yaml
Environment: testing
Attributes:
  - maximize-observability
  - maximize-reliability

Components:
  Storage: Blob Storage (Hot, GRS, versioning enabled)
  Database: Azure SQL (General Purpose, Microsoft-managed encryption)
  Compute: Virtual Machines (Standard_B2s On-demand, auto-scaling enabled)
  Networking: VNet with Load Balancer, NSGs, monitoring enabled

Estimated Cost: $50-100/month
```

### Production Stack (Reliability & Compliance)

```yaml
Environment: production
Attributes:
  - maximize-reliability
  - comply-with-SOC2
  - comply-with-PCI-DSS

Components:
  Storage: Blob Storage (Hot + Cool, GRS with RA-GRS)
  Database: Azure SQL (Business Critical, High Availability, customer-managed encryption)
  Compute: Virtual Machines (Standard_D4s_v3+, multi-zone, auto-scaling)
  Networking: VNet with Azure Firewall, Application Gateway, DDoS Protection

Estimated Cost: $500+/month
```

---

## References

- [Azure Documentation](https://docs.microsoft.com/en-us/azure/)
- [Azure Best Practices](https://docs.microsoft.com/en-us/azure/architecture/guide/)
- [Azure Pricing](https://azure.microsoft.com/en-us/pricing/)
- [Azure Always Free Tier](https://azure.microsoft.com/en-us/free/)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
