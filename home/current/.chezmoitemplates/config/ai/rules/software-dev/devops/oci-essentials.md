# OCI (Oracle Cloud Infrastructure) Best Practices

**Document Version**: 1.0  
**Last Updated**: 2025-11-22  
**Scope**: Cloud provider abstraction library support for Oracle Cloud Infrastructure

## Overview

Oracle Cloud Infrastructure (OCI) is a comprehensive cloud platform offering compute, storage, database, and networking services. This document outlines best practices for cost optimization, security, reliability, and performance when using OCI within the cloud provider abstraction library.

---

## 1. Storage Services

### Object Storage (OCI Equivalent of S3)

#### Prototyping Configuration (Minimize Cost)

- **Storage Class**: Standard storage (no tiering needed for short-term data)
- **Replication**: Single-region (no cross-region replication)
- **Versioning**: Disabled (cost savings)
- **Encryption**: Oracle-managed encryption (no customer-managed keys)
- **Lifecycle Policies**: Auto-delete after 30 days (prevents accidental long-term costs)
- **Access Logging**: Disabled ($0.50/GB equivalent cost)
- **Multipart Upload**: Default settings (auto-cleanup after 7 days)
- **Cost Estimate**: ~$2-5/month for typical prototyping workloads

**Disabled Features** (Cost Optimization):
- Object versioning (saves storage)
- Access logging (saves ingestion costs)
- Replication (saves data transfer)
- Retention rules (unnecessary for ephemeral data)

#### Testing Configuration (Full Observability)

- **Storage Class**: Standard storage
- **Replication**: None (single-region)
- **Versioning**: Enabled (for test data recovery)
- **Encryption**: Oracle-managed encryption
- **Lifecycle Policies**: Indefinite retention (testing data needs persistence)
- **Access Logging**: Enabled (logs to Object Storage bucket)
- **Monitoring**: Enabled (CloudWatch equivalent: OCI Monitoring)
- **Cost Estimate**: ~$50-100/month

#### Production Configuration (Reliability & Compliance)

- **Storage Class**: Standard storage
- **Replication**: Cross-region replication (to secondary region)
- **Versioning**: Enabled (required for compliance)
- **Encryption**: Customer-managed encryption (OCI KMS)
- **Lifecycle Policies**: Transition to Archive Storage after 90 days (cost optimization)
- **Access Logging**: Enabled (required for compliance audits)
- **Monitoring**: Enabled with alarms
- **Retention Rules**: Enabled (compliance requirement)
- **Cost Estimate**: $500+/month

#### Cost Optimization Strategies

| Strategy | Savings | Trade-off |
|----------|---------|-----------|
| Single-region vs. cross-region | ~50% | No disaster recovery |
| Standard vs. Archive storage | ~80% after 90 days | Retrieval delays (4 hours) |
| Disable versioning | ~30% | No rollback capability |
| Disable access logging | ~$0.50/GB | No access audit trail |
| 30-day auto-delete | ~100% after 30 days | Data loss risk |

---

## 2. Database Services

### Autonomous Database (OCI Equivalent of RDS)

#### Prototyping Configuration

- **Deployment**: Single-node (no redundancy)
- **Backup Retention**: 1 day (minimal)
- **Encryption**: Oracle-managed encryption
- **Monitoring**: Disabled (cost savings)
- **Automatic Scaling**: Disabled (fixed OCPU count)
- **Data Guard**: Disabled (no replication)
- **Cost Estimate**: ~$10-20/month

**Key Features**:
- Autonomous Database is fully managed (no patching required)
- Always encrypted (cannot be disabled)
- Automatic backups (cannot be disabled, but retention is configurable)

#### Testing Configuration

- **Deployment**: Single-node
- **Backup Retention**: 7 days
- **Encryption**: Oracle-managed encryption
- **Monitoring**: Enabled (OCI Monitoring)
- **Automatic Scaling**: Enabled (for variable workloads)
- **Data Guard**: Optional (for HA testing)
- **Cost Estimate**: ~$50-100/month

