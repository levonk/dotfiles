<#
.SYNOPSIS
    MTU (Maximum Transmission Unit) Discovery and Configuration Tool for Windows

.DESCRIPTION
    WHAT IS MTU?
    MTU is the largest packet size that can be transmitted over a network interface
    without fragmentation. Standard Ethernet MTU is 1500 bytes, but VPNs, tunnels,
    and some network configurations require smaller MTUs.

    PROBLEMS WITH MTU MISMATCH:
    - Slow or stalled connections (packets get dropped/fragmented)
    - Timeouts when accessing websites or services
    - RDP/SSH sessions that connect but hang during data transfer
    - Large file transfers that fail or are extremely slow
    - Applications that work on small data but fail on larger payloads

    HOW THIS SCRIPT HELPS:
    1. Shows current interface MTU settings
    2. Demonstrates binary search algorithm for MTU discovery
    3. Provides Windows-specific ping commands for MTU testing
    4. Offers guidance on setting MTU permanently

.PARAMETER max
    Maximum MTU to test (default: 9000)

.PARAMETER min
    Minimum MTU to test (default: 900)

.EXAMPLE
    .\DebugWindowsNetworkMTU.ps1
    Run with default parameters (max=1500, min=900)

.EXAMPLE
    .\DebugWindowsNetworkMTU.ps1 -max 1400 -min 1000
    Run with custom MTU range
#>

## If you're optimizing for performance or troubleshooting MTU-related
## issues, it's worth testing with tools like ping using the "do not fragment"
## flags like -f and -l (Windows) or ping -M do -s (Linux) to find the
## largest non-fragmented packet size.


# Parse command line arguments with defaults
## Most NICs support up to 1500, Jumbo Frames on high
## end NICs go 9000+, PPPoE 1492, VPN 1400-1476
## Minimum spec based IPv4 576, IPv6 1280 (dial up numbers)

param(
    [int]$max = 9000,
    [int]$min = 576
)

# Define a reasonable minimum MTU to consider as valid. If discovery
# produces anything lower than this, we treat it as a failure rather
# than suggesting an obviously broken MTU.
$MinReasonableMtu = 576

Write-Host "=== MTU Discovery Tool for Windows ==="
Write-Host "Parameters: max=$max, min=$min"

Write-Host "`n=== CURRENT INTERFACE MTU SETTINGS ==="

