<#
.SYNOPSIS
    A GUI-based utility to convert Microsoft Word documents (.doc, .docx) to plain text files (.txt).

.DESCRIPTION
    This PowerShell script presents a user-friendly interface for batch converting Word documents.
    The user can select a source folder and a destination folder. The script will recursively
    scan the source folder for any .doc or .docx files and convert each one into a .txt file
    in the chosen destination folder. Progress is displayed in a log window.

    NOTE: This script requires Microsoft Word to be installed on the system to function correctly,
    as it utilizes the Word COM object for conversion.

.PROJECT
    Word to TXT Converter v1.1 - Created by: Zachary Whiteman & Google Gemini Ai.
    Date: Thursday, July 17, 2025 - 12:15 PM
#>

# --- SCRIPT SETUP ---

# Minimize the console window on start
try {
    Add-Type -Name Window -Namespace Console -MemberDefinition '
    [System.Runtime.InteropServices.DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [System.Runtime.InteropServices.DllImport("User32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int cmdShow);
    '
    $consolePtr = [Console.Window]::GetConsoleWindow()
    if ($consolePtr -ne [IntPtr]::Zero) {
        # 6 = SW_MINIMIZE
        [Console.Window]::ShowWindow($consolePtr, 6)
    }
}
catch {
    Write-Warning "Could not minimize the console window. It might not be available in this host."
}


# Load required .NET assemblies for the GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Enable system visual styles for UI elements (for modern look & feel)
[System.Windows.Forms.Application]::EnableVisualStyles()

# --- GUI CREATION ---

# Main Form
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text = "Word to TXT Converter 1.1"
$main_form.Size = New-Object System.Drawing.Size(600, 480)
$main_form.StartPosition = 'CenterScreen'
$main_form.FormBorderStyle = 'FixedSingle'
$main_form.MaximizeBox = $false

# --- UI CONTROLS ---

# Source Folder Section
$source_group = New-Object System.Windows.Forms.GroupBox
$source_group.Text = "Source Folder"
$source_group.Location = New-Object System.Drawing.Point(10, 10)
$source_group.Size = New-Object System.Drawing.Size(565, 60)
$main_form.Controls.Add($source_group)

$source_path_textbox = New-Object System.Windows.Forms.TextBox
$source_path_textbox.Location = New-Object System.Drawing.Point(10, 20)
$source_path_textbox.Size = New-Object System.Drawing.Size(440, 20)
$source_path_textbox.ReadOnly = $true
$source_group.Controls.Add($source_path_textbox)

$source_browse_button = New-Object System.Windows.Forms.Button
$source_browse_button.Location = New-Object System.Drawing.Point(460, 19)
$source_browse_button.Size = New-Object System.Drawing.Size(95, 23)
$source_browse_button.Text = "Browse..."
$source_group.Controls.Add($source_browse_button)

# Destination Folder Section
$dest_group = New-Object System.Windows.Forms.GroupBox
$dest_group.Text = "Destination Folder"
$dest_group.Location = New-Object System.Drawing.Point(10, 80)
$dest_group.Size = New-Object System.Drawing.Size(565, 60)
$main_form.Controls.Add($dest_group)

$dest_path_textbox = New-Object System.Windows.Forms.TextBox
$dest_path_textbox.Location = New-Object System.Drawing.Point(10, 20)
$dest_path_textbox.Size = New-Object System.Drawing.Size(440, 20)
$dest_path_textbox.ReadOnly = $true
$dest_group.Controls.Add($dest_path_textbox)

$dest_browse_button = New-Object System.Windows.Forms.Button
$dest_browse_button.Location = New-Object System.Drawing.Point(460, 19)
$dest_browse_button.Size = New-Object System.Drawing.Size(95, 23)
$dest_browse_button.Text = "Browse..."
$dest_group.Controls.Add($dest_browse_button)

# Progress Log Section
$log_group = New-Object System.Windows.Forms.GroupBox
$log_group.Text = "Progress Log"
$log_group.Location = New-Object System.Drawing.Point(10, 150)
$log_group.Size = New-Object System.Drawing.Size(565, 220)
$main_form.Controls.Add($log_group)

$log_box = New-Object System.Windows.Forms.RichTextBox
$log_box.Location = New-Object System.Drawing.Point(10, 20)
$log_box.Size = New-Object System.Drawing.Size(545, 190)
$log_box.ReadOnly = $true
$log_box.Font = New-Object System.Drawing.Font("Consolas", 9)
$log_group.Controls.Add($log_box)

# Action Buttons
$start_button = New-Object System.Windows.Forms.Button
$start_button.Location = New-Object System.Drawing.Point(10, 385)
$start_button.Size = New-Object System.Drawing.Size(150, 30)
$start_button.Text = "Start Conversion"
$start_button.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$main_form.Controls.Add($start_button)

$exit_button = New-Object System.Windows.Forms.Button
$exit_button.Location = New-Object System.Drawing.Point(475, 385)
$exit_button.Size = New-Object System.Drawing.Size(100, 30)
$exit_button.Text = "Exit"
$main_form.Controls.Add($exit_button)


# --- EVENT HANDLERS ---

# Function to add messages to the log box
function Add-Log {
    param(
        [string]$Message,
        [System.Drawing.Color]$Color = 'Black'
    )
    $log_box.SelectionStart = $log_box.TextLength
    $log_box.SelectionLength = 0
    $log_box.SelectionColor = $Color
    $log_box.AppendText("$(Get-Date -Format 'HH:mm:ss') - $Message`n")
    $log_box.ScrollToCaret()
    $main_form.Update() # Force UI refresh
}

# Browse for Source Folder
$source_browse_button.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select the source folder containing Word documents"
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $source_path_textbox.Text = $folderBrowser.SelectedPath
        Add-Log "Source folder selected: $($folderBrowser.SelectedPath)"
    }
})

