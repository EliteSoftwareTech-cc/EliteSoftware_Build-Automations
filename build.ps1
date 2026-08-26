$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " EliteSoftware Master Framework Builder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Compile Sub-Components
Write-Host "`n[1] Compiling EliteSoftware-GitHub_Repo-Automation..." -ForegroundColor Yellow
Set-Location "EliteSoftware-GitHub_Repo-Automation"
& .\build.ps1
Set-Location ".."

# 2. Verify Build Success
$x64Path = "EliteSoftware-GitHub_Repo-Automation\x64\EliteGitHubAutomator.exe"
$x86Path = "EliteSoftware-GitHub_Repo-Automation\x86\EliteGitHubAutomator.exe"

if (-not (Test-Path $x64Path)) {
    Write-Error "x64 build failed or is missing. Aborting automation steps."
    exit 1
}

Write-Host "`n[2] Build Successful! Triggering GitHub Automator..." -ForegroundColor Green

# 3. Auto-Commit and Push
Write-Host " -> Committing to repository..."
& $x64Path commit --msg "Auto-commit after framework compilation"

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

if (Test-Path $x64Path) { 
    $releaseArgs += "--x64"
    $releaseArgs += $x64Path 
}
if (Test-Path $x86Path) { 
    $releaseArgs += "--x86"
    $releaseArgs += $x86Path 
}

& $x64Path $releaseArgs

Write-Host "`nMaster Build and Deployment Complete!" -ForegroundColor Cyan
