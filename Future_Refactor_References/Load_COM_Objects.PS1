<#
.SYNOPSIS
    A PowerShell GUI tool to browse and launch COM objects.

.DESCRIPTION
    This script creates a Windows Forms application that enumerates registered
    COM objects on the system. It displays their ProgID (Programmatic ID) and
    CLSID (Class ID), and allows the user to filter/search through them.
    Selected COM objects can then be launched (instantiated).

    This version implements asynchronous loading of COM objects to prevent
    the GUI from freezing, providing progress updates to the user.
    It now specifically focuses on scanning for COM objects that can be executed
    as standalone applications (LocalServer32 type).

    This tool is intended for advanced users and for educational/tinkering purposes.
    Instantiating unknown COM objects can lead to unexpected behavior or system instability.

.NOTES
    Author: Gemini (Your helpful artificial intelligence assistant)
    Date: 2025-06-20
    Version: 1.8 - Filtered enumeration to only include LocalServer32 (executable) COM objects.

    IMPORTANT:
    1. PowerShell Execution Policy: You might need to adjust your PowerShell
       execution policy to run this script. Open PowerShell as administrator
       and run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
       (or Bypass if you're comfortable, but RemoteSigned is generally sufficient).
    2. COM Object Instantiation: Be cautious when launching COM objects. Some
       may have side effects, require specific parameters, or might not be
       designed for direct user interaction.
    3. Error Handling: The script includes basic error handling for COM object
       instantiation. More advanced error handling or specific parameter
       passing might be required for certain COM objects.

.EXAMPLE
    To run the script:
    1. Save the code below as a .ps1 file (e.g., ComObjectBrowser.ps1).
    2. Open PowerShell.
    3. Navigate to the directory where you saved the file.
    4. Run: .\ComObjectBrowser.ps1
#>

#region Load Assemblies
# Load necessary .NET assemblies for creating a Windows Forms GUI
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    # PresentationFramework is typically needed for WPF, but sometimes helps with general threading context.
    # We'll keep it here just in case it resolves obscure environment issues.
    Add-Type -AssemblyName PresentationFramework | Out-Null
    Write-Host "Successfully loaded System.Windows.Forms and System.Drawing assemblies." | Out-Null
}
catch {
    Write-Error "Failed to load required .NET assemblies. $($_.Exception.Message)"
    exit
}
#endregion

#region COM Object Definition Class
# Define a custom class to hold COM object properties for easier management
class ComObjectInfo {
    [string]$ProgID
    [string]$CLSID
    [string]$Description # This will be harder to find for all, so might be empty
    [string]$ServerType # InprocServer32 (DLL) or LocalServer32 (EXE)
    [string]$ServerPath # Path to the DLL/EXE
}
#endregion

#region Form Creation
# Create the main form for the GUI
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell COM Object Browser"
$form.Size = New-Object System.Drawing.Size(900, 700)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle" # Prevent resizing for simplicity
$form.MaximizeBox = $false # Disable maximize button

# Set form icon (optional, default icon will be used if not specified)
# $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:SystemRoot\system32\shell32.dll")
#endregion

#region Controls Creation

# Label for search input
$labelSearch = New-Object System.Windows.Forms.Label
$labelSearch.Text = "Search (ProgID/CLSID/Description):"
$labelSearch.Location = New-Object System.Drawing.Point(10, 10)
$labelSearch.AutoSize = $true
$form.Controls.Add($labelSearch)

# Textbox for search input
$textBoxSearch = New-Object System.Windows.Forms.TextBox
$textBoxSearch.Location = New-Object System.Drawing.Point(10, 30)
$textBoxSearch.Size = New-Object System.Drawing.Size(860, 20)
$form.Controls.Add($textBoxSearch)

# DataGridView to display COM objects
$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Location = New-Object System.Drawing.Point(10, 60)
$dataGridView.Size = New-Object System.Drawing.Size(860, 500)
$dataGridView.AutoSizeColumnsMode = "Fill"
$dataGridView.SelectionMode = "FullRowSelect"
$dataGridView.MultiSelect = $false
$dataGridView.AllowUserToAddRows = $false
$dataGridView.ReadOnly = $true

# Add columns to the DataGridView
$colProgID = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colProgID.Name = "ProgID"
$colProgID.HeaderText = "Programmatic ID"
$colProgID.Width = 250
$dataGridView.Columns.Add($colProgID)

