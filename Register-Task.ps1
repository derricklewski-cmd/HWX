<#
.SYNOPSIS
    Registers Analyze-Logs.ps1 as a Windows Scheduled Task that runs daily.

.DESCRIPTION
    Uses New-ScheduledTaskAction + New-ScheduledTaskTrigger to schedule the
    log analyzer automatically. Fulfills the "automated processing" requirement
    of the CSCI-185 final project.

    Run from an elevated PowerShell (Run as Administrator).

.PARAMETER ScriptPath
    Full path to Analyze-Logs.ps1.

.PARAMETER LogFolder
    Folder that will be scanned each run.

.PARAMETER OutputFolder
    Folder that receives the generated reports.

.PARAMETER RunAt
    Time of day (24h) to run, e.g. "08:00". Default = 08:00.

.PARAMETER TaskName
    Name to register the task under. Default = "CSCI185-LogAnalyzer".

.EXAMPLE
    .\Register-Task.ps1 `
        -ScriptPath   "C:\projects\log-analyzer\Analyze-Logs.ps1" `
        -LogFolder    "C:\projects\log-analyzer\logs" `
        -OutputFolder "C:\projects\log-analyzer\reports" `
        -RunAt        "07:30"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ScriptPath,
    [Parameter(Mandatory)][string]$LogFolder,
    [Parameter(Mandatory)][string]$OutputFolder,
    [string]$RunAt    = "08:00",
    [string]$TaskName = "CSCI185-LogAnalyzer"
)

if (-not (Test-Path $ScriptPath)) {
    Write-Error "Script not found: $ScriptPath"
    exit 1
}

$pwshArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" -LogFolder `"$LogFolder`" -OutputFolder `"$OutputFolder`""

$action    = New-ScheduledTaskAction    -Execute "powershell.exe" -Argument $pwshArgs
$trigger   = New-ScheduledTaskTrigger   -Daily -At $RunAt
$settings  = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries

# Remove a prior registration of the same name, if any
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

Register-ScheduledTask `
    -TaskName    $TaskName `
    -Action      $action `
    -Trigger     $trigger `
    -Settings    $settings `
    -Description "Daily CSCI-185 log analyzer run" | Out-Null

Write-Host "Registered scheduled task '$TaskName' to run daily at $RunAt." -ForegroundColor Green
Write-Host "To test immediately: Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "To remove:           Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"
