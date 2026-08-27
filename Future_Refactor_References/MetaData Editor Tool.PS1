using namespace System.Windows.Forms
using namespace System.Drawing
using namespace System.Runtime.InteropServices

<#
.SYNOPSIS
    A GUI-based tool to view and edit metadata for files and folders.
.DESCRIPTION
    This PowerShell script launches a Windows Forms application that allows a user to select a file or a folder,
    view its common and extended metadata properties, and modify them.
    For files, it leverages the Shell.Application COM object to interact with extended properties dynamically.
    For folders, it modifies the desktop.ini file to set the 'InfoTip' (Comments) and a custom 'Tags' property.
    This is designed to help organize project templates and integrate with tools like Stardock Fences.
.NOTES
    Project Name: PowerShell Metadata Editor v1.1
    Created by: Zachary Whiteman & Google Gemini AI (Refactored by ChatGPT/Bard)
    Date: 7/13/2025 (Original Date)
    Requires: PowerShell 5.1 or higher (Tested on PowerShell 7). GUI may look slightly different between versions.
    Compatibility: Requires Windows OS for Shell.Application COM object and Windows Forms.
#>

# --- Assembly Loading ---
# Load the necessary .NET assemblies for creating a Graphical User Interface (GUI).
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
} catch {
    Write-Error "Failed to load required .NET assemblies. This script requires a Windows environment with .NET Framework. Error: $($_.Exception.Message)"
    exit 1
}

# --- Global UI Element References and Metadata Definitions ---
# This hashtable will store references to dynamically created text boxes, mapped by canonical name.
$global:TextBoxes = @{}
$global:lblStatus = $null
$global:txtPath = $null
$global:lblItemType = $null
$global:dynamicFieldsPanel = $null

# Define a rich set of metadata properties, including their canonical names
# and how they map to UI and behavior.
# IsReadOnly: True for properties that cannot be directly set by the shell API (e.g., file system properties like Date Created).
# IsMultiValue: True if the property accepts multiple values (e.g., Authors, Keywords).
# Delimiter: The character used to join/split multi-value properties in the UI.
# AppliesToFile: True if this property is generally applicable and editable for files via Shell.Application.
# AppliesToFolder: True if this property should be handled (read/write) for folders (e.g., via desktop.ini).
# FolderIniKey: The key name in desktop.ini if ApplicableToFolder is true (e.g., InfoTip). Leave blank if not applicable.
$global:MetadataPropertyDefinitions = @(
    @{ DisplayName = "Title"; CanonicalName = "System.Title"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Subject"; CanonicalName = "System.Subject"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Authors"; CanonicalName = "System.Author"; IsReadOnly = $false; IsMultiValue = $true; Delimiter = "; "; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Keywords (Tags)"; CanonicalName = "System.Keywords"; IsReadOnly = $false; IsMultiValue = $true; Delimiter = "; "; AppliesToFile = $true; AppliesToFolder = $true; FolderIniKey = "Tags" }, # Custom key for folder
    @{ DisplayName = "Comments"; CanonicalName = "System.Comment"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $true; FolderIniKey = "InfoTip" },
    @{ DisplayName = "Category"; CanonicalName = "System.Category"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Company"; CanonicalName = "System.Company"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Program Name"; CanonicalName = "System.ApplicationName"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Copyright"; CanonicalName = "System.Copyright"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Rating"; CanonicalName = "System.Rating"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Source"; CanonicalName = "System.Source"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Date Acquired"; CanonicalName = "System.DateAcquired"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Date Last Saved"; CanonicalName = "System.DateSaved"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Project"; CanonicalName = "System.Project"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },

    # Media-specific properties (can add more from System.Media, System.Audio, System.Video)
    @{ DisplayName = "Album Title"; CanonicalName = "System.Music.AlbumTitle"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Artist"; CanonicalName = "System.Music.Artist"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Album Artist"; CanonicalName = "System.Music.AlbumArtist"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Genre"; CanonicalName = "System.Music.Genre"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Composer"; CanonicalName = "System.Music.Composer"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Year"; CanonicalName = "System.Music.Year"; IsReadOnly = $false; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },

    # Read-only common properties (example - usually not editable via Shell.Application)
    @{ DisplayName = "File Size"; CanonicalName = "System.Size"; IsReadOnly = $true; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Date Created"; CanonicalName = "System.DateCreated"; IsReadOnly = $true; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "Date Modified"; CanonicalName = "System.DateModified"; IsReadOnly = $true; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "File Type"; CanonicalName = "System.ItemTypeText"; IsReadOnly = $true; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" },
    @{ DisplayName = "File Path"; CanonicalName = "System.ParsingPath"; IsReadOnly = $true; IsMultiValue = $false; AppliesToFile = $true; AppliesToFolder = $false; FolderIniKey = "" }
)

# --- Main Form Definition ---
$mainForm = [Form]::new()
$mainForm.Text = "Metadata Editor v1.1"
$mainForm.Size = [Size]::new(580, 650) # Increased size for more fields and better layout
$mainForm.MinimumSize = [Size]::new(580, 500)
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = 'Sizable' # Allow resizing
$mainForm.MaximizeBox = $true # Allow maximizing

# --- Function to Get Shell Application Object ---
function Get-Shell {
    try {
        return [Shell.Application]::new()
    } catch {
        Write-Warning "Could not create Shell.Application COM object. File metadata features will be unavailable. Error: $($_.Exception.Message)"
        return $null
    }
}

# --- Function to Read INI File ---
# This function reads values from an INI file (like desktop.ini).
function Read-IniFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [string]$Section = "",
        [string]$Key = ""
    )
    
    if (-not (Test-Path $Path -PathType Leaf)) { return $null }

    $content = (Get-Content $Path -Raw) -split "`r`n|`n" # Split by Windows or Unix newlines
    $currentSection = ""
    $sectionData = [ordered]@{}
    $inRequestedSection = $false

    foreach ($line in $content) {
        $trimmedLine = $line.Trim()
        if ($trimmedLine.StartsWith("[") -and $trimmedLine.EndsWith("]")) {
            $currentSection = $trimmedLine.Substring(1, $trimmedLine.Length - 2)
            $inRequestedSection = ($Section -eq "" -or $currentSection -eq $Section) # Check if we are in the target section
        } elseif ($inRequestedSection -and $trimmedLine -match "^([^=]+)=(.*)") {
            $iniKey = $matches[1].Trim()
            $iniValue = $matches[2].Trim()
            
            if (-not $sectionData.ContainsKey($currentSection)) {
                $sectionData[$currentSection] = [ordered]@{}
            }
            $sectionData[$currentSection][$iniKey] = $iniValue
        }
    }

    if ($Section -ne "") {
        if ($sectionData.ContainsKey($Section)) {
            if ($Key -ne "") {
                return $sectionData[$Section][$Key]
            } else {
                return $sectionData[$Section]
            }
        }
        return $null
    }
    return $sectionData # Return all sections/keys if no specific section requested
}

