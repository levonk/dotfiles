param(
    [int]$step = 10,
    [int]$max = 1500,
    [int]$min = 900
)

Write-Host "MTU Check on Windows Host"
Write-Host "Parameters: step=$step, max=$max, min=$min"

Get-NetIPInterface | Sort-Object InterfaceIndex | ForEach-Object {
    $alias = $_.InterfaceAlias
    $mtu = $_.NlMtu
    Write-Host "$alias : MTU $mtu"
}

Write-Host "`nWARP Interface MTU:"
Get-NetIPInterface | Where-Object {$_.InterfaceAlias -like "*WARP*"} | Format-Table InterfaceAlias, NlMtu

Write-Host "`nMTU Testing Range: $min to $max (step: $step)"