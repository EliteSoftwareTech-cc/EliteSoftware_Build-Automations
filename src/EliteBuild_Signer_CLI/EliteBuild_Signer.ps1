<#
.SYNOPSIS
EliteBuild_Signer

.DESCRIPTION
A CLI tool to handle Authenticode signing.
Uses arguments, falling back to EliteBuild_Signer.config if present.

.PARAMETER ConfigFile
Optional config file
.PARAMETER PfxPath
Path to the PFX certificate.
.PARAMETER PfxPassword
Password for the PFX.
.PARAMETER Targets
Array of file paths to sign.
#>
param (
    [string]$ConfigFile = "EliteBuild_Signer.config",
    [string]$PfxPath,
    [string]$PfxPassword,
    [string[]]$Targets
)

$ErrorActionPreference = 'Stop'
Write-Host "[ EliteBuild_Signer ]" -ForegroundColor Cyan

$config = @{}
if (Test-Path $ConfigFile) {
    try {
        $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        Write-Host "Loaded config: $ConfigFile" -ForegroundColor Gray
    } catch {
        Write-Warning "Failed to parse config."
    }
}

if (-not $PfxPath -and $config.PfxPath) { $PfxPath = $config.PfxPath }
if (-not $PfxPath) { $PfxPath = "C:\EliteSoftware PE TOOLS\Elite-EasySigner\EliteSoftware_Special.pfx" }

if (-not $PfxPassword -and $config.PfxPasswordEnvVar) { $PfxPassword = [Environment]::GetEnvironmentVariable($config.PfxPasswordEnvVar) }
if (-not $PfxPassword -and $config.PfxPassword) { $PfxPassword = $config.PfxPassword }
if (-not $PfxPassword) { $PfxPassword = "Minecraft145!!" }

if (-not $Targets -and $config.Targets) { $Targets = $config.Targets }

if (-not $Targets) {
    Write-Error "No targets specified to sign."
    exit 1
}

if (-not (Test-Path $PfxPath)) {
    Write-Error "PFX certificate not found at $PfxPath"
    exit 1
}

# Find signtool
$sdkRoot = "C:\Program Files (x86)\Windows Kits"
$signtool = "signtool.exe"
if (Test-Path $sdkRoot) {
    $versions = Get-ChildItem -Path (Join-Path $sdkRoot "10\bin") -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    foreach ($v in $versions) {
        $p = Join-Path $v.FullName "x64\signtool.exe"
        if (Test-Path $p) { $signtool = $p; break }
    }
}

foreach ($target in $Targets) {
    $resolvedTarget = Resolve-Path $target -ErrorAction SilentlyContinue
    if ($resolvedTarget) {
        Write-Host "Signing $target..." -ForegroundColor Green
        & $signtool sign /f $PfxPath /p $PfxPassword /fd SHA256 /v $resolvedTarget
        if ($LASTEXITCODE -ne 0) { throw "Failed to sign $target" }
    } else {
        Write-Warning "Target not found: $target"
    }
}
Write-Host "Signing complete." -ForegroundColor Green
