$dirs = Get-ChildItem "src" -Directory
$links = @()
foreach ($dir in $dirs) {
    $existingMd = Get-ChildItem $dir.FullName -Filter "*.md" -ErrorAction SilentlyContinue
    if ($existingMd.Count -gt 0) {
        $links += "- ?? [$($dir.Name)](src/$($dir.Name)/$($existingMd[0].Name))"
    }
}

$rootReadme = Get-Content "README.md" -Encoding UTF8
$newReadme = @()

foreach ($line in $rootReadme) {
    $newReadme += $line
    if ($line -match "Quick Links") {
        $newReadme += ""
        $newReadme += "#### ?? Master Tools Source Code"
        foreach ($l in $links) { $newReadme += $l }
        $newReadme += ""
        $newReadme += "#### ?? Documentation Links"
    }
}
Set-Content "README.md" -Value ($newReadme -join "`n") -Encoding UTF8
Write-Host "Done linking!"
