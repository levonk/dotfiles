# GCP (Google Cloud Platform) Best Practices

**Document Version**: 1.0  
**Last Updated**: 2025-11-22  
**Scope**: Cloud provider abstraction library support for Google Cloud Platform

## Overview

Google Cloud Platform (GCP) is a comprehensive cloud platform offering compute, storage, database, and networking services. This document outlines best practices for cost optimization, security, reliability, and performance when using GCP within the cloud provider abstraction library.

---

## 1. Storage Services

### Cloud Storage (GCP Equivalent of S3)

#### Prototyping Configuration (Minimize Cost)

- **Storage Class**: Standard (no tiering for short-term data)
- **Location**: Single-region (us-central1 or closest region)
- **Replication**: None (single-region)
- **Versioning**: Disabled (cost savings)
- **Encryption**: Google-managed encryption (default, free)
- **Lifecycle Policies**: Auto-delete after 30 days (prevents accidental long-term costs)
- **Access Logging**: Disabled ($0.50/GB equivalent cost)
- **Cost Estimate**: ~$2-5/month for typical prototyping workloads

**Disabled Features** (Cost Optimization):
- Object versioning (saves storage)
- Access logging (saves ingestion costs)
- Cross-region replication (saves data transfer)
- Retention policies (unnecessary for ephemeral data)

#### Testing Configuration (Full Observability)

- **Storage Class**: Standard
- **Location**: Multi-region (US) for redundancy
- **Replication**: None (multi-region provides redundancy)
- **Versioning**: Enabled (for test data recovery)
- **Encryption**: Google-managed encryption
- **Lifecycle Policies**: Indefinite retention (testing data needs persistence)
- **Access Logging**: Enabled (logs to Cloud Logging)
- **Monitoring**: Enabled (Cloud Monitoring)
- **Cost Estimate**: ~$50-100/month

#### Production Configuration (Reliability & Compliance)

- **Storage Class**: Standard + Nearline (transition after 30 days)
- **Location**: Multi-region (US or EU)
- **Replication**: Dual-region replication (automatic failover)
- **Versioning**: Enabled (required for compliance)
- **Encryption**: Customer-managed encryption (Cloud KMS)
- **Lifecycle Policies**: Transition to Archive after 90 days (cost optimization)
- **Access Logging**: Enabled (required for compliance audits)
- **Monitoring**: Enabled with alarms
- **Retention Rules**: Enabled (compliance requirement)
- **Cost Estimate**: $500+/month

#### Cost Optimization Strategies

| Strategy | Savings | Trade-off |
|----------|---------|-----------|
| Standard vs. Nearline | ~50% after 30 days | 30-day minimum storage duration |
| Standard vs. Coldline | ~80% after 90 days | 90-day minimum, retrieval fees |
| Single-region vs. multi-region | ~50% | No geographic redundancy |
| Disable versioning | ~30% | No rollback capability |
| Disable access logging | ~$0.50/GB | No access audit trail |

---

## 2. Database Services

### Cloud SQL (GCP Equivalent of RDS)

#### Prototyping Configuration

- **Deployment**: Single-zone (no redundancy)
- **Machine Type**: db-f1-micro (smallest, free tier eligible)
- **Backup Retention**: 7 days (minimal)
- **Encryption**: Google-managed encryption
- **Monitoring**: Disabled (cost savings)
- **Automated Backups**: Enabled (required, cannot be disabled)
- **High Availability**: Disabled
- **Cost Estimate**: ~$10-20/month (or free with Always Free tier)

**Key Features**:
- Cloud SQL is fully managed (automatic patching)
- Automated backups are mandatory
- Free tier includes 1 db-f1-micro instance with 10 GB storage

#### Testing Configuration

- **Deployment**: Single-zone
- **Machine Type**: db-n1-standard-1 (1 vCPU, 3.75 GB RAM)
- **Backup Retention**: 7 days
- **Encryption**: Google-managed encryption
- **Monitoring**: Enabled (Cloud Monitoring)
- **Automated Backups**: Enabled
- **High Availability**: Optional (for HA testing)
- **Cost Estimate**: ~$50-100/month

