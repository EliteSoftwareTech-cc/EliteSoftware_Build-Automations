#requires -version 5.1
# [Win-PS2EXE Settings: -noConsole -sta -icon "ClipBackSaver.ico"]
param(
    [switch]$Hidden
)

#region Assembly Loading
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
#endregion

#region Initialization & Boilerplate
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# The Premium Feel Loading Delay
Start-Sleep -Milliseconds 500

$script:toolName = "ClipboardImageSaver"
$script:appDataDir = "$env:APPDATA\EliteSoftwareCorp\$script:toolName"
if (-not (Test-Path $script:appDataDir)) { New-Item -ItemType Directory -Path $script:appDataDir -Force | Out-Null }
$script:configPath = "$script:appDataDir\config.json"
$script:logPath = "$env:SystemDrive\EliteSoftware\Logs\$script:toolName.log"
$logDir = Split-Path $script:logPath
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

# Setup Sound Registry
$regLabel = "HKCU:\AppEvents\EventLabels\ClipboardImageSaver"
$regSound = "HKCU:\AppEvents\Schemes\Apps\ClipboardImageSaver\ClipboardImageSaver\.Current"
if (-not (Test-Path $regLabel)) { New-Item -Path $regLabel -Force | Out-Null }
Set-ItemProperty -Path $regLabel -Name "(default)" -Value "Clipboard Image Saved" -ErrorAction SilentlyContinue
if (-not (Test-Path $regSound)) { New-Item -Path $regSound -Force | Out-Null }

# --- EliteSoftware Standards: Default Configuration ---
$script:supportedExtensions = @(".png", ".jpg", ".bmp", ".gif", ".tiff", ".ico", ".jpeg")
$script:saveDirectory = Join-Path ([Environment]::GetFolderPath("MyPictures")) "Clipboard Images"
$script:soundPath = "$env:SystemRoot\Media\Vista tada.wav"
$script:isMuted = $false
$script:alwaysOnTop = $true
$script:stopMonitor = $false
$script:hotkeyEnabled = $true
$script:hotkeyModifier = "Ctrl"
$script:hotkeyChar = "1"
$script:loggingEnabled = $true
$script:showBalloons = $true
$script:lastSavedHash = ""
$script:isExiting = $false
$script:BannerTheme = "Elite Aurora v2"
$script:WindowOpacity = 90
#endregion

#region Win32 API & Shell Launcher
$Win32Functions = Add-Type -MemberDefinition @"
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
"@ -Name "Win32Utils" -Namespace Win32 -PassThru

# Hide PowerShell Console if running uncompiled
if ($MyInvocation.MyCommand.Path) {
    $hwnd = 0
    $attempts = 0
    while ($hwnd -eq 0 -and $attempts -lt 20) {
        $hwnd = (Get-Process -Id $PID).MainWindowHandle
        if ($hwnd -eq 0) { Start-Sleep -Milliseconds 50; $attempts++ }
    }
    if ($hwnd -ne 0) { $Win32Functions::ShowWindow($hwnd, 0) | Out-Null }
}

function Open-TargetFolder {
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $script:saveDirectory
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        return $true
    } catch {
        return $false
    }
}
#endregion