# --- Function to Update INI File ---
# This function updates specific keys within a specific section of an INI file.
# It preserves existing sections and keys not specified for update.
function Update-IniFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$Section,
        [Parameter(Mandatory=$true)]
        [hashtable]$PropertiesToUpdate
    )

    $existingLines = @()
    if (Test-Path $Path -PathType Leaf) {
        $existingLines = (Get-Content $Path -Raw) -split "`r`n|`n"
    }

    $newLines = [System.Collections.ArrayList]::new()
    $inTargetSection = $false
    $sectionFound = $false
    $updatedProperties = [hashtable]::new($PropertiesToUpdate, [System.StringComparer]::InvariantCultureIgnoreCase) # Clone and use case-insensitive keys
    
    # Temporary list to store lines for the target section, so new properties can be added at the end of the section
    $targetSectionTempLines = [System.Collections.ArrayList]::new()

    foreach ($line in $existingLines) {
        $trimmedLine = $line.Trim()

        if ($trimmedLine.StartsWith("[") -and $trimmedLine.EndsWith("]")) {
            # If we were in the target section, add its lines (including newly added props)
            if ($inTargetSection) {
                foreach ($prop in $updatedProperties.GetEnumerator()) {
                    if ($prop.Value -ne $null) { # Add remaining properties that weren't existing in the INI
                        $targetSectionTempLines.Add("$($prop.Key)=$($prop.Value)")
                    }
                }
                $newLines.AddRange($targetSectionTempLines) # Add collected lines to overall newLines
                $targetSectionTempLines.Clear()
            }

            # Check if current section is the target section
            if ($trimmedLine -eq "[$Section]") {
                $inTargetSection = $true
                $sectionFound = $true
            } else {
                $inTargetSection = $false
            }
            $newLines.Add($line) # Always add the section header
        } elseif ($inTargetSection) {
            # Inside the target section: try to match and update keys
            $keyMatch = $trimmedLine -match "^([^=]+)=(.*)"
            if ($keyMatch) {
                $key = $matches[1].Trim()
                if ($updatedProperties.ContainsKey($key)) {
                    # Update existing key, add to temp list
                    $targetSectionTempLines.Add("$key=$($updatedProperties[$key])")
                    $updatedProperties.Remove($key) # Mark as processed
                } else {
                    # Keep other keys in section, add to temp list
                    $targetSectionTempLines.Add($line)
                }
            } else {
                # Keep other lines (e.g., comments) in section, add to temp list
                $targetSectionTempLines.Add($line)
            }
        } else {
            # Outside target section, just copy line to newLines
            $newLines.Add($line)
        }
    }
    
    # Handle remaining lines in targetSectionTempLines if INI ends inside target section
    if ($inTargetSection) {
        foreach ($prop in $updatedProperties.GetEnumerator()) {
            if ($prop.Value -ne $null) {
                $targetSectionTempLines.Add("$($prop.Key)=$($prop.Value)")
            }
        }
        $newLines.AddRange($targetSectionTempLines)
    }

    # If the target section was not found at all, add it and its properties to the end
    if (-not $sectionFound) {
        if ($existingLines.Count -gt 0) { $newLines.Add("") } # Add empty line for separation if file existed
        $newLines.Add("[$Section]")
        foreach ($prop in $updatedProperties.GetEnumerator()) {
            if ($prop.Value -ne $null) {
                $newLines.Add("$($prop.Key)=$($prop.Value)")
            }
        }
    }

    # Write back the content, ensuring correct newlines
    Set-Content -Path $Path -Value ($newLines -join "`r`n") -Force -Encoding Default
}

