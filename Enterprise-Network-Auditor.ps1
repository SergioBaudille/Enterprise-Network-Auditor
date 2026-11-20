# ==========================================
# Enterprise Network Auditor v1.0
# Author: Sergio Baudille
# ==========================================

$Global:ReportData = @()

$TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

if (!(Test-Path ".\Reports")) {
    New-Item -Path ".\Reports" -ItemType Directory | Out-Null
}

$Global:ReportPath = ".\Reports\NetworkReport_$TimeStamp.txt"

# ==========================================
# Connectivity Test
# ==========================================

function Test-HostConnectivity {

    $Target = Read-Host "Enter Hostname or IP"

    Write-Host ""
    Write-Host "Testing connectivity..." -ForegroundColor Cyan
    Write-Host ""

    $Result = Test-Connection `
        -ComputerName $Target `
        -Count 4 `
        -ErrorAction SilentlyContinue

    if ($Result) {

        $AverageLatency = (
            $Result |
            Measure-Object ResponseTime -Average
        ).Average

        Write-Host "Status: ONLINE" -ForegroundColor Green
        Write-Host "Average Latency: $([math]::Round($AverageLatency,2)) ms"

        $Global:ReportData += @"
====================================
Connectivity Test
====================================
Target: $Target
Status: ONLINE
Average Latency: $([math]::Round($AverageLatency,2)) ms

"@
    }
    else {

        Write-Host "Status: OFFLINE" -ForegroundColor Red

        $Global:ReportData += @"
====================================
Connectivity Test
====================================
Target: $Target
Status: OFFLINE

"@
    }
}

# ==========================================
# DNS Resolution
# ==========================================

function Test-DNSResolution {

    $Target = Read-Host "Enter Hostname"

    try {

        $DNSResult = Resolve-DnsName `
            -Name $Target `
            -ErrorAction Stop

        Write-Host ""
        Write-Host "DNS Resolution Successful" -ForegroundColor Green

        $DNSResult |
            Select-Object Name, IPAddress |
            Format-Table

        $IPs = $DNSResult.IPAddress -join ", "

        $Global:ReportData += @"
====================================
DNS Resolution
====================================
Hostname: $Target
Status: SUCCESS
Addresses: $IPs

"@
    }
    catch {

        Write-Host ""
        Write-Host "DNS Resolution Failed" -ForegroundColor Red

        $Global:ReportData += @"
====================================
DNS Resolution
====================================
Hostname: $Target
Status: FAILED

"@
    }
}

# ==========================================
# Gateway Test
# ==========================================

function Test-DefaultGateway {

    $Gateway = (
        Get-NetRoute `
            -DestinationPrefix "0.0.0.0/0" |
            Sort-Object RouteMetric |
            Select-Object -First 1
    ).NextHop

    Write-Host ""
    Write-Host "Gateway: $Gateway"
    Write-Host ""

    $Reachable = Test-Connection `
        -ComputerName $Gateway `
        -Count 2 `
        -Quiet

    if ($Reachable) {

        Write-Host "Gateway Reachable" -ForegroundColor Green

        $Global:ReportData += @"
====================================
Gateway Test
====================================
Gateway: $Gateway
Status: Reachable

"@
    }
    else {

        Write-Host "Gateway Unreachable" -ForegroundColor Red

        $Global:ReportData += @"
====================================
Gateway Test
====================================
Gateway: $Gateway
Status: Unreachable

"@
    }
}

# ==========================================
# Port Scanner
# ==========================================

function Test-CommonPorts {

    $Target = Read-Host "Enter Hostname or IP"

    $Ports = @(
        53,
        80,
        443,
        445,
        3389
    )

    Write-Host ""
    Write-Host "Scanning ports on $Target"
    Write-Host ""

    foreach ($Port in $Ports) {

        $Result = Test-NetConnection `
            -ComputerName $Target `
            -Port $Port `
            -WarningAction SilentlyContinue

        if ($Result.TcpTestSucceeded) {

            Write-Host "Port $Port OPEN" -ForegroundColor Green

            $Global:ReportData += "$Target - Port $Port OPEN"
        }
        else {

            Write-Host "Port $Port CLOSED" -ForegroundColor Red

            $Global:ReportData += "$Target - Port $Port CLOSED"
        }
    }

    $Global:ReportData += ""
}

# ==========================================
# Export Report
# ==========================================

function Export-NetworkReport {

    $ComputerName = $env:COMPUTERNAME

    $Header = @"
====================================
Enterprise Network Auditor Report
====================================

Computer Name: $ComputerName
Date: $(Get-Date)

"@

    $Header | Out-File $Global:ReportPath

    $Global:ReportData |
        Out-File `
        -FilePath $Global:ReportPath `
        -Append

    Write-Host ""
    Write-Host "Report Generated Successfully" -ForegroundColor Green
    Write-Host $Global:ReportPath -ForegroundColor Cyan
}

# ==========================================
# Main Menu
# ==========================================

do {

    Clear-Host

    Write-Host "========================================"
    Write-Host " Enterprise Network Auditor v1.0"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "1. Connectivity Test"
    Write-Host "2. DNS Resolution Test"
    Write-Host "3. Gateway Test"
    Write-Host "4. Port Scanner"
    Write-Host "5. Export Report"
    Write-Host "6. Exit"
    Write-Host ""

    $Choice = Read-Host "Choose an option"

   switch ($Choice) {

    "1" { Test-HostConnectivity }
    "2" { Test-DNSResolution }
    "3" { Test-DefaultGateway }
    "4" { Test-CommonPorts }
    "5" { Export-NetworkReport }
    "6" { break }

    default {
        Write-Host ""
        Write-Host "Invalid Option" -ForegroundColor Yellow
    }
}

    if ($Choice -ne "6") {
        Pause
    }

} while ($true)