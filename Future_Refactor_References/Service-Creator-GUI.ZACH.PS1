# Service-Creator-GUI.ZACH - Advanced PowerShell Concepts - Scripting Project - v3.0.1.0

# ---------------------------------------------------------------------------------
# 1.) ADMINISTRATOR SELF-ELEVATION CHECK
# ---------------------------------------------------------------------------------
if (-not ([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell.exe -ArgumentList "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
    exit
}

# --- Unique identifier for services created by this script ---
$ScriptIdentifier = "This service was created and is managed by the Service-Creator-GUI.ZACH script."

# ---------------------------------------------------------------------------------
# 2.) DEPENDENCY CHECK AND INSTALLATION
# ---------------------------------------------------------------------------------
$NSSM_URL = "https://nssm.cc/release/nssm-2.24.zip"
$NSSM_DIR = "$env:APPDATA\EliteSoftwareCorp\ServiceCreator"
$NSSM_EXE = Join-Path -Path $NSSM_DIR -ChildPath "nssm-2.24\win64\nssm.exe"

Function Install-NSSM {
    Write-Host "NSSM not found. Downloading and installing..."
    if (-not (Test-Path $NSSM_DIR)) { New-Item -Path $NSSM_DIR -ItemType Directory -Force | Out-Null }
    $NSSM_ZIP_PATH = Join-Path -Path $NSSM_DIR -ChildPath "nssm.zip"
    try {
        Invoke-WebRequest -Uri $NSSM_URL -OutFile $NSSM_ZIP_PATH
        Expand-Archive -Path $NSSM_ZIP_PATH -DestinationPath $NSSM_DIR -Force
        Remove-Item -Path $NSSM_ZIP_PATH -Force
        Write-Host "NSSM has been installed successfully."
    } catch { Write-Error "Failed to download or install NSSM."; exit }
}

if (-not (Test-Path $NSSM_EXE)) {
    Write-Host "Checking for NSSM dependency..."
    Install-NSSM
}
if (-not (Test-Path $NSSM_EXE)) {
    [System.Windows.Forms.MessageBox]::Show("NSSM dependency could not be installed. The application will now close.", "Dependency Error", "OK", "Error")
    exit
}

# ---------------------------------------------------------------------------------
# 3.) GUI SETUP
# ---------------------------------------------------------------------------------
[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
[void][System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "Process to Service Creator (v3.0.1)"
$form.Size = New-Object System.Drawing.Size(600, 450)
$form.StartPosition = "CenterScreen"
$form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($NSSM_EXE)
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

# ---------------------------------------------------------------------------------
# 4.) UI ELEMENTS - CONTROLS
# ---------------------------------------------------------------------------------
# --- Main Tab Control ---
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Dock = [System.Windows.Forms.DockStyle]::Fill

$createServiceTab = New-Object System.Windows.Forms.TabPage
$createServiceTab.Text = "Create Service"

$manageServiceTab = New-Object System.Windows.Forms.TabPage
$manageServiceTab.Text = "Manage Services"

$aboutTab = New-Object System.Windows.Forms.TabPage
$aboutTab.Text = "About"

$tabControl.Controls.AddRange(@($createServiceTab, $manageServiceTab, $aboutTab))
$form.Controls.Add($tabControl)

# --- CREATE SERVICE TAB CONTROLS (RESTORED) ---
$createGroup = New-Object System.Windows.Forms.GroupBox
$createGroup.Text = "Service Configuration"
$createGroup.Dock = "Fill"
$createServiceTab.Controls.Add($createGroup)

$label1 = New-Object System.Windows.Forms.Label
$label1.Text = "Executable Path:"
$label1.Location = New-Object System.Drawing.Point(20, 30)
$label1.Size = New-Object System.Drawing.Size(120, 20)
$textBoxPath = New-Object System.Windows.Forms.TextBox
$textBoxPath.Location = New-Object System.Drawing.Point(140, 30)
$textBoxPath.Size = New-Object System.Drawing.Size(320, 20)
$buttonBrowse = New-Object System.Windows.Forms.Button
$buttonBrowse.Text = "Browse..."
$buttonBrowse.Location = New-Object System.Drawing.Point(470, 28)
$buttonBrowse.Size = New-Object System.Drawing.Size(80, 25)

$label2 = New-Object System.Windows.Forms.Label
$label2.Text = "Service Name:"
$label2.Location = New-Object System.Drawing.Point(20, 70)
$label2.Size = New-Object System.Drawing.Size(120, 20)
$textBoxName = New-Object System.Windows.Forms.TextBox
$textBoxName.Location = New-Object System.Drawing.Point(140, 70)
$textBoxName.Size = New-Object System.Drawing.Size(320, 20)

$label3 = New-Object System.Windows.Forms.Label
$label3.Text = "Display Name:"
$label3.Location = New-Object System.Drawing.Point(20, 110)
$label3.Size = New-Object System.Drawing.Size(120, 20)
$textBoxDisplay = New-Object System.Windows.Forms.TextBox
$textBoxDisplay.Location = New-Object System.Drawing.Point(140, 110)
$textBoxDisplay.Size = New-Object System.Drawing.Size(320, 20)

$buttonCreate = New-Object System.Windows.Forms.Button
$buttonCreate.Text = "Create Service"
$buttonCreate.Location = New-Object System.Drawing.Point(20, 150)
$buttonCreate.Size = New-Object System.Drawing.Size(530, 40)
$buttonCreate.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$createStatusLabel = New-Object System.Windows.Forms.Label
$createStatusLabel.Text = "Status: Awaiting input..."
$createStatusLabel.Location = New-Object System.Drawing.Point(20, 200)
$createStatusLabel.Size = New-Object System.Drawing.Size(530, 40)
$createStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$createGroup.Controls.AddRange(@($label1, $textBoxPath, $buttonBrowse, $label2, $textBoxName, $label3, $textBoxDisplay, $buttonCreate, $createStatusLabel))

# --- MANAGE SERVICES TAB CONTROLS ---
$manageGroup = New-Object System.Windows.Forms.GroupBox
$manageGroup.Text = "Detected Services (Created by this Script)"
$manageGroup.Dock = "Fill"
$manageServiceTab.Controls.Add($manageGroup)

$listViewServices = New-Object System.Windows.Forms.ListView
$listViewServices.Location = New-Object System.Drawing.Point(10, 20)
$listViewServices.Size = New-Object System.Drawing.Size(560, 280)
$listViewServices.View = "Details"
$listViewServices.FullRowSelect = $true
$listViewServices.GridLines = $true
$listViewServices.Columns.Add("Service Name", 150) | Out-Null
$listViewServices.Columns.Add("Display Name", 250) | Out-Null
$listViewServices.Columns.Add("Status", 100) | Out-Null

$buttonRefresh = New-Object System.Windows.Forms.Button
$buttonRefresh.Text = "Refresh"
$buttonRefresh.Location = New-Object System.Drawing.Point(10, 310)
$buttonRefresh.Size = New-Object System.Drawing.Size(100, 30)

$buttonDisable = New-Object System.Windows.Forms.Button
$buttonDisable.Text = "Stop & Disable"
$buttonDisable.Location = New-Object System.Drawing.Point(120, 310)
$buttonDisable.Size = New-Object System.Drawing.Size(100, 30)

$buttonOpenServices = New-Object System.Windows.Forms.Button
$buttonOpenServices.Text = "Open Services.msc"
$buttonOpenServices.Location = New-Object System.Drawing.Point(230, 310)
$buttonOpenServices.Size = New-Object System.Drawing.Size(130, 30)

$buttonDelete = New-Object System.Windows.Forms.Button
$buttonDelete.Text = "Delete Service"
$buttonDelete.Location = New-Object System.Drawing.Point(450, 310)
$buttonDelete.Size = New-Object System.Drawing.Size(120, 30)
$buttonDelete.BackColor = [System.Drawing.Color]::LightCoral

$manageStatusLabel = New-Object System.Windows.Forms.Label
$manageStatusLabel.Text = "Status: Ready"
$manageStatusLabel.Location = New-Object System.Drawing.Point(10, 350)
$manageStatusLabel.Size = New-Object System.Drawing.Size(560, 20)

$manageGroup.Controls.AddRange(@($listViewServices, $buttonRefresh, $buttonDisable, $buttonOpenServices, $buttonDelete, $manageStatusLabel))

# --- ABOUT TAB CONTROLS (RESTORED) ---
$aboutText = New-Object System.Windows.Forms.RichTextBox
$aboutText.ReadOnly = $true
$aboutText.Dock = "Fill"
$aboutText.BorderStyle = "None"
$aboutText.BackColor = $form.BackColor
$aboutText.Text = @"
Service Creator v3.0.1 - Created by: Zachary Whiteman & Google Gemini

This application allows you to create a Windows Service from any executable using the NSSM (Non-Sucking Service Manager) wrapper. This is an advanced operation intended for tech enthusiasts and system administrators.

**How to Use:**
1.  Enter the full path to the executable you want to run as a service.
2.  Provide a short, unique name for the service (no spaces).
3.  Provide a display name that will appear in the Services.msc console.
4.  Click "Create Service."
5.  Manage the service from the 'Manage Services' tab.

**Important:**
This application requires Administrator privileges to function correctly and will prompt for elevation on start.
"@
$aboutTab.Controls.Add($aboutText)


# ---------------------------------------------------------------------------------
# 5.) EVENT HANDLERS AND LOGIC
# ---------------------------------------------------------------------------------
Function Refresh-ServiceList { 
    $listViewServices.Items.Clear()
    $manageStatusLabel.Text = "Status: Searching for services..."
    $form.Refresh()
    try {
        $scriptServices = Get-CimInstance -ClassName Win32_Service | Where-Object { $_.Description -eq $ScriptIdentifier }
        foreach ($service in $scriptServices) {
            $item = New-Object System.Windows.Forms.ListViewItem($service.Name)
            $item.SubItems.Add($service.DisplayName) | Out-Null
            $item.SubItems.Add($service.State) | Out-Null
            $listViewServices.Items.Add($item) | Out-Null
        }
        $manageStatusLabel.Text = "Status: Service list updated."
    } catch {
        $manageStatusLabel.Text = "Error: Could not retrieve service list."
        $manageStatusLabel.ForeColor = "Red"
    }
}

$buttonBrowse.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Executable files (*.exe)|*.exe|All files (*.*)|*.*"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBoxPath.Text = $openFileDialog.FileName
    }
})

$buttonCreate.Add_Click({
    $executablePath = $textBoxPath.Text
    $serviceName = $textBoxName.Text
    $displayName = $textBoxDisplay.Text
    
    if (-not (Test-Path $executablePath)) { $createStatusLabel.Text = "Error: Executable path is invalid!"; $createStatusLabel.ForeColor = "Red"; return }
    if ([string]::IsNullOrWhiteSpace($serviceName)) { $createStatusLabel.Text = "Error: Service Name cannot be empty!"; $createStatusLabel.ForeColor = "Red"; return }
    
    $createStatusLabel.Text = "Creating service, please wait..."
    $createStatusLabel.ForeColor = "Black"
    $form.Refresh()

    try {
        Start-Process -FilePath $NSSM_EXE -ArgumentList "install", $serviceName, "`"$executablePath`"" -Wait -NoNewWindow -ErrorAction Stop
        if (-not [string]::IsNullOrWhiteSpace($displayName)) {
            Start-Process -FilePath $NSSM_EXE -ArgumentList "set", $serviceName, "DisplayName", "`"$displayName`"" -Wait -NoNewWindow -ErrorAction Stop
        }
        Start-Process -FilePath $NSSM_EXE -ArgumentList "set", $serviceName, "Description", "`"$ScriptIdentifier`"" -Wait -NoNewWindow -ErrorAction Stop
        
        $createStatusLabel.Text = "Service '$serviceName' created successfully!"
        $createStatusLabel.ForeColor = "Green"
        
        Refresh-ServiceList
        $tabControl.SelectedTab = $manageServiceTab

    } catch {
        $createStatusLabel.Text = "Error creating service: $($_.Exception.Message)"
        $createStatusLabel.ForeColor = "Red"
    }
})

$buttonRefresh.Add_Click({ Refresh-ServiceList })

$buttonDisable.Add_Click({
    if ($listViewServices.SelectedItems.Count -eq 0) { $manageStatusLabel.Text = "Status: Please select a service to disable."; return }
    $serviceName = $listViewServices.SelectedItems[0].Text
    try {
        $manageStatusLabel.Text = "Status: Stopping and disabling '$serviceName'..."
        Stop-Service -Name $serviceName -Force -ErrorAction Stop
        Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop
        $manageStatusLabel.Text = "Status: Service '$serviceName' has been disabled."
        Refresh-ServiceList
    } catch {
        $manageStatusLabel.Text = "Error disabling service: $($_.Exception.Message)"
        $manageStatusLabel.ForeColor = "Red"
    }
})

$buttonDelete.Add_Click({
    if ($listViewServices.SelectedItems.Count -eq 0) { $manageStatusLabel.Text = "Status: Please select a service to delete."; return }
    $serviceName = $listViewServices.SelectedItems[0].Text
    $confirmResult = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to permanently delete the service '$serviceName'?", "Confirm Deletion", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    
    if ($confirmResult -eq 'Yes') {
        try {
            $manageStatusLabel.Text = "Status: Deleting '$serviceName'..."
            Start-Process -FilePath $NSSM_EXE -ArgumentList "remove", "`"$serviceName`"", "confirm" -Wait -NoNewWindow -ErrorAction Stop
            $manageStatusLabel.Text = "Status: Service '$serviceName' was deleted successfully."
            Refresh-ServiceList
        } catch {
            $manageStatusLabel.Text = "Error deleting service: $($_.Exception.Message)"
            $manageStatusLabel.ForeColor = "Red"
        }
    }
})

$buttonOpenServices.Add_Click({
    try {
        Start-Process services.msc -ErrorAction Stop
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Could not open services.msc. Please check your system.", "Error", "OK", "Error")
    }
})

# ---------------------------------------------------------------------------------
# 6.) SHOW THE FORM AND INITIALIZE
# ---------------------------------------------------------------------------------
$form.Add_Shown({ Refresh-ServiceList })
$form.ShowDialog()