# --- Function to Load Metadata ---
function Load-Metadata {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    $lblStatus = $global:lblStatus
    $lblItemType = $global:lblItemType

    # Clear all text boxes and set them to enabled state initially
    foreach ($propDef in $global:MetadataPropertyDefinitions) {
        $txtBox = $global:TextBoxes[$propDef.CanonicalName]
        if ($txtBox) {
            $txtBox.Text = ""
            $txtBox.Enabled = $true # Re-enable for fresh start
            $txtBox.ReadOnly = $false
        }
    }
    $lblStatus.Text = "Loading metadata..."

    if (-not (Test-Path $Path)) {
        $lblStatus.Text = "Error: Path '$Path' not found."
        $lblItemType.Text = "Type: (invalid path)"
        foreach ($propDef in $global:MetadataPropertyDefinitions) {
            $txtBox = $global:TextBoxes[$propDef.CanonicalName]
            if ($txtBox) { $txtBox.Enabled = $false }
        }
        return
    }

    $item = Get-Item $Path

    # Check if the selected item is a file or a folder
    if ($item.PSIsContainer) {
        # --- FOLDER METADATA LOGIC ---
        $lblItemType.Text = "Type: Folder"
        $desktopIniPath = Join-Path $Path "desktop.ini"
        
        foreach ($propDef in $global:MetadataPropertyDefinitions) {
            $txtBox = $global:TextBoxes[$propDef.CanonicalName]
            if ($txtBox) {
                if ($propDef.AppliesToFolder -and $propDef.FolderIniKey) {
                    # This property applies to folders and has a desktop.ini key
                    $txtBox.Text = (Read-IniFile -Path $desktopIniPath -Section ".ShellClassInfo" -Key $propDef.FolderIniKey) ?? ""
                    $txtBox.Enabled = -not $propDef.IsReadOnly
                    $txtBox.ReadOnly = $propDef.IsReadOnly
                } else {
                    # Disable fields not applicable to folders (or read-only file system properties)
                    $txtBox.Text = ""
                    $txtBox.Enabled = $false
                    $txtBox.ReadOnly = $true # Always read-only if disabled
                }
            }
        }

        if (Test-Path $desktopIniPath) {
            $lblStatus.Text = "Loaded metadata from desktop.ini."
        } else {
            $lblStatus.Text = "No desktop.ini found for this folder. Save to create one."
        }
    } else {
        # --- FILE METADATA LOGIC ---
        $lblItemType.Text = "Type: File"
        
        $shell = Get-Shell
        if (-not $shell) {
            $lblStatus.Text = "Shell.Application COM object unavailable. Cannot load file metadata."
            foreach ($propDef in $global:MetadataPropertyDefinitions) {
                $txtBox = $global:TextBoxes[$propDef.CanonicalName]
                if ($txtBox) { $txtBox.Enabled = $false }
            }
            return
        }

        $parentFolder = Split-Path -Path $Path -Parent
        $fileName = Split-Path -Path $Path -Leaf
        
        # Declare COM objects for finally block
        $shellFolder = $null
        $shellFile = $null

        try {
            $shellFolder = $shell.Namespace($parentFolder)
            if (-not $shellFolder) {
                $lblStatus.Text = "Error: Could not get shell namespace for '$parentFolder'."
                return
            }
            $shellFile = $shellFolder.ParseName($fileName)
            if (-not $shellFile) {
                $lblStatus.Text = "Error: Could not parse file name '$fileName' in shell folder."
                return
            }

            foreach ($propDef in $global:MetadataPropertyDefinitions) {
                $txtBox = $global:TextBoxes[$propDef.CanonicalName]
                if ($txtBox) {
                    if ($propDef.AppliesToFile) {
                        try {
                            $value = $shellFile.ExtendedProperty($propDef.CanonicalName)
                            if ($value -ne $null) {
                                if ($propDef.IsMultiValue -and $value -is [System.Array]) {
                                    $txtBox.Text = $value -join ($propDef.Delimiter ?? "; ")
                                } elseif ($value -is [System.DateTime]) {
                                    $txtBox.Text = $value.ToString("yyyy-MM-dd HH:mm:ss") # Format dates
                                } elseif ($value -is [System.Decimal] -or $value -is [System.Double] -or $value -is [System.Int32] -or $value -is [System.Int64]) {
                                    $txtBox.Text = $value.ToString()
                                } else {
                                    $txtBox.Text = $value.ToString() # Handle other types as strings
                                }
                            } else {
                                $txtBox.Text = ""
                            }
                            $txtBox.Enabled = -not $propDef.IsReadOnly
                            $txtBox.ReadOnly = $propDef.IsReadOnly
                        } catch {
                            # Silently ignore properties that don't exist for the file or cause an error on retrieval
                            $txtBox.Text = "N/A"
                            $txtBox.Enabled = $false
                            $txtBox.ReadOnly = $true
                        }
                    } else {
                        # Disable fields not applicable to files in this context
                        $txtBox.Text = ""
                        $txtBox.Enabled = $false
                        $txtBox.ReadOnly = $true # Always read-only if disabled
                    }
                }
            }
            $lblStatus.Text = "Successfully loaded file metadata."
        } catch {
            $lblStatus.Text = "Error loading file metadata: $($_.Exception.Message)"
            Write-Error "Error loading file metadata for '$Path': $($_.Exception.Message)"
        } finally {
            # Explicitly release COM objects to free memory and resources
            if ($shellFile) { [Marshal]::ReleaseComObject($shellFile) | Out-Null }
            if ($shellFolder) { [Marshal]::ReleaseComObject($shellFolder) | Out-Null }
            if ($shell) { [Marshal]::ReleaseComObject($shell) | Out-Null }
        }
    }
}

