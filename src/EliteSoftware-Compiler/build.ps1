$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "Building EliteSoftware-Compiler (C++)..." -ForegroundColor Cyan

$SourceFile = Join-Path $ScriptDir "main.cpp"
$Outx64 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx64\EliteBuild_Compiler.exe"
$Outx86 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx86\EliteBuild_Compiler.exe"

$Rootx64 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx64"
$Rootx86 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx86"
if (-not (Test-Path $Rootx64)) { New-Item -ItemType Directory -Path $Rootx64 | Out-Null }
if (-not (Test-Path $Rootx86)) { New-Item -ItemType Directory -Path $Rootx86 | Out-Null }

Write-Host "Compiling x64 Executable (g++)..." -ForegroundColor Green
& g++ -m64 -O3 -std=c++17 -o $Outx64 $SourceFile
if ($LASTEXITCODE -ne 0) { throw "Failed to compile x64 variant." }

Write-Host "Compiling x86 Executable (g++)..." -ForegroundColor Green
& g++ -m32 -O3 -std=c++17 -o $Outx86 $SourceFile
if ($LASTEXITCODE -ne 0) { 
    Write-Warning "Failed to compile x86 variant. MinGW may lack 32-bit libs." 
}

Write-Host "Build Complete!" -ForegroundColor Cyan




