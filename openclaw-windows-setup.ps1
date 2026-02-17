#Requires -Version 5.1
<#
.SYNOPSIS
    OpenClaw Windows Setup — Automated WSL2 + Ubuntu + Node.js installer.

.DESCRIPTION
    Sets up WSL2, Ubuntu 22.04, Node.js (via nvm), and prepares the
    environment for OpenClaw installation. Handles reboots gracefully
    via a resume marker.

    After this script completes, open Ubuntu from the Start menu and run:
      curl -fsSL https://get.openclaw.ai | bash

.PARAMETER Force
    Skip confirmation prompts (unattended install).

.PARAMETER Resume
    Resume from last completed stage after a reboot.

.PARAMETER Reset
    Clear progress and start fresh.

.EXAMPLE
    # Right-click → Run with PowerShell (recommended)
    .\openclaw-windows-setup.ps1

    # Or from an elevated PowerShell:
    Set-ExecutionPolicy Bypass -Scope Process -Force
    .\openclaw-windows-setup.ps1
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Resume,
    [switch]$Reset
)

# ═══════════════════════════════════════════════════════════════════
# Constants
# ═══════════════════════════════════════════════════════════════════
$Script:Version         = "1.0.0"
$Script:ProgressFile    = "$env:USERPROFILE\.openclaw-windows-progress.json"
$Script:LogFile         = "$env:USERPROFILE\.openclaw\windows-setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$Script:MinWinBuild     = 19041          # Windows 10 May 2020 Update
$Script:UbuntuDistro    = "Ubuntu-22.04"
$Script:NodeVersion     = "22"           # LTS
$Script:DefaultModel    = "opencode/kimi-k2.5-free"
$Script:FallbackModel1  = "anthropic/claude-haiku-4-5"
$Script:FallbackModel2  = "openrouter/qwen/qwen3-coder:free"

