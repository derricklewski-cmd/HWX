# Project Guide — How to land this by April 28

This is your internal plan (keep it out of the graded repo, or rename it if
your instructor wants it included). It covers the one-week timeline, how to
split work with your teammate so both of you get your required 3+ commits
with branches/PRs, and the presentation outline.

## One-week schedule (today is Tue Apr 21)

| Day | What happens |
|---|---|
| Tue Apr 21 | Create repo, both clone, push starter files, divide tasks. First commits today. |
| Wed Apr 22 | Each person works on their assigned feature branch. Open draft PRs. |
| Thu Apr 23 | Review each other's PRs. Merge. Add a second round of improvements on new branches. |
| Fri Apr 24 | Polish: edge cases, extra log files, nicer HTML, test the scheduled task. Commit. |
| Sat Apr 25 | Freeze code. Write `HWX.pdf` deliverable (repo link, GitHub IDs, contributions). |
| Sun Apr 26 | Rehearse the presentation end-to-end. Run the live demo a few times. |
| Mon Apr 27 | Final rehearsal; fix any last-minute issues; push tagged `v1.0` release. |
| Tue Apr 28 | Present. |

## How to split the work (Group of 2)

The goal is that both of you end up with 3+ meaningful commits on
separate branches that get merged via PR.

### Derrick (you) — "Core analyzer" track

Branch name suggestion: `feat/analyzer-core`

- Commit 1 — Add `Analyze-Logs.ps1` skeleton with parameter block and main
  flow (no parsing yet).
- Commit 2 — Add `Parse-LogLine` + regex; add `Get-LogFiles` and
  `Get-LogEntries`.
- Commit 3 — Add `Get-LevelSummary`, `Get-TopErrorPatterns`, and CSV export.
- (Optional 4th) — Handle edge cases: empty folder, unparseable lines.

### Teammate — "Reporting + automation" track

Branch name suggestion: `feat/html-report-and-scheduler`

- Commit 1 — Add `Export-HtmlReport` function and wire it into the main
  flow.
- Commit 2 — Add `Register-Task.ps1` (scheduled task registration).
- Commit 3 — Add `README.md` with usage, sample output, team table.
- (Optional 4th) — Add `logs/` sample files and screenshots.

### Workflow

1. One of you creates the repo on GitHub (private is fine unless the rubric
   says otherwise) and pushes an initial commit with just this folder
   structure and an empty `README.md`.
2. Add your teammate as a collaborator in GitHub **Settings → Collaborators**.
3. Both clone: `git clone https://github.com/your-org/log-analyzer.git`
4. Each person creates their branch:
   ```bash
   git checkout -b feat/analyzer-core
   # ... edit files ...
   git add Analyze-Logs.ps1
   git commit -m "Add analyzer skeleton with parameters and main flow"
   git push -u origin feat/analyzer-core
   ```
5. Open a Pull Request on GitHub. The other person reviews, comments, and
   approves. Then merge.
6. Repeat for each commit chunk. This naturally produces the "evidence of
   branching or pull requests" the rubric asks for.

### Commit message style (examples of clear messages)

Good:
- `Add Parse-LogLine with named-capture regex for timestamp/level/message`
- `Write CSV summary of entry counts by level`
- `Register scheduled task to run analyzer daily at 08:00`
- `Fix: treat WARN as WARNING so counts don't split`

Avoid:
- `updates`
- `fix stuff`
- `final`

## Presentation outline (10–15 min)

| Section | Minutes | Who |
|---|---|---|
| 1. Problem / use case | 1 | Derrick |
| 2. How the script works — architecture walkthrough | 2 | Teammate |
| 3. Code walkthrough — regex, pipeline, functions | 3 | Both (alternate) |
| 4. Live demo — run against sample logs, open HTML report | 3 | Derrick |
| 5. Scheduled task demo | 1 | Teammate |
| 6. Git history — `git log --oneline --graph --all` | 2 | Both show their commits |
| 7. Challenges & lessons learned | 1–2 | Both |
| 8. Q&A | remaining | Both |

### Live demo script

Run these exact commands in front of the class:

```powershell
# Show the folder layout
ls

# Run the analyzer
.\Analyze-Logs.ps1 -LogFolder .\logs -OutputFolder .\reports

# Show the CSV output
Import-Csv .\reports\summary.csv | Format-Table -AutoSize

# Open the HTML report in the browser
Invoke-Item .\reports\report.html

# Show the scheduled task (if already registered)
Get-ScheduledTask -TaskName CSCI185-LogAnalyzer | Format-List

# Show the git history
git log --oneline --graph --all
```

### Challenges & lessons learned (talking points to fill in)

- Writing a regex that matches *both* `[ERROR]` and bare `ERROR` log formats
- Deciding how to normalize `WARN` vs `WARNING`
- PowerShell pipeline gotcha: a function returning `$null` still emits to the
  pipeline unless you filter with `Where-Object { $_ -ne $null }`
- HTML encoding — making sure angle brackets in messages don't break the
  rendered report
- Coordinating branches/PRs — first time using PRs for collaboration
- Getting execution policy right for the scheduled task
  (`-ExecutionPolicy Bypass`)

## HWX.pdf deliverable checklist

The rubric asks for a PDF in `/shared_folder/HWX/` with:

- [ ] GitHub repository link
- [ ] Team names
- [ ] Each member's GitHub ID
- [ ] Each member's contribution summary (2–3 sentences per person)

Keep it to one page. Export it from Word or Google Docs.

## Rubric self-check (before presenting)

- [ ] Written in PowerShell — ✓ (`Analyze-Logs.ps1`)
- [ ] Automated processing — ✓ (`Register-Task.ps1` uses `New-ScheduledTaskAction`)
- [ ] File I/O — ✓ (reads `.log`, writes `.csv` + `.html`)
- [ ] Loops & conditionals — ✓ (`foreach` + `switch` in HTML styling)
- [ ] Functions with parameters — ✓ (6+ defined)
- [ ] Pipeline usage — ✓ (`Get-ChildItem | Where-Object | Group-Object | Sort-Object`)
- [ ] Regular expressions — ✓ (named-capture regex in `Parse-LogLine`)
- [ ] Produces report file — ✓ (`.csv` and `.html`)
- [ ] 3+ commits per contributor
- [ ] Branching / pull requests
- [ ] Clear commit messages
- [ ] `README.md` with title, description, usage, sample output
- [ ] Sample output file in repo (the CSV / HTML from a run)
