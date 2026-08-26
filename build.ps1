$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " EliteSoftware Master Framework Builder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Compile Sub-Components
Write-Host "`n[1] Compiling Sub-Components..." -ForegroundColor Yellow

$components = @(
    "EliteSoftware-GitHub_Repo-Automation",
    "EliteSoftware-EasySigner",
    "EliteSoftware-Compiler",
    "EliteSoftware-Packager"
)

foreach ($comp in $components) {
    if (Test-Path $comp) {
        Write-Host " -> Building $comp..."
        Set-Location $comp
        & .\build.ps1
        Set-Location ".."
    }
}

# 2. Verify Build Success
$AutomatorPath = "EliteSoftware-GitHub_Repo-Automation\x64\EliteGitHubAutomator.exe"

if (-not (Test-Path $AutomatorPath)) {
    Write-Error "EliteGitHubAutomator is missing. Aborting automation steps."
    exit 1
}

Write-Host "`n[2] Build Successful! Triggering GitHub Automator..." -ForegroundColor Green

# 3. Auto-Commit and Push
Write-Host " -> Committing to repository..."
& $AutomatorPath commit --msg "Auto-commit after framework compilation"

# 4. Parse Version from Root Changelog
$version = "1.0.0.0"
if (Test-Path "changelog.md") {
    $changelog = Get-Content "changelog.md" -Raw
    $versionMatch = [regex]::Match($changelog, '## v([0-9\.]+)')
    if ($versionMatch.Success) {
        $version = $versionMatch.Groups[1].Value
    }
}

# 5. Create GitHub Release
Write-Host " -> Drafting GitHub Release v$version..."
$releaseArgs = @("release", "--version", $version)
if (Test-Path "changelog.md") {
    $releaseArgs += "--notes"
    $releaseArgs += "changelog.md"
}

# Attach all built EXEs from root x64 and x86
$x64Assets = Get-ChildItem -Path "x64" -Filter "*.exe" -ErrorAction SilentlyContinue
foreach ($asset in $x64Assets) {
    $releaseArgs += "--x64"
    $releaseArgs += $asset.FullName
}
$x86Assets = Get-ChildItem -Path "x86" -Filter "*.exe" -ErrorAction SilentlyContinue
foreach ($asset in $x86Assets) {
    $releaseArgs += "--x86"
    $releaseArgs += $asset.FullName
}

# Also attach the automator itself which builds locally
$releaseArgs += "--x64"
$releaseArgs += (Resolve-Path "EliteSoftware-GitHub_Repo-Automation\x64\EliteGitHubAutomator.exe").Path
if (Test-Path "EliteSoftware-GitHub_Repo-Automation\x86\EliteGitHubAutomator.exe") {
    $releaseArgs += "--x86"
    $releaseArgs += (Resolve-Path "EliteSoftware-GitHub_Repo-Automation\x86\EliteGitHubAutomator.exe").Path
}

& $AutomatorPath $releaseArgs

Write-Host "`nMaster Build and Deployment Complete!" -ForegroundColor Cyan
