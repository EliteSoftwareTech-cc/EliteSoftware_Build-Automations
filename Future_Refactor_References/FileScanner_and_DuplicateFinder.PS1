<#
.SYNOPSIS
    A graphical tool to scan folders, find duplicate files, and generate reports.
.DESCRIPTION
    This PowerShell script creates a feature-rich Windows Forms GUI with two main tabs:
    1. Folder Scanner: Scans a folder recursively and exports the structure. Includes advanced options
       for filtering, hashing, and choosing a custom save location. Now outputs to TXT, CSV, or an
       interactive HTML report.
    2. Duplicate Finder: Finds duplicate files within a folder by hashing or by analyzing a previously
       generated CSV/TXT report file.

    This version is personalized with default paths for the primary user.
    The script supports setting a custom application icon, which is saved for future sessions.
    The PowerShell console is hidden on launch for a native app feel.
.AUTHOR
    Gemini
.VERSION
    1.6
#>

#region Hide Console Window
# This C# code gets the handle to the console window and hides it.
try {
    $kernel32 = Add-Type -MemberDefinition '
    [DllImport("Kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("User32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmdShow);
    ' -Name 'Kernel32' -Namespace 'Win32' -PassThru -ErrorAction Stop
    $consolePtr = $kernel32::GetConsoleWindow()
    if ($consolePtr -ne [System.IntPtr]::Zero) { $kernel32::ShowWindow($consolePtr, 0) }
}
catch { Write-Warning "Could not hide the console window: $($_.Exception.Message)" }
#endregion

#region Assembly Loading and Initial Setup
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
#endregion

#region Configuration Management (Icon Saving)
# Define the path for the configuration file in the user's AppData directory.
$configDir = Join-Path $env:APPDATA "GeminiFolderScanner"
if (-not (Test-Path $configDir)) { New-Item -Path $configDir -ItemType Directory | Out-Null }
$configPath = Join-Path $configDir "settings.json"

# Function to load settings from the config file.
function Load-Settings {
    if (Test-Path $configPath) {
        try {
            return Get-Content $configPath | ConvertFrom-Json
        }
        catch {
            Write-Warning "Could not read settings file. Using defaults."
            return $null
        }
    }
    return $null
}

# Function to save settings to the config file.
function Save-Settings($settings) {
    try {
        $settings | ConvertTo-Json | Out-File -FilePath $configPath -Encoding UTF8
    }
    catch {
        Write-Warning "Could not save settings: $($_.Exception.Message)"
    }
}
#endregion

#region GUI Element Creation

# --- Main Form ---
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Folder & Duplicate Scanner"
$mainForm.Size = New-Object System.Drawing.Size(650, 720) # Increased width
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = "FixedSingle"
$mainForm.MaximizeBox = $false

# --- Apply Saved Icon ---
$savedSettings = Load-Settings
if ($savedSettings.CustomIconPath -and (Test-Path $savedSettings.CustomIconPath)) {
    try {
        $mainForm.Icon = New-Object System.Drawing.Icon($savedSettings.CustomIconPath)
    } catch {
        Write-Warning "Failed to load custom icon from path: $($savedSettings.CustomIconPath)"
    }
}

# --- Logo Bitmap for Tabs ---
# Use the main form's icon if available, otherwise use a default system icon (e.g., question mark)
$tabLogoBitmap = if ($mainForm.Icon) { $mainForm.Icon.ToBitmap() } else { [System.Drawing.SystemIcons]::Question.ToBitmap() }

# --- Menu Strip ---
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$fileMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&File")
$setIconMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Set Custom Icon...")
$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("E&xit")
$fileMenuItem.DropDownItems.AddRange(@($setIconMenuItem, $exitMenuItem))
$menuStrip.Items.Add($fileMenuItem)
$mainForm.Controls.Add($menuStrip)

# --- Tab Control ---
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(10, 30)
$tabControl.Size = New-Object System.Drawing.Size(620, 570) # Increased width
$mainForm.Controls.Add($tabControl)

# --- TAB 1: Folder Scanner ---
$scannerTab = New-Object System.Windows.Forms.TabPage
$scannerTab.Text = "Folder Scanner"
$tabControl.Controls.Add($scannerTab)

$scannerPanel = New-Object System.Windows.Forms.Panel
$scannerPanel.Dock = "Fill"
$scannerTab.Controls.Add($scannerPanel)

# Logo for Scanner Tab - positioned next to the title label
$scannerLogoPictureBox = New-Object System.Windows.Forms.PictureBox
$scannerLogoPictureBox.Location = New-Object System.Drawing.Point(20, 20)
$scannerLogoPictureBox.Size = New-Object System.Drawing.Size(32, 32) # Standard icon size
$scannerLogoPictureBox.SizeMode = "StretchImage" # Ensure it scales to fit
$scannerLogoPictureBox.Image = $tabLogoBitmap
$scannerPanel.Controls.Add($scannerLogoPictureBox)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Folder Contents Scanner"
$titleLabel.Location = New-Object System.Drawing.Point(60, 20) # Shift right to make space for logo
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.AutoSize = $true
$scannerPanel.Controls.Add($titleLabel)

$pathGroupBox = New-Object System.Windows.Forms.GroupBox
$pathGroupBox.Text = "Paths"
$pathGroupBox.Location = New-Object System.Drawing.Point(20, 70)
$pathGroupBox.Size = New-Object System.Drawing.Size(540, 100)
$scannerPanel.Controls.Add($pathGroupBox)

$folderPathTextBox = New-Object System.Windows.Forms.TextBox
$folderPathTextBox.Location = New-Object System.Drawing.Point(110, 25)
$folderPathTextBox.Size = New-Object System.Drawing.Size(290, 25)
$folderPathTextBox.ReadOnly = $true
# --- PERSONALIZATION: Set default scan folder ---
$folderPathTextBox.Text = "H:\Zachary Whiteman\Electronic Arts\The Sims 4\Mods"
$pathGroupBox.Controls.Add($folderPathTextBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse..."
$browseButton.Location = New-Object System.Drawing.Point(410, 23)
$browseButton.Size = New-Object System.Drawing.Size(110, 28)
$pathGroupBox.Controls.Add($browseButton)

$scanFolderLabel = New-Object System.Windows.Forms.Label
$scanFolderLabel.Text = "Folder to Scan:"
$scanFolderLabel.Location = New-Object System.Drawing.Point(15, 28)
$scanFolderLabel.AutoSize = $true
$pathGroupBox.Controls.Add($scanFolderLabel)

$outputPathTextBox = New-Object System.Windows.Forms.TextBox
$outputPathTextBox.Location = New-Object System.Drawing.Point(110, 60)
$outputPathTextBox.Size = New-Object System.Drawing.Size(290, 25)
$outputPathTextBox.ReadOnly = $true
# --- PERSONALIZATION: Set default output folder ---
$outputPathTextBox.Text = "H:\Zachary Whiteman\Documents\Electronic Arts\ScanResults"
$pathGroupBox.Controls.Add($outputPathTextBox)

$outputBrowseButton = New-Object System.Windows.Forms.Button
$outputBrowseButton.Text = "Browse..."
$outputBrowseButton.Location = New-Object System.Drawing.Point(410, 58)
$outputBrowseButton.Size = New-Object System.Drawing.Size(110, 28)
$pathGroupBox.Controls.Add($outputBrowseButton)

$outputPathLabel = New-Object System.Windows.Forms.Label
$outputPathLabel.Text = "Save Location:"
$outputPathLabel.Location = New-Object System.Drawing.Point(15, 63)
$outputPathLabel.AutoSize = $true
$pathGroupBox.Controls.Add($outputPathLabel)

$outputFormatGroupBox = New-Object System.Windows.Forms.GroupBox
$outputFormatGroupBox.Text = "Output Format"
$outputFormatGroupBox.Location = New-Object System.Drawing.Point(20, 180)
$outputFormatGroupBox.Size = New-Object System.Drawing.Size(540, 70)
$scannerPanel.Controls.Add($outputFormatGroupBox)

$txtRadioButton = New-Object System.Windows.Forms.RadioButton
$txtRadioButton.Text = "Text File (.txt)"
$txtRadioButton.Location = New-Object System.Drawing.Point(20, 30)
$txtRadioButton.AutoSize = $true
$txtRadioButton.Checked = $true
$outputFormatGroupBox.Controls.Add($txtRadioButton)

$csvRadioButton = New-Object System.Windows.Forms.RadioButton
$csvRadioButton.Text = "CSV File (.csv)"
$csvRadioButton.Location = New-Object System.Drawing.Point(150, 30)
$csvRadioButton.AutoSize = $true
$outputFormatGroupBox.Controls.Add($csvRadioButton)

$htmlRadioButton = New-Object System.Windows.Forms.RadioButton
$htmlRadioButton.Text = "Interactive HTML File (.html)"
$htmlRadioButton.Location = New-Object System.Drawing.Point(280, 30)
$htmlRadioButton.AutoSize = $true
$outputFormatGroupBox.Controls.Add($htmlRadioButton)

$advancedGroupBox = New-Object System.Windows.Forms.GroupBox
$advancedGroupBox.Text = "Advanced Options"
$advancedGroupBox.Location = New-Object System.Drawing.Point(20, 260)
$advancedGroupBox.Size = New-Object System.Drawing.Size(540, 100)
$scannerPanel.Controls.Add($advancedGroupBox)

$hashCheckBox = New-Object System.Windows.Forms.CheckBox
$hashCheckBox.Text = "Calculate MD5 Hash (Needed for HTML/CSV, slower)"
$hashCheckBox.Location = New-Object System.Drawing.Point(20, 30)
$hashCheckBox.AutoSize = $true
$advancedGroupBox.Controls.Add($hashCheckBox)

$filterLabel = New-Object System.Windows.Forms.Label
$filterLabel.Text = "Filter by extensions (e.g. .package,.zip):"
$filterLabel.Location = New-Object System.Drawing.Point(15, 65)
$filterLabel.AutoSize = $true
$advancedGroupBox.Controls.Add($filterLabel)

$filterTextBox = New-Object System.Windows.Forms.TextBox
$filterTextBox.Location = New-Object System.Drawing.Point(250, 62)
$filterTextBox.Size = New-Object System.Drawing.Size(270, 25)
$advancedGroupBox.Controls.Add($filterTextBox)

$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Text = "Start Folder Scan"
$scanButton.Location = New-Object System.Drawing.Point(20, 380)
$scanButton.Size = New-Object System.Drawing.Size(540, 50)
$scanButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$scannerPanel.Controls.Add($scanButton)

# --- TAB 2: Duplicate Finder ---
$duplicateTab = New-Object System.Windows.Forms.TabPage
$duplicateTab.Text = "Duplicate Finder"
$tabControl.Controls.Add($duplicateTab)
$duplicatePanel = New-Object System.Windows.Forms.Panel; $duplicatePanel.Dock = "Fill"; $duplicateTab.Controls.Add($duplicatePanel)

# Logo for Duplicate Finder Tab - positioned next to the title label
$duplicateLogoPictureBox = New-Object System.Windows.Forms.PictureBox
$duplicateLogoPictureBox.Location = New-Object System.Drawing.Point(20, 20)
$duplicateLogoPictureBox.Size = New-Object System.Drawing.Size(32, 32)
$duplicateLogoPictureBox.SizeMode = "StretchImage"
$duplicateLogoPictureBox.Image = $tabLogoBitmap
$duplicatePanel.Controls.Add($duplicateLogoPictureBox)

$dupTitleLabel = New-Object System.Windows.Forms.Label; $dupTitleLabel.Text = "Duplicate File Finder"; $dupTitleLabel.Location = New-Object System.Drawing.Point(60, 20); $dupTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold); $dupTitleLabel.AutoSize = $true; $duplicatePanel.Controls.Add($dupTitleLabel)
$dupOptionsGroupBox = New-Object System.Windows.Forms.GroupBox; $dupOptionsGroupBox.Text = "Scan Mode"; $dupOptionsGroupBox.Location = New-Object System.Drawing.Point(20, 70); $dupOptionsGroupBox.Size = New-Object System.Drawing.Size(540, 130); $duplicatePanel.Controls.Add($dupOptionsGroupBox)
$dupScanFolderRadio = New-Object System.Windows.Forms.RadioButton; $dupScanFolderRadio.Text = "Scan a folder for duplicates"; $dupScanFolderRadio.Location = New-Object System.Drawing.Point(15, 25); $dupScanFolderRadio.AutoSize = $true; $dupScanFolderRadio.Checked = $true; $dupOptionsGroupBox.Controls.Add($dupScanFolderRadio)
$dupScanFolderTextBox = New-Object System.Windows.Forms.TextBox; $dupScanFolderTextBox.Location = New-Object System.Drawing.Point(35, 50); $dupScanFolderTextBox.Size = New-Object System.Drawing.Size(365, 25); $dupScanFolderTextBox.ReadOnly = $true; $dupOptionsGroupBox.Controls.Add($dupScanFolderTextBox)
$dupScanFolderBrowseBtn = New-Object System.Windows.Forms.Button; $dupScanFolderBrowseBtn.Text = "Browse..."; $dupScanFolderBrowseBtn.Location = New-Object System.Drawing.Point(410, 48); $dupScanFolderBrowseBtn.Size = New-Object System.Drawing.Size(110, 28); $dupOptionsGroupBox.Controls.Add($dupScanFolderBrowseBtn)
$dupScanReportRadio = New-Object System.Windows.Forms.RadioButton; $dupScanReportRadio.Text = "Analyze a previous scan report (.csv or .txt with hashes)"; $dupScanReportRadio.Location = New-Object System.Drawing.Point(15, 85); $dupScanReportRadio.AutoSize = $true; $dupOptionsGroupBox.Controls.Add($dupScanReportRadio)
$dupReportFileTextBox = New-Object System.Windows.Forms.TextBox; $dupReportFileTextBox.Location = New-Object System.Drawing.Point(35, 110); $dupReportFileTextBox.Size = New-Object System.Drawing.Size(365, 25); $dupReportFileTextBox.ReadOnly = $true; $dupReportFileTextBox.Enabled = $false; $dupOptionsGroupBox.Controls.Add($dupReportFileTextBox)
$dupReportFileBrowseBtn = New-Object System.Windows.Forms.Button; $dupReportFileBrowseBtn.Text = "Browse..."; $dupReportFileBrowseBtn.Location = New-Object System.Drawing.Point(410, 108); $dupReportFileBrowseBtn.Size = New-Object System.Drawing.Size(110, 28); $dupReportFileBrowseBtn.Enabled = $false; $dupOptionsGroupBox.Controls.Add($dupReportFileBrowseBtn)
$dupResultsGroupBox = New-Object System.Windows.Forms.GroupBox; $dupResultsGroupBox.Text = "Duplicate Sets Found"; $dupResultsGroupBox.Location = New-Object System.Drawing.Point(20, 210); $dupResultsGroupBox.Size = New-Object System.Drawing.Size(540, 270); $duplicatePanel.Controls.Add($dupResultsGroupBox)
$dupResultsListView = New-Object System.Windows.Forms.ListView; $dupResultsListView.View = "Details"; $dupResultsListView.Location = New-Object System.Drawing.Point(15, 25); $dupResultsListView.Size = New-Object System.Drawing.Size(510, 230); $dupResultsListView.Columns.Add("File Hash (MD5)", 250); $dupResultsListView.Columns.Add("Count", 50); $dupResultsListView.Columns.Add("File Paths", 500); $dupResultsListView.FullRowSelect = $true; $dupResultsListView.MultiSelect = $false; $dupResultsGroupBox.Controls.Add($dupResultsListView)
$findDuplicatesButton = New-Object System.Windows.Forms.Button; $findDuplicatesButton.Text = "Find Duplicates"; $findDuplicatesButton.Location = New-Object System.Drawing.Point(20, 490); $findDuplicatesButton.Size = New-Object System.Drawing.Size(540, 50); $findDuplicatesButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $duplicatePanel.Controls.Add($findDuplicatesButton)


# --- Global Controls (Progress Bar & Status) ---
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 610)
$progressBar.Size = New-Object System.Drawing.Size(575, 25)
$progressBar.Visible = $false
$mainForm.Controls.Add($progressBar)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready. Please select an action."
$statusLabel.Location = New-Object System.Drawing.Point(20, 645)
$statusLabel.Size = New-Object System.Drawing.Size(575, 20)
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$statusLabel.ForeColor = [System.Drawing.Color]::Gray
$mainForm.Controls.Add($statusLabel)

