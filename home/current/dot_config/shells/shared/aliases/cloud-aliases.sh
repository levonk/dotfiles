# shellcheck shell=sh
# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
# Directory navigation aliases and functions (from legacy sharedrc and aliases)

# AWS EC2 instance metadata helper
# Usage:
#   aws-info [path]
# Examples:
#   aws-info                     # list top-level metadata
#   aws-info iam/security-credentials/
aws_info() {
  local path
  path=${1:-}

  # Try to get IMDSv2 token (falls back to IMDSv1 if not available)
  local token
  token=$(curl -fsS -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 60" 2>/dev/null || true)

  if [ -n "$token" ]; then
    curl -fsS -H "X-aws-ec2-metadata-token: $token" \
      "http://169.254.169.254/latest/meta-data/${path}"
  else
    curl -fsS "http://169.254.169.254/latest/meta-data/${path}"
  fi
}

# Preserve original hyphenated command name via alias
alias aws-info='aws_info'

# GCP Compute Engine metadata helper
# Docs: https://cloud.google.com/compute/docs/metadata/overview
# Usage:
#   gcp-info [path]
# Examples:
#   gcp-info                                # list top-level
#   gcp-info instance/service-accounts/
gcp_info() {
  local path
  path=${1:-}
  curl -fsS -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/${path}"
}
alias gcp-info='gcp_info'

# Azure VM Instance Metadata helper
# Docs: https://learn.microsoft.com/azure/virtual-machines/instance-metadata-service
# Usage:
#   azure-info [path] [api-version]
# Notes:
#   - Default path is 'instance' (JSON). Provide a subpath to drill down.
#   - Default api-version is 2021-02-01.
azure_info() {
  local path api
  path=${1:-instance}
  api=${2:-2021-02-01}
  # Normalize leading slash if provided
  if [ -n "$path" ] && [ "${path:0:1}" = "/" ]; then
    path=${path#/}
  fi
  curl -fsS -H "Metadata: true" \
    "http://169.254.169.254/metadata/${path}?api-version=${api}"
}
alias azure-info='azure_info'

# DigitalOcean Droplets metadata helper
# Docs: https://docs.digitalocean.com/reference/metadata/
# Usage:
#   do-info [path]
# Examples:
#   do-info                      # list top-level
#   do-info droplet_id
do_info() {
  local path
  path=${1:-}
  curl -fsS "http://169.254.169.254/metadata/v1/${path}"
}
alias do-info='do_info'

# Oracle Cloud Infrastructure (OCI) metadata helper
# Docs: https://docs.oracle.com/iaas/Content/Compute/Tasks/gettingmetadata.htm
# Usage:
#   oci-info [path]
# Notes:
#   - Requires Authorization header for v2 endpoints
oci_info() {
  local path
  path=${1:-instance/}
  curl -fsS \
    -H "Authorization: Bearer Oracle" \
    -H "Accept: application/json" \
    "http://169.254.169.254/opc/v2/${path}"
}
alias oci-info='oci_info'

# OpenStack metadata helper (EC2-compatible or native OpenStack paths)
# Docs: https://docs.openstack.org/nova/latest/user/metadata.html
# Usage:
#   openstack-info [path]
# Examples:
#   openstack-info latest/meta-data/           # EC2-style
#   openstack-info openstack/latest/meta_data.json
openstack_info() {
  local path
  path=${1:-latest/meta-data/}
  curl -fsS "http://169.254.169.254/${path}"
}
alias openstack-info='openstack_info'

# Alibaba Cloud ECS metadata helper
# Docs: https://www.alibabacloud.com/help/en/ecs/user-guide/instance-metadata
# Usage:
#   alicloud-info [path]
# Notes:
#   - ECS uses 100.100.100.200 as the metadata IP
alicloud_info() {
  local path
  path=${1:-latest/meta-data/}
  curl -fsS "http://100.100.100.200/${path}"
}
alias alicloud-info='alicloud_info'

# Linode metadata helper
# Docs: https://www.linode.com/docs/products/compute/compute-instances/guides/metadata/
linode_info() {
  local path
  path=${1:-}
  curl -fsS "http://169.254.169.254/metadata/${path}"
}
alias linode-info='linode_info'

# Hetzner Cloud metadata helper
# Docs: https://docs.hetzner.com/cloud/servers/metadata/
hetzner_info() {
  local path
  path=${1:-}
  curl -fsS -H "Metadata-Flavor: Google" \
    "http://169.254.169.254/metadata/${path}"
}
alias hetzner-info='hetzner_info'

# Scaleway metadata helper
# Docs: https://www.scaleway.com/en/docs/compute/instances/how-to/use-metadata/
scaleway_info() {
  local path
  path=${1:-}
  curl -fsS "http://169.254.42.42/${path}"
}
alias scaleway-info='scaleway_info'

# Vultr metadata helper
# Docs: https://docs.vultr.com/metadata
vultr_info() {
  local path
  path=${1:-}
  curl -fsS "http://169.254.169.254/v1/${path}"
}
alias vultr-info='vultr_info'

# OVH Public Cloud (OpenStack-based) metadata helper
# Docs: https://help.ovhcloud.com/csm/en-public-cloud-compute-metadata?id=kb_article_view&sysparm_article=KB0047171
ovh_info() {
  local path
  path=${1:-}
  curl -fsS "http://169.254.169.254/latest/meta-data/${path}"
}
alias ovh-info='ovh_info'

# Equinix Metal (Packet) metadata helper
# Docs: https://metal.equinix.com/developers/docs/servers/metadata/
equinix_info() {
  local path
  path=${1:-}
  curl -fsS "http://metadata.packet.net/metadata/${path}"
}
alias equinix-info='equinix_info'

# Exoscale (CloudStack) metadata helper
# Docs: https://community.exoscale.com/documentation/compute/metadata/
exoscale_info() {
  local path
  path=${1:-}
  curl -fsS "http://169.254.169.254/1.0/meta-data/${path}"
}
alias exoscale-info='exoscale_info'

# Yandex Cloud metadata helper (GCE-compatible)
# Docs: https://cloud.yandex.com/en/docs/compute/operations/vm-info/get-info
yandex_info() {
  local path
  path=${1:-}
  curl -fsS -H "Metadata-Flavor: Google" \
    "http://169.254.169.254/computeMetadata/v1/${path}"
}
alias yandex-info='yandex_info'

# IBM Cloud VPC metadata helper
# Docs: https://cloud.ibm.com/docs/vpc?topic=vpc-imd-overview
ibmcloud_info() {
  local path
  path=${1:-}
  curl -fsS "http://169.254.169.254/metadata/v1/${path}"
}
alias ibmcloud-info='ibmcloud_info'

# UpCloud metadata helper
# Docs: https://upcloud.com/resources/tutorials/metadata-service
upcloud_info() {
  local path
  path=${1:-}
  curl -fsS "http://169.254.169.254/metadata/v1/${path}"
}
alias upcloud-info='upcloud_info'

# Tencent Cloud metadata helper (EC2-compatible paths)
# Docs: https://www.tencentcloud.com/document/product/213/4933
tencent_info() {
  local path
  path=${1:-}
  curl -fsS "http://169.254.169.254/latest/meta-data/${path}"
}
alias tencent-info='tencent_info'
