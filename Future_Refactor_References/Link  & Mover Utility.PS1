<#
.SYNOPSIS
A GUI application for creating and managing symbolic links and directory junctions with advanced move features.
.DESCRIPTION
This PowerShell script provides a user-friendly graphical interface for:
- Creating symbolic links for files and directories.
- Creating directory junctions.
- Securely moving an entire directory to a new location and linking back, with an option to create a "return link" at the destination.
- Selectively moving specific files/folders from a directory and linking them back individually.
- Displaying live previews (icon, name, size) of selected folders.
- A persistent, resizable activity log.
.NOTES
Linker & Mover Utility v1.3 - Created by: Zachary Whiteman & Google Gemini Ai.
Date: 7/18/2025 - 3:28 AM
Requires administrative privileges to create links. The script will attempt to self-elevate if not run as an administrator.
v1.3 Update: Major UI overhaul. Added persistent log viewer, folder preview panels (icon, name, size), and a "return link" feature for the Bulk Move operation.
#>

#region --- Admin Check and Self-Elevation ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}
#endregion

#region --- Assembly Loading and GUI Setup ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
#endregion

#region --- Main Form Definition ---
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Linker & Mover Utility v1.3 (ComputerCare Co.)"
$mainForm.Size = New-Object System.Drawing.Size(640, 720)
$mainForm.MinimumSize = New-Object System.Drawing.Size(620, 600)
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = 'Sizable'
$mainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Command "powershell.exe").Path)
#endregion

#region --- Helper Functions ---
function Write-Log {
    param([string]$Message)
    # Ensure UI updates happen on the main thread
    $mainForm.Invoke([Action]{
        $logTextBox.AppendText("$(Get-Date -Format 'HH:mm:ss') - $Message`r`n")
        $logTextBox.ScrollToCaret()
    })
}

# --- Function to update the preview panels ---
function Update-PreviewPanel {
    param($path, $groupBox, $pictureBox, $labelName, $labelSize)
    $groupBox.Text = "Preview"
    $labelName.Text = "Name: "
    $labelSize.Text = "Size: "
    $pictureBox.Image = $null

    if (-not (Test-Path $path)) { return }

    try {
        $item = Get-Item -LiteralPath $path
        $groupBox.Text = "Preview: $($item.Name)"
        $labelName.Text = "Name: $($item.Name)"
        $pictureBox.Image = [System.Drawing.Icon]::ExtractAssociatedIcon($item.FullName).ToBitmap()

        if ($item.PSIsContainer) {
            $labelSize.Text = "Size: Calculating..."
            Write-Log "Calculating size for '$($item.FullName)'... This may take a moment."
            # Use a background job for size calculation to keep the GUI responsive
            $job = Start-Job -ScriptBlock {
                param($targetPath)
                $colItems = Get-ChildItem -LiteralPath $targetPath -Recurse -Force -ErrorAction SilentlyContinue
                $sum = ($colItems | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                return $sum
            } -ArgumentList $item.FullName

            Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
                if ($sender.State -eq 'Completed') {
                    $sizeInBytes = Receive-Job -Job $sender
                    $sizeFormatted = ""
                    if ($sizeInBytes -ge 1GB) { $sizeFormatted = "{0:N2} GB" -f ($sizeInBytes / 1GB) }
                    elseif ($sizeInBytes -ge 1MB) { $sizeFormatted = "{0:N2} MB" -f ($sizeInBytes / 1MB) }
                    elseif ($sizeInBytes -ge 1KB) { $sizeFormatted = "{0:N2} KB" -f ($sizeInBytes / 1KB) }
                    else { $sizeFormatted = "$sizeInBytes Bytes" }
                    $mainForm.Invoke([Action]{ $labelSize.Text = "Size: $sizeFormatted" })
                    Write-Log "Size calculation complete for '$($item.FullName)'."
                }
                Unregister-Event -SourceIdentifier $sender.Name
                Remove-Job -Job $sender
            } | Out-Null
        } else {
            $sizeInBytes = $item.Length
            if ($sizeInBytes -ge 1GB) { $labelSize.Text = "Size: {0:N2} GB" -f ($sizeInBytes / 1GB) }
            elseif ($sizeInBytes -ge 1MB) { $labelSize.Text = "Size: {0:N2} MB" -f ($sizeInBytes / 1MB) }
            elseif ($sizeInBytes -ge 1KB) { $labelSize.Text = "Size: {0:N2} KB" -f ($sizeInBytes / 1KB) }
            else { $labelSize.Text = "Size: $sizeInBytes Bytes" }
        }
    } catch {
        $pictureBox.Image = [System.Drawing.SystemIcons]::Error.ToBitmap()
        Write-Log "ERROR: Could not get information for path '$path'."
    }
}

