# Project Memory & Standards

## Docker Standards

- **Base Images**: Always use project-specific base images (e.g., `localnet/base-alpine`) instead of generic upstream images.
- **File Structure**:
  - `Dockerfile` should be placed in a `docker/` subdirectory.
  - Entrypoint scripts and other assets should be in an `assets/` subdirectory.
  - Configuration templates requiring runtime environment substitution MUST be placed in `mounts/templates/`.
  - A standalone `docker-compose.yml` MUST be present at the service root for isolated development and testing.
  - A `Makefile` MUST be present at the service root to standardize automation.
  - **Example Reference Structure**:
    ```text
    service-name/
    ├── .env.example          # Environment variable template
    ├── .dockerignore         # Build context exclusion
    ├── docker-compose.yml    # Standalone development composition
    ├── Makefile              # Standard automation targets
    ├── README.md             # Service documentation
    ├── assets/               # Runtime assets (scripts, static files)
    │   └── entrypoint.sh
    ├── docker/               # Build artifacts
    │   └── Dockerfile
    ├── healthcheck/          # Health check scripts
    │   └── healthcheck-internal-{service}.sh	# healthcheck for docker to run
    │   └── healthcheck-external-{service}.sh	# healthcheck for external monitoring
    ├── mounts/               # Mounted configurations
    │   ├── static.conf
    │   └── templates/        # Templates needing env substitution
    │       └── dynamic.conf.template
    └── tests/                # Automated tests
        └── test-service.sh
    ```
- **YAML Formatting**:
  - All YAML files (including `docker-compose.yml`) must start with `---`.
  - Do not use the deprecated `version` top-level key in `docker-compose.yml`.
- **Naming Conventions**:
  - Container names should follow the pattern `localnet-app-{service_name}`.
- **Environment Variables**:
  - **Port Binds**: There should always be Environment variables for port bindings and IPs. They MUST follow the format:
    `{CATEGORY}_{SERVICE}_{SUB_SERVICE}_{HOST|CONTAINER}_{PORT|IP}`
    - **Examples**:
      - `DNS_DNSCRYPT_ODOH_CONTAINER_PORT`
      - `DNS_DNSCRYPT_ODOH_HOST_PORT`
      - `PROXY_TOR_MAIN_CONTAINER_IP`
    - This ensures consistent, conflict-free naming across the monorepo.
  - **Standard Configuration**: All services MUST support the following standard variables:
    - `PUID`: Process User ID for file permissions (default: 1000)
    - `PGID`: Process Group ID for file permissions (default: 1000)
    - `TZ`: Timezone setting (default: UTC)
- **Logging**:
  - Use shared logging configuration (json-file with rotation) defined in `x-logging` anchor.
- **Documentation**:
  - Every service MUST have a `README.md` documenting purpose, setup, environment variables, and maintenance.
  - Include comments about platform limitations (e.g., Windows/WSL2 network restrictions for monitoring tools).
- **Testing**:
  - Automated tests are REQUIRED and MUST be placed in the `tests/` directory.
  - Tests MUST be executable via the standard `make test` target.
- **Shell Scripts**:
  - Include `shellcheck` directive after the shebang.
  - Use strict error handling (`set -e -u -o pipefail`).

## Boilerplate Updates

### Unified `docker-linux` Boilerplate

- **Standard**: All new Docker services not based on specific existing docker image MUST use the `docker-linux` boilerplate via `copier copy docker-linux <target-dir>`.
- **Base OS Options**:
  - `base-debian`: Default for general-purpose applications, complex dependencies.
  - `base-alpine`: For microservices, high-security needs, and resource-constrained environments.
- **Automation**:
  - Projects MUST include the standard `Makefile` with targets: `build`, `up`, `test`, `security-scan`, `health-check`.
  - Health checks MUST be implemented via `healthcheck/` scripts and Docker `HEALTHCHECK` instruction.

## Security Standards

- **Non-Root Execution**: Services MUST run as a non-root user (e.g., `appuser`, `nobody`) or drop immediately if necessary. The boilerplate enforces this by default.
- **Security Scanning**: Automated scanning (Trivy/Dockle/Hadolint) MUST be integrated into the CI/CD pipeline and local dev workflow (`make security-scan`).
- **Minimal Base Images**: Use the hardened `base-debian` or `base-alpine` images which are optimized for security and minimal attack surface.
- **Container Hardening**:
  - **Privileges**: Use `--security-opt=no-new-privileges` to prevent privilege escalation. Drop all capabilities (`--cap-drop all`) and add back only what is needed. Never use `--privileged`.
  - **Docker Socket**: NEVER mount `/var/run/docker.sock` or enable the TCP Docker daemon socket without TLS via a security limiting tool like https://github.com/wollomatic/socket-proxy
  - **Filesystems**: Use read-only root filesystems where possible with `tmpfs` for temporary write needs.
  - **Networks**: Avoid host networking. Use defined custom networks and limit exposed ports.
  - **Secrets**: Never bake secrets into image layers or environment variables. Use Docker secrets or mount them at runtime.
  - **Health Checks**: Always include a `HEALTHCHECK` instruction.
  - **Firewall Rules**:
    - Lock down external endpoints: Use `iptables` or host firewalls (like UFW/CrowdSec) to restrict which external IPs/ranges a container can contact.
    - Egress Filtering: Where possible, restrict outbound traffic from containers to only necessary services (e.g., package repositories during build, specific APIs during runtime).
    - See **Networking & Connectivity > Transparent Proxy** for guidance on routing traffic through a restrictive proxy container.

## Docker Best Practices Guidelines

### 1. Image Optimization

- **Multi-stage Builds**: Always use multi-stage builds to separate build dependencies from runtime artifacts.
- **Minimize Layers**: Combine `RUN` commands where possible to reduce image layers.
- **Cache Leverage**: Order Dockerfile instructions from least to most frequently changed to maximize build cache usage.
- **Clean Up**: Remove package manager caches (e.g., `apt-get clean && rm -rf /var/lib/apt/lists/*`) in the same `RUN` instruction as the install.

### 2. Container Lifecycle

- **Graceful Shutdown**: Ensure applications handle `SIGTERM` correctly for clean shutdowns.
- **PID 1**: Use `tini` or similar init processes to handle signal propagation and zombie processes if the app doesn't handle them natively.
- **Statelessness**: Treat containers as ephemeral. Persist state only to attached volumes.

### 3. Networking & Connectivity

- **Service Discovery**: Rely on Docker's internal DNS for inter-container communication.
- **Port Exposure**: Only expose ports that are necessary. Use `127.0.0.1` binding for ports that should not be accessible externally.
- **Traefik Integration**: Use labels for ingress configuration rather than exposing ports directly, where applicable.
- **Transparent Proxy**: Use a transparent proxy container (e.g., for locking down external access, VPN or Tor tunneling), ensure that the service container is configured to route all traffic through the proxy container's network stack (e.g., `network_mode: "service:vpn-cloudflare-api-only"`).

### 4. Development vs Production

- **Consistency**: Keep `Dockerfile` and base images consistent between dev and prod.
- **Overrides**: Use `docker-compose.override.yml` for development-specific settings (e.g., volume mounts for hot reloading) without modifying the main compose file.
