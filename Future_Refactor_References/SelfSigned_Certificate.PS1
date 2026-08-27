<#
.SYNOPSIS
    A GUI-based PowerShell utility for creating and trusting self-signed SSL certificates for local development, such as for IIS websites.
.DESCRIPTION
    This script provides a user-friendly Windows Forms interface to generate a self-signed certificate with a custom DNS name (Common Name), friendly name, and validity period.
    It then automatically installs the certificate into the Local Computer's "Trusted Root Certification Authorities" store, which resolves browser security warnings for local sites.
    The script requires administrative privileges to modify the certificate stores.
.NOTES
    Self-Signed Certificate Utility v1.0 - Created by: Zachary Whiteman & Google Gemini Ai. 2025-07-13 - 11:25 PM
    File Name: Create-TrustedCert.ps1
    Usage: Right-click the .ps1 file and select "Run with PowerShell". Ensure you are running as an Administrator.
#>

# ---[ PRE-FLIGHT CHECKS ]---
# Check if running as Administrator, which is required for certificate store access.
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # If not admin, display a pop-up message and exit.
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("This script must be run as an Administrator to install certificates. Please right-click the script and choose 'Run as Administrator'.", "Administrator Privileges Required", "OK", "Error")
    exit
}

# ---[ GUI DEFINITION USING WINDOWS FORMS ]---
try {
    # Load the necessary .NET assemblies for creating a GUI.
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms

    # ---[ Form Creation ]---
    $mainForm = New-Object System.Windows.Forms.Form
    $mainForm.Text = "Self-Signed Certificate Utility v1.0"
    $mainForm.Size = New-Object System.Drawing.Size(480, 420)
    $mainForm.MinimumSize = New-Object System.Drawing.Size(480, 420)
    $mainForm.StartPosition = "CenterScreen"
    $mainForm.FormBorderStyle = "FixedSingle"
    $mainForm.MaximizeBox = $false
    $mainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -Id $pid).Path)


    # ---[ UI Element Creation & Configuration ]---

    # GroupBox for Inputs
    $inputGroup = New-Object System.Windows.Forms.GroupBox
    $inputGroup.Text = "Certificate Details"
    $inputGroup.Size = New-Object System.Drawing.Size(430, 150)
    $inputGroup.Location = New-Object System.Drawing.Point(15, 15)
    $mainForm.Controls.Add($inputGroup)

    # Label for DNS Name
    $dnsNameLabel = New-Object System.Windows.Forms.Label
    $dnsNameLabel.Text = "DNS Name (e.g., localhost, my.site):"
    $dnsNameLabel.Location = New-Object System.Drawing.Point(15, 30)
    $dnsNameLabel.Size = New-Object System.Drawing.Size(200, 20)
    $inputGroup.Controls.Add($dnsNameLabel)

    # TextBox for DNS Name
    $dnsNameTextBox = New-Object System.Windows.Forms.TextBox
    $dnsNameTextBox.Location = New-Object System.Drawing.Point(220, 27)
    $dnsNameTextBox.Size = New-Object System.Drawing.Size(190, 20)
    $dnsNameTextBox.Text = "localhost" # Default value
    $inputGroup.Controls.Add($dnsNameTextBox)

    # Label for Friendly Name
    $friendlyNameLabel = New-Object System.Windows.Forms.Label
    $friendlyNameLabel.Text = "Friendly Name (for easy identification):"
    $friendlyNameLabel.Location = New-Object System.Drawing.Point(15, 70)
    $friendlyNameLabel.Size = New-Object System.Drawing.Size(200, 20)
    $inputGroup.Controls.Add($friendlyNameLabel)

    # TextBox for Friendly Name
    $friendlyNameTextBox = New-Object System.Windows.Forms.TextBox
    $friendlyNameTextBox.Location = New-Object System.Drawing.Point(220, 67)
    $friendlyNameTextBox.Size = New-Object System.Drawing.Size(190, 20)
    $friendlyNameTextBox.Text = "Local Dev Cert" # Default value
    $inputGroup.Controls.Add($friendlyNameTextBox)

    # Label for Validity Period
    $validityLabel = New-Object System.Windows.Forms.Label
    $validityLabel.Text = "Validity Period (Years):"
    $validityLabel.Location = New-Object System.Drawing.Point(15, 110)
    $validityLabel.Size = New-Object System.Drawing.Size(200, 20)
    $inputGroup.Controls.Add($validityLabel)

    # NumericUpDown for Validity Period
    $validityNumericUpDown = New-Object System.Windows.Forms.NumericUpDown
    $validityNumericUpDown.Location = New-Object System.Drawing.Point(220, 107)
    $validityNumericUpDown.Size = New-Object System.Drawing.Size(70, 20)
    $validityNumericUpDown.Minimum = 1
    $validityNumericUpDown.Maximum = 20
    $validityNumericUpDown.Value = 5 # Default value
    $inputGroup.Controls.Add($validityNumericUpDown)

    # Generate Button
    $generateButton = New-Object System.Windows.Forms.Button
    $generateButton.Text = "Generate & Install Certificate"
    $generateButton.Location = New-Object System.Drawing.Point(15, 175)
    $generateButton.Size = New-Object System.Drawing.Size(430, 35)
    $generateButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $mainForm.Controls.Add($generateButton)

    # GroupBox for Output
    $outputGroup = New-Object System.Windows.Forms.GroupBox
    $outputGroup.Text = "Log"
    $outputGroup.Size = New-Object System.Drawing.Size(430, 140)
    $outputGroup.Location = New-Object System.Drawing.Point(15, 220)
    $mainForm.Controls.Add($outputGroup)

    # TextBox for Output Log (Read-Only)
    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(15, 25)
    $outputTextBox.Size = New-Object System.Drawing.Size(400, 100)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 8)
    $outputTextBox.Text = "Ready. Fill in the details and click the button above.`r`n"
    $outputGroup.Controls.Add($outputTextBox)


    # ---[ Event Handler for the Generate Button ]---
    $generateButton.Add_Click({
        # Clear previous output
        $outputTextBox.Text = ""
        
        # Function to append text to the log
        $log = { param($message) $outputTextBox.AppendText("$message`r`n") }

        try {
            # --- 1. Get User Inputs ---
            $dnsName = $dnsNameTextBox.Text.Trim()
            $friendlyName = $friendlyNameTextBox.Text.Trim()
            $validityYears = [int]$validityNumericUpDown.Value
            $notAfter = (Get-Date).AddYears($validityYears)

            # Input Validation
            if ([string]::IsNullOrWhiteSpace($dnsName) -or [string]::IsNullOrWhiteSpace($friendlyName)) {
                [System.Windows.Forms.MessageBox]::Show("DNS Name and Friendly Name cannot be empty.", "Input Error", "OK", "Warning")
                return
            }

            & $log "Starting certificate generation process..."
            & $log "  - DNS Name: $dnsName"
            & $log "  - Friendly Name: $friendlyName"
            & $log "  - Valid Until: $($notAfter.ToString('yyyy-MM-dd'))"

            # --- 2. Create the Self-Signed Certificate ---
            # It will be placed in the Local Computer's "Personal" (My) certificate store.
            & $log "Creating the self-signed certificate..."
            $certParams = @{
                DnsName           = $dnsName
                CertStoreLocation = "Cert:\LocalMachine\My"
                FriendlyName      = $friendlyName
                NotAfter          = $notAfter
                KeyUsage          = "KeyEncipherment", "DigitalSignature"
                TextExtension     = "2.5.29.37={text}1.3.6.1.5.5.7.3.1" # Specifies Server Authentication
            }
            $newCert = New-SelfSignedCertificate @certParams
            
            if ($newCert) {
                & $log "Successfully created certificate."
                & $log "  - Thumbprint: $($newCert.Thumbprint)"
            }
            else {
                throw "Failed to create the new certificate."
            }

            # --- 3. Install the Certificate to the Trusted Root Store ---
            # This is the key step to make browsers trust the certificate.
            & $log "Installing certificate to Trusted Root Certification Authorities..."

            # Define paths to the certificate stores
            $sourceStorePath = "Cert:\LocalMachine\My"
            $destStorePath = "Cert:\LocalMachine\Root"

            # Open the stores
            $sourceStore = Get-Item -Path $sourceStorePath
            $destStore = Get-Item -Path $destStorePath
            $sourceStore.Open("ReadOnly")
            $destStore.Open("ReadWrite")

            # Add the certificate
            $destStore.Add($newCert)

            # Close the stores
            $sourceStore.Close()
            $destStore.Close()

            & $log "Certificate successfully installed in the trusted store."
            & $log ""
            & $log "SUCCESS! Browsers on this machine should now trust this certificate."
            
            [System.Windows.Forms.MessageBox]::Show("The certificate was successfully created and installed. You may need to restart your browser or IIS for the changes to take effect.", "Success", "OK", "Information")

        }
        catch {
            # --- Error Handling ---
            $errorMessage = $_.Exception.Message
            & $log "--- ERROR ---"
            & $log $errorMessage
            & $log "---------------"
            [System.Windows.Forms.MessageBox]::Show("An error occurred:`n`n$errorMessage", "Error", "OK", "Error")
        }
    })


    # ---[ Display the Form ]---
    # This makes the form visible and waits for the user to close it.
    $mainForm.ShowDialog() | Out-Null

}
catch {
    # Catch any critical errors during form initialization.
    $errorMessage = $_.Exception.Message
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("A critical error occurred while starting the application:`n`n$errorMessage", "Fatal Error", "OK", "Error")
    # Pause the console to see the error if not running from an interactive session
    if ($Host.Name -eq "ConsoleHost") {
        Write-Warning "Press any key to exit."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    }
}