# --- UI Controls Definition ---

# Label and TextBox for the selected path
$lblPath = [Label]::new()
$lblPath.Text = "Selected Item:"
$lblPath.Location = [Point]::new(10, 15)
$lblPath.AutoSize = $true
$mainForm.Controls.Add($lblPath)

$txtPath = [TextBox]::new()
$txtPath.Location = [Point]::new(10, 35)
$txtPath.Size = [Size]::new(370, 20)
$txtPath.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Left -bor [AnchorStyles]::Right
$mainForm.Controls.Add($txtPath)
$global:txtPath = $txtPath # Store global reference for easy access in event handlers

$btnBrowseFile = [Button]::new()
$btnBrowseFile.Text = "Browse File..."
$btnBrowseFile.Location = [Point]::new(390, 34)
$btnBrowseFile.Size = [Size]::new(85, 23)
$btnBrowseFile.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Right
$mainForm.Controls.Add($btnBrowseFile)

$btnBrowseFolder = [Button]::new()
$btnBrowseFolder.Text = "Browse Folder..."
$btnBrowseFolder.Location = [Point]::new(480, 34)
$btnBrowseFolder.Size = [Size]::new(85, 23)
$btnBrowseFolder.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Right
$mainForm.Controls.Add($btnBrowseFolder)