#region UI Helpers & Dialogs
function Get-GradientBmp {
    param([System.Drawing.Color]$botCol, [int]$h)
    $w = 10
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $topCol = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $topCol, $botCol, [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    $g.FillRectangle($brush, $rect)
    $brush.Dispose(); $g.Dispose()
    return $bmp
}

function Get-AuroraBmp {
    param([int]$w, [int]$h)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::Teal, [System.Drawing.Color]::MediumSeaGreen, [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal)
    $blend = New-Object System.Drawing.Drawing2D.ColorBlend
    $blend.Colors = @([System.Drawing.Color]::Teal, [System.Drawing.Color]::MediumBlue, [System.Drawing.Color]::Purple, [System.Drawing.Color]::MediumSeaGreen)
    $blend.Positions = @(0.0, 0.33, 0.66, 1.0)
    $brush.InterpolationColors = $blend
    $g.FillRectangle($brush, $rect)
    $brush.Dispose(); $g.Dispose()
    return $bmp
}

function Get-AuroraBmpV2 {
    param([int]$w, [int]$h)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::Teal, [System.Drawing.Color]::MediumSeaGreen, [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal)
    $blend = New-Object System.Drawing.Drawing2D.ColorBlend
    $blend.Colors = @(
        [System.Drawing.Color]::Teal,
        [System.Drawing.Color]::Teal,
        [System.Drawing.Color]::RoyalBlue,
        [System.Drawing.Color]::RoyalBlue,
        [System.Drawing.Color]::Purple,
        [System.Drawing.Color]::Purple,
        [System.Drawing.Color]::MediumSeaGreen,
        [System.Drawing.Color]::MediumSeaGreen
    )
    $blend.Positions = @(0.0, 0.15, 0.35, 0.50, 0.65, 0.80, 0.95, 1.0)
    $brush.InterpolationColors = $blend
    $g.FillRectangle($brush, $rect)
    $brush.Dispose(); $g.Dispose()
    return $bmp
}

function Apply-Settings-To-UI {
    $frm_Main.Opacity = $script:WindowOpacity / 100.0
    if ($pnl_Banner) {
        if ($script:BannerTheme -eq "Elite Aurora v2") {
            $pnl_Banner.BackgroundImage = Get-AuroraBmpV2 1000 70
            $lbl_TitleBanner.ForeColor = [System.Drawing.Color]::White
        } elseif ($script:BannerTheme -eq "Elite Aurora") {
            $pnl_Banner.BackgroundImage = Get-AuroraBmp 1000 70
            $lbl_TitleBanner.ForeColor = [System.Drawing.Color]::White
        } else {
            $lbl_TitleBanner.ForeColor = [System.Drawing.Color]::Black
            if ($script:BannerTheme -eq "Classic Silver") {
                $botCol = [System.Drawing.Color]::FromArgb(255, 220, 225, 230)
            } elseif ($script:BannerTheme -eq "Steel Blue") {
                $botCol = [System.Drawing.Color]::FromArgb(255, 175, 195, 225)
            } else {
                $botCol = [System.Drawing.Color]::FromArgb(255, 175, 215, 225) 
            }
            $pnl_Banner.BackgroundImage = Get-GradientBmp $botCol 70
        }
        $pnl_Banner.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Stretch
    }
}

function Show-AboutDialog {
    $frm_About = New-Object System.Windows.Forms.Form
    $frm_About.Text = "About - Clipboard Image Saver"
    $frm_About.Size = New-Object System.Drawing.Size(500, 260)
    $frm_About.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $frm_About.MaximizeBox = $false
    $frm_About.MinimizeBox = $false
    $frm_About.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $frm_About.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $frm_About.TopMost = $true
    $frm_About.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    
    $infoIconBmp = [System.Drawing.SystemIcons]::Information.ToBitmap()
    $frm_About.Icon = [System.Drawing.Icon]::FromHandle($infoIconBmp.GetHicon())
    
    $aboutBanner = New-Object System.Windows.Forms.Panel
    $aboutBanner.Dock = [System.Windows.Forms.DockStyle]::Top
    $aboutBanner.Height = 70
    
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "Elite Clipboard Image Saver"
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lblTitle.AutoSize = $false
    $lblTitle.Size = New-Object System.Drawing.Size(500, 25)
    $lblTitle.Location = New-Object System.Drawing.Point(0, 15)
    $lblTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblTitle.BackColor = [System.Drawing.Color]::Transparent
    
    $lblSub = New-Object System.Windows.Forms.Label
    $lblSub.Text = "Elite tools for elite surveillance."
    $lblSub.AutoSize = $false
    $lblSub.Size = New-Object System.Drawing.Size(500, 20)
    $lblSub.Location = New-Object System.Drawing.Point(0, 40)
    $lblSub.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblSub.BackColor = [System.Drawing.Color]::Transparent

    if ($script:BannerTheme -eq "Elite Aurora v2") {
        $aboutBanner.BackgroundImage = Get-AuroraBmpV2 500 70
        $lblTitle.ForeColor = [System.Drawing.Color]::White
        $lblSub.ForeColor = [System.Drawing.Color]::White
    } elseif ($script:BannerTheme -eq "Elite Aurora") {
        $aboutBanner.BackgroundImage = Get-AuroraBmp 500 70
        $lblTitle.ForeColor = [System.Drawing.Color]::White
        $lblSub.ForeColor = [System.Drawing.Color]::White
    } else {
        $lblTitle.ForeColor = [System.Drawing.Color]::Black
        $lblSub.ForeColor = [System.Drawing.Color]::Black
        if ($script:BannerTheme -eq "Classic Silver") { $botCol = [System.Drawing.Color]::FromArgb(255, 220, 225, 230) } 
        elseif ($script:BannerTheme -eq "Steel Blue") { $botCol = [System.Drawing.Color]::FromArgb(255, 175, 195, 225) } 
        else { $botCol = [System.Drawing.Color]::FromArgb(255, 175, 215, 225) }
        $aboutBanner.BackgroundImage = Get-GradientBmp $botCol 70
    }
    $aboutBanner.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Stretch
    
    $aboutBanner.Controls.Add($lblTitle)
    $aboutBanner.Controls.Add($lblSub)
    
    $infoIconBox = New-Object System.Windows.Forms.PictureBox
    $infoIconBox.Size = New-Object System.Drawing.Size(32, 32)
    $infoIconBox.Location = New-Object System.Drawing.Point(15, 20)
    $infoIconBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
    $infoIconBox.Image = $infoIconBmp
    $infoIconBox.BackColor = [System.Drawing.Color]::Transparent
    $aboutBanner.Controls.Add($infoIconBox)
    
    $aboutClient = New-Object System.Windows.Forms.Panel
    $aboutClient.Location = New-Object System.Drawing.Point(20, 85)
    $aboutClient.Size = New-Object System.Drawing.Size(445, 80)
    $aboutClient.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $aboutClient.BackColor = [System.Drawing.Color]::FromArgb(255, 251, 251, 251)
    
    $lblInfo = New-Object System.Windows.Forms.Label
    $lblInfo.Text = "EliteSoftware Suite v1.2.0.0`nAuthors: Zachary Whiteman, Susan Gemm, TheShadyRainbow4`nTarget: .NET Framework 4.6 (WinForms, Legacy Visual Styles)"
    $lblInfo.Location = New-Object System.Drawing.Point(5, 15)
    $lblInfo.Size = New-Object System.Drawing.Size(430, 50)
    $lblInfo.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblInfo.BackColor = [System.Drawing.Color]::Transparent
    $aboutClient.Controls.Add($lblInfo)
    
    $aboutChin = New-Object System.Windows.Forms.Panel
    $aboutChin.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $aboutChin.Height = 45
    $aboutChin.BackColor = [System.Drawing.Color]::FromArgb(255, 230, 230, 230)
    
    $btn_Done = New-Object System.Windows.Forms.Button
    $btn_Done.Text = "Done"
    $btn_Done.Size = New-Object System.Drawing.Size(100, 28)
    $btn_Done.Location = New-Object System.Drawing.Point((($frm_About.ClientSize.Width - 100) / 2), 8)
    $btn_Done.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $btn_Done.UseVisualStyleBackColor = $true
    $aboutChin.Controls.Add($btn_Done)
    
    $frm_About.Controls.Add($aboutClient)
    $frm_About.Controls.Add($aboutChin)
    $frm_About.Controls.Add($aboutBanner)
    $frm_About.ShowDialog() | Out-Null
}

function Show-HelpDialog {
    $frm_Help = New-Object System.Windows.Forms.Form
    $frm_Help.Text = "User Manual - Clipboard Image Saver"
    $frm_Help.Size = New-Object System.Drawing.Size(700, 550)
    $frm_Help.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $frm_Help.MaximizeBox = $false
    $frm_Help.MinimizeBox = $false
    $frm_Help.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $frm_Help.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $frm_Help.TopMost = $true
    $frm_Help.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    
    $helpIconBmp = [System.Drawing.SystemIcons]::Question.ToBitmap()
    $frm_Help.Icon = [System.Drawing.Icon]::FromHandle($helpIconBmp.GetHicon())
    
    $helpBanner = New-Object System.Windows.Forms.Panel
    $helpBanner.Dock = [System.Windows.Forms.DockStyle]::Top
    $helpBanner.Height = 70
    
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "Elite Operational Manual"
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lblTitle.AutoSize = $false
    $lblTitle.Size = New-Object System.Drawing.Size(700, 25)
    $lblTitle.Location = New-Object System.Drawing.Point(0, 15)
    $lblTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblTitle.BackColor = [System.Drawing.Color]::Transparent
    
    $lblSub = New-Object System.Windows.Forms.Label
    $lblSub.Text = "Comprehensive documentation for advanced clipboard infiltration."
    $lblSub.AutoSize = $false
    $lblSub.Size = New-Object System.Drawing.Size(700, 20)
    $lblSub.Location = New-Object System.Drawing.Point(0, 40)
    $lblSub.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblSub.BackColor = [System.Drawing.Color]::Transparent

    if ($script:BannerTheme -eq "Elite Aurora v2") {
        $helpBanner.BackgroundImage = Get-AuroraBmpV2 700 70
        $lblTitle.ForeColor = [System.Drawing.Color]::White
        $lblSub.ForeColor = [System.Drawing.Color]::White
    } elseif ($script:BannerTheme -eq "Elite Aurora") {
        $helpBanner.BackgroundImage = Get-AuroraBmp 700 70
        $lblTitle.ForeColor = [System.Drawing.Color]::White
        $lblSub.ForeColor = [System.Drawing.Color]::White
    } else {
        $lblTitle.ForeColor = [System.Drawing.Color]::Black
        $lblSub.ForeColor = [System.Drawing.Color]::Black
        if ($script:BannerTheme -eq "Classic Silver") { $botCol = [System.Drawing.Color]::FromArgb(255, 220, 225, 230) } 
        elseif ($script:BannerTheme -eq "Steel Blue") { $botCol = [System.Drawing.Color]::FromArgb(255, 175, 195, 225) } 
        else { $botCol = [System.Drawing.Color]::FromArgb(255, 175, 215, 225) }
        $helpBanner.BackgroundImage = Get-GradientBmp $botCol 70
    }
    $helpBanner.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Stretch
    
    $helpBanner.Controls.Add($lblTitle)
    $helpBanner.Controls.Add($lblSub)
    
    $helpIconBox = New-Object System.Windows.Forms.PictureBox
    $helpIconBox.Size = New-Object System.Drawing.Size(32, 32)
    $helpIconBox.Location = New-Object System.Drawing.Point(15, 20)
    $helpIconBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
    $helpIconBox.Image = $helpIconBmp
    $helpIconBox.BackColor = [System.Drawing.Color]::Transparent
    $helpBanner.Controls.Add($helpIconBox)
    
    $helpClient = New-Object System.Windows.Forms.Panel
    $helpClient.Location = New-Object System.Drawing.Point(20, 85)
    $helpClient.Size = New-Object System.Drawing.Size(645, 370)
    $helpClient.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $helpClient.BackColor = [System.Drawing.Color]::FromArgb(255, 251, 251, 251)
    
    $txtHelp = New-Object System.Windows.Forms.TextBox
    $txtHelp.Multiline = $true
    $txtHelp.ReadOnly = $true
    $txtHelp.ScrollBars = "Vertical"
    $txtHelp.Dock = "Fill"
    $txtHelp.BorderStyle = "None"
    $txtHelp.BackColor = [System.Drawing.Color]::FromArgb(255, 251, 251, 251)
    
    $essay = "Welcome to the Clipboard Image Saver, the ultimate EliteSoftware surveillance engine designed to aggressively hijack and hoard your ephemeral clipboard data.`r`n`r`n"
    $essay += "OPERATIONAL OVERVIEW:`r`n"
    $essay += "This utility does not simply 'save images'. It establishes a hyper-aggressive ~200ms polling loop against the Windows Presentation Foundation clipboard layer, intercepting standard user memory allocations before they can be overwritten or garbage-collected by the operating system. When an image bitmap is detected, the program instantaneously rips it from the volatile memory stack.`r`n`r`n"
    $essay += "CRYPTOGRAPHIC INTEGRITY:`r`n"
    $essay += "To prevent redundant storage and unnecessary disk I/O, every captured bitmap is passed through a rigid SHA-256 cryptographic hashing algorithm. We rip the memory stream to a byte array, compute a complex hash, and compare it against the last known signature. Only unique hexadecimal signatures are committed to your rigid disk architecture. We absolutely do not waste bytes.`r`n`r`n"
    $essay += "WIN32 API HOTKEY INTERCEPT:`r`n"
    $essay += "Rather than relying on modern, fragile global hooks, this utility reaches directly into user32.dll using unmanaged P/Invoke signatures (GetAsyncKeyState) to query your hardware interrupt states. When your configured Modifier + Key combination is struck, the shell is immediately commanded to spawn your designated file browser. It completely bypasses native OS focus rules to execute your will.`r`n`r`n"
    $essay += "LEGACY RENDERING:`r`n"
    $essay += "You will notice the immaculate rendering of the UI. This is achieved through raw GDI+ linear gradient brushes, manually blending RGB values across a dynamically drawn bitmap canvas, specifically designed to emulate the tactile depth of the Windows Vista aesthetic. We specifically avoid WPF and modern XAML structures to ensure raw execution speed and absolute UI rigidity.`r`n`r`n"
    $essay += "If you manage to break this software, view the heavily appended raw text logs stored in your system drive's EliteSoftware directory. If you still can't figure out the error codes, you probably shouldn't be operating software of this caliber."
    
    $txtHelp.Text = $essay
    $helpClient.Controls.Add($txtHelp)
    
    $helpChin = New-Object System.Windows.Forms.Panel
    $helpChin.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $helpChin.Height = 45
    $helpChin.BackColor = [System.Drawing.Color]::FromArgb(255, 230, 230, 230)
    
    $btn_Done = New-Object System.Windows.Forms.Button
    $btn_Done.Text = "Done"
    $btn_Done.Size = New-Object System.Drawing.Size(120, 28)
    $btn_Done.Location = New-Object System.Drawing.Point((($frm_Help.ClientSize.Width - 120) / 2), 8)
    $btn_Done.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $btn_Done.UseVisualStyleBackColor = $true
    $helpChin.Controls.Add($btn_Done)
    
    $frm_Help.Controls.Add($helpClient)
    $frm_Help.Controls.Add($helpChin)
    $frm_Help.Controls.Add($helpBanner)
    
    $frm_Help.ActiveControl = $btn_Done
    $txtHelp.SelectionStart = 0
    $txtHelp.SelectionLength = 0
    
    $frm_Help.ShowDialog() | Out-Null
}
#endregion

#region Error Handling & Logging
$ErrorActionPreference = 'Stop'

$script:frm_Log = New-Object System.Windows.Forms.Form
$script:frm_Log.Text = "System Activity Log"
$script:frm_Log.Size = New-Object System.Drawing.Size(600, 400)
$script:frm_Log.BackColor = [System.Drawing.Color]::Black
if ($script:globalIcon) { $script:frm_Log.Icon = $script:globalIcon }
$script:frm_Log.StartPosition = "CenterScreen"
$script:frm_Log.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None

$script:txt_DedicatedLog = New-Object System.Windows.Forms.RichTextBox
$script:txt_DedicatedLog.Dock = "Fill"
$script:txt_DedicatedLog.BackColor = [System.Drawing.Color]::Black
$script:txt_DedicatedLog.ForeColor = [System.Drawing.Color]::White
$script:txt_DedicatedLog.BorderStyle = "None"
$script:txt_DedicatedLog.ReadOnly = $true
$script:txt_DedicatedLog.Font = New-Object System.Drawing.Font("Consolas", 10)
$script:frm_Log.Controls.Add($script:txt_DedicatedLog)

$script:frm_Log.Add_FormClosing({
    $_.Cancel = $true
    $script:frm_Log.Hide()
})

function Write-Log {
    param($message, $color = "Lime")
    if (-not $script:loggingEnabled) { return }
    $timestamp = "[$(Get-Date -f 'yyyy-MM-dd HH:mm:ss')] "
    $fullMessage = $timestamp + $message
    try {
        Add-Content -Path $script:logPath -Value $fullMessage -ErrorAction SilentlyContinue
    } catch {}
    
    if ($txt_LogOutput) {
        $txt_LogOutput.AppendText($fullMessage + "`r`n")
        $txt_LogOutput.ScrollToCaret()
    }
    
    if ($script:txt_DedicatedLog) {
        $script:txt_DedicatedLog.SelectionStart = $script:txt_DedicatedLog.TextLength
        $script:txt_DedicatedLog.SelectionColor = [System.Drawing.Color]::Gray
        $script:txt_DedicatedLog.AppendText($timestamp)
        $script:txt_DedicatedLog.SelectionColor = [System.Drawing.Color]::$color
        $script:txt_DedicatedLog.AppendText($message + "`r`n")
        $script:txt_DedicatedLog.ScrollToCaret()
    }
}
#endregion

#region Dynamic Icon Targeting
$script:currentProcess = [System.Diagnostics.Process]::GetCurrentProcess()
$script:processPath = $script:currentProcess.MainModule.FileName

$scriptName = if ($MyInvocation.MyCommand.Path) { [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Path) } else { "ClipboardImageMover" }
$scriptDir = if ($MyInvocation.MyCommand.Path) { [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path) } else { $PWD.Path }

$looseIconPath1 = Join-Path $scriptDir "ClipBackSaver.ico"
$looseIconPath2 = Join-Path $scriptDir "$scriptName.ico"

if ($MyInvocation.MyCommand.Path) {
    if (Test-Path $looseIconPath1) {
        $script:globalIcon = New-Object System.Drawing.Icon($looseIconPath1)
    } elseif (Test-Path $looseIconPath2) {
        $script:globalIcon = New-Object System.Drawing.Icon($looseIconPath2)
    } else {
        $script:globalIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($script:processPath)
    }
} else {
    $script:globalIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($script:processPath)
}
#endregion

#region Configuration Management
function Save-Config {
    $config = [PSCustomObject]@{
        SupportedExtensions = $script:supportedExtensions
        SaveDirectory = $script:saveDirectory
        SoundPath = $script:soundPath
        IsMuted = $script:isMuted
        AlwaysOnTop = $script:alwaysOnTop
        HotkeyEnabled = $script:hotkeyEnabled
        HotkeyModifier = $script:hotkeyModifier
        HotkeyChar = $script:hotkeyChar
        ShowBalloons = $script:showBalloons
        BannerTheme = $script:BannerTheme
        WindowOpacity = $script:WindowOpacity
    }
    $config | ConvertTo-Json -Depth 5 -Compress:$false | Set-Content -Path $script:configPath -ErrorAction SilentlyContinue
}

function Load-Config {
    if (Test-Path $script:configPath) {
        try {
            $config = Get-Content -Path $script:configPath | Out-String | ConvertFrom-Json -ErrorAction Stop
            if ($config.SaveDirectory) { $script:saveDirectory = $config.SaveDirectory }
            if ($config.SoundPath) { $script:soundPath = $config.SoundPath }
            if ($config.IsMuted -ne $null) { $script:isMuted = $config.IsMuted }
            if ($config.AlwaysOnTop -ne $null) { $script:alwaysOnTop = $config.AlwaysOnTop }
            if ($config.HotkeyEnabled -ne $null) { $script:hotkeyEnabled = $config.HotkeyEnabled }
            if ($config.HotkeyModifier -ne $null) { $script:hotkeyModifier = $config.HotkeyModifier }
            if ($config.HotkeyChar -ne $null) { $script:hotkeyChar = $config.HotkeyChar }
            if ($config.ShowBalloons -ne $null) { $script:showBalloons = $config.ShowBalloons }
            if ($config.BannerTheme) { $script:BannerTheme = $config.BannerTheme }
            if ($config.WindowOpacity -ne $null) { $script:WindowOpacity = $config.WindowOpacity }
            if ($config.SupportedExtensions -is [System.Collections.Generic.List[string]] -or $config.SupportedExtensions -is [object[]]) {
                $script:supportedExtensions = $config.SupportedExtensions
            }
        } catch {
            Write-Log "Failed to parse configuration."
        }
    } else {
        Save-Config
    }
}
Load-Config
#endregion

#region GUI Creation
$frm_Main = New-Object System.Windows.Forms.Form
$frm_Main.Text = "Clipboard Image Saver"
$frm_Main.ClientSize = New-Object System.Drawing.Size(750, 680)
$frm_Main.StartPosition = "CenterScreen"
$frm_Main.Icon = $script:globalIcon
$frm_Main.TopMost = $script:alwaysOnTop
$frm_Main.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$frm_Main.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$frm_Main.MaximizeBox = $false
$frm_Main.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None

$tooltip = New-Object System.Windows.Forms.ToolTip

# --- EliteSoftware Standards: Native Win32 MainMenu Override ---
$menu_Main = New-Object System.Windows.Forms.MainMenu
$frm_Main.Menu = $menu_Main

$menu_File = $menu_Main.MenuItems.Add("File")
$menu_Settings = $menu_Main.MenuItems.Add("Settings")
$menu_Help = $menu_Main.MenuItems.Add("Help")

$menu_Hide = $menu_File.MenuItems.Add("Hide to Tray")
$menu_Hide.Add_Click({ $frm_Main.Hide() })
$menu_Exit = $menu_File.MenuItems.Add("Exit")
$menu_Exit.Add_Click({ $script:isExiting = $true })

$menu_Theme = $menu_Settings.MenuItems.Add("Banner Color Theme")
$menu_Theme_Aurora2 = $menu_Theme.MenuItems.Add("Elite Aurora v2")
$menu_Theme_Aurora2.Add_Click({ $script:BannerTheme = "Elite Aurora v2"; Apply-Settings-To-UI; Save-Config })
$menu_Theme_Aurora = $menu_Theme.MenuItems.Add("Elite Aurora")
$menu_Theme_Aurora.Add_Click({ $script:BannerTheme = "Elite Aurora"; Apply-Settings-To-UI; Save-Config })
$menu_Theme_Teal = $menu_Theme.MenuItems.Add("Vista Teal")
$menu_Theme_Teal.Add_Click({ $script:BannerTheme = "Vista Teal"; Apply-Settings-To-UI; Save-Config })
$menu_Theme_Silver = $menu_Theme.MenuItems.Add("Classic Silver")
$menu_Theme_Silver.Add_Click({ $script:BannerTheme = "Classic Silver"; Apply-Settings-To-UI; Save-Config })
$menu_Theme_Blue = $menu_Theme.MenuItems.Add("Steel Blue")
$menu_Theme_Blue.Add_Click({ $script:BannerTheme = "Steel Blue"; Apply-Settings-To-UI; Save-Config })

$menu_Opacity = $menu_Settings.MenuItems.Add("Window Opacity")
$menu_Opacity_100 = $menu_Opacity.MenuItems.Add("100%")
$menu_Opacity_100.Add_Click({ $script:WindowOpacity = 100; Apply-Settings-To-UI; Save-Config })
$menu_Opacity_90 = $menu_Opacity.MenuItems.Add("90%")
$menu_Opacity_90.Add_Click({ $script:WindowOpacity = 90; Apply-Settings-To-UI; Save-Config })
$menu_Opacity_80 = $menu_Opacity.MenuItems.Add("80%")
$menu_Opacity_80.Add_Click({ $script:WindowOpacity = 80; Apply-Settings-To-UI; Save-Config })

$menu_Guidance = $menu_Help.MenuItems.Add("User Manual")
$menu_Guidance.Add_Click({ Show-HelpDialog })
$menu_About = $menu_Help.MenuItems.Add("About")
$menu_About.Add_Click({ Show-AboutDialog })

# Statusbar
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusBar.SizingGrip = $false
$lbl_Status = New-Object System.Windows.Forms.ToolStripStatusLabel("Status: Ready")
$statusBar.Items.Add($lbl_Status)
$frm_Main.Controls.Add($statusBar)

# Chin Panel
$pnl_Chin = New-Object System.Windows.Forms.Panel
$pnl_Chin.Dock = "Bottom"
$pnl_Chin.Height = 50
$pnl_Chin.BackColor = [System.Drawing.Color]::FromArgb(255, 224, 224, 224)
$frm_Main.Controls.Add($pnl_Chin)

$btn_Okay = New-Object System.Windows.Forms.Button
$btn_Okay.Text = "Okay"
$btn_Okay.Size = New-Object System.Drawing.Size(100, 30)
$btn_Okay_X = [int]($frm_Main.ClientSize.Width) - 120
$btn_Okay.Location = New-Object System.Drawing.Point($btn_Okay_X, 10)
$tooltip.SetToolTip($btn_Okay, "Dismisses this window to the tray. Does not terminate the elite surveillance.")
$pnl_Chin.Controls.Add($btn_Okay)

$btn_Apply = New-Object System.Windows.Forms.Button
$btn_Apply.Text = "Apply"
$btn_Apply.Size = New-Object System.Drawing.Size(100, 30)
$btn_Apply_X = [int]($frm_Main.ClientSize.Width) - 230
$btn_Apply.Location = New-Object System.Drawing.Point($btn_Apply_X, 10)
$tooltip.SetToolTip($btn_Apply, "Applies changes so you don't lose your precious configuration.")
$pnl_Chin.Controls.Add($btn_Apply)

$btn_Exit = New-Object System.Windows.Forms.Button
$btn_Exit.Text = "Exit"
$btn_Exit.Size = New-Object System.Drawing.Size(100, 30)
$btn_Exit.Location = New-Object System.Drawing.Point(10, 10)
$tooltip.SetToolTip($btn_Exit, "Terminates the application completely.")
$pnl_Chin.Controls.Add($btn_Exit)

# Title Banner
$pnl_Banner = New-Object System.Windows.Forms.Panel
$pnl_Banner.Dock = "Top"
$pnl_Banner.Height = 70
$pnl_Banner.BackColor = [System.Drawing.Color]::White
$frm_Main.Controls.Add($pnl_Banner)

$pic_BannerIcon = New-Object System.Windows.Forms.PictureBox
if ($script:globalIcon) {
    $pic_BannerIcon.Image = $script:globalIcon.ToBitmap()
}
$pic_BannerIcon.SizeMode = "StretchImage"
$pic_BannerIcon.Size = New-Object System.Drawing.Size(48, 48)
$pic_BannerIcon.Location = New-Object System.Drawing.Point(10, 10)
$pic_BannerIcon.BackColor = [System.Drawing.Color]::Transparent
$pnl_Banner.Controls.Add($pic_BannerIcon)

$lbl_TitleBanner = New-Object System.Windows.Forms.Label
$lbl_TitleBanner.Text = "Elite Clipboard Saver"
$lbl_TitleBanner.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lbl_TitleBanner.AutoSize = $true
$lbl_TitleBanner.Location = New-Object System.Drawing.Point(70, 18)
$lbl_TitleBanner.BackColor = [System.Drawing.Color]::Transparent
$pnl_Banner.Controls.Add($lbl_TitleBanner)

# 3D Inset Client Area
$pnl_ClientEdge = New-Object System.Windows.Forms.Panel
$pnl_ClientEdge.Dock = "Fill"
$pnl_ClientEdge.BorderStyle = "Fixed3D"
$pnl_ClientEdge.Padding = New-Object System.Windows.Forms.Padding(5)
$frm_Main.Controls.Add($pnl_ClientEdge)

$tab_Main = New-Object System.Windows.Forms.TabControl
$tab_Main.Dock = "Fill"
$pnl_ClientEdge.Controls.Add($tab_Main)

# --- Tab: Control ---
$page_Control = New-Object System.Windows.Forms.TabPage("Control")
$tab_Main.TabPages.Add($page_Control)

$btn_Start = New-Object System.Windows.Forms.Button
$btn_Start.Text = "Start Monitoring"
$btn_Start.Location = New-Object System.Drawing.Point(208, 15)
$btn_Start.Size = New-Object System.Drawing.Size(150, 35)
$tooltip.SetToolTip($btn_Start, "Engage the elite surveillance algorithm to aggressively archive your clipboard.")
$page_Control.Controls.Add($btn_Start)

$btn_Stop = New-Object System.Windows.Forms.Button
$btn_Stop.Text = "Stop Monitoring"
$btn_Stop.Location = New-Object System.Drawing.Point(378, 15)
$btn_Stop.Size = New-Object System.Drawing.Size(150, 35)
$btn_Stop.Enabled = $false
$tooltip.SetToolTip($btn_Stop, "Coward's way out. Halts the clipboard monitoring.")
$page_Control.Controls.Add($btn_Stop)

$lbl_LogView = New-Object System.Windows.Forms.Label
$lbl_LogView.Text = "Activity Log:"
$lbl_LogView.Location = New-Object System.Drawing.Point(28, 70)
$lbl_LogView.AutoSize = $true
$lbl_LogView.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$page_Control.Controls.Add($lbl_LogView)

$txt_LogOutput = New-Object System.Windows.Forms.TextBox
$txt_LogOutput.Multiline = $true
$txt_LogOutput.ScrollBars = "Vertical"
$txt_LogOutput.Location = New-Object System.Drawing.Point(28, 95)
$txt_LogOutput.Size = New-Object System.Drawing.Size(680, 240)
$txt_LogOutput.Font = New-Object System.Drawing.Font("Consolas", 10)
$txt_LogOutput.BackColor = [System.Drawing.Color]::Black
$txt_LogOutput.ForeColor = [System.Drawing.Color]::Lime
$txt_LogOutput.ReadOnly = $true
$page_Control.Controls.Add($txt_LogOutput)

$lnk_ViewLogs = New-Object System.Windows.Forms.LinkLabel
$lnk_ViewLogs.Text = "View ClipboardImageSaver Logs"
$lnk_ViewLogs.Location = New-Object System.Drawing.Point(28, 345)
$lnk_ViewLogs.AutoSize = $true
$tooltip.SetToolTip($lnk_ViewLogs, "Click to violently open the raw log file in Notepad.")
$page_Control.Controls.Add($lnk_ViewLogs)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(28, 365)
$progressBar.Size = New-Object System.Drawing.Size(680, 20)
$progressBar.Style = "Blocks"
$page_Control.Controls.Add($progressBar)

# --- Tab: Settings ---
$page_Settings = New-Object System.Windows.Forms.TabPage("Settings")
$tab_Main.TabPages.Add($page_Settings)

$grp_General = New-Object System.Windows.Forms.GroupBox
$grp_General.Text = "General Settings"
$grp_General.Location = New-Object System.Drawing.Point(25, 15)
$grp_General.Size = New-Object System.Drawing.Size(680, 200)
$page_Settings.Controls.Add($grp_General)

$lbl_SaveDir = New-Object System.Windows.Forms.Label
$lbl_SaveDir.Text = "Save Directory:"
$lbl_SaveDir.Location = New-Object System.Drawing.Point(20, 30)
$lbl_SaveDir.AutoSize = $true
$grp_General.Controls.Add($lbl_SaveDir)

$txt_SaveDir = New-Object System.Windows.Forms.TextBox
$txt_SaveDir.Location = New-Object System.Drawing.Point(140, 27)
$txt_SaveDir.Size = New-Object System.Drawing.Size(420, 23)
$txt_SaveDir.Text = $script:saveDirectory
$tooltip.SetToolTip($txt_SaveDir, "Where your precious copied images will be hoarded.")
$grp_General.Controls.Add($txt_SaveDir)

$btn_BrowseDir = New-Object System.Windows.Forms.Button
$btn_BrowseDir.Text = "Browse..."
$btn_BrowseDir.Location = New-Object System.Drawing.Point(570, 26)
$btn_BrowseDir.Size = New-Object System.Drawing.Size(90, 25)
$tooltip.SetToolTip($btn_BrowseDir, "Click to choose a new hoarding location.")
$grp_General.Controls.Add($btn_BrowseDir)

$chk_AlwaysOnTop = New-Object System.Windows.Forms.CheckBox
$chk_AlwaysOnTop.Text = "Always On Top"
$chk_AlwaysOnTop.Location = New-Object System.Drawing.Point(20, 70)
$chk_AlwaysOnTop.Width = 150
$chk_AlwaysOnTop.Checked = $script:alwaysOnTop
$tooltip.SetToolTip($chk_AlwaysOnTop, "Forces this window to aggressively dominate your screen space.")
$grp_General.Controls.Add($chk_AlwaysOnTop)

$chk_Mute = New-Object System.Windows.Forms.CheckBox
$chk_Mute.Text = "Mute Save Sound"
$chk_Mute.Location = New-Object System.Drawing.Point(400, 70)
$chk_Mute.Width = 130
$chk_Mute.Checked = $script:isMuted
$tooltip.SetToolTip($chk_Mute, "Silences the glorious chime of a successful image capture.")
$grp_General.Controls.Add($chk_Mute)

$chk_Balloons = New-Object System.Windows.Forms.CheckBox
$chk_Balloons.Text = "Show Balloon Tips"
$chk_Balloons.Location = New-Object System.Drawing.Point(540, 70)
$chk_Balloons.Width = 110
$chk_Balloons.Checked = $script:showBalloons
$tooltip.SetToolTip($chk_Balloons, "Announce saves with a legacy tray balloon.")
$grp_General.Controls.Add($chk_Balloons)

$chk_Hotkey = New-Object System.Windows.Forms.CheckBox
$chk_Hotkey.Text = "Enable Hotkey"
$chk_Hotkey.Location = New-Object System.Drawing.Point(20, 110)
$chk_Hotkey.Width = 120
$chk_Hotkey.Checked = $script:hotkeyEnabled
$grp_General.Controls.Add($chk_Hotkey)

$lbl_Modifier = New-Object System.Windows.Forms.Label
$lbl_Modifier.Text = "Mod:"
$lbl_Modifier.Location = New-Object System.Drawing.Point(145, 113)
$lbl_Modifier.AutoSize = $true
$grp_General.Controls.Add($lbl_Modifier)

$cmb_Modifier = New-Object System.Windows.Forms.ComboBox
$cmb_Modifier.DropDownStyle = "DropDownList"
$cmb_Modifier.Location = New-Object System.Drawing.Point(180, 110)
$cmb_Modifier.Size = New-Object System.Drawing.Size(60, 23)
$cmb_Modifier.Items.AddRange(@("Ctrl", "Alt", "Shift"))
$cmb_Modifier.SelectedItem = $script:hotkeyModifier
$grp_General.Controls.Add($cmb_Modifier)

$lbl_Key = New-Object System.Windows.Forms.Label
$lbl_Key.Text = "Key:"
$lbl_Key.Location = New-Object System.Drawing.Point(260, 113)
$lbl_Key.AutoSize = $true
$grp_General.Controls.Add($lbl_Key)

$cmb_Key = New-Object System.Windows.Forms.ComboBox
$cmb_Key.DropDownStyle = "DropDownList"
$cmb_Key.Location = New-Object System.Drawing.Point(290, 110)
$cmb_Key.Size = New-Object System.Drawing.Size(60, 23)
$cmb_Key.Items.AddRange(@("1","2","3","4","5","6","7","8","9","0","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"))
$cmb_Key.SelectedItem = $script:hotkeyChar
$grp_General.Controls.Add($cmb_Key)

$lbl_SoundFile = New-Object System.Windows.Forms.Label
$lbl_SoundFile.Text = "Sound File:"
$lbl_SoundFile.Location = New-Object System.Drawing.Point(20, 150)
$lbl_SoundFile.AutoSize = $true
$grp_General.Controls.Add($lbl_SoundFile)

$txt_SoundFile = New-Object System.Windows.Forms.TextBox
$txt_SoundFile.Location = New-Object System.Drawing.Point(140, 147)
$txt_SoundFile.Size = New-Object System.Drawing.Size(420, 23)
$txt_SoundFile.Text = $script:soundPath
$grp_General.Controls.Add($txt_SoundFile)

$btn_BrowseSound = New-Object System.Windows.Forms.Button
$btn_BrowseSound.Text = "Browse..."
$btn_BrowseSound.Location = New-Object System.Drawing.Point(570, 146)
$btn_BrowseSound.Size = New-Object System.Drawing.Size(90, 25)
$grp_General.Controls.Add($btn_BrowseSound)

$grp_Extensions = New-Object System.Windows.Forms.GroupBox
$grp_Extensions.Text = "Supported Extensions"
$grp_Extensions.Location = New-Object System.Drawing.Point(25, 230)
$grp_Extensions.Size = New-Object System.Drawing.Size(680, 140)
$page_Settings.Controls.Add($grp_Extensions)

$lst_Extensions = New-Object System.Windows.Forms.ListBox
$lst_Extensions.Location = New-Object System.Drawing.Point(20, 30)
$lst_Extensions.Size = New-Object System.Drawing.Size(150, 120)
$script:supportedExtensions | ForEach-Object { $lst_Extensions.Items.Add($_) | Out-Null }
$tooltip.SetToolTip($lst_Extensions, "A list of image formats we deem worthy of processing.")
$grp_Extensions.Controls.Add($lst_Extensions)

$lbl_NewExt = New-Object System.Windows.Forms.Label
$lbl_NewExt.Text = "Add Extension:"
$lbl_NewExt.Location = New-Object System.Drawing.Point(200, 30)
$lbl_NewExt.AutoSize = $true
$grp_Extensions.Controls.Add($lbl_NewExt)

$txt_NewExt = New-Object System.Windows.Forms.TextBox
$txt_NewExt.Location = New-Object System.Drawing.Point(200, 50)
$txt_NewExt.Size = New-Object System.Drawing.Size(120, 23)
$tooltip.SetToolTip($txt_NewExt, "Type a new format here. Don't forget the dot.")
$grp_Extensions.Controls.Add($txt_NewExt)

$btn_AddExt = New-Object System.Windows.Forms.Button
$btn_AddExt.Text = "Add"
$btn_AddExt.Location = New-Object System.Drawing.Point(330, 48)
$btn_AddExt.Size = New-Object System.Drawing.Size(80, 27)
$tooltip.SetToolTip($btn_AddExt, "Command the system to accept this new format.")
$grp_Extensions.Controls.Add($btn_AddExt)

$btn_RemoveExt = New-Object System.Windows.Forms.Button
$btn_RemoveExt.Text = "Remove Selected"
$btn_RemoveExt.Location = New-Object System.Drawing.Point(200, 90)
$btn_RemoveExt.Size = New-Object System.Drawing.Size(130, 30)
$tooltip.SetToolTip($btn_RemoveExt, "Banishes the selected format from our processing list.")
$grp_Extensions.Controls.Add($btn_RemoveExt)

# --- Tab: Configuration (Raw JSON) ---
$page_Config = New-Object System.Windows.Forms.TabPage("Configuration")
$tab_Main.TabPages.Add($page_Config)

$btn_OpenConfig = New-Object System.Windows.Forms.Button
$btn_OpenConfig.Text = "Open Folder"
$btn_OpenConfig.Location = New-Object System.Drawing.Point(25, 15)
$btn_OpenConfig.Size = New-Object System.Drawing.Size(100, 30)
$tooltip.SetToolTip($btn_OpenConfig, "Opens the folder where your secrets are stored.")
$page_Config.Controls.Add($btn_OpenConfig)

$btn_EditConfig = New-Object System.Windows.Forms.Button
$btn_EditConfig.Text = "Edit in Notepad"
$btn_EditConfig.Location = New-Object System.Drawing.Point(135, 15)
$btn_EditConfig.Size = New-Object System.Drawing.Size(110, 30)
$page_Config.Controls.Add($btn_EditConfig)

$btn_SaveConfig = New-Object System.Windows.Forms.Button
$btn_SaveConfig.Text = "Save Changes"
$btn_SaveConfig.Location = New-Object System.Drawing.Point(255, 15)
$btn_SaveConfig.Size = New-Object System.Drawing.Size(110, 30)
$page_Config.Controls.Add($btn_SaveConfig)

$btn_RevertConfig = New-Object System.Windows.Forms.Button
$btn_RevertConfig.Text = "Revert Changes"
$btn_RevertConfig.Location = New-Object System.Drawing.Point(375, 15)
$btn_RevertConfig.Size = New-Object System.Drawing.Size(110, 30)
$page_Config.Controls.Add($btn_RevertConfig)

$txt_ConfigEditor = New-Object System.Windows.Forms.TextBox
$txt_ConfigEditor.Multiline = $true
$txt_ConfigEditor.ScrollBars = "Both"
$txt_ConfigEditor.Location = New-Object System.Drawing.Point(25, 60)
$txt_ConfigEditor.Size = New-Object System.Drawing.Size(690, 330)
$txt_ConfigEditor.Font = New-Object System.Drawing.Font("Consolas", 10)
$tooltip.SetToolTip($txt_ConfigEditor, "The raw configuration data. Touch it if you dare.")
if (Test-Path $script:configPath) { $txt_ConfigEditor.Text = Get-Content $script:configPath | Out-String }
$page_Config.Controls.Add($txt_ConfigEditor)

foreach ($btn in @($btn_Okay, $btn_Apply, $btn_Exit, $btn_Start, $btn_Stop, $btn_BrowseDir, $btn_AddExt, $btn_RemoveExt, $btn_OpenConfig, $btn_EditConfig, $btn_SaveConfig, $btn_RevertConfig, $btn_BrowseSound)) {
    if ($null -ne $btn) { $btn.UseVisualStyleBackColor = $true }
}

# --- EliteSoftware Standards: Correct Docking Z-Order ---
$pnl_Chin.SendToBack()
$statusBar.SendToBack()
$pnl_Banner.SendToBack()
$pnl_ClientEdge.BringToFront()

Apply-Settings-To-UI

# --- Native Win32 ContextMenu for Tray Icon Override ---
$script:trayIcon = New-Object System.Windows.Forms.NotifyIcon
$script:trayIcon.Icon = $script:globalIcon
$script:trayIcon.Text = "Clipboard Image Saver"
$script:trayIcon.Visible = $true

$ctx_Menu = New-Object System.Windows.Forms.ContextMenu
$ctx_OpenFolder = $ctx_Menu.MenuItems.Add("Open Folder")
$ctx_ShowLog = $ctx_Menu.MenuItems.Add("Show Activity Log")
$ctx_Open = $ctx_Menu.MenuItems.Add("Show Settings GUI")
$ctx_Menu.MenuItems.Add("-") | Out-Null
$ctx_Hotkey = $ctx_Menu.MenuItems.Add("Disable Hotkey (Ctrl+1)")
$ctx_Logging = $ctx_Menu.MenuItems.Add("Disable Logging")
$ctx_Pause = $ctx_Menu.MenuItems.Add("Pause Saving")
$ctx_Menu.MenuItems.Add("-") | Out-Null
$ctx_Exit = $ctx_Menu.MenuItems.Add("Quit Program")

$script:trayIcon.ContextMenu = $ctx_Menu

if (-not $script:hotkeyEnabled) { $ctx_Hotkey.Text = "Enable Hotkey (Ctrl+1)" }
if (-not $script:loggingEnabled) { $ctx_Logging.Text = "Enable Logging" }
if ($script:stopMonitor) { $ctx_Pause.Text = "Resume Saving" }
#endregion

#region Event Handlers
$btn_Start.Add_Click({
    $script:stopMonitor = $false
    $btn_Start.Enabled = $false
    $btn_Stop.Enabled = $true
    $progressBar.Style = "Marquee"
    $lbl_Status.Text = "Status: Monitoring Active"
    if ($ctx_Pause) { $ctx_Pause.Text = "Pause Saving" }
    Write-Log "Surveillance algorithm engaged. Monitoring clipboard."
})

$btn_Stop.Add_Click({
    $script:stopMonitor = $true
    $btn_Start.Enabled = $true
    $btn_Stop.Enabled = $false
    $progressBar.Style = "Blocks"
    $progressBar.Value = 0
    $lbl_Status.Text = "Status: Monitoring Paused"
    if ($ctx_Pause) { $ctx_Pause.Text = "Resume Saving" }
    Write-Log "Surveillance algorithm paused by user."
})

$btn_Okay.Add_Click({
    $frm_Main.Hide()
})

$btn_Apply.Add_Click({
    $script:saveDirectory = $txt_SaveDir.Text
    $script:alwaysOnTop = $chk_AlwaysOnTop.Checked
    $script:hotkeyEnabled = $chk_Hotkey.Checked
    $script:hotkeyModifier = $cmb_Modifier.SelectedItem
    $script:hotkeyChar = $cmb_Key.SelectedItem
    $script:isMuted = $chk_Mute.Checked
    $script:showBalloons = $chk_Balloons.Checked
    
    $script:soundPath = $txt_SoundFile.Text
    $regSound = "HKCU:\AppEvents\Schemes\Apps\ClipboardImageSaver\ClipboardImageSaver\.Current"
    if (-not (Test-Path $regSound)) { New-Item -Path $regSound -Force | Out-Null }
    Set-ItemProperty -Path $regSound -Name "(default)" -Value $script:soundPath -ErrorAction SilentlyContinue
    
    $script:supportedExtensions = @()
    foreach ($item in $lst_Extensions.Items) {
        $script:supportedExtensions += $item
    }
    
    Save-Config
    $frm_Main.TopMost = $script:alwaysOnTop
    
    if (Test-Path $script:configPath) { $txt_ConfigEditor.Text = Get-Content $script:configPath | Out-String }
    
    Write-Log "Configuration applied successfully."
})

$btn_Exit.Add_Click({
    $script:isExiting = $true
})

$btn_BrowseDir.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.SelectedPath = $script:saveDirectory
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txt_SaveDir.Text = $folderBrowser.SelectedPath
    }
})

