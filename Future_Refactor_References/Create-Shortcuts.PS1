<#
.SYNOPSIS
    A PowerShell script with a GUI to find installed applications and create shortcuts.

.DESCRIPTION
    This script launches a WPF (Windows Presentation Foundation) window that allows a user to:
    1. Scan the Windows Registry for officially installed applications.
    2. Scan common program folders across ALL connected drives to find portable or non-registered apps.
    3. Manually scan any specific drive or folder for executable (.exe) files.
    4. View a list of common system applications.
    5. Create a desktop shortcut (.lnk file) for any found application.

.NOTES
    Author: Gemini
    Version: 2.1
    Created for: Zach
    - v2.1: Added "Deep Scan" to search Program Files on all drives. Enhanced UI styles.
    - v2.0: Added manual folder/drive scanning, stability improvements, and a progress bar.
#>

# --- PRE-LOAD ASSEMBLIES ---
# Explicitly load required assemblies to prevent the script from closing prematurely.
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# --- GUI DEFINITION (XAML) ---
# Define the layout and controls of the application window using XAML.
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Application Shortcut Creator v2.1" Height="700" Width="850"
        WindowStartupLocation="CenterScreen"
        Background="#FFDADADA">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="5">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Opacity" Value="0.9"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Opacity" Value="0.5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Top Section: Scan Controls -->
        <StackPanel Grid.Row="0" Margin="0,0,0,10">
            <TextBlock Text="1. Scan for Applications" FontWeight="Bold" FontSize="16" Margin="0,0,0,10"/>
            <WrapPanel>
                <Button x:Name="ScanRegistryButton" Content="Scan Registry" Background="#FF4CAF50" Margin="0,0,10,0"/>
                <Button x:Name="ScanAllDrivesButton" Content="Deep Scan All Drives" Background="#FFC95100" ToolTip="Scans 'Program Files' on all drives. May take some time."/>
            </WrapPanel>
        </StackPanel>

        <!-- Middle Section: Application Lists -->
        <TabControl x:Name="TabControl" Grid.Row="1" Margin="0,5,0,0">
            <TabItem Header="User Installed Apps">
                <DataGrid x:Name="UserAppsGrid" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single" Background="White">
                    <DataGrid.Columns>
                        <DataGridTextColumn Header="Program Name" Binding="{Binding Name}" Width="*"/>
                        <DataGridTextColumn Header="Executable Path" Binding="{Binding Path}" Width="2*"/>
                    </DataGrid.Columns>
                </DataGrid>
            </TabItem>
            <TabItem Header="All Drive Apps">
                <DataGrid x:Name="AllDrivesGrid" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single" Background="White">
                    <DataGrid.Columns>
                        <DataGridTextColumn Header="Program Name" Binding="{Binding Name}" Width="*"/>
                        <DataGridTextColumn Header="Executable Path" Binding="{Binding Path}" Width="2*"/>
                    </DataGrid.Columns>
                </DataGrid>
            </TabItem>
            <TabItem Header="System Apps">
                <DataGrid x:Name="SystemAppsGrid" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single" Background="White">
                    <DataGrid.Columns>
                        <DataGridTextColumn Header="Program Name" Binding="{Binding Name}" Width="*"/>
                        <DataGridTextColumn Header="Executable Path" Binding="{Binding Path}" Width="2*"/>
                    </DataGrid.Columns>
                </DataGrid>
            </TabItem>
            <TabItem Header="Manual Scan">
                <Grid Margin="5">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <StackPanel Grid.Row="0">
                        <TextBlock Text="Scan a specific drive or folder for all .exe files." TextWrapping="Wrap" Margin="0,5,0,10"/>
                        <Button x:Name="ScanFolderButton" Content="Choose Folder to Scan..." HorizontalAlignment="Left" Background="#FF007ACC"/>
                    </StackPanel>
                    <DataGrid x:Name="ManualScanGrid" Grid.Row="1" Margin="0,10,0,0" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single" Background="White">
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="File Name" Binding="{Binding Name}" Width="*"/>
                            <DataGridTextColumn Header="Full Path" Binding="{Binding Path}" Width="2*"/>
                        </DataGrid.Columns>
                    </DataGrid>
                </Grid>
            </TabItem>
        </TabControl>

        <!-- Bottom Section: Shortcut Creation -->
        <StackPanel Grid.Row="2" Margin="0,15,0,0">
            <TextBlock Text="2. Create Shortcut" FontWeight="Bold" FontSize="16" Margin="0,0,0,5"/>
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBox x:Name="ShortcutPathTextBox" Grid.Column="0" VerticalContentAlignment="Center" Margin="0,0,10,0" IsReadOnly="True" Background="#FFF0F0F0" Padding="5"/>
                <Button x:Name="BrowseButton" Grid.Column="1" Content="Browse..." Background="#FF555555"/>
            </Grid>
            <Button x:Name="CreateShortcutButton" Content="Create Shortcut" Margin="0,10,0,0" Width="150" HorizontalAlignment="Left" IsEnabled="False" Background="#FF2196F3"/>
        </StackPanel>

        <!-- Status Bar -->
        <StatusBar Grid.Row="3" Margin="0,10,0,0">
            <StatusBarItem>
                <TextBlock x:Name="StatusTextBlock" Text="Status: Ready"/>
            </StatusBarItem>
            <StatusBarItem HorizontalAlignment="Right">
                <ProgressBar x:Name="ProgressBar" Width="150" Height="15" IsIndeterminate="True" Visibility="Collapsed"/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