# ═══════════════════════════════════════════════════════════════════
# Output helpers
# ═══════════════════════════════════════════════════════════════════
function Write-Step  { param([string]$msg) Write-Host ">>> " -ForegroundColor Cyan -NoNewline; Write-Host $msg -ForegroundColor White }
function Write-Pass  { param([string]$msg) Write-Host "  ✓ " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Write-Fail  { param([string]$msg) Write-Host "  ✗ " -ForegroundColor Red -NoNewline; Write-Host $msg }
function Write-Warn  { param([string]$msg) Write-Host "  ! " -ForegroundColor Yellow -NoNewline; Write-Host $msg }
function Write-Info  { param([string]$msg) Write-Host "  → " -ForegroundColor Cyan -NoNewline; Write-Host $msg }

function Write-Log {
    param([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logDir = Split-Path $Script:LogFile -Parent
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    Add-Content -Path $Script:LogFile -Value "[$timestamp] $msg" -ErrorAction SilentlyContinue
}

# ═══════════════════════════════════════════════════════════════════
# Progress tracking (survives reboots)
# ═══════════════════════════════════════════════════════════════════
function Get-Progress {
    if (Test-Path $Script:ProgressFile) {
        try { return Get-Content $Script:ProgressFile -Raw | ConvertFrom-Json }
        catch { return @{ completedStages = @(); startedAt = (Get-Date -Format o) } }
    }
    return @{ completedStages = @(); startedAt = (Get-Date -Format o) }
}

function Save-Progress {
    param([object]$progress)
    $progress | ConvertTo-Json -Depth 5 | Set-Content $Script:ProgressFile -Force
}

function Complete-Stage {
    param([string]$stage)
    $progress = Get-Progress
    if ($progress.completedStages -notcontains $stage) {
        $progress.completedStages += $stage
    }
    Save-Progress $progress
    Write-Log "Stage completed: $stage"
}

function Test-StageComplete {
    param([string]$stage)
    $progress = Get-Progress
    return ($progress.completedStages -contains $stage)
}

# ═══════════════════════════════════════════════════════════════════
# Prerequisites check
# ═══════════════════════════════════════════════════════════════════
function Test-Prerequisites {
    Write-Step "Checking prerequisites"
    Write-Log "Checking prerequisites"

    # Admin check
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Fail "This script must be run as Administrator"
        Write-Info "Right-click PowerShell → 'Run as administrator', then re-run this script"
        Write-Log "FAIL: Not running as administrator"
        return $false
    }
    Write-Pass "Running as Administrator"

    # Windows version check
    $build = [System.Environment]::OSVersion.Version.Build
    if ($build -lt $Script:MinWinBuild) {
        Write-Fail "Windows build $build is too old (minimum: $Script:MinWinBuild)"
        Write-Info "You need Windows 10 May 2020 Update or later"
        Write-Info "Check your version: press Win+R, type 'winver', press Enter"
        Write-Log "FAIL: Windows build $build < $Script:MinWinBuild"
        return $false
    }
    Write-Pass "Windows build $build (minimum: $Script:MinWinBuild)"

    # Virtualization check
    try {
        $hyperv = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
        if ($hyperv.HypervisorPresent) {
            Write-Pass "Hardware virtualization enabled"
        } else {
            Write-Warn "Hardware virtualization may not be enabled"
            Write-Info "WSL2 requires VT-x (Intel) or AMD-V (AMD) enabled in BIOS"
            Write-Info "If WSL2 fails to install, check your BIOS settings"
            Write-Log "WARN: HypervisorPresent is false"
        }
    } catch {
        Write-Warn "Could not check virtualization status"
    }

    # Internet check
    try {
        $null = Invoke-WebRequest -Uri "https://get.openclaw.ai" -Method Head -TimeoutSec 10 -UseBasicParsing
        Write-Pass "Internet connection available"
    } catch {
        Write-Fail "Cannot reach get.openclaw.ai — check your internet connection"
        Write-Log "FAIL: No internet connectivity"
        return $false
    }

    # Disk space check (need ~2GB for WSL2 + Ubuntu + Node.js)
    $sysDrive = (Get-Item $env:SystemDrive)
    $freeGB = [math]::Round((Get-PSDrive $sysDrive.Name.TrimEnd(':')).Free / 1GB, 1)
    if ($freeGB -lt 2) {
        Write-Fail "Only ${freeGB}GB free on $($sysDrive.Name) (need at least 2GB)"
        Write-Log "FAIL: Only ${freeGB}GB free disk space"
        return $false
    }
    Write-Pass "${freeGB}GB free disk space"

    Write-Log "Prerequisites passed"
    return $true
}

# ═══════════════════════════════════════════════════════════════════
# Stage 1: Enable WSL2
# ═══════════════════════════════════════════════════════════════════
function Install-WSL2 {
    if (Test-StageComplete "wsl2") {
        Write-Info "Skipping: WSL2 already installed"
        return $true
    }

    Write-Step "Installing WSL2"
    Write-Log "Stage: Install-WSL2"

    # Check if WSL is already installed and on version 2
    $wslStatus = $null
    try { $wslStatus = wsl --status 2>&1 } catch {}

    if ($wslStatus -and ($wslStatus -match "Default Version: 2")) {
        Write-Pass "WSL2 is already installed and set as default"
        Complete-Stage "wsl2"
        return $true
    }

    # Install WSL2 with Ubuntu (wsl --install handles everything on modern Windows)
    Write-Info "Running: wsl --install --no-distribution"
    Write-Info "This enables WSL2, Virtual Machine Platform, and downloads the kernel"
    Write-Info "This may take 5-10 minutes..."
    Write-Host ""

    try {
        $output = wsl --install --no-distribution 2>&1
        Write-Log "wsl --install output: $output"

        if ($LASTEXITCODE -ne 0 -and $output -notmatch "already installed") {
            Write-Fail "WSL2 installation failed"
            Write-Info "Error: $output"
            Write-Info "Try manually: Open PowerShell as Admin → run 'wsl --install'"
            Write-Log "FAIL: wsl --install exit code $LASTEXITCODE"
            return $false
        }
    } catch {
        Write-Fail "WSL2 installation encountered an error: $_"
        Write-Log "FAIL: wsl --install exception: $_"
        return $false
    }

    # Set WSL2 as default version
    wsl --set-default-version 2 2>&1 | Out-Null

    # Check if reboot is needed
    if ($output -match "restart" -or $output -match "reboot") {
        Write-Pass "WSL2 features enabled — reboot required"
        Complete-Stage "wsl2"

        Write-Host ""
        Write-Host "  ┌─────────────────────────────────────────────────┐" -ForegroundColor Yellow
        Write-Host "  │  REBOOT REQUIRED                                │" -ForegroundColor Yellow
        Write-Host "  │                                                 │" -ForegroundColor Yellow
        Write-Host "  │  Save your work, then restart your computer.    │" -ForegroundColor Yellow
        Write-Host "  │  After reboot, re-run this script:              │" -ForegroundColor Yellow
        Write-Host "  │                                                 │" -ForegroundColor Yellow
        Write-Host "  │    .\openclaw-windows-setup.ps1 -Resume         │" -ForegroundColor Yellow
        Write-Host "  │                                                 │" -ForegroundColor Yellow
        Write-Host "  └─────────────────────────────────────────────────┘" -ForegroundColor Yellow
        Write-Host ""

        if (-not $Force) {
            $reboot = Read-Host "Reboot now? (y/n)"
            if ($reboot -eq 'y' -or $reboot -eq 'Y') {
                Write-Info "Rebooting in 10 seconds... (Ctrl+C to cancel)"
                Start-Sleep -Seconds 10
                Restart-Computer -Force
            } else {
                Write-Info "Remember to reboot and re-run with -Resume"
            }
        }
        return $false  # Signal caller to stop (reboot needed)
    }

    Write-Pass "WSL2 installed successfully"
    Complete-Stage "wsl2"
    return $true
}

# ═══════════════════════════════════════════════════════════════════
# Stage 2: Install Ubuntu
# ═══════════════════════════════════════════════════════════════════
function Install-Ubuntu {
    if (Test-StageComplete "ubuntu") {
        Write-Info "Skipping: Ubuntu already installed"
        return $true
    }

    Write-Step "Installing Ubuntu 22.04"
    Write-Log "Stage: Install-Ubuntu"

    # Check if Ubuntu is already installed
    $distros = wsl --list --quiet 2>&1
    if ($distros -match "Ubuntu") {
        Write-Pass "Ubuntu is already installed"

        # Ensure it's WSL2
        $verbose = wsl --list --verbose 2>&1
        if ($verbose -match "Ubuntu.*1\s*$") {
            Write-Warn "Ubuntu is running WSL1 — upgrading to WSL2..."
            Write-Info "This may take 5-10 minutes. Do not close this window."
            wsl --set-version Ubuntu 2 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Pass "Ubuntu upgraded to WSL2"
            } else {
                Write-Warn "WSL2 upgrade may have failed — check with: wsl --list --verbose"
            }
        }

        Complete-Stage "ubuntu"
        return $true
    }

    Write-Info "Downloading and installing Ubuntu 22.04..."
    Write-Info "This may take 5-10 minutes depending on your internet speed"
    Write-Host ""

    try {
        wsl --install -d $Script:UbuntuDistro 2>&1 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

        if ($LASTEXITCODE -ne 0) {
            Write-Fail "Ubuntu installation failed (exit code: $LASTEXITCODE)"
            Write-Info "Try manually: wsl --install -d Ubuntu-22.04"
            Write-Log "FAIL: Ubuntu install exit code $LASTEXITCODE"
            return $false
        }
    } catch {
        Write-Fail "Ubuntu installation error: $_"
        Write-Log "FAIL: Ubuntu install exception: $_"
        return $false
    }

    Write-Pass "Ubuntu 22.04 installed"
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "  │  UBUNTU FIRST-RUN SETUP                         │" -ForegroundColor Cyan
    Write-Host "  │                                                 │" -ForegroundColor Cyan
    Write-Host "  │  Ubuntu will open and ask you to create a       │" -ForegroundColor Cyan
    Write-Host "  │  username and password. This is for Linux       │" -ForegroundColor Cyan
    Write-Host "  │  only — it doesn't affect your Windows login.   │" -ForegroundColor Cyan
    Write-Host "  │                                                 │" -ForegroundColor Cyan
    Write-Host "  │  After setup completes, close the Ubuntu        │" -ForegroundColor Cyan
    Write-Host "  │  window and return here.                        │" -ForegroundColor Cyan
    Write-Host "  └─────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""

    if (-not $Force) {
        Read-Host "Press Enter after completing Ubuntu first-run setup"
    }

    Complete-Stage "ubuntu"
    return $true
}

# ═══════════════════════════════════════════════════════════════════
# Stage 3: Install Node.js (via nvm, inside WSL2)
# ═══════════════════════════════════════════════════════════════════
function Install-NodeJS {
    if (Test-StageComplete "nodejs") {
        Write-Info "Skipping: Node.js already installed"
        return $true
    }

    Write-Step "Installing Node.js $Script:NodeVersion inside Ubuntu"
    Write-Log "Stage: Install-NodeJS"

    # Check if node is already available in WSL2
    $nodeCheck = wsl -d Ubuntu -- bash -c "command -v node" 2>&1
    if ($nodeCheck -match "/node") {
        $nodeVer = wsl -d Ubuntu -- bash -c "node --version" 2>&1
        Write-Pass "Node.js already installed: $nodeVer"
        Complete-Stage "nodejs"
        return $true
    }

    Write-Info "Installing nvm (Node Version Manager)..."

    # Install nvm + Node.js in a single WSL command
    $installScript = @"
set -e
export HOME=~
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
# Source nvm
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"
# Install Node.js LTS
nvm install $Script:NodeVersion
nvm use $Script:NodeVersion
nvm alias default $Script:NodeVersion
# Verify
echo "NODE_VERSION=\$(node --version)"
echo "NPM_VERSION=\$(npm --version)"
"@

    try {
        $output = wsl -d Ubuntu -- bash -c $installScript 2>&1
        Write-Log "Node.js install output: $($output -join "`n")"

        $nodeVer = ($output | Select-String "NODE_VERSION=(.+)" | ForEach-Object { $_.Matches.Groups[1].Value })
        $npmVer  = ($output | Select-String "NPM_VERSION=(.+)"  | ForEach-Object { $_.Matches.Groups[1].Value })

        if ($nodeVer) {
            Write-Pass "Node.js $nodeVer installed (npm $npmVer)"
        } else {
            Write-Warn "Node.js may have installed but version check failed"
            Write-Info "Verify inside Ubuntu: node --version"
        }
    } catch {
        Write-Fail "Node.js installation error: $_"
        Write-Info "Try manually inside Ubuntu: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && nvm install $Script:NodeVersion"
        Write-Log "FAIL: Node.js install exception: $_"
        return $false
    }

    Complete-Stage "nodejs"
    return $true
}

# ═══════════════════════════════════════════════════════════════════
# Stage 4: Install OpenClaw
# ═══════════════════════════════════════════════════════════════════
function Install-OpenClaw {
    if (Test-StageComplete "openclaw") {
        Write-Info "Skipping: OpenClaw already installed"
        return $true
    }

    Write-Step "Installing OpenClaw inside Ubuntu"
    Write-Log "Stage: Install-OpenClaw"

    # Check if openclaw is already installed
    $clawCheck = wsl -d Ubuntu -- bash -c "source ~/.nvm/nvm.sh 2>/dev/null; command -v openclaw" 2>&1
    if ($clawCheck -match "openclaw") {
        $clawVer = wsl -d Ubuntu -- bash -c "source ~/.nvm/nvm.sh 2>/dev/null; openclaw --version" 2>&1
        Write-Pass "OpenClaw already installed: $clawVer"
        Complete-Stage "openclaw"
        return $true
    }

    Write-Info "Installing OpenClaw via npm..."

    $installScript = @"
set -e
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"
npm install -g openclaw
echo "OPENCLAW_VERSION=\$(openclaw --version 2>/dev/null || echo 'unknown')"
"@

    try {
        $output = wsl -d Ubuntu -- bash -c $installScript 2>&1
        Write-Log "OpenClaw install output: $($output -join "`n")"

        $clawVer = ($output | Select-String "OPENCLAW_VERSION=(.+)" | ForEach-Object { $_.Matches.Groups[1].Value })
        if ($clawVer -and $clawVer -ne "unknown") {
            Write-Pass "OpenClaw $clawVer installed"
        } else {
            Write-Warn "OpenClaw installed but version check failed"
            Write-Info "Verify inside Ubuntu: openclaw --version"
        }
    } catch {
        Write-Fail "OpenClaw installation error: $_"
        Write-Info "Try manually inside Ubuntu: npm install -g openclaw"
        Write-Log "FAIL: OpenClaw install exception: $_"
        return $false
    }

    Complete-Stage "openclaw"
    return $true
}

# ═══════════════════════════════════════════════════════════════════
# Stage 5: Run onboarding + configure model
# ═══════════════════════════════════════════════════════════════════
function Start-Onboarding {
    if (Test-StageComplete "onboard") {
        Write-Info "Skipping: Onboarding already completed"
        return $true
    }

    Write-Step "OpenClaw Onboarding"
    Write-Log "Stage: Start-Onboarding"

    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "  │  ONBOARDING WIZARD                              │" -ForegroundColor Cyan
    Write-Host "  │                                                 │" -ForegroundColor Cyan
    Write-Host "  │  Open Ubuntu from the Start menu and run:       │" -ForegroundColor Cyan
    Write-Host "  │                                                 │" -ForegroundColor Cyan
    Write-Host "  │    openclaw onboard --install-daemon            │" -ForegroundColor Cyan
    Write-Host "  │                                                 │" -ForegroundColor Cyan
    Write-Host "  │  Follow the prompts. When done, return here.    │" -ForegroundColor Cyan
    Write-Host "  │                                                 │" -ForegroundColor Cyan
    Write-Host "  │  Model defaults:                                │" -ForegroundColor Cyan
    Write-Host "  │    Primary:  $Script:DefaultModel   │" -ForegroundColor Cyan
    Write-Host "  │    Fallback: $Script:FallbackModel1   │" -ForegroundColor Cyan
    Write-Host "  │    Backup:   $Script:FallbackModel2      │" -ForegroundColor Cyan
    Write-Host "  └─────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""

    if (-not $Force) {
        Read-Host "Press Enter after completing the onboarding wizard"
    }

    # Verify onboarding created config
    $configCheck = wsl -d Ubuntu -- bash -c "test -f ~/.openclaw/openclaw.json && echo EXISTS" 2>&1
    if ($configCheck -match "EXISTS") {
        Write-Pass "OpenClaw config file created"

        # Apply model fallback chain
        Write-Info "Configuring model fallback chain..."
        $modelScript = @"
set -e
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"

python3 -c "
import json, sys
config_path = '$env:HOME/.openclaw/openclaw.json'.replace('\\\\', '/')
# Use the WSL home directory
import os
config_path = os.path.expanduser('~/.openclaw/openclaw.json')
with open(config_path, 'r') as f:
    config = json.load(f)
if 'agents' not in config:
    config['agents'] = {}
if 'defaults' not in config['agents']:
    config['agents']['defaults'] = {}
config['agents']['defaults']['model'] = {
    'primary': '$Script:DefaultModel',
    'fallbacks': ['$Script:FallbackModel1', '$Script:FallbackModel2']
}
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
print('MODEL_CONFIG=OK')
"
"@
        try {
            $output = wsl -d Ubuntu -- bash -c $modelScript 2>&1
            if ($output -match "MODEL_CONFIG=OK") {
                Write-Pass "Model fallback chain configured ($Script:DefaultModel → $Script:FallbackModel1 → $Script:FallbackModel2)"
            } else {
                Write-Warn "Model config may not have been written — check manually"
            }
        } catch {
            Write-Warn "Could not auto-configure models: $_"
            Write-Info "You can set this manually in ~/.openclaw/openclaw.json"
        }
    } else {
        Write-Warn "Config file not found — onboarding may not have completed"
        Write-Info "Run inside Ubuntu: openclaw onboard --install-daemon"
    }

    Complete-Stage "onboard"
    return $true
}

# ═══════════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════════
function Show-Summary {
    $progress = Get-Progress

    Write-Host ""
    Write-Host "  ═══════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "  ║  OpenClaw Windows Setup Complete!               ║" -ForegroundColor Green
    Write-Host "  ═══════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Stages completed:" -ForegroundColor White
    foreach ($stage in $progress.completedStages) {
        Write-Host "    ✓ $stage" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "  What's next:" -ForegroundColor Cyan
    Write-Host "    1. Open Ubuntu from the Start menu" -ForegroundColor White
    Write-Host "    2. Run: openclaw gateway start" -ForegroundColor White
    Write-Host "    3. Talk to your agent via Discord or Telegram" -ForegroundColor White
    Write-Host ""
    Write-Host "  Model configuration:" -ForegroundColor Cyan
    Write-Host "    Primary:    $Script:DefaultModel (free)" -ForegroundColor White
    Write-Host "    Fallback 1: $Script:FallbackModel1 (low-cost)" -ForegroundColor White
    Write-Host "    Fallback 2: $Script:FallbackModel2 (free)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Useful commands (run inside Ubuntu):" -ForegroundColor Cyan
    Write-Host "    openclaw status          — Check gateway status" -ForegroundColor DarkGray
    Write-Host "    openclaw gateway restart  — Restart gateway" -ForegroundColor DarkGray
    Write-Host "    openclaw doctor           — Diagnose issues" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Need help? https://docs.openclaw.ai" -ForegroundColor DarkGray
    Write-Host "  Community: https://discord.com/invite/clawd" -ForegroundColor DarkGray
    Write-Host ""

    Write-Log "Setup complete. Stages: $($progress.completedStages -join ', ')"
}

# ═══════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════
function Main {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                   ║" -ForegroundColor Cyan
    Write-Host "  ║   🦞 OpenClaw Windows Setup v$Script:Version              ║" -ForegroundColor Cyan
    Write-Host "  ║                                                   ║" -ForegroundColor Cyan
    Write-Host "  ║   Installs WSL2 + Ubuntu + Node.js + OpenClaw     ║" -ForegroundColor Cyan
    Write-Host "  ║   Estimated time: 10-20 minutes                   ║" -ForegroundColor Cyan
    Write-Host "  ║                                                   ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # Handle flags
    if ($Reset) {
        if (Test-Path $Script:ProgressFile) {
            Remove-Item $Script:ProgressFile -Force
            Write-Pass "Progress reset"
        }
        Write-Info "Starting fresh..."
    }

    if ($Resume) {
        $progress = Get-Progress
        $completed = $progress.completedStages.Count
        Write-Info "Resuming from stage $($completed + 1) ($completed stages completed)"
        Write-Host ""
    }

    Write-Log "=== OpenClaw Windows Setup v$Script:Version ==="
    Write-Log "Flags: Force=$Force Resume=$Resume Reset=$Reset"

    # Prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Host ""
        Write-Fail "Prerequisites check failed. Fix the issues above and re-run."
        return
    }
    Write-Host ""

    # Stage 1: WSL2
    $result = Install-WSL2
    if (-not $result) {
        # Reboot needed or failure
        return
    }
    Write-Host ""

    # Stage 2: Ubuntu
    $result = Install-Ubuntu
    if (-not $result) { return }
    Write-Host ""

    # Stage 3: Node.js
    $result = Install-NodeJS
    if (-not $result) { return }
    Write-Host ""

    # Stage 4: OpenClaw
    $result = Install-OpenClaw
    if (-not $result) { return }
    Write-Host ""

    # Stage 5: Onboarding
    $result = Start-Onboarding
    if (-not $result) { return }
    Write-Host ""

    # Summary
    Show-Summary
}

# Run
Main
