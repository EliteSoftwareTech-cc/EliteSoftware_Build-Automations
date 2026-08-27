<#
.SYNOPSIS
    Dev-Deploy Environment Manager v0.4
    Created by: Zachary Whiteman & Google Gemini
    Date: 7/14/2025 - 1:06 PM

.DESCRIPTION
    A comprehensive utility for discovering, installing, and managing Python and .NET environments.
    This tool provides a graphical user interface to simplify development environment setup.
    v0.4 Update:
    - Implemented a more robust P/Invoke method to guarantee system UI theming.
    - Reworked winget searches to run in the background for a responsive UI.
    - Replaced brittle text parsing with a reliable RegEx-based parser for winget results.
    - Implemented the pip package installer functionality.
#>

# --- Initial Setup: Minimize Console Window ---
try {
    $psWindow = (Get-Process -Id $PID).MainWindowHandle
    if ($psWindow) {
        Add-Type -Name Window -Namespace Console -MemberDefinition '
            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        '
        [Console.Window]::ShowWindow($psWindow, 6) # 6 corresponds to SW_MINIMIZE
    }
}
catch { Write-Warning "Could not minimize the console window." }

# --- Add Required .NET Assemblies ---
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- Enable Visual Styles (Theming) - Robust Method ---
# This C# code uses P/Invoke to directly initialize Common Controls v6, which provides
# the modern visual styles. This is the most reliable method for PowerShell scripts.
$cSharpCode = @"
using System;
using System.Runtime.InteropServices;

public class VisualStylesInitializer {
    [StructLayout(LayoutKind.Sequential)]
    public struct INITCOMMONCONTROLSEX {
        public int dwSize;
        public int dwICC;
    }

    [DllImport("comctl32.dll")]
    public static extern bool InitCommonControlsEx(ref INITCOMMONCONTROLSEX iccex);

    public static void Enable() {
        INITCOMMONCONTROLSEX iccex = new INITCOMMONCONTROLSEX();
        iccex.dwSize = Marshal.SizeOf(typeof(INITCOMMONCONTROLSEX));
        iccex.dwICC = 0x40FF; // Init all common controls
        InitCommonControlsEx(ref iccex);
    }
}
"@
Add-Type -TypeDefinition $cSharpCode
[VisualStylesInitializer]::Enable()

