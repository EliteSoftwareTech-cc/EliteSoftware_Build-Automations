$ErrorActionPreference = 'Stop'
$catalogue = Get-Content "Tool_Catalogue.md" -Raw
$dirs = Get-ChildItem "src" -Directory

$links = @()

foreach ($dir in $dirs) {
    $dirName = $dir.Name
    $existingMd = Get-ChildItem $dir.FullName -Filter "*.md" -ErrorAction SilentlyContinue
    
    $readmePath = ""
    
    if ($existingMd.Count -gt 0) {
        $readmePath = "src/$dirName/$($existingMd[0].Name)"
        $links += "- ?? [$dirName]($readmePath)"
        continue
    }
    
    $readmePath = "src/$dirName/README.md"
    $links += "- ?? [$dirName]($readmePath)"
    
    # Try to find tool in catalogue (e.g. EliteEnvManager.exe)
    $searchName = $dirName.Replace("EliteSoftware-", "Elite")
    if ($searchName -match "CLI|GUI|ShellExt") {
        $searchName = $searchName.Replace("_CLI", "").Replace("_GUI", "").Replace("_ShellExt", "")
    }
    
    $purpose = "A native Win32/C++ utility designed for high-performance execution."
    $features = "- **System Purity:** Zero external dependencies.`n- **Automation:** Support for headless execution."
    $args = "- Execute natively from terminal or invoke via pipeline.`n- Natively supports headless automation."
    
    # Regex to grab block from catalogue
    $pattern = "\*\*$searchName\.exe\*\*(.*?)(?=\*\*Elite|`$)"
    if ($catalogue -match $pattern) {
        $block = $matches[1]
        
        if ($block -match "- \*\*Purpose:\*\* (.*?)(?=`n-)") { $purpose = $matches[1].Trim() }
        if ($block -match "- \*\*Features:\*\* (.*?)(?=`n- \*\*Arguments)") { $features = "- " + $matches[1].Trim() }
        if ($block -match "(?s)- \*\*Arguments:\*\*(.*?)(?=- \*\*Example Command)") { $args = $matches[1].Trim() }
    }
    
    $md = @"
<div align="center"> <a href='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' target='_blank'><img src='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' height='80' border='0' alt='Elite-Software-Company-Logo'></a> </div>

# $dirName

**Information-First Engineering. Absolute System Purity.**

Welcome to the official source repository for **$dirName**. 
This project serves as the digital station for EliteSoftware's engineering initiatives.

## ?? Mission Protocol
$purpose

### Core Focus Areas:
$features

## ??? Workstation Profile 
- **Automation:** Native C++
- **Frameworks:** Windows Win32 API
- **Languages:** C++

## ?? Deployment Information
This utility is designed for high-density deployment in build pipelines.

### Usage & Arguments
$args

--- 
**Lead:** Zachary Whiteman 
**Region:** Fingerlakes, NY   *"Density is efficiency."*
"@
    Set-Content -Path $readmePath -Value $md -Encoding UTF8
}

$rootReadme = Get-Content "README.md"
$newReadme = @()

foreach ($line in $rootReadme) {
    $newReadme += $line
    if ($line -match "### \?\? Quick Links") {
        $newReadme += ""
        $newReadme += "#### ?? Master Tools Source Code"
        foreach ($l in $links) { $newReadme += $l }
        $newReadme += ""
        $newReadme += "#### ?? Documentation Links"
    }
}
Set-Content "README.md" -Value ($newReadme -join "`n") -Encoding UTF8
Write-Host "Done safely generating 44 Readmes and linking them!"
