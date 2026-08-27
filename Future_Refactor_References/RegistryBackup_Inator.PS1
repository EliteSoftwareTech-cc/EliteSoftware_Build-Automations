# Define the PowerShell script with a GUI for Windows Registry management.
# This script allows for backing up specific registry hives (HKEY_CURRENT_USER, HKEY_LOCAL_MACHINE)
# and restoring them from previously created .reg files.
# It also provides an option to launch the Registry Editor.

#region GUI Setup
# Load necessary .NET assemblies for creating the GUI.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form (window) for the application.
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Windows Registry Manager" # Title of the window
$mainForm.Size = New-Object System.Drawing.Size(550, 480) # Set the initial size (width, height), adjusted for more controls
$mainForm.StartPosition = "CenterScreen" # Center the window on the screen
$mainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle # Prevent resizing
$mainForm.MaximizeBox = $false # Disable maximize button
$mainForm.MinimizeBox = $false # Disable minimize button
$mainForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#F0F0F0") # Set a light gray background color

# Create a status bar at the bottom of the form to display messages.
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready" # Initial status message
$statusBar.Items.Add($statusLabel) # Add the label to the status bar
$mainForm.Controls.Add($statusBar) # Add the status bar to the form controls

# Define a function to easily update the status message in the GUI.
# It allows setting the message text and its color.
function Update-Status ($message, $color = "Black") {
    $statusLabel.Text = $message
    $statusLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($color)
}

# Create a GroupBox for path selection (where backups will be stored/restored from).
$pathGroupBox = New-Object System.Windows.Forms.GroupBox
$pathGroupBox.Text = "Backup/Restore Path" # Text displayed on the group box
$pathGroupBox.Location = New-Object System.Drawing.Point(20, 20) # Position (x, y)
$pathGroupBox.Size = New-Object System.Drawing.Size(490, 80) # Size (width, height)
$pathGroupBox.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) # Set font
$mainForm.Controls.Add($pathGroupBox) # Add to the main form

# Create a TextBox to display and edit the backup/restore path.
$pathTextBox = New-Object System.Windows.Forms.TextBox
$pathTextBox.Location = New-Object System.Drawing.Point(10, 30) # Position within the group box
$pathTextBox.Size = New-Object System.Drawing.Size(380, 25) # Size
$pathTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bOr [System.Windows.Forms.AnchorStyles]::Right
$pathTextBox.Text = "$env:USERPROFILE\Documents\Registry_Backups" # Set a default path for registry backups
$pathGroupBox.Controls.Add($pathTextBox) # Add to the path group box

# Create a Browse Button to open a folder selection dialog.
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse" # Button text
$browseButton.Location = New-Object System.Drawing.Point(400, 28) # Position
$browseButton.Size = New-Object System.Drawing.Size(75, 28) # Size
# Add an event handler for when the button is clicked.
$browseButton.Add_Click({
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog # Create a new folder browser dialog
    $folderBrowserDialog.SelectedPath = $pathTextBox.Text # Set the initial path in the dialog
    # If the user selects a folder and clicks OK, update the text box.
    if ($folderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $pathTextBox.Text = $folderBrowserDialog.SelectedPath
    }
})
$pathGroupBox.Controls.Add($browseButton) # Add to the path group box

# Create a GroupBox for selecting registry hives to backup.
$backupOptionsGroupBox = New-Object System.Windows.Forms.GroupBox
$backupOptionsGroupBox.Text = "Backup Options (Select Hives)"
$backupOptionsGroupBox.Location = New-Object System.Drawing.Point(20, 110)
$backupOptionsGroupBox.Size = New-Object System.Drawing.Size(490, 60)
$backupOptionsGroupBox.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$mainForm.Controls.Add($backupOptionsGroupBox)

