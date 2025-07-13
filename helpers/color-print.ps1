function Write-HostColor {
    param (
        [string]$formattedString,
        [string[]]$colors,
        [bool]$noNewLine = $false
    )

    if ($formattedString.startsWith("%c")) {
        $formattedString = $formattedString.subString(2)
    }

    $segments = $formattedString -split '(?=%c)'
    $colorIndex = 0

    foreach ($segment in $segments) {
        if ($segment.startsWith("%c")) {
            $segment = $segment.subString(2)
            $colorIndex++
        }
        if ($segment.length -eq 0) { continue }
        $color = if ($colorIndex -lt $colors.count) { $colors[$colorIndex] } else { "white" }

        Write-Host -NoNewline -ForegroundColor $color $segment
    }

    if (-not $noNewLine) { Write-Host }
}