# Requires PowerShell 5.1 or later for most cmdlets (Windows 10/11)
# And .NET Framework 4.5 or later for WPF GUI.

#region XAML Definition
# Define the XAML for the GUI. This creates the window, layout, and controls.
# Using a Grid for flexible layout, TextBoxes for input, Buttons for actions,
# and a ListBox to display network adapters.
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Zach's Advanced Network Manager" Height="650" Width="800"
        WindowStartupLocation="CenterScreen"
        Background="#F0F0F0"
        FontFamily="Inter">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#007ACC"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#007ACC"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="5">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#005C99"/>
                    <Setter Property="BorderBrush" Value="#005C99"/>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Setter Property="Background" Value="#003D66"/>
                    <Setter Property="BorderBrush" Value="#003D66"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Padding" Value="5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="BorderBrush" Value="#CCCCCC"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="3"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="Margin" Value="5,8,5,5"/>
            <Setter Property="Foreground" Value="#333333"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>
        <Style TargetType="Border">
            <Setter Property="Background" Value="White"/>
            <Setter Property="BorderBrush" Value="#DDDDDD"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="8"/>
            <Setter Property="Padding" Value="10"/>
            <Setter Property="Margin" Value="10"/>
        </Style>
        <Style TargetType="ListBox">
            <Setter Property="BorderBrush" Value="#CCCCCC"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="5"/>
            <Setter Property="Padding" Value="5"/>
            <Setter Property="Margin" Value="5"/>
        </Style>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#333333"/>
            <Setter Property="Margin" Value="5"/>
        </Style>
    </Window.Resources>
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="2*"/>
            <ColumnDefinition Width="3*"/>
        </Grid.ColumnDefinitions>

        <!-- Header -->
        <TextBlock Grid.Row="0" Grid.ColumnSpan="2" Text="Network Adapter Manager"
                   FontSize="24" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,10"
                   Foreground="#007ACC"/>

        <!-- Left Column: Adapter List -->
        <Border Grid.Row="1" Grid.Column="0">
            <StackPanel>
                <Label Content="Network Adapters:"/>
                <ListBox x:Name="AdapterListBox" Height="350" SelectionChanged="AdapterListBox_SelectionChanged"/>
                <Button x:Name="RefreshButton" Content="Refresh Adapters" Margin="5,10,5,5"/>
            </StackPanel>
        </Border>

        <!-- Right Column: Adapter Details and Configuration -->
        <Border Grid.Row="1" Grid.Column="1">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <Label Grid.Row="0" Grid.ColumnSpan="2" Content="Adapter Details &amp; IP Configuration" FontWeight="Bold" FontSize="16"/>

                <Label Grid.Row="1" Grid.Column="0" Content="Name:"/>
                <TextBlock x:Name="AdapterNameTextBlock" Grid.Row="1" Grid.Column="1" Text="Select an adapter..."/>

                <Label Grid.Row="2" Grid.Column="0" Content="Description:"/>
                <TextBlock x:Name="AdapterDescriptionTextBlock" Grid.Row="2" Grid.Column="1"/>

                <Label Grid.Row="3" Grid.Column="0" Content="Status:"/>
                <TextBlock x:Name="AdapterStatusTextBlock" Grid.Row="3" Grid.Column="1"/>

                <CheckBox x:Name="EnableDHCPCheckBox" Grid.Row="4" Grid.ColumnSpan="2" Content="Enable DHCP" Margin="5" Checked="EnableDHCPCheckBox_Checked" Unchecked="EnableDHCPCheckBox_Unchecked"/>

                <Label Grid.Row="5" Grid.Column="0" Content="IP Address:"/>
                <TextBox x:Name="IpAddressTextBox" Grid.Row="5" Grid.Column="1"/>

                <Label Grid.Row="6" Grid.Column="0" Content="Subnet Mask:"/>
                <TextBox x:Name="SubnetMaskTextBox" Grid.Row="6" Grid.Column="1"/>

                <Label Grid.Row="7" Grid.Column="0" Content="Default Gateway:"/>
                <TextBox x:Name="GatewayTextBox" Grid.Row="7" Grid.Column="1"/>

                <CheckBox x:Name="EnableAutoDNSCheckBox" Grid.Row="8" Grid.ColumnSpan="2" Content="Automatic DNS" Margin="5" Checked="EnableAutoDNSCheckBox_Checked" Unchecked="EnableAutoDNSCheckBox_Unchecked"/>

                <Label Grid.Row="9" Grid.Column="0" Content="DNS Servers (comma-separated):"/>
                <TextBox x:Name="DnsServersTextBox" Grid.Row="9" Grid.Column="1"/>

                <StackPanel Grid.Row="10" Grid.ColumnSpan="2" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,10,0,0">
                    <Button x:Name="ApplyIpSettingsButton" Content="Apply IP/DNS Settings"/>
                    <Button x:Name="EnableAdapterButton" Content="Enable Adapter"/>
                    <Button x:Name="DisableAdapterButton" Content="Disable Adapter"/>
                </StackPanel>

                <Label Grid.Row="11" Grid.ColumnSpan="2" Content="Network Bridges:" FontWeight="Bold" FontSize="16" Margin="0,15,0,0"/>
                <TextBlock x:Name="BridgeInfoTextBlock" Grid.Row="12" Grid.ColumnSpan="2" TextWrapping="Wrap" VerticalAlignment="Top"/>
            </Grid>
        </Border>

        <!-- Status Bar -->
        <Border Grid.Row="2" Grid.ColumnSpan="2" Margin="0,10,0,0">
            <TextBlock x:Name="StatusTextBlock" Text="Ready." FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center" Padding="5"/>
        </Border>
    </Grid>