# (Other helper functions from v1.2 are still here but omitted for brevity in this comment block)
function Populate-TreeView { param($directory, $parentNode) ; try { Get-ChildItem -Path $directory -Force -ErrorAction Stop | ForEach-Object { $node = New-Object System.Windows.Forms.TreeNode($_.Name); $node.Tag = $_.FullName; if ($parentNode) { $parentNode.Nodes.Add($node) } else { $sm_treeView.Nodes.Add($node) }; if ($_.PSIsContainer) { Populate-TreeView $_.FullName $node } } } catch { Write-Log "ERROR: Could not access path '$directory'. Details: $($_.Exception.Message)" } }
function Get-CheckedNodes { param($nodes); $checkedNodes = New-Object System.Collections.Generic.List[System.Windows.Forms.TreeNode]; foreach ($node in $nodes) { if ($node.Checked) { $checkedNodes.Add($node) }; if ($node.Nodes.Count -gt 0) { $checkedNodes.AddRange((Get-CheckedNodes $node.Nodes)) } }; return $checkedNodes }
#endregion

#region --- GUI Element Definitions ---

# --- Main Layout: Split Container ---
$mainSplitContainer = New-Object System.Windows.Forms.SplitContainer
$mainSplitContainer.Dock = 'Fill'
$mainSplitContainer.Orientation = 'Horizontal'
$mainForm.Controls.Add($mainSplitContainer)

# --- Top Panel: Tabs ---
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Dock = 'Fill'
$mainSplitContainer.Panel1.Controls.Add($tabControl)

# --- Bottom Panel: Log Viewer ---
$logGroupBox = New-Object System.Windows.Forms.GroupBox; $logGroupBox.Text = "Activity Log"; $logGroupBox.Dock = 'Fill'
$logTextBox = New-Object System.Windows.Forms.TextBox; $logTextBox.Multiline = $true; $logTextBox.ScrollBars = "Vertical"; $logTextBox.ReadOnly = $true; $logTextBox.Dock = 'Fill'; $logTextBox.Font = New-Object System.Drawing.Font("Consolas", 9); $logGroupBox.Controls.Add($logTextBox)
$clearLogButton = New-Object System.Windows.Forms.Button; $clearLogButton.Text = "Clear Log"; $clearLogButton.Dock = 'Top'; $logGroupBox.Controls.Add($clearLogButton)
$mainSplitContainer.Panel2.Controls.Add($logGroupBox)
$mainSplitContainer.SplitterDistance = 450

# --- Tab Pages ---
$createLinkTabPage = New-Object System.Windows.Forms.TabPage; $createLinkTabPage.Text = "Create Link / Junction"; $tabControl.Controls.Add($createLinkTabPage)
$moveLinkTabPage = New-Object System.Windows.Forms.TabPage; $moveLinkTabPage.Text = "Bulk Move & Link"; $tabControl.Controls.Add($moveLinkTabPage)
$selectiveMoveTabPage = New-Object System.Windows.Forms.TabPage; $selectiveMoveTabPage.Text = "Selective Move & Link"; $tabControl.Controls.Add($selectiveMoveTabPage)