# --- SCRIPT LOGIC ---
$ErrorActionPreference = 'SilentlyContinue'

$reader = New-Object System.Xml.XmlNodeReader $xaml
try {
    $window = [Windows.Markup.XamlReader]::Load($reader)
}
catch {
    [System.Windows.MessageBox]::Show("Failed to load the application window (XAML).`n`nError: $($_.Exception.Message)", "Fatal Error", "OK", "Error")
    exit
}

# Find and assign controls from the XAML to PowerShell variables
$ScanRegistryButton = $window.FindName("ScanRegistryButton")
$ScanAllDrivesButton = $window.FindName("ScanAllDrivesButton")
$ScanFolderButton = $window.FindName("ScanFolderButton")
$UserAppsGrid = $window.FindName("UserAppsGrid")
$SystemAppsGrid = $window.FindName("SystemAppsGrid")
$AllDrivesGrid = $window.FindName("AllDrivesGrid")
$ManualScanGrid = $window.FindName("ManualScanGrid")
$TabControl = $window.FindName("TabControl")
$ShortcutPathTextBox = $window.FindName("ShortcutPathTextBox")
$BrowseButton = $window.FindName("BrowseButton")
$CreateShortcutButton = $window.FindName("CreateShortcutButton")
$StatusTextBlock = $window.FindName("StatusTextBlock")
$ProgressBar = $window.FindName("ProgressBar")

# --- HELPER FUNCTIONS ---
Function Set-BusyState($IsBusy, $StatusMessage) {
    $window.Cursor = if ($IsBusy) { 'Wait' } else { 'Arrow' }
    $StatusTextBlock.Text = "Status: $StatusMessage"
    $ProgressBar.Visibility = if ($IsBusy) { 'Visible' } else { 'Collapsed' }
    # Disable buttons while busy
    $ScanRegistryButton.IsEnabled = !$IsBusy
    $ScanAllDrivesButton.IsEnabled = !$IsBusy
    $ScanFolderButton.IsEnabled = !$IsBusy
    $CreateShortcutButton.IsEnabled = !$IsBusy

    $window.UpdateLayout() # Force UI to refresh immediately
}

# --- CORE FUNCTIONS ---

Function Get-InstalledApps {
    $uninstallKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    $installedApps = foreach ($key in $uninstallKeys) {
        if (Test-Path $key) {
            Get-ItemProperty -Path "$key\*" | Where-Object { $_.DisplayName -and ($_.InstallLocation -or $_.DisplayIcon) -and -not $_.SystemComponent } | ForEach-Object {
                # Logic to determine the best possible path for the executable
                $appName = $_.DisplayName
                $appPath = ""
                if ($_.DisplayIcon) {
                    $appPath = ($_.DisplayIcon -split ",*")[0].Trim('"')
                }
                if ((-not ($appPath -match '\.exe$')) -and $_.InstallLocation) {
                    $potentialExeName = if ($_.PSChildName) { "$($_.PSChildName).exe" } else { "$($_.DisplayName).exe" }
                    $appPath = Join-Path -Path $_.InstallLocation -ChildPath $potentialExeName
                }
                if (($appPath -match '\.exe$') -and (Test-Path $appPath -PathType Leaf)) {
                    [PSCustomObject]@{ Name = $appName; Path = $appPath }
                }
            }
        }
    }
    return $installedApps | Sort-Object -Property Name -Unique
}

Function Get-AppsFromAllDrives {
    $allApps = [System.Collections.Generic.List[object]]::new()
    $drives = Get-PSDrive -PSProvider FileSystem
    $searchFolders = "Program Files", "Program Files (x86)"

    foreach ($drive in $drives) {
        foreach ($folder in $searchFolders) {
            $scanPath = Join-Path -Path $drive.Root -ChildPath $folder
            if (Test-Path $scanPath) {
                Set-BusyState -IsBusy $true -StatusMessage "Scanning: $scanPath..."
                $apps = Get-ChildItem -Path $scanPath -Filter *.exe -Recurse -ErrorAction SilentlyContinue | Select-Object @{Name = "Name"; Expression = { $_.Directory.Name } }, @{Name = "Path"; Expression = { $_.FullName } }
                $allApps.AddRange($apps)
            }
        }
    }
    return $allApps | Sort-Object -Property Name -Unique
}