# CheckBox for HKEY_CURRENT_USER (HKCU) hive.
$hkcuCheckBox = New-Object System.Windows.Forms.CheckBox
$hkcuCheckBox.Text = "HKEY_CURRENT_USER"
$hkcuCheckBox.Location = New-Object System.Drawing.Point(10, 25)
$hkcuCheckBox.AutoSize = $true # Adjust size to fit text
$hkcuCheckBox.Checked = $true # Default to checked
$backupOptionsGroupBox.Controls.Add($hkcuCheckBox)

# CheckBox for HKEY_LOCAL_MACHINE (HKLM) hive.
$hklmCheckBox = New-Object System.Windows.Forms.CheckBox
$hklmCheckBox.Text = "HKEY_LOCAL_MACHINE"
$hklmCheckBox.Location = New-Object System.Drawing.Point(170, 25)
$hklmCheckBox.AutoSize = $true
$hklmCheckBox.Checked = $true # Default to checked
$backupOptionsGroupBox.Controls.Add($hklmCheckBox)

# Create a GroupBox for action buttons (Backup, Restore, Defaults, Open Editor).
$actionGroupBox = New-Object System.Windows.Forms.GroupBox
$actionGroupBox.Text = "Actions" # Text for the group box
$actionGroupBox.Location = New-Object System.Drawing.Point(20, 180) # Adjusted position
$actionGroupBox.Size = New-Object System.Drawing.Size(490, 200) # Size (adjusted height)
$actionGroupBox.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) # Set font
$mainForm.Controls.Add($actionGroupBox) # Add to the main form

# Create the Backup Registry Button.
$backupRegistryButton = New-Object System.Windows.Forms.Button
$backupRegistryButton.Text = "Backup Registry Hives" # Button text
$backupRegistryButton.Location = New-Object System.Drawing.Point(20, 30) # Position
$backupRegistryButton.Size = New-Object System.Drawing.Size(220, 40) # Size
$backupRegistryButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) # Font
$backupRegistryButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4CAF50") # Green background
$backupRegistryButton.ForeColor = [System.Drawing.Color]::White # White text color
$backupRegistryButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Flat style
$backupRegistryButton.FlatAppearance.BorderSize = 0 # No border
$actionGroupBox.Controls.Add($backupRegistryButton) # Add to action group box

# Create the Restore Registry Button.
$restoreRegistryButton = New-Object System.Windows.Forms.Button
$restoreRegistryButton.Text = "Restore Registry (.reg)" # Button text
$restoreRegistryButton.Location = New-Object System.Drawing.Point(250, 30) # Position
$restoreRegistryButton.Size = New-Object System.Drawing.Size(220, 40) # Size
$restoreRegistryButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) # Font
$restoreRegistryButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2196F3") # Blue background
$restoreRegistryButton.ForeColor = [System.Drawing.Color]::White # White text
$restoreRegistryButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Flat style
$restoreRegistryButton.FlatAppearance.BorderSize = 0 # No border
$actionGroupBox.Controls.Add($restoreRegistryButton) # Add to action group box

# Create the Restore Defaults Button (with advisory).
$restoreDefaultsButton = New-Object System.Windows.Forms.Button
$restoreDefaultsButton.Text = "Restore System Defaults (Advisory)" # Button text
$restoreDefaultsButton.Location = New-Object System.Drawing.Point(20, 80) # Position
$restoreDefaultsButton.Size = New-Object System.Drawing.Size(220, 40) # Size
$restoreDefaultsButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) # Font
$restoreDefaultsButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#FFC107") # Amber background
$restoreDefaultsButton.ForeColor = [System.Drawing.Color]::Black # Black text
$restoreDefaultsButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Flat style
$restoreDefaultsButton.FlatAppearance.BorderSize = 0 # No border
$actionGroupBox.Controls.Add($restoreDefaultsButton) # Add to action group box

