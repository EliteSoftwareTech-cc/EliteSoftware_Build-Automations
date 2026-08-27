#Requires -Version 7
<#
.SYNOPSIS
    A PowerShell script with a GUI to convert .PS1 scripts into self-contained .EXE applications.
    This version is hardened to automatically detect and use the latest installed .NET SDK for maximum reliability.

.DESCRIPTION
    This script provides a user-friendly GUI to convert a PowerShell script into an executable. It now uses a robust
    `dotnet build` process, creates a `global.json` file to lock the build to the latest detected SDK,
    and actively searches all drives for the `dotnet.exe` path to bypass environmental issues. The tool includes metadata,
    admin elevation, profile management, and drag-and-drop support.

.NOTES
    Author: Gemini
    Date:   June 21, 2025
    Credit: This script was created for Zach. This version is engineered for maximum environmental resilience.
#>

# ---[ ASSEMBLY AND FORM DEFINITION ]---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Management.Automation

# ---[ GUI CREATION ]---
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "PowerShell to EXE Converter"
$mainForm.Size = New-Object System.Drawing.Size(540, 630)
$mainForm.MinimumSize = $mainForm.Size
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = "FixedSingle"
$mainForm.MaximizeBox = $false
$mainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)

# ---[ UI ELEMENTS ]---
$yPos = 20
$ps1Label = New-Object System.Windows.Forms.Label
$ps1Label.Text = "PowerShell Script (.ps1):"
$ps1Label.Location = New-Object System.Drawing.Point(20, $yPos); $ps1Label.AutoSize = $true
$mainForm.Controls.Add($ps1Label)
$yPos += 25
$ps1TextBox = New-Object System.Windows.Forms.TextBox
$ps1TextBox.Location = New-Object System.Drawing.Point(20, $yPos); $ps1TextBox.Size = New-Object System.Drawing.Size(370, 20)
$ps1TextBox.Anchor = "Top, Left, Right"; $ps1TextBox.AllowDrop = $true
$mainForm.Controls.Add($ps1TextBox)
$browsePs1Button = New-Object System.Windows.Forms.Button
$browsePs1Button.Text = "Browse..."; $browsePs1Button.Location = New-Object System.Drawing.Point(400, ($yPos - 2))
$browsePs1Button.Size = New-Object System.Drawing.Size(100, 25); $browsePs1Button.Anchor = "Top, Right"
$mainForm.Controls.Add($browsePs1Button)
$yPos += 40
$iconLabel = New-Object System.Windows.Forms.Label
$iconLabel.Text = "Icon File (.ico):"
$iconLabel.Location = New-Object System.Drawing.Point(20, $yPos); $iconLabel.AutoSize = $true
$mainForm.Controls.Add($iconLabel)
$yPos += 25
$iconTextBox = New-Object System.Windows.Forms.TextBox
$iconTextBox.Location = New-Object System.Drawing.Point(20, $yPos); $iconTextBox.Size = New-Object System.Drawing.Size(370, 20)
$iconTextBox.Anchor = "Top, Left, Right"; $iconTextBox.AllowDrop = $true
$mainForm.Controls.Add($iconTextBox)
$browseIconButton = New-Object System.Windows.Forms.Button
$browseIconButton.Text = "Browse..."; $browseIconButton.Location = New-Object System.Drawing.Point(400, ($yPos - 2))
$browseIconButton.Size = New-Object System.Drawing.Size(100, 25); $browseIconButton.Anchor = "Top, Right"
$mainForm.Controls.Add($browseIconButton)
$yPos += 45
$groupFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$metadataGroupBox = New-Object System.Windows.Forms.GroupBox
$metadataGroupBox.Text = "File Metadata & Options"; $metadataGroupBox.Font = $groupFont
$metadataGroupBox.Location = New-Object System.Drawing.Point(20, $yPos); $metadataGroupBox.Size = New-Object System.Drawing.Size(480, 230)
$metadataGroupBox.Anchor = "Top, Left, Right"
$mainForm.Controls.Add($metadataGroupBox)

function Add-MetadataField {
    param($parent, $labelText, $y, [ref]$textBox)
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $labelText; $label.Location = New-Object System.Drawing.Point(15, $y); $label.AutoSize = $true
    $parent.Controls.Add($label)
    $textBox.Value = New-Object System.Windows.Forms.TextBox
    $textBox.Value.Location = New-Object System.Drawing.Point(160, ($y - 3)); $textBox.Value.Size = New-Object System.Drawing.Size(300, 20)
    $textBox.Value.Anchor = "Top, Left, Right"; $parent.Controls.Add($textBox.Value)
}