#================================================================================================
#  XAML DEFINITION FOR THE GUI
#================================================================================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Dev-Deploy Environment Manager v0.4" Height="600" Width="800"
        WindowStartupLocation="CenterScreen" MinHeight="500" MinWidth="700">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>

        <TabControl x:Name="MainTabControl" Grid.Row="0">
            <!-- Python Environment Tab -->
            <TabItem Header="Python Environment">
                <Grid Margin="5">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <StackPanel Orientation="Horizontal" Margin="0,5,0,10">
                        <Button x:Name="RefreshPython" Content="Refresh All" Width="120" Margin="0,0,10,0"/>
                        <Label Content="Status:" VerticalAlignment="Center"/>
                        <TextBlock x:Name="PythonStatus" Text="Ready." VerticalAlignment="Center" FontWeight="Bold"/>
                    </StackPanel>
                    <Grid Grid.Row="1">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="5"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <GroupBox Header="Installed Python Versions" Grid.Column="0">
                            <ListBox x:Name="InstalledPythonList" />
                        </GroupBox>
                        <GridSplitter Grid.Column="1" Width="5" HorizontalAlignment="Stretch" />
                        <GroupBox Header="Available via Winget" Grid.Column="2">
                            <ListBox x:Name="AvailablePythonList" />
                        </GroupBox>
                    </Grid>
                    <StackPanel Grid.Row="2" Orientation="Vertical" Margin="0,10,0,0">
                         <GroupBox Header="Manage Packages (pip) for Selected Installation">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <TextBox x:Name="PipPackageName" Grid.Column="0" Margin="5" VerticalContentAlignment="Center"/>
                                <Button x:Name="InstallPipPackage" Content="Install Package" Grid.Column="1" Margin="5" Padding="10,5" IsEnabled="False"/>
                            </Grid>
                        </GroupBox>
                        <Button x:Name="InstallPython" Content="Install Selected Python Version" Margin="0,10,0,0" Padding="5" IsEnabled="False"/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <!-- .NET Environment Tab -->
            <TabItem Header=".NET Environment">
                 <Grid Margin="5">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <StackPanel Orientation="Horizontal" Margin="0,5,0,10">
                        <Button x:Name="RefreshDotNet" Content="Refresh All" Width="120" Margin="0,0,10,0"/>
                        <Label Content="Status:" VerticalAlignment="Center"/>
                        <TextBlock x:Name="DotNetStatus" Text="Ready." VerticalAlignment="Center" FontWeight="Bold"/>
                    </StackPanel>
                    <Grid Grid.Row="1">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="5"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <GroupBox Header="Installed .NET SDKs &amp; Runtimes" Grid.Column="0">
                            <ListBox x:Name="InstalledDotNetList" />
                        </GroupBox>
                        <GridSplitter Grid.Column="1" Width="5" HorizontalAlignment="Stretch" />
                        <GroupBox Header="Available via Winget" Grid.Column="2">
                             <ListBox x:Name="AvailableDotNetList" />
                        </GroupBox>
                    </Grid>
                    <Button Grid.Row="2" x:Name="InstallDotNet" Content="Install Selected .NET Version" Margin="0,10,0,0" Padding="5" IsEnabled="False"/>
                </Grid>
            </TabItem>
            
            <!-- Activity Log Tab -->
            <TabItem Header="Activity Log">
                <Grid Margin="5">
                    <TextBox x:Name="LogOutput" IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" FontFamily="Consolas"/>
                </Grid>
            </TabItem>
        </TabControl>

        <StatusBar Grid.Row="1">
            <StatusBarItem>
                <TextBlock x:Name="MainStatusBar" Text="Welcome to Dev-Deploy!"/>
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

#================================================================================================
#  GUI SETUP AND VARIABLE INITIALIZATION
#================================================================================================
$window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))

$xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {
    Set-Variable -Name $_.Name -Value $window.FindName($_.Name)
}

# Store the path to the selected python installation for use with pip
$SelectedPythonPath = $null

#================================================================================================
#  CORE LOGIC AND FUNCTIONS
#================================================================================================

# --- Logging Function ---
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    $LogOutput.Dispatcher.InvokeAsync({
        $LogOutput.AppendText("$logEntry`n"); $LogOutput.ScrollToEnd()
    }) | Out-Null
}

# --- Generic Background Job Installer (Winget & Pip) ---
function Start-InstallerJob {
    param(
        [Parameter(Mandatory=$true)] [scriptblock]$InstallerScriptBlock,
        [Parameter(Mandatory=$true)] [string]$SoftwareName
    )
    
    Write-Log "Starting background installation for $SoftwareName..."
    $MainStatusBar.Dispatcher.InvokeAsync({ $MainStatusBar.Text = "Installing $SoftwareName..." }) | Out-Null
    
    $job = Start-Job -ScriptBlock $InstallerScriptBlock
    Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        if ($job.State -eq 'Completed') {
            $result = Receive-Job $job
            
            $window.Dispatcher.InvokeAsync({
                Write-Log "--- Installer Log for $SoftwareName ---"
                $result.Log | ForEach-Object { Write-Log $_ }
                Write-Log "--- End Log ---"

                if ($result.Success) {
                    Write-Log "Successfully installed $SoftwareName."
                    $MainStatusBar.Text = "Installation of $SoftwareName complete."
                } else {
                    Write-Log "Installation of $SoftwareName failed. Check logs for details." "ERROR"
                    $MainStatusBar.Text = "Installation of $SoftwareName failed."
                }
                # Automatically refresh the lists of installed software
                Find-InstalledPython
                Find-InstalledDotNet
            }) | Out-Null
            
            Remove-Job $job
            Unregister-Event -SourceIdentifier $job.id
        }
    } | Out-Null
}

