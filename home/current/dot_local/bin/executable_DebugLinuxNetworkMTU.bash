#!/usr/bin/env bash
#
# MTU (Maximum Transmission Unit) Discovery and Configuration Tool for Linux/WSL
#
# WHAT IS MTU?
# MTU is the largest packet size that can be transmitted over a network interface
# without fragmentation. Standard Ethernet MTU is 1500 bytes, but VPNs, tunnels,
# and some network configurations require smaller MTUs.
#
# PROBLEMS WITH MTU MISMATCH:
# - Slow or stalled connections (packets get dropped/fragmented)
# - Timeouts when accessing websites or services
# - SSH/RDP sessions that connect but hang during data transfer
# - Large file transfers that fail or are extremely slow
# - Applications that work on small data but fail on larger payloads
#
# HOW THIS SCRIPT HELPS:
# 1. Shows current interface MTU settings
# 2. Uses binary search to find the maximum working path MTU
# 3. Tests actual network connectivity to find optimal MTU
# 4. Provides commands to set the discovered MTU permanently
#
# USAGE:
#   ./DebugLinuxNetworkMTU.bash [max] [min]
#   Default: max=1500, min=900
#   Example: ./DebugLinuxNetworkMTU.bash 1400 1000
#

## If you're optimizing for performance or troubleshooting MTU-related
## issues, it's worth testing with tools like ping using the "do not fragment"
## flags like -f and -l (Windows) or ping -M do -s (Linux) to find the
## largest non-fragmented packet size.

# Parse command line arguments with defaults
## Most NICs support up to 1500, Jumbo Frames on high
## end NICs go 9000+, PPPoE 1492, VPN 1400-1476
## Minimum spec based IPv4 576, IPv6 1280 (dial up numbers)
max=${1:-9000}
min=${2:-576}

# Define a reasonable minimum MTU to consider as valid. If discovery
# produces anything lower than this, we treat it as a failure rather
# than suggesting an obviously broken MTU.
MIN_REASONABLE_MTU=576

echo "=== MTU Discovery Tool for Linux/WSL ==="
echo "Parameters: max=$max, min=$min"

echo -e "\n=== CURRENT INTERFACE MTU SETTINGS ==="
# Find the primary network interface (usually eth0 or the one with default route)
primary_iface=$(ip route | grep '^default' | head -1 | awk '{print $5}')
if [ -z "$primary_iface" ]; then
    primary_iface="eth0"  # fallback for WSL
fi

echo "Primary interface: $primary_iface"
ip link show | awk -F': ' '/^[0-9]+: / {print $2}' | while read -r iface; do
    mtu=$(ip link show "$iface" | grep mtu | awk '{print $5}')
    if [ "$iface" = "$primary_iface" ]; then
        echo "→ $iface: MTU $mtu (PRIMARY)"
    else
        echo "  $iface: MTU $mtu"
    fi
done

# Show current MTU of primary interface
current_mtu=$(ip link show "$primary_iface" 2>/dev/null | grep mtu | awk '{print $5}')
if [ -n "$current_mtu" ]; then
    echo -e "\nCurrent MTU on $primary_iface: $current_mtu bytes"
fi

echo -e "\nPath MTU Discovery using Binary Search:"

# Binary search for maximum working MTU
low=$min
high=$max
best_mtu=0

echo "Starting binary search between $low and $high..."

while [ $((high - low)) -gt 1 ]; do
    mid=$(((low + high) / 2))
    echo -n "Testing MTU $mid... "

    if ping -c 1 -M do -s $mid deb.debian.org &>/dev/null; then
        echo "OK"
        best_mtu=$mid
        low=$mid
    else
        echo "Fail"
        high=$mid
    fi
done

# Fine-tune with smaller steps around the found value
echo -e "\nFine-tuning around $best_mtu..."
final_mtu=$best_mtu

for ((size=best_mtu+1; size<=best_mtu+10 && size<=max; size++)); do
    echo -n "Testing MTU $size... "
    if ping -c 1 -M do -s $size deb.debian.org &>/dev/null; then
        echo "OK"
        final_mtu=$size
    else
        echo "Fail"
        break
    fi
done

echo -e "\n=== RESULTS ==="

if [ "$final_mtu" -lt "$MIN_REASONABLE_MTU" ] || [ "$final_mtu" -eq 0 ]; then
    echo "❌ MTU discovery did not find a reliable value (final payload size: $final_mtu bytes)." >&2
    echo "   This usually indicates a different network problem (e.g., DNS, routing, firewall, or ICMP blocked)." >&2
    echo "   Skipping MTU change suggestions --- please fix underlying connectivity issues first." >&2
    exit 1
fi

echo "Maximum working payload size: $final_mtu bytes"
suggestedMTU=$((final_mtu + 28))
echo "Suggested MTU for $primary_iface: $suggestedMTU bytes"
echo "(Payload + 20 bytes IP header + 8 bytes ICMP header = MTU)"

# Check if suggested MTU is different from current
if [ -n "$current_mtu" ] && [ "$current_mtu" != "$suggestedMTU" ]; then
    echo -e "\n=== MTU CONFIGURATION ==="
    echo "Current MTU ($current_mtu) differs from optimal MTU ($suggestedMTU)"
    echo ""
    echo "To set MTU temporarily (until reboot):"
    echo "  sudo ip link set dev $primary_iface mtu $suggestedMTU"
    echo ""
    echo "To make MTU persistent across reboots:"
    echo ""
    echo "For Ubuntu/Debian with netplan:"
    echo "  1. Edit /etc/netplan/01-network-manager-all.yaml"
    echo "  2. Add under the interface:"
    echo "     mtu: $suggestedMTU"
    echo "  3. Run: sudo netplan apply"
    echo ""
    echo "For systems with /etc/network/interfaces:"
    echo "  1. Edit /etc/network/interfaces"
    echo "  2. Add: mtu $suggestedMTU to the interface section"
    echo ""
    echo "For WSL2:"
    echo "  1. Create/edit ~/.wslconfig on Windows host"
    echo "  2. Add: [wsl2]\nmtu=$suggestedMTU"
    echo "  3. Restart WSL: wsl --shutdown"
    echo ""
    echo "Would you like to set the MTU now? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Setting MTU to $suggestedMTU on $primary_iface..."
        if sudo ip link set dev "$primary_iface" mtu "$suggestedMTU"; then
            echo "✅ MTU successfully set to $suggestedMTU"
            echo "⚠️  This change is temporary - use the persistent methods above for permanent configuration"
        else
            echo "❌ Failed to set MTU. You may need to run as root or check interface name."
        fi
    else
        echo "MTU not changed. Use the commands above when ready."
    fi
elif [ -n "$current_mtu" ]; then
    echo -e "\n✅ Current MTU ($current_mtu) is already within the discovered optimal range."
fi