#### Production Configuration

- **Deployment**: Multi-node with Data Guard (automatic failover)
- **Backup Retention**: 35 days
- **Encryption**: Customer-managed encryption (OCI KMS)
- **Monitoring**: Enabled with alarms
- **Automatic Scaling**: Enabled
- **Data Guard**: Enabled (standby in different region)
- **Audit Logging**: Enabled (required for compliance)
- **Cost Estimate**: $500+/month

#### Autonomous Database Advantages

- **Zero-downtime patching**: Oracle handles all updates automatically
- **Automatic backups**: No manual intervention required
- **Always encrypted**: Data encryption is mandatory
- **Workload optimization**: Separate ATP (transaction processing) and ADW (data warehouse) options

---

## 3. Networking Services

### Virtual Cloud Network (VCN) - OCI Equivalent of VPC

#### Prototyping Configuration

- **VCN Flow Logs**: Disabled (cost savings: ~$0.50/GB)
- **NAT Gateway**: None (use service gateway for Object Storage)
- **Load Balancer**: None (cost savings)
- **Security Lists**: Default deny-all ingress, allow-all egress
- **Network Segmentation**: Single subnet
- **Cost Estimate**: ~$0/month (VCN itself is free)

**Cost Optimization**:
- Use service gateway for free Object Storage access (no data transfer charges)
- Avoid NAT Gateway ($0.045/GB equivalent in OCI)
- Use security lists instead of network security groups (both free)

#### Testing Configuration

- **VCN Flow Logs**: Enabled (logs to Object Storage)
- **NAT Gateway**: 1 per availability domain (for private subnet internet access)
- **Load Balancer**: Optional (for testing HA)
- **Security Lists**: Explicit allow rules (deny-by-default)
- **Network Segmentation**: Public + private subnets
- **Monitoring**: Enabled (OCI Monitoring)
- **Cost Estimate**: ~$32/month (NAT Gateway)

#### Production Configuration

- **VCN Flow Logs**: Enabled (logs to Object Storage + OCI Logging)
- **NAT Gateway**: Multi-AZ NAT Gateways (HA)
- **Load Balancer**: Enabled (Network Load Balancer for HA)
- **Security Lists**: Explicit allow rules with DDoS protection
- **Network Segmentation**: Multi-tier (public, private, database)
- **VPN/FastConnect**: Enabled (for secure on-premises connectivity)
- **DDoS Protection**: Enabled (OCI DDoS Protection Service)
- **Cost Estimate**: $100+/month

---

## 4. Compute Services

### Compute Instances (OCI Equivalent of EC2)

#### Prototyping Configuration (Minimize Cost)

- **Instance Type**: Flexible shape with minimal OCPUs (0.1-1 OCPU)
- **Pricing Model**: Always Free tier (if eligible) or Spot instances (70%+ savings)
- **Image**: Oracle Linux (free, optimized for OCI)
- **Monitoring**: Disabled (cost savings)
- **Auto-scaling**: Disabled
- **Cost Estimate**: ~$5-10/month (or free with Always Free tier)

**Spot Instances**:
- 70%+ cost savings vs. on-demand
- 2-minute interruption notice
- Suitable for fault-tolerant workloads (batch processing, testing)

#### Testing Configuration

- **Instance Type**: Standard flexible shape (2-4 OCPUs)
- **Pricing Model**: On-demand
- **Image**: Oracle Linux or Ubuntu
- **Monitoring**: Enabled (OCI Monitoring)
- **Auto-scaling**: Enabled (for variable workloads)
- **Cost Estimate**: ~$50-100/month

#### Production Configuration

- **Instance Type**: Dense compute shape (high OCPU count)
- **Pricing Model**: On-demand (for reliability)
- **Image**: Oracle Linux (optimized, free)
- **Monitoring**: Enabled with alarms
- **Auto-scaling**: Enabled (for HA)
- **Placement Groups**: Enabled (for low-latency clusters)
- **Cost Estimate**: $500+/month

