$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Outx64 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx64\EliteIconReplacer.exe"
$Outx86 = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) "BuildOutputx86\EliteIconReplacer.exe"

& windres ($ScriptDir + "\app.rc") -O coff -o ($ScriptDir + "\app.res")
& g++ -m64 -O3 -o $Outx64 ($ScriptDir + "\main.cpp") ($ScriptDir + "\app.res") -limagehlp
if (Test-Path $Outx86 -ErrorAction SilentlyContinue) { & g++ -m32 -O3 -o $Outx86 ($ScriptDir + "\main.cpp") ($ScriptDir + "\app.res") -limagehlp }