#### Production Configuration

- **Deployment**: High Availability (multi-zone with automatic failover)
- **Machine Type**: db-n1-standard-2 or larger (2+ vCPUs)
- **Backup Retention**: 35 days
- **Encryption**: Customer-managed encryption (Cloud KMS)
- **Monitoring**: Enabled with alarms
- **Automated Backups**: Enabled
- **High Availability**: Enabled (standby replica in different zone)
- **Read Replicas**: Enabled (for read scaling)
- **Audit Logging**: Enabled (required for compliance)
- **Cost Estimate**: $500+/month

#### Cloud SQL Advantages

- **Fully managed**: Automatic patching, backups, and maintenance
- **High Availability**: Automatic failover to standby replica
- **Read replicas**: Scale read traffic across regions
- **Free tier**: db-f1-micro instance with 10 GB storage

---

## 3. Firestore & Datastore

### Cloud Firestore (NoSQL Database)

#### Prototyping Configuration

- **Mode**: Datastore mode (simpler, lower cost)
- **Replication**: Single-region
- **Backup**: Automatic (daily)
- **Encryption**: Google-managed encryption
- **Monitoring**: Disabled
- **Cost Estimate**: ~$5-10/month (or free with Always Free tier)

**Always Free Tier**:
- 1 GB storage
- 50,000 reads/day
- 20,000 writes/day
- 20,000 deletes/day

#### Testing Configuration

- **Mode**: Native mode (more features, higher cost)
- **Replication**: Multi-region
- **Backup**: Automatic (daily)
- **Encryption**: Google-managed encryption
- **Monitoring**: Enabled
- **Cost Estimate**: ~$50-100/month

#### Production Configuration

- **Mode**: Native mode
- **Replication**: Multi-region with automatic failover
- **Backup**: Automatic (daily) + manual backups
- **Encryption**: Customer-managed encryption (Cloud KMS)
- **Monitoring**: Enabled with alarms
- **Point-in-time recovery**: Enabled
- **Cost Estimate**: $500+/month

---

## 4. Networking Services

### Virtual Private Cloud (VPC)

#### Prototyping Configuration

- **VPC Flow Logs**: Disabled (cost savings: ~$0.50/GB)
- **Cloud NAT**: None (use Private Google Access for GCP services)
- **Load Balancer**: None (cost savings)
- **Firewall Rules**: Default deny-all ingress, allow-all egress
- **Network Segmentation**: Single subnet
- **Cost Estimate**: ~$0/month (VPC itself is free)

**Cost Optimization**:
- Use Private Google Access for free access to GCP services (no NAT Gateway needed)
- Avoid Cloud NAT ($0.045/GB equivalent in GCP)
- Use firewall rules instead of Cloud Armor (both free)

#### Testing Configuration

- **VPC Flow Logs**: Enabled (logs to Cloud Logging)
- **Cloud NAT**: 1 per region (for private subnet internet access)
- **Load Balancer**: Optional (for testing HA)
- **Firewall Rules**: Explicit allow rules (deny-by-default)
- **Network Segmentation**: Public + private subnets
- **Monitoring**: Enabled (Cloud Monitoring)
- **Cost Estimate**: ~$32/month (Cloud NAT)

#### Production Configuration

- **VPC Flow Logs**: Enabled (logs to Cloud Logging + Cloud Storage)
- **Cloud NAT**: Multi-zone NAT Gateways (HA)
- **Load Balancer**: Enabled (Global HTTP(S) Load Balancer or Network Load Balancer)
- **Firewall Rules**: Explicit allow rules with Cloud Armor
- **Network Segmentation**: Multi-tier (public, private, database)
- **VPN/Interconnect**: Enabled (for secure on-premises connectivity)
- **Cloud Armor**: Enabled (DDoS protection)
- **Cost Estimate**: $100+/month

---

## 5. Compute Services

### Compute Engine (GCP Equivalent of EC2)

#### Prototyping Configuration (Minimize Cost)