# Create the Open Registry Editor Button.
$openRegEditorButton = New-Object System.Windows.Forms.Button
$openRegEditorButton.Text = "Open Registry Editor (regedit.exe)" # Button text
$openRegEditorButton.Location = New-Object System.Drawing.Point(250, 80) # Position
$openRegEditorButton.Size = New-Object System.Drawing.Size(220, 40) # Size
$openRegEditorButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold) # Font
$openRegEditorButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#9E9E9E") # Gray background
$openRegEditorButton.ForeColor = [System.Drawing.Color]::White # White text
$openRegEditorButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Flat style
$openRegEditorButton.FlatAppearance.BorderSize = 0 # No border
$actionGroupBox.Controls.Add($openRegEditorButton) # Add to action group box

# Information Label to remind the user about Administrator privileges.
$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.Text = "Note: Registry operations require Administrator privileges!"
$infoLabel.Location = New-Object System.Drawing.Point(20, 390) # Position (adjusted)
$infoLabel.Size = New-Object System.Drawing.Size(490, 30) # Size
$infoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic) # Italic font
$infoLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter # Center text alignment
$infoLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#D32F2F") # Dark Red text color
$mainForm.Controls.Add($infoLabel) # Add to the main form

#endregion GUI Setup

#region Registry Functions

# Function to check if the script is running with Administrator privileges.
function Test-IsAdministrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Event handler for the Backup Registry Button.
$backupRegistryButton.Add_Click({
    # Check for Administrator privileges.
    if (-not (Test-IsAdministrator)) {
        Update-Status "Error: Please run this script as Administrator to backup the registry." "Red"
        return # Exit the function if not admin
    }

    $backupPath = $pathTextBox.Text # Get the desired backup destination path from the text box.
    # Create the backup directory if it doesn't exist.
    if (-not (Test-Path $backupPath)) {
        try {
            New-Item -ItemType Directory -Path $backupPath | Out-Null
            Update-Status "Created backup directory: $backupPath" "Blue"
        } catch {
            Update-Status "Error creating backup directory: $($_.Exception.Message)" "Red"
            return # Exit on error
        }
    }

    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $backupFileNamePrefix = "Registry_Backup_$timestamp"
    $backupSucceeded = $false

    # Backup HKEY_CURRENT_USER if selected.
    if ($hkcuCheckBox.Checked) {
        $hkcuFilePath = Join-Path $backupPath "$backupFileNamePrefix-HKCU.reg"
        Update-Status "Exporting HKEY_CURRENT_USER to '$hkcuFilePath'..." "Black"
        try {
            # Use reg.exe export to export the hive to a .reg file.
            $process = Start-Process -FilePath "reg.exe" -ArgumentList "export HKCU `"$hkcuFilePath`" /y" -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -eq 0) {
                Update-Status "HKEY_CURRENT_USER exported successfully." "Green"
                $backupSucceeded = $true
            } else {
                Update-Status "Error exporting HKEY_CURRENT_USER. Exit code: $($process.ExitCode)" "Red"
            }
        } catch {
            Update-Status "Failed to export HKEY_CURRENT_USER: $($_.Exception.Message)" "Red"
        }
    }

    # Backup HKEY_LOCAL_MACHINE if selected.
    if ($hklmCheckBox.Checked) {
        $hklmFilePath = Join-Path $backupPath "$backupFileNamePrefix-HKLM.reg"
        Update-Status "Exporting HKEY_LOCAL_MACHINE to '$hklmFilePath'..." "Black"
        try {
            # Use reg.exe export to export the hive to a .reg file.
            $process = Start-Process -FilePath "reg.exe" -ArgumentList "export HKLM `"$hklmFilePath`" /y" -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -eq 0) {
                Update-Status "HKEY_LOCAL_MACHINE exported successfully." "Green"
                $backupSucceeded = $true
            } else {
                Update-Status "Error exporting HKEY_LOCAL_MACHINE. Exit code: $($process.ExitCode)" "Red"
            }
        } catch {
            Update-Status "Failed to export HKEY_LOCAL_MACHINE: $($_.Exception.Message)" "Red"
        }
    }

    if ($backupSucceeded) {
        Update-Status "Registry backup operation completed." "Green"
    } else {
        Update-Status "Registry backup operation completed with some failures or no hives selected." "Orange"
    }
})