#endregion

#region Event Handler Logic

# --- Helper Functions ---
function Show-FolderBrowser($description) {
    $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowserDialog.Description = $description
    $folderBrowserDialog.ShowNewFolderButton = $true
    if ($folderBrowserDialog.ShowDialog($mainForm) -eq "OK") { return $folderBrowserDialog.SelectedPath }
    return $null
}

function Show-FileBrowser($title, $filter) {
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $title
    $openFileDialog.Filter = $filter
    if ($openFileDialog.ShowDialog($mainForm) -eq "OK") { return $openFileDialog.FileName }
    return $null
}

function Set-UIState($enabled) {
    $mainForm.Cursor = if ($enabled) { [System.Windows.Forms.Cursors]::Default } else { [System.Windows.Forms.Cursors]::WaitCursor }
    $tabControl.Enabled = $enabled
    $menuStrip.Enabled = $enabled
}

function ConvertTo-InteractiveHtml {
    param(
        [Parameter(Mandatory=$true)] $Items, # Expects items with .MD5Hash and .IsDuplicate properties
        [Parameter(Mandatory=$true)] $ReportMetadata
    )
   
    $tableRows = foreach ($item in $Items) {
        if ($item.PSIsContainer) { continue } # Skip folders for this report type
        $sizeKB = [math]::Round($item.Length / 1KB, 2)
        $hash = $item.MD5Hash # Use the pre-calculated hash
        $isDuplicate = if ($item.IsDuplicate) { "Yes" } else { "No" }
        # Adding data-isduplicate attribute for JS filtering
        "                   <tr>
                            <td>$([System.Security.SecurityElement]::Escape($item.Name))</td>
                            <td>$([System.Security.SecurityElement]::Escape($item.DirectoryName.Replace($ReportMetadata.targetPath, '.\'))))</td>
                            <td>$($item.Extension)</td>
                            <td data-sort='$($item.Length)'>$($sizeKB)</td>
                            <td data-sort='$($item.LastWriteTime.Ticks)'>$($item.LastWriteTime)</td>
                            <td>$($hash)</td>
                            <td data-isduplicate='$($isDuplicate)'>$($isDuplicate)</td>
                        </tr>"
    }

    # Calculate sizes for display in HTML
    $totalSizeKB = $ReportMetadata.totalSizeKB
    # Using 1024 for KB->MB and MB->GB conversions for consistent binary units
    $totalSizeMB = [math]::Round($totalSizeKB / 1024, 2)
    $totalSizeGB = [math]::Round($totalSizeMB / 1024, 2)

    $htmlTemplate = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Folder Scan Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; margin: 0; background-color: #f4f4f9; color: #333; }
        .container { max-width: 1200px; margin: 20px auto; padding: 20px; background-color: #fff; box-shadow: 0 2px 10px rgba(0,0,0,0.1); border-radius: 8px; }
        h1, h2 { color: #1a1a1a; }
        h2 { border-bottom: 2px solid #e1e1e1; padding-bottom: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; table-layout: fixed; }
        th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #ddd; word-wrap: break-word; }
        thead th { background-color: #0078d4; color: #fff; cursor: pointer; user-select: none; position: relative; }
        thead th::after { content: ''; position: absolute; right: 10px; top: 50%; transform: translateY(-50%); border: 5px solid transparent; }
        thead th.sort-asc::after { border-bottom-color: #fff; }
        thead th.sort-desc::after { border-top-color: #fff; }
        tbody tr:nth-of-type(even) { background-color: #f9f9f9; }
        tbody tr:hover { background-color: #f1f1f1; }
        .search-controls { display: flex; gap: 10px; margin-bottom: 20px; flex-wrap: wrap; }
        .search-box { flex-grow: 1; padding: 10px; font-size: 16px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; min-width: 200px; }
        .filter-group { display: flex; align-items: center; gap: 5px; }
        .metadata p { margin: 5px 0; }
        .metadata code { background-color: #e1e1e1; padding: 2px 5px; border-radius: 3px; word-break: break-all; }
    </style>
</head>
<body>
<div class="container">
    <h1>Folder Scan Report</h1>
    <div class="metadata">
        <p><strong>Scanned Folder:</strong> <code>$($ReportMetadata.targetPath)</code></p>
        <p><strong>Scan Date:</strong> $($ReportMetadata.scanDate)</p>
        <p><strong>Total Files Found:</strong> $($ReportMetadata.totalFiles)</p>
        <p><strong>Total Folder Size:</strong> $($totalSizeGB) GB ($($totalSizeMB) MB / $($totalSizeKB) KB)</p>
        <p><strong>Unique Files:</strong> $($ReportMetadata.uniqueFiles)</p>
        <p><strong>Duplicate Files:</strong> $($ReportMetadata.duplicateFiles)</p>
    </div>
    <h2>File List</h2>
    <div class="search-controls">
        <input type="text" id="searchInput" onkeyup="searchTable()" placeholder="Search for files..." class="search-box">
        <div class="filter-group">
            <label for="duplicateFilter">Show:</label>
            <select id="duplicateFilter" onchange="filterDuplicates()">
                <option value="all">All Files</option>
                <option value="unique">Unique Files Only</option>
                <option value="duplicates">Duplicate Files Only</option>
            </select>
        </div>
    </div>
    <table id="reportTable">
        <thead>
            <tr>
                <th onclick="sortTable(0)" style="width: 25%;">File Name</th>
                <th onclick="sortTable(1)" style="width: 25%;">Relative Path</th>
                <th onclick="sortTable(2)" style="width: 8%;">Extension</th>
                <th onclick="sortTable(3, 'num')" style="width: 8%;">Size (KB)</th>
                <th onclick="sortTable(4, 'num')" style="width: 12%;">Date Modified</th>
                <th onclick="sortTable(5)" style="width: 12%;">MD5 Hash</th>
                <th onclick="sortTable(6, 'bool')" style="width: 10%;">Is Duplicate?</th>
            </tr>
        </thead>
        <tbody>
            $([string]::Join([Environment]::NewLine, $tableRows))
        </tbody>
    </table>
</div>
<script>
    function searchTable() {
        const input = document.getElementById('searchInput');
        const filter = input.value.toUpperCase();
        const table = document.getElementById('reportTable');
        const tr = table.getElementsByTagName('tr');
        for (let i = 1; i < tr.length; i++) {
            let visible = false;
            const td = tr[i].getElementsByTagName('td');
            // Check all columns except the 'Is Duplicate?' column (index 6) for search
            for (let j = 0; j < td.length - 1; j++) { // Loop up to 6th column
                if (td[j] && td[j].textContent.toUpperCase().indexOf(filter) > -1) {
                    visible = true;
                    break; // Found match, no need to check other cells for this row
                }
            }
            // Apply current duplicate filter after search visibility is determined
            const duplicateFilter = document.getElementById('duplicateFilter').value;
            const isDuplicateCell = td[6]; // 'Is Duplicate?' column is at index 6
            const isDuplicate = isDuplicateCell.getAttribute('data-isduplicate') === 'Yes';

            if (duplicateFilter === 'unique' && isDuplicate) {
                visible = false;
            } else if (duplicateFilter === 'duplicates' && !isDuplicate) {
                visible = false;
            }
            
            tr[i].style.display = visible ? '' : 'none';
        }
    }
    
    function filterDuplicates() {
        searchTable(); // Re-run searchTable to apply both search and duplicate filter
    }

    function sortTable(n, type = 'str') {
        const table = document.getElementById('reportTable');
        let switching = true, shouldSwitch, i;
        let dir = "asc";
        let switchcount = 0;
        
        const headers = table.getElementsByTagName("TH");
        // Remove existing sort indicators from all headers
        for (let h of headers) { h.classList.remove('sort-asc', 'sort-desc'); }
        // Determine initial direction based on current sort of the clicked column
        if (headers[n].classList.contains('sort-asc')) {
            dir = "desc";
        } else if (headers[n].classList.contains('sort-desc')) {
            dir = "asc"; // Cycle back to asc
        }
        
        while (switching) {
            switching = false;
            const rows = table.rows;
            for (i = 1; i < (rows.length - 1); i++) {
                shouldSwitch = false;
                const x = rows[i].getElementsByTagName("TD")[n];
                const y = rows[i + 1].getElementsByTagName("TD")[n];
               
                let valX, valY;
                if (type === 'num') {
                    valX = Number(x.dataset.sort || x.innerHTML);
                    valY = Number(y.dataset.sort || y.innerHTML);
                } else if (type === 'bool') { // For 'Is Duplicate?' column
                    // 'Yes' comes before 'No' in ascending sort (0 for No, 1 for Yes)
                    valX = x.getAttribute('data-isduplicate') === 'Yes' ? 1 : 0;
                    valY = y.getAttribute('data-isduplicate') === 'Yes' ? 1 : 0;
                }
                else {
                    valX = x.innerHTML.toLowerCase();
                    valY = y.innerHTML.toLowerCase();
                }

                if (dir == "asc") {
                    if (valX > valY) { shouldSwitch = true; break; }
                } else if (dir == "desc") {
                    if (valX < valY) { shouldSwitch = true; break; }
                }
            }
            if (shouldSwitch) {
                rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
                switching = true;
                switchcount++;
            } else {
                // If no switches were made in this pass and it was an ascending sort,
                // it means the table is sorted or all values are equal.
                // For a toggle sort, if no switch happened on the first 'asc' pass,
                // it means it's already sorted, so switch to 'desc' for the next click.
                if (switchcount == 0 && dir == "asc") {
                    dir = "desc";
                    switching = true; // Rerun the loop with new direction
                }
            }
        }
        // Apply sorting indicator to header
        headers[n].classList.add(dir === 'asc' ? 'sort-asc' : 'sort-desc');
    }
</script>
</body>
</html>
"@
    return $htmlTemplate
}


# --- Menu Item Clicks ---
$setIconMenuItem.Add_Click({
    $iconPath = Show-FileBrowser "Select an Icon File" "Icon Files (*.ico)|*.ico|All Files (*.*)|*.*"
    if ($iconPath -and (Test-Path $iconPath)) {
        try {
            $mainForm.Icon = New-Object System.Drawing.Icon($iconPath)
            # Update the logo bitmap for the tabs to reflect the newly set icon
            $tabLogoBitmap = $mainForm.Icon.ToBitmap()
            $scannerLogoPictureBox.Image = $tabLogoBitmap
            $duplicateLogoPictureBox.Image = $tabLogoBitmap

            Save-Settings -settings @{ CustomIconPath = $iconPath }
            [System.Windows.Forms.MessageBox]::Show("Icon has been set and will be remembered.", "Success", "OK", "Information")
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("The selected file is not a valid icon.", "Error", "OK", "Error")
        }
    }
})

$exitMenuItem.Add_Click({ $mainForm.Close() })

# --- Scanner Tab Events ---
$browseButton.Add_Click({
    $selectedPath = Show-FolderBrowser "Select the folder to scan"
    if ($selectedPath) { $folderPathTextBox.Text = $selectedPath }
})

$outputBrowseButton.Add_Click({
    $selectedPath = Show-FolderBrowser "Select where to save the output file"
    if ($selectedPath) { $outputPathTextBox.Text = $selectedPath }
})

$scanButton.Add_Click({
    # Input validation for scan folder and save location
    if ([string]::IsNullOrWhiteSpace($folderPathTextBox.Text) -or [string]::IsNullOrWhiteSpace($outputPathTextBox.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Please select both a folder to scan and a save location.", "Input Missing", "OK", "Warning")
        return
    }
    # Check if the folder to scan exists
    if (-not (Test-Path -Path $folderPathTextBox.Text -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show("The folder to scan does not exist. Please select a valid folder.", "Invalid Path", "OK", "Error")
        return
    }
   
    # Auto-create output directory if it doesn't exist.
    if (-not (Test-Path -Path $outputPathTextBox.Text -PathType Container)) {
        try {
            New-Item -Path $outputPathTextBox.Text -ItemType Directory -Force -ErrorAction Stop | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Could not create the output directory: $($_.Exception.Message). Please select a different location.", "Directory Error", "OK", "Error")
            return
        }
    }

    # Prompt to enable hash calculation for CSV/HTML if not already checked
    if (($csvRadioButton.Checked -or $htmlRadioButton.Checked) -and !$hashCheckBox.Checked) {
        if ([System.Windows.Forms.MessageBox]::Show("CSV and HTML reports are best with file hashes. Do you want to enable hash calculation for this scan?", "Enable Hashes?", "YesNo", "Question") -eq "Yes") {
            $hashCheckBox.Checked = $true
        }
    }
   
    Set-UIState $false # Disable UI during scan
    $progressBar.Visible = $true # Show progress bar
    $statusLabel.Text = "Scanning folder..." # Update status
    $mainForm.Update() # Force UI refresh

    try {
        $targetPath = $folderPathTextBox.Text
        $outputPath = $outputPathTextBox.Text
        $scanDate = Get-Date
        $outputFileBase = "FolderScan_$(Split-Path $targetPath -Leaf)_$($scanDate.ToString('yyyy-MM-dd_HH-mm-ss'))"

        # Get all items (files and folders) recursively
        $gciParams = @{ Path = $targetPath; Recurse = $true; Force = $true; ErrorAction = 'SilentlyContinue' }
        if (-not [string]::IsNullOrWhiteSpace($filterTextBox.Text)) {
            $gciParams.Include = ($filterTextBox.Text -split ',' | ForEach-Object { "*$($_.Trim())" })
        }
        $allItems = Get-ChildItem @gciParams

        $outputExtension = if ($txtRadioButton.Checked) { ".txt" } elseif ($csvRadioButton.Checked) { ".csv" } else { ".html" }
        $outputFile = Join-Path -Path $outputPath -ChildPath "$($outputFileBase)$($outputExtension)"
       
        # HTML Report Generation
        if ($htmlRadioButton.Checked) {
            $filesOnly = $allItems | Where-Object { -not $_.PSIsContainer }
            
            # Calculate total size of all scanned files
            $totalSizeKB = [math]::Round(($filesOnly | Measure-Object -Property Length -Sum).Sum / 1KB, 2)

            # Prepare files for HTML report by calculating hashes and identifying duplicates
            $fileHashes = @{} # To store first occurrence of a hash
            $duplicateHashes = New-Object System.Collections.Generic.HashSet[string] # To store hashes that are duplicates
            $filesWithHashAndDuplicateStatus = @()

            foreach ($file in $filesOnly) {
                $md5Hash = if ($hashCheckBox.Checked) { 
                    try { 
                        $hashResult = Get-FileHash -Algorithm MD5 -Path $file.FullName -ErrorAction SilentlyContinue
                        if ($hashResult) {
                            $hashResult.Hash
                        } else {
                            "ErrorCalculatingHash" # Fallback if Get-FileHash returns null/empty
                        }
                    }
                    catch { 
                        "ErrorCalculatingHash" # Assign a distinct value for errors
                    }
                } else { "N/A" }

                # Ensure $md5Hash is never null or empty before adding as a property or using as key
                if ([string]::IsNullOrEmpty($md5Hash)) {
                    $md5Hash = "InvalidHash" # A default non-null, non-empty string for problematic hashes
                }

                # Add MD5Hash property to the file object
                $file | Add-Member -MemberType NoteProperty -Name MD5Hash -Value $md5Hash -Force

                # Now, perform the ContainsKey check ensuring $md5Hash is not 'N/A' or any error/invalid state
                if ($md5Hash -ne "N/A" -and $md5Hash -ne "ErrorCalculatingHash" -and $md5Hash -ne "InvalidHash") {
                    if ($fileHashes.ContainsKey($md5Hash)) {
                        # This hash has been seen before, so both this file and the previous one are duplicates
                        $fileHashes[$md5Hash] | Add-Member -MemberType NoteProperty -Name IsDuplicate -Value $true -Force
                        $file | Add-Member -MemberType NoteProperty -Name IsDuplicate -Value $true -Force
                        $duplicateHashes.Add($md5Hash)
                    } else {
                        $fileHashes[$md5Hash] = $file
                        $file | Add-Member -MemberType NoteProperty -Name IsDuplicate -Value $false -Force
                    }
                } else {
                    # Files with "N/A", "ErrorCalculatingHash", or "InvalidHash" are not considered duplicates
                    $file | Add-Member -MemberType NoteProperty -Name IsDuplicate -Value $false -Force
                }
                $filesWithHashAndDuplicateStatus += $file
            }

            # Ensure all files that share a hash marked as duplicate
            # (A second pass is needed because a file might be marked 'false' initially,
            # but then a duplicate appears later in the list)
            $finalFilesForHtml = $filesWithHashAndDuplicateStatus | ForEach-Object {
                if ($duplicateHashes.Contains($_.MD5Hash)) {
                    $_ | Add-Member -MemberType NoteProperty -Name IsDuplicate -Value $true -Force
                }
                $_
            } | Sort-Object Name # Sort by name for consistent report, or other preference

            $uniqueFilesCount = ($finalFilesForHtml | Where-Object { -not $_.IsDuplicate }).Count
            $duplicateFilesCount = ($finalFilesForHtml | Where-Object { $_.IsDuplicate }).Count # This counts each *instance* of a duplicate file

            # Prepare metadata for the HTML report
            $reportMetadata = @{ 
                targetPath = $targetPath; 
                scanDate = $scanDate; 
                totalFiles = $filesOnly.Count;
                totalSizeKB = $totalSizeKB;
                uniqueFiles = $uniqueFilesCount;
                duplicateFiles = $duplicateFilesCount;
            }
            # Generate HTML content
            $htmlContent = ConvertTo-InteractiveHtml -Items $finalFilesForHtml -ReportMetadata $reportMetadata
            $htmlContent | Out-File -FilePath $outputFile -Encoding UTF8
        }
        # Text File Report Generation
        elseif ($txtRadioButton.Checked) {
            $fileContent = "Folder Scan Report`r`n================================`r`nScanned Folder: $targetPath`r`nScan Date: $scanDate`r`n================================`r`n`r`n"
            foreach ($item in $allItems) {
                $indent = "   " * (($item.FullName.Substring($targetPath.Length) -split '[\\/]').Count - 2)
                if ($item.PSIsContainer) { $fileContent += "$($indent)└── [$($item.Name)]`r`n" }
                else {
                    $fileSizeKB = [math]::Round($item.Length / 1KB, 2)
                    $fileInfo = "$($indent)   ├── $($item.Name) ($($fileSizeKB) KB)"
                    if ($hashCheckBox.Checked) { $fileInfo += " [MD5: $((Get-FileHash -Algorithm MD5 -Path $item.FullName).Hash)]" }
                    $fileContent += "$fileInfo`r`n"
                }
            }
            $fileContent | Out-File -FilePath $outputFile -Encoding UTF8
        }
        # CSV File Report Generation
        elseif ($csvRadioButton.Checked) {
            $report = $allItems | ForEach-Object {
                $props = [ordered]@{ 
                    "Type" = if ($_.PSIsContainer) { "Folder" } else { "File" }; 
                    "FileName" = $_.Name; 
                    "FolderPath" = $_.DirectoryName; 
                    "FullPath" = $_.FullName; 
                    "Extension" = $_.Extension; 
                    "Size_KB" = if (-not $_.PSIsContainer) { [math]::Round($_.Length / 1KB, 2) } else { 0 }; 
                    "DateCreated" = $_.CreationTime; 
                    "DateModified" = $_.LastWriteTime 
                }
                if ($hashCheckBox.Checked -and -not $_.PSIsContainer) { 
                    try { 
                        $props.Add("MD5Hash", (Get-FileHash -Algorithm MD5 -Path $_.FullName).Hash) 
                    } catch {
                        $props.Add("MD5Hash", "ErrorCalculatingHash")
                    }
                }
                [PSCustomObject]$props
            }
            $report | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
        }
       
        $statusLabel.Text = "Scan complete! File saved to: $outputFile"
        $dialogMessage = "Scan complete!`nOutput file saved to:`n$outputFile`n`nWould you like to open the file now?"
        # Using [System.Windows.Forms.MessageBox]::Show with parent form argument
        if ([System.Windows.Forms.MessageBox]::Show($mainForm, $dialogMessage, "Success", "YesNo", "Question") -eq "Yes") {
            try { Invoke-Item -Path $outputFile -ErrorAction Stop }
            catch { [System.Windows.Forms.MessageBox]::Show($mainForm, "Could not open file: $($_.Exception.Message)", "File Error", "OK", "Error") }
        }
    }
    catch {
        $statusLabel.Text = "An error occurred during the scan."
        # Using [System.Windows.Forms.MessageBox]::Show with parent form argument
        [System.Windows.Forms.MessageBox]::Show($mainForm, "An error occurred: $($_.Exception.Message)", "Error", "OK", "Error")
    }
    finally {
        Set-UIState $true # Re-enable UI
        $progressBar.Visible = $false # Hide progress bar
    }
})

# --- Duplicate Finder Tab Events --- 
$dupScanFolderRadio.Add_CheckedChanged({ 
    if ($dupScanFolderRadio.Checked) { 
        $dupScanFolderTextBox.Enabled = $true; 
        $dupScanFolderBrowseBtn.Enabled = $true; 
        $dupReportFileTextBox.Enabled = $false; 
        $dupReportFileBrowseBtn.Enabled = $false 
    }
})
$dupScanReportRadio.Add_CheckedChanged({ 
    if ($dupScanReportRadio.Checked) { 
        $dupScanFolderTextBox.Enabled = $false; 
        $dupScanFolderBrowseBtn.Enabled = $false; 
        $dupReportFileTextBox.Enabled = $true; 
        $dupReportFileBrowseBtn.Enabled = $true 
    }
})
$dupScanFolderBrowseBtn.Add_Click({ 
    $selectedPath = Show-FolderBrowser "Select folder to scan for duplicates"; 
    if ($selectedPath) { $dupScanFolderTextBox.Text = $selectedPath } 
})
$dupReportFileBrowseBtn.Add_Click({ 
    $selectedPath = Show-FileBrowser "Select Scan Report" "Report Files (*.csv, *.txt)|*.csv;*.txt|All Files (*.*)|*.*"; 
    if ($selectedPath) { $dupReportFileTextBox.Text = $selectedPath } 
})
$findDuplicatesButton.Add_Click({
    Set-UIState $false; 
    $progressBar.Visible = $true; 
    $statusLabel.Text = "Finding duplicates..."; 
    $dupResultsListView.Items.Clear(); 
    $mainForm.Update()
    try {
        $duplicates = if ($dupScanFolderRadio.Checked) {
            if ([string]::IsNullOrWhiteSpace($dupScanFolderTextBox.Text)) { throw "Please select a folder to scan." }
            (Get-ChildItem -Path $dupScanFolderTextBox.Text -Recurse -File -ErrorAction SilentlyContinue) | Get-FileHash -Algorithm MD5 | Group-Object -Property Hash | Where-Object { $_.Count -gt 1 }
        } else {
            if ([string]::IsNullOrWhiteSpace($dupReportFileTextBox.Text)) { throw "Please select a report file." }
            $reportPath = $dupReportFileTextBox.Text
            if ($reportPath.EndsWith(".csv")) { 
                (Import-Csv $reportPath) | Where-Object { $_.MD5Hash -ne "N/A" -and $_.MD5Hash -ne "ErrorCalculatingHash" } | Group-Object -Property MD5Hash | Where-Object { $_.Count -gt 1 } 
            }
            elseif ($reportPath.EndsWith(".txt")) { 
                (Get-Content $reportPath) | 
                ForEach-Object { 
                    # Regex to extract path and MD5 hash from the TXT format
                    if ($_ -match '^(.*?)\s+\[MD5: ([a-fA-F0-9]{32})\]$') {
                        # Extract the path part, removing the '├──' prefix and trimming whitespace
                        $rawPath = $matches[1]
                        $trimmedPath = $rawPath -replace '^\s*(└──|├──)\s*', ''
                        [pscustomobject]@{ Path = $trimmedPath; Hash = $matches[2] } 
                    }
                } | 
                Where-Object { $_.Hash } | 
                Group-Object -Property Hash | 
                Where-Object { $_.Count -gt 1 } 
            }
            else { throw "Unsupported report file type." }
        }
        if ($duplicates) {
            foreach ($group in $duplicates) {
                # Ensure paths are collected correctly for display and tooltip
                $pathsForDisplay = ($group.Group | Select-Object -ExpandProperty Path | Select-Object -First 3) -join "; "
                if ($group.Count -gt 3) { $pathsForDisplay += "..." }
                $allPathsToolTip = ($group.Group | Select-Object -ExpandProperty Path) -join [Environment]::NewLine
                
                $item = New-Object System.Windows.Forms.ListViewItem($group.Name) # Hash
                $item.SubItems.Add($group.Count) # Count
                $item.SubItems.Add($pathsForDisplay) # Display paths
                $item.ToolTipText = $allPathsToolTip # Full paths in tooltip
                $dupResultsListView.Items.Add($item) | Out-Null
            }
            $statusLabel.Text = "Found $($dupResultsListView.Items.Count) sets of duplicate files."
        } else {
            $statusLabel.Text = "No duplicate files found."; 
            [System.Windows.Forms.MessageBox]::Show($mainForm, "No duplicates were found.", "Scan Complete", "OK", "Information")
        }
    } catch { 
        $statusLabel.Text = "An error occurred."; 
        [System.Windows.Forms.MessageBox]::Show($mainForm, "An error occurred: $($_.Exception.Message)", "Error", "OK", "Error") 
    }
    finally { 
        Set-UIState $true; 
        $progressBar.Visible = $false 
    }
})

#endregion

#region Application Start
[void]$mainForm.ShowDialog()
#endregion
