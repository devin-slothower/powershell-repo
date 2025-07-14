. "$PSScriptRoot\color-print.ps1"

$tpmInfo = Get-CimInstance -Namespace "Root\CIMV2\Security\MicrosoftTpm" -ClassName Win32_Tpm
$cpuInfo = Get-CimInstance -ClassName Win32_Processor
$graphicsInfo = Get-CimInstance -ClassName Win32_VideoController
$ramInfo = Get-CimInstance -ClassName Win32_PhysicalMemory
$networkInfo = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = TRUE"

# Grab OS version information from the registry
$osInfo = Get-ItemProperty("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion")
$buildName = $osInfo.DisplayVersion
$buildNumber = $osInfo.CurrentBuild
$buildRevision = $osInfo.UBR

# Grab TPM Module version
$tpmInfo = $tpmInfo.SpecVersion
if ($tpmInfo.contains(",")) { $tpmInfo = $tpmInfo.substring(0, $tpmInfo.IndexOf(",")) }

# Grab CPU information
$cpuName = $cpuInfo.Name.Trim()
$maxClockSpeed = $cpuInfo.MaxClockSpeed
try {
    $maxClockSpeed = [double]$maxClockSpeed
    $maxClockSpeed = $maxClockSpeed / 1000
} catch {
    $maxClockSpeed = "UNKNOWN"
}

# Grab RAM Information
$totalRamCapacity, $highestSpeed = [uint64]0, 0
foreach ($ram in $ramInfo) {
    $totalRamCapacity += [uint64]$ram.Capacity

    if ($ram.Speed -gt $highestSpeed) {
        $highestSpeed = $ram.Speed
    }
}

$totalRamCapacity = $totalRamCapacity / 1GB

# Grab Uptime
$uptime = [TimeSpan]::FromMilliseconds([Environment]::TickCount64)

# Grab networking information
$dnsServers = $networkInfo.DNSServerSearchOrder -join ", "

# Check pending reboots
$componentPendingReboot = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
$updatePendingReboot = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired\"
$isPendingReboot = if ($componentPendingReboot -or $updatePendingReboot) { "True" } else { "False" }

Write-HostColor "%cVersion%c       : $($buildName) $($buildNumber).$($buildRevision)" -colors "blue", "white"
Write-HostColor "%cTPM%c           : $($tpmInfo)" -colors "blue", "white"
Write-HostColor "%cCPU%c           : $($cpuName) @ $($maxClockSpeed)GHz" -colors "blue", "white"
Write-HostColor "%cGPU%c           : $($graphicsInfo.Name)" -colors "blue", "white"
Write-HostColor "%cRAM%c           : $($totalRamCapacity)GB @ $($highestSpeed)MT/s" -colors "blue", "white"
Write-HostColor "%cUptime%c        : $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes" -colors "blue", "white"
Write-HostColor "%cResolution%c    : $($graphicsInfo.CurrentHorizontalResolution)x$($graphicsInfo.CurrentVerticalResolution) @ $($graphicsInfo.CurrentRefreshRate)Hz" -colors "blue", "white"
Write-HostColor "%cMAC Address%c   : $($networkInfo.MACAddress)" -colors "blue", "white"
Write-HostColor "%cDNS Addresses%c : $($dnsServers)" -colors "blue", "white"
Write-HostColor "%cLocal Address%c : $($networkInfo.IPAddress)" -colors "blue", "white"
Write-HostColor "%cAdapter%c       : $($networkInfo.Description)" -colors "blue", "white"
Write-HostColor "%cPending Reboot%c: $($isPendingReboot)" -colors "blue", "white"