function Show-Help { @"
Commands (case-insensitive):
    listprinters    (lp)    - Show every printer on the system
    listports       (lport) - Show every printer port
    listdrivers     (ldrv)  - Show every installed printer driver

    addprinter      (ap)    - Install a new printer
        -name <Name> -driver <DriverName> -port <PortName> [-computername <C>]

    renameprinter   (rp)    - Rename an existing printer
        -old <OldName> -new <NewName> [-computername <C>]

    deleteprinter   (dp)    - Remove a printer
        -name <Name> [-computername <C>]

    selectcomputer  (sc)    - Set the default computer for remote commands
        -name <ComputerName>
    help or ?               - Display this help text
    exit (x) or quit (q)    - Leave the console
"@ }

function Parse-Args {
    param([string[]]$Tokens)

    $argsHash   = @{}
    $currentKey = $null

    foreach ($token in $Tokens) {
        if ($token -match '^-(.+)') {
            $currentKey = $Matches[1].ToLower()
            $argsHash[$currentKey] = @()
        }
        elseif ($currentKey) {
            $clean = $token -replace '"',' '
            $argsHash[$currentKey] += $clean.Trim()
        }
    }

    foreach ($k in $argsHash.Keys) {
        if ($argsHash[$k].Count -eq 1) {
            $argsHash[$k] = $argsHash[$k][0]
        }
    }

    return $argsHash
}

function Select-Computer {
    param([string]$Name)
    
    if (-not $Name) {
        Write-Host "No computer name provided. Use: selectcomputer -name <ComputerName>" -ForegroundColor Red
        return
    }
    
    $Name = $Name -replace '\s',''

    if ($Name.Length -le 2 -or $Name -eq "localhost") {
        $script:DefaultComputer = $null
        Write-Host "Computer set to the localhost." -ForegroundColor Green
        return
    }
    
    $script:DefaultComputer = $Name
    Write-Host "Default computer set to $Name. $($Name.Length)" -ForegroundColor Green
}

function Invoke-Remote {
    param([scriptblock]$Script, [string[]]$ComputerName)
    $ComputerName = if (-not $ComputerName) { "" } else { $ComputerName }

    if (-not $ComputerName) { 
        if ($script:DefaultComputer -ne $null -and $script:DefaultComputer -ne "" -and $script:DefaultComputer.Length -gt 2) {
            $ComputerName = $script:DefaultComputer
        } else {
            & $Script
            return
        }
    }
    
    Write-Host "Remote Execution on $ComputerName" -ForegroundColor Cyan
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $Script -ErrorAction Stop
}

if (-not ([bool]([Security.Principal.WindowsIdentity]::GetCurrent()).Groups -match 'S-1-5-32-544')) {
    Write-Warning "Run this script from an elevated PowerShell session."
}

Write-Host "PrinterPart - type 'help' or '?' for usage, 'exit' to quit." -ForegroundColor Cyan

:mainLoop while ($true) {
    Write-Host -NoNewline "> "
    $raw = Read-Host
    $raw = $raw.Trim()
    if ([string]::IsNullOrWhiteSpace($raw)) { continue }

    $tokens = $raw -split '(?<=^| )"([^"]*)"| +'
    $cmd = $tokens[0].ToLower()
    $args = if ($tokens.Count -gt 1) { $tokens[1..($tokens.Count-1)] } else { @() }

    switch ($cmd) {
        'help'  { Show-Help; continue }
        '?'     { Show-Help; continue }
        'exit'  { break mainLoop } 'x' { break mainLoop }
        'quit'  { break mainLoop } 'q' { break mainLoop }
        'cls'  { cls } 'clear' { cls }

        { $_ -in @('listprinters', 'lp') } {
            $p = Parse-Args $args
            $sb = { Get-Printer | Format-Table -AutoSize Name, DriverName, PortName, Shared }
            Invoke-Remote -Script $sb -ComputerName $p.computername
            continue
        }
        { $_ -in @('listports', 'lport') } {
            $p = Parse-Args $args

            $sb = {
                Get-PrinterPort |
                    Select-Object Name, Description, PrinterHostAddress |
                    Format-Table -AutoSize
            }

            Invoke-Remote -Script $sb -ComputerName $p.computername
            continue
        }
        { $_ -in @('listdrivers', 'ldrv') } {
            $p = Parse-Args $args

            $sb = {
                Get-PrinterDriver |
                    Select-Object Name, Manufacturer, Version |
                    Sort-Object Name |
                    Format-Table -AutoSize
            }

            Invoke-Remote -Script $sb -ComputerName $p.computername
            continue
        }
        { $_ -in @('addprinter', 'ap') } {
            $p = Parse-Args $args

            if (-not $p.name -or -not $p.driver -or -not $p.port) {
                Write-Host "Missing parameters. Use: addprinter -name <Name> -driver <Driver> -port <Port> [-computername <C>]" -ForegroundColor Red
                continue
            }

            $sb = {
                param($nm, $drv, $prt)
                try {
                    Add-Printer -Name $nm -DriverName $drv -PortName $prt -ErrorAction Stop
                    Write-Host "Printer '$nm' added." -ForegroundColor Green
                } catch {
                    Write-Host "Failed to add printer: $($_.Exception.Message)" -ForegroundColor Red
                }
            }.GetNewClosure()

            Invoke-Remote -Script $sb -ComputerName $p.computername -ArgumentList $p.name,$p.driver,$p.port
            continue
        }
        { $_ -in @('renameprinter', 'rp') } {
            $p = Parse-Args $args

            if (-not $p.old -or -not $p.new) {
                Write-Host "Missing old or -new switch." -ForegroundColor Red
                continue
            }

            $sb = {
                param($old, $new)
                try {
                    Rename-Printer -Name $old -NewName $new -ErrorAction Stop
                    Write-Host "Printer renamed from '$old' to '$new'." -ForegroundColor Green
                } catch {
                    Write-Host "Failed to rename printer: $($_.Exception.Message)" -ForegroundColor Red
                }
            }.GetNewClosure()

            Invoke-Remote -Script $sb -ComputerName $p.computername -ArgumentList $p.old,$p.new
            continue
        }
        { $_ -in @('deleteprinter', 'dp') } {
            $p = Parse-Args $args
            
            if (-not $p.name) {
                Write-Host "Missing name switch." -ForegroundColor Red
                continue
            }

            $sb = {
                param($nm)
                try {
                    Remove-Printer -Name $nm -ErrorAction Stop
                    Write-Host "Printer '$nm' removed." -ForegroundColor Green
                } catch {
                    Write-Host "Failed to remove printer: $($_.Exception.Message)" -ForegroundColor Red
                }
            }.GetNewClosure()

            Invoke-Remote -Script $sb -ComputerName $p.computername -ArgumentList $p.name
            continue
        }
        { $_ -in @('selectcomputer', 'sc') } {
            $p = Parse-Args $args
            if (-not $p.name) {
                Write-Host "Missing computer name switch." -ForegroundColor Red
                continue
            }

            Select-Computer -Name $p.name
            continue
        }
        default {
            Write-Host "Unrecognised command: $cmd. Type 'help' for a list." -ForegroundColor Yellow
        }
    }

    Write-Host ""
}