$metaY = 30
$productTextBox, $descriptionTextBox, $companyTextBox, $copyrightTextBox, $versionTextBox = $null, $null, $null, $null, $null
Add-MetadataField $metadataGroupBox "Product Name:" $metaY ([ref]$productTextBox); $metaY += 30
Add-MetadataField $metadataGroupBox "Description:" $metaY ([ref]$descriptionTextBox); $metaY += 30
Add-MetadataField $metadataGroupBox "Company Name:" $metaY ([ref]$companyTextBox); $metaY += 30
Add-MetadataField $metadataGroupBox "Copyright:" $metaY ([ref]$copyrightTextBox)
$copyrightTextBox.Text = "Copyright © $(Get-Date -Format 'yyyy')"; $metaY += 30
Add-MetadataField $metadataGroupBox "File Version (e.g., 1.0.0.0):" $metaY ([ref]$versionTextBox)
$versionTextBox.Text = "1.0.0.0"; $metaY += 40
$runAsAdminCheckBox = New-Object System.Windows.Forms.CheckBox
$runAsAdminCheckBox.Text = "Require Administrator Privileges"; $runAsAdminCheckBox.Location = New-Object System.Drawing.Point(160, $metaY)
$runAsAdminCheckBox.AutoSize = $true; $metadataGroupBox.Controls.Add($runAsAdminCheckBox)
$yPos += 250
$buttonFont = New-Object System.Drawing.Font("Segoe UI", 10)
$loadProfileButton = New-Object System.Windows.Forms.Button
$loadProfileButton.Text = "Load Profile"; $loadProfileButton.Font = $buttonFont
$loadProfileButton.Location = New-Object System.Drawing.Point(20, $yPos); $loadProfileButton.Size = New-Object System.Drawing.Size(115, 35)
$mainForm.Controls.Add($loadProfileButton)
$saveProfileButton = New-Object System.Windows.Forms.Button
$saveProfileButton.Text = "Save Profile"; $saveProfileButton.Font = $buttonFont
$saveProfileButton.Location = New-Object System.Drawing.Point(145, $yPos); $saveProfileButton.Size = New-Object System.Drawing.Size(115, 35)
$mainForm.Controls.Add($saveProfileButton)
$resetButton = New-Object System.Windows.Forms.Button
$resetButton.Text = "Reset"; $resetButton.Font = $buttonFont
$resetButton.Location = New-Object System.Drawing.Point(270, $yPos); $resetButton.Size = New-Object System.Drawing.Size(115, 35)
$mainForm.Controls.Add($resetButton)
$createExeButton = New-Object System.Windows.Forms.Button
$createExeButton.Text = "Create EXE"
$createExeButton.Location = New-Object System.Drawing.Point(395, ($yPos - 5))
$createExeButton.Size = New-Object System.Drawing.Size(105, 45); $createExeButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$mainForm.Controls.Add($createExeButton)
$yPos += 55
$statusBar = New-Object System.Windows.Forms.Label
$statusBar.Text = "Ready"; $statusBar.Location = New-Object System.Drawing.Point(20, $yPos)
$statusBar.Size = New-Object System.Drawing.Size(480, 20); $mainForm.Controls.Add($statusBar)
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, ($yPos + 20)); 
$progressBar.Size = New-Object System.Drawing.Size(480, 20)
$progressBar.Style = "Continuous"; $mainForm.Controls.Add($progressBar)

# ---[ HELPER FUNCTIONS ]---
function Find-DotNetExe {
    $dotnetExe = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($dotnetExe) { return $dotnetExe.Source }

    $searchPaths = @()
    $drives = Get-PSDrive -PSProvider FileSystem
    foreach ($drive in $drives) {
        $searchPaths += Join-Path $drive.Root "Program Files\dotnet\dotnet.exe"
        $searchPaths += Join-Path $drive.Root "Program Files (x86)\dotnet\dotnet.exe"
    }
    
    foreach ($path in $searchPaths) {
        if (Test-Path -LiteralPath $path) {
            return $path
        }
    }
    return $null
}

