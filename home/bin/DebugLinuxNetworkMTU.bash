#!/bin/bash

# Parse command line arguments with defaults
step=${1:-10}
max=${2:-1500}
min=${3:-900}

echo "MTU Check in WSL2/Debian"
echo "Parameters: step=$step, max=$max, min=$min"

echo -e "\nInterfaces and MTU:"
ip link show | awk -F': ' '/^[0-9]+: / {print $2}' | while read -r iface; do
    mtu=$(ip link show "$iface" | grep mtu | awk '{print $5}')
    echo "$iface: MTU $mtu"
done

echo -e "\nPath MTU to deb.debian.org:"
for ((size=max; size>=min; size-=step)); do
    echo -n "Trying size $size... "
    ping -c 1 -M do -s $size deb.debian.org &>/dev/null && echo "OK" || echo "Fail"
done

echo -e "\nSuggested MTU for eth0: Use highest successful size + 28"
echo "MTU Testing Range: $min to $max (step: $step)"