Function Get-SystemApps {
    $systemPath = [Environment]::GetFolderPath('System')
    $systemApps = @(
        @{ Name = "Calculator"; Path = Join-Path $systemPath "calc.exe" },
        @{ Name = "Notepad"; Path = Join-Path $systemPath "notepad.exe" },
        @{ Name = "Command Prompt"; Path = Join-Path $systemPath "cmd.exe" },
        @{ Name = "PowerShell"; Path = Join-Path $systemPath "WindowsPowerShell\v1.0\powershell.exe" },
        @{ Name = "Task Manager"; Path = Join-Path $systemPath "taskmgr.exe" },
        @{ Name = "Registry Editor"; Path = Join-Path $systemPath "regedit.exe" },
        @{ Name = "File Explorer"; Path = "C:\Windows\explorer.exe" },
        @{ Name = "Services"; Path = Join-Path $systemPath "services.msc" },
        @{ Name = "Paint"; Path = Join-Path $systemPath "mspaint.exe" }
    )
    return $systemApps | Where-Object { Test-Path $_.Path } | Sort-Object -Property Name
}

Function Get-ExecutablesInFolder($FolderPath) {
    Get-ChildItem -Path $FolderPath -Filter *.exe -Recurse -ErrorAction SilentlyContinue | Select-Object @{Name = "Name"; Expression = { $_.Name } }, @{Name = "Path"; Expression = { $_.FullName } }
}

Function New-Shortcut($ShortcutPath, $TargetPath, $Description) {
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($ShortcutPath)
        $shortcut.TargetPath = $TargetPath
        $shortcut.Description = $Description
        $shortcut.Save()
        [System.Windows.MessageBox]::Show("Shortcut for '$($Description -replace 'Shortcut to ','')' created successfully!", "Success", "OK", "Information")
        Set-BusyState -IsBusy $false -StatusMessage "Shortcut created successfully."
    }
    catch {
        [System.Windows.MessageBox]::Show("Failed to create shortcut. Error: `n$($_.Exception.Message)", "Error", "OK", "Error")
        Set-BusyState -IsBusy $false -StatusMessage "Error creating shortcut."
    }
}

# --- EVENT HANDLERS ---

$ScanRegistryButton.Add_Click({
    Set-BusyState -IsBusy $true -StatusMessage "Scanning registry for applications..."
    $UserAppsGrid.ItemsSource = Get-InstalledApps
    $SystemAppsGrid.ItemsSource = Get-SystemApps
    Set-BusyState -IsBusy $false -StatusMessage "Registry scan complete. Found $($UserAppsGrid.Items.Count) user apps."
    $CreateShortcutButton.IsEnabled = $true
})

$ScanAllDrivesButton.Add_Click({
    Set-BusyState -IsBusy $true -StatusMessage "Starting deep scan on all drives..."
    $AllDrivesGrid.ItemsSource = Get-AppsFromAllDrives
    Set-BusyState -IsBusy $false -StatusMessage "Deep scan complete. Found $($AllDrivesGrid.Items.Count) potential apps."
    $CreateShortcutButton.IsEnabled = $true
})

$ScanFolderButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select a drive or folder to scan for .exe files"
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $selectedFolder = $folderBrowser.SelectedPath
        Set-BusyState -IsBusy $true -StatusMessage "Scanning folder: $selectedFolder..."
        $ManualScanGrid.ItemsSource = Get-ExecutablesInFolder -FolderPath $selectedFolder
        Set-BusyState -IsBusy $false -StatusMessage "Folder scan complete. Found $($ManualScanGrid.Items.Count) executables."
        $CreateShortcutButton.IsEnabled = $true
    }
})

$BrowseButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select a folder to save the shortcut"
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $ShortcutPathTextBox.Text = $folderBrowser.SelectedPath
    }
})

$CreateShortcutButton.Add_Click({
    $selectedApp = $null
    
    switch ($TabControl.SelectedItem.Header) {
        "User Installed Apps" { $selectedApp = $UserAppsGrid.SelectedItem }
        "System Apps"         { $selectedApp = $SystemAppsGrid.SelectedItem }
        "Manual Scan"         { $selectedApp = $ManualScanGrid.SelectedItem }
        "All Drive Apps"      { $selectedApp = $AllDrivesGrid.SelectedItem }
    }

    if (-not $selectedApp) {
        [System.Windows.MessageBox]::Show("Please select an application from one of the lists first.", "Selection Required", "OK", "Warning")
        return
    }

    $destinationFolder = $ShortcutPathTextBox.Text
    if ([string]::IsNullOrWhiteSpace($destinationFolder)) {
        [System.Windows.MessageBox]::Show("Please select a destination folder first.", "Folder Required", "OK", "Warning")
        return
    }
    
    $appName = $selectedApp.Name
    $appPath = $selectedApp.Path
    
    if (-not (Test-Path $appPath -PathType Leaf)) {
         [System.Windows.MessageBox]::Show("The target executable for '$appName' could not be found at:`n$appPath`n`nCannot create shortcut.", "File Not Found", "OK", "Error")
        return
    }

    $safeAppName = ($appName -replace '\.exe$', '') -replace '[\\/:*?"<>|]'
    $shortcutFile = Join-Path -Path $destinationFolder -ChildPath "$safeAppName.lnk"
    $description = "Shortcut to $appName"

    New-Shortcut -ShortcutPath $shortcutFile -TargetPath $appPath -Description $description
})


# --- START THE GUI ---
$window.ShowDialog() | Out-Null