$btn_BrowseSound.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "WAV Files (*.wav)|*.wav|All Files (*.*)|*.*"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txt_SoundFile.Text = $dlg.FileName
    }
})

$btn_AddExt.Add_Click({
    $newExt = $txt_NewExt.Text.Trim()
    if ($newExt -ne "") {
        if (-not $newExt.StartsWith(".")) { $newExt = ".$newExt" }
        if (-not $lst_Extensions.Items.Contains($newExt)) {
            $lst_Extensions.Items.Add($newExt) | Out-Null
            $txt_NewExt.Clear()
        }
    }
})

$btn_RemoveExt.Add_Click({
    if ($lst_Extensions.SelectedIndex -ge 0) {
        $lst_Extensions.Items.RemoveAt($lst_Extensions.SelectedIndex)
    }
})

$lnk_ViewLogs.Add_LinkClicked({
    if (Test-Path $script:logPath) {
        Start-Process "notepad.exe" $script:logPath
    } else {
        [System.Windows.Forms.MessageBox]::Show("Log file does not exist yet.", "Error", "OK", "Error")
    }
})

$btn_OpenConfig.Add_Click({
    if (Test-Path $script:appDataDir) {
        Invoke-Item $script:appDataDir
    }
})

$btn_EditConfig.Add_Click({
    if (Test-Path $script:configPath) { Start-Process "notepad.exe" $script:configPath }
})
$btn_SaveConfig.Add_Click({
    try {
        Set-Content -Path $script:configPath -Value $txt_ConfigEditor.Text
        Load-Config
        Write-Log "Raw configuration saved and loaded."
    } catch { Write-Log "Error saving raw configuration." "Red" }
})
$btn_RevertConfig.Add_Click({
    if (Test-Path $script:configPath) { $txt_ConfigEditor.Text = Get-Content $script:configPath | Out-String }
})

