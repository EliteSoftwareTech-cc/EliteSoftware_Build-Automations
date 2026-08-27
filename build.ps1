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
    "EliteSoftware-Packager",
    "EliteSoftware-EnvManager_GUI",
    "EliteSoftware-EntryPoint",
    "EliteSoftware-VersionBumper",`n    "EliteSoftware-CLSIDGenerator",`n    "EliteSoftware-SmartRegsvr",`n    "EliteSoftware-InnoCreator",`n    "EliteSoftware-RCManager",`n    "EliteSoftware-IconReplacer",
    "EliteSoftware-ReadmeGenerator",
    "EliteSoftware-BuildLocator"
)

foreach ($comp in $components) {
    $compPath = "src\$comp"
    if (Test-Path $compPath) {
        Write-Host " -> Building $comp..."
        Set-Location $compPath
        & .\build.ps1
        Set-Location $ScriptDir
    }
}

# 2. Verify Build Success
$AutomatorPath = "BuildOutputx64\EliteGitHubAutomator.exe"

if (-not (Test-Path $AutomatorPath)) {
    Write-Error "EliteGitHubAutomator is missing. Aborting automation steps."
    exit 1
}

Write-Host "`n[2.5] Signing Binaries..." -ForegroundColor Yellow
$SignerPath = "BuildOutputx64\EliteEasySigner.exe"
if (Test-Path $SignerPath) {
    $allExes = Get-ChildItem -Path "BuildOutputx64", "BuildOutputx86" -Filter "*.exe" -ErrorAction SilentlyContinue
    foreach ($exe in $allExes) {
        Write-Host " -> Signing $($exe.Name)..."
        & $SignerPath --file $exe.FullName --ai-mode
    }
} else {
    Write-Warning "EliteEasySigner is missing. Binaries will NOT be signed."
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

# Attach all built EXEs from root BuildOutputx64 and BuildOutputx86
$x64Assets = Get-ChildItem -Path "BuildOutputx64" -Filter "*.exe" -ErrorAction SilentlyContinue
foreach ($asset in $x64Assets) {
    $releaseArgs += "--x64"
    $releaseArgs += $asset.FullName
}
$x86Assets = Get-ChildItem -Path "BuildOutputx86" -Filter "*.exe" -ErrorAction SilentlyContinue
foreach ($asset in $x86Assets) {
    $releaseArgs += "--x86"
    $releaseArgs += $asset.FullName
}

& $AutomatorPath $releaseArgs

Write-Host "`nMaster Build and Deployment Complete!" -ForegroundColor Cyan



