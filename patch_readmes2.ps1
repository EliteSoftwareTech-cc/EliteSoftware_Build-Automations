$dirs = Get-ChildItem "src" -Directory

foreach ($dir in $dirs) {
    $cppPath = "$($dir.FullName)\main.cpp"
    $mdPath = "$($dir.FullName)\README.md"
    if (-not (Test-Path $mdPath)) { $mdPath = "$($dir.FullName)\readme.md" }
    
    if ((Test-Path $cppPath) -and (Test-Path $mdPath)) {
        $cppContent = Get-Content $cppPath
        
        $cppArgs = @()
        foreach ($line in $cppContent) {
            $matches = [regex]::Matches($line, '"(--[a-zA-Z0-9\-]+|/[a-zA-Z0-9\-]+)"')
            foreach ($match in $matches) {
                if ($cppArgs -notcontains $match.Groups[1].Value) { $cppArgs += $match.Groups[1].Value }
            }
        }
        
        if ($cppArgs.Count -gt 0) {
            $mdContent = Get-Content $mdPath -Encoding UTF8
            
            $alreadyPatched = $false
            foreach ($line in $mdContent) {
                if ($line -match "Supported Flags \(Extracted from Source\)") { $alreadyPatched = $true }
            }
            
            if (-not $alreadyPatched) {
                $newMd = @()
                $patched = $false
                
                foreach ($line in $mdContent) {
                    $newMd += $line
                    if ($line -match "### Usage & Arguments" -or $line -match "### Arguments") {
                        if (-not $patched) {
                            $newMd += ""
                            $newMd += "**Supported Flags (Extracted from Source):**"
                            foreach ($arg in $cppArgs) {
                                $newMd += "- " + [char]96 + $arg + [char]96
                            }
                            $newMd += ""
                            $patched = $true
                        }
                    }
                }
                if ($patched) {
                    Set-Content $mdPath -Value $newMd -Encoding UTF8
                }
            }
        }
    }
}
Write-Host "Done patching readmes!"