# --- Controls for "Create Link" Tab ---
# (Unchanged from v1.2, layout adjusted for new form size)
$cl_group = New-Object System.Windows.Forms.GroupBox; $cl_group.Text = "Link Properties"; $cl_group.Size = New-Object System.Drawing.Size(590, 230); $cl_group.Location = New-Object System.Drawing.Point(10, 10); $cl_group.Anchor = 'Top, Left, Right'; $createLinkTabPage.Controls.Add($cl_group)
# ... (rest of controls are the same, just using more compact notation here)
$cl_labelLink = New-Object System.Windows.Forms.Label; $cl_labelLink.Text = "Link / Junction Path (Source):"; $cl_labelLink.Location = New-Object System.Drawing.Point(10, 30); $cl_labelLink.AutoSize = $true; $cl_group.Controls.Add($cl_labelLink)
$cl_textLinkPath = New-Object System.Windows.Forms.TextBox; $cl_textLinkPath.Location = New-Object System.Drawing.Point(10, 50); $cl_textLinkPath.Size = New-Object System.Drawing.Size(470, 20); $cl_textLinkPath.Anchor = 'Top, Left, Right'; $cl_group.Controls.Add($cl_textLinkPath)
$cl_buttonBrowseLink = New-Object System.Windows.Forms.Button; $cl_buttonBrowseLink.Text = "Browse..."; $cl_buttonBrowseLink.Location = New-Object System.Drawing.Point(490, 48); $cl_buttonBrowseLink.Size = New-Object System.Drawing.Size(85, 25); $cl_buttonBrowseLink.Anchor = 'Top, Right'; $cl_group.Controls.Add($cl_buttonBrowseLink)
$cl_labelTarget = New-Object System.Windows.Forms.Label; $cl_labelTarget.Text = "Target Path (Destination):"; $cl_labelTarget.Location = New-Object System.Drawing.Point(10, 90); $cl_labelTarget.AutoSize = $true; $cl_group.Controls.Add($cl_labelTarget)
$cl_textTargetPath = New-Object System.Windows.Forms.TextBox; $cl_textTargetPath.Location = New-Object System.Drawing.Point(10, 110); $cl_textTargetPath.Size = New-Object System.Drawing.Size(470, 20); $cl_textTargetPath.Anchor = 'Top, Left, Right'; $cl_group.Controls.Add($cl_textTargetPath)
$cl_buttonBrowseTarget = New-Object System.Windows.Forms.Button; $cl_buttonBrowseTarget.Text = "Browse..."; $cl_buttonBrowseTarget.Location = New-Object System.Drawing.Point(490, 108); $cl_buttonBrowseTarget.Size = New-Object System.Drawing.Size(85, 25); $cl_buttonBrowseTarget.Anchor = 'Top, Right'; $cl_group.Controls.Add($cl_buttonBrowseTarget)
$cl_radioSymLinkFile = New-Object System.Windows.Forms.RadioButton; $cl_radioSymLinkFile.Text = "Symbolic Link (File)"; $cl_radioSymLinkFile.Location = New-Object System.Drawing.Point(15, 150); $cl_radioSymLinkFile.AutoSize = $true; $cl_radioSymLinkFile.Checked = $true; $cl_group.Controls.Add($cl_radioSymLinkFile)
$cl_radioSymLinkDir = New-Object System.Windows.Forms.RadioButton; $cl_radioSymLinkDir.Text = "Symbolic Link (Directory)"; $cl_radioSymLinkDir.Location = New-Object System.Drawing.Point(180, 150); $cl_radioSymLinkDir.AutoSize = $true; $cl_group.Controls.Add($cl_radioSymLinkDir)
$cl_radioJunction = New-Object System.Windows.Forms.RadioButton; $cl_radioJunction.Text = "Junction (Directory)"; $cl_radioJunction.Location = New-Object System.Drawing.Point(370, 150); $cl_radioJunction.AutoSize = $true; $cl_group.Controls.Add($cl_radioJunction)
$cl_buttonCreate = New-Object System.Windows.Forms.Button; $cl_buttonCreate.Text = "Create Link"; $cl_buttonCreate.Location = New-Object System.Drawing.Point(235, 185); $cl_buttonCreate.Size = New-Object System.Drawing.Size(120, 30); $cl_buttonCreate.Anchor = 'Top'; $cl_group.Controls.Add($cl_buttonCreate)