# Find primary interface (usually the one with default route)
$primaryInterface = Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -First 1 -ExpandProperty InterfaceAlias
if (-not $primaryInterface) {
    $primaryInterface = (Get-NetIPInterface | Where-Object {$_.ConnectionState -eq "Connected" -and $_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1).InterfaceAlias
}

Write-Host "Primary interface: $primaryInterface"

Get-NetIPInterface | Sort-Object InterfaceIndex | ForEach-Object {
    $alias = $_.InterfaceAlias
    $mtu = $_.NlMtu
    if ($alias -eq $primaryInterface) {
        Write-Host "→ $alias : MTU $mtu (PRIMARY)" -ForegroundColor Green
    } else {
        Write-Host "  $alias : MTU $mtu"
    }
}

# Show current MTU of primary interface
$currentMTU = (Get-NetIPInterface | Where-Object {$_.InterfaceAlias -eq $primaryInterface}).NlMtu
Write-Host "`nCurrent MTU on $primaryInterface : $currentMTU bytes" -ForegroundColor Cyan

Write-Host "`nWARP Interface MTU:"
Get-NetIPInterface | Where-Object {$_.InterfaceAlias -like "*WARP*"} | Format-Table InterfaceAlias, NlMtu

Write-Host "`n=== PATH MTU DISCOVERY USING BINARY SEARCH ==="
Write-Host "Testing connectivity to 8.8.8.8 (Google DNS) with Don't Fragment flag..."

# Binary search for maximum working MTU
$low = $min
$high = $max
$bestMTU = 0
$testTarget = "8.8.8.8"

Write-Host "Starting binary search between $low and $high..."

while (($high - $low) -gt 1) {
    $mid = [Math]::Floor(($low + $high) / 2)
    Write-Host "Testing payload size $mid... " -NoNewline

    # Use ping with -f (don't fragment) and -l (payload size)
    $pingResult = ping -f -l $mid -n 1 $testTarget 2>$null

    if ($LASTEXITCODE -eq 0 -and $pingResult -notmatch "needs to be fragmented") {
        Write-Host "OK" -ForegroundColor Green
        $bestMTU = $mid
        $low = $mid
    } else {
        Write-Host "Fail" -ForegroundColor Red
        $high = $mid
    }
}

# Fine-tune with smaller steps around the found value
if ($bestMTU -gt 0) {
    Write-Host "`nFine-tuning around $bestMTU..."
    $finalMTU = $bestMTU

    for ($size = $bestMTU + 1; $size -le ($bestMTU + 10) -and $size -le $max; $size++) {
        Write-Host "Testing payload size $size... " -NoNewline
        $pingResult = ping -f -l $size -n 1 $testTarget 2>$null

        if ($LASTEXITCODE -eq 0 -and $pingResult -notmatch "needs to be fragmented") {
            Write-Host "OK" -ForegroundColor Green
            $finalMTU = $size
        } else {
            Write-Host "Fail" -ForegroundColor Red
            break
        }
    }
} else {
    Write-Host "`nTesting minimum value $low..." -NoNewline
    $pingResult = ping -f -l $low -n 1 $testTarget 2>$null
    if ($LASTEXITCODE -eq 0 -and $pingResult -notmatch "needs to be fragmented") {
        Write-Host "OK" -ForegroundColor Green
        $finalMTU = $low
    } else {
        Write-Host "Fail" -ForegroundColor Red
        Write-Host "ERROR: Even minimum payload size $low failed!" -ForegroundColor Red
        $finalMTU = 0
    }
}

if ($finalMTU -gt 0 -and $finalMTU -ge $MinReasonableMtu) {
    $suggestedMTU = $finalMTU + 28
    Write-Host "`n=== RESULTS ===" -ForegroundColor Cyan
    Write-Host "Maximum working payload size: $finalMTU bytes"
    Write-Host "Suggested MTU for $primaryInterface : $suggestedMTU bytes"
    Write-Host "(Payload + 20 bytes IP header + 8 bytes ICMP header = MTU)"

    # Check if suggested MTU is different from current
    if ($currentMTU -ne $suggestedMTU) {
        Write-Host "`n=== MTU CONFIGURATION ===" -ForegroundColor Yellow
        Write-Host "Current MTU ($currentMTU) differs from optimal MTU ($suggestedMTU)"
        Write-Host ""
        Write-Host "To set MTU temporarily:"
        Write-Host "  netsh interface ipv4 set subinterface `"$primaryInterface`" mtu=$suggestedMTU store=active"
        Write-Host ""
        Write-Host "To set MTU permanently:"
        Write-Host "  netsh interface ipv4 set subinterface `"$primaryInterface`" mtu=$suggestedMTU store=persistent"
        Write-Host ""
        Write-Host "Alternative PowerShell method:"
        Write-Host "  Set-NetIPInterface -InterfaceAlias `"$primaryInterface`" -NlMtu $suggestedMTU"

        Write-Host "`nWould you like to set the MTU now? (y/N): " -NoNewline
        $response = Read-Host
        if ($response -match '^[Yy]$') {
            Write-Host "Setting MTU to $suggestedMTU on $primaryInterface..." -ForegroundColor Yellow
            try {
                Set-NetIPInterface -InterfaceAlias $primaryInterface -NlMtu $suggestedMTU -ErrorAction Stop
                Write-Host "✅ MTU successfully set to $suggestedMTU" -ForegroundColor Green
                Write-Host "⚠️  This change is temporary - use netsh with store=persistent for permanent configuration" -ForegroundColor Yellow
            } catch {
                Write-Host "❌ Failed to set MTU: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Try running as Administrator or use netsh command manually." -ForegroundColor Yellow
            }
        } else {
            Write-Host "MTU not changed. Use the commands above when ready."
        }
    } else {
        Write-Host "`n✅ Current MTU ($currentMTU) is already optimal!" -ForegroundColor Green
    }
} else {
    Write-Host "`n❌ MTU discovery did not find a reliable value (final payload size: $finalMTU bytes)." -ForegroundColor Red
    Write-Host "   This usually indicates a different network problem (DNS, routing, firewall, or ICMP being blocked)." -ForegroundColor Yellow
    Write-Host "   Skipping MTU change suggestions --- please fix underlying connectivity issues first." -ForegroundColor Yellow
}

Write-Host "`n=== MANUAL MTU TESTING ON WINDOWS ==="
Write-Host "To perform actual MTU testing on Windows:"
Write-Host "ping -f -l 1472 8.8.8.8  # Test with 1472 byte payload"
Write-Host "ping -f -l 1200 8.8.8.8  # Test with 1200 byte payload"
Write-Host "Adjust size based on 'Packet needs to be fragmented' errors"
Write-Host ""
Write-Host "Binary search example:"
Write-Host "1. Start with ping -f -l $max 8.8.8.8"
Write-Host "2. If it fails, try ping -f -l $((($max + $min) / 2)) 8.8.8.8"
Write-Host "3. Continue halving the range until you find the maximum working size"
Write-Host "4. Add 28 bytes (IP + ICMP headers) to get the MTU"

Write-Host "`n=== MTU CONFIGURATION FOR WINDOWS ==="
Write-Host "Once you find the optimal MTU through testing:"
Write-Host ""
Write-Host "To set MTU temporarily:"
Write-Host "  netsh interface ipv4 set subinterface `"$primaryInterface`" mtu=<discovered_mtu> store=active"
Write-Host ""
Write-Host "To set MTU permanently:"
Write-Host "  netsh interface ipv4 set subinterface `"$primaryInterface`" mtu=<discovered_mtu> store=persistent"
Write-Host ""
Write-Host "To check current MTU:"
Write-Host "  netsh interface ipv4 show subinterfaces"
Write-Host ""
Write-Host "Alternative method using PowerShell:"
Write-Host "  Set-NetIPInterface -InterfaceAlias `"$primaryInterface`" -NlMtu <discovered_mtu>"
Write-Host ""
Write-Host "For VPN connections, you may also need to adjust:"
Write-Host "- Registry: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
Write-Host "- Add DWORD: EnablePMTUDiscovery = 1"
Write-Host "- Add DWORD: EnablePMTUBHDetect = 0"

Write-Host "`n⚠️  Note: Always test connectivity after changing MTU settings!" -ForegroundColor Yellow
Write-Host "🔄 Reboot may be required for some changes to take effect" -ForegroundColor Yellow