#### OCI Compute Advantages

- **Always Free tier**: Eligible accounts get free compute, storage, and database
- **Flexible shapes**: Pay only for OCPUs used (not full instance size)
- **Spot instances**: Significant savings for fault-tolerant workloads
- **Oracle Linux**: Free, optimized for OCI, includes free patches

---

## 5. Security Best Practices

### Identity & Access Management (IAM)

#### Prototyping

- **Compartments**: Single compartment (no isolation needed)
- **Policies**: Broad permissions (for development speed)
- **MFA**: Optional
- **Audit Logging**: Disabled

#### Testing

- **Compartments**: Separate compartment for testing
- **Policies**: Role-based access control (RBAC)
- **MFA**: Enabled for human users
- **Audit Logging**: Enabled (OCI Audit)

#### Production

- **Compartments**: Separate compartments per environment/team
- **Policies**: Least-privilege access
- **MFA**: Required for all users
- **Audit Logging**: Enabled with long retention (90+ days)
- **Federation**: SAML 2.0 integration with corporate identity provider

### Encryption

#### Data at Rest

- **Prototyping**: Oracle-managed encryption (default, free)
- **Testing**: Oracle-managed encryption
- **Production**: Customer-managed encryption (OCI KMS) for compliance

#### Data in Transit

- **All Environments**: TLS 1.2+ (enforced by OCI)
- **Production**: Mutual TLS (mTLS) for service-to-service communication

### Network Security

- **Security Lists**: Explicit allow rules (deny-by-default)
- **Network Security Groups**: Additional layer of security (optional)
- **DDoS Protection**: Enabled in production
- **WAF**: Enabled for public-facing applications

---

## 6. Compliance & Governance

### Audit & Logging

| Component | Prototyping | Testing | Production |
|-----------|-------------|---------|------------|
| **Audit Logs** | Disabled | Enabled | Enabled (90-day retention) |
| **VCN Flow Logs** | Disabled | Enabled | Enabled |
| **Database Audit** | Disabled | Optional | Enabled |
| **Object Storage Logs** | Disabled | Enabled | Enabled |

### Compliance Standards

#### SOC2 Compliance

- Enable audit logging (OCI Audit)
- Enable database audit logging
- Enable VCN Flow Logs
- Implement encryption at rest (KMS)
- Implement encryption in transit (TLS)
- Restrict public access (security lists)
- Enable MFA for all users

#### PCI-DSS Compliance

- Encryption at rest (KMS)
- Encryption in transit (TLS 1.2+)
- Network segmentation (VCN subnets)
- Access logging (all components)
- Audit logging (90-day retention)
- Vulnerability scanning (OCI Vulnerability Scanning Service)
- Intrusion detection (OCI Network Firewall)

#### HIPAA Compliance

- Encryption at rest (customer-managed KMS)
- Encryption in transit (mTLS)
- Audit logging (immutable, 6-year retention)
- Access controls (RBAC, MFA)
- Data residency (specific OCI regions)
- Business Associate Agreement (BAA) with Oracle

---

## 7. Cost Optimization Strategies

### Storage Cost Optimization

1. **Use Archive Storage** for data older than 90 days (80% savings)
2. **Enable lifecycle policies** to auto-transition to Archive
3. **Disable versioning** for non-critical data (30% savings)
4. **Use service gateway** for Object Storage access (free data transfer)
5. **Compress data** before storage (reduces storage and transfer costs)

### Compute Cost Optimization

1. **Use Spot instances** for fault-tolerant workloads (70%+ savings)
2. **Use Always Free tier** for eligible accounts (free compute, storage, database)
3. **Right-size instances** (use flexible shapes, pay only for OCPUs used)
4. **Use auto-scaling** to match demand
5. **Schedule instances** to stop during off-hours (for non-24/7 workloads)

