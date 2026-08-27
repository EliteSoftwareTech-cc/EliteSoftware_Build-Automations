$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Building EliteSoftware-CLSIDGenerator..."
$Outx64 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx64\EliteCLSIDGenerator.exe"
$Outx86 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx86\EliteCLSIDGenerator.exe"

& windres ($ScriptDir + "\app.rc") -O coff -o ($ScriptDir + "\app.res")
& g++ -m64 -O3 -o $Outx64 ($ScriptDir + "\main.cpp") -lole32 -ladvapi32
if (Test-Path $Outx86 -ErrorAction SilentlyContinue) { & g++ -m32 -O3 -o $Outx86 ($ScriptDir + "\main.cpp") -lole32 -ladvapi32 }

