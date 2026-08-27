$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Building EliteSoftware-ProjectBackup..."
$Outx64 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx64\EliteProjectBackup.exe"
$Outx86 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx86\EliteProjectBackup.exe"
& g++ -m64 -O3 -o $Outx64 ($ScriptDir + "\main.cpp")
if (Test-Path $Outx86 -ErrorAction SilentlyContinue) { & g++ -m32 -O3 -o $Outx86 ($ScriptDir + "\main.cpp") }