### Database Cost Optimization

1. **Use Autonomous Database** (fully managed, automatic patching)
2. **Reduce backup retention** for non-critical data (1-7 days for prototyping)
3. **Disable Data Guard** for non-critical databases (replication costs)
4. **Use Oracle-managed encryption** instead of customer-managed KMS
5. **Right-size OCPU count** (use flexible shapes)

### Network Cost Optimization

1. **Use service gateway** for Object Storage (free data transfer)
2. **Avoid NAT Gateway** when possible (use service gateway instead)
3. **Consolidate NAT Gateways** (1 per VCN, not per subnet)
4. **Use VCN peering** instead of NAT for inter-VCN communication
5. **Avoid cross-region data transfer** (expensive: $0.02/GB)

---

## 8. OCI vs. AWS Comparison

| Feature | OCI | AWS | Notes |
|---------|-----|-----|-------|
| **Object Storage** | Object Storage | S3 | OCI: single storage class; AWS: multiple tiers |
| **Database** | Autonomous DB | RDS | OCI: fully managed, auto-patching; AWS: more control |
| **Compute** | Compute Instances | EC2 | OCI: flexible shapes; AWS: fixed instance types |
| **Networking** | VCN | VPC | Similar functionality, different terminology |
| **Encryption** | OCI KMS | AWS KMS | Both support customer-managed keys |
| **Logging** | OCI Audit | CloudTrail | Similar functionality |
| **Cost** | Generally cheaper | Higher | OCI: 3-year commitment discounts available |

### OCI Advantages

1. **Always Free tier**: Generous free tier (compute, storage, database)
2. **Autonomous Database**: Fully managed, zero-downtime patching
3. **Flexible shapes**: Pay only for OCPUs used
4. **3-year commitments**: Significant discounts (up to 50% off)
5. **Consistent pricing**: No regional price variations (unlike AWS)

### AWS Advantages

1. **Larger ecosystem**: More third-party integrations
2. **More service options**: Broader service portfolio
3. **Mature marketplace**: Larger community and documentation
4. **Reserved instances**: More flexible pricing options

---

## 9. Migration Path from AWS to OCI

### Service Mapping

| AWS Service | OCI Equivalent | Migration Effort |
|-------------|----------------|-----------------|
| S3 | Object Storage | Low (similar APIs) |
| RDS | Autonomous Database | Medium (schema migration) |
| EC2 | Compute Instances | Medium (image conversion) |
| VPC | VCN | Low (similar concepts) |
| CloudTrail | OCI Audit | Low (similar functionality) |
| KMS | OCI KMS | Low (key migration) |
| CloudFront | OCI CDN | Medium (configuration migration) |
| Lambda | OCI Functions | High (code rewrite) |

### Migration Best Practices

1. **Use Database Migration Service** (OCI DMS) for database migrations
2. **Use VM Import** for EC2 instance migration
3. **Test in OCI first** (use Always Free tier for prototyping)
4. **Plan for data transfer costs** (cross-region transfer is expensive)
5. **Validate compliance** (ensure OCI regions meet data residency requirements)

---

## 10. Monitoring & Observability

### OCI Monitoring

- **Metrics**: CPU, memory, disk, network (free tier: 5-minute granularity)
- **Alarms**: Threshold-based alerts (free tier: limited)
- **Dashboards**: Custom dashboards (free tier: limited)
- **Logs**: Centralized logging (OCI Logging service)

### Recommended Monitoring Setup

#### Prototyping

- Minimal monitoring (cost savings)
- Basic alarms for critical failures

#### Testing

- Full monitoring (OCI Monitoring)
- Alarms for performance degradation
- Log aggregation (OCI Logging)

#### Production

- Comprehensive monitoring (OCI Monitoring)
- Alarms for all critical metrics
- Log aggregation with long retention (90+ days)
- Distributed tracing (OCI Application Performance Monitoring)