$frm_Main.Add_FormClosing({
    if (-not $script:isExiting) {
        $_.Cancel = $true
        $frm_Main.Hide()
    }
})

$ctx_OpenFolder.Add_Click({
    Open-TargetFolder | Out-Null
})

$ctx_ShowLog.Add_Click({
    $script:frm_Log.Show()
    $script:frm_Log.WindowState = "Normal"
    $script:frm_Log.Activate()
})

$ctx_Open.Add_Click({
    $frm_Main.Show()
    $frm_Main.WindowState = "Normal"
})

$ctx_Hotkey.Add_Click({
    $script:hotkeyEnabled = -not $script:hotkeyEnabled
    $chk_Hotkey.Checked = $script:hotkeyEnabled
    if ($script:hotkeyEnabled) { $ctx_Hotkey.Text = "Disable Hotkey (Ctrl+1)" } else { $ctx_Hotkey.Text = "Enable Hotkey (Ctrl+1)" }
    Save-Config
    Write-Log "HOTKEY SETTING: $($ctx_Hotkey.Text)" "Yellow"
})

$ctx_Logging.Add_Click({
    $script:loggingEnabled = -not $script:loggingEnabled
    if ($script:loggingEnabled) { $ctx_Logging.Text = "Disable Logging" } else { $ctx_Logging.Text = "Enable Logging" }
    if ($script:loggingEnabled) { Write-Log "LOGGING ENABLED" "Lime" } else { Write-Log "LOGGING DISABLED" "Red" }
})

