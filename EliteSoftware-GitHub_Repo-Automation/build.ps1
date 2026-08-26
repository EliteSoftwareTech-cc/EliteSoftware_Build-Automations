$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "Building EliteSoftware-GitHub_Repo-Automation (C++)..." -ForegroundColor Cyan

$SourceFile = Join-Path $ScriptDir "EliteSoftware-GitHub_Repo-Automation_CLI\main.cpp"
$Outx64 = Join-Path $ScriptDir "x64\EliteGitHubAutomator.exe"
$Outx86 = Join-Path $ScriptDir "x86\EliteGitHubAutomator.exe"

# Create output dirs if missing
if (-not (Test-Path "$ScriptDir\x64")) { New-Item -ItemType Directory -Path "$ScriptDir\x64" | Out-Null }
if (-not (Test-Path "$ScriptDir\x86")) { New-Item -ItemType Directory -Path "$ScriptDir\x86" | Out-Null }

# Compile using g++
Write-Host "Compiling x64 Executable (g++)..." -ForegroundColor Green
& g++ -m64 -O3 -o $Outx64 $SourceFile
if ($LASTEXITCODE -ne 0) { throw "Failed to compile x64 variant. Make sure g++ is in PATH." }

Write-Host "Compiling x86 Executable (g++)..." -ForegroundColor Green
& g++ -m32 -O3 -o $Outx86 $SourceFile
if ($LASTEXITCODE -ne 0) { 
    Write-Warning "Failed to compile x86 variant. Your MinGW installation may not support -m32. Skipping x86." 
}

Write-Host "Build Complete!" -ForegroundColor Cyan