$colCLSID = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colCLSID.Name = "CLSID"
$colCLSID.HeaderText = "Class ID (GUID)"
$colCLSID.Width = 280
$dataGridView.Columns.Add($colCLSID)

$colDescription = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colDescription.Name = "Description"
$colDescription.HeaderText = "Description"
$colDescription.Width = 230
$dataGridView.Columns.Add($colDescription)

$colServerType = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colServerType.Name = "ServerType"
$colServerType.HeaderText = "Server Type"
$colServerType.Width = 100
$dataGridView.Columns.Add($colServerType)

$colServerPath = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colServerPath.Name = "ServerPath"
$colServerPath.HeaderText = "Server Path"
$colServerPath.Visible = $false # Hidden by default, can be shown in details
$dataGridView.Columns.Add($colServerPath)

$form.Controls.Add($dataGridView)

# ProgressBar to show loading progress
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 560)
$progressBar.Size = New-Object System.Drawing.Size(860, 20)
$progressBar.Style = "Continuous" # Smooth progress bar
$progressBar.Visible = $false # Hidden initially
$form.Controls.Add($progressBar)

# Button to load COM objects
$buttonLoad = New-Object System.Windows.Forms.Button
$buttonLoad.Text = "Load COM Objects"
$buttonLoad.Location = New-Object System.Drawing.Point(10, 590) # Adjusted position
$buttonLoad.Size = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($buttonLoad)

# Button to launch selected COM object
$buttonLaunch = New-Object System.Windows.Forms.Button
$buttonLaunch.Text = "Launch Selected"
$buttonLaunch.Location = New-Object System.Drawing.Point(140, 590) # Adjusted position
$buttonLaunch.Size = New-Object System.Drawing.Size(120, 30)
$buttonLaunch.Enabled = $false # Disable until an item is selected
$form.Controls.Add($buttonLaunch)

# Button to view details of selected COM object
$buttonDetails = New-Object System.Windows.Forms.Button
$buttonDetails.Text = "View Details"
$buttonDetails.Location = New-Object System.Drawing.Point(270, 590) # Adjusted position
$buttonDetails.Size = New-Object System.Drawing.Size(120, 30)
$buttonDetails.Enabled = $false # Disable until an item is selected
$form.Controls.Add($buttonDetails)

# Label to display status messages
$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Text = "Ready."
$labelStatus.Location = New-Object System.Drawing.Point(10, 630) # Adjusted position
$labelStatus.AutoSize = $true
# Fix: Ensure $form.Width is treated as an integer for subtraction
$labelStatus.MaximumSize = New-Object System.Drawing.Size(([int]$form.Width - 20), 0) # Wrap text
$form.Controls.Add($labelStatus)

# List to hold all COM objects
# Changed to BindingList for automatic DataGridView updates from background thread
$allComObjects = New-Object 'System.ComponentModel.BindingList[ComObjectInfo]'
# Set the DataGridView's DataSource directly to the BindingList
$dataGridView.DataSource = $allComObjects

# Holds the complete, unfiltered list for re-filtering
$fullComObjectList = [System.Collections.Generic.List[ComObjectInfo]]::new()

#endregion

#region Functions

# Function to safely get a registry property
function Get-RegProperty {
    param (
        [string]$Path,
        [string]$Name
    )
    try {
        # Using Get-ItemProperty with -ErrorAction SilentlyContinue and then explicitly accessing the property
        (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue).$Name
    }
    catch {
        $null # Return null if not found or error
    }
}