# Browse for Destination Folder
$dest_browse_button.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select the destination folder for the TXT files"
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $dest_path_textbox.Text = $folderBrowser.SelectedPath
        Add-Log "Destination folder selected: $($folderBrowser.SelectedPath)"
    }
})

# Start Conversion Process
$start_button.Add_Click({
    # --- Input Validation ---
    if ([string]::IsNullOrWhiteSpace($source_path_textbox.Text) -or -not (Test-Path $source_path_textbox.Text -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a valid source folder.", "Error", "OK", "Error")
        return
    }
    if ([string]::IsNullOrWhiteSpace($dest_path_textbox.Text) -or -not (Test-Path $dest_path_textbox.Text -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a valid destination folder.", "Error", "OK", "Error")
        return
    }

    $sourcePath = $source_path_textbox.Text
    $destPath = $dest_path_textbox.Text
    
    # Disable buttons during conversion
    $start_button.Enabled = $false
    $source_browse_button.Enabled = $false
    $dest_browse_button.Enabled = $false
    
    Add-Log "Starting conversion process..." -Color 'Blue'
    
    # --- Conversion Logic ---
    $wordApp = $null
    try {
        # Check if Word is installed by trying to create the COM object
        Add-Log "Checking for Microsoft Word..."
        $wordApp = New-Object -ComObject Word.Application
        $wordApp.Visible = $false
        Add-Log "Microsoft Word found. Starting scan." -Color 'Green'

        # Find all .doc and .docx files recursively
        $filesToConvert = Get-ChildItem -Path $sourcePath -Include "*.doc", "*.docx" -Recurse
        
        if ($filesToConvert.Count -eq 0) {
            Add-Log "No .doc or .docx files found in the source folder." -Color 'Orange'
            return
        }

        Add-Log "Found $($filesToConvert.Count) files to convert."

        # Define the format for plain text
        $wdFormatText = 2

        # Process each file
        foreach ($file in $filesToConvert) {
            Add-Log "Converting: $($file.Name)"
            $doc = $null
            try {
                $doc = $wordApp.Documents.Open($file.FullName)
                
                # Define the new file name and path
                $newFileName = [System.IO.Path]::ChangeExtension($file.Name, ".txt")
                $newFilePath = Join-Path -Path $destPath -ChildPath $newFileName
                
                # --- FIX IS HERE ---
                # Save the document as a text file.
                # The explicit [ref] cast is removed as it causes type conversion errors.
                # PowerShell handles the COM parameter marshalling automatically.
                $doc.SaveAs2($newFilePath, $wdFormatText)
                
                Add-Log "Successfully converted to: $newFileName" -Color 'Green'
            }
            catch {
                Add-Log "ERROR converting $($file.Name): $($_.Exception.Message)" -Color 'Red'
                Write-Error "Error converting $($file.FullName): $_"
            }
            finally {
                if ($doc -ne $null) {
                    $doc.Close([ref]$false) # Close without saving changes
                }
            }
        }
        Add-Log "Conversion process completed!" -Color 'Blue'
    }
    catch {
        # This catches major errors, like Word not being installed
        $errorMessage = $_.Exception.Message
        Add-Log "A critical error occurred: $errorMessage" -Color 'Red'
        Write-Error "A critical error occurred: $_"
        [System.Windows.Forms.MessageBox]::Show("A critical error occurred. It's possible Microsoft Word is not installed.`n`nError: $errorMessage", "Critical Error", "OK", "Error")
    }
    finally {
        # Clean up the Word COM object
        if ($wordApp -ne $null) {
            $wordApp.Quit()
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wordApp) | Out-Null
            Remove-Variable wordApp -ErrorAction SilentlyContinue
        }
        
        # Re-enable buttons
        $start_button.Enabled = $true
        $source_browse_button.Enabled = $true
        $dest_browse_button.Enabled = $true
    }
})


# Exit Button
$exit_button.Add_Click({
    $main_form.Close()
})

# --- SHOW GUI & CLEANUP ---

# Add a handler to clean up COM objects if the form is closed with the 'X' button
$main_form.Add_FormClosing({
    # The 'finally' block in the start button click should handle this if running,
    # but this is a good safeguard.
    if (Get-Variable -Name 'wordApp' -ErrorAction SilentlyContinue) {
        $wordApp.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wordApp) | Out-Null
    }
})

# Display the form
[void]$main_form.ShowDialog()

# Dispose of the form object after it's closed
$main_form.Dispose()

# Keep the console window open to display any final messages or errors
Write-Host "GUI closed. The script has finished."
Write-Host "Press Enter to close this console window..."
Read-Host