- **Machine Type**: e2-micro (0.25-2 vCPUs, 1 GB RAM)
- **Pricing Model**: Preemptible instances (70%+ savings)
- **Image**: Container-Optimized OS (free, optimized for GCP)
- **Monitoring**: Disabled (cost savings)
- **Auto-scaling**: Disabled
- **Cost Estimate**: ~$5-10/month (or free with Always Free tier)

**Preemptible Instances**:
- 70%+ cost savings vs. on-demand
- 30-second interruption notice
- Suitable for fault-tolerant workloads (batch processing, testing)
- Maximum 24-hour runtime

**Always Free Tier**:
- 1 e2-micro instance per month (744 hours)
- 30 GB HDD storage
- 1 GB egress per month

#### Testing Configuration

- **Machine Type**: e2-standard-2 (2 vCPUs, 8 GB RAM)
- **Pricing Model**: On-demand
- **Image**: Container-Optimized OS or Ubuntu
- **Monitoring**: Enabled (Cloud Monitoring)
- **Auto-scaling**: Enabled (for variable workloads)
- **Cost Estimate**: ~$50-100/month

#### Production Configuration

- **Machine Type**: n2-standard-4 or larger (4+ vCPUs)
- **Pricing Model**: On-demand (for reliability)
- **Image**: Container-Optimized OS (optimized, free)
- **Monitoring**: Enabled with alarms
- **Auto-scaling**: Enabled (for HA)
- **Instance Groups**: Enabled (for load balancing)
- **Cost Estimate**: $500+/month

#### GCP Compute Advantages

- **Always Free tier**: e2-micro instance, 30 GB storage, 1 GB egress
- **Preemptible instances**: 70%+ savings for fault-tolerant workloads
- **Committed use discounts**: Up to 37% discount for 1-year, 55% for 3-year commitments
- **Container-Optimized OS**: Free, optimized for containers

---

## 6. Security Best Practices

### Identity & Access Management (IAM)

#### Prototyping

- **Projects**: Single project (no isolation needed)
- **Service Accounts**: Default service account
- **Roles**: Basic roles (Editor, Viewer)
- **MFA**: Optional
- **Audit Logging**: Disabled

#### Testing

- **Projects**: Separate project for testing
- **Service Accounts**: Custom service accounts per component
- **Roles**: Predefined roles (Compute Admin, Storage Admin, etc.)
- **MFA**: Enabled for human users
- **Audit Logging**: Enabled (Cloud Audit Logs)

#### Production

- **Projects**: Separate projects per environment/team
- **Service Accounts**: Custom service accounts with minimal permissions
- **Roles**: Custom roles with least-privilege access
- **MFA**: Required for all users
- **Audit Logging**: Enabled with long retention (90+ days)
- **Workload Identity**: Enabled (for Kubernetes workloads)

### Encryption

#### Data at Rest

- **Prototyping**: Google-managed encryption (default, free)
- **Testing**: Google-managed encryption
- **Production**: Customer-managed encryption (Cloud KMS) for compliance

#### Data in Transit

- **All Environments**: TLS 1.2+ (enforced by GCP)
- **Production**: Mutual TLS (mTLS) for service-to-service communication

### Network Security

- **Firewall Rules**: Explicit allow rules (deny-by-default)
- **Cloud Armor**: DDoS protection (enabled in production)
- **VPC Service Controls**: Additional layer of security (optional)
- **Cloud DLP**: Data loss prevention (optional)

---

## 7. Compliance & Governance

### Audit & Logging

| Component | Prototyping | Testing | Production |
|-----------|-------------|---------|------------|
| **Cloud Audit Logs** | Disabled | Enabled | Enabled (90-day retention) |
| **VPC Flow Logs** | Disabled | Enabled | Enabled |
| **Cloud Logging** | Disabled | Enabled | Enabled |
| **Cloud Trace** | Disabled | Optional | Enabled |

### Compliance Standards

#### SOC2 Compliance

- Enable Cloud Audit Logs
- Enable VPC Flow Logs
- Implement encryption at rest (KMS)
- Implement encryption in transit (TLS)
- Restrict public access (firewall rules)
- Enable MFA for all users

#### PCI-DSS Compliance

