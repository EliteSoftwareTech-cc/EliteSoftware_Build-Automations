# ==============================================================================
# Build.ps1
# Master Build & Verification Pipeline Orchestrator
# EliteSoftwareTech Co. - File Splitter For AI Upload v1.2.0.0
# Target Framework: Native Win32 C++17 | Minimum OS Target: Windows Vista+
# ==============================================================================

$ErrorActionPreference = 'Stop'
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$projectRoot = $PSScriptRoot
Set-Location $projectRoot

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "  EliteSoftwareTech Co. - File Splitter For AI Upload v1.2.0.0" -ForegroundColor Cyan
Write-Host "  Automated PowerShell Build & Verification Pipeline" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " Target OS        : Windows Vista / Windows 7+ (WINVER=0x0600)" -ForegroundColor Gray
Write-Host " Architecture     : 64-bit (BuildOutput\) & 32-bit (BuildOutputx86\)" -ForegroundColor Gray
Write-Host " Compiler         : MinGW-w64 GCC (C++17) & windres" -ForegroundColor Gray
Write-Host " Start Time       : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "------------------------------------------------------------------------------`n" -ForegroundColor Cyan

$scripts = @(
    "Scripts\01_PrepareEnvironment.ps1",
    "Scripts\02_CompileResources.ps1",
    "Scripts\03_CompileEngineAndTests.ps1",
    "Scripts\04_CompileBinaries.ps1",
    "Scripts\05_PackageOutput.ps1"
)

$stepNum = 1
$totalSteps = $scripts.Count

foreach ($script in $scripts) {
    $scriptFullPath = "$projectRoot\$script"
    if (-not (Test-Path $scriptFullPath)) {
        Write-Host "[FATAL ERROR] Step script not found: $scriptFullPath" -ForegroundColor Red
        exit 1
    }

    Write-Host "==============================================================================" -ForegroundColor Yellow
    Write-Host " [Step $stepNum/$totalSteps] Executing: $script" -ForegroundColor Yellow
    Write-Host "==============================================================================" -ForegroundColor Yellow

    & $scriptFullPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n[FATAL ERROR] Pipeline failed at step: $script (Exit Code: $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }

    $stepNum++
}

$sw.Stop()
$elapsedSec = [math]::Round($sw.Elapsed.TotalSeconds, 2)

Write-Host "==============================================================================" -ForegroundColor Green
Write-Host " BUILD SUCCESSFUL! All binaries compiled, tested, and packaged." -ForegroundColor Green
Write-Host " Total Elapsed Time: $elapsedSec seconds" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Green