$ctx_Pause.Add_Click({
    if ($script:stopMonitor) {
        $btn_Start.PerformClick()
        $ctx_Pause.Text = "Pause Saving"
        Write-Log "Monitoring RESUMED" "Lime"
    } else {
        $btn_Stop.PerformClick()
        $ctx_Pause.Text = "Resume Saving"
        Write-Log "Monitoring PAUSED" "Red"
    }
})

$ctx_Exit.Add_Click({
    $script:isExiting = $true
})

$script:trayIcon.Add_DoubleClick({
    $frm_Main.Show()
    $frm_Main.WindowState = "Normal"
    $frm_Main.Activate()
})
#endregion

#region Helper: Image Functions
function Get-ImageHash($image) {
    $ms = New-Object System.IO.MemoryStream
    $image.Save($ms, [System.Drawing.Imaging.ImageFormat]::Bmp)
    $bytes = $ms.ToArray(); $ms.Dispose()
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $h = [System.BitConverter]::ToString($sha256.ComputeHash($bytes)); $sha256.Dispose()
    return $h
}

function Get-ImageFormatFromExtension($extension) {
    switch ($extension.ToLower()) {
        ".png" { return [System.Drawing.Imaging.ImageFormat]::Png }
        ".jpg" { return [System.Drawing.Imaging.ImageFormat]::Jpeg }
        ".jpeg" { return [System.Drawing.Imaging.ImageFormat]::Jpeg }
        ".gif" { return [System.Drawing.Imaging.ImageFormat]::Gif }
        ".tiff" { return [System.Drawing.Imaging.ImageFormat]::Tiff }
        default { return [System.Drawing.Imaging.ImageFormat]::Bmp }
    }
}
#endregion