---

## 11. Disaster Recovery & High Availability

### RTO/RPO Targets

| Environment | RTO | RPO | Strategy |
|-------------|-----|-----|----------|
| **Prototyping** | 24 hours | 24 hours | Manual recovery, daily backups |
| **Testing** | 4 hours | 1 hour | Automated backups, cross-region replication |
| **Production** | 1 hour | 15 minutes | Data Guard, cross-region failover |

### High Availability Architecture

#### Prototyping

- Single-region, single-AZ deployment
- Daily backups (1-day retention)
- Manual recovery process

#### Testing

- Single-region, multi-AZ deployment
- Automated backups (7-day retention)
- Load balancer for HA
- Auto-scaling enabled

#### Production

- Multi-region deployment
- Data Guard for database HA
- Cross-region replication for storage
- Network Load Balancer for compute HA
- Automated failover (RTO < 1 hour)

---

## 12. OCI-Specific Features

### Always Free Tier

OCI offers a generous Always Free tier (not time-limited):

- **Compute**: 2 AMD-based Compute instances (1 OCPU, 1 GB RAM each)
- **Storage**: 20 GB Object Storage, 100 GB Archive Storage
- **Database**: 1 Autonomous Database (1 OCPU, 20 GB storage)
- **Networking**: 10 Mbps bandwidth

**Prototyping Benefit**: Entire prototyping infrastructure can run free on Always Free tier.

### Flexible Shapes

OCI's flexible shapes allow you to customize:

- **OCPUs**: Pay only for OCPUs used (0.1 to 128 OCPUs)
- **Memory**: 1 GB per OCPU (configurable)
- **Network**: Bandwidth scales with OCPU count

**Cost Benefit**: Right-size instances precisely, no overpaying for unused resources.

### 3-Year Commitment Discounts

OCI offers significant discounts for 3-year commitments:

- **Compute**: Up to 50% discount
- **Storage**: Up to 30% discount
- **Database**: Up to 40% discount

**Production Benefit**: Long-term cost savings for stable workloads.

---

## 13. Recommended Configuration Templates

### Prototyping Stack (Minimal Cost)

```yaml
Environment: prototyping
Attributes:
  - minimize-cost
  - use-always-free-tier

Components:
  Storage: Object Storage (Standard, single-region, 30-day auto-delete)
  Database: Autonomous Database (1 OCPU, Oracle-managed encryption)
  Compute: Compute Instances (Spot, 0.1 OCPU, Oracle Linux)
  Networking: VCN with service gateway (free Object Storage access)

Estimated Cost: $0-5/month (or free with Always Free tier)
```

### Testing Stack (Full Observability)

```yaml
Environment: testing
Attributes:
  - maximize-observability
  - maximize-reliability

Components:
  Storage: Object Storage (Standard, single-region, versioning enabled)
  Database: Autonomous Database (2 OCPUs, Oracle-managed encryption)
  Compute: Compute Instances (On-demand, 2 OCPUs, auto-scaling enabled)
  Networking: VCN with NAT Gateway, load balancer, monitoring enabled

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
  Storage: Object Storage (Standard + Archive, cross-region replication)
  Database: Autonomous Database (4+ OCPUs, Data Guard, customer-managed encryption)
  Compute: Compute Instances (On-demand, 4+ OCPUs, multi-AZ, auto-scaling)
  Networking: VCN with multi-AZ NAT, load balancer, DDoS protection, monitoring

Estimated Cost: $500+/month
```

---

## References

- [OCI Documentation](https://docs.oracle.com/en-us/iaas/)
- [OCI Best Practices](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/best_practices.htm)
- [OCI Pricing](https://www.oracle.com/cloud/price-list/)
- [OCI Always Free Tier](https://www.oracle.com/cloud/free/)
- [OCI Architecture Center](https://www.oracle.com/cloud/architecture-center/)
