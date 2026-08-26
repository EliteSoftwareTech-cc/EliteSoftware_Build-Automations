$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "Building EliteSoftware-Packager (C++)..." -ForegroundColor Cyan

$SourceFile = Join-Path $ScriptDir "main.cpp"
$RcFile = Join-Path $ScriptDir "resource.rc"
$Outx64 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx64\EliteBuild_Packager.exe"
$Outx86 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx86\EliteBuild_Packager.exe"

$Rootx64 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx64"
$Rootx86 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx86"
if (-not (Test-Path $Rootx64)) { New-Item -ItemType Directory -Path $Rootx64 | Out-Null }
if (-not (Test-Path $Rootx86)) { New-Item -ItemType Directory -Path $Rootx86 | Out-Null }

Write-Host "Compiling resources (windres)..." -ForegroundColor Yellow
$ResOut64 = Join-Path $ScriptDir "resource_x64.o"
$ResOut32 = Join-Path $ScriptDir "resource_x86.o"

& windres -F pe-x86-64 $RcFile -o $ResOut64
if ($LASTEXITCODE -ne 0) { throw "windres failed for x64" }

& windres -F pe-i386 $RcFile -o $ResOut32
if ($LASTEXITCODE -ne 0) { Write-Warning "windres failed for x86. Skipping 32-bit resources." }

Write-Host "Compiling x64 Executable (g++)..." -ForegroundColor Green
& g++ -m64 -O3 -std=c++17 -o $Outx64 $SourceFile $ResOut64
if ($LASTEXITCODE -ne 0) { throw "Failed to compile x64 variant." }

Write-Host "Compiling x86 Executable (g++)..." -ForegroundColor Green
if (Test-Path $ResOut32) {
    & g++ -m32 -O3 -std=c++17 -o $Outx86 $SourceFile $ResOut32
    if ($LASTEXITCODE -ne 0) { 
        Write-Warning "Failed to compile x86 variant. MinGW may lack 32-bit libs." 
    }
}

if (Test-Path $ResOut64) { Remove-Item $ResOut64 -Force }
if (Test-Path $ResOut32) { Remove-Item $ResOut32 -Force }

Write-Host "Build Complete!" -ForegroundColor Cyan