# --- Functions to Find Available Software (Now fully asynchronous) ---
function Find-AvailableSoftware {
    param(
        [Parameter(Mandatory=$true)] [string]$SearchTerm,
        [Parameter(Mandatory=$true)] [System.Windows.Controls.ListBox]$TargetListBox,
        [Parameter(Mandatory=$true)] [System.Windows.Controls.TextBlock]$StatusTextBlock
    )
    
    $StatusTextBlock.Dispatcher.InvokeAsync({ $StatusTextBlock.Text = "Searching winget..." }) | Out-Null
    $TargetListBox.Dispatcher.InvokeAsync({ $TargetListBox.Items.Clear() }) | Out-Null
    
    $scriptBlock = {
        param($term)
        $log = @()
        $items = [System.Collections.Generic.List[PSCustomObject]]::new()
        try {
            $log += "Executing: winget search $term"
            $results = winget search $term --accept-source-agreements
            
            # Robust parsing using RegEx to split by 2 or more spaces
            $results | Select-Object -Skip 2 | ForEach-Object {
                $columns = $_ -split '\s{2,}' | Where-Object { $_ }
                if ($columns.Count -ge 3) {
                    $name = $columns[0].Trim()
                    $id = $columns[1].Trim()
                    $version = $columns[2].Trim()
                    
                    if ($id -like "$term*") {
                        $items.Add([PSCustomObject]@{
                            DisplayName = "$name $version"
                            WingetId    = $id
                        })
                    }
                }
            }
            $log += "Found $($items.Count) items."
            return [PSCustomObject]@{ Success = $true; Items = $items; Log = $log }
        } catch {
            $log += "ERROR: Failed to execute winget search. Is winget installed and in your PATH? Error: $($_.Exception.Message)"
            return [PSCustomObject]@{ Success = $false; Items = $null; Log = $log }
        }
    }
    
    $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $SearchTerm
    Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        if ($job.State -eq 'Completed') {
            $result = Receive-Job $job
            $window.Dispatcher.InvokeAsync({
                $result.Log | ForEach-Object { Write-Log $_ }
                if ($result.Success) {
                    $result.Items | ForEach-Object { $TargetListBox.Items.Add($_) }
                    $StatusTextBlock.Text = "Found $($TargetListBox.Items.Count) versions."
                } else {
                    $StatusTextBlock.Text = "Winget search failed."
                }
            }) | Out-Null
            Remove-Job $job
            Unregister-Event -SourceIdentifier $job.id
        }
    } | Out-Null
}

# --- Functions to Find Installed Software ---
function Find-InstalledPython {
    Write-Log "Scanning for existing Python installations..."
    $InstalledPythonList.Dispatcher.InvokeAsync({ $InstalledPythonList.Items.Clear() }) | Out-Null
    
    # Use a background job to avoid freezing the UI during the file scan
    $job = Start-Job -ScriptBlock {
        $found = [System.Collections.Generic.List[object]]::new()
        $drives = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | Select-Object -ExpandProperty DeviceID
        $searchFolders = @("Python*", "Program Files\Python*", "Program Files (x86)\Python*")
        $userFolders = @(Join-Path $env:LOCALAPPDATA "Programs\Python", Join-Path $env:APPDATA "Python")

        foreach ($drive in $drives) {
            foreach($folder in $searchFolders) {
                Get-ChildItem -Path (Join-Path $drive $folder) -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                    if (Test-Path (Join-Path $_.FullName "python.exe")) { $found.Add($_.FullName) }
                }
            }
        }
        $userFolders | ForEach-Object { Get-ChildItem -Path $_ -Directory -ErrorAction SilentlyContinue | ForEach-Object { if (Test-Path (Join-Path $_.FullName "python.exe")) { $found.Add($_.FullName) } } }
        ($env:Path -split ';') | ForEach-Object { if ($_ -like "*Python*" -and (Test-Path (Join-Path $_ "python.exe"))) { $found.Add($_) } }

        $uniquePaths = $found | Select-Object -Unique
        $results = @()
        foreach ($path in $uniquePaths) {
            try {
                $version = (Get-Command (Join-Path $path "python.exe")).Version
                $results += [PSCustomObject]@{ DisplayName = "Python $($version.Major).$($version.Minor).$($version.Build)"; Path = $path }
            } catch {}
        }
        return $results
    }
    
    Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        if ($job.State -eq 'Completed') {
            $results = Receive-Job $job
            $window.Dispatcher.InvokeAsync({
                if ($results.Count -eq 0) {
                    Write-Log "No Python installations found."
                    $PythonStatus.Text = "No local Python found."
                } else {
                    $results | ForEach-Object { $InstalledPythonList.Items.Add($_) }
                    Write-Log "Found $($results.Count) Python installation(s)."
                }
            }) | Out-Null
            Remove-Job $job
        }
    } | Out-Null
}