# Label to show if it's a file or folder
$lblItemType = [Label]::new()
$lblItemType.Text = "Type: (none selected)"
$lblItemType.Location = [Point]::new(10, 65)
$lblItemType.AutoSize = $true
$mainForm.Controls.Add($lblItemType)
$global:lblItemType = $lblItemType # Store global reference

# Panel to hold dynamically created metadata fields
$dynamicFieldsPanel = [Panel]::new()
$dynamicFieldsPanel.Location = [Point]::new(10, 95)
$dynamicFieldsPanel.Size = [Size]::new($mainForm.ClientSize.Width - 30, $mainForm.ClientSize.Height - 190) # Adjusted size
$dynamicFieldsPanel.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Bottom -bor [AnchorStyles]::Left -bor [AnchorStyles]::Right
$dynamicFieldsPanel.AutoScroll = $true
$mainForm.Controls.Add($dynamicFieldsPanel)
$global:dynamicFieldsPanel = $dynamicFieldsPanel # Store global reference

# Dynamically create Labels and TextBoxes for each metadata field inside the panel
$currentY = 0 # Starting Y position within the panel

foreach ($field in $global:MetadataPropertyDefinitions) {
    $label = [Label]::new()
    $label.Text = "$($field.DisplayName):"
    $label.Location = [Point]::new(5, $currentY + 5) # Indent slightly within panel
    $label.AutoSize = $true
    $dynamicFieldsPanel.Controls.Add($label)

    $textBox = [TextBox]::new()
    # Use canonical name for the textbox name, sanitizing it for .NET control naming rules
    $textBox.Name = "txt_" + ($field.CanonicalName -replace '\.', '_') # e.g., txt_System_Title
    $textBox.Location = [Point]::new(5, $currentY + 25) # 20px below label
    $textBox.Size = [Size]::new($dynamicFieldsPanel.ClientSize.Width - 20, 20) # Match panel width, accounting for scrollbar if present
    $textBox.Anchor = [AnchorStyles]::Left -bor [AnchorStyles]::Right # Anchor to panel's width
    $dynamicFieldsPanel.Controls.Add($textBox)

    # Store the textbox object in the global hashtable for easy access later
    $global:TextBoxes[$field.CanonicalName] = $textBox

    $currentY += 55 # Increment Y for the next field (label + textbox + some spacing)
}

# Save Button
$btnSave = [Button]::new()
$btnSave.Text = "Save Metadata"
$btnSave.Location = [Point]::new($mainForm.ClientSize.Width - 110, $mainForm.ClientSize.Height - 40)
$btnSave.Size = [Size]::new(100, 30)
$btnSave.Anchor = [AnchorStyles]::Bottom -bor [AnchorStyles]::Right
$mainForm.Controls.Add($btnSave)

# Status Label
$lblStatus = [Label]::new()
$lblStatus.Text = ""
$lblStatus.Location = [Point]::new(10, $mainForm.ClientSize.Height - 32)
$lblStatus.AutoSize = $true
$lblStatus.Anchor = [AnchorStyles]::Bottom -bor [AnchorStyles]::Left
$mainForm.Controls.Add($lblStatus)
$global:lblStatus = $lblStatus # Store global reference

# --- Event Handlers ---

# Event handler for the Browse File button
$btnBrowseFile.Add_Click({
    $openFileDialog = [OpenFileDialog]::new()
    $openFileDialog.Title = "Select a file"
    $openFileDialog.Filter = "All Files (*.*)|*.*"
    $openFileDialog.Multiselect = $false
    
    if ($openFileDialog.ShowDialog() -eq [DialogResult]::OK) {
        $global:txtPath.Text = $openFileDialog.FileName
        Load-Metadata -Path $global:txtPath.Text
    }
    $openFileDialog.Dispose() # Release resources
})

# Event handler for the Browse Folder button
$btnBrowseFolder.Add_Click({
    $folderBrowser = [FolderBrowserDialog]::new()
    $folderBrowser.Description = "Select a folder"
    
    if ($folderBrowser.ShowDialog() -eq [DialogResult]::OK) {
        $global:txtPath.Text = $folderBrowser.SelectedPath
        Load-Metadata -Path $global:txtPath.Text
    }
    $folderBrowser.Dispose() # Release resources
})

# Event handler for the Path text box (if user pastes a path or manually types and leaves the field)
$txtPath.Add_Leave({
    if ($global:txtPath.Text) {
        Load-Metadata -Path $global:txtPath.Text
    }
})