function Get-LatestSdk($dotnetExePath) {
    if (-not $dotnetExePath) { return $null, $null }
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $dotnetExePath
    $processInfo.Arguments = "--list-sdks"
    $processInfo.RedirectStandardOutput = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($processInfo)
    $sdkOutput = $process.StandardOutput.ReadToEnd()
    $process.WaitForExit()

    # Match any valid SDK version string (e.g., 6.0.417, 9.0.100-preview.5)
    $versions = $sdkOutput | Select-String -Pattern '\b(\d+\.\d+\.[\d\w-]+)' | ForEach-Object { 
        try {
            # Create a comparable version object. For previews, we only consider the main version part.
            $versionString = $_.Matches.Groups[1].Value.Split('-')[0]
            [System.Version]::new($versionString)
        } catch {} 
    }
    
    if (-not $versions) { return $null, $null }

    # Sort to find the absolute latest version
    $latestVersion = $versions | Sort-Object -Descending | Select-Object -First 1

    if (-not $latestVersion) { return $null, $null }
    
    # Re-run to get the full SDK string for global.json
    $fullSdkString = ($sdkOutput | Select-String -Pattern "\b$($latestVersion.Major)\.$($latestVersion.Minor)\.[\d\w-]+" | Select-Object -First 1).ToString().Split(' ')[0]
    $targetFramework = "net$($latestVersion.Major).$($latestVersion.Minor)-windows"
    
    return $fullSdkString, $targetFramework
}

# ---[ EVENT HANDLERS (LOGIC) ]---
$browsePs1Button.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Select a PowerShell Script"; $openFileDialog.Filter = "PowerShell Scripts (*.ps1)|*.ps1"
    if ($openFileDialog.ShowDialog() -eq "OK") {
        $ps1TextBox.Text = $openFileDialog.FileName
        if (-not $productTextBox.Text) {
            $productTextBox.Text = [System.IO.Path]::GetFileNameWithoutExtension($openFileDialog.FileName)
            $descriptionTextBox.Text = "$($productTextBox.Text) Application"
        }
        $statusBar.Text = "Script selected."
    }
})

$browseIconButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Select an Icon"; $openFileDialog.Filter = "Icon Files (*.ico)|*.ico"
    if ($openFileDialog.ShowDialog() -eq "OK") { $iconTextBox.Text = $openFileDialog.FileName; $statusBar.Text = "Icon selected." }
})

$ps1TextBox.Add_DragEnter({ param($s, $e)
    if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop) -and ($e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)[0] -like '*.ps1')) {
        $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    } else { $e.Effect = [System.Windows.Forms.DragDropEffects]::None } })
$ps1TextBox.Add_DragDrop({ param($s, $e)
    $files = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    if ($files.Count -gt 0 -and $files[0] -like '*.ps1') {
        $ps1TextBox.Text = $files[0]
        if (-not $productTextBox.Text) { $productTextBox.Text = [System.IO.Path]::GetFileNameWithoutExtension($files[0]); $descriptionTextBox.Text = "$($productTextBox.Text) Application" }
        $statusBar.Text = "Script dropped."
    }
})
$iconTextBox.Add_DragEnter({ param($s, $e)
    if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop) -and ($e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)[0] -like '*.ico')) {
        $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    } else { $e.Effect = [System.Windows.Forms.DragDropEffects]::None } })
$iconTextBox.Add_DragDrop({ param($s, $e)
    $files = $e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    if ($files.Count -gt 0 -and $files[0] -like '*.ico') { $iconTextBox.Text = $files[0]; $statusBar.Text = "Icon dropped." } })

$saveProfileButton.Add_Click({
    $saveProfileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveProfileDialog.Title = "Save Profile"; $saveProfileDialog.Filter = "PS2EXE Profile (*.json)|*.json"
    $saveProfileDialog.FileName = "$($productTextBox.Text).json"
    if ($saveProfileDialog.ShowDialog() -eq "OK") {
        $profileData = @{
            ProductName = $productTextBox.Text; Description = $descriptionTextBox.Text
            Company = $companyTextBox.Text; Copyright = $copyrightTextBox.Text
            Version = $versionTextBox.Text; IconPath = $iconTextBox.Text
            RunAsAdmin = $runAsAdminCheckBox.Checked
        }
        $profileData | ConvertTo-Json | Set-Content -Path $saveProfileDialog.FileName -Encoding UTF8
        $statusBar.Text = "Profile saved."
    }
})