- Encryption at rest (Cloud KMS)
- Encryption in transit (TLS 1.2+)
- Network segmentation (VPC subnets)
- Access logging (all components)
- Audit logging (90-day retention)
- Vulnerability scanning (Container Analysis)
- DDoS protection (Cloud Armor)

#### HIPAA Compliance

- Encryption at rest (customer-managed Cloud KMS)
- Encryption in transit (mTLS)
- Audit logging (immutable, 6-year retention)
- Access controls (RBAC, MFA)
- Data residency (specific GCP regions)
- Business Associate Agreement (BAA) with Google

---

## 8. Cost Optimization Strategies

### Storage Cost Optimization

1. **Use Nearline/Coldline** for data older than 30/90 days (50-80% savings)
2. **Enable lifecycle policies** to auto-transition storage classes
3. **Disable versioning** for non-critical data (30% savings)
4. **Use Private Google Access** for free GCP service access (no NAT Gateway)
5. **Compress data** before storage (reduces storage and transfer costs)

### Compute Cost Optimization

1. **Use Preemptible instances** for fault-tolerant workloads (70%+ savings)
2. **Use Always Free tier** for eligible accounts (free compute, storage, database)
3. **Use Committed Use Discounts** (37% for 1-year, 55% for 3-year)
4. **Use auto-scaling** to match demand
5. **Schedule instances** to stop during off-hours (for non-24/7 workloads)

### Database Cost Optimization

1. **Use Cloud SQL** (fully managed, automatic patching)
2. **Reduce backup retention** for non-critical data (7 days for prototyping)
3. **Disable High Availability** for non-critical databases (replication costs)
4. **Use Google-managed encryption** instead of customer-managed KMS
5. **Right-size machine types** (use smaller instances for prototyping)

### Network Cost Optimization

1. **Use Private Google Access** for free GCP service access (no NAT Gateway)
2. **Avoid Cloud NAT** when possible (use Private Google Access instead)
3. **Consolidate Cloud NAT** (1 per VPC, not per subnet)
4. **Use VPC Peering** instead of Cloud NAT for inter-VPC communication
5. **Avoid cross-region data transfer** (expensive: $0.02/GB)

---

## 9. GCP vs. AWS Comparison

| Feature | GCP | AWS | Notes |
|---------|-----|-----|-------|
| **Object Storage** | Cloud Storage | S3 | GCP: simpler pricing; AWS: more storage classes |
| **Database** | Cloud SQL | RDS | GCP: fully managed; AWS: more control |
| **Compute** | Compute Engine | EC2 | GCP: preemptible; AWS: spot instances |
| **Networking** | VPC | VPC | Similar functionality, different terminology |
| **Encryption** | Cloud KMS | AWS KMS | Both support customer-managed keys |
| **Logging** | Cloud Audit Logs | CloudTrail | Similar functionality |
| **Cost** | Generally cheaper | Higher | GCP: committed use discounts available |

### GCP Advantages

1. **Always Free tier**: Generous free tier (compute, storage, database)
2. **Preemptible instances**: 70%+ savings for fault-tolerant workloads
3. **Committed Use Discounts**: Up to 55% discount for 3-year commitments
4. **Simpler pricing**: No regional price variations (unlike AWS)
5. **Kubernetes**: GKE is fully managed and optimized

### AWS Advantages

1. **Larger ecosystem**: More third-party integrations
2. **More service options**: Broader service portfolio
3. **Mature marketplace**: Larger community and documentation
4. **Reserved instances**: More flexible pricing options

---

## 10. Migration Path from AWS to GCP

### Service Mapping

| AWS Service | GCP Equivalent | Migration Effort |
|-------------|----------------|-----------------|
| S3 | Cloud Storage | Low (similar APIs) |
| RDS | Cloud SQL | Medium (schema migration) |
| EC2 | Compute Engine | Medium (image conversion) |
| VPC | VPC | Low (similar concepts) |
| CloudTrail | Cloud Audit Logs | Low (similar functionality) |
| KMS | Cloud KMS | Low (key migration) |
| CloudFront | Cloud CDN | Medium (configuration migration) |
| Lambda | Cloud Functions | High (code rewrite) |

