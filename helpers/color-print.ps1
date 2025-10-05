function Write-HostColor {
    param ([string]$formattedString, [string[]]$colors, [bool]$noNewLine = $false)
    if ($colors.Length -eq 0) { $colors = @("White") }

    $stringSegment, $colorIndex = "", 0
    if ($formattedString.StartsWith("%c")) { $formattedString = $formattedString.Substring(2) }

    for ($i = 0; $i -lt $formattedString.Length; $i++) {
        if ($formattedString[$i] -eq "%" -and $formattedString[$i + 1] -eq "%") {
            $stringSegment += "%"; $i++;
        } elseif ($formattedString[$i] -eq "%" -and $formattedString[$i + 1] -eq "c") {
            Write-Host $stringSegment -ForegroundColor $colors[$colorIndex] -NoNewline
            $i++; $stringSegment = ""
            if ($colorIndex + 1 -lt $colors.Length) { $colorIndex++ }
        } else {
            $stringSegment += $formattedString[$i]
        }
    }

    if ($stringSegment -ne "") { Write-Host $stringSegment -ForegroundColor $colors[$colorIndex] -NoNewline }
    if (-not $noNewLine) { Write-Host }
}