function Find-InstalledDotNet {
    Write-Log "Scanning for .NET SDKs and Runtimes..."
    $InstalledDotNetList.Dispatcher.InvokeAsync({ $InstalledDotNetList.Items.Clear() }) | Out-Null
    try {
        $sdks = dotnet --list-sdks
        $runtimes = dotnet --list-runtimes
        if ($sdks) { $sdks | ForEach-Object { $InstalledDotNetList.Items.Add("SDK: $_") } }
        if ($runtimes) { $runtimes | ForEach-Object { $InstalledDotNetList.Items.Add("Runtime: $_") } }
        $total = ($sdks | Measure-Object).Count + ($runtimes | Measure-Object).Count
        $DotNetStatus.Text = "Found $total item(s)."
        Write-Log "Found $total installed .NET items."
    } catch {
        Write-Log "The 'dotnet' command was not found in your PATH." "ERROR"
        $DotNetStatus.Text = "'dotnet' command not found."
    }
}

#================================================================================================
#  EVENT HANDLERS
#================================================================================================
# --- Button Clicks ---
$RefreshPython.Add_Click({
    Find-InstalledPython
    Find-AvailableSoftware -SearchTerm "Python.Python.3" -TargetListBox $AvailablePythonList -StatusTextBlock $PythonStatus
})

$RefreshDotNet.Add_Click({
    Find-InstalledDotNet
    Find-AvailableSoftware -SearchTerm "Microsoft.DotNet" -TargetListBox $AvailableDotNetList -StatusTextBlock $DotNetStatus
})

