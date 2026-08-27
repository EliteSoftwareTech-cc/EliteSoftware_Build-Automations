# ==============================================================================
# Scripts/03_CompileEngineAndTests.ps1
# Engine Compilation, C++ Unit Tests, and Python E2E Verification
# EliteSoftwareTech Co. - File Splitter For AI Upload v1.2.0.0
# ==============================================================================

$ErrorActionPreference = 'Stop'

Write-Host " [03/05] Compiling Engine & Running Verification Test Suites..." -ForegroundColor Cyan

$scriptPath = $PSScriptRoot
$projectRoot = Resolve-Path "$scriptPath\.."

Set-Location $projectRoot

# 1. Locate Engine Source and Unit Test Runner Source
$engineSrc = "$projectRoot\src\TextSplitterEngine.cpp"
$testSrc = "$projectRoot\src\test_main.cpp"

if (-not (Test-Path $testSrc)) {
    $testSrc = "$projectRoot\tests\test_main.cpp"
}

if (-not (Test-Path $engineSrc) -or -not (Test-Path $testSrc)) {
    Write-Host " [ERROR] Engine source or test runner source file missing." -ForegroundColor Red
    exit 1
}

# 2. Compile C++ Unit Test Executable (test_engine.exe)
Write-Host "  -> Compiling C++ Unit Test Runner (test_engine.exe)..." -ForegroundColor Gray
$testExe = "$projectRoot\test_engine.exe"
& g++ -std=c++17 -O2 -Wall -Wextra -Iinclude $engineSrc $testSrc -o $testExe
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $testExe)) {
    Write-Host " [ERROR] Failed to compile test_engine.exe" -ForegroundColor Red
    exit 1
}
Write-Host "     Built: $testExe" -ForegroundColor Green

# 3. Execute C++ Engine Unit Tests
Write-Host "  -> Running C++ Engine Unit Tests..." -ForegroundColor Gray
& $testExe
if ($LASTEXITCODE -ne 0) {
    Write-Host " [ERROR] C++ Unit Tests failed!" -ForegroundColor Red
    exit 1
}
Write-Host "     All C++ Unit Tests Passed!" -ForegroundColor Green

# 4. Check for Python & Run Python E2E Test Harness if available
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    $pythonCmd = Get-Command py -ErrorAction SilentlyContinue
}

$pyTestScript = "$projectRoot\tests\test_splitter.py"
if ($pythonCmd -and (Test-Path $pyTestScript)) {
    Write-Host "  -> Running Python E2E Test Harness (tests/test_splitter.py)..." -ForegroundColor Gray
    & $pythonCmd.Path $pyTestScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host " [ERROR] Python E2E Test Harness failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "     Python E2E Test Harness Passed!" -ForegroundColor Green
} else {
    Write-Host "  -> Python not available or test_splitter.py missing, skipping E2E harness." -ForegroundColor Yellow
}

Write-Host " [SUCCESS] Step 03: Engine compilation & test suites passed cleanly.`n" -ForegroundColor Green
