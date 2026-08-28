$ErrorActionPreference = 'Stop'
Write-Host "=============================================="
Write-Host " EliteSoftware Master Build Bootstrapper      "
Write-Host "=============================================="

$Outx64 = "BuildOutputx64"
$Outx86 = "BuildOutputx86"

if (-not (Test-Path $Outx64)) { New-Item -ItemType Directory -Path $Outx64 -Force | Out-Null }
if (-not (Test-Path $Outx86)) { New-Item -ItemType Directory -Path $Outx86 -Force | Out-Null }

if (-not (Test-Path "$Outx64\EliteBuild.exe")) {
    Write-Host "[Bootstrap] Compiling EliteBuild.exe..."
    & windres "src\EliteSoftware-EntryPoint\app.rc" -O coff -o "src\EliteSoftware-EntryPoint\app.res"
    & g++ -m64 -O3 -o "$Outx64\EliteBuild.exe" "src\EliteSoftware-EntryPoint\main.cpp" "src\EliteSoftware-EntryPoint\app.res" -lole32 -luuid -lshell32
}

if (-not (Test-Path "$Outx64\EliteBuild_Compiler.exe")) {
    Write-Host "[Bootstrap] Compiling EliteBuild_Compiler.exe..."
    & windres "src\EliteSoftware-Compiler\app.rc" -O coff -o "src\EliteSoftware-Compiler\app.res"
    & g++ -m64 -O3 -o "$Outx64\EliteBuild_Compiler.exe" "src\EliteSoftware-Compiler\main.cpp" "src\EliteSoftware-Compiler\app.res" -lole32 -luuid -lshell32
}

if (-not (Test-Path "$Outx64\EliteEasySigner.exe")) {
    Write-Host "[Bootstrap] Compiling EliteEasySigner.exe..."
    & windres "src\EliteSoftware-EasySigner\app.rc" -O coff -o "src\EliteSoftware-EasySigner\app.res"
    & g++ -m64 -O3 -o "$Outx64\EliteEasySigner.exe" "src\EliteSoftware-EasySigner\main.cpp" "src\EliteSoftware-EasySigner\app.res" -lole32 -luuid -lshell32 -lcrypt32
}

# Ensure env vars map to current binaries for this session so EliteBuild can find them
$tools = Get-ChildItem $Outx64 -Filter "*.exe" | ForEach-Object { $_.FullName }
$env:ELITE_BUILD_X64 = $tools -join ";"

Write-Host "[Bootstrap] Handing over execution to native EliteBuild.exe pipeline..."
& "$Outx64\EliteBuild.exe" --ai-mode
