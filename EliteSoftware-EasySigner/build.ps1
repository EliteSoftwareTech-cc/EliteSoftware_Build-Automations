$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "Building EliteSoftware-EasySigner (C++)..." -ForegroundColor Cyan

$SourceFile = Join-Path $ScriptDir "main.cpp"
$RcFile = Join-Path $ScriptDir "resources.rc"
$Outx64 = Join-Path (Split-Path -Parent $ScriptDir) "x64\EliteEasySigner.exe"
$Outx86 = Join-Path (Split-Path -Parent $ScriptDir) "x86\EliteEasySigner.exe"

# Create output dirs if missing
$Rootx64 = Join-Path (Split-Path -Parent $ScriptDir) "x64"
$Rootx86 = Join-Path (Split-Path -Parent $ScriptDir) "x86"
if (-not (Test-Path $Rootx64)) { New-Item -ItemType Directory -Path $Rootx64 | Out-Null }
if (-not (Test-Path $Rootx86)) { New-Item -ItemType Directory -Path $Rootx86 | Out-Null }

Write-Host "Compiling resources (windres)..." -ForegroundColor Yellow
$ResOut64 = Join-Path $ScriptDir "resources_x64.o"
$ResOut32 = Join-Path $ScriptDir "resources_x86.o"

& windres -F pe-x86-64 $RcFile -o $ResOut64
if ($LASTEXITCODE -ne 0) { throw "windres failed for x64" }

& windres -F pe-i386 $RcFile -o $ResOut32
if ($LASTEXITCODE -ne 0) { Write-Warning "windres failed for x86. Skipping 32-bit resources." }

Write-Host "Compiling x64 Executable (g++)..." -ForegroundColor Green
& g++ -m64 -O3 -o $Outx64 $SourceFile $ResOut64
if ($LASTEXITCODE -ne 0) { throw "Failed to compile x64 variant. Make sure g++ is in PATH." }

Write-Host "Compiling x86 Executable (g++)..." -ForegroundColor Green
if (Test-Path $ResOut32) {
    & g++ -m32 -O3 -o $Outx86 $SourceFile $ResOut32
    if ($LASTEXITCODE -ne 0) { 
        Write-Warning "Failed to compile x86 variant. Your MinGW installation may not support -m32. Skipping x86." 
    }
} else {
    Write-Warning "Skipping x86 compilation due to missing resource file."
}

# Cleanup Temp Object Files
if (Test-Path $ResOut64) { Remove-Item $ResOut64 -Force }
if (Test-Path $ResOut32) { Remove-Item $ResOut32 -Force }

Write-Host "Build Complete!" -ForegroundColor Cyan
