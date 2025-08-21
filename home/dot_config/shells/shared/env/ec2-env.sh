# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
# EC2 environment detection and variables (from legacy sharedrc)
# POSIX-compatible version
# Note: Review security implications before enabling in production environments.

# Default: not in EC2
in_ec2=0

# Path to proprietary environment properties file
PROPRIETARY_ENV_FILE="/etc/proprietary/proprietary.properties"

# Check for EC2 marker file and extract value if present
if [ -f "$PROPRIETARY_ENV_FILE" ]; then
    in_ec2=$(grep -w '^ec2' "$PROPRIETARY_ENV_FILE" | sed 's/^ec2[^a-zA-Z0-9]*//')
    [ -z "$in_ec2" ] && in_ec2=0
fi

# If in EC2, fetch security group info from metadata (with timeouts for safety)
if [ "$in_ec2" -ne 0 ]; then
    # Query EC2 metadata service for security groups (timeout for security)
    ec2_secgroups="$(curl --max-time 2 -sf http://169.254.169.254/latest/meta-data/security-groups 2>/dev/null)"
    if [ -n "$ec2_secgroups" ]; then
        # Use first security group as ec2_sg (or empty if not found)
        ec2_sg="$(printf '%s' "$ec2_secgroups" | head -n1)"
        # Create a normalized variable (alphanumeric, underscores)
        ec2_univ="$(printf '%s' "$ec2_secgroups" | tr -cs '[:alnum:]_' '_')"
    else
        ec2_sg=""
        ec2_univ=""
    fi
else
    ec2_secgroups=""
    ec2_sg=""
    ec2_univ=""
fi

# Export variables for use in other scripts
export in_ec2 ec2_secgroups ec2_sg ec2_univ
