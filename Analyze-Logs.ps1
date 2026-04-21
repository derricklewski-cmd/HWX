<#
.SYNOPSIS
    Log File Analyzer - scans application log files and produces a summary report.

.DESCRIPTION
    Reads one or more .log/.txt files from a folder, counts ERROR / WARNING / INFO
    entries, extracts timestamps, identifies the most frequent error messages,
    and writes CSV + HTML summary reports to an output folder.

    Designed for CSCI-185 Final Project. Demonstrates:
      * File I/O   (reads .log files, writes .csv and .html)
      * Loops/conditionals
      * Functions with parameters
      * Pipeline usage (Get-ChildItem | Where-Object | Group-Object | Sort-Object ...)
      * Regular expressions (timestamp + level parsing)

.PARAMETER LogFolder
    Folder containing .log / .txt files to scan. Defaults to .\logs

.PARAMETER OutputFolder
    Folder to write the reports into. Defaults to .\reports

.PARAMETER TopN
    How many most-frequent error messages to surface. Default = 5.

.EXAMPLE
    .\Analyze-Logs.ps1
    .\Analyze-Logs.ps1 -LogFolder C:\app\logs -OutputFolder C:\app\reports -TopN 10
#>

[CmdletBinding()]
param(
    [string]$LogFolder    = ".\logs",
    [string]$OutputFolder = ".\reports",
    [int]   $TopN         = 5
)

# ---------- Functions ----------

function Get-LogFiles {
    # Pipeline usage: Get-ChildItem piped into Where-Object
    param([Parameter(Mandatory)][string]$Path)

    Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in '.log', '.txt' }
}

function Parse-LogLine {
    <#
        Regex captures three named groups:
          timestamp : yyyy-MM-dd HH:mm:ss  (or with 'T')
          level     : ERROR | WARN | WARNING | INFO | DEBUG | FATAL
          message   : rest of the line
    #>
    param([string]$Line)

    $pattern = '^(?<timestamp>\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2})\s*\[?(?<level>ERROR|WARNING|WARN|INFO|DEBUG|FATAL)\]?\s*[:\-]?\s*(?<message>.*)$'

    if ($Line -match $pattern) {
        # Normalize WARN -> WARNING so counts line up
        $lvl = $matches['level']
        if ($lvl -eq 'WARN') { $lvl = 'WARNING' }

        [PSCustomObject]@{
            Timestamp = $matches['timestamp']
            Level     = $lvl
            Message   = $matches['message'].Trim()
        }
    }
}

function Get-LogEntries {
    param([Parameter(Mandatory)][System.IO.FileInfo[]]$Files)

    foreach ($file in $Files) {
        Get-Content -Path $file.FullName |
            ForEach-Object { Parse-LogLine -Line $_ } |
            Where-Object   { $_ -ne $null } |
            ForEach-Object {
                $_ | Add-Member -NotePropertyName SourceFile -NotePropertyValue $file.Name -PassThru
            }
    }
}

function Get-LevelSummary {
    param([Parameter(Mandatory)]$Entries)

    $Entries |
        Group-Object -Property Level |
        Sort-Object  -Property Count -Descending |
        ForEach-Object { [PSCustomObject]@{ Level = $_.Name; Count = $_.Count } }
}

function Get-TopErrorPatterns {
    param(
        [Parameter(Mandatory)]$Entries,
        [int]$Count = 5
    )

    $Entries |
        Where-Object { $_.Level -eq 'ERROR' -or $_.Level -eq 'FATAL' } |
        Group-Object -Property Message |
        Sort-Object  -Property Count -Descending |
        Select-Object -First $Count |
        ForEach-Object {
            [PSCustomObject]@{
                Occurrences = $_.Count
                Message     = $_.Name
            }
        }
}

function HtmlEncode {
    param([string]$Text)
    if (-not $Text) { return '' }
    $Text -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;'
}