# --- Controls for "Bulk Move and Link" Tab (Overhauled) ---
$ml_group = New-Object System.Windows.Forms.GroupBox; $ml_group.Text = "Move and Link Properties"; $ml_group.Location = New-Object System.Drawing.Point(10, 10); $ml_group.Size = New-Object System.Drawing.Size(590, 160); $ml_group.Anchor = 'Top, Left, Right'; $moveLinkTabPage.Controls.Add($ml_group)
$ml_labelSource = New-Object System.Windows.Forms.Label; $ml_labelSource.Text = "Original Directory to Move:"; $ml_labelSource.Location = New-Object System.Drawing.Point(10, 30); $ml_labelSource.AutoSize = $true; $ml_group.Controls.Add($ml_labelSource)
$ml_textSourcePath = New-Object System.Windows.Forms.TextBox; $ml_textSourcePath.Location = New-Object System.Drawing.Point(10, 50); $ml_textSourcePath.Size = New-Object System.Drawing.Size(470, 20); $ml_textSourcePath.Anchor = 'Top, Left, Right'; $ml_group.Controls.Add($ml_textSourcePath)
$ml_buttonBrowseSource = New-Object System.Windows.Forms.Button; $ml_buttonBrowseSource.Text = "Browse..."; $ml_buttonBrowseSource.Location = New-Object System.Drawing.Point(490, 48); $ml_buttonBrowseSource.Size = New-Object System.Drawing.Size(85, 25); $ml_buttonBrowseSource.Anchor = 'Top, Right'; $ml_group.Controls.Add($ml_buttonBrowseSource)
$ml_labelDest = New-Object System.Windows.Forms.Label; $ml_labelDest.Text = "New Parent Destination Folder:"; $ml_labelDest.Location = New-Object System.Drawing.Point(10, 85); $ml_labelDest.AutoSize = $true; $ml_group.Controls.Add($ml_labelDest)
$ml_textDestPath = New-Object System.Windows.Forms.TextBox; $ml_textDestPath.Location = New-Object System.Drawing.Point(10, 105); $ml_textDestPath.Size = New-Object System.Drawing.Size(470, 20); $ml_textDestPath.Anchor = 'Top, Left, Right'; $ml_group.Controls.Add($ml_textDestPath)
$ml_buttonBrowseDest = New-Object System.Windows.Forms.Button; $ml_buttonBrowseDest.Text = "Browse..."; $ml_buttonBrowseDest.Location = New-Object System.Drawing.Point(490, 103); $ml_buttonBrowseDest.Size = New-Object System.Drawing.Size(85, 25); $ml_buttonBrowseDest.Anchor = 'Top, Right'; $ml_group.Controls.Add($ml_buttonBrowseDest)

# --- NEW Preview Panel for Bulk Move ---
$ml_previewGroup = New-Object System.Windows.Forms.GroupBox; $ml_previewGroup.Text = "Source Preview"; $ml_previewGroup.Location = New-Object System.Drawing.Point(10, 175); $ml_previewGroup.Size = New-Object System.Drawing.Size(590, 100); $ml_previewGroup.Anchor = 'Top, Left, Right'; $moveLinkTabPage.Controls.Add($ml_previewGroup)
$ml_previewIcon = New-Object System.Windows.Forms.PictureBox; $ml_previewIcon.Location = New-Object System.Drawing.Point(15, 25); $ml_previewIcon.Size = New-Object System.Drawing.Size(64, 64); $ml_previewIcon.SizeMode = 'CenterImage'; $ml_previewGroup.Controls.Add($ml_previewIcon)
$ml_previewNameLabel = New-Object System.Windows.Forms.Label; $ml_previewNameLabel.Text = "Name: "; $ml_previewNameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold); $ml_previewNameLabel.Location = New-Object System.Drawing.Point(90, 30); $ml_previewNameLabel.AutoSize = $true; $ml_previewGroup.Controls.Add($ml_previewNameLabel)
$ml_previewSizeLabel = New-Object System.Windows.Forms.Label; $ml_previewSizeLabel.Text = "Size: "; $ml_previewSizeLabel.Location = New-Object System.Drawing.Point(90, 60); $ml_previewSizeLabel.AutoSize = $true; $ml_previewGroup.Controls.Add($ml_previewSizeLabel)

# --- Options and Action Button for Bulk Move ---
$ml_optionsGroup = New-Object System.Windows.Forms.GroupBox; $ml_optionsGroup.Text = "Options"; $ml_optionsGroup.Location = New-Object System.Drawing.Point(10, 280); $ml_optionsGroup.Size = New-Object System.Drawing.Size(590, 120); $ml_optionsGroup.Anchor = 'Top, Left, Right'; $moveLinkTabPage.Controls.Add($ml_optionsGroup)
$ml_radioSymLink = New-Object System.Windows.Forms.RadioButton; $ml_radioSymLink.Text = "Create Symbolic Link"; $ml_radioSymLink.Location = New-Object System.Drawing.Point(40, 30); $ml_radioSymLink.AutoSize = $true; $ml_radioSymLink.Checked = $true; $ml_optionsGroup.Controls.Add($ml_radioSymLink)
$ml_radioJunction = New-Object System.Windows.Forms.RadioButton; $ml_radioJunction.Text = "Create Junction"; $ml_radioJunction.Location = New-Object System.Drawing.Point(220, 30); $ml_radioJunction.AutoSize = $true; $ml_optionsGroup.Controls.Add($ml_radioJunction)
$ml_chkReturnLink = New-Object System.Windows.Forms.CheckBox; $ml_chkReturnLink.Text = "Create a return link shortcut at the new destination"; $ml_chkReturnLink.Location = New-Object System.Drawing.Point(40, 60); $ml_chkReturnLink.AutoSize = $true; $ml_chkReturnLink.Checked = $true; $ml_optionsGroup.Controls.Add($ml_chkReturnLink)
$ml_buttonMove = New-Object System.Windows.Forms.Button; $ml_buttonMove.Text = "Move and Link"; $ml_buttonMove.Location = New-Object System.Drawing.Point(225, 80); $ml_buttonMove.Size = New-Object System.Drawing.Size(140, 30); $ml_buttonMove.Anchor = 'Top'; $ml_optionsGroup.Controls.Add($ml_buttonMove)

