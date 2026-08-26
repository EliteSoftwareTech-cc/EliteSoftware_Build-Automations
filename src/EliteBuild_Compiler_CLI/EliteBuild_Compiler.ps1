<#
.SYNOPSIS
EliteBuild_Compiler

.DESCRIPTION
A CLI tool to handle MSBuild compilation and pre-build tasks (process killing).
Uses arguments, falling back to EliteBuild_Compiler.config if present.

.PARAMETER ConfigFile
Optional config file (default: EliteBuild_Compiler.config)
.PARAMETER SlnPaths
Array of solution paths to compile.
.PARAMETER Architectures
Array of architectures to build (e.g., x86, x64).
.PARAMETER KillProcesses
Array of processes to kill before building.
.PARAMETER MSBuildPath
Path to MSBuild.exe
#>
param (
    [string]$ConfigFile = "EliteBuild_Compiler.config",
    [string[]]$SlnPaths,
    [string[]]$Architectures,
    [string[]]$KillProcesses,
    [string]$MSBuildPath
)

$ErrorActionPreference = 'Stop'
Write-Host "[ EliteBuild_Compiler ]" -ForegroundColor Cyan

# Parse Config if it exists
$config = @{}
if (Test-Path $ConfigFile) {
    try {
        $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        Write-Host "Loaded config: $ConfigFile" -ForegroundColor Gray
    } catch {
        Write-Warning "Failed to parse $ConfigFile. Ensure it is valid JSON."
    }
}

# Resolve Arguments (CLI > Config > Default)
if (-not $SlnPaths -and $config.SlnPaths) { $SlnPaths = $config.SlnPaths }
if (-not $Architectures -and $config.Architectures) { $Architectures = $config.Architectures }
if (-not $Architectures) { $Architectures = @("x86", "x64") }
if (-not $KillProcesses -and $config.KillProcesses) { $KillProcesses = $config.KillProcesses }
if (-not $MSBuildPath -and $config.MSBuildPath) { $MSBuildPath = $config.MSBuildPath }
if (-not $MSBuildPath) { $MSBuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe" }

if (-not $SlnPaths) {
    Write-Error "No solution paths provided via CLI or Config!"
    exit 1
}

if ($KillProcesses) {
    Write-Host "Killing pre-build processes..." -ForegroundColor Yellow
    foreach ($proc in $KillProcesses) {
        $procName = [System.IO.Path]::GetFileNameWithoutExtension($proc)
        Get-Process -Name $procName -ErrorAction SilentlyContinue | Stop-Process -Force
    }
    Start-Sleep -Seconds 1
}

foreach ($sln in $SlnPaths) {
    if (-not (Test-Path $sln)) { Write-Warning "Solution not found: $sln"; continue }
    foreach ($arch in $Architectures) {
        Write-Host "Compiling $sln ($arch)..." -ForegroundColor Green
        $platform = if ($arch -eq "x86") { "Win32" } else { "x64" }
        & $MSBuildPath $sln /p:Configuration=Release /p:Platform=$platform /m
        if ($LASTEXITCODE -ne 0) { throw "Compilation failed for $sln ($arch)" }
    }
}
if ($config.Compiler.GccTargets) {
    Write-Host "Starting MinGW/G++ Compilation Phase..." -ForegroundColor Yellow
    foreach ($target in $config.Compiler.GccTargets) {
        Write-Host "Building MinGW Target: $($target.Output)" -ForegroundColor Cyan
        
        # Compile Resources if specified
        if ($target.Windres) {
            Write-Host "  -> Compiling resources: $($target.Windres.Input)" -ForegroundColor DarkGray
            & "windres" $target.Windres.Input -o $target.Windres.Output
            if ($LASTEXITCODE -ne 0) { throw "Windres failed for $($target.Windres.Input)" }
        }
        
        # Compile C++ source
        $gppArgs = @()
        if ($target.IsShared) { $gppArgs += "-shared" }
        $gppArgs += "-o", $target.Output
        $gppArgs += $target.Sources
        if ($target.Libraries) { $gppArgs += $target.Libraries }
        
        Write-Host "  -> Linking: $($target.Output)" -ForegroundColor DarkGray
        & "g++" $gppArgs
        if ($LASTEXITCODE -ne 0) { throw "g++ compilation failed for $($target.Output)" }
    }
}

Write-Host "Compilation complete." -ForegroundColor Green