# Function to enumerate and load COM objects (runs asynchronously)
function Load-ComObjects {
    # Disable buttons and show progress indicator
    $form.Invoke([action]{
        $buttonLoad.Enabled = $false
        $buttonLaunch.Enabled = false # Explicitly disable
        $buttonDetails.Enabled = false # Explicitly disable
        $labelStatus.Text = "Starting COM object enumeration..."
        $progressBar.Value = 0
        $progressBar.Visible = $true
        $allComObjects.Clear() # Clear previous data for BindingList
        $fullComObjectList.Clear() # Clear the full list too
    }) | Out-Null # Suppress output

    # Start the loading operation in a background task
    [System.Threading.Tasks.Task]::Run([Action]{
        Write-Host "Background task started for executable COM objects." | Out-Null # Debugging line
        try {
            $baseClsidPath = if (Test-Path 'HKCR:\') { 'HKCR:\CLSID' } else { 'Registry::HKEY_CLASSES_ROOT\CLSID' }
            Write-Host "Using base CLSID path: $baseClsidPath" | Out-Null # Debugging line

            $form.Invoke([action]{ $labelStatus.Text = "Collecting CLSID paths (executable only) for total count..." }) | Out-Null # Suppress output

            # Get all CLSID paths first to determine total count for progress bar
            # Using -ErrorAction SilentlyContinue to handle any access denied errors for specific paths
            # Using @() to ensure it's always an array, even if only one item is found or none.
            # We will filter for LocalServer32 within the loop, after reading the properties
            $allClsidPaths = @(Get-Item -Path "$baseClsidPath\*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PSPath)
            
            Write-Host "Found $($allClsidPaths.Count) potential CLSID paths." | Out-Null # Debugging line

            if (-not $allClsidPaths -or $allClsidPaths.Count -eq 0) {
                # Handle no CLSIDs found or access denied
                $form.Invoke([action]{
                    $labelStatus.Text = "No COM objects found in registry or insufficient permissions to read CLSIDs."
                    [System.Windows.Forms.MessageBox]::Show("No COM objects found in registry or insufficient permissions. Try running PowerShell as administrator.", "Loading Warning", "OK", "Warning") | Out-Null
                }) | Out-Null # Suppress output
                return
            }

            # Initialize total executable CLSIDs to 0, it will be updated as we find them
            $totalExecutableClsids = 0 
            $form.Invoke([action]{ $progressBar.Maximum = $allClsidPaths.Count }) | Out-Null # Set initial max for first pass progress

            $processedClsidsForProgress = 0
            foreach ($clsidPath in $allClsidPaths) {
                $processedClsidsForProgress++
                
                # Extract CLSID from path (e.g., from 'Microsoft.PowerShell.Core\Registry::HKEY_CLASSES_ROOT\CLSID\{GUID}')
                $clsid = ($clsidPath -split '\\')[-1]

                # Determine server type and path FIRST to filter for executable COM objects
                $serverType = $null
                $serverPath = $null

                $localServer32Path = Join-Path $clsidPath "LocalServer32"
                if (Test-Path $localServer32Path -ErrorAction SilentlyContinue) {
                    $serverType = "LocalServer32"
                    $serverPath = (Get-RegProperty -Path $localServer32Path -Name "")
                }
                
                # Only proceed if it's a LocalServer32 (executable) COM object
                if ($serverType -eq "LocalServer32") {
                    $totalExecutableClsids++ # Increment count of *actual* executable CLSIDs

                    # Get ProgID and ensure it's a string before calling .Replace()
                    $rawProgId = Get-RegProperty -Path $clsidPath -Name ""
                    $progId = if ($rawProgId -ne $null) { $rawProgId.ToString().Replace(" ", "") } else { "" }

                    # Get Description
                    $description = (Get-RegProperty -Path $clsidPath -Name "LocalizedString")
                    if (-not $description) {
                        $description = (Get-RegProperty -Path $clsidPath -Name "")
                        $progIdRegPath = if (Test-Path 'HKCR:\') { "HKCR:\$progId" } else { "Registry::HKEY_CLASSES_ROOT\$progId" }
                        if ($progId -and (Test-Path $progIdRegPath -ErrorAction SilentlyContinue)) {
                            $progIdDefault = (Get-RegProperty -Path $progIdRegPath -Name "")
                            if ($progIdDefault -and $progIdDefault -ne $progId) {
                                $description = $progIdDefault
                            }
                        }
                    }

                    $comObject = [ComObjectInfo]::new()
                    $comObject.ProgID = $progId
                    $comObject.CLSID = $clsid
                    $comObject.Description = $description
                    $comObject.ServerType = $serverType
                    $comObject.ServerPath = $serverPath

                    # Add the object to the BindingList and update progress on the UI thread
                    $form.Invoke([action]{
                        $allComObjects.Add($comObject)
                        $fullComObjectList.Add($comObject) # Also add to the full list for re-filtering
                        # Update status label less frequently for very large numbers of objects
                        $labelStatus.Text = "Found executable COM objects: $($allComObjects.Count) of (total scan: $($totalClsids))"
                    }) | Out-Null # Suppress output
                }
                
                # Update general scan progress bar
                $form.Invoke([action]{ $progressBar.Value = $processedClsidsForProgress }) | Out-Null # Suppress output
            }
            Write-Host "Background task completed. Total executable COM objects found: $totalExecutableClsids" | Out-Null # Debugging line
        }
        catch {
            # Catch any errors during the background enumeration
            $form.Invoke([action]{
                [System.Windows.Forms.MessageBox]::Show("An error occurred during COM object loading: $($_.Exception.Message)`n`nInner Exception: $($_.Exception.InnerException.Message)", "Loading Error", "OK", "Error") | Out-Null
                $labelStatus.Text = "Loading failed: $($_.Exception.Message)"
            }) | Out-Null # Suppress output
        }
    }).ContinueWith({
        # This block runs on completion (success or failure) of the background task
        $task = $_ # The completed task object
        $form.Invoke([action]{
            $progressBar.Visible = $false # Hide progress bar
            $buttonLoad.Enabled = $true # Re-enable load button
            $buttonLaunch.Enabled = ($allComObjects.Count -gt 0) # Enable launch if items loaded
            $buttonDetails.Enabled = ($allComObjects.Count -gt 0) # Enable details if items loaded

            if ($task.IsFaulted) {
                # If the task faulted, update status with error
                $labelStatus.Text = "Loading completed with errors: $($task.Exception.InnerException.Message)"
            }
            elseif ($allComObjects.Count -gt 0) {
                $labelStatus.Text = "Loaded $($allComObjects.Count) executable COM objects. Ready."
            }
            else {
                $labelStatus.Text = "No executable COM objects loaded."
            }

            # After loading, apply any existing filter if text is present
            if (-not [string]::IsNullOrEmpty($textBoxSearch.Text.Trim())) {
                Filter-ComObjects
            } else {
                # Ensure DataGridView displays the fully loaded list sorted
                $dataGridView.DataSource = $allComObjects | Sort-Object ProgID
            }
        }) | Out-Null # Suppress output
    }) | Out-Null # Prevent ContinueWith from holding the console if run directly
}

# Function to filter COM objects based on search input
function Filter-ComObjects {
    $searchText = $textBoxSearch.Text.ToLower().Trim()

    if ([string]::IsNullOrEmpty($searchText)) {
        # If search box is empty, show all objects from the full list
        $dataGridView.DataSource = $fullComObjectList | Sort-Object ProgID
        $labelStatus.Text = "Displaying all $($fullComObjectList.Count) executable COM objects."
    }
    else {
        # Filter objects based on ProgID, CLSID, or Description from the full list
        $filtered = $fullComObjectList | Where-Object {
            $_.ProgID.ToLower().Contains($searchText) -or
            $_.CLSID.ToLower().Contains($searchText) -or
            ($_.Description -ne $null -and $_.Description.ToLower().Contains($searchText))
        } | Sort-Object ProgID

        $dataGridView.DataSource = $filtered
        $labelStatus.Text = "Found $($filtered.Count) matching executable COM objects."
    }
    $buttonLaunch.Enabled = ($dataGridView.SelectedRows.Count -gt 0)
    $buttonDetails.Enabled = ($dataGridView.SelectedRows.Count -gt 0)
}

# Function to launch the selected COM object
function Launch-SelectedComObject {
    if ($dataGridView.SelectedRows.Count -gt 0) {
        $selectedRow = $dataGridView.SelectedRows[0]
        $progIdToLaunch = $selectedRow.Cells["ProgID"].Value

        if ([string]::IsNullOrEmpty($progIdToLaunch)) {
            [System.Windows.Forms.MessageBox]::Show("Selected item does not have a ProgID to launch.", "Error", "OK", "Error") | Out-Null
            $labelStatus.Text = "Error: No ProgID for selected item."
            return
        }

        try {
            $labelStatus.Text = "Attempting to launch '$progIdToLaunch'..."
            $form.Update() | Out-Null # Suppress output

            # Create an instance of the COM object
            $comObjectInstance = New-Object -ComObject $progIdToLaunch

            # Attempt to make it visible if it has a 'Visible' property (like IE, Word, Excel)
            # This is a common property for applications with a UI.
            if ($comObjectInstance -is [System.__ComObject] -and $comObjectInstance.PSMembers.MemberType -contains "Property") {
                $visibleProperty = $comObjectInstance.PSMembers | Where-Object {$_.Name -eq "Visible" -and $_.MemberType -eq "Property"} | Select-Object -First 1
                if ($visibleProperty -ne $null -and $visibleProperty.TypeNameOfValue -eq "System.Boolean") {
                    try {
                        $comObjectInstance.Visible = $true
                        $labelStatus.Text = "'$progIdToLaunch' launched and made visible."
                    }
                    catch {
                        $labelStatus.Text = "'$progIdToLaunch' launched, but failed to make visible (Error: $($_.Exception.Message))."
                    }
                }
                else {
                    $labelStatus.Text = "'$progIdToLaunch' launched (no 'Visible' property or not a boolean)."
                }
            }
            else {
                $labelStatus.Text = "'$progIdToLaunch' launched successfully, but no common 'Visible' property found."
            }

            # NOTE: For many COM objects, launching them just creates an in-memory instance
            # and doesn't necessarily open a GUI. You might need to interact with
            # $comObjectInstance further depending on its purpose.
            # E.g., for Word application: $comObjectInstance.Documents.Add()
            # For now, we'll just instantiate it.

        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to launch COM object '$progIdToLaunch'. Error: $($_.Exception.Message)", "Launch Error", "OK", "Error") | Out-Null
            $labelStatus.Text = "Launch failed: $($_.Exception.Message)"
        }
    }
}

# Function to show detailed information about the selected COM object
function Show-ComObjectDetails {
    if ($dataGridView.SelectedRows.Count -gt 0) {
        $selectedRow = $dataGridView.SelectedRows[0]
        $selectedProgID = $selectedRow.Cells["ProgID"].Value
        $selectedCLSID = $selectedRow.Cells["CLSID"].Value
        $selectedDescription = $selectedRow.Cells["Description"].Value
        $selectedServerType = $selectedRow.Cells["ServerType"].Value
        $selectedServerPath = $selectedServerPath # This variable is already defined and accurate

        $details = @"
        ProgID: $selectedProgID
        CLSID: {$selectedCLSID}
        Description: $selectedDescription
        Server Type: $selectedServerType
        Server Path: $selectedServerPath

        Registry Path: HKCR:\CLSID\$selectedCLSID
"@

        # Optionally, add more registry details
        try {
            # Adjust the Test-Path for CLSID as well
            $clsidDetailsRegPath = if (Test-Path 'HKCR:\') { "HKCR:\CLSID\$selectedCLSID" } else { "Registry::HKEY_CLASSES_ROOT\CLSID\$selectedCLSID" }
            $registryDetails = Get-Item -Path $clsidDetailsRegPath -Recurse -ErrorAction SilentlyContinue | Out-String
            if (-not [string]::IsNullOrEmpty($registryDetails.Trim())) {
                $details += "`n`nRegistry Details:`n" + $registryDetails
            } else {
                $details += "`n`nNo detailed registry properties found."
            }
        }
        catch {
            $details += "`n`nCould not retrieve full registry details for this CLSID: $($_.Exception.Message)"
        }

        [System.Windows.Forms.MessageBox]::Show($details, "COM Object Details", "OK", "Information") | Out-Null
    }
}

#endregion

#region Event Handlers

# Event handler for the search textbox (live filtering)
$textBoxSearch.Add_TextChanged({
    # Only filter if loading is not in progress
    if ($buttonLoad.Enabled) { # Check if the load button is enabled (meaning not loading)
        Filter-ComObjects
    }
})

# Event handler for Load button click
$buttonLoad.Add_Click({
    Load-ComObjects
})

# Event handler for Launch button click
$buttonLaunch.Add_Click({
    Launch-SelectedComObject
})

# Event handler for Details button click
$buttonDetails.Add_Click({
    Show-ComObjectDetails
})

# Event handler for DataGridView selection change
$dataGridView.Add_SelectionChanged({
    # Enable launch/details buttons if a row is selected AND not currently loading
    $buttonLaunch.Enabled = ($dataGridView.SelectedRows.Count -gt 0 -and $buttonLoad.Enabled)
    $buttonDetails.Enabled = ($dataGridView.SelectedRows.Count -gt 0 -and $buttonLoad.Enabled)
})

#endregion

#region Show Form
# Initial load of COM objects when the form is shown
$form.Add_Shown({
    Load-ComObjects
})

# Show the form
$form.ShowDialog() | Out-Null

# Clean up any created COM objects if necessary (important for some applications)
# For this script, we're not maintaining references to launched objects beyond the function call,
# so explicit cleanup here isn't strictly necessary unless we added a 'Close' or 'Quit' button for them.
# Example: if ($comObjectInstance -ne $null) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($comObjectInstance) | Out-Null }
# For now, processes will run independently.
#endregion