$loadProfileButton.Add_Click({
    $openProfileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openProfileDialog.Title = "Load Profile"; $openProfileDialog.Filter = "PS2EXE Profile (*.json)|*.json"
    if ($openProfileDialog.ShowDialog() -eq "OK") {
        try {
            $profileData = Get-Content -Path $openProfileDialog.FileName -Raw | ConvertFrom-Json
            $productTextBox.Text = $profileData.ProductName; $descriptionTextBox.Text = $profileData.Description
            $companyTextBox.Text = $profileData.Company; $copyrightTextBox.Text = $profileData.Copyright
            $versionTextBox.Text = $profileData.Version; $iconTextBox.Text = $profileData.IconPath
            $runAsAdminCheckBox.Checked = $profileData.RunAsAdmin
            $statusBar.Text = "Profile loaded."
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to load or parse the profile file.", "Load Failed", "OK", "Error")
            $statusBar.Text = "Profile load failed."
        }
    }
})

$resetButton.Add_Click({
    $ps1TextBox.Text = ""; $iconTextBox.Text = ""; $productTextBox.Text = ""; $descriptionTextBox.Text = ""
    $companyTextBox.Text = ""; $versionTextBox.Text = "1.0.0.0"
    $copyrightTextBox.Text = "Copyright © $(Get-Date -Format 'yyyy')"; $runAsAdminCheckBox.Checked = $false
    $statusBar.Text = "Fields cleared. Ready."; $progressBar.Value = 0
})

