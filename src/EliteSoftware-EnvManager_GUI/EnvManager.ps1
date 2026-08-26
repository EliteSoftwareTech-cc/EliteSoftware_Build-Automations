<#
.SYNOPSIS
EliteSoftware Environment Manager GUI
.DESCRIPTION
Manages custom ELITE_BUILD_X64 and ELITE_BUILD_X86 environment variables.
#>
#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

#region UI Generation
$frm_Main = New-Object System.Windows.Forms.Form
$frm_Main.Text = "EliteSoftware Environment Manager"
$frm_Main.Size = New-Object System.Drawing.Size(600, 450)
$frm_Main.StartPosition = "CenterScreen"
$frm_Main.FormBorderStyle = "FixedDialog"
$frm_Main.MaximizeBox = $false
$frm_Main.BackColor = [System.Drawing.Color]::FromArgb(255, 240, 240, 240) # Native dialog background

$font_Primary = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Semibold)
$frm_Main.Font = $font_Primary

# Title Banner
$lbl_TitleBanner = New-Object System.Windows.Forms.Label
$lbl_TitleBanner.Text = "  EliteSoftware Environment Manager"
$lbl_TitleBanner.Size = New-Object System.Drawing.Size(600, 50)
$lbl_TitleBanner.Location = New-Object System.Drawing.Point(0, 0)
$lbl_TitleBanner.BackColor = [System.Drawing.Color]::White
$lbl_TitleBanner.ForeColor = [System.Drawing.Color]::Black
$lbl_TitleBanner.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lbl_TitleBanner.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$frm_Main.Controls.Add($lbl_TitleBanner)

# 3D Inset Area (Main Panel)
$pnl_MainInset = New-Object System.Windows.Forms.Panel
$pnl_MainInset.Size = New-Object System.Drawing.Size(560, 280)
$pnl_MainInset.Location = New-Object System.Drawing.Point(12, 60)
$pnl_MainInset.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$pnl_MainInset.BackColor = [System.Drawing.Color]::White
$frm_Main.Controls.Add($pnl_MainInset)

# Content inside Inset
$lbl_Desc = New-Object System.Windows.Forms.Label
$lbl_Desc.Text = "Configure the global variables for the EliteBuild CLI Toolchain."
$lbl_Desc.Location = New-Object System.Drawing.Point(10, 10)
$lbl_Desc.AutoSize = $true
$pnl_MainInset.Controls.Add($lbl_Desc)

$lbl_X64 = New-Object System.Windows.Forms.Label
$lbl_X64.Text = "ELITE_BUILD_X64 Path:"
$lbl_X64.Location = New-Object System.Drawing.Point(10, 50)
$lbl_X64.AutoSize = $true
$pnl_MainInset.Controls.Add($lbl_X64)

$txt_X64Path = New-Object System.Windows.Forms.TextBox
$txt_X64Path.Location = New-Object System.Drawing.Point(10, 70)
$txt_X64Path.Size = New-Object System.Drawing.Size(430, 25)
$pnl_MainInset.Controls.Add($txt_X64Path)

$btn_BrowseX64 = New-Object System.Windows.Forms.Button
$btn_BrowseX64.Text = "Browse..."
$btn_BrowseX64.Location = New-Object System.Drawing.Point(450, 68)
$btn_BrowseX64.Size = New-Object System.Drawing.Size(90, 27)
$pnl_MainInset.Controls.Add($btn_BrowseX64)

$lbl_X86 = New-Object System.Windows.Forms.Label
$lbl_X86.Text = "ELITE_BUILD_X86 Path:"
$lbl_X86.Location = New-Object System.Drawing.Point(10, 110)
$lbl_X86.AutoSize = $true
$pnl_MainInset.Controls.Add($lbl_X86)

$txt_X86Path = New-Object System.Windows.Forms.TextBox
$txt_X86Path.Location = New-Object System.Drawing.Point(10, 130)
$txt_X86Path.Size = New-Object System.Drawing.Size(430, 25)
$pnl_MainInset.Controls.Add($txt_X86Path)

$btn_BrowseX86 = New-Object System.Windows.Forms.Button
$btn_BrowseX86.Text = "Browse..."
$btn_BrowseX86.Location = New-Object System.Drawing.Point(450, 128)
$btn_BrowseX86.Size = New-Object System.Drawing.Size(90, 27)
$pnl_MainInset.Controls.Add($btn_BrowseX86)