# --- Controls for "Selective Move" Tab ---
# (Unchanged from v1.2, just layout adjustments)
$sm_group = New-Object System.Windows.Forms.GroupBox; $sm_group.Text = "Selection and Destination"; $sm_group.Dock = 'Fill'; $sm_group.Padding = New-Object System.Windows.Forms.Padding(10); $selectiveMoveTabPage.Controls.Add($sm_group)
# ... (rest of controls are the same, just using more compact notation here)
$sm_labelSource = New-Object System.Windows.Forms.Label; $sm_labelSource.Text = "Source Directory:"; $sm_labelSource.Location = New-Object System.Drawing.Point(10, 30); $sm_labelSource.AutoSize = $true; $sm_group.Controls.Add($sm_labelSource)
$sm_textSourcePath = New-Object System.Windows.Forms.TextBox; $sm_textSourcePath.Location = New-Object System.Drawing.Point(10, 50); $sm_textSourcePath.Size = New-Object System.Drawing.Size(380, 20); $sm_textSourcePath.Anchor = 'Top, Left, Right'; $sm_group.Controls.Add($sm_textSourcePath)
$sm_buttonBrowseSource = New-Object System.Windows.Forms.Button; $sm_buttonBrowseSource.Text = "Browse..."; $sm_buttonBrowseSource.Location = New-Object System.Drawing.Point(400, 48); $sm_buttonBrowseSource.Size = New-Object System.Drawing.Size(85, 25); $sm_buttonBrowseSource.Anchor = 'Top, Right'; $sm_group.Controls.Add($sm_buttonBrowseSource)
$sm_buttonLoad = New-Object System.Windows.Forms.Button; $sm_buttonLoad.Text = "Load"; $sm_buttonLoad.Location = New-Object System.Drawing.Point(495, 48); $sm_buttonLoad.Size = New-Object System.Drawing.Size(80, 25); $sm_buttonLoad.Anchor = 'Top, Right'; $sm_group.Controls.Add($sm_buttonLoad)
$sm_treeView = New-Object System.Windows.Forms.TreeView; $sm_treeView.Location = New-Object System.Drawing.Point(10, 80); $sm_treeView.Size = New-Object System.Drawing.Size(565, 190); $sm_treeView.Anchor = 'Top, Left, Right, Bottom'; $sm_treeView.CheckBoxes = $true; $sm_group.Controls.Add($sm_treeView)
$sm_labelDest = New-Object System.Windows.Forms.Label; $sm_labelDest.Text = "Destination Folder:"; $sm_labelDest.Location = New-Object System.Drawing.Point(10, 280); $sm_labelDest.Anchor = 'Bottom, Left'; $sm_labelDest.AutoSize = $true; $sm_group.Controls.Add($sm_labelDest)
$sm_textDestPath = New-Object System.Windows.Forms.TextBox; $sm_textDestPath.Location = New-Object System.Drawing.Point(10, 300); $sm_textDestPath.Size = New-Object System.Drawing.Size(475, 20); $sm_textDestPath.Anchor = 'Bottom, Left, Right'; $sm_group.Controls.Add($sm_textDestPath)
$sm_buttonBrowseDest = New-Object System.Windows.Forms.Button; $sm_buttonBrowseDest.Text = "Browse..."; $sm_buttonBrowseDest.Location = New-Object System.Drawing.Point(495, 298); $sm_buttonBrowseDest.Size = New-Object System.Drawing.Size(80, 25); $sm_buttonBrowseDest.Anchor = 'Bottom, Right'; $sm_group.Controls.Add($sm_buttonBrowseDest)
$sm_radioSymLink = New-Object System.Windows.Forms.RadioButton; $sm_radioSymLink.Text = "Create Symbolic Links"; $sm_radioSymLink.Location = New-Object System.Drawing.Point(100, 335); $sm_radioSymLink.Anchor = 'Bottom, Left'; $sm_radioSymLink.AutoSize = $true; $sm_radioSymLink.Checked = $true; $sm_group.Controls.Add($sm_radioSymLink)
$sm_radioJunction = New-Object System.Windows.Forms.RadioButton; $sm_radioJunction.Text = "Create Junctions (Dirs Only)"; $sm_radioJunction.Location = New-Object System.Drawing.Point(320, 335); $sm_radioJunction.Anchor = 'Bottom, Left'; $sm_radioJunction.AutoSize = $true; $sm_group.Controls.Add($sm_radioJunction)
$sm_buttonMove = New-Object System.Windows.Forms.Button; $sm_buttonMove.Text = "Perform Selective Move"; $sm_buttonMove.Location = New-Object System.Drawing.Point(205, 365); $sm_buttonMove.Size = New-Object System.Drawing.Size(180, 30); $sm_buttonMove.Anchor = 'Bottom'; $sm_group.Controls.Add($sm_buttonMove)