# Event handler for the Restore Registry Button.
$restoreRegistryButton.Add_Click({
    # Check for Administrator privileges.
    if (-not (Test-IsAdministrator)) {
        Update-Status "Error: Please run this script as Administrator to restore the registry." "Red"
        return # Exit if not admin
    }

    # Open a File Dialog to allow the user to select a .reg file for restoration.
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.InitialDirectory = $pathTextBox.Text # Start in the default backup path
    $openFileDialog.Filter = "Registry Files (*.reg)|*.reg|All Files (*.*)|*.*" # Filter for .reg files
    $openFileDialog.Title = "Select a .reg file to restore"

    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedRegFile = $openFileDialog.FileName # Get the selected file path.

        # Show a confirmation message box before proceeding with importing the registry file.
        $dialogResult = [System.Windows.Forms.MessageBox]::Show(
            "WARNING: Importing a .reg file can significantly alter your system and may cause instability if the file is corrupt or incompatible. Are you absolutely sure you want to proceed?",
            "Confirm Registry Restore", # Dialog title
            [System.Windows.Forms.MessageBoxButtons]::YesNo, # Buttons available
            [System.Windows.Forms.MessageBoxIcon]::Exclamation # Icon displayed
        )

        if ($dialogResult -eq [System.Windows.Forms.DialogResult]::Yes) {
            Update-Status "Importing registry file '$selectedRegFile'..." "Black"
            try {
                # Use reg.exe import to import the selected .reg file.
                $process = Start-Process -FilePath "reg.exe" -ArgumentList "import `"$selectedRegFile`"" -Wait -PassThru -NoNewWindow
                if ($process.ExitCode -eq 0) {
                    Update-Status "Registry file imported successfully." "Green"
                } else {
                    Update-Status "Error importing registry file. Exit code: $($process.ExitCode). Please check the file for errors." "Red"
                }
            } catch {
                Update-Status "Failed to import registry file: $($_.Exception.Message)" "Red"
            }
        } else {
            Update-Status "Registry restoration cancelled by user." "Gray"
        }
    } else {
        Update-Status "No registry file selected for restoration." "Gray"
    }
})

# Event handler for the Restore Defaults Button.
$restoreDefaultsButton.Add_Click({
    # For general registry "defaults", the best approach is typically a System Restore point.
    # Resetting the entire registry to a pristine "default" state is not a standard, simple operation.
    Update-Status "Information: A full registry 'default' restore is not directly possible via a simple command." "Black"
    [System.Windows.Forms.MessageBox]::Show(
        "To revert your system's registry to a previous state, it is strongly recommended to use Windows System Restore. " +
        "This tool creates restore points that can roll back system files and registry settings to an earlier time.",
        "Registry Defaults Advisory",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    Update-Status "Advised user to use Windows System Restore." "Blue"
})

# Event handler for the Open Registry Editor Button.
$openRegEditorButton.Add_Click({
    Update-Status "Opening Registry Editor (regedit.exe)..." "Black"
    try {
        # Start the regedit.exe process.
        Start-Process -FilePath "regedit.exe" -ErrorAction Stop
        Update-Status "Registry Editor opened." "Green"
    } catch {
        # Catch errors if regedit.exe cannot be opened for some reason.
        Update-Status "Failed to open regedit.exe. Error: $($_.Exception.Message)" "Red"
    }
})

#endregion Registry Functions

# Display the main form to the user. This line is blocking until the form is closed.
$mainForm.ShowDialog() | Out-Null

# Clean up variables after the form is closed.
Remove-Variable -Name mainForm, pathGroupBox, pathTextBox, browseButton, backupOptionsGroupBox, hkcuCheckBox, hklmCheckBox, actionGroupBox, backupRegistryButton, restoreRegistryButton, restoreDefaultsButton, openRegEditorButton, infoLabel, statusBar, statusLabel -ErrorAction SilentlyContinue
