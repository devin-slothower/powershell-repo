. "$PSScriptRoot\color-print.ps1"

# Grab OS version information from the registry
$osInfo = Get-ItemProperty("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion")
$buildName = $osInfo.DisplayVersion
$buildNumber = $osInfo.CurrentBuild
$buildRevision = $osInfo.UBR

# Grab TPM Module version
$tpmVersion = Get-CimInstance -Namespace "Root\CIMV2\Security\MicrosoftTpm" -ClassName Win32_Tpm | Select-Object SpecVersion
$tpmVersion = $tpmVersion.SpecVersion
if ($tpmVersion.contains(",")) { $tpmVersion = $tpmVersion.substring(0, $tpmVersion.IndexOf(",")) }

# Grab CPU information
$cpuInformation = Get-CimInstance -ClassName Win32_Processor | Select-Object Name, MaxClockSpeed
$cpuName = $cpuInformation.Name.Trim()
$maxClockSpeed = $cpuInformation.MaxClockSpeed
try {
    $maxClockSpeed = [double]$maxClockSpeed
    $maxClockSpeed = $maxClockSpeed / 1000
} catch {
    $maxClockSpeed = "UNKNOWN"
}

# Grab Graphics information
$graphicsInfo = Get-CimInstance -ClassName Win32_VideoController | Select-Object Name, CurrentHorizontalResolution, CurrentVerticalResolution, CurrentRefreshRate

# Grab RAM Information
$ramArray = Get-CimInstance Win32_PhysicalMemory | Select-Object Capacity, Speed, FormFactor
$totalRamCapacity, $highestSpeed = [uint64]0, 0
foreach ($ram in $ramArray) {
    $totalRamCapacity += [uint64]$ram.Capacity

    if ($ram.Speed -gt $highestSpeed) {
        $highestSpeed = $ram.Speed
    }
}

$totalRamCapacity = $totalRamCapacity / 1GB

# Grab Uptime
$os = Get-CimInstance Win32_OperatingSystem | Select-Object LastBootUpTime
$uptime = (Get-Date) - $os.LastBootUpTime

Write-HostColor "%cVersion%c: $($buildName) $($buildNumber).$($buildRevision)" -colors "blue", "white"
Write-HostColor "%cTPM%c: $($tpmVersion)" -colors "blue", "white"
Write-HostColor "%cCPU%c: $($cpuName) @ $($maxClockSpeed)GHz" -colors "blue", "white"
Write-HostColor "%cGPU%c: $($graphicsInfo.Name)" -colors "blue", "white"
Write-HostColor "%cRAM%c: $($totalRamCapacity)GB @ $($highestSpeed)MT/s" -colors "blue", "white"
Write-HostColor "%cUptime%c: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes" -colors "blue", "white"
Write-HostColor "%cResolution%c: $($graphicsInfo.CurrentHorizontalResolution)x$($graphicsInfo.CurrentVerticalResolution) @ $($graphicsInfo.CurrentRefreshRate)Hz" -colors "blue", "white"