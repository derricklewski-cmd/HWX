# Log File Analyzer

A PowerShell automation script that scans application log files, tallies
ERROR / WARNING / INFO entries, surfaces the most frequent error messages,
and produces both a CSV summary and an HTML report.

Built for CSCI-185 Final Project.

## Problem it solves

Developers and sysadmins often have folders full of application logs with
thousands of lines. Reading them by hand is slow and error-prone. This script
automates the scan: run it once (or on a schedule) and get a clear summary of
what went wrong, how often, and when.

## Features

- Recursively scans a folder for `.log` and `.txt` files
- Parses timestamped entries using regular expressions
- Counts entries by level (ERROR, WARNING, INFO, DEBUG, FATAL)
- Surfaces the top N most frequent error messages
- Writes a CSV summary, a full parsed-entries CSV, and a styled HTML report
- Ships with a scheduled-task registration script for daily automated runs

## Requirements

- Windows 10/11 with PowerShell 5.1 or PowerShell 7+
- Read access to the log folder
- (Optional) Admin rights to register the scheduled task

## Usage

From the repo root:

```powershell
# Run against the included sample logs
.\Analyze-Logs.ps1 -LogFolder .\logs -OutputFolder .\reports

# Point at a real log folder and surface the top 10 errors
.\Analyze-Logs.ps1 -LogFolder "C:\MyApp\logs" -OutputFolder ".\reports" -TopN 10
```

Outputs will appear in the `-OutputFolder`:

| File | What it contains |
|---|---|
| `summary.csv` | Count of entries per level |
| `all-entries.csv` | Every parsed entry: timestamp, level, message, source file |
| `report.html` | Styled HTML report with summary + top error patterns |

### Register a daily scheduled task (optional)

Run from an elevated PowerShell prompt:

```powershell
.\Register-Task.ps1 `
    -ScriptPath   "$PWD\Analyze-Logs.ps1" `
    -LogFolder    "$PWD\logs" `
    -OutputFolder "$PWD\reports" `
    -RunAt        "08:00"
```

This registers a task named `CSCI185-LogAnalyzer` that runs daily at 08:00.

To test immediately: `Start-ScheduledTask -TaskName "CSCI185-LogAnalyzer"`
To remove: `Unregister-ScheduledTask -TaskName "CSCI185-LogAnalyzer" -Confirm:$false`

## Sample output

Console:

```
Summary by Level:
Level    Count
-----    -----
INFO     32
ERROR    15
WARNING  8
FATAL    2

Top 5 Error Patterns:
Occurrences Message
----------- -------
          5 Connection refused by upstream service auth-svc
          3 Timeout while calling payment-service
          3 Null reference exception in OrderController.Process
          ...
```

`summary.csv`:

```
"Level","Count"
"INFO","32"
"ERROR","15"
"WARNING","8"
"FATAL","2"
```

`report.html` renders the same data as a styled report with color-coded
severity levels and top error patterns.

## Repo layout

```
.
├── Analyze-Logs.ps1      # main analyzer script
├── Register-Task.ps1     # optional: register Windows scheduled task
├── README.md             # this file
├── logs/                 # sample input logs (also used for demo)
│   ├── app-2026-04-20.log
│   └── app-2026-04-21.log
└── reports/              # generated output (created on run)
    ├── summary.csv
    ├── all-entries.csv
    └── report.html
```

## Required techniques demonstrated

| Requirement | Where |
|---|---|
| File I/O | `Get-Content` for logs; `Export-Csv` / `Set-Content` for reports |
| Loops / conditionals | `foreach` in `Get-LogEntries`, `switch` in HTML styling |
| Functions with parameters | `Get-LogFiles`, `Parse-LogLine`, `Get-TopErrorPatterns`, etc. |
| Pipeline | `Get-ChildItem ... \| Where-Object ... \| Group-Object ... \| Sort-Object ...` |
| Regular expressions | `Parse-LogLine` uses a named-capture regex for timestamp/level/message |
| Automated processing | `Register-Task.ps1` uses `New-ScheduledTaskAction` |

## Team

| Name | GitHub | Contribution |
| Derrick | derricklewski-cmd | 5 substansive commits and two merges
| Nick | NicholasK1800 | technically 2 commits but 1 commit has content of 2 and a merge