function Export-HtmlReport {
    param(
        [Parameter(Mandatory)]$Summary,
        [Parameter(Mandatory)]$TopErrors,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$SourceFolder,
        [Parameter(Mandatory)][int]$FileCount,
        [Parameter(Mandatory)][int]$EntryCount
    )

    $now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    $rowsSummary = foreach ($row in $Summary) {
        $cls = switch ($row.Level) {
            'ERROR'   { 'error' }
            'FATAL'   { 'error' }
            'WARNING' { 'warn'  }
            default   { 'info'  }
        }
        "<tr><td class='$cls'>$($row.Level)</td><td>$($row.Count)</td></tr>"
    }

    $rowsTop = foreach ($e in $TopErrors) {
        "<tr><td>$($e.Occurrences)</td><td>$(HtmlEncode $e.Message)</td></tr>"
    }

    $html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Log Analysis Report</title>
<style>
body { font-family: Segoe UI, Arial, sans-serif; margin: 30px; color: #222; }
h1 { border-bottom: 2px solid #333; padding-bottom: 6px; }
h2 { margin-top: 28px; }
table { border-collapse: collapse; margin: 10px 0; }
th, td { border: 1px solid #ccc; padding: 8px 14px; text-align: left; }
th { background: #2c3e50; color: #fff; }
.error { color: #c0392b; font-weight: bold; }
.warn  { color: #e67e22; font-weight: bold; }
.info  { color: #27ae60; }
.summary-box { background: #f4f6f8; border-left: 4px solid #2c3e50; padding: 12px 16px; }
.small { color: #666; font-size: 0.9em; }
</style>
</head>
<body>
<h1>Log Analysis Report</h1>
<div class="summary-box">
  <div><b>Generated:</b> $now</div>
  <div><b>Source folder:</b> $(HtmlEncode $SourceFolder)</div>
  <div><b>Files scanned:</b> $FileCount</div>
  <div><b>Entries parsed:</b> $EntryCount</div>
</div>

<h2>Counts by Level</h2>
<table>
  <tr><th>Level</th><th>Count</th></tr>
  $($rowsSummary -join "`n  ")
</table>

<h2>Top Error Patterns</h2>
<table>
  <tr><th>Occurrences</th><th>Message</th></tr>
  $($rowsTop -join "`n  ")
</table>

<p class="small">Generated by Analyze-Logs.ps1</p>
</body>
</html>
"@

    $html | Set-Content -Path $Path -Encoding UTF8
}

# ---------- Main ----------

Write-Host "Log File Analyzer" -ForegroundColor Cyan
Write-Host "-----------------"

if (-not (Test-Path $LogFolder)) {
    Write-Error "Log folder not found: $LogFolder"
    exit 1
}

if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$files = Get-LogFiles -Path $LogFolder
if (-not $files -or $files.Count -eq 0) {
    Write-Warning "No .log or .txt files found in $LogFolder"
    exit 0
}

Write-Host "Found $($files.Count) file(s) in $LogFolder. Parsing..." -ForegroundColor Cyan

$entries = @(Get-LogEntries -Files $files)

if ($entries.Count -eq 0) {
    Write-Warning "No parseable log entries found."
    exit 0
}

$summary   = Get-LevelSummary     -Entries $entries
$topErrors = Get-TopErrorPatterns -Entries $entries -Count $TopN

# Write CSVs
$csvSummary = Join-Path $OutputFolder 'summary.csv'
$csvAll     = Join-Path $OutputFolder 'all-entries.csv'
$summary | Export-Csv -Path $csvSummary -NoTypeInformation -Encoding UTF8
$entries | Export-Csv -Path $csvAll     -NoTypeInformation -Encoding UTF8

# Write HTML
$htmlPath = Join-Path $OutputFolder 'report.html'
Export-HtmlReport `
    -Summary      $summary `
    -TopErrors    $topErrors `
    -Path         $htmlPath `
    -SourceFolder (Resolve-Path $LogFolder).Path `
    -FileCount    $files.Count `
    -EntryCount   $entries.Count

# Console output
Write-Host ""
Write-Host "Summary by Level:" -ForegroundColor Yellow
$summary | Format-Table -AutoSize
Write-Host "Top $TopN Error Patterns:" -ForegroundColor Yellow
$topErrors | Format-Table -AutoSize

Write-Host "Reports written to:" -ForegroundColor Green
Write-Host "  $csvSummary"
Write-Host "  $csvAll"
Write-Host "  $htmlPath"