#endregion

#region --- Event Handlers ---
$clearLogButton.Add_Click({ $logTextBox.Clear() })
$cl_buttonBrowseLink.Add_Click({ $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog; if ($folderBrowser.ShowDialog() -eq "OK") { $cl_textLinkPath.Text = $folderBrowser.SelectedPath } })
$cl_buttonBrowseTarget.Add_Click({ $dialog = New-Object System.Windows.Forms.OpenFileDialog; $dialog.ValidateNames = $false; $dialog.CheckFileExists = $false; $dialog.CheckPathExists = $true; $dialog.FileName = "Select Folder."; if ($dialog.ShowDialog() -eq 'OK') { $cl_textTargetPath.Text = $dialog.FileName.Replace("Select Folder.", "") } })
$ml_buttonBrowseSource.Add_Click({ $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog; if ($folderBrowser.ShowDialog() -eq "OK") { $ml_textSourcePath.Text = $folderBrowser.SelectedPath } })
$ml_buttonBrowseDest.Add_Click({ $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog; if ($folderBrowser.ShowDialog() -eq "OK") { $ml_textDestPath.Text = $folderBrowser.SelectedPath } })
$sm_buttonBrowseSource.Add_Click({ $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog; if ($folderBrowser.ShowDialog() -eq "OK") { $sm_textSourcePath.Text = $folderBrowser.SelectedPath } })
$sm_buttonBrowseDest.Add_Click({ $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog; if ($folderBrowser.ShowDialog() -eq "OK") { $sm_textDestPath.Text = $folderBrowser.SelectedPath } })

# --- NEW Event Handler for Preview Panel ---
$ml_textSourcePath.Add_TextChanged({
    Update-PreviewPanel -path $_.Text -groupBox $ml_previewGroup -pictureBox $ml_previewIcon -labelName $ml_previewNameLabel -labelSize $ml_previewSizeLabel
})

