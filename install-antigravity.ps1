#Requires -Version 5.1

<#
.SYNOPSIS
Installs and verifies Google Antigravity CLI on Windows.

.DESCRIPTION
Downloads and executes Google's official Antigravity CLI installer,
then verifies that the `agy` command is available.

```
Official installer:
https://antigravity.google/cli/install.ps1
```

#>

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------

# Configuration

# ------------------------------------------------------------

$InstallerUrl = "https://antigravity.google/cli/install.ps1"

# ------------------------------------------------------------

# Helpers

# ------------------------------------------------------------

function Write-Info {
param([string]$Message)

```
Write-Host "  " -NoNewline
Write-Host "✔" -ForegroundColor Green -NoNewline
Write-Host " $Message"
```

}

function Write-Warn {
param([string]$Message)

```
Write-Host "  " -NoNewline
Write-Host "⚠" -ForegroundColor Yellow -NoNewline
Write-Host " $Message"
```

}

function Write-Err {
param([string]$Message)

```
Write-Host "  " -NoNewline
Write-Host "✘" -ForegroundColor Red -NoNewline
Write-Host " $Message" -ForegroundColor Red
```

}

function Write-Step {
param([string]$Message)

```
Write-Host ""
Write-Host "▶ $Message" -ForegroundColor Cyan
Write-Host ""
```

}

# ------------------------------------------------------------

# Banner

# ------------------------------------------------------------

Clear-Host

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║       GOOGLE ANTIGRAVITY INSTALLER           ║" -ForegroundColor Magenta
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# ------------------------------------------------------------

# Windows check

# ------------------------------------------------------------

Write-Step "Checking Windows environment"

if (-not $IsWindows -and $PSVersionTable.Platform -ne "Win32NT") {
Write-Err "This script is intended for Windows."
exit 1
}

Write-Info "Windows detected"

# ------------------------------------------------------------

# PowerShell version

# ------------------------------------------------------------

Write-Step "Checking PowerShell"

Write-Info "PowerShell version $($PSVersionTable.PSVersion)"

# ------------------------------------------------------------

# Internet connectivity

# ------------------------------------------------------------

Write-Step "Checking internet connection"

try {
$response = Invoke-WebRequest `        -Uri "https://antigravity.google"`
-Method Head `        -UseBasicParsing`
-TimeoutSec 10

```
Write-Info "Internet connection available"
```

}
catch {
Write-Err "Unable to reach antigravity.google"
Write-Err "Check your internet connection and try again."
exit 1
}

# ------------------------------------------------------------

# Check existing installation

# ------------------------------------------------------------

Write-Step "Checking existing Antigravity installation"

$agyCommand = Get-Command agy -ErrorAction SilentlyContinue

if ($null -ne $agyCommand) {

```
try {
    $version = & agy --version 2>$null

    Write-Info "Antigravity CLI is already installed"
    Write-Info "Version: $version"

    Write-Host ""
    Write-Info "Running the official installer to check for updates..."
}
catch {
    Write-Warn "Antigravity command exists but version could not be detected."
}
```

}
else {
Write-Warn "Antigravity CLI not found"
Write-Info "Starting installation..."
}

# ------------------------------------------------------------

# Download official installer

# ------------------------------------------------------------

Write-Step "Installing Google Antigravity CLI"

try {

```
Write-Host "  Downloading official installer..." -ForegroundColor DarkGray

$installer = Invoke-WebRequest `
    -Uri $InstallerUrl `
    -UseBasicParsing

if (-not $installer.Content) {
    throw "Installer download returned empty content."
}

Write-Info "Official installer downloaded"

# Execute Google's official installer.
Invoke-Expression $installer.Content

Write-Info "Official installer completed"
```

}
catch {
Write-Err "Antigravity installation failed."
Write-Err $_.Exception.Message
exit 1
}

# ------------------------------------------------------------

# Refresh PATH

# ------------------------------------------------------------

Write-Step "Refreshing PATH"

$userPath = [Environment]::GetEnvironmentVariable(
"Path",
"User"
)

$machinePath = [Environment]::GetEnvironmentVariable(
"Path",
"Machine"
)

$env:Path = "$userPath;$machinePath"

Write-Info "PATH refreshed"

# ------------------------------------------------------------

# Expected installation location

# ------------------------------------------------------------

$agyPath = Join-Path $env:LOCALAPPDATA "agy\bin"

if (Test-Path $agyPath) {
Write-Info "Antigravity installation directory found:"
Write-Host "    $agyPath"
}
else {
Write-Warn "Expected Antigravity directory was not found:"
Write-Host "    $agyPath"
}

# ------------------------------------------------------------

# Verify installation

# ------------------------------------------------------------

Write-Step "Verifying Antigravity installation"

$agyCommand = Get-Command agy -ErrorAction SilentlyContinue

if ($null -eq $agyCommand) {

```
Write-Warn "agy was not found in the current terminal PATH."

Write-Host ""
Write-Host "  The installation may have succeeded, but this terminal"
Write-Host "  may still have the old PATH environment."
Write-Host ""

Write-Info "Close this PowerShell window."
Write-Info "Open a new PowerShell window."
Write-Info "Run: agy --version"

exit 0
```

}

try {

```
$version = & agy --version 2>&1

Write-Info "Antigravity CLI detected"
Write-Info "Version: $version"
Write-Info "Executable: $($agyCommand.Source)"
```

}
catch {

```
Write-Err "Antigravity was installed but could not be executed."
exit 1
```

}

# ------------------------------------------------------------

# Summary

# ------------------------------------------------------------

Write-Step "Installation Summary"

Write-Host "  ┌────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "  │  Antigravity CLI                           │" -ForegroundColor Cyan
Write-Host "  │                                            │" -ForegroundColor Cyan
Write-Host ("  │  Version:   {0,-28} │" -f $version) -ForegroundColor Cyan
Write-Host ("  │  Command:   {0,-28} │" -f "agy") -ForegroundColor Cyan
Write-Host ("  │  Location:  {0,-28} │" -f $agyPath) -ForegroundColor Cyan
Write-Host "  └────────────────────────────────────────────┘" -ForegroundColor Cyan

Write-Host ""
Write-Host "  Antigravity is ready." -ForegroundColor Green
Write-Host ""

Write-Host "  To start Antigravity:" -ForegroundColor DarkGray
Write-Host ""
Write-Host "      agy" -ForegroundColor White
Write-Host ""

Write-Host "  To check the version:" -ForegroundColor DarkGray
Write-Host ""
Write-Host "      agy --version" -ForegroundColor White
Write-Host ""

