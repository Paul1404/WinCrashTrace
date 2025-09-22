<#
.SYNOPSIS
  WinCrashTrace - Windows Support Bundle Generator

.DESCRIPTION
  Collects crash-related diagnostics (events, dumps, hardware errors, 
  drivers, hotfixes, system info) and packages them into a ZIP bundle
  suitable for vendor support (Dell, Microsoft).

.OUTPUTS
  ZIP file in Downloads folder (WinCrashTrace-Bundle-YYYYMMDD-HHMMSS.zip)

.AUTHOR
  Paul Dresch & T3 Chat
#>

[CmdletBinding()]
param()

# -----------------------------------------------------------------------------
# Helper: Console logging with colors
# -----------------------------------------------------------------------------
function Write-Info($msg)  { Write-Host "ℹ $msg" -ForegroundColor Cyan }
function Write-Ok($msg)    { Write-Host "✔ $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "⚠ $msg" -ForegroundColor Yellow }
function Write-ErrorMsg($msg) { Write-Host "✖ $msg" -ForegroundColor Red }

# -----------------------------------------------------------------------------
# Helper: Downloads path and bundle directory
# -----------------------------------------------------------------------------
function Get-DownloadsPath {
    $downloads = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
    if (-not (Test-Path $downloads)) { $downloads = "." }
    return $downloads
}

$downloads = Get-DownloadsPath
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$bundleName = "WinCrashTrace-Bundle-$timestamp"
$bundleDir = Join-Path $downloads $bundleName
$zipPath = "$bundleDir.zip"
New-Item -ItemType Directory -Path $bundleDir -Force | Out-Null

# -----------------------------------------------------------------------------
# Collectors
# -----------------------------------------------------------------------------
function Get-SystemInfo {
    $cs   = Get-CimInstance Win32_ComputerSystem
    $os   = Get-CimInstance Win32_OperatingSystem
    $bios = Get-CimInstance Win32_BIOS
    $cpu  = Get-CimInstance Win32_Processor | Select-Object -First 1 Name,
                NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
    $ram  = [Math]::Round(($cs.TotalPhysicalMemory / 1GB),2)

    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        Manufacturer = $cs.Manufacturer
        Model        = $cs.Model
        BIOSVersion  = ($bios.SMBIOSBIOSVersion -join " ")
        BIOSDate     = $bios.ReleaseDate
        SerialNumber = $bios.SerialNumber
        OSVersion    = "$($os.Caption) $($os.Version) (Build $($os.BuildNumber))"
        InstallDate  = $os.InstallDate
        LastBoot     = $os.LastBootUpTime
        Uptime       = (New-TimeSpan -Start $os.LastBootUpTime -End (Get-Date)).ToString("dd\.hh\:mm\:ss")
        UserLoggedIn = $cs.UserName
        CPU          = $cpu.Name
        Cores        = $cpu.NumberOfCores
        Threads      = $cpu.NumberOfLogicalProcessors
        MaxClockMHz  = $cpu.MaxClockSpeed
        MemoryGB     = $ram
    }
}

function Get-CrashEvents {
    # Crash-related Event IDs
    $eventIds = @(41, 1001, 6008)
    Get-WinEvent -FilterHashtable @{ LogName='System'; Id=$eventIds } `
        -MaxEvents 500 -ErrorAction SilentlyContinue |
        Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message
}

function Get-WheaEvents {
    Get-WinEvent -FilterHashtable @{ LogName='System'; Id=@(18,19,20)} `
        -MaxEvents 200 -ErrorAction SilentlyContinue |
        Select-Object TimeCreated, Id, ProviderName, Message
}

function Get-HotfixList {
    Get-HotFix | Select-Object HotFixID, Description, InstalledOn
}

function Get-DriverList {
    Get-CimInstance Win32_PnPSignedDriver |
        Select-Object DeviceName, DriverVersion, DriverDate, Manufacturer
}

function Get-CrashDumps {
    $dumpPaths = @("$env:SystemRoot\Minidump", "$env:SystemRoot\MEMORY.DMP")
    foreach ($path in $dumpPaths) {
        if (Test-Path $path) {
            Get-ChildItem -Path $path -ErrorAction SilentlyContinue |
                Select-Object FullName,
                              @{n="SizeMB";e={[math]::Round($_.Length/1MB,2)}},
                              LastWriteTime
        }
    }
}

