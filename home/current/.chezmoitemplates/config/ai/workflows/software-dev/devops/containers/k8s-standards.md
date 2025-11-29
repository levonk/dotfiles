# Kubernetes Standards

## Network Policies

- **Default Deny**: All namespaces MUST have a default-deny NetworkPolicy for both ingress and egress traffic.
- **L7 Policies**: Use **Cilium** Network Policies for Layer 7 (HTTP, API, gRPC) enforcement.
  - Define specific paths and methods allowed between services.
  - Restrict egress to external APIs by FQDN (e.g., `toFQDNs`).
- **Encryption**: Enable Cilium Transparent Encryption (WireGuard/IPsec) for all inter-node traffic.

## Resource Management

- **Quotas**: Every namespace MUST have a `ResourceQuota` object.
- **Limits**: Every pod container MUST define `requests` and `limits` for CPU and Memory.

## Security

- **Pod Security**: Enforce the `restricted` Pod Security Standard at the namespace level.
  - `runAsNonRoot: true`
  - `allowPrivilegeEscalation: false`
  - `readOnlyRootFilesystem: true`
- **Probes**: Liveness and Readiness probes are REQUIRED for all deployments.

## Configuration

- **ConfigMaps/Secrets**: Use `ConfigMap` for non-sensitive configuration and `Secret` for sensitive data.
- **Mounting**: Mount ConfigMaps and Secrets as volumes rather than environment variables where possible to allow for hot-reloading.

## Autoscaling

- **HPA**: Use `HorizontalPodAutoscaler` based on CPU/Memory or custom metrics.
- **VPA**: Use `VerticalPodAutoscaler` in "Off" or "Initial" mode to recommend resource requests.

## Service Mesh

- **Usage**: If a Service Mesh (e.g., Istio, Linkerd) is used, ensure mTLS is enabled by default.
- **Observability**: Leverage mesh capabilities for metrics and tracing instead of implementing them in every application.
