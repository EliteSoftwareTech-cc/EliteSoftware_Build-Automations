$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "Building EliteSoftware-EnvManager_GUI (PS2EXE)..." -ForegroundColor Cyan

$SourceFile = Join-Path $ScriptDir "EnvManager.ps1"
$IconFile = Join-Path $ScriptDir "icon.ico"
$Outx64 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx64\EliteSoftware-EnvManager_GUI.exe"

# We assume PS2EXE is installed
# Build x64 variant
Invoke-ps2exe -inputFile $SourceFile -outputFile $Outx64 -iconFile $IconFile -noConsole -STA -x64

Write-Host "Build Complete!" -ForegroundColor Cyan
