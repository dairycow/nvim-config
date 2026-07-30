# Reproducible Neovim setup installer for Windows (PowerShell).
# Installs system deps via Scoop, copies init.lua to the Windows nvim config
# location, bootstraps all plugins, and compiles Treesitter parsers.
#
# Run from an elevated-or-normal PowerShell (Scoop does not need admin):
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\install.ps1
#
# Requires Neovim 0.12+ for nvim-treesitter (main branch).
#Requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference = "Stop"

$script:NvimMinMajor = 0
$script:NvimMinMinor = 12

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    OK: $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "    WARN: $msg" -ForegroundColor Yellow }
function Die($msg) { Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }

Write-Step "Neovim config installer (Windows / PowerShell)"

# ---------------------------------------------------------------------------
# 1. Ensure Scoop is installed (dev-friendly package manager, no admin needed)
# ---------------------------------------------------------------------------
Write-Step "Ensuring Scoop package manager..."
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    # Allow script execution for the current process so Scoop can install.
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    Write-Host "    Installing Scoop..."
    Invoke-RestMethod -Uri "https://get.scoop.sh" | Invoke-Expression
    # Make scoop available in this session.
    $scoopPath = Join-Path $env:USERPROFILE "scoop\shims"
    if ($env:PATH -notlike "*$scoopPath*") { $env:PATH = "$scoopPath;$env:PATH" }
    Write-Ok "Scoop installed."
} else {
    Write-Ok "Scoop already present."
}

# ---------------------------------------------------------------------------
# 2. Install system dependencies
# ---------------------------------------------------------------------------
Write-Step "Installing system dependencies via Scoop..."
$pkgs = @("git", "ripgrep", "gcc", "make", "curl")
foreach ($p in $pkgs) {
    if (-not (Get-Command $p -ErrorAction SilentlyContinue)) {
        Write-Host "    Installing $p..."
        scoop install $p | Out-Null
    }
}

# Neovim (may already be installed via other means)
if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
    Write-Host "    Installing neovim..."
    scoop install neovim | Out-Null
}

# tree-sitter CLI (try scoop, fall back to cargo)
if (-not (Get-Command tree-sitter -ErrorAction SilentlyContinue)) {
    Write-Host "    Installing tree-sitter-cli..."
    $ts = (scoop install tree-sitter 2>&1)
    if ($LASTEXITCODE -ne 0 -and -not (Get-Command tree-sitter -ErrorAction SilentlyContinue)) {
        Write-Warn "tree-sitter not in scoop; trying cargo..."
        if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
            Write-Warn "Installing rustup (for cargo)..."
            scoop install rustup | Out-Null
        }
        cargo install tree-sitter-cli
    }
}

# Refresh PATH so newly installed tools are visible in this session.
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "Machine")

# ---------------------------------------------------------------------------
# 3. Verify Neovim version (needs >= 0.12)
# ---------------------------------------------------------------------------
$nvimCmd = Get-Command nvim -ErrorAction SilentlyContinue
if (-not $nvimCmd) { Die "neovim not found after install (open a new terminal and re-run)." }
$firstLine = (& nvim --version | Select-Object -First 1)
$verMatch = [regex]::Match($firstLine, "(\d+)\.(\d+)\.(\d+)")
if (-not $verMatch.Success) { Die "Could not parse Neovim version from: $firstLine" }
$major = [int]$verMatch.Groups[1].Value
$minor = [int]$verMatch.Groups[2].Value
$nvimVersion = "$($verMatch.Groups[1].Value).$($verMatch.Groups[2].Value).$($verMatch.Groups[3].Value)"
Write-Step "Neovim version: $nvimVersion"
if (($major -lt $script:NvimMinMajor) -or
    ($major -eq $script:NvimMinMajor -and $minor -lt $script:NvimMinMinor)) {
    Die "Neovim >= $($script:NvimMinMajor).$($script:NvimMinMinor) required (got $nvimVersion). Install a newer build via 'scoop install neovim' (nightly) or https://github.com/neovim/neovim/releases"
}

# Sanity-check the toolchain that Treesitter / telescope-fzf-native will use.
foreach ($t in @("gcc", "make", "rg", "tree-sitter", "git", "curl", "tar")) {
    if (-not (Get-Command $t -ErrorAction SilentlyContinue)) {
        Die "Required tool missing from PATH: $t"
    }
}
Write-Ok "All build tools present."

# ---------------------------------------------------------------------------
# 4. Copy init.lua into the Windows Neovim config location
# ---------------------------------------------------------------------------
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$src = Join-Path $scriptDir "init.lua"
$destDir = Join-Path $env:LOCALAPPDATA "nvim"
$dest = Join-Path $destDir "init.lua"

if (-not (Test-Path $src)) { Die "init.lua not found next to this script ($src)." }
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
Copy-Item -Path $src -Destination $dest -Force
Write-Ok "Installed config: $dest"

# ---------------------------------------------------------------------------
# 5. Bootstrap plugins (lazy.nvim) + compile Treesitter parsers
# ---------------------------------------------------------------------------
Write-Step "Bootstrapping plugins and Treesitter parsers (this takes a minute)..."
& nvim --headless "+Lazy! sync" +qa
if ($LASTEXITCODE -ne 0) { Die "lazy.nvim sync failed." }

& nvim --headless `
    -c "lua require('nvim-treesitter').install({ 'rust', 'lua', 'vim', 'vimdoc', 'query' }):wait(300000)" `
    -c "qa"

# ---------------------------------------------------------------------------
# 6. Verify
# ---------------------------------------------------------------------------
$theme = (& nvim --headless -c "lua print(vim.g.colors_name or 'NONE')" -c "qa" 2>$null | Select-Object -Last 1)
Write-Step "Active colorscheme: $theme"
if ($theme -eq "ayu") {
    Write-Ok "SUCCESS. Run 'nvim' to start."
} else {
    Write-Warn "Expected theme 'ayu', got '$theme'. Open nvim and run :Lazy sync."
}