# Event handler for the Save button
$btnSave.Add_Click({
    $path = $global:txtPath.Text
    $lblStatus = $global:lblStatus # Local alias for status label

    if (-not (Test-Path $path)) {
        $lblStatus.Text = "Error: Path not found. Cannot save."
        return
    }

    $item = Get-Item $path
    if ($item.PSIsContainer) {
        # --- SAVE FOLDER METADATA ---
        try {
            # Ensure the folder is marked as a system folder for desktop.ini to be active
            # Use bitwise OR to preserve existing attributes
            $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::System
            
            $desktopIniPath = Join-Path $path "desktop.ini"
            $propertiesToSave = [hashtable]::new([System.StringComparer]::InvariantCultureIgnoreCase)

            foreach ($propDef in $global:MetadataPropertyDefinitions) {
                if ($propDef.AppliesToFolder -and $propDef.FolderIniKey -ne "") {
                    $txtBox = $global:TextBoxes[$propDef.CanonicalName]
                    if ($txtBox) {
                        $propertiesToSave[$propDef.FolderIniKey] = $txtBox.Text
                    }
                }
            }

            Update-IniFile -Path $desktopIniPath -Section ".ShellClassInfo" -Properties $propertiesToSave

            # Set the desktop.ini file to be hidden, system, and archive (common for ini files)
            # Use bitwise OR to combine attributes
            (Get-Item $desktopIniPath).Attributes = [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System -bor [System.IO.FileAttributes]::Archive

            $lblStatus.Text = "Folder metadata saved to desktop.ini successfully."
        } catch {
            $lblStatus.Text = "Error saving folder metadata: $($_.Exception.Message)"
            Write-Error "Error saving folder metadata for '$path': $($_.Exception.Message)"
        }
    } else {
        # --- SAVE FILE METADATA ---
        # Declare COM objects for finally block to ensure disposal
        $shell = $null
        $shellFolder = $null
        $shellFile = $null
        try {
            $shell = Get-Shell
            if (-not $shell) {
                $lblStatus.Text = "Shell.Application COM object unavailable. Cannot save file metadata."
                return
            }

            $parentFolder = Split-Path -Path $path -Parent
            $fileName = Split-Path -Path $path -Leaf
            $shellFolder = $shell.Namespace($parentFolder)
            
            if (-not $shellFolder) {
                $lblStatus.Text = "Error: Could not get shell namespace for parent folder '($parentFolder)' via COM."
                return
            }

            $shellFile = $shellFolder.ParseName($fileName)
            if (-not $shellFile) {
                $lblStatus.Text = "Error: Could not parse file name '($fileName)' within shell folder via COM."
                return
            }

            foreach ($propDef in $global:MetadataPropertyDefinitions) {
                if ($propDef.AppliesToFile -and -not $propDef.IsReadOnly) {
                    $txtBox = $global:TextBoxes[$propDef.CanonicalName]
                    if ($txtBox) {
                        $value = $txtBox.Text
                        if ($propDef.IsMultiValue) {
                            $value = ($value -split ($propDef.Delimiter ?? "; ")) | Where-Object { $_ -ne "" } # Split and remove empty entries
                        }
                        # Setting the property might fail for some file types or values, wrap in try/catch
                        try {
                            $shellFile.ExtendedProperty($propDef.CanonicalName) = $value
                        } catch {
                            Write-Warning "Could not set property '$($propDef.DisplayName)' for '$fileName'. Error: $($_.Exception.Message)"
                        }
                    }
                }
            }
            $lblStatus.Text = "File metadata saved successfully."
        } catch {
            $lblStatus.Text = "Error saving file metadata: $($_.Exception.Message)"
            Write-Error "Error saving file metadata for '$path': $($_.Exception.Message)"
        } finally {
            # Explicitly release COM objects to prevent resource leaks
            if ($shellFile) { [Marshal]::ReleaseComObject($shellFile) | Out-Null }
            if ($shellFolder) { [Marshal]::ReleaseComObject($shellFolder) | Out-Null }
            if ($shell) { [Marshal]::ReleaseComObject($shell) | Out-Null }
        }
    }
})

# --- Show the Form ---
# The .ShowDialog() method opens the form and waits until it's closed.
$mainForm.Add_Shown({
    $mainForm.Activate()
    # Set initial status message when the form is shown
    $global:lblStatus.Text = "Select a file or folder to begin."
})
[void]$mainForm.ShowDialog()

# --- Cleanup ---
# Dispose of the form object after it's closed to free up memory.
$mainForm.Dispose()