$createExeButton.Add_Click({
    $errors = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path -LiteralPath $ps1TextBox.Text -PathType Leaf)) { $errors.Add("• The PowerShell script file does not exist.") }
    if (-not (Test-Path -LiteralPath $iconTextBox.Text -PathType Leaf) -or $iconTextBox.Text -notlike "*.ico") { $errors.Add("• The icon file does not exist or is not a .ico file.") }
    try { [void][System.Version]::new($versionTextBox.Text) } catch { $errors.Add("• File Version is invalid. Use format '1.0.0' or '1.0.0.0'.") }
    
    $dotnetExePath = Find-DotNetExe
    if (-not $dotnetExePath) {
        $errors.Add("• Could not find dotnet.exe. Please ensure the .NET SDK is installed.")
    } else {
        $sdkVersion, $targetFramework = Get-LatestSdk -dotnetExePath $dotnetExePath
        if (-not $sdkVersion) {
            $errors.Add("• Could not detect any installed .NET SDKs. This tool requires a .NET SDK (6.0 or higher). Please install one from https://dotnet.microsoft.com/download")
        }
    }
    
    if ($errors.Count -gt 0) {
        [System.Windows.Forms.MessageBox]::Show(($errors -join "`n`n"), "Validation Failed", "OK", "Error"); $statusBar.Text = "Validation failed."; return
    }
    
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Title = "Save Executable As"; $saveFileDialog.Filter = "Executable File (*.exe)|*.exe"; $saveFileDialog.FileName = "$($productTextBox.Text).exe"
    if ($saveFileDialog.ShowDialog() -ne "OK") { $statusBar.Text = "Save cancelled."; return }
    $exePath = $saveFileDialog.FileName

    $buildDir = [System.IO.Path]::Combine($env:TEMP, [System.IO.Path]::GetRandomFileName())
    try {
        $createExeButton.Enabled = $false; $mainForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $statusBar.Text = "Creating build environment..."; $progressBar.Value = 10; $mainForm.Refresh()
        New-Item -Path $buildDir -ItemType Directory | Out-Null

        $globalJsonContent = @{ sdk = @{ version = $sdkVersion; rollForward = "latestPatch" } } | ConvertTo-Json
        Set-Content -Path (Join-Path $buildDir "global.json") -Value $globalJsonContent -Encoding Utf8

        $escapedPs1Content = (Get-Content -Path $ps1TextBox.Text -Raw) -replace '"', '""'
        $mainCsSource = (@'
using System; using System.Text; using System.Collections.ObjectModel; using System.Management.Automation; using System.Windows.Forms;
public class PowerShellRunner {
    [STAThread] public static void Main() {
        try {
            string scriptContents = @"{0}";
            using (PowerShell ps = PowerShell.Create()) { ps.AddScript(scriptContents).Invoke(); }
        } catch (Exception e) {
            StringBuilder sb = new StringBuilder();
            sb.AppendLine("An error occurred while running the script:");
            sb.AppendLine(e.GetType().FullName);
            sb.AppendLine(e.Message);
            sb.AppendLine().AppendLine("Stack Trace:").AppendLine(e.StackTrace);
            if (e.InnerException != null) { sb.AppendLine().AppendLine("Inner Exception:").AppendLine(e.InnerException.ToString()); }
            MessageBox.Show(sb.ToString(), "PowerShell Script Execution Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
'@).Replace("{0}", $escapedPs1Content)
        Set-Content -Path (Join-Path $buildDir "Program.cs") -Value $mainCsSource -Encoding Utf8

        $statusBar.Text = "Creating project file for $targetFramework..."; $progressBar.Value = 30; $mainForm.Refresh()
        $version = [System.Version]::new($versionTextBox.Text)
        $tempIconPath = Join-Path $buildDir "icon.ico"
        Copy-Item -Path $iconTextBox.Text -Destination $tempIconPath

        $csprojContent = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>$targetFramework</TargetFramework>
    <UseWindowsForms>true</UseWindowsForms>
    <ImplicitUsings>disable</ImplicitUsings>
    <Nullable>disable</Nullable>
    <AssemblyName>$($productTextBox.Text)</AssemblyName>
    <AssemblyVersion>$($version.ToString())</AssemblyVersion>
    <FileVersion>$($version.ToString())</FileVersion>
    <Company>$($companyTextBox.Text)</Company>
    <Product>$($productTextBox.Text)</Product>
    <Description>$($descriptionTextBox.Text)</Description>
    <Copyright>$($copyrightTextBox.Text)</Copyright>
    <ApplicationIcon>icon.ico</ApplicationIcon>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="System.Management.Automation" Version="7.4.2" />
  </ItemGroup>
</Project>
"@
        if ($runAsAdminCheckBox.Checked) {
            $manifestContent = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0"><trustInfo xmlns="urn:schemas-microsoft-com:asm.v3"><security><requestedPrivileges><requestedExecutionLevel level="requireAdministrator" uiAccess="false" /></requestedPrivileges></security></trustInfo></assembly>'
            $csprojContent = $csprojContent.Replace("</PropertyGroup>", "<ApplicationManifest>app.manifest</ApplicationManifest></PropertyGroup>")
            Set-Content -Path (Join-Path $buildDir "app.manifest") -Value $manifestContent -Encoding Utf8
        }
        Set-Content -Path (Join-Path $buildDir "Project.csproj") -Value $csprojContent -Encoding Utf8

        $statusBar.Text = "Running dotnet publish..."; $progressBar.Value = 60; $mainForm.Refresh()
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $dotnetExePath # Use the full path we found
        $processInfo.Arguments = "publish -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true /p:PublishTrimmed=true"
        $processInfo.WorkingDirectory = $buildDir
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        $process = [System.Diagnostics.Process]::Start($processInfo)
        $stdOut = $process.StandardOutput.ReadToEnd()
        $stdErr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()

        if ($process.ExitCode -ne 0) {
            throw "dotnet publish failed.`n`nSTDOUT:`n$stdOut`n`nSTDERR:`n$stdErr"
        }

        $statusBar.Text = "Copying artifacts..."; $progressBar.Value = 90; $mainForm.Refresh()
        $publishDir = Join-Path $buildDir "bin\Release\$targetFramework\win-x64\publish"
        $builtExe = Join-Path $publishDir "$($productTextBox.Text).exe"
        Copy-Item -Path $builtExe -Destination $exePath -Force
        
        $progressBar.Value = 100
        $statusBar.Text = "Success! EXE created."
        [System.Windows.Forms.MessageBox]::Show("Successfully created '$([System.IO.Path]::GetFileName($exePath))'!`n`nThe file is self-contained and ready to run.", "Success", "OK", "Information")
    }
    catch {
        $statusBar.Text = "A fatal error occurred."; $progressBar.Value = 0
        [System.Windows.Forms.MessageBox]::Show("An unexpected error occurred during the build process:`n`n$($_.Exception.Message)", "Fatal Error", "OK", "Error")
    }
    finally {
        if (Test-Path -Path $buildDir) { Remove-Item -Path $buildDir -Recurse -Force -ErrorAction SilentlyContinue }
        $createExeButton.Enabled = $true; $mainForm.Cursor = [System.Windows.Forms.Cursors]::Default
        $progressBar.Style = "Continuous"
    }
})

# ---[ SHOW THE FORM ]---
$mainForm.Add_Shown({$mainForm.Activate()})
[void]$mainForm.ShowDialog()