#region Main Loop
if (-not $Hidden -and -not ($args -contains "-Hidden") -and -not ($args -contains "/Hidden")) {
    $frm_Main.Show()
    $frm_Main.Activate()
}

Write-Log "System Initialized. Ready for action."
if (-not $script:stopMonitor) {
    $btn_Start.PerformClick()
}

$null = $frm_Main.Handle
$lastTick = [Environment]::TickCount

while (-not $script:isExiting) {
    if ($script:hotkeyEnabled) {
        $modVal = 0
        if ($script:hotkeyModifier -eq "Ctrl") { $modVal = 0x11 }
        elseif ($script:hotkeyModifier -eq "Alt") { $modVal = 0x12 }
        elseif ($script:hotkeyModifier -eq "Shift") { $modVal = 0x10 }
        
        $keyVal = [int][char]$script:hotkeyChar
        
        if (($Win32Functions::GetAsyncKeyState($modVal) -band 0x8000) -and ($Win32Functions::GetAsyncKeyState($keyVal) -band 0x8000)) {
            Write-Log "Global Hotkey detected. Opening save directory."
            Open-TargetFolder | Out-Null
            Start-Sleep -Seconds 1
        }
    }

    $currentTick = [Environment]::TickCount
    if ($currentTick - $lastTick -gt 200) {
        if (-not $script:stopMonitor -and [System.Windows.Forms.Clipboard]::ContainsImage()) {
            try {
                $img = [System.Windows.Forms.Clipboard]::GetImage()
                $currentHash = Get-ImageHash $img
                if ($currentHash -ne $script:lastSavedHash) {
                    $timestamp = Get-Date -f 'dddd-MM-yyyy-HHmmss'
                    
                    if (-not (Test-Path $script:saveDirectory)) { New-Item -ItemType Directory -Path $script:saveDirectory -Force | Out-Null }
                    
                    $saved = $false
                    if ($script:supportedExtensions.Count -gt 0) {
                        $ext = $script:supportedExtensions[0]
                        $fileName = "$timestamp-Clip$ext"
                        $savePath = Join-Path $script:saveDirectory $fileName
                        $format = Get-ImageFormatFromExtension $ext
                        $img.Save($savePath, $format)
                        $saved = $true
                    } else {
                        $fileName = "$timestamp-Clip.bmp"
                        $savePath = Join-Path $script:saveDirectory $fileName
                        $img.Save($savePath, [System.Drawing.Imaging.ImageFormat]::Bmp)
                        $saved = $true
                    }
                    
                    if ($saved) {
                        $script:lastSavedHash = $currentHash
                        Write-Log "Acquired target: $fileName"
                        
                        if ($script:showBalloons) {
                            $script:trayIcon.ShowBalloonTip(3000, "Image Saved", "Acquired target: $fileName", [System.Windows.Forms.ToolTipIcon]::Info)
                        }
                        
                        if (-not $script:isMuted) {
                            $regSound = "HKCU:\AppEvents\Schemes\Apps\ClipboardImageSaver\ClipboardImageSaver\.Current"
                            $cpSound = (Get-ItemProperty -Path $regSound -ErrorAction SilentlyContinue)."(default)"
                            if ($cpSound -and (Test-Path $cpSound)) {
                                try { $player = New-Object System.Media.SoundPlayer($cpSound); $player.Play() } catch {}
                            } elseif (Test-Path $script:soundPath) {
                                try { $player = New-Object System.Media.SoundPlayer($script:soundPath); $player.Play() } catch {}
                            }
                        }
                    }
                }
                $img.Dispose()
            } catch { }
        }
        $lastTick = $currentTick
    }

    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 10
}

# Cleanup
$script:trayIcon.Visible = $false
$script:trayIcon.Dispose()
$frm_Main.Dispose()
#endregion