$txt_LogOutput = New-Object System.Windows.Forms.TextBox
$txt_LogOutput.Location = New-Object System.Drawing.Point(10, 180)
$txt_LogOutput.Size = New-Object System.Drawing.Size(530, 80)
$txt_LogOutput.Multiline = $true
$txt_LogOutput.ScrollBars = "Vertical"
$txt_LogOutput.ReadOnly = $true
$txt_LogOutput.BackColor = [System.Drawing.Color]::FromArgb(255, 245, 245, 245)
$pnl_MainInset.Controls.Add($txt_LogOutput)

# The "Chin" (Bottom Area)
$pnl_Chin = New-Object System.Windows.Forms.Panel
$pnl_Chin.Size = New-Object System.Drawing.Size(600, 60)
$pnl_Chin.Location = New-Object System.Drawing.Point(0, 355)
$pnl_Chin.BackColor = [System.Drawing.Color]::FromArgb(255, 225, 225, 225) # Standard grayscale hex mapping
$frm_Main.Controls.Add($pnl_Chin)

$btn_Apply = New-Object System.Windows.Forms.Button
$btn_Apply.Text = "Apply"
$btn_Apply.Location = New-Object System.Drawing.Point(400, 15)
$btn_Apply.Size = New-Object System.Drawing.Size(90, 30)
$pnl_Chin.Controls.Add($btn_Apply)

$btn_Exit = New-Object System.Windows.Forms.Button
$btn_Exit.Text = "Exit"
$btn_Exit.Location = New-Object System.Drawing.Point(495, 15)
$btn_Exit.Size = New-Object System.Drawing.Size(90, 30)
$pnl_Chin.Controls.Add($btn_Exit)

# Tooltips
$tooltip = New-Object System.Windows.Forms.ToolTip
$tooltip.SetToolTip($txt_X64Path, "The path where the 64-bit EliteBuild EXEs are stored. Don't break this.")
$tooltip.SetToolTip($txt_X86Path, "The path where the 32-bit EliteBuild EXEs are stored. Assuming anyone still uses 32-bit.")
$tooltip.SetToolTip($btn_BrowseX64, "Open a fancy dialog to find the 64-bit folder.")
$tooltip.SetToolTip($btn_BrowseX86, "Open a fancy dialog to find the 32-bit folder.")
$tooltip.SetToolTip($btn_Apply, "Save the environment variables permanently into the system. Requires Admin.")
$tooltip.SetToolTip($btn_Exit, "Coward's way out.")
#endregion

#region Event Handlers
function Log-Message {
    param([string]$Msg)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $txt_LogOutput.AppendText("[$timestamp] $Msg`r`n")
}

$btn_BrowseX64.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txt_X64Path.Text = $dialog.SelectedPath
    }
})

$btn_BrowseX86.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txt_X86Path.Text = $dialog.SelectedPath
    }
})

$btn_Apply.Add_Click({
    $x64 = $txt_X64Path.Text.Trim()
    $x86 = $txt_X86Path.Text.Trim()
    
    if ([string]::IsNullOrEmpty($x64) -or [string]::IsNullOrEmpty($x86)) {
        [System.Windows.Forms.MessageBox]::Show("You must specify both paths, you absolute genius.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    try {
        [Environment]::SetEnvironmentVariable("ELITE_BUILD_X64", $x64, "Machine")
        [Environment]::SetEnvironmentVariable("ELITE_BUILD_X86", $x86, "Machine")
        Log-Message "Successfully set System Variables ELITE_BUILD_X64 and ELITE_BUILD_X86."
        
        # Add to PATH if not already present
        $path = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $pathVars = $path -split ';'
        $changed = $false
        if ($x64 -notin $pathVars) { $path += ";$x64"; $changed = $true }
        if ($x86 -notin $pathVars) { $path += ";$x86"; $changed = $true }
        
        if ($changed) {
            [Environment]::SetEnvironmentVariable("Path", $path, "Machine")
            Log-Message "Appended paths to System PATH."
        }
        
        [System.Windows.Forms.MessageBox]::Show("Environment configured successfully. You may need to restart your terminal.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        Log-Message "Error: $_"
        [System.Windows.Forms.MessageBox]::Show("Failed to set variables. Are you running as Administrator?", "Fatal Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

$btn_Exit.Add_Click({
    $frm_Main.Close()
})
#endregion

# Artificial delay for that premium feel
Start-Sleep -Milliseconds 600

# Load current vars if exist
$txt_X64Path.Text = [Environment]::GetEnvironmentVariable("ELITE_BUILD_X64", "Machine")
$txt_X86Path.Text = [Environment]::GetEnvironmentVariable("ELITE_BUILD_X86", "Machine")

Log-Message "EliteSoftware EnvManager Loaded."

$frm_Main.ShowDialog() | Out-Null