### Migration Best Practices

1. **Use Database Migration Service** (GCP DMS) for database migrations
2. **Use VM Import** for EC2 instance migration
3. **Test in GCP first** (use Always Free tier for prototyping)
4. **Plan for data transfer costs** (cross-region transfer is expensive)
5. **Validate compliance** (ensure GCP regions meet data residency requirements)

---

## 11. Monitoring & Observability

### Cloud Monitoring & Logging

- **Metrics**: CPU, memory, disk, network (free tier: 5-minute granularity)
- **Alarms**: Threshold-based alerts (free tier: limited)
- **Dashboards**: Custom dashboards (free tier: limited)
- **Logs**: Centralized logging (Cloud Logging service)

### Recommended Monitoring Setup

#### Prototyping

- Minimal monitoring (cost savings)
- Basic alarms for critical failures

#### Testing

- Full monitoring (Cloud Monitoring)
- Alarms for performance degradation
- Log aggregation (Cloud Logging)

#### Production

- Comprehensive monitoring (Cloud Monitoring)
- Alarms for all critical metrics
- Log aggregation with long retention (90+ days)
- Distributed tracing (Cloud Trace)

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

- Single-region, multi-zone deployment
- Automated backups (7-day retention)
- Load balancer for HA
- Auto-scaling enabled

#### Production

- Multi-region deployment
- Cloud SQL High Availability (standby replica)
- Cross-region replication for storage
- Global Load Balancer for compute HA
- Automated failover (RTO < 1 hour)

---

## 13. GCP-Specific Features

### Always Free Tier

GCP offers a generous Always Free tier (not time-limited):

- **Compute**: 1 e2-micro instance per month (744 hours)
- **Storage**: 5 GB Cloud Storage, 1 GB Cloud SQL
- **Database**: 1 GB Firestore storage, 50K reads/day
- **Networking**: 1 GB egress per month

**Prototyping Benefit**: Entire prototyping infrastructure can run free on Always Free tier.

### Preemptible Instances

GCP's preemptible instances offer:

- **Cost Savings**: 70%+ discount vs. on-demand
- **Interruption Notice**: 30-second notice before termination
- **Maximum Runtime**: 24 hours
- **Use Cases**: Batch processing, testing, fault-tolerant workloads

**Cost Benefit**: Significant savings for non-critical workloads.

### Committed Use Discounts

GCP offers discounts for multi-year commitments:

- **1-Year Commitment**: Up to 37% discount
- **3-Year Commitment**: Up to 55% discount
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
  Storage: Cloud Storage (Standard, single-region, 30-day auto-delete)
  Database: Cloud SQL (db-f1-micro, Google-managed encryption)
  Compute: Compute Engine (e2-micro Preemptible, Container-Optimized OS)
  Networking: VPC with Private Google Access (free GCP service access)

Estimated Cost: $0-5/month (or free with Always Free tier)
```

### Testing Stack (Full Observability)

```yaml
Environment: testing
Attributes:
  - maximize-observability
  - maximize-reliability

Components:
  Storage: Cloud Storage (Standard, multi-region, versioning enabled)
  Database: Cloud SQL (db-n1-standard-1, Google-managed encryption)
  Compute: Compute Engine (e2-standard-2 On-demand, auto-scaling enabled)
  Networking: VPC with Cloud NAT, load balancer, monitoring enabled

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
  Storage: Cloud Storage (Standard + Nearline, multi-region replication)
  Database: Cloud SQL (db-n1-standard-2+, High Availability, customer-managed encryption)
  Compute: Compute Engine (n2-standard-4+, multi-zone, auto-scaling)
  Networking: VPC with multi-zone Cloud NAT, Global Load Balancer, Cloud Armor

Estimated Cost: $500+/month
```

---

## References

- [GCP Documentation](https://cloud.google.com/docs)
- [GCP Best Practices](https://cloud.google.com/architecture/best-practices)
- [GCP Pricing](https://cloud.google.com/pricing)
- [GCP Always Free Tier](https://cloud.google.com/free)
- [GCP Architecture Center](https://cloud.google.com/architecture)