# -----------------------------------------------------------------------------
# RCA Summary
# -----------------------------------------------------------------------------
function Get-Summary {
    param($SystemInfo,$Crashes,$Whea,$Dumps)

    $out = @()
    $out += "SUMMARY (Auto-Generated)"
    $out += "------------------------"

    $crashCount = ($Crashes | Measure-Object).Count
    if ($crashCount -eq 0) {
        $out += "No crash events found in System log."
    } else {
        $firstCrash = ($Crashes | Sort-Object TimeCreated | Select-Object -First 1).TimeCreated
        $lastCrash  = ($Crashes | Sort-Object TimeCreated -Descending | Select-Object -First 1).TimeCreated
        $spanDays   = [Math]::Round(((New-TimeSpan -Start $firstCrash -End $lastCrash).TotalDays),1)
        $out += "Number of crashes observed : $crashCount"
        $out += "First crash recorded       : $firstCrash"
        $out += "Last crash recorded        : $lastCrash"
        $out += "Crash observation span     : $spanDays days"
    }

    if ($Whea) {
        $wheaCount = ($Whea | Measure-Object).Count
        $out += "Hardware/WHEA-related events: $wheaCount"
        $out += "Check for possible hardware/firmware or driver issues."
    } else {
        $out += "No WHEA/Hardware error events found."
    }

    if ($Dumps) {
        $out += "Crash dumps found           : Yes ($(($Dumps | Measure-Object).Count) files)"
    } else {
        $out += "Crash dumps found           : No dump files present"
    }

    # BIOS vs Install age check
    if ($SystemInfo.BIOSDate) {
        $biosAge = (New-TimeSpan -Start $SystemInfo.BIOSDate -End (Get-Date)).Days
        if ($biosAge -gt 365) {
            $out += "NOTE: BIOS is older than 1 year ($biosAge days) → consider checking vendor for updates."
        }
    }

    return ($out -join "`r`n")
}

# -----------------------------------------------------------------------------
# Report Writer
# -----------------------------------------------------------------------------
function New-SupportReport {
    param($SystemInfo,$Crashes,$Whea,$Dumps,$ReportFile)

    $summary = Get-Summary -SystemInfo $SystemInfo -Crashes $Crashes -Whea $Whea -Dumps $Dumps

    $out = @()
    $out += "==============================="
    $out += " WinCrashTrace Support Report"
    $out += " Generated: $(Get-Date)"
    $out += "==============================="
    $out += ""
    $out += $summary
    $out += ""
    $out += "---- System Information ----"
    $out += ($SystemInfo | Format-List | Out-String)
    $out += ""
    $out += "---- Crash Events ----"
    $out += ($Crashes | Format-List | Out-String)
    $out += ""
    $out += "---- WHEA (Hardware Errors) ----"
    if ($Whea) { $out += ($Whea | Format-List | Out-String) } else { $out += "No WHEA hardware errors found." }
    $out += ""
    $out += "---- Crash Dumps ----"
    if ($Dumps) { $out += ($Dumps | Format-Table -AutoSize | Out-String) } else { $out += "No crash dumps found." }

    Set-Content -Path $ReportFile -Value ($out -join "`r`n") -Encoding UTF8 -Force
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------
Write-Info "Collecting system information..."
$sysInfo = Get-SystemInfo

Write-Info "Collecting crash events..."
$crashes = Get-CrashEvents

Write-Info "Collecting WHEA hardware errors..."
$whea = Get-WheaEvents

Write-Info "Collecting crash dump metadata..."
$dumps = Get-CrashDumps

Write-Info "Collecting installed hotfixes..."
$hotfixes = Get-HotfixList
$hotfixFile = Join-Path $bundleDir "Hotfixes.csv"
$hotfixes | Export-Csv -Path $hotfixFile -NoTypeInformation -Encoding UTF8

Write-Info "Collecting driver list..."
$drivers = Get-DriverList
$driverFile = Join-Path $bundleDir "Drivers.csv"
$drivers | Export-Csv -Path $driverFile -NoTypeInformation -Encoding UTF8

# Main report
$reportFile = Join-Path $bundleDir "SupportReport.txt"
New-SupportReport -SystemInfo $sysInfo -Crashes $crashes -Whea $whea -Dumps $dumps -ReportFile $reportFile

# Export supporting CSVs
$crashCsv = Join-Path $bundleDir "CrashEvents.csv"
$crashes | Export-Csv -Path $crashCsv -NoTypeInformation -Encoding UTF8
$dumpFile = Join-Path $bundleDir "CrashDumps.csv"
if ($dumps) { $dumps | Export-Csv -Path $dumpFile -NoTypeInformation -Encoding UTF8 }

# Zip bundle
Write-Info "Creating bundle ZIP..."
Compress-Archive -Path $bundleDir\* -DestinationPath $zipPath -Force

# Cleanup raw dir
Remove-Item $bundleDir -Recurse -Force

Write-Ok "Support bundle generated!"
Write-Host "   → $zipPath" -ForegroundColor Yellow