<#
.SYNOPSIS
EliteBuild_Publisher

.DESCRIPTION
A CLI tool to handle Git operations, Changelog extraction, and GitHub Releases.
Uses arguments, falling back to EliteBuild_Publisher.config if present.

.PARAMETER ConfigFile
Optional config file.
.PARAMETER Version
The version string for the release (e.g. 1.0.0)
.PARAMETER GitAutoCommit
Boolean to run git add, commit, push
.PARAMETER UploadArtifacts
Array of paths to upload to GitHub release.
#>
param (
    [string]$ConfigFile = "EliteBuild_Publisher.config",
    [string]$Version,
    [switch]$GitAutoCommit,
    [string[]]$UploadArtifacts
)

$ErrorActionPreference = 'Stop'
Write-Host "[ EliteBuild_Publisher ]" -ForegroundColor Cyan

$config = @{}
if (Test-Path $ConfigFile) {
    try {
        $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        Write-Host "Loaded config: $ConfigFile" -ForegroundColor Gray
    } catch {
        Write-Warning "Failed to parse config."
    }
}

$doGit = $GitAutoCommit.IsPresent -or $config.GitAutoCommit
if (-not $UploadArtifacts -and $config.UploadArtifacts) { $UploadArtifacts = $config.UploadArtifacts }
if (-not $Version -and $config.Version) { $Version = $config.Version }
if (-not $Version) { $Version = "1.0.0.0" } # Default

if ($doGit) {
    Write-Host "Executing Git Auto-Commit..." -ForegroundColor Green
    git add .
    $commitMsg = "Auto-build and release v$Version"
    if ($config.CommitMessageTemplate) { $commitMsg = $config.CommitMessageTemplate.Replace("{version}", $Version) }
    git commit -m $commitMsg
    
    $branch = if ($config.PushBranch) { $config.PushBranch } else { "master" }
    git push -u origin $branch
}

Write-Host "Compiling Release Notes..." -ForegroundColor Green
$releaseNotes = ""
if (Test-Path "README.md") { $releaseNotes += (Get-Content "README.md" -Raw) + "`r`n`r`n" }

if ($config.ExtractChangelog -and (Test-Path "changelog.md")) {
    $cl = Get-Content "changelog.md" -Raw
    # Extract the block for this version
    if ($cl -match '(?s)(## v' + $Version + '.*?)(?=## v|\z)') {
        $releaseNotes += "## Changelog`r`n" + $matches[1]
    }
}

if (-not $releaseNotes) { $releaseNotes = "Automated release v$Version" }
Set-Content "temp_release_notes.md" -Value $releaseNotes

if ($config.GitHubRelease) {
    Write-Host "Creating GitHub Release (v$Version)..." -ForegroundColor Green
    
    $ghArgs = @("release", "create", "v$Version")
    foreach ($a in $UploadArtifacts) {
        $resolved = $a.Replace("{version}", $Version)
        if (Test-Path $resolved) { $ghArgs += $resolved }
        else { Write-Warning "Artifact not found for release: $resolved" }
    }
    
    $title = if ($config.ReleaseTitleTemplate) { $config.ReleaseTitleTemplate.Replace("{version}", $Version) } else { "Release v$Version" }
    $ghArgs += "--title", $title, "--notes-file", "temp_release_notes.md"
    
    & gh $ghArgs
    if ($LASTEXITCODE -ne 0) { throw "GitHub Release failed." }
}

Remove-Item "temp_release_notes.md" -Force -ErrorAction SilentlyContinue
Write-Host "Publishing complete." -ForegroundColor Green