</Window>
"@
#endregion

#region PowerShell Script Logic

#region GUI Initialization and Event Handlers
# Add type for XAML.
# Removed System.Management.Automation as it's not needed for WPF and can sometimes cause issues.
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xml

# Load the XAML.
# Using [xml] cast first for potentially more robust parsing of the string.
try {
    $xml = [xml]$xaml
    $reader = (New-Object System.Xml.XmlNodeReader $xml)
    $mainWin = [Windows.Markup.XamlReader]::Load($reader)

    if (-not $mainWin) {
        Write-Host "Error: Failed to load WPF Window from XAML. The $mainWin object is null." -ForegroundColor Red
        exit
    }
} catch {
    Write-Host "Fatal Error: An exception occurred during XAML loading: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Get references to the controls.
# Adding explicit checks for null values after FindName calls to help diagnose if any control is not found.
$adapterListBox = $mainWin.FindName('AdapterListBox')
if (-not $adapterListBox) { Write-Host "Error: AdapterListBox control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$refreshButton = $mainWin.FindName('RefreshButton')
if (-not $refreshButton) { Write-Host "Error: RefreshButton control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$adapterNameTextBlock = $mainWin.FindName('AdapterNameTextBlock')
if (-not $adapterNameTextBlock) { Write-Host "Error: AdapterNameTextBlock control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$adapterDescriptionTextBlock = $mainWin.FindName('AdapterDescriptionTextBlock')
if (-not $adapterDescriptionTextBlock) { Write-Host "Error: AdapterDescriptionTextBlock control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$adapterStatusTextBlock = $mainWin.FindName('AdapterStatusTextBlock')
if (-not $adapterStatusTextBlock) { Write-Host "Error: AdapterStatusTextBlock control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$enableDHCPCheckBox = $mainWin.FindName('EnableDHCPCheckBox')
if (-not $enableDHCPCheckBox) { Write-Host "Error: EnableDHCPCheckBox control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$ipAddressTextBox = $mainWin.FindName('IpAddressTextBox')
if (-not $ipAddressTextBox) { Write-Host "Error: IpAddressTextBox control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$subnetMaskTextBox = $mainWin.FindName('SubnetMaskTextBox')
if (-not $subnetMaskTextBox) { Write-Host "Error: SubnetMaskTextBox control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$gatewayTextBox = $mainWin.FindName('GatewayTextBox')
if (-not $gatewayTextBox) { Write-Host "Error: GatewayTextBox control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$enableAutoDNSCheckBox = $mainWin.FindName('EnableAutoDNSCheckBox')
if (-not $enableAutoDNSCheckBox) { Write-Host "Error: EnableAutoDNSCheckBox control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$dnsServersTextBox = $mainWin.FindName('DnsServersTextBox')
if (-not $dnsServersTextBox) { Write-Host "Error: DnsServersTextBox control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$applyIpSettingsButton = $mainWin.FindName('ApplyIpSettingsButton')
if (-not $applyIpSettingsButton) { Write-Host "Error: ApplyIpSettingsButton control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$enableAdapterButton = $mainWin.FindName('EnableAdapterButton')
if (-not $enableAdapterButton) { Write-Host "Error: EnableAdapterButton control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$disableAdapterButton = $mainWin.FindName('DisableAdapterButton')
if (-not $disableAdapterButton) { Write-Host "Error: DisableAdapterButton control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$statusTextBlock = $mainWin.FindName('StatusTextBlock')
if (-not $statusTextBlock) { Write-Host "Error: StatusTextBlock control not found. Check x:Name in XAML." -ForegroundColor Red; exit }

$bridgeInfoTextBlock = $mainWin.FindName('BridgeInfoTextBlock')
if (-not $bridgeInfoTextBlock) { Write-Host "Error: BridgeInfoTextBlock control not found. Check x:Name in XAML." -ForegroundColor Red; exit }


# Function to update the status text in the GUI.
function Update-Status ($message, $isError = $false) {
    # Ensure $statusTextBlock is not null before trying to access its properties
    if ($null -ne $statusTextBlock) {
        $statusTextBlock.Text = $message
        if ($isError) {
            $statusTextBlock.Foreground = [Windows.Media.Brushes]::Red
        } else {
            $statusTextBlock.Foreground = [Windows.Media.Brushes]::Green
        }
    } else {
        # Fallback to Write-Host if the status text block itself isn't available
        if ($isError) {
            Write-Host "GUI Status Error: $message" -ForegroundColor Red
        } else {
            Write-Host "GUI Status: $message" -ForegroundColor Green
        }
    }
}

#endregion

#region Core Network Functions
# Function to get network adapter information.
function Get-NetworkAdapterInfo {
    try {
        # Get all network adapters, including disabled ones, for comprehensive listing.
        Get-NetAdapter -ErrorAction Stop | Select-Object Name, Description, Status, InterfaceAlias, IfIndex, MacAddress, LinkSpeed, @{Name="State";Expression={$_.State}}
    } catch {
        Update-Status "Error getting network adapter info: $($_.Exception.Message)" $true
        return @()
    }
}

# Function to get IP configuration for a specific adapter.
function Get-IpConfiguration ($adapterName) {
    try {
        # Get IPv4 address configuration.
        $ipConfig = Get-NetAdapterIpConfiguration -InterfaceAlias $adapterName -ErrorAction Stop | Select-Object IPv4Address, IPv4DefaultGateway, @{Name='DNSServer';Expression={($_.DNSServer | ForEach-Object IPAddressToString) -join ','}}, DhcpEnabled
        return $ipConfig
    } catch {
        # Adapter might not have an IP config (e.g., Bluetooth, or not connected).
        return $null
    }
}

# Function to set IP configuration.
function Set-IpConfiguration ($adapterName, $ipAddress, $subnetMask, $gateway) {
    try {
        Update-Status "Applying IP configuration for '$adapterName'..."
        # Remove existing IPv4 addresses first to avoid conflicts.
        Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

        # Add the new static IP address.
        New-NetIPAddress -InterfaceAlias $adapterName -IPAddress $ipAddress -PrefixLength ([IPAddress]::Parse($subnetMask).GetAddressBytes() | Measure-Object -Property Length -Sum).Sum -DefaultGateway $gateway -ErrorAction Stop
        Update-Status "IP configuration applied successfully for '$adapterName'."
        return $true
    } catch {
        Update-Status "Error applying IP configuration: $($_.Exception.Message)" $true
        return $false
    }
}

# Function to enable DHCP.
function Set-DhcpEnabled ($adapterName) {
    try {
        Update-Status "Enabling DHCP for '$adapterName'..."
        # First remove any static IP configurations.
        Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

        # Then enable DHCP on the adapter.
        Set-NetIPInterface -InterfaceAlias $adapterName -Dhcp Enabled -ErrorAction Stop
        Update-Status "DHCP enabled successfully for '$adapterName'."
        return $true
    } catch {
        Update-Status "Error enabling DHCP: $($_.Exception.Message)" $true
        return $false
    }
}

# Function to set DNS servers.
function Set-DnsServers ($adapterName, $dnsServers) {
    try {
        Update-Status "Applying DNS servers for '$adapterName'..."
        # Set DNS servers. If $dnsServers is empty, it effectively sets to automatic.
        if (-not [string]::IsNullOrEmpty($dnsServers)) {
            $dnsArray = $dnsServers.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrEmpty($_) }
            Set-DnsClientServerAddress -InterfaceAlias $adapterName -ServerAddresses $dnsArray -ErrorAction Stop
            Update-Status "DNS servers applied successfully for '$adapterName'."
        } else {
            # Set to automatic DNS.
            Set-DnsClientServerAddress -InterfaceAlias $adapterName -ResetServerAddresses -ErrorAction Stop
            Update-Status "DNS set to automatic for '$adapterName'."
        }
        return $true
    } catch {
        Update-Status "Error applying DNS servers: $($_.Exception.Message)" $true
        return $false
    }
}

# Function to enable a network adapter.
function Enable-NetworkAdapter ($adapterName) {
    try {
        Update-Status "Enabling adapter '$adapterName'..."
        Enable-NetAdapter -InterfaceAlias $adapterName -Confirm:$false -ErrorAction Stop
        Update-Status "Adapter '$adapterName' enabled successfully."
        return $true
    } catch {
        Update-Status "Error enabling adapter: $($_.Exception.Message)" $true
        return $false
    }
}

# Function to disable a network adapter.
function Disable-NetworkAdapter ($adapterName) {
    try {
        Update-Status "Disabling adapter '$adapterName'..."
        Disable-NetAdapter -InterfaceAlias $adapterName -Confirm:$false -ErrorAction Stop
        Update-Status "Adapter '$adapterName' disabled successfully."
        return $true
    } catch {
        Update-Status "Error disabling adapter: $($_.Exception.Message)" $true
        return $false
    }
}

# Function to get network bridge information.
function Get-NetworkBridgeInfo {
    $bridges = @()
    try {
        # Network bridges are often managed by 'netsh bridge'. We can parse its output.
        $netshOutput = (netsh bridge show adapter) 2>$null

        if ($netshOutput) {
            $currentBridgeName = ""
            foreach ($line in $netshOutput) {
                if ($line.Trim() -match "^Bridge Name:\s*(.*)") {
                    $currentBridgeName = $Matches[1].Trim()
                    $bridges += [PSCustomObject]@{
                        Name = $currentBridgeName
                        Members = @()
                    }
                } elseif ($line.Trim() -match "^\s*Adapter Name:\s*(.*)") {
                    if ($bridges.Count -gt 0) {
                        $adapterName = $Matches[1].Trim()
                        $bridges[-1].Members += $adapterName
                    }
                }
            }
        }

        # Also check for "Network Bridge" adapters via Get-NetAdapter
        $bridgeAdapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*Network Bridge*" -or $_.Description -like "*Bridge*" }
        foreach ($bridgeAdapter in $bridgeAdapters) {
            if (-not ($bridges | Where-Object { $_.Name -eq $bridgeAdapter.Name })) {
                $bridges += [PSCustomObject]@{
                    Name = $bridgeAdapter.Name
                    Description = $bridgeAdapter.Description
                    Status = $bridgeAdapter.Status
                    Members = @("Managed by OS or another software") # Cannot easily determine members via Get-NetAdapter
                }
            }
        }

        if ($bridges.Count -gt 0) {
            $bridgeOutput = "Found $($bridges.Count) network bridge(s):`n"
            foreach ($bridge in $bridges) {
                $bridgeOutput += "  - Name: $($bridge.Name)`n"
                if ($bridge.Members.Count -gt 0) {
                    $bridgeOutput += "    Members:`n"
                    $bridge.Members | ForEach-Object { $bridgeOutput += "      * $($_)`n" }
                }
                $bridgeOutput += "`n"
            }
        } else {
            $bridgeOutput = "No network bridges found. You can create bridges via 'Network Connections' in Control Panel."
        }
        if ($null -ne $bridgeInfoTextBlock) { # Defensive check
            $bridgeInfoTextBlock.Text = $bridgeOutput
        } else {
            Write-Host "Bridge Info TextBlock not available. Outputting to console: $bridgeOutput"
        }
    } catch {
        if ($null -ne $bridgeInfoTextBlock) { # Defensive check
            $bridgeInfoTextBlock.Text = "Error retrieving bridge info: $($_.Exception.Message)"
        }
        Update-Status "Error retrieving bridge info: $($_.Exception.Message)" $true
    }
}

#endregion

#region GUI Event Handlers (PowerShell Side)

# Function to populate the adapter list and refresh GUI elements.
function Refresh-AdapterList {
    Update-Status "Refreshing adapter list..."
    
    # Defensive checks for null controls before operations
    if ($null -ne $adapterListBox) {
        $adapterListBox.Items.Clear()
        $adapterListBox.SelectedValue = $null # Clear selection
    }

    if ($null -ne $adapterNameTextBlock) { $adapterNameTextBlock.Text = "Select an adapter..." }
    if ($null -ne $adapterDescriptionTextBlock) { $adapterDescriptionTextBlock.Text = "" }
    if ($null -ne $adapterStatusTextBlock) { $adapterStatusTextBlock.Text = "" }
    if ($null -ne $ipAddressTextBox) { $ipAddressTextBox.Text = "" }
    if ($null -ne $subnetMaskTextBox) { $subnetMaskTextBox.Text = "" }
    if ($null -ne $gatewayTextBox) { $gatewayTextBox.Text = "" }
    if ($null -ne $dnsServersTextBox) { $dnsServersTextBox.Text = "" }
    if ($null -ne $enableDHCPCheckBox) { $enableDHCPCheckBox.IsChecked = $false }
    if ($null -ne $enableAutoDNSCheckBox) { $enableAutoDNSCheckBox.IsChecked = $false }
    # Also ensure text boxes and buttons are enabled by default for a fresh start
    if ($null -ne $ipAddressTextBox) { $ipAddressTextBox.IsEnabled = $true }
    if ($null -ne $subnetMaskTextBox) { $subnetMaskTextBox.IsEnabled = $true }
    if ($null -ne $gatewayTextBox) { $gatewayTextBox.IsEnabled = $true }
    if ($null -ne $dnsServersTextBox) { $dnsServersTextBox.IsEnabled = $true }
    if ($null -ne $applyIpSettingsButton) { $applyIpSettingsButton.IsEnabled = $true }
    if ($null -ne $enableAdapterButton) { $enableAdapterButton.IsEnabled = $true }
    if ($null -ne $disableAdapterButton) { $disableAdapterButton.IsEnabled = $true }

    $adapters = Get-NetworkAdapterInfo

    # Populate the list box.
    if ($null -ne $adapterListBox) {
        foreach ($adapter in $adapters) {
            $adapterListBox.Items.Add($adapter)
        }
    } else {
        Write-Host "Warning: AdapterListBox is null, cannot populate list." -ForegroundColor Yellow
    }

    Update-Status "Adapter list refreshed. Found $($adapters.Count) adapters."
    Get-NetworkBridgeInfo # Refresh bridge info as well
}

# Event handler for adapter selection change.
$adapterListBox.Add_SelectionChanged({
    $selectedAdapter = $adapterListBox.SelectedItem
    if ($selectedAdapter) {
        $adapterNameTextBlock.Text = $selectedAdapter.Name
        $adapterDescriptionTextBlock.Text = $selectedAdapter.Description
        $adapterStatusTextBlock.Text = $selectedAdapter.Status

        $ipConfig = Get-IpConfiguration $selectedAdapter.Name
        if ($ipConfig) {
            # Update IP and DNS fields.
            if ($null -ne $ipConfig.IPv4Address) {
                $ipAddressTextBox.Text = $ipConfig.IPv4Address.IPAddressToString
                # Convert PrefixLength to Subnet Mask for display
                if ($ipConfig.IPv4Address.PrefixLength -ne $null) {
                    $prefixLength = $ipConfig.IPv4Address.PrefixLength
                    $mask = [System.Net.IPAddress]::new(($([long]('0xFFFFFFFF') -shl (32 - $prefixLength))))
                    $subnetMaskTextBox.Text = $mask.ToString()
                } else {
                    $subnetMaskTextBox.Text = ""
                }
            } else {
                $ipAddressTextBox.Text = ""
                $subnetMaskTextBox.Text = ""
            }

            if ($null -ne $ipConfig.IPv4DefaultGateway) {
                 $gatewayTextBox.Text = $ipConfig.IPv4DefaultGateway.IPAddressToString
            } else {
                $gatewayTextBox.Text = ""
            }

            $dnsServersTextBox.Text = $ipConfig.DNSServer
            $enableDHCPCheckBox.IsChecked = $ipConfig.DhcpEnabled
            $enableAutoDNSCheckBox.IsChecked = ([string]::IsNullOrEmpty($ipConfig.DNSServer) -or ($ipConfig.DNSServer -eq "0.0.0.0")) # Simple check for automatic DNS
        } else {
            # Clear fields if no IP config found.
            $ipAddressTextBox.Text = ""
            $subnetMaskTextBox.Text = ""
            $gatewayTextBox.Text = ""
            $dnsServersTextBox.Text = ""
            $dnsServersTextBox.IsEnabled = $true
            $enableDHCPCheckBox.IsChecked = $false
            $enableAutoDNSCheckBox.IsChecked = $true
        }
        Update-Status "Details loaded for '$($selectedAdapter.Name)'."
    } else {
        Update-Status "No adapter selected."
        # Clear all fields when no adapter is selected.
        $adapterNameTextBlock.Text = "Select an adapter..."
        $adapterDescriptionTextBlock.Text = ""
        $adapterStatusTextBlock.Text = ""
        $ipAddressTextBox.Text = ""
        $subnetMaskTextBox.Text = ""
        $gatewayTextBox.Text = ""
        $dnsServersTextBox.Text = ""
        $enableDHCPCheckBox.IsChecked = $false
        $enableAutoDNSCheckBox.IsChecked = $false
        $ipAddressTextBox.IsEnabled = $true
        $subnetMaskTextBox.IsEnabled = $true
        $gatewayTextBox.IsEnabled = $true
        $dnsServersTextBox.IsEnabled = $true
        $applyIpSettingsButton.IsEnabled = $true
        $enableAdapterButton.IsEnabled = $true
        $disableAdapterButton.IsEnabled = $true
    }
})

# Event handler for Refresh button.
$refreshButton.Add_Click({
    Refresh-AdapterList
})

# Event handler for Enable DHCP checkbox.
$enableDHCPCheckBox.Add_Checked({
    # Defensive check
    if ($null -ne $ipAddressTextBox) { $ipAddressTextBox.IsEnabled = $false }
    if ($null -ne $subnetMaskTextBox) { $subnetMaskTextBox.IsEnabled = $false }
    if ($null -ne $gatewayTextBox) { $gatewayTextBox.IsEnabled = $false }
})

$enableDHCPCheckBox.Add_Unchecked({
    # Defensive check
    if ($null -ne $ipAddressTextBox) { $ipAddressTextBox.IsEnabled = $true }
    if ($null -ne $subnetMaskTextBox) { $subnetMaskTextBox.IsEnabled = $true }
    if ($null -ne $gatewayTextBox) { $gatewayTextBox.IsEnabled = $true }
})

# Event handler for Automatic DNS checkbox.
$enableAutoDNSCheckBox.Add_Checked({
    # Defensive check
    if ($null -ne $dnsServersTextBox) { $dnsServersTextBox.IsEnabled = $false }
})

$enableAutoDNSCheckBox.Add_Unchecked({
    # Defensive check
    if ($null -ne $dnsServersTextBox) { $dnsServersTextBox.IsEnabled = $true }
})

# Event handler for Apply IP/DNS Settings button.
$applyIpSettingsButton.Add_Click({
    $selectedAdapter = $adapterListBox.SelectedItem
    if ($selectedAdapter) {
        $adapterName = $selectedAdapter.Name
        $success = $true

        # Handle IP Configuration (DHCP or Static).
        if ($enableDHCPCheckBox.IsChecked) {
            $success = Set-DhcpEnabled $adapterName
        } else {
            $ip = $ipAddressTextBox.Text
            $subnet = $subnetMaskTextBox.Text
            $gateway = $gatewayTextBox.Text

            # Basic validation.
            if ([string]::IsNullOrEmpty($ip) -or [string]::IsNullOrEmpty($subnet)) {
                Update-Status "IP Address and Subnet Mask cannot be empty for static configuration." $true
                $success = $false
            } elseif (-not ([System.Net.IPAddress]::TryParse($ip, [ref]$null)) -or -not ([System.Net.IPAddress]::TryParse($subnet, [ref]$null))) {
                Update-Status "Invalid IP Address or Subnet Mask format." $true
                $success = $false
            } elseif (-not [string]::IsNullOrEmpty($gateway) -and -not ([System.Net.IPAddress]::TryParse($gateway, [ref]$null))) {
                 Update-Status "Invalid Default Gateway format." $true
                 $success = $false
            } else {
                $success = Set-IpConfiguration $adapterName $ip $subnet $gateway
            }
        }

        # Handle DNS Configuration (Automatic or Custom).
        if ($success) { # Only proceed if IP setting was successful or skipped.
            if ($enableAutoDNSCheckBox.IsChecked) {
                Set-DnsServers $adapterName $null # Pass $null to reset DNS.
            } else {
                $dns = $dnsServersTextBox.Text
                if (-not [string]::IsNullOrEmpty($dns)) {
                    # Validate DNS servers (simple check for now).
                    $dnsArray = $dns.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrEmpty($_) }
                    $isValidDns = $true
                    foreach ($d in $dnsArray) {
                        if (-not ([System.Net.IPAddress]::TryParse($d, [ref]$null))) {
                            $isValidDns = $false
                            break
                        }
                    }
                    if ($isValidDns) {
                        Set-DnsServers $adapterName $dns
                    } else {
                        Update-Status "Invalid DNS server format. Please enter comma-separated valid IP addresses." $true
                    }
                } else {
                    Update-Status "DNS servers cannot be empty for custom configuration." $true
                }
            }
        }
        # After applying settings, refresh the list to show updated status.
        Refresh-AdapterList
    } else {
        Update-Status "Please select an adapter first." $true
    }
})

# Event handler for Enable Adapter button.
$enableAdapterButton.Add_Click({
    $selectedAdapter = $adapterListBox.SelectedItem
    if ($selectedAdapter) {
        Enable-NetworkAdapter $selectedAdapter.Name
        Refresh-AdapterList # Refresh to show updated status.
    } else {
        Update-Status "Please select an adapter first." $true
    }
})

# Event handler for Disable Adapter button.
$disableAdapterButton.Add_Click({
    $selectedAdapter = $adapterListBox.SelectedItem
    if ($selectedAdapter) {
        Disable-NetworkAdapter $selectedAdapter.Name
        Refresh-AdapterList # Refresh to show updated status.
    } else {
        Update-Status "Please select an adapter first." $true
    }
})

#endregion

#region Initial Setup and Runtime Check

# Check for Administrator privileges.
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # No GUI elements are initialized yet, so use Write-Host.
    Write-Host "This script requires Administrator privileges to manage network adapters." -ForegroundColor Red
    Write-Host "Please right-click on the PowerShell script and select 'Run as administrator'." -ForegroundColor Red
    exit
}

# Initial population of the adapter list.
# Ensure that $mainWin is loaded and controls are found before calling Refresh-AdapterList
# If a control was not found and caused an exit previously, this line won't be reached.
Refresh-AdapterList

# Show the window. This is the main application loop.
# Ensure $mainWin is not null before attempting to show it.
if ($null -ne $mainWin) {
    $mainWin.ShowDialog()
} else {
    Write-Host "Error: The main window object is null and cannot be displayed." -ForegroundColor Red
}

#endregion
