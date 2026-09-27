<#
.SYNOPSIS
    Animated toolchain checker for Node.js, npm, Git on Windows (winget).
#>

# --- Configuration ---
$TargetNodeMajor = 20

# --- Color helpers ---
function Write-Info    { param($Msg) Write-Host "  " -NoNewline; Write-Host "✔" -ForegroundColor Green -NoNewline; Write-Host " $Msg" }
function Write-Warn    { param($Msg) Write-Host "  " -NoNewline; Write-Host "⚠" -ForegroundColor Yellow -NoNewline; Write-Host " $Msg" }
function Write-Err     { param($Msg) Write-Host "  " -NoNewline; Write-Host "✘" -ForegroundColor Red -NoNewline; Write-Host " $Msg" -ForegroundColor Red }
function Write-Step    { param($Msg) Write-Host ""; Write-Host "▶ $Msg" -ForegroundColor Cyan -NoNewline; Write-Host ""; Write-Host "" }

# --- Platform check ---
if (-not $IsWindows -and $PSVersionTable.Platform -ne "Win32NT") {
    Write-Err "This script is intended for Windows systems."
    exit 1
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Err "winget (Windows Package Manager) not found."
    Write-Err "Install from the Microsoft Store (App Installer)."
    exit 1
}

function Test-Command {
    param([string]$Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# --- Spinner ---
function Show-Spinner {
    param(
        [scriptblock]$Script,
        [string]$Message,
        [int]$TimeoutSec = 600
    )

    $frames = @('⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏')
    $job = Start-Job -ScriptBlock $Script
    $i = 0
    $start = Get-Date

    while ($job.State -eq 'Running') {
        if (((Get-Date) - $start).TotalSeconds -gt $TimeoutSec) {
            Stop-Job $job; Remove-Job $job
            throw "Spinner timed out after ${TimeoutSec}s"
        }
        $frame = $frames[$i % $frames.Count]
        Write-Host "`r  " -NoNewline
        Write-Host $frame -ForegroundColor Cyan -NoNewline
        Write-Host " $Message" -NoNewline
        Start-Sleep -Milliseconds 80
        $i++
    }

    # Clear line and print result
    Write-Host "`r$(' ' * ($Message.Length + 6))`r" -NoNewline

    $result = Receive-Job $job
    Remove-Job $job
    return $result
}

# --- Progress bar ---
function Show-ProgressBar {
    param(
        [int]$DurationMs = 800,
        [string]$Message = "Working",
        [int]$Width = 40
    )

    $steps = 50
    $delay = [int]($DurationMs / $steps)
    $esc = [char]27

    for ($i = 0; $i -le $steps; $i++) {
        $filled = [int]($i * $Width / $steps)
        $empty  = $Width - $filled
        $pct = [int]($i * 100 / $steps)

        $bar = ("█" * $filled) + ("░" * $empty)
        Write-Host "`r  $Message [" -NoNewline
        Write-Host ("█" * $filled) -ForegroundColor Green -NoNewline
        Write-Host ("░" * $empty) -ForegroundColor DarkGray -NoNewline
        Write-Host ("] {0,3}%" -f $pct) -NoNewline
        Start-Sleep -Milliseconds $delay
    }
    Write-Host ""
}

# --- Typewriter effect ---
function Write-Typewriter {
    param(
        [string]$Text,
        [int]$DelayMs = 20,
        [string]$Color = "White"
    )
    foreach ($ch in $Text.ToCharArray()) {
        Write-Host $ch -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $DelayMs
    }
    Write-Host ""
}

# --- Banner ---
Clear-Host
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║   ⚙️   TOOLCHAIN CHECKER — Node · npm · Git   ║" -ForegroundColor Magenta
Write-Host "  ╚═══════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Typewriter "  Initializing environment scan..." 15 "DarkGray"
Write-Host ""

# --- Git ---
function Invoke-GitCheck {
    Write-Step "Checking Git"
    if (Test-Command "git") {
        $v = (git --version) -replace 'git version ', ''
        Write-Info "Git detected — version $v"

        $result = Show-Spinner -Message "Checking for Git updates..." -Script {
            winget upgrade --id Git.Git -e --source winget --silent --accept-package-agreements --accept-source-agreements 2>&1
        }
        if ($result -match "Successfully installed") {
            Write-Info "Git updated → $(git --version)"
        } else {
            Write-Info "Git is up to date"
        }
    } else {
        Write-Warn "Git not found — installing..."
        Show-Spinner -Message "Installing Git via winget..." -Script {
            winget install --id Git.Git -e --source winget --silent --accept-package-agreements --accept-source-agreements 2>&1
        } | Out-Null
        Write-Info "Git installed → $(git --version)"
    }
}

# --- Node.js ---
function Install-NodeLts {
    Show-Spinner -Message "Installing Node.js LTS via winget..." -Script {
        winget install --id OpenJS.NodeJS.LTS -e --source winget --silent --accept-package-agreements --accept-source-agreements 2>&1
    } | Out-Null
    Write-Info "Node.js installed → $(node --version)"
    Write-Info "npm installed     → $(npm --version)"
}

function Invoke-NodeCheck {
    Write-Step "Checking Node.js"
    if (Test-Command "node") {
        $v = (node --version) -replace 'v', ''
        Write-Info "Node.js detected — version v$v"
        $major = [int]($v -split '\.')[0]

        if ($major -lt $TargetNodeMajor) {
            Write-Warn "Node.js v$major is behind LTS ($TargetNodeMajor) — updating..."
            Show-Spinner -Message "Upgrading Node.js via winget..." -Script {
                winget upgrade --id OpenJS.NodeJS.LTS -e --source winget --silent --accept-package-agreements --accept-source-agreements 2>&1
            } | Out-Null
            Write-Info "Node.js updated → $(node --version)"
        } else {
            Write-Info "Node.js is at or above LTS — no update needed"
        }
    } else {
        Write-Warn "Node.js not found — installing..."
        Install-NodeLts
    }
}

# --- npm ---
function Invoke-NpmCheck {
    Write-Step "Checking npm"
    if (-not (Test-Command "npm")) {
        Write-Warn "npm not found — reinstalling Node.js..."
        Install-NodeLts
    }

    $current = (npm --version).Trim()
    Write-Info "npm detected — version $current"

    $latest = $null
    try { $latest = (npm view npm version 2>$null).Trim() } catch { }

    if ($latest -and ($current -ne $latest)) {
        Write-Warn "Updating npm $current → $latest"
        Show-Spinner -Message "Fetching npm@latest..." -Script {
            npm install -g npm@latest 2>&1 | Out-Null
        } | Out-Null
        Write-Info "npm updated → $(npm --version)"
    } else {
        Write-Info "npm is up to date"
    }
}

# --- Run checks ---
Invoke-GitCheck
Invoke-NodeCheck
Invoke-NpmCheck

# --- Summary ---
Write-Step "Summary"
Show-ProgressBar -DurationMs 800 -Message "Finalizing"
Write-Host ""

$gitV  = if (Test-Command "git")  { (git --version) -replace 'git version ','v' } else { "NOT FOUND" }
$nodeV = if (Test-Command "node") { node --version } else { "NOT FOUND" }
$npmV  = if (Test-Command "npm")  { npm --version }  else { "NOT FOUND" }

Write-Host "  ┌─────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host ("  │  {0,-8} {1,-22} │" -f "Git:",  $gitV)  -ForegroundColor Cyan
Write-Host ("  │  {0,-8} {1,-22} │" -f "Node:", $nodeV) -ForegroundColor Cyan
Write-Host ("  │  {0,-8} {1,-22} │" -f "npm:",  $npmV)  -ForegroundColor Cyan
Write-Host "  └─────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""
Write-Typewriter "  ✅ All checks complete." 20 "Green"
Write-Host ""