$InstallPython.Add_Click({
    $selected = $AvailablePythonList.SelectedItem
    if ($null -ne $selected) {
        $sb = [scriptblock]::Create("param(`$id, `$name)
            `$log = @()
            try {
                `$log += 'Executing: winget install --id ' + `$id
                `$process = Start-Process winget -ArgumentList 'install --id ' + `$id + ' -e -h --accept-package-agreements --accept-source-agreements' -Wait -PassThru
                if (`$process.ExitCode -eq 0) { `$log += 'Winget process completed successfully.'; return [PSCustomObject]@{ Success = `$true; Log = `$log } }
                else { `$log += 'Winget process exited with code ' + `$process.ExitCode; return [PSCustomObject]@{ Success = `$false; Log = `$log } }
            } catch { `$log += 'ERROR: ' + `$_.Exception.Message; return [PSCustomObject]@{ Success = `$false; Log = `$log } }
        ")
        $jobArgs = @{ InstallerScriptBlock = $sb.GetNewClosure(); SoftwareName = $selected.DisplayName }
        $jobArgs.InstallerScriptBlock.BeginInvoke($selected.WingetId, $selected.DisplayName, $null, $null)
        Start-InstallerJob @jobArgs
    }
})

$InstallDotNet.Add_Click({
    $selected = $AvailableDotNetList.SelectedItem
    if ($null -ne $selected) {
        $sb = [scriptblock]::Create("param(`$id, `$name)
            `$log = @()
            try {
                `$log += 'Executing: winget install --id ' + `$id
                `$process = Start-Process winget -ArgumentList 'install --id ' + `$id + ' -e -h --accept-package-agreements --accept-source-agreements' -Wait -PassThru
                if (`$process.ExitCode -eq 0) { `$log += 'Winget process completed successfully.'; return [PSCustomObject]@{ Success = `$true; Log = `$log } }
                else { `$log += 'Winget process exited with code ' + `$process.ExitCode; return [PSCustomObject]@{ Success = `$false; Log = `$log } }
            } catch { `$log += 'ERROR: ' + `$_.Exception.Message; return [PSCustomObject]@{ Success = `$false; Log = `$log } }
        ")
        $jobArgs = @{ InstallerScriptBlock = $sb.GetNewClosure(); SoftwareName = $selected.DisplayName }
        $jobArgs.InstallerScriptBlock.BeginInvoke($selected.WingetId, $selected.DisplayName, $null, $null)
        Start-InstallerJob @jobArgs
    }
})

$InstallPipPackage.Add_Click({
    if ($null -ne $SelectedPythonPath -and -not [string]::IsNullOrWhiteSpace($PipPackageName.Text)) {
        $packageName = $PipPackageName.Text
        $pythonExe = Join-Path $SelectedPythonPath "python.exe"
        $sb = [scriptblock]::Create("param(`$exe, `$pkg)
            `$log = @()
            try {
                `$log += 'Executing: ' + `$exe + ' -m pip install ' + `$pkg
                `$process = Start-Process `$exe -ArgumentList ('-m', 'pip', 'install', `$pkg) -Wait -PassThru -NoNewWindow
                if (`$process.ExitCode -eq 0) { `$log += 'Pip process completed successfully.'; return [PSCustomObject]@{ Success = `$true; Log = `$log } }
                else { `$log += 'Pip process exited with code ' + `$process.ExitCode; return [PSCustomObject]@{ Success = `$false; Log = `$log } }
            } catch { `$log += 'ERROR: ' + `$_.Exception.Message; return [PSCustomObject]@{ Success = `$false; Log = `$log } }
        ")
        $jobArgs = @{ InstallerScriptBlock = $sb.GetNewClosure(); SoftwareName = $packageName }
        $jobArgs.InstallerScriptBlock.BeginInvoke($pythonExe, $packageName, $null, $null)
        Start-InstallerJob @jobArgs
    }
})

# --- Selection Changes ---
$InstalledPythonList.Add_SelectionChanged({
    $selected = $InstalledPythonList.SelectedItem
    if ($null -ne $selected) {
        $SelectedPythonPath = $selected.Path
        $InstallPipPackage.IsEnabled = $true
        Write-Log "Selected Python for pip: $($selected.DisplayName) at $($selected.Path)"
    } else {
        $SelectedPythonPath = $null
        $InstallPipPackage.IsEnabled = $false
    }
})

$AvailablePythonList.Add_SelectionChanged({
    $InstallPython.IsEnabled = ($null -ne $AvailablePythonList.SelectedItem)
})

$AvailableDotNetList.Add_SelectionChanged({
    $InstallDotNet.IsEnabled = ($null -ne $AvailableDotNetList.SelectedItem)
})

# --- Window Loaded Event ---
$window.Add_Loaded({
    Write-Log "Application window loaded. Starting initial scans."
    $MainStatusBar.Text = "Scanning for installed and available software..."
    # Set the DisplayMemberPath for our ListBoxes holding custom objects
    $AvailablePythonList.DisplayMemberPath = "DisplayName"
    $AvailableDotNetList.DisplayMemberPath = "DisplayName"
    $InstalledPythonList.DisplayMemberPath = "DisplayName"
    
    # Perform initial scans automatically on startup
    $RefreshPython.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
    $RefreshDotNet.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
    
    Write-Log "Initial scans complete. Ready for user input."
    $MainStatusBar.Text = "Ready."
})

#================================================================================================
#  SHOW WINDOW AND CLEANUP
#================================================================================================
$window.ShowDialog() | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Error "The application exited with an error."
    Pause
}
