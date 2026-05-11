param(
  [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
  throw "WSL is not installed. Install WSL first: wsl --install"
}

$drive = $repoRoot.Substring(0, 1).ToLower()
$rest = ($repoRoot.Substring(2) -replace '\\', '/')
$wslRepoRoot = "/mnt/$drive$rest"

if (-not $SkipInstall) {
  Write-Host "Installing build-essential inside WSL (may prompt for sudo password)..."
  wsl -e sh -lc "if command -v sudo >/dev/null 2>&1; then sudo apt update && sudo apt install -y build-essential; else apt update && apt install -y build-essential; fi"
}

Write-Host "Building assembly simulation in WSL..."
wsl -e sh -lc "cd '$wslRepoRoot' && bash assembly/build_linux.sh"

Write-Host "Running assembly simulation in WSL..."
wsl -e sh -lc "cd '$wslRepoRoot' && bash assembly/run_linux.sh"