$cl_buttonCreate.Add_Click({
    # Logic from v1.2, unchanged
    try {
        $linkPath = $cl_textLinkPath.Text.Trim(); $targetPath = $cl_textTargetPath.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($linkPath) -or [string]::IsNullOrWhiteSpace($targetPath)) { [System.Windows.Forms.MessageBox]::Show("Both Link Path and Target Path must be filled out.", "Error", "OK", "Error"); return }
        $cmdArgs = ""; if ($cl_radioSymLinkFile.Checked) { $cmdArgs = "/C mklink `"$linkPath`" `"$targetPath`""; Write-Log "Attempting to create a FILE symbolic link." } elseif ($cl_radioSymLinkDir.Checked) { $cmdArgs = "/C mklink /D `"$linkPath`" `"$targetPath`""; Write-Log "Attempting to create a DIRECTORY symbolic link." } elseif ($cl_radioJunction.Checked) { $cmdArgs = "/C mklink /J `"$linkPath`" `"$targetPath`""; Write-Log "Attempting to create a DIRECTORY junction." }
        Write-Log "Executing: cmd.exe $cmdArgs"; $process = Start-Process cmd.exe -ArgumentList $cmdArgs -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput ".\stdout.tmp" -RedirectStandardError ".\stderr.tmp"; $stdout = Get-Content ".\stdout.tmp" -EA SilentlyContinue; $stderr = Get-Content ".\stderr.tmp" -EA SilentlyContinue; Remove-Item ".\stdout.tmp", ".\stderr.tmp" -EA SilentlyContinue
        if ($process.ExitCode -eq 0) { Write-Log "SUCCESS: Link created. Output: $stdout"; [System.Windows.Forms.MessageBox]::Show("Link created successfully!", "Success", "OK", "Information") } else { Write-Log "ERROR: Failed to create link. Code: $($process.ExitCode). Details: $stderr"; [System.Windows.Forms.MessageBox]::Show("Failed to create link. Check log.", "Error", "OK", "Error") }
    } catch { Write-Log "FATAL ERROR: $_"; [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Fatal Error", "OK", "Stop") }
})

$ml_buttonMove.Add_Click({
    # UPDATED logic for v1.3
    try {
        $sourceDir = $ml_textSourcePath.Text.Trim(); $destParentDir = $ml_textDestPath.Text.Trim()
        if (-not (Test-Path $sourceDir -PathType Container)) { [System.Windows.Forms.MessageBox]::Show("Source must be a valid directory.", "Error", "OK", "Error"); return }
        if (-not (Test-Path $destParentDir -PathType Container)) { [System.Windows.Forms.MessageBox]::Show("Destination must be a valid directory.", "Error", "OK", "Error"); return }
        $sourceDirName = (Get-Item $sourceDir).Name; $finalDestPath = Join-Path -Path $destParentDir -ChildPath $sourceDirName
        if (Test-Path $finalDestPath) { [System.Windows.Forms.MessageBox]::Show("Destination '$finalDestPath' already exists.", "Error", "OK", "Error"); return }
        $confirmation = [System.Windows.Forms.MessageBox]::Show("This will move directory:`n$sourceDir`nTo:`n$finalDestPath`nand create a link. Proceed?", "Confirm Move", "YesNo", "Warning"); if ($confirmation -ne 'Yes') { Write-Log "User cancelled operation."; return }
        Write-Log "Starting bulk move: $sourceDir -> $finalDestPath"; $roboArgs = @("`"$sourceDir`"", "`"$finalDestPath`"", "/E", "/SL", "/MOVE", "/NJH", "/NJS", "/NP"); $process = Start-Process robocopy.exe -ArgumentList $roboArgs -Wait -PassThru -WindowStyle Hidden
        if ($process.ExitCode -lt 8) {
            Write-Log "SUCCESS: Robocopy move completed. Code: $($process.ExitCode)."; $linkPath = $sourceDir; $targetPath = $finalDestPath; $cmdArgs = ""; if ($ml_radioSymLink.Checked) { $cmdArgs = "/C mklink /D `"$linkPath`" `"$targetPath`"" } else { $cmdArgs = "/C mklink /J `"$linkPath`" `"$targetPath`"" }
            Write-Log "Executing: cmd.exe $cmdArgs"; $linkProcess = Start-Process cmd.exe -ArgumentList $cmdArgs -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput ".\stdout.tmp" -RedirectStandardError ".\stderr.tmp"; $stdout = Get-Content ".\stdout.tmp" -EA SilentlyContinue; $stderr = Get-Content ".\stderr.tmp" -EA SilentlyContinue; Remove-Item ".\stdout.tmp", ".\stderr.tmp" -EA SilentlyContinue
            if ($linkProcess.ExitCode -eq 0) {
                Write-Log "SUCCESS: Link created. Output: $stdout"
                # --- NEW Return Link Logic ---
                if ($ml_chkReturnLink.Checked) {
                    Write-Log "Creating return link shortcut..."
                    try {
                        $wshell = New-Object -ComObject WScript.Shell
                        $shortcutPath = Join-Path -Path $finalDestPath -ChildPath "_Return to original location.lnk"
                        $shortcut = $wshell.CreateShortcut($shortcutPath)
                        $shortcut.TargetPath = $linkPath
                        $shortcut.Description = "Return to the original linked location at $linkPath"
                        $shortcut.Save()
                        Write-Log "SUCCESS: Return link created at '$shortcutPath'."
                    } catch {
                        Write-Log "ERROR: Failed to create return link. Details: $_"
                    }
                }
                [System.Windows.Forms.MessageBox]::Show("Directory moved and link(s) created successfully!", "Complete", "OK", "Information")
            } else { Write-Log "ERROR: Move complete, but FAILED to create link back. Code: $($linkProcess.ExitCode). Details: $stderr"; [System.Windows.Forms.MessageBox]::Show("CRITICAL: Directory moved, but link creation failed. Please create link manually.", "Error", "OK", "Error") }
        } else { Write-Log "ERROR: Robocopy failed. Code: $($process.ExitCode). Operation aborted."; [System.Windows.Forms.MessageBox]::Show("Directory move failed. No changes made.", "Move Failed", "OK", "Error") }
    } catch { Write-Log "FATAL ERROR: $_"; [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Fatal Error", "OK", "Stop") }
})

$sm_buttonLoad.Add_Click({
    # Logic from v1.2, unchanged
    $sourcePath = $sm_textSourcePath.Text.Trim(); if (-not (Test-Path $sourcePath -PathType Container)) { [System.Windows.Forms.MessageBox]::Show("Please select a valid source directory to load.", "Error", "OK", "Error"); return }; Write-Log "Loading directory structure from '$sourcePath'..."; $sm_treeView.Nodes.Clear(); Populate-TreeView $sourcePath $null; Write-Log "Directory loaded. Please select items to move."
})

$sm_buttonMove.Add_Click({
    # Logic from v1.2, unchanged
    try {
        $baseSourcePath = $sm_textSourcePath.Text.Trim(); $baseDestPath = $sm_textDestPath.Text.Trim(); if (-not (Test-Path $baseSourcePath -PathType Container) -or -not (Test-Path $baseDestPath -PathType Container)) { [System.Windows.Forms.MessageBox]::Show("Both source and destination must be valid directories.", "Error", "OK", "Error"); return }; $checkedNodes = Get-CheckedNodes $sm_treeView.Nodes; if ($checkedNodes.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("No files or folders were selected to move.", "Information", "OK", "Information"); return }; $confirmation = [System.Windows.Forms.MessageBox]::Show("You have selected $($checkedNodes.Count) items to move and link. This action cannot be undone. Proceed?", "Confirm Selective Move", "YesNo", "Warning"); if ($confirmation -ne 'Yes') { Write-Log "User cancelled selective move."; return }
        Write-Log "Starting selective move of $($checkedNodes.Count) items..."; foreach ($node in $checkedNodes) { $sourceItemPath = $node.Tag; $relativeItemPath = $sourceItemPath.Substring($baseSourcePath.Length); $destItemPath = "$baseDestPath$relativeItemPath"; $destItemParentDir = Split-Path -Path $destItemPath -Parent; Write-Log "Processing: $sourceItemPath"; if (-not (Test-Path $destItemParentDir)) { Write-Log "Creating destination structure: $destItemParentDir"; New-Item -Path $destItemParentDir -ItemType Directory -Force | Out-Null }; Write-Log "Moving to: $destItemPath"; Move-Item -Path $sourceItemPath -Destination $destItemPath -Force
            if ($?) { Write-Log "Move successful. Creating link back..."; $isContainer = Test-Path $destItemPath -PathType Container; $cmdArgs = ""; if ($isContainer) { if ($sm_radioJunction.Checked) { $cmdArgs = "/C mklink /J `"$sourceItemPath`" `"$destItemPath`"" } else { $cmdArgs = "/C mklink /D `"$sourceItemPath`" `"$destItemPath`"" } } else { if ($sm_radioJunction.Checked) { Write-Log "SKIPPING file link: Junctions are for directories only."; continue }; $cmdArgs = "/C mklink `"$sourceItemPath`" `"$destItemPath`"" }; Write-Log "Executing: cmd.exe $cmdArgs"; $linkProcess = Start-Process cmd.exe -ArgumentList $cmdArgs -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput ".\stdout.tmp" -RedirectStandardError ".\stderr.tmp"; $stdout = Get-Content ".\stdout.tmp" -EA SilentlyContinue; $stderr = Get-Content ".\stderr.tmp" -EA SilentlyContinue; Remove-Item ".\stdout.tmp", ".\stderr.tmp" -EA SilentlyContinue; if ($linkProcess.ExitCode -eq 0) { Write-Log "SUCCESS: Link created for $($node.Text)." } else { Write-Log "ERROR: Moved $($node.Text) but FAILED to create link back. Details: $stderr" }
            } else { Write-Log "ERROR: Failed to move item: $sourceItemPath" }
        }; Write-Log "Selective move operation finished."; [System.Windows.Forms.MessageBox]::Show("Selective move and link operation complete. Please check the log for details.", "Complete", "OK", "Information")
    } catch { Write-Log "FATAL ERROR in selective move: $_"; [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Fatal Error", "OK", "Stop") }
})
#endregion

#region --- Show Form ---
Write-Log "Application started. Running with administrative privileges."
Write-Log "Ready for user input."
$mainForm.ShowDialog() | Out-Null
#endregion

Read-Host -Prompt "Press Enter to close the console window"
