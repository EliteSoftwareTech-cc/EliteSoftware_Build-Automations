<#
.SYNOPSIS
    PsExec64 Drop Target Launcher
.DESCRIPTION
    A comprehensive legacy-styled WinForms frontend for launching executables via PsExec64 as SYSTEM, featuring a Vista Aero gradient, scope selection, and high-fidelity icons.
.VERSION
    1.2.0.0
.AUTHOR
    EliteSoftwareTech Co - Zachary Whiteman - Susan Gemm - TheShadyRainbow4
#>

# ==============================================================================
# #region Initialization & Logging
# ==============================================================================
$ErrorActionPreference = "Stop"

# Single Instance Check
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, "Global\PsExec64-Launcher-EliteSoftware", [ref]$createdNew)
if (-not $createdNew) {
    Add-Type -AssemblyName System.Windows.Forms
    $res = [System.Windows.Forms.MessageBox]::Show("Another instance of this launcher is already running. Do you want to close it and continue?", "Instance Already Running", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
        $currentProcName = [System.Diagnostics.Process]::GetCurrentProcess().ProcessName
        Get-Process -Name $currentProcName -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $PID } | Stop-Process -Force
        Start-Sleep -Milliseconds 500
    } else {
        exit
    }
}

$ToolName = "PsExecDropTarget"
$LogDir = "$env:SystemDrive\EliteSoftware\Logs"
$LogFile = "$LogDir\$ToolName.log"

if (-not (Test-Path $LogDir)) {
    try {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    } catch { }
}

function Write-Log {
    param(
        [string]$Message,
        [string]$ErrorCode = "0x00000000",
        [bool]$IsError = $false
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Spaced-out double-newline logging updates
    $LogEntry = "`r`n[$Timestamp] [$ErrorCode] $Message`r`n"
    if ($IsError) {
        $LogEntry = "`r`n[$Timestamp] [ERROR: $ErrorCode] $Message`r`n"
    }
    try {
        Add-Content -Path $LogFile -Value $LogEntry
    } catch { }
}

Write-Log "Initializing $ToolName Boot Sequence (Vista Aero Paint Update)." "0x00000001"

$CurrentPath = $MyInvocation.MyCommand.Path
$IsCompiled = $false
if (-not $CurrentPath) {
    $CurrentPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $IsCompiled = $true
}
$ScriptDir = [System.IO.Path]::GetDirectoryName($CurrentPath)
#endregion

# ==============================================================================
# #region Settings & Persistence
# ==============================================================================
$SettingsPath = Join-Path $ScriptDir "PsExec64-Launcher.xml"

$script:Settings = @{
    History = [System.Collections.ArrayList]@()
    Credentials = @{} # Username -> Password
    Favorites = [System.Collections.ArrayList]@()
    LastScope = "NT AUTHORITY\SYSTEM"
    LastUser = ""
    LastPass = ""
    LastInteractive = $true
    LastNoPassword = $false
}

$script:ToolbarIconSize = 24
$script:AlwaysOnTop = $true
$script:MinimizeToTrayOnClose = $false
$script:ShowTooltips = $true
$script:WindowOpacity = 100
$script:BannerTheme = "Vista Teal"
$script:StayOpenOnExecution = $true
$script:LaunchCount = 0

function Load-Settings {
    $xmlContent = $null
    try { $xmlContent = (Get-ItemProperty "HKCU:\SOFTWARE\EliteSoftware\PsExecLauncher" -Name "SettingsXML" -ErrorAction Stop).SettingsXML; $script:SaveLocation = "Registry (Current User)" } catch {}
    if (-not $xmlContent) { try { $xmlContent = (Get-ItemProperty "HKLM:\SOFTWARE\EliteSoftware\PsExecLauncher" -Name "SettingsXML" -ErrorAction Stop).SettingsXML; $script:SaveLocation = "Registry (Local Machine)" } catch {} }
    if (-not $xmlContent -and (Test-Path $SettingsPath)) { try { $xmlContent = Get-Content $SettingsPath -Raw -ErrorAction Stop; $script:SaveLocation = "XML File" } catch {} }
    if (-not $script:SaveLocation) { $script:SaveLocation = "XML File" }
    
    if ($xmlContent) {
        try {
            [xml]$xml = $xmlContent
            
            # Load History
            if ($xml.Settings.History) {
                foreach ($item in $xml.Settings.History.Command) {
                    if ($item -and $script:Settings.History -notcontains $item) {
                        [void]$script:Settings.History.Add($item)
                    }
                }
            }
            
            # Load Credentials
            if ($xml.Settings.Credentials) {
                foreach ($cred in $xml.Settings.Credentials.Credential) {
                    if ($cred.Username) {
                        $script:Settings.Credentials[$cred.Username] = $cred.Password
                    }
                }
            }
            
            # Load Favorites
            if ($xml.Settings.Favorites) {
                foreach ($fav in $xml.Settings.Favorites.Favorite) {
                    $favObj = [PSCustomObject]@{
                        Title = $fav.Title
                        Description = $fav.Description
                        Path = $fav.Path
                        Args = $fav.Args
                        WorkingDir = $fav.WorkingDir
                        Scope = $fav.Scope
                        User = $fav.User
                        Pass = $fav.Pass
                        Interactive = [System.Convert]::ToBoolean($fav.Interactive)
                        NoPassword = [System.Convert]::ToBoolean($fav.NoPassword)
                    }
                    [void]$script:Settings.Favorites.Add($favObj)
                }
            }
            
            # Load Last Settings
            if ($xml.Settings.LastSettings) {
                if ($xml.Settings.LastSettings.Scope) { $script:Settings.LastScope = $xml.Settings.LastSettings.Scope }
                if ($xml.Settings.LastSettings.User) { $script:Settings.LastUser = $xml.Settings.LastSettings.User }
                if ($xml.Settings.LastSettings.Pass) { $script:Settings.LastPass = $xml.Settings.LastSettings.Pass }
                if ($xml.Settings.LastSettings.Interactive) { $script:Settings.LastInteractive = [System.Convert]::ToBoolean($xml.Settings.LastSettings.Interactive) }
                if ($xml.Settings.LastSettings.NoPassword) { $script:Settings.LastNoPassword = [System.Convert]::ToBoolean($xml.Settings.LastSettings.NoPassword) }
                if ($xml.Settings.LastSettings.ToolbarIconSize) { $script:ToolbarIconSize = [int]$xml.Settings.LastSettings.ToolbarIconSize }
                if ($xml.Settings.LastSettings.AlwaysOnTop) { $script:AlwaysOnTop = [System.Convert]::ToBoolean($xml.Settings.LastSettings.AlwaysOnTop) }
                if ($xml.Settings.LastSettings.MinimizeToTrayOnClose) { $script:MinimizeToTrayOnClose = [System.Convert]::ToBoolean($xml.Settings.LastSettings.MinimizeToTrayOnClose) }
                if ($xml.Settings.LastSettings.ShowTooltips) { $script:ShowTooltips = [System.Convert]::ToBoolean($xml.Settings.LastSettings.ShowTooltips) }
                if ($xml.Settings.LastSettings.StayOpenOnExecution) { $script:StayOpenOnExecution = [System.Convert]::ToBoolean($xml.Settings.LastSettings.StayOpenOnExecution) }
                if ($xml.Settings.LastSettings.WindowOpacity) { $script:WindowOpacity = [int]$xml.Settings.LastSettings.WindowOpacity }
                if ($xml.Settings.LastSettings.BannerTheme) { $script:BannerTheme = $xml.Settings.LastSettings.BannerTheme }
            }
        } catch {
            Write-Log "Failed to load settings: $($_.Exception.Message)" "0xE0000020" $true
        }
    } else {
        # Prepopulate default favorites for premium feel on first launch
        $defaultFavs = @(
            [PSCustomObject]@{
                Title = "System Command Prompt"
                Description = "Launch an interactive Cmd Shell under NT AUTHORITY\SYSTEM context."
                Path = "cmd.exe"
                Args = ""
                WorkingDir = $ScriptDir
                Scope = "NT AUTHORITY\SYSTEM"
                User = ""
                Pass = ""
                Interactive = $true
                NoPassword = $false
            },
            [PSCustomObject]@{
                Title = "Registry Editor (SYSTEM)"
                Description = "Launch Registry Editor under NT AUTHORITY\SYSTEM to access system-protected keys."
                Path = "regedit.exe"
                Args = ""
                WorkingDir = $ScriptDir
                Scope = "NT AUTHORITY\SYSTEM"
                User = ""
                Pass = ""
                Interactive = $true
                NoPassword = $false
            }
        )
        foreach ($f in $defaultFavs) {
            [void]$script:Settings.Favorites.Add($f)
        }
        Save-Settings
    }
}

function Save-Settings {
    try {
        $xmlDoc = New-Object System.Xml.XmlDocument
        $xmlDeclaration = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)
        [void]$xmlDoc.AppendChild($xmlDeclaration)
        
        $root = $xmlDoc.CreateElement("Settings")
        [void]$xmlDoc.AppendChild($root)
        
        # Save History
        $histNode = $xmlDoc.CreateElement("History")
        foreach ($cmd in $script:Settings.History) {
            $cmdNode = $xmlDoc.CreateElement("Command")
            $cmdNode.InnerText = $cmd
            [void]$histNode.AppendChild($cmdNode)
        }
        [void]$root.AppendChild($histNode)
        
        # Save Credentials
        $credsNode = $xmlDoc.CreateElement("Credentials")
        foreach ($key in $script:Settings.Credentials.Keys) {
            $credNode = $xmlDoc.CreateElement("Credential")
            
            $uNode = $xmlDoc.CreateElement("Username")
            $uNode.InnerText = $key
            [void]$credNode.AppendChild($uNode)
            
            $pNode = $xmlDoc.CreateElement("Password")
            $pNode.InnerText = $script:Settings.Credentials[$key]
            [void]$credNode.AppendChild($pNode)
            
            [void]$credsNode.AppendChild($credNode)
        }
        [void]$root.AppendChild($credsNode)
        
        # Save Favorites
        $favsNode = $xmlDoc.CreateElement("Favorites")
        foreach ($fav in $script:Settings.Favorites) {
            $favNode = $xmlDoc.CreateElement("Favorite")
            
            $tNode = $xmlDoc.CreateElement("Title"); $tNode.InnerText = $fav.Title; [void]$favNode.AppendChild($tNode)
            $dNode = $xmlDoc.CreateElement("Description"); $dNode.InnerText = $fav.Description; [void]$favNode.AppendChild($dNode)
            $pNode = $xmlDoc.CreateElement("Path"); $pNode.InnerText = $fav.Path; [void]$favNode.AppendChild($pNode)
            $aNode = $xmlDoc.CreateElement("Args"); $aNode.InnerText = $fav.Args; [void]$favNode.AppendChild($aNode)
            $wNode = $xmlDoc.CreateElement("WorkingDir"); $wNode.InnerText = $fav.WorkingDir; [void]$favNode.AppendChild($wNode)
            $sNode = $xmlDoc.CreateElement("Scope"); $sNode.InnerText = $fav.Scope; [void]$favNode.AppendChild($sNode)
            $uNode = $xmlDoc.CreateElement("User"); $uNode.InnerText = $fav.User; [void]$favNode.AppendChild($uNode)
            $psNode = $xmlDoc.CreateElement("Pass"); $psNode.InnerText = $fav.Pass; [void]$favNode.AppendChild($psNode)
            
            $iNode = $xmlDoc.CreateElement("Interactive")
            $iNode.InnerText = $fav.Interactive.ToString().ToLower()
            [void]$favNode.AppendChild($iNode)
            
            $npNode = $xmlDoc.CreateElement("NoPassword")
            $npNode.InnerText = $fav.NoPassword.ToString().ToLower()
            [void]$favNode.AppendChild($npNode)
            
            [void]$favsNode.AppendChild($favNode)
        }
        [void]$root.AppendChild($favsNode)
        
        # Save Last Settings
        $lastNode = $xmlDoc.CreateElement("LastSettings")
        
        $sNode = $xmlDoc.CreateElement("Scope"); $sNode.InnerText = $script:Settings.LastScope; [void]$lastNode.AppendChild($sNode)
        $uNode = $xmlDoc.CreateElement("User"); $uNode.InnerText = $script:Settings.LastUser; [void]$lastNode.AppendChild($uNode)
        $pNode = $xmlDoc.CreateElement("Pass"); $pNode.InnerText = $script:Settings.LastPass; [void]$lastNode.AppendChild($pNode)
        
        $iNode = $xmlDoc.CreateElement("Interactive")
        $iNode.InnerText = $script:Settings.LastInteractive.ToString().ToLower()
        [void]$lastNode.AppendChild($iNode)
        
        $npNode = $xmlDoc.CreateElement("NoPassword")
        $npNode.InnerText = $script:Settings.LastNoPassword.ToString().ToLower()
        [void]$lastNode.AppendChild($npNode)
        
        $pdNode = $xmlDoc.CreateElement("ArtificialDelay")
        $currentDelay = "500"
        if ($script:Settings.LastSettings -and $script:Settings.LastSettings.ArtificialDelay) {
            $currentDelay = $script:Settings.LastSettings.ArtificialDelay
        }
        $pdNode.InnerText = $currentDelay
        [void]$lastNode.AppendChild($pdNode)
        
        $isNode = $xmlDoc.CreateElement("ToolbarIconSize")
        $isNode.InnerText = $script:ToolbarIconSize.ToString()
        [void]$lastNode.AppendChild($isNode)
        
        $aotNode = $xmlDoc.CreateElement("AlwaysOnTop")
        $aotNode.InnerText = $script:AlwaysOnTop.ToString().ToLower()
        [void]$lastNode.AppendChild($aotNode)
        
        $stayNode = $xmlDoc.CreateElement("StayOpenOnExecution")
        $stayNode.InnerText = $script:StayOpenOnExecution.ToString().ToLower()
        [void]$lastNode.AppendChild($stayNode)
        
        $mtNode = $xmlDoc.CreateElement("MinimizeToTrayOnClose")
        $mtNode.InnerText = $script:MinimizeToTrayOnClose.ToString().ToLower()
        [void]$lastNode.AppendChild($mtNode)
        
        $stNode = $xmlDoc.CreateElement("ShowTooltips")
        $stNode.InnerText = $script:ShowTooltips.ToString().ToLower()
        [void]$lastNode.AppendChild($stNode)
        
        $woNode = $xmlDoc.CreateElement("WindowOpacity")
        $woNode.InnerText = $script:WindowOpacity.ToString()
        [void]$lastNode.AppendChild($woNode)
        
        $btNode = $xmlDoc.CreateElement("BannerTheme")
        $btNode.InnerText = $script:BannerTheme
        [void]$lastNode.AppendChild($btNode)
        
        [void]$root.AppendChild($lastNode)
        
        $xmlString = $xmlDoc.OuterXml
        if ($script:SaveLocation -eq "Registry (Current User)") {
            $path = "HKCU:\SOFTWARE\EliteSoftware\PsExecLauncher"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "SettingsXML" -Value $xmlString -Force
        } elseif ($script:SaveLocation -eq "Registry (Local Machine)") {
            $path = "HKLM:\SOFTWARE\EliteSoftware\PsExecLauncher"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "SettingsXML" -Value $xmlString -Force
        } else {
            $xmlDoc.Save($SettingsPath)
        }
    } catch {
        Write-Log "Failed to save settings: $($_.Exception.Message)" "0xE0000021" $true
    }
}

function Apply-Settings-To-UI {
    if ($script:PendingDropFile) {
        $frm_Main.Opacity = 0
        $frm_Main.ShowInTaskbar = $false
        $frm_Main.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    } else {
        $frm_Main.TopMost = $script:AlwaysOnTop
        $frm_Main.Opacity = $script:WindowOpacity / 100.0
        $frm_Main.ShowInTaskbar = $true
    }
    $ToolTip.Active = $script:ShowTooltips
    if ($lbl_CurrentTheme) {
        $lbl_CurrentTheme.Text = "Theme: $script:BannerTheme"
    }
    if ($script:BannerTheme -eq "Classic Silver") {
        $botCol = [System.Drawing.Color]::FromArgb(255, 220, 225, 230)
    } elseif ($script:BannerTheme -eq "Steel Blue") {
        $botCol = [System.Drawing.Color]::FromArgb(255, 175, 195, 225)
    } else {
        $botCol = [System.Drawing.Color]::FromArgb(255, 175, 215, 225) 
    }
    if ($BannerPanel) {
        $BannerPanel.BackgroundImage = Get-GradientBmp $botCol 65
    }
    $frm_Main.Refresh()
}
#endregion

# ==============================================================================
# #region PsExec & Resolution Logic
# ==============================================================================
$PsExecPath = Join-Path $ScriptDir "psexec64.exe"
if (-not (Test-Path $PsExecPath)) {
    $SysPath = (Get-Command "psexec64.exe" -ErrorAction SilentlyContinue).Source
    if ($SysPath) {
        $PsExecPath = $SysPath
    }
}

function Resolve-CommandPath {
    param(
        [string]$Command
    )
    $Command = $Command.Trim()
    if ([string]::IsNullOrWhiteSpace($Command)) {
        return $null
    }
    
    $Extensions = @("", ".exe", ".cmd", ".bat", ".ps1", ".lnk", ".com")
    
    # 1. Absolute or relative path check
    foreach ($ext in $Extensions) {
        $testPath = $Command + $ext
        if (Test-Path $testPath) {
            return [System.IO.Path]::GetFullPath($testPath)
        }
    }
    
    # 2. Check script directory
    foreach ($ext in $Extensions) {
        $testPath = Join-Path $ScriptDir ($Command + $ext)
        if (Test-Path $testPath) {
            return $testPath
        }
    }
    
    # 3. Check system PATH
    $EnvPaths = $env:PATH -split ";"
    foreach ($p in $EnvPaths) {
        if (-not [string]::IsNullOrWhiteSpace($p)) {
            foreach ($ext in $Extensions) {
                try {
                    $testPath = Join-Path $p ($Command + $ext)
                    if (Test-Path $testPath) {
                        return $testPath
                    }
                } catch {}
            }
        }
    }
    
    # 4. Fallback search in standard system directories
    $WinDir = $env:SystemRoot
    $DirsToSearch = @(Join-Path $WinDir "System32", Join-Path $WinDir "SysWOW64", $WinDir)
    foreach ($d in $DirsToSearch) {
        if (Test-Path $d) {
            foreach ($ext in $Extensions) {
                $testPath = Join-Path $d ($Command + $ext)
                if (Test-Path $testPath) {
                    return $testPath
                }
            }
        }
    }
    
    return $null
}

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

function Get-TileBmp {
    param([bool]$Hover, [int]$w = 218, [int]$h = 82)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rad = 5
    $path.AddArc(0, 0, $rad*2, $rad*2, 180, 90)
    $path.AddArc($w - $rad*2 - 1, 0, $rad*2, $rad*2, 270, 90)
    $path.AddArc($w - $rad*2 - 1, $h - $rad*2 - 1, $rad*2, $rad*2, 0, 90)
    $path.AddArc(0, $h - $rad*2 - 1, $rad*2, $rad*2, 90, 90)
    $path.CloseFigure()
    
    if ($Hover) {
        $topH = [System.Drawing.Color]::FromArgb(120, 252, 253, 254)
        $botH = [System.Drawing.Color]::FromArgb(120, 229, 243, 251)
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $topH, $botH, [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
        $g.FillPath($brush, $path)
        $brush.Dispose()
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 112, 192, 231))
        $g.DrawPath($pen, $path)
        $pen.Dispose()
    } else {
        $g.Clear([System.Drawing.Color]::FromArgb(255, 251, 251, 251))
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 0, 0, 0))
        $g.DrawPath($pen, $path)
        $pen.Dispose()
    }
    $path.Dispose()
    $g.Dispose()
    return $bmp
}


# INSTANT DROP TARGET LOGIC (GUI Bypass to Tray)
$script:PendingDropFile = $null
$script:PendingUseNTAS = $false

if ($args.Count -gt 0) {
    foreach ($arg in $args) {
        if ($arg -eq "//NTAS") {
            $script:PendingUseNTAS = $true
        } elseif (Test-Path $arg) {
            $script:PendingDropFile = $arg
        }
    }
    
    if (-not $script:PendingDropFile -and (Test-Path $args[0])) {
        $script:PendingDropFile = $args[0]
    }
}
#endregion

# ==============================================================================
# #region Assemblies & Environment
# ==============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

$ScriptBaseName = [System.IO.Path]::GetFileNameWithoutExtension($CurrentPath)
$IconPath = Join-Path $ScriptDir "$ScriptBaseName.ico"

# Fonts
$BaseFontName = "Segoe UI"
$StandardFont = New-Object System.Drawing.Font($BaseFontName, 9, [System.Drawing.FontStyle]::Regular)
$SemiboldFont = New-Object System.Drawing.Font($BaseFontName, 9, [System.Drawing.FontStyle]::Bold)
$TitleFont = New-Object System.Drawing.Font($BaseFontName, 12, [System.Drawing.FontStyle]::Bold)

# Win32 API for extracting index icons from system DLLs
$Signature = @"
[DllImport("shell32.dll", CharSet = CharSet.Auto)]
public static extern int ExtractIconEx(string lpszFile, int nIconIndex, IntPtr[] phiconLarge, IntPtr[] phiconSmall, int nIcons);
"@
Add-Type -MemberDefinition $Signature -Name "Shell32Icons" -Namespace "Win32" -ErrorAction SilentlyContinue
#endregion

# ==============================================================================
# #region UI Generation
# ==============================================================================
$frm_Main = New-Object System.Windows.Forms.Form
$frm_Main.Text = "EliteSoftware PsExec Launcher"
$frm_Main.Size = New-Object System.Drawing.Size(540, 580)
$frm_Main.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$frm_Main.MinimizeBox = $false   # Only X button shown on titlebar
$frm_Main.MaximizeBox = $false   # Only X button shown on titlebar
$frm_Main.TopMost = $true        # Window remains on top of all other windows
$frm_Main.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$frm_Main.Font = $StandardFont

$AppIcon = $null
if (Test-Path $IconPath) {
    try {
        $AppIcon = New-Object System.Drawing.Icon($IconPath, 48, 48)
        $frm_Main.Icon = $AppIcon
    } catch {
        Write-Log "Icon file exists but failed to extract 48x48 frame." "0xE0000012" $true
    }
} elseif ($IsCompiled) {
    $AppIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($CurrentPath)
    $frm_Main.Icon = $AppIcon
}

$ToolTip = New-Object System.Windows.Forms.ToolTip

# Extract shell32 system icons
function Get-Shell32Icon {
    param([int]$Index)
    try {
        $large = New-Object IntPtr[] 1
        $small = New-Object IntPtr[] 1
        $res = [Win32.Shell32Icons]::ExtractIconEx("shell32.dll", $Index, $large, $small, 1)
        if ($large[0] -ne [IntPtr]::Zero) {
            $icon = [System.Drawing.Icon]::FromHandle($large[0])
            $bmp = $icon.ToBitmap()
            return $bmp
        }
    } catch {}
    return $null
}

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

function Get-TileBmp {
    param([bool]$Hover, [int]$w = 218, [int]$h = 82)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rad = 5
    $path.AddArc(0, 0, $rad*2, $rad*2, 180, 90)
    $path.AddArc($w - $rad*2 - 1, 0, $rad*2, $rad*2, 270, 90)
    $path.AddArc($w - $rad*2 - 1, $h - $rad*2 - 1, $rad*2, $rad*2, 0, 90)
    $path.AddArc(0, $h - $rad*2 - 1, $rad*2, $rad*2, 90, 90)
    $path.CloseFigure()
    
    if ($Hover) {
        $topH = [System.Drawing.Color]::FromArgb(120, 252, 253, 254)
        $botH = [System.Drawing.Color]::FromArgb(120, 229, 243, 251)
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $topH, $botH, [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
        $g.FillPath($brush, $path)
        $brush.Dispose()
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 112, 192, 231))
        $g.DrawPath($pen, $path)
        $pen.Dispose()
    } else {
        $g.Clear([System.Drawing.Color]::FromArgb(255, 251, 251, 251))
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 0, 0, 0))
        $g.DrawPath($pen, $path)
        $pen.Dispose()
    }
    $path.Dispose()
    $g.Dispose()
    return $bmp
}


# Extract large native file icons from executables
function Get-FileIcon {
    param([string]$FilePath)
    try {
        $large = New-Object IntPtr[] 1
        $small = New-Object IntPtr[] 1
        $res = [Win32.Shell32Icons]::ExtractIconEx($FilePath, 0, $large, $small, 1)
        if ($large[0] -ne [IntPtr]::Zero) {
            $icon = [System.Drawing.Icon]::FromHandle($large[0])
            $bmp = $icon.ToBitmap()
            return $bmp
        }
    } catch {}
    return $null
}

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

function Get-TileBmp {
    param([bool]$Hover, [int]$w = 218, [int]$h = 82)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rad = 5
    $path.AddArc(0, 0, $rad*2, $rad*2, 180, 90)
    $path.AddArc($w - $rad*2 - 1, 0, $rad*2, $rad*2, 270, 90)
    $path.AddArc($w - $rad*2 - 1, $h - $rad*2 - 1, $rad*2, $rad*2, 0, 90)
    $path.AddArc(0, $h - $rad*2 - 1, $rad*2, $rad*2, 90, 90)
    $path.CloseFigure()
    
    if ($Hover) {
        $topH = [System.Drawing.Color]::FromArgb(120, 252, 253, 254)
        $botH = [System.Drawing.Color]::FromArgb(120, 229, 243, 251)
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $topH, $botH, [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
        $g.FillPath($brush, $path)
        $brush.Dispose()
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 112, 192, 231))
        $g.DrawPath($pen, $path)
        $pen.Dispose()
    } else {
        $g.Clear([System.Drawing.Color]::FromArgb(255, 251, 251, 251))
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 0, 0, 0))
        $g.DrawPath($pen, $path)
        $pen.Dispose()
    }
    $path.Dispose()
    $g.Dispose()
    return $bmp
}


# Return native system icons directly
function Get-ToolIcon {
    param([string]$Type)
    if ($Type -eq "Run") {
        return [System.Drawing.SystemIcons]::Shield.ToBitmap()
    } elseif ($Type -eq "Favorite") {
        # Native Quick Access gold star from shell32.dll index 43
        $star = Get-Shell32Icon 43
        if ($star) { return $star }
        return [System.Drawing.SystemIcons]::Asterisk.ToBitmap()
    } elseif ($Type -eq "Settings") {
        $cp = Get-Shell32Icon 21
        if ($cp) { return $cp }
        return [System.Drawing.SystemIcons]::Application.ToBitmap()
    } elseif ($Type -eq "Help") {
        return [System.Drawing.SystemIcons]::Question.ToBitmap()
    }
    return $null
}

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

function Get-TileBmp {
    param([bool]$Hover, [int]$w = 218, [int]$h = 82)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rad = 5
    $path.AddArc(0, 0, $rad*2, $rad*2, 180, 90)
    $path.AddArc($w - $rad*2 - 1, 0, $rad*2, $rad*2, 270, 90)
    $path.AddArc($w - $rad*2 - 1, $h - $rad*2 - 1, $rad*2, $rad*2, 0, 90)
    $path.AddArc(0, $h - $rad*2 - 1, $rad*2, $rad*2, 90, 90)
    $path.CloseFigure()
    
    if ($Hover) {
        $topH = [System.Drawing.Color]::FromArgb(120, 252, 253, 254)
        $botH = [System.Drawing.Color]::FromArgb(120, 229, 243, 251)
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $topH, $botH, [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
        $g.FillPath($brush, $path)
        $brush.Dispose()
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 112, 192, 231))
        $g.DrawPath($pen, $path)
        $pen.Dispose()
    } else {
        $g.Clear([System.Drawing.Color]::FromArgb(255, 251, 251, 251))
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 0, 0, 0))
        $g.DrawPath($pen, $path)
        $pen.Dispose()
    }
    $path.Dispose()
    $g.Dispose()
    return $bmp
}


# --- Menubar (MenuStrip) ---
$menu_Main = New-Object System.Windows.Forms.MenuStrip
$menu_Main.Dock = [System.Windows.Forms.DockStyle]::Top
$menu_Main.RenderMode = [System.Windows.Forms.ToolStripRenderMode]::System

$menuFile = $menu_Main.Items.Add("File")
$menuFile_RunAs = New-Object System.Windows.Forms.ToolStripMenuItem("Run As...")
$menuFile_RunAs_System = $menuFile_RunAs.DropDownItems.Add("NT AUTHORITY\SYSTEM")
$menuFile_RunAs_Admin = $menuFile_RunAs.DropDownItems.Add("Administrator")
$menuFile.DropDownItems.Add($menuFile_RunAs) | Out-Null

$menuFile_ClearHist = $menuFile.DropDownItems.Add("Clear History")
$menuFile.DropDownItems.Add("-") | Out-Null
$menuFile_Tray = $menuFile.DropDownItems.Add("Minimize to Tray")
$menuFile.DropDownItems.Add("-") | Out-Null
$menuFile_Exit = $menuFile.DropDownItems.Add("Exit")

$menuSettings = $menu_Main.Items.Add("Settings")
$menuSettings_Theme = New-Object System.Windows.Forms.ToolStripMenuItem("Banner Color Theme")
$menuSettings_Theme_Teal = $menuSettings_Theme.DropDownItems.Add("Vista Teal")
$menuSettings_Theme_Silver = $menuSettings_Theme.DropDownItems.Add("Classic Silver")
$menuSettings_Theme_Blue = $menuSettings_Theme.DropDownItems.Add("Steel Blue")
$menuSettings.DropDownItems.Add($menuSettings_Theme) | Out-Null

$menuSettings_Opacity = New-Object System.Windows.Forms.ToolStripMenuItem("Window Opacity")
$menuSettings_Opacity_100 = $menuSettings_Opacity.DropDownItems.Add("100%")
$menuSettings_Opacity_90 = $menuSettings_Opacity.DropDownItems.Add("90%")
$menuSettings_Opacity_80 = $menuSettings_Opacity.DropDownItems.Add("80%")
$menuSettings_Opacity_70 = $menuSettings_Opacity.DropDownItems.Add("70%")
$menuSettings.DropDownItems.Add($menuSettings_Opacity) | Out-Null

$menuSettings.DropDownItems.Add("-") | Out-Null
$menuSettings_Configure = $menuSettings.DropDownItems.Add("Configure...")

$menuHelp = $menu_Main.Items.Add("Help")
$menuHelp_Website = $menuHelp.DropDownItems.Add("EliteSoftware Website")
$menuHelp_Logs = $menuHelp.DropDownItems.Add("View Launcher Logs")
$menuHelp.DropDownItems.Add("-") | Out-Null
$menuHelp_Guidance = $menuHelp.DropDownItems.Add("User Manual")
$menuHelp_About = $menuHelp.DropDownItems.Add("About")

# --- Toolbar (ToolStrip) ---
$tool_Main = New-Object System.Windows.Forms.ToolStrip
$tool_Main.Dock = [System.Windows.Forms.DockStyle]::Top
$tool_Main.GripStyle = [System.Windows.Forms.ToolStripGripStyle]::Hidden # Removed triple dot grab handle
$tool_Main.RenderMode = [System.Windows.Forms.ToolStripRenderMode]::System

$btn_ToolRun = New-Object System.Windows.Forms.ToolStripButton
$btn_ToolRun.Text = "Execute"
$btn_ToolRun.Image = Get-ToolIcon "Run"
$btn_ToolRun.DisplayStyle = [System.Windows.Forms.ToolStripItemDisplayStyle]::ImageAndText
$tool_Main.Items.Add($btn_ToolRun) | Out-Null

$btn_ToolFav = New-Object System.Windows.Forms.ToolStripButton
$btn_ToolFav.Text = "Pin Favorite"
$btn_ToolFav.Image = Get-ToolIcon "Favorite"
$btn_ToolFav.DisplayStyle = [System.Windows.Forms.ToolStripItemDisplayStyle]::ImageAndText
$tool_Main.Items.Add($btn_ToolFav) | Out-Null

$tool_Main.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

$btn_ToolSettings = New-Object System.Windows.Forms.ToolStripButton
$btn_ToolSettings.Image = Get-ToolIcon "Settings"
$btn_ToolSettings.DisplayStyle = [System.Windows.Forms.ToolStripItemDisplayStyle]::Image
$tool_Main.Items.Add($btn_ToolSettings) | Out-Null

$btn_ToolHelp = New-Object System.Windows.Forms.ToolStripButton
$btn_ToolHelp.Text = "Help"
$btn_ToolHelp.Image = Get-ToolIcon "Help"
$btn_ToolHelp.DisplayStyle = [System.Windows.Forms.ToolStripItemDisplayStyle]::ImageAndText
$btn_ToolHelp.Alignment = [System.Windows.Forms.ToolStripItemAlignment]::Right
$tool_Main.Items.Add($btn_ToolHelp) | Out-Null

# --- Top Banner Panel (Vista Teal Gradient) ---
$BannerPanel = New-Object System.Windows.Forms.Panel
$BannerPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$BannerPanel.Height = 65

    if ($script:BannerTheme -eq "Classic Silver") {
        $botCol = [System.Drawing.Color]::FromArgb(255, 220, 225, 230)
    } elseif ($script:BannerTheme -eq "Steel Blue") {
        $botCol = [System.Drawing.Color]::FromArgb(255, 175, 195, 225)
    } else {
        $botCol = [System.Drawing.Color]::FromArgb(255, 175, 215, 225) 
    }
    $BannerPanel.BackgroundImage = Get-GradientBmp $botCol 65
    $BannerPanel.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Stretch

$lbl_TitleBanner = New-Object System.Windows.Forms.Label
$lbl_TitleBanner.Text = "System Context Launcher"
$lbl_TitleBanner.Font = $TitleFont
$lbl_TitleBanner.Location = New-Object System.Drawing.Point(15, 10)
$lbl_TitleBanner.AutoSize = $true
$lbl_TitleBanner.BackColor = [System.Drawing.Color]::Transparent
$ToolTip.SetToolTip($lbl_TitleBanner, "You are entering the NT AUTHORITY realm. Tread lightly.")
$BannerPanel.Controls.Add($lbl_TitleBanner)

$SubTitleLabel = New-Object System.Windows.Forms.Label
$SubTitleLabel.Text = "Select or drop a target executable to launch with elevated parameters."
$SubTitleLabel.Location = New-Object System.Drawing.Point(18, 35)
$SubTitleLabel.AutoSize = $true
$SubTitleLabel.BackColor = [System.Drawing.Color]::Transparent
$BannerPanel.Controls.Add($SubTitleLabel)

if ($AppIcon) {
    $BannerIcon = New-Object System.Windows.Forms.PictureBox
    $BannerIcon.Size = New-Object System.Drawing.Size(48, 48)
    $BannerIcon.Location = New-Object System.Drawing.Point(460, 8)
    $BannerIcon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::CenterImage
    $BannerIcon.Image = $AppIcon.ToBitmap()
    $BannerIcon.BackColor = [System.Drawing.Color]::Transparent
    $BannerPanel.Controls.Add($BannerIcon)
}

$BannerDivider = New-Object System.Windows.Forms.Label
$BannerDivider.BackColor = [System.Drawing.SystemColors]::ControlDark
$BannerDivider.Height = 1
$BannerDivider.Dock = [System.Windows.Forms.DockStyle]::Bottom
$BannerPanel.Controls.Add($BannerDivider)

# --- Statusbar (StatusStrip) ---
$status_Main = New-Object System.Windows.Forms.StatusStrip
$status_Main.Dock = [System.Windows.Forms.DockStyle]::Bottom
$status_Main.RenderMode = [System.Windows.Forms.ToolStripRenderMode]::System

$lbl_Status = New-Object System.Windows.Forms.ToolStripStatusLabel
$lbl_Status.Text = "Ready"
$lbl_Status.Spring = $true
$lbl_Status.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$status_Main.Items.Add($lbl_Status) | Out-Null

$lbl_SessionLaunches = New-Object System.Windows.Forms.ToolStripStatusLabel
$lbl_SessionLaunches.Text = "Launches: 0"
$lbl_SessionLaunches.BorderSides = [System.Windows.Forms.ToolStripStatusLabelBorderSides]::Left
$lbl_SessionLaunches.BorderStyle = [System.Windows.Forms.Border3DStyle]::SunkenOuter
$lbl_SessionLaunches.Padding = New-Object System.Windows.Forms.Padding(5, 0, 5, 0)
$status_Main.Items.Add($lbl_SessionLaunches) | Out-Null

$lbl_CurrentTheme = New-Object System.Windows.Forms.ToolStripStatusLabel
$lbl_CurrentTheme.Text = "Theme: Vista Teal"
$lbl_CurrentTheme.BorderSides = [System.Windows.Forms.ToolStripStatusLabelBorderSides]::Left
$lbl_CurrentTheme.BorderStyle = [System.Windows.Forms.Border3DStyle]::SunkenOuter
$lbl_CurrentTheme.Padding = New-Object System.Windows.Forms.Padding(5, 0, 5, 0)
$status_Main.Items.Add($lbl_CurrentTheme) | Out-Null

# --- Bottom Chin Panel ---
$ChinPanel = New-Object System.Windows.Forms.Panel
$ChinPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
$ChinPanel.Height = 55

$btn_Apply = New-Object System.Windows.Forms.Button
$btn_Apply.Text = "Execute"
$btn_Apply.Size = New-Object System.Drawing.Size(90, 28)
$btn_Apply.Location = New-Object System.Drawing.Point(320, 13)
$btn_Apply.Font = $SemiboldFont
$btn_Apply.UseVisualStyleBackColor = $true
$ToolTip.SetToolTip($btn_Apply, "Applies your configuration and sparks the PsExec engine. Prepare for UAC.")
$ChinPanel.Controls.Add($btn_Apply)

$btn_Exit = New-Object System.Windows.Forms.Button
$btn_Exit.Text = "Exit"
$btn_Exit.Size = New-Object System.Drawing.Size(90, 28)
$btn_Exit.Location = New-Object System.Drawing.Point(420, 13)
$btn_Exit.Font = $SemiboldFont
$btn_Exit.UseVisualStyleBackColor = $true
$ToolTip.SetToolTip($btn_Exit, "Abandon execution protocol and return to safety.")
$ChinPanel.Controls.Add($btn_Exit)

$lnk_Logs = New-Object System.Windows.Forms.LinkLabel
$lnk_Logs.Text = "View $ToolName Logs"
$lnk_Logs.AutoSize = $true
$lnk_Logs.Location = New-Object System.Drawing.Point(15, 20)
$ToolTip.SetToolTip($lnk_Logs, "Summon Notepad to view the transcripts of your previous decisions.")
$ChinPanel.Controls.Add($lnk_Logs)

# --- TabControl sitting ABOVE client edge panels ---
$tab_Main = New-Object System.Windows.Forms.TabControl
$tab_Main.Location = New-Object System.Drawing.Point(10, 145)
$tab_Main.Size = New-Object System.Drawing.Size(504, 305)

$TabPageLauncher = New-Object System.Windows.Forms.TabPage
$TabPageLauncher.Text = "Launcher"
$TabPageLauncher.BackColor = [System.Drawing.SystemColors]::Control

$TabPageFavorites = New-Object System.Windows.Forms.TabPage
$TabPageFavorites.Text = "Favorites"
$TabPageFavorites.BackColor = [System.Drawing.SystemColors]::Control

[void]$tab_Main.TabPages.Add($TabPageLauncher)
[void]$tab_Main.TabPages.Add($TabPageFavorites)

# --- Inset Panels with Client Edge (Window background) inside TabPages ---
$pnl_LauncherClient = New-Object System.Windows.Forms.Panel
$pnl_LauncherClient.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$pnl_LauncherClient.BackColor = [System.Drawing.Color]::FromArgb(255, 251, 251, 251)  # Slightly off-white
$pnl_LauncherClient.Location = New-Object System.Drawing.Point(5, 5)
$pnl_LauncherClient.Size = New-Object System.Drawing.Size(486, 265)
$pnl_LauncherClient.AllowDrop = $true

$pnl_FavoritesClient = New-Object System.Windows.Forms.Panel
$pnl_FavoritesClient.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$pnl_FavoritesClient.BackColor = [System.Drawing.Color]::FromArgb(255, 251, 251, 251)  # Slightly off-white
$pnl_FavoritesClient.Location = New-Object System.Drawing.Point(5, 5)
$pnl_FavoritesClient.Size = New-Object System.Drawing.Size(486, 265)

# --- Launcher Tab Page Content ---

# Target setup
$lblTarget = New-Object System.Windows.Forms.Label
$lblTarget.Text = "Target File / Command:"
$lblTarget.Location = New-Object System.Drawing.Point(10, 8)
$lblTarget.AutoSize = $true
$pnl_LauncherClient.Controls.Add($lblTarget)

$cmb_Target = New-Object System.Windows.Forms.ComboBox
$cmb_Target.Location = New-Object System.Drawing.Point(10, 26)
$cmb_Target.Size = New-Object System.Drawing.Size(360, 23)
$cmb_Target.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
$ToolTip.SetToolTip($cmb_Target, "Specify the target executable to invoke. Supports typing name-only commands like 'cmd' or 'regedit'.")
$pnl_LauncherClient.Controls.Add($cmb_Target)

$btn_Browse = New-Object System.Windows.Forms.Button
$btn_Browse.Text = "Browse..."
$btn_Browse.Location = New-Object System.Drawing.Point(380, 25)
$btn_Browse.Size = New-Object System.Drawing.Size(90, 25)
$btn_Browse.UseVisualStyleBackColor = $true
$ToolTip.SetToolTip($btn_Browse, "Invokes the file dialog so you don't have to type the path manually.")
$pnl_LauncherClient.Controls.Add($btn_Browse)

# Arguments
$lblArgs = New-Object System.Windows.Forms.Label
$lblArgs.Text = "Arguments (Optional):"
$lblArgs.Location = New-Object System.Drawing.Point(10, 56)
$lblArgs.AutoSize = $true
$pnl_LauncherClient.Controls.Add($lblArgs)

$txt_Args = New-Object System.Windows.Forms.TextBox
$txt_Args.Location = New-Object System.Drawing.Point(10, 74)
$txt_Args.Size = New-Object System.Drawing.Size(460, 23)
$ToolTip.SetToolTip($txt_Args, "Command-line flags and parameters to feed the target payload.")
$pnl_LauncherClient.Controls.Add($txt_Args)

# Execution Scope GroupBox
$ScopeGroupBox = New-Object System.Windows.Forms.GroupBox
$ScopeGroupBox.Text = "Execution Scope"
$ScopeGroupBox.Location = New-Object System.Drawing.Point(10, 104)
$ScopeGroupBox.Size = New-Object System.Drawing.Size(460, 112)
$pnl_LauncherClient.Controls.Add($ScopeGroupBox)

$lblScope = New-Object System.Windows.Forms.Label
$lblScope.Text = "Run As:"
$lblScope.Location = New-Object System.Drawing.Point(10, 22)
$lblScope.AutoSize = $true
$ScopeGroupBox.Controls.Add($lblScope)

$cmb_Scope = New-Object System.Windows.Forms.ComboBox
$cmb_Scope.Location = New-Object System.Drawing.Point(85, 19)
$cmb_Scope.Size = New-Object System.Drawing.Size(360, 23)
$cmb_Scope.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$cmb_Scope.Items.Add("Current User (Elevated)")
$cmb_Scope.Items.Add("NT AUTHORITY\SYSTEM")
$cmb_Scope.Items.Add("NT SERVICE\TrustedInstaller")
$cmb_Scope.Items.Add("NT AUTHORITY\LOCAL SERVICE")
$cmb_Scope.Items.Add("NT AUTHORITY\NETWORK SERVICE")
$cmb_Scope.Items.Add("Guest")
$cmb_Scope.Items.Add("Specific User / Domain")
$cmb_Scope.SelectedIndex = 1 
$ToolTip.SetToolTip($cmb_Scope, "Defines the token structure. SYSTEM is default, or pick a scanned PC user.")
$ScopeGroupBox.Controls.Add($cmb_Scope)

$lblUser = New-Object System.Windows.Forms.Label
$lblUser.Text = "Username:"
$lblUser.Location = New-Object System.Drawing.Point(10, 52)
$lblUser.AutoSize = $true
$ScopeGroupBox.Controls.Add($lblUser)

$txt_User = New-Object System.Windows.Forms.TextBox
$txt_User.Location = New-Object System.Drawing.Point(85, 49)
$txt_User.Size = New-Object System.Drawing.Size(360, 23)
$txt_User.Enabled = $false
$ToolTip.SetToolTip($txt_User, "Domain\Username format. Prefilled dynamically for stored credentials.")
$ScopeGroupBox.Controls.Add($txt_User)

$lblPass = New-Object System.Windows.Forms.Label
$lblPass.Text = "Password:"
$lblPass.Location = New-Object System.Drawing.Point(10, 82)
$lblPass.AutoSize = $true
$ScopeGroupBox.Controls.Add($lblPass)

$txt_Pass = New-Object System.Windows.Forms.TextBox
$txt_Pass.Location = New-Object System.Drawing.Point(85, 79)
$txt_Pass.Size = New-Object System.Drawing.Size(360, 23)
$txt_Pass.UseSystemPasswordChar = $true
$txt_Pass.Enabled = $false
$ToolTip.SetToolTip($txt_Pass, "Your secret password. Masked visually, stored obfuscated.")
$ScopeGroupBox.Controls.Add($txt_Pass)

# Flags
$chk_Interactive = New-Object System.Windows.Forms.CheckBox
$chk_Interactive.Text = "Interactive UI (-i)"
$chk_Interactive.Location = New-Object System.Drawing.Point(15, 230)
$chk_Interactive.AutoSize = $true
$chk_Interactive.Checked = $true
$ToolTip.SetToolTip($chk_Interactive, "Ensures the spawned process interacts with Session 1.")
$pnl_LauncherClient.Controls.Add($chk_Interactive)

$chk_NoPassword = New-Object System.Windows.Forms.CheckBox
$chk_NoPassword.Text = "No Password Required"
$chk_NoPassword.Location = New-Object System.Drawing.Point(180, 230)
$chk_NoPassword.AutoSize = $true
$chk_NoPassword.Enabled = $false
$ToolTip.SetToolTip($chk_NoPassword, "Bypasses passing password credentials. Ideal for empty accounts.")
$pnl_LauncherClient.Controls.Add($chk_NoPassword)

$TabPageLauncher.Controls.Add($pnl_LauncherClient)

# --- Favorites Tab Page Content ---
$flow_Favorites = New-Object System.Windows.Forms.FlowLayoutPanel
$flow_Favorites.Location = New-Object System.Drawing.Point(10, 10)
$flow_Favorites.Size = New-Object System.Drawing.Size(460, 200)
$flow_Favorites.AutoScroll = $true
$pnl_FavoritesClient.Controls.Add($flow_Favorites)

$btn_AddFavorite = New-Object System.Windows.Forms.Button
$btn_AddFavorite.Text = "Pin Current Config to Favorites"
$btn_AddFavorite.Location = New-Object System.Drawing.Point(10, 218)
$btn_AddFavorite.Size = New-Object System.Drawing.Size(220, 28)
$btn_AddFavorite.UseVisualStyleBackColor = $true
$ToolTip.SetToolTip($btn_AddFavorite, "Saves current configuration fields to the Favorites dashboard.")
$pnl_FavoritesClient.Controls.Add($btn_AddFavorite)

$TabPageFavorites.Controls.Add($pnl_FavoritesClient)

# Dock order: Add ChinPanel first, Status bar second, TabControl third (manual location).
# Then add Toolstrip, Banner panel, and Menu strip last so menu strip is at the absolute top,
# the Banner is below the Menu strip, and the Toolstrip is below the Banner.
$frm_Main.Controls.Add($ChinPanel)
$frm_Main.Controls.Add($status_Main)
$frm_Main.Controls.Add($tab_Main)
$frm_Main.Controls.Add($tool_Main)
$frm_Main.Controls.Add($BannerPanel)
$frm_Main.Controls.Add($menu_Main)

# Ensure enter key submits execution
$frm_Main.AcceptButton = $btn_Apply
#endregion

# ==============================================================================
# #region Event Handlers
# ==============================================================================

# ComboBox selection logic
$cmb_Scope.add_SelectedIndexChanged({
    $sel = $cmb_Scope.Text
    if ($sel -eq "Specific User / Domain") {
        $txt_User.Enabled = $true
        $txt_Pass.Enabled = ($chk_NoPassword.Checked -eq $false)
        $chk_NoPassword.Enabled = $true
    } elseif ($sel -eq "Current User (Elevated)" -or $sel -eq "NT AUTHORITY\SYSTEM" -or $sel -eq "NT SERVICE\TrustedInstaller" -or $sel -eq "NT AUTHORITY\LOCAL SERVICE" -or $sel -eq "NT AUTHORITY\NETWORK SERVICE") {
        $txt_User.Enabled = $false
        $txt_Pass.Enabled = $false
        $chk_NoPassword.Enabled = $false
        $txt_User.Text = ""
        $txt_Pass.Text = ""
    } else {
        # Selected local user or Guest
        $txt_User.Text = $sel
        $txt_User.Enabled = $true
        $txt_Pass.Enabled = ($chk_NoPassword.Checked -eq $false)
        $chk_NoPassword.Enabled = $true
        
        if ($sel -eq "Guest") {
            $chk_NoPassword.Checked = $true
            $txt_Pass.Text = ""
            $txt_Pass.Enabled = $false
        } else {
            if ($script:Settings.Credentials.ContainsKey($sel)) {
                $txt_Pass.Text = $script:Settings.Credentials[$sel]
            } else {
                $txt_Pass.Text = ""
            }
        }
    }
})

$txt_User.add_Leave({
    $u = $txt_User.Text.Trim()
    if ($u -and $script:Settings.Credentials.ContainsKey($u)) {
        $txt_Pass.Text = $script:Settings.Credentials[$u]
    }
})

$chk_NoPassword.add_CheckedChanged({
    if ($chk_NoPassword.Checked) {
        $txt_Pass.Enabled = $false
        $txt_Pass.Text = ""
    } else {
        if ($cmb_Scope.Text -ne "Current User (Elevated)" -and $cmb_Scope.Text -ne "NT AUTHORITY\SYSTEM" -and $cmb_Scope.Text -ne "NT AUTHORITY\LOCAL SERVICE" -and $cmb_Scope.Text -ne "NT AUTHORITY\NETWORK SERVICE") {
            $txt_Pass.Enabled = $true
        }
    }
})

# Drag & Drop Events
$DragEnterAction = {
    if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $_.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    }
}

$DragDropAction = {
    $Files = $_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    if ($Files.Count -gt 0) {
        $cmb_Target.Text = $Files[0]
        Write-Log "Target acquired via GUI UIPI drag-and-drop: $($Files[0])" "0x00000003"
    }
}

$pnl_LauncherClient.add_DragEnter($DragEnterAction)
$pnl_LauncherClient.add_DragDrop($DragDropAction)
$frm_Main.AllowDrop = $true
$frm_Main.add_DragEnter($DragEnterAction)
$frm_Main.add_DragDrop($DragDropAction)

$btn_Browse.add_Click({
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "Executables (*.exe;*.bat;*.cmd;*.ps1)|*.exe;*.bat;*.cmd;*.ps1|All Files (*.*)|*.*"
    $OpenFileDialog.Title = "Select Target Executable"
    if ($OpenFileDialog.ShowDialog($frm_Main) -eq [System.Windows.Forms.DialogResult]::OK) {
        $cmb_Target.Text = $OpenFileDialog.FileName
    }
})

$lnk_Logs.add_Click({
    if (Test-Path $LogFile) {
        Start-Process "notepad.exe" -ArgumentList "`"$LogFile`""
    } else {
        [System.Windows.Forms.MessageBox]::Show("Log file has not been materialized yet.", "Missing Logs", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

# Tray minimization logic
$script:NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
$script:NotifyIcon.Text = "EliteSoftware PsExec Launcher"
if ($frm_Main.Icon) {
    $script:NotifyIcon.Icon = $frm_Main.Icon
}
$script:NotifyIcon.Visible = $true

$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
$tray_Restore = $trayMenu.Items.Add("Restore Launcher")
$tray_RunLast = $trayMenu.Items.Add("Run Last Command")
$trayMenu.Items.Add("-") | Out-Null
$tray_Exit = $trayMenu.Items.Add("Exit")
$script:NotifyIcon.ContextMenuStrip = $trayMenu

function Hide-To-Tray {
    $frm_Main.Opacity = 0
    $frm_Main.ShowInTaskbar = $true
    $frm_Main.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    $script:NotifyIcon.Visible = $true
    
    # Display legacy balloon notification when it minimizes to tray
    $script:NotifyIcon.ShowBalloonTip(3000, "EliteSoftware PsExec Launcher", "Launcher minimized to system tray. Double-click the tray icon to restore.", [System.Windows.Forms.ToolTipIcon]::Info)
}

function Restore-From-Tray {
    $frm_Main.Opacity = $script:WindowOpacity / 100.0
    $frm_Main.ShowInTaskbar = $true
    $frm_Main.Show()
    $frm_Main.WindowState = [System.Windows.Forms.FormWindowState]::Normal
    $frm_Main.Activate()
    # Tray icon always visible
}

$script:NotifyIcon.add_DoubleClick({
    Restore-From-Tray
})

$tray_Restore.add_Click({
    Restore-From-Tray
})

$tray_Exit.add_Click({
    $script:IsExiting = $true
    $script:NotifyIcon.Visible = $false
    $frm_Main.Close()
})

$frm_Main.add_SizeChanged({
    if ($frm_Main.WindowState -eq [System.Windows.Forms.FormWindowState]::Minimized) {
        Hide-To-Tray
    }
})

# Title bar Close (X) button intercepts close event and minimizes/hides to tray
$frm_Main.add_FormClosing({
    param($sender, $e)
    if ($script:IsExiting) { return }
    $e.Cancel = $true
    Hide-To-Tray
})

# Form Menu events
$menuFile_Tray.add_Click({ Hide-To-Tray })
$menuFile_Exit.add_Click({
    $script:IsExiting = $true
    $script:NotifyIcon.Visible = $false
    $frm_Main.Close()
})

$btn_Exit.add_Click({
    $script:IsExiting = $true
    $script:NotifyIcon.Visible = $false
    $frm_Main.Close()
})

# Sub dialog invocations
function Show-AboutDialog {
    $frm_About = New-Object System.Windows.Forms.Form
    $frm_About.Text = "About - EliteSoftware PsExec Launcher"
    $frm_About.Size = New-Object System.Drawing.Size(440, 160)
    $frm_About.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $frm_About.MaximizeBox = $false
    $frm_About.MinimizeBox = $false
    $frm_About.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $frm_About.Font = $StandardFont
    $frm_About.TopMost = $true # Always on top of topmost parent
    
    # Use native Information blue circle "i" icon for the titlebar and taskbar
    $infoIconBmp = [System.Drawing.SystemIcons]::Information.ToBitmap()
    $infoIcon = [System.Drawing.Icon]::FromHandle($infoIconBmp.GetHicon())
    $frm_About.Icon = $infoIcon
    
    $aboutBanner = New-Object System.Windows.Forms.Panel
    $aboutBanner.Dock = [System.Windows.Forms.DockStyle]::Top
    $aboutBanner.Height = 55
        if ($script:BannerTheme -eq "Classic Silver") {
        $botCol = [System.Drawing.Color]::FromArgb(255, 220, 225, 230)
    } elseif ($script:BannerTheme -eq "Steel Blue") {
        $botCol = [System.Drawing.Color]::FromArgb(255, 175, 195, 225)
    } else {
        $botCol = [System.Drawing.Color]::FromArgb(255, 175, 215, 225) 
    }
    $aboutBanner.BackgroundImage = Get-GradientBmp $botCol 55
    $aboutBanner.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Stretch
    
    $lblAboutTitle = New-Object System.Windows.Forms.Label
    $lblAboutTitle.Text = "EliteSoftware PsExec Launcher"
    $lblAboutTitle.Font = $TitleFont
    $lblAboutTitle.Location = New-Object System.Drawing.Point(12, 10)
    $lblAboutTitle.AutoSize = $true
    $lblAboutTitle.BackColor = [System.Drawing.Color]::Transparent
    $aboutBanner.Controls.Add($lblAboutTitle)

    $lblAboutSub = New-Object System.Windows.Forms.Label
    $lblAboutSub.Text = "System details, authors, and assembly diagnostics."
    $lblAboutSub.Location = New-Object System.Drawing.Point(14, 30)
    $lblAboutSub.AutoSize = $true
    $lblAboutSub.BackColor = [System.Drawing.Color]::Transparent
    $aboutBanner.Controls.Add($lblAboutSub)
    
    $infoIconBox = New-Object System.Windows.Forms.PictureBox
    $infoIconBox.Size = New-Object System.Drawing.Size(32, 32)
    $infoIconBox.Location = New-Object System.Drawing.Point(380, 10)
    $infoIconBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
    $infoIconBox.Image = $infoIconBmp
    $infoIconBox.BackColor = [System.Drawing.Color]::Transparent
    $aboutBanner.Controls.Add($infoIconBox)
    
    $aboutClient = New-Object System.Windows.Forms.Panel
    $aboutClient.Location = New-Object System.Drawing.Point(10, 65)
    $aboutClient.Size = New-Object System.Drawing.Size(404, 130) # Height increased
    $aboutClient.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $aboutClient.BackColor = [System.Drawing.Color]::FromArgb(255, 251, 251, 251) # Slightly off-white
    
    $lblInfo = New-Object System.Windows.Forms.Label
    $lblInfo.Text = "EliteSoftware Suite v1.2.0.0`nAuthors: Zachary Whiteman, Susan Gemm, TheShadyRainbow4`nTarget: .NET Framework 4.6 (WinForms)"
    $lblInfo.Location = New-Object System.Drawing.Point(10, 10)
    $lblInfo.Size = New-Object System.Drawing.Size(380, 50)
    $lblInfo.BackColor = [System.Drawing.Color]::Transparent
    $aboutClient.Controls.Add($lblInfo)
    
    try {
        $os = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
        $cpu = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).Name
        $ram = [math]::Round(((Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).TotalPhysicalMemory / 1GB), 1)
    } catch {}
    if (-not $os) { $os = "Unknown" }
    if (-not $cpu) { $cpu = "Unknown" }
    
    $lblSysInfo = New-Object System.Windows.Forms.Label
    $lblSysInfo.Text = "System Details:`nOS: $os`nCPU: $cpu`nRAM: $ram GB"
    $lblSysInfo.Location = New-Object System.Drawing.Point(10, 65)
    $lblSysInfo.Size = New-Object System.Drawing.Size(380, 60)
    $lblSysInfo.BackColor = [System.Drawing.Color]::Transparent
    $aboutClient.Controls.Add($lblSysInfo)
    
    $txt_Details = New-Object System.Windows.Forms.TextBox
    $txt_Details.Multiline = $true
    $txt_Details.ReadOnly = $true
    $txt_Details.BorderStyle = [System.Windows.Forms.BorderStyle]::None # NOT a 3d textbox
    $txt_Details.BackColor = [System.Drawing.SystemColors]::Control # Blend with parent form background
    $txt_Details.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $txt_Details.Location = New-Object System.Drawing.Point(10, 150) # Adjusted start position to 150
    $txt_Details.Size = New-Object System.Drawing.Size(404, 120) # Height set to 120
    $txt_Details.Visible = $false
    
    $sysInfo = "System Information:`r`n"
    $sysInfo += "OS Version: $([System.Environment]::OSVersion.ToString())`r`n"
    $sysInfo += "64-Bit OS: $([System.Environment]::Is64BitOperatingSystem)`r`n"
    $sysInfo += "Machine Name: $($env:COMPUTERNAME)`r`n"
    $sysInfo += "Processor Count: $([System.Environment]::ProcessorCount)`r`n"
    $sysInfo += "Loaded Assemblies:`r`n"
    $sysInfo += " - System.Windows.Forms`r`n"
    $sysInfo += " - System.Drawing`r`n"
    foreach ($ass in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
        try {
            $sysInfo += " - $($ass.GetName().Name) ($($ass.GetName().Version))`r`n"
        } catch {}
    }
    $txt_Details.Text = $sysInfo
    
    $aboutChin = New-Object System.Windows.Forms.Panel
    $aboutChin.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $aboutChin.Height = 45
    $aboutChin.BackColor = [System.Drawing.Color]::FromArgb(255, 230, 230, 230) # Solid greyish for legacy chin
    
    $btn_Details = New-Object System.Windows.Forms.Button
    $btn_Details.Text = "Details v"
    $btn_Details.Size = New-Object System.Drawing.Size(85, 28)
    $btn_Details.Location = New-Object System.Drawing.Point(10, 8)
    $btn_Details.UseVisualStyleBackColor = $true
    $btn_Details.add_Click({
        if ($frm_About.Height -eq 160) {
            $frm_About.Height = 280
            $btn_Details.Text = "Details ^"
        } else {
            $frm_About.Height = 160
            $btn_Details.Text = "Details v"
        }
    })
    $aboutChin.Controls.Add($btn_Details)
    
    $btn_Done = New-Object System.Windows.Forms.Button
    $btn_Done.Text = "Done"
    $btn_Done.Size = New-Object System.Drawing.Size(85, 28)
    $btn_Done.Location = New-Object System.Drawing.Point(325, 8)
    $btn_Done.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $btn_Done.UseVisualStyleBackColor = $true
    $aboutChin.Controls.Add($btn_Done)

    $frm_About.Controls.Add($txt_Details)
    $frm_About.Controls.Add($aboutClient)
    $frm_About.Controls.Add($aboutBanner)
    $frm_About.Controls.Add($aboutChin)
    
    [void]$frm_About.ShowDialog($frm_Main)
}

function Show-HelpDialog {
    $frm_Help = New-Object System.Windows.Forms.Form
    $frm_Help.Text = "Help - EliteSoftware PsExec Launcher"
    $frm_Help.Size = New-Object System.Drawing.Size(480, 460) # Large, comfortable size to prevent button cut-offs
    $frm_Help.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $frm_Help.MaximizeBox = $false
    $frm_Help.MinimizeBox = $false
    $frm_Help.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $frm_Help.Font = $StandardFont
    $frm_Help.TopMost = $true # Always on top of topmost parent
    
    $helpIconBmp = [System.Drawing.SystemIcons]::Question.ToBitmap()
    $helpIcon = [System.Drawing.Icon]::FromHandle($helpIconBmp.GetHicon())
    $frm_Help.Icon = $helpIcon
    
    $helpBanner = New-Object System.Windows.Forms.Panel
    $helpBanner.Dock = [System.Windows.Forms.DockStyle]::Top
    $helpBanner.Height = 55
        $botCol = [System.Drawing.Color]::FromArgb(255, 185, 220, 230)
    $helpBanner.BackgroundImage = Get-GradientBmp $botCol 55
    $helpBanner.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Stretch
    
    $lblHelpTitle = New-Object System.Windows.Forms.Label
    $lblHelpTitle.Text = "User Documentation Guide"
    $lblHelpTitle.Font = $TitleFont
    $lblHelpTitle.Location = New-Object System.Drawing.Point(12, 10)
    $lblHelpTitle.AutoSize = $true
    $lblHelpTitle.BackColor = [System.Drawing.Color]::Transparent
    $helpBanner.Controls.Add($lblHelpTitle)

    $lblHelpSub = New-Object System.Windows.Forms.Label
    $lblHelpSub.Text = "Command resolution, favorites, and tray mode shortcuts."
    $lblHelpSub.Location = New-Object System.Drawing.Point(14, 30)
    $lblHelpSub.AutoSize = $true
    $lblHelpSub.BackColor = [System.Drawing.Color]::Transparent
    $helpBanner.Controls.Add($lblHelpSub)
    
    $pbQIcon = New-Object System.Windows.Forms.PictureBox
    $pbQIcon.Size = New-Object System.Drawing.Size(32, 32)
    $pbQIcon.Location = New-Object System.Drawing.Point(420, 10)
    $pbQIcon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
    $pbQIcon.Image = $helpIconBmp
    $pbQIcon.BackColor = [System.Drawing.Color]::Transparent
    $helpBanner.Controls.Add($pbQIcon)
    
    $helpClient = New-Object System.Windows.Forms.Panel
    $helpClient.Location = New-Object System.Drawing.Point(10, 65)
    $helpClient.Size = New-Object System.Drawing.Size(444, 300)
    $helpClient.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $helpClient.BackColor = [System.Drawing.Color]::FromArgb(255, 251, 251, 251) # Slightly off-white
    
    $txtHelpText = New-Object System.Windows.Forms.RichTextBox
    $txtHelpText.Dock = [System.Windows.Forms.DockStyle]::Fill
    $txtHelpText.ReadOnly = $true
    $txtHelpText.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $txtHelpText.BackColor = [System.Drawing.Color]::FromArgb(255, 251, 251, 251) # Slightly off-white
    $helpClient.Controls.Add($txtHelpText)
    
    $helpChin = New-Object System.Windows.Forms.Panel
    $helpChin.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $helpChin.Height = 40
    
    $btn_Okay = New-Object System.Windows.Forms.Button
    $btn_Okay.Text = "Okay"
    $btn_Okay.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $btn_Okay.Location = New-Object System.Drawing.Point(370, 8)
    $btn_Okay.Size = New-Object System.Drawing.Size(80, 25)
    $btn_Okay.UseVisualStyleBackColor = $true
    $helpChin.Controls.Add($btn_Okay)
    
    $frm_Help.Controls.Add($helpClient)
    $frm_Help.Controls.Add($helpBanner)
    $frm_Help.Controls.Add($helpChin)
    
    # Pre-populate help manual text cleanly
    $txtHelpText.Text = @"
ELITESOFTWARE PSEXEC LAUNCHER USER MANUAL

1. Command Execution (Run Dialog Mode)
You can type simple commands like "cmd" or "regedit" in the Target field. The launcher resolves paths like the Windows Run dialog, crawling system PATH and standard extensions (.exe, .bat, etc.) automatically.

2. Privilege Elevation (Bypass UIPI)
The main UI runs unelevated to ensure Windows Explorer Drag & Drop remains active. Elevated execution is triggered on-demand via PsExec64.exe (which requests UAC).

3. Favorites Manager
Go to the "Favorites" tab to launch pinned applications with custom arguments, scope, and working directories. Double-click any tile to execute. Pin new commands using the "Pin Current Config to Favorites" button.

4. System Tray Mode
Minimizing or closing the launcher will place it in the system tray. Use the tray menu to quickly launch commands, restore, or exit.

5. Credentials Management
Passwords are stored obfuscated in the PsExec64-Launcher.xml file in the application directory.
"@

    [void]$frm_Help.ShowDialog($frm_Main)
}

function Show-SettingsDialog {
    $frm_Settings = New-Object System.Windows.Forms.Form
    $frm_Settings.Text = "Settings - EliteSoftware PsExec Launcher"
    $frm_Settings.Size = New-Object System.Drawing.Size(440, 340)
    $frm_Settings.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $frm_Settings.MaximizeBox = $false
    $frm_Settings.MinimizeBox = $false
    $frm_Settings.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $frm_Settings.Font = $StandardFont
    $frm_Settings.TopMost = $true # Always on top of topmost parent
    
    # Use native Control Panel settings icon for the titlebar
    $settingsBmp = Get-ToolIcon "Settings"
    if ($settingsBmp) {
        $hIcon = $settingsBmp.GetHicon()
        $frm_Settings.Icon = [System.Drawing.Icon]::FromHandle($hIcon)
    } elseif ($frm_Main.Icon) {
        $frm_Settings.Icon = $frm_Main.Icon
    }
    
    $settingsBanner = New-Object System.Windows.Forms.Panel
    $settingsBanner.Dock = [System.Windows.Forms.DockStyle]::Top
    $settingsBanner.Height = 55
        $botCol = [System.Drawing.Color]::FromArgb(255, 185, 220, 230)
    $settingsBanner.BackgroundImage = Get-GradientBmp $botCol 55
    $settingsBanner.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Stretch
    
    $lblSettingsTitle = New-Object System.Windows.Forms.Label
    $lblSettingsTitle.Text = "Application Settings"
    $lblSettingsTitle.Font = $TitleFont
    $lblSettingsTitle.Location = New-Object System.Drawing.Point(12, 10)
    $lblSettingsTitle.AutoSize = $true
    $lblSettingsTitle.BackColor = [System.Drawing.Color]::Transparent
    $settingsBanner.Controls.Add($lblSettingsTitle)
    
    $lblSettingsSub = New-Object System.Windows.Forms.Label
    $lblSettingsSub.Text = "Personalize launcher behavior, themes, and transparency."
    $lblSettingsSub.Location = New-Object System.Drawing.Point(14, 30)
    $lblSettingsSub.AutoSize = $true
    $lblSettingsSub.BackColor = [System.Drawing.Color]::Transparent
    $settingsBanner.Controls.Add($lblSettingsSub)
    
    if ($settingsBmp) {
        $settingsIcon = New-Object System.Windows.Forms.PictureBox
        $settingsIcon.Size = New-Object System.Drawing.Size(32, 32)
        $settingsIcon.Location = New-Object System.Drawing.Point(380, 10)
        $settingsIcon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
        $settingsIcon.Image = $settingsBmp
        $settingsIcon.BackColor = [System.Drawing.Color]::Transparent
        $settingsBanner.Controls.Add($settingsIcon)
    }
    
    $settingsClient = New-Object System.Windows.Forms.Panel
    $settingsClient.Location = New-Object System.Drawing.Point(10, 65)
    $settingsClient.Size = New-Object System.Drawing.Size(404, 185)
    $settingsClient.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $settingsClient.BackColor = [System.Drawing.SystemColors]::Window
    
    # Left Column (Delay, Icon Size, Opacity, Clear History)
    $lblDelay = New-Object System.Windows.Forms.Label
    $lblDelay.Text = "Delay (ms):"
    $lblDelay.Location = New-Object System.Drawing.Point(15, 15)
    $lblDelay.Size = New-Object System.Drawing.Size(80, 18)
    $lblDelay.BackColor = [System.Drawing.Color]::Transparent
    $settingsClient.Controls.Add($lblDelay)
    
    $numDelay = New-Object System.Windows.Forms.NumericUpDown
    $numDelay.Minimum = 0
    $numDelay.Maximum = 3000
    $numDelay.Location = New-Object System.Drawing.Point(105, 12)
    $numDelay.Size = New-Object System.Drawing.Size(80, 23)
    $currentDelay = 500
    if ($script:Settings.LastSettings -and $script:Settings.LastSettings.ArtificialDelay) {
        $currentDelay = [int]$script:Settings.LastSettings.ArtificialDelay
    }
    $numDelay.Value = $currentDelay
    $settingsClient.Controls.Add($numDelay)

    $lblIconSize = New-Object System.Windows.Forms.Label
    $lblIconSize.Text = "Icon Size:"
    $lblIconSize.Location = New-Object System.Drawing.Point(15, 45)
    $lblIconSize.Size = New-Object System.Drawing.Size(80, 18)
    $lblIconSize.BackColor = [System.Drawing.Color]::Transparent
    $settingsClient.Controls.Add($lblIconSize)

    $cmbIconSize = New-Object System.Windows.Forms.ComboBox
    $cmbIconSize.Location = New-Object System.Drawing.Point(105, 42)
    $cmbIconSize.Size = New-Object System.Drawing.Size(80, 23)
    $cmbIconSize.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbIconSize.Items.Add("16x16")
    $cmbIconSize.Items.Add("24x24")
    $cmbIconSize.Items.Add("32x32")
    if ($script:ToolbarIconSize -eq 16) { $cmbIconSize.SelectedIndex = 0 }
    elseif ($script:ToolbarIconSize -eq 24) { $cmbIconSize.SelectedIndex = 1 }
    else { $cmbIconSize.SelectedIndex = 2 }
    $settingsClient.Controls.Add($cmbIconSize)

    $lblOpacity = New-Object System.Windows.Forms.Label
    $lblOpacity.Text = "Opacity (%):"
    $lblOpacity.Location = New-Object System.Drawing.Point(15, 75)
    $lblOpacity.Size = New-Object System.Drawing.Size(80, 18)
    $lblOpacity.BackColor = [System.Drawing.Color]::Transparent
    $settingsClient.Controls.Add($lblOpacity)

    $numOpacity = New-Object System.Windows.Forms.NumericUpDown
    $numOpacity.Minimum = 20
    $numOpacity.Maximum = 100
    $numOpacity.Location = New-Object System.Drawing.Point(105, 72)
    $numOpacity.Size = New-Object System.Drawing.Size(80, 23)
    $numOpacity.Value = $script:WindowOpacity
    $settingsClient.Controls.Add($numOpacity)

    $btnResetHist = New-Object System.Windows.Forms.Button
    $btnResetHist.Text = "Clear History"
    $btnResetHist.Location = New-Object System.Drawing.Point(15, 115)
    $btnResetHist.Size = New-Object System.Drawing.Size(170, 25)
    $btnResetHist.UseVisualStyleBackColor = $true
    $btnResetHist.add_Click({
        $script:Settings.History.Clear()
        $cmb_Target.Items.Clear()
        Save-Settings
        [System.Windows.Forms.MessageBox]::Show("History cleared successfully.", "Settings Reset", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    })
    $settingsClient.Controls.Add($btnResetHist)

    $lblSaveLoc = New-Object System.Windows.Forms.Label
    $lblSaveLoc.Text = "Save To:"
    $lblSaveLoc.Location = New-Object System.Drawing.Point(15, 148)
    $lblSaveLoc.Size = New-Object System.Drawing.Size(80, 18)
    $lblSaveLoc.BackColor = [System.Drawing.Color]::Transparent
    $settingsClient.Controls.Add($lblSaveLoc)

    $cmbSaveLoc = New-Object System.Windows.Forms.ComboBox
    $cmbSaveLoc.Location = New-Object System.Drawing.Point(105, 145)
    $cmbSaveLoc.Size = New-Object System.Drawing.Size(160, 23)
    $cmbSaveLoc.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbSaveLoc.Items.Add("XML File")
    $cmbSaveLoc.Items.Add("Registry (Current User)")
    $cmbSaveLoc.Items.Add("Registry (Local Machine)")
    if (-not $script:SaveLocation) { $script:SaveLocation = "XML File" }
    $cmbSaveLoc.Text = $script:SaveLocation
    $settingsClient.Controls.Add($cmbSaveLoc)

    # Right Column (AOT, Min to Tray, Tooltips, Theme, Clear Creds)
    $chkAot = New-Object System.Windows.Forms.CheckBox
    $chkAot.Text = "Always on Top"
    $chkAot.Location = New-Object System.Drawing.Point(210, 13)
    $chkAot.AutoSize = $true
    $chkAot.Checked = $script:AlwaysOnTop
    $chkAot.BackColor = [System.Drawing.Color]::Transparent
    $settingsClient.Controls.Add($chkAot)

    $chkMinTray = New-Object System.Windows.Forms.CheckBox
    $chkMinTray.Text = "Minimize on Close"
    $chkMinTray.Location = New-Object System.Drawing.Point(210, 38)
    $chkMinTray.AutoSize = $true
    $chkMinTray.Checked = $script:MinimizeToTrayOnClose
    $chkMinTray.BackColor = [System.Drawing.Color]::Transparent
    $settingsClient.Controls.Add($chkMinTray)

    $chkTips = New-Object System.Windows.Forms.CheckBox
    $chkTips.Text = "Show Hover Tooltips"
    $chkTips.Location = New-Object System.Drawing.Point(210, 63)
    $chkTips.AutoSize = $true
    $chkTips.Checked = $script:ShowTooltips
    $chkTips.BackColor = [System.Drawing.Color]::Transparent
    $settingsClient.Controls.Add($chkTips)

    $lblTheme = New-Object System.Windows.Forms.Label
    $lblTheme.Text = "Theme:"
    $lblTheme.Location = New-Object System.Drawing.Point(210, 91)
    $lblTheme.Size = New-Object System.Drawing.Size(50, 18)
    $lblTheme.BackColor = [System.Drawing.Color]::Transparent
    $settingsClient.Controls.Add($lblTheme)

    $cmbTheme = New-Object System.Windows.Forms.ComboBox
    $cmbTheme.Location = New-Object System.Drawing.Point(265, 88)
    $cmbTheme.Size = New-Object System.Drawing.Size(120, 23)
    $cmbTheme.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbTheme.Items.Add("Vista Teal")
    $cmbTheme.Items.Add("Classic Silver")
    $cmbTheme.Items.Add("Steel Blue")
    $cmbTheme.Text = $script:BannerTheme
    $settingsClient.Controls.Add($cmbTheme)

    $btnResetCreds = New-Object System.Windows.Forms.Button
    $btnResetCreds.Text = "Clear Credentials"
    
    $chkStayOpen = New-Object System.Windows.Forms.CheckBox
    $chkStayOpen.Text = "Stay Open on Exec"
    $chkStayOpen.Location = New-Object System.Drawing.Point(210, 142)
    $chkStayOpen.AutoSize = $true
    $chkStayOpen.Checked = $script:StayOpenOnExecution
    $chkStayOpen.BackColor = [System.Drawing.Color]::Transparent
    $settingsClient.Controls.Add($chkStayOpen)
    $btnResetCreds.Location = New-Object System.Drawing.Point(210, 115)
    $btnResetCreds.Size = New-Object System.Drawing.Size(175, 25)
    $btnResetCreds.UseVisualStyleBackColor = $true
    $btnResetCreds.add_Click({
        $script:Settings.Credentials.Clear()
        $txt_User.Text = ""
        $txt_Pass.Text = ""
        Save-Settings
        [System.Windows.Forms.MessageBox]::Show("Credentials cleared successfully.", "Settings Reset", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    })
    $settingsClient.Controls.Add($btnResetCreds)
    
    $settingsChin = New-Object System.Windows.Forms.Panel
    $settingsChin.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $settingsChin.Height = 40
    
    $btn_Cancel = New-Object System.Windows.Forms.Button
    $btn_Cancel.Text = "Cancel"
    $btn_Cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $btn_Cancel.Location = New-Object System.Drawing.Point(330, 8)
    $btn_Cancel.Size = New-Object System.Drawing.Size(80, 25)
    $btn_Cancel.UseVisualStyleBackColor = $true
    $settingsChin.Controls.Add($btn_Cancel)
    
    $btn_Save = New-Object System.Windows.Forms.Button
    $btn_Save.Text = "Okay"
    $btn_Save.Location = New-Object System.Drawing.Point(230, 8)
    $btn_Save.Size = New-Object System.Drawing.Size(80, 25)
    $btn_Save.UseVisualStyleBackColor = $true
    $btn_Save.add_Click({
        if (-not $script:Settings.LastSettings) {
            $script:Settings.LastSettings = @{}
        }
        $script:Settings.LastSettings.ArtificialDelay = $numDelay.Value.ToString()
        
        $selectedSizeText = $cmbIconSize.Text
        $newSize = 24
        if ($selectedSizeText -eq "16x16") { $newSize = 16 }
        elseif ($selectedSizeText -eq "24x24") { $newSize = 24 }
        elseif ($selectedSizeText -eq "32x32") { $newSize = 32 }
        $script:ToolbarIconSize = $newSize
        
        $script:AlwaysOnTop = $chkAot.Checked
        $script:MinimizeToTrayOnClose = $chkMinTray.Checked
        $script:ShowTooltips = $chkTips.Checked
        $script:StayOpenOnExecution = $chkStayOpen.Checked
        $script:WindowOpacity = [int]$numOpacity.Value
        $script:BannerTheme = $cmbTheme.Text
        $script:SaveLocation = $cmbSaveLoc.Text
        
        Save-Settings
        Apply-Settings-To-UI
        
        $tool_Main.ImageScalingSize = New-Object System.Drawing.Size($newSize, $newSize)
        $frm_Settings.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $frm_Settings.Close()
    })
    $settingsChin.Controls.Add($btn_Save)
    
    $frm_Settings.Controls.Add($settingsClient)
    $frm_Settings.Controls.Add($settingsBanner)
    $frm_Settings.Controls.Add($settingsChin)
    
    [void]$frm_Settings.ShowDialog($frm_Main)
}

function Show-AddFavoriteDialog {
    param($FavToEdit = $null)
    $frm_Fav = New-Object System.Windows.Forms.Form
    $frm_Fav.Text = "Pin Favorite - EliteSoftware PsExec Launcher"
    $frm_Fav.Size = New-Object System.Drawing.Size(440, 310)
    $frm_Fav.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $frm_Fav.MaximizeBox = $false
    $frm_Fav.MinimizeBox = $false
    $frm_Fav.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $frm_Fav.Font = $StandardFont
    $frm_Fav.TopMost = $true # Always on top of topmost parent
    
    if ($frm_Main.Icon) { $frm_Fav.Icon = $frm_Main.Icon }
    
    $favBanner = New-Object System.Windows.Forms.Panel
    $favBanner.Dock = [System.Windows.Forms.DockStyle]::Top
    $favBanner.Height = 55
        $botCol = [System.Drawing.Color]::FromArgb(255, 185, 220, 230)
    $favBanner.BackgroundImage = Get-GradientBmp $botCol 55
    $favBanner.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Stretch
    
    $lblFavTitle = New-Object System.Windows.Forms.Label
    $lblFavTitle.Text = "Pin to Favorites Dashboard"
    $lblFavTitle.Font = $TitleFont
    $lblFavTitle.Location = New-Object System.Drawing.Point(12, 10)
    $lblFavTitle.AutoSize = $true
    $lblFavTitle.BackColor = [System.Drawing.Color]::Transparent
    $favBanner.Controls.Add($lblFavTitle)

    $lblFavSub = New-Object System.Windows.Forms.Label
    $lblFavSub.Text = "Create a quick-launch tile with custom scope and arguments."
    $lblFavSub.Location = New-Object System.Drawing.Point(14, 30)
    $lblFavSub.AutoSize = $true
    $lblFavSub.BackColor = [System.Drawing.Color]::Transparent
    $favBanner.Controls.Add($lblFavSub)
    
    $favClient = New-Object System.Windows.Forms.Panel
    $favClient.Location = New-Object System.Drawing.Point(10, 65)
    $favClient.Size = New-Object System.Drawing.Size(404, 150)
    $favClient.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
    $favClient.BackColor = [System.Drawing.Color]::FromArgb(255, 251, 251, 251) # Slightly off-white
    
    $lblT = New-Object System.Windows.Forms.Label
    $lblT.Text = "Title:"
    $lblT.Location = New-Object System.Drawing.Point(15, 15)
    $lblT.AutoSize = $true
    $lblT.BackColor = [System.Drawing.Color]::Transparent
    $favClient.Controls.Add($lblT)
    
    $txtTitle = New-Object System.Windows.Forms.TextBox
    $txtTitle.Location = New-Object System.Drawing.Point(110, 12)
    $txtTitle.Size = New-Object System.Drawing.Size(270, 23)
    $targetFile = $cmb_Target.Text.Trim()
    if ($targetFile) {
        $txtTitle.Text = [System.IO.Path]::GetFileNameWithoutExtension($targetFile)
    } else {
        $txtTitle.Text = "My Command"
    }
    $favClient.Controls.Add($txtTitle)
    
    $lblD = New-Object System.Windows.Forms.Label
    $lblD.Text = "Description:"
    $lblD.Location = New-Object System.Drawing.Point(15, 45)
    $lblD.AutoSize = $true
    $lblD.BackColor = [System.Drawing.Color]::Transparent
    $favClient.Controls.Add($lblD)
    
    $txtDesc = New-Object System.Windows.Forms.TextBox
    $txtDesc.Location = New-Object System.Drawing.Point(110, 42)
    $txtDesc.Size = New-Object System.Drawing.Size(270, 23)
    $txtDesc.Text = "Launches target command under elevated context."
    $favClient.Controls.Add($txtDesc)
    
    $lblW = New-Object System.Windows.Forms.Label
    $lblW.Text = "Working Dir:"
    $lblW.Location = New-Object System.Drawing.Point(15, 75)
    $lblW.AutoSize = $true
    $lblW.BackColor = [System.Drawing.Color]::Transparent
    $favClient.Controls.Add($lblW)
    
    $txtWorking = New-Object System.Windows.Forms.TextBox
    $txtWorking.Location = New-Object System.Drawing.Point(110, 72)
    $txtWorking.Size = New-Object System.Drawing.Size(270, 23)
    $txtWorking.Text = $ScriptDir
    $favClient.Controls.Add($txtWorking)
    
    $lblIcon = New-Object System.Windows.Forms.Label
    $lblIcon.Text = "Custom Icon:"
    $lblIcon.Location = New-Object System.Drawing.Point(15, 105)
    $lblIcon.AutoSize = $true
    $lblIcon.BackColor = [System.Drawing.Color]::Transparent
    $favClient.Controls.Add($lblIcon)
    
    $txtIconPath = New-Object System.Windows.Forms.TextBox
    $txtIconPath.Location = New-Object System.Drawing.Point(110, 102)
    $txtIconPath.Size = New-Object System.Drawing.Size(190, 23)
    $favClient.Controls.Add($txtIconPath)
    
    $btnBrowseIcon = New-Object System.Windows.Forms.Button
    $btnBrowseIcon.Text = "Browse"
    $btnBrowseIcon.Location = New-Object System.Drawing.Point(305, 101)
    $btnBrowseIcon.Size = New-Object System.Drawing.Size(75, 25)
    $btnBrowseIcon.UseVisualStyleBackColor = $true
    $btnBrowseIcon.add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "Icon/Image Files|*.ico;*.png;*.jpg;*.bmp|All Files|*.*"
        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtIconPath.Text = $ofd.FileName
        }
    })
    $favClient.Controls.Add($btnBrowseIcon)
    
    if ($FavToEdit) {
        $cmb_Target.Text = $FavToEdit.Path
        $txt_Args.Text = $FavToEdit.Args
        $scopeIndex = $cmb_Scope.FindStringExact($FavToEdit.Scope)
        if ($scopeIndex -ge 0) { $cmb_Scope.SelectedIndex = $scopeIndex }
        $txt_User.Text = $FavToEdit.User
        $txt_Pass.Text = $FavToEdit.Pass
        $chk_Interactive.Checked = $FavToEdit.Interactive
        $chk_NoPassword.Checked = $FavToEdit.NoPassword
        
        $txtTitle.Text = $FavToEdit.Title
        $txtDesc.Text = $FavToEdit.Description
        $txtWorking.Text = $FavToEdit.WorkingDir
        if ($FavToEdit.IconPath) { $txtIconPath.Text = $FavToEdit.IconPath }
    }
    
    $favChin = New-Object System.Windows.Forms.Panel
    $favChin.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $favChin.Height = 40
    
    $btn_Cancel = New-Object System.Windows.Forms.Button
    $btn_Cancel.Text = "Cancel"
    $btn_Cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $btn_Cancel.Location = New-Object System.Drawing.Point(330, 8)
    $btn_Cancel.Size = New-Object System.Drawing.Size(80, 25)
    $btn_Cancel.UseVisualStyleBackColor = $true
    $favChin.Controls.Add($btn_Cancel)
    
    $btn_Save = New-Object System.Windows.Forms.Button
    $btn_Save.Text = "Okay"
    $btn_Save.Location = New-Object System.Drawing.Point(230, 8)
    $btn_Save.Size = New-Object System.Drawing.Size(80, 25)
    $btn_Save.UseVisualStyleBackColor = $true
    $btn_Save.add_Click({
        if ($FavToEdit) {
            $FavToEdit.Title = $txtTitle.Text.Trim()
            $FavToEdit.Description = $txtDesc.Text.Trim()
            $FavToEdit.WorkingDir = $txtWorking.Text.Trim()
            $FavToEdit.IconPath = $txtIconPath.Text.Trim()
            $FavToEdit.Path = $cmb_Target.Text.Trim()
            $FavToEdit.Args = $txt_Args.Text.Trim()
            $FavToEdit.Scope = $cmb_Scope.Text
            $FavToEdit.User = $txt_User.Text
            $FavToEdit.Pass = $txt_Pass.Text
            $FavToEdit.Interactive = $chk_Interactive.Checked
            $FavToEdit.NoPassword = $chk_NoPassword.Checked
        } else {
            $favObj = [PSCustomObject]@{
                Title = $txtTitle.Text.Trim()
                Description = $txtDesc.Text.Trim()
                Path = $cmb_Target.Text.Trim()
                Args = $txt_Args.Text.Trim()
                WorkingDir = $txtWorking.Text.Trim()
                Scope = $cmb_Scope.Text
                User = $txt_User.Text
                Pass = $txt_Pass.Text
                Interactive = $chk_Interactive.Checked
                NoPassword = $chk_NoPassword.Checked
                IconPath = $txtIconPath.Text.Trim()
            }
            [void]$script:Settings.Favorites.Add($favObj)
        }
        Save-Settings
        Refresh-Favorites
        
        $frm_Fav.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $frm_Fav.Close()
    })
    $favChin.Controls.Add($btn_Save)
    
    $frm_Fav.Controls.Add($favClient)
    $frm_Fav.Controls.Add($favBanner)
    $frm_Fav.Controls.Add($favChin)
    
    [void]$frm_Fav.ShowDialog($frm_Main)
}

# --- Event Handlers & Menu Integrations ---
$menuFile_RunAs_System.add_Click({
    $cmb_Scope.SelectedIndex = $cmb_Scope.FindStringExact("NT AUTHORITY\SYSTEM")
    Run-CommandAction
})
$menuFile_RunAs_Admin.add_Click({
    $cmb_Scope.SelectedIndex = $cmb_Scope.FindStringExact("Administrator")
    Run-CommandAction
})
$menuFile_ClearHist.add_Click({
    $script:Settings.History.Clear()
    $cmb_Target.Items.Clear()
    Save-Settings
    [System.Windows.Forms.MessageBox]::Show("History cleared successfully.", "Settings Reset", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
$menuFile_Tray.add_Click({ Hide-To-Tray })
$menuFile_Exit.add_Click({
    $script:IsExiting = $true
    $script:NotifyIcon.Visible = $false
    $frm_Main.Close()
})
$menuSettings_Theme_Teal.add_Click({
    $script:BannerTheme = "Vista Teal"
    Save-Settings
    Apply-Settings-To-UI
})
$menuSettings_Theme_Silver.add_Click({
    $script:BannerTheme = "Classic Silver"
    Save-Settings
    Apply-Settings-To-UI
})
$menuSettings_Theme_Blue.add_Click({
    $script:BannerTheme = "Steel Blue"
    Save-Settings
    Apply-Settings-To-UI
})
$menuSettings_Opacity_100.add_Click({ $script:WindowOpacity = 100; Save-Settings; Apply-Settings-To-UI })
$menuSettings_Opacity_90.add_Click({ $script:WindowOpacity = 90; Save-Settings; Apply-Settings-To-UI })
$menuSettings_Opacity_80.add_Click({ $script:WindowOpacity = 80; Save-Settings; Apply-Settings-To-UI })
$menuSettings_Opacity_70.add_Click({ $script:WindowOpacity = 70; Save-Settings; Apply-Settings-To-UI })

$menuHelp_Website.add_Click({
    [System.Diagnostics.Process]::Start("https://main.elitesoftwaretech.cc")
})
$menuHelp_Logs.add_Click({
    if (Test-Path $LogFile) {
        Start-Process "notepad.exe" -ArgumentList "`"$LogFile`""
    }
})
$menuSettings_Configure.add_Click({ Show-SettingsDialog })
$menuHelp_Guidance.add_Click({ Show-HelpDialog })
$menuHelp_About.add_Click({ Show-AboutDialog })

$btn_ToolSettings.add_Click({ Show-SettingsDialog })
$btn_ToolHelp.add_Click({ Show-HelpDialog })
$btn_ToolFav.add_Click({ Show-AddFavoriteDialog })
$btn_AddFavorite.add_Click({ Show-AddFavoriteDialog })

# Execution Action Logic
function Run-CommandAction {
    $Target = $cmb_Target.Text.Trim()
    
    if ([string]::IsNullOrWhiteSpace($Target)) {
        [System.Windows.Forms.MessageBox]::Show("The target executable path is completely void of reality.", "Execution Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        Write-Log "Launch aborted: Target path empty." "0xE0000003" $true
        return
    }

    # Resolve Command Path like Run Dialog
    $ResolvedTarget = Resolve-CommandPath $Target
    if (-not $ResolvedTarget) {
        [System.Windows.Forms.MessageBox]::Show("Could not resolve target command: '$Target'. Ensure the file exists in the directory or environment PATH.", "Command Resolution Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        Write-Log "Launch aborted: Command '$Target' could not be resolved." "0xE0000009" $true
        return
    }

    if (-not (Test-Path $PsExecPath)) {
        [System.Windows.Forms.MessageBox]::Show("Could not locate psexec64.exe. Ensure it resides alongside this tool.", "PsExec Missing", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        Write-Log "Failed execution: PsExec64.exe pulled a vanishing act." "0xE0000004" $true
        return
    }

    $UserArgs = $txt_Args.Text.Trim()
    $shortcutWd = ""
    if ($ResolvedTarget.EndsWith(".lnk", [System.StringComparison]::OrdinalIgnoreCase)) {
        try {
            $sh = New-Object -ComObject WScript.Shell
            $shortcut = $sh.CreateShortcut($ResolvedTarget)
            $ResolvedTarget = $shortcut.TargetPath
            $shortcutArgs = $shortcut.Arguments
            $shortcutWd = $shortcut.WorkingDirectory
            
            if (-not [string]::IsNullOrWhiteSpace($shortcutArgs)) {
                if ([string]::IsNullOrWhiteSpace($UserArgs)) {
                    $UserArgs = $shortcutArgs
                } else {
                    $UserArgs = "$shortcutArgs $UserArgs"
                }
            }
            Write-Log "Dereferenced LNK shortcut to: $ResolvedTarget" "0x0000000C"
        } catch {
            Write-Log "Failed to dereference shortcut payload: $ResolvedTarget" "0xE000000B" $false
        }
    }

    $PsArgs = ""
    
    # Scope Logic Application
    $SelectedScope = $cmb_Scope.Text
    if ($SelectedScope -eq "Current User (Elevated)") {
        $PsArgs += "-h "
    } elseif ($SelectedScope -eq "NT AUTHORITY\SYSTEM") {
        $PsArgs += "-s "
    } elseif ($SelectedScope -eq "NT SERVICE\TrustedInstaller") {
        $PsArgs += "-s -u `"NT SERVICE\TrustedInstaller`" "
    } elseif ($SelectedScope -eq "NT AUTHORITY\LOCAL SERVICE") {
        $PsArgs += "-s -u `"NT AUTHORITY\LOCAL SERVICE`" "
    } elseif ($SelectedScope -eq "NT AUTHORITY\NETWORK SERVICE") {
        $PsArgs += "-s -u `"NT AUTHORITY\NETWORK SERVICE`" "
    } else {
        $U = $txt_User.Text.Trim()
        $P = $txt_Pass.Text
        if (-not [string]::IsNullOrWhiteSpace($U)) { $PsArgs += "-u `"$U`" " }
        if (-not $chk_NoPassword.Checked -and -not [string]::IsNullOrWhiteSpace($P)) { $PsArgs += "-p `"$P`" " }
    }

    if ($chk_Interactive.Checked) { $PsArgs += "-i " }
    if (-not [string]::IsNullOrWhiteSpace($shortcutWd)) { $PsArgs += "-w `"$shortcutWd`" " }
    
    $PsArgs += "`"$ResolvedTarget`""
    
    if (-not [string]::IsNullOrWhiteSpace($UserArgs)) {
        $PsArgs += " $UserArgs"
    }

    Write-Log "Attempting to invoke PsExec with payload: $ResolvedTarget" "0x00000005"

    try {
        $StartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $StartInfo.FileName = $PsExecPath
        $StartInfo.Arguments = $PsArgs
        $StartInfo.Verb = "RunAs"
        $StartInfo.UseShellExecute = $true
        $StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        
        $proc = [System.Diagnostics.Process]::Start($StartInfo)
        Write-Log "PsExec deployed successfully." "0x00000006"
        $lbl_Status.Text = "Command executed successfully: $Target"
        
        # Save command history
        if ($script:Settings.History -notcontains $Target) {
            [void]$script:Settings.History.Add($Target)
            $cmb_Target.Items.Add($Target)
        }
        
        # Save password if specified
        if ($SelectedScope -ne "Current User (Elevated)" -and $SelectedScope -ne "NT AUTHORITY\SYSTEM" -and $SelectedScope -ne "NT AUTHORITY\LOCAL SERVICE" -and $SelectedScope -ne "NT AUTHORITY\NETWORK SERVICE") {
            $U = $txt_User.Text.Trim()
            $P = $txt_Pass.Text
            if ($U) {
                $script:Settings.Credentials[$U] = $P
            }
        }
        
        # Save last used settings
        $script:Settings.LastScope = $SelectedScope
        $script:Settings.LastUser = $txt_User.Text
        $script:Settings.LastPass = $txt_Pass.Text
        $script:Settings.LastInteractive = $chk_Interactive.Checked
        $script:Settings.LastNoPassword = $chk_NoPassword.Checked
        
        Save-Settings
        
        $script:LaunchCount++
        $lbl_SessionLaunches.Text = "Launches: $script:LaunchCount"
        
        # Close/Minimize to tray upon successful execution (Unless StayOpen setting is true)
        if (-not $script:StayOpenOnExecution) {
            Hide-To-Tray
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Launch failed. See log for diagnostic details.", "Execution Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        Write-Log "Launch exception caught: $($_.Exception.Message)" "0xE0000005" $true
        $lbl_Status.Text = "Execution failed."
    }
}

$btn_Apply.add_Click({
    $delay = 500
    if ($script:Settings.LastSettings -and $script:Settings.LastSettings.ArtificialDelay) {
        $delay = [int]$script:Settings.LastSettings.ArtificialDelay
    }
    if ($delay -gt 0) {
        $lbl_Status.Text = "Negotiating elevated context security tokens..."
        [System.Windows.Forms.Application]::DoEvents()
        [System.Threading.Thread]::Sleep($delay)
    }
    Run-CommandAction
})
$btn_ToolRun.add_Click({
    Run-CommandAction
})

$tray_RunLast.add_Click({
    if ($script:Settings.History.Count -gt 0) {
        $cmb_Target.Text = $script:Settings.History[$script:Settings.History.Count - 1]
        Run-CommandAction
    } else {
        [System.Windows.Forms.MessageBox]::Show("No previous commands exist in history transcript.", "Execution Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})

# Favorites UI Refreshing
function Refresh-Favorites {
    $flow_Favorites.Controls.Clear()
    
    # Store hover states in script scope to prevent garbage collection
    if (-not $script:HoverStates) {
        $script:HoverStates = @{}
    }
    
    foreach ($fav in $script:Settings.Favorites) {
        $tile = New-Object System.Windows.Forms.Panel
        $tileW = [int](($flow_Favorites.ClientSize.Width - 12) / 2)
        if ($tileW -lt 150) { $tileW = 210 }
        $tile.Size = New-Object System.Drawing.Size($tileW, 82)
        $tile.BackColor = [System.Drawing.SystemColors]::Window
        $tile.Cursor = [System.Windows.Forms.Cursors]::Hand
        
        $tileId = [guid]::NewGuid().ToString()
        $script:HoverStates[$tileId] = $false
        $tile.Tag = $tileId # Store tile ID in tag for safe parent identification
        
        $pb = New-Object System.Windows.Forms.PictureBox
        $pb.Size = New-Object System.Drawing.Size(32, 32)
        $pb.Location = New-Object System.Drawing.Point(8, 8)
        $pb.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
        $pb.BackColor = [System.Drawing.Color]::Transparent
        
        $iconBmp = $null
        if ($fav.IconPath -and (Test-Path $fav.IconPath)) {
            try {
                $bytes = [System.IO.File]::ReadAllBytes($fav.IconPath)
                $ms = New-Object System.IO.MemoryStream(,$bytes)
                $iconBmp = [System.Drawing.Image]::FromStream($ms)
            } catch {}
        }
        if (-not $iconBmp -and $fav.Path) {
            $resolved = Resolve-CommandPath $fav.Path
            if ($resolved -and (Test-Path $resolved)) {
                $iconBmp = Get-FileIcon $resolved
            }
        }
        if (-not $iconBmp) {
            # Default to Quick Access gold star from shell32.dll index 43
            $iconBmp = Get-Shell32Icon 43
            if (-not $iconBmp) {
                $iconBmp = New-Object System.Drawing.Bitmap(32, 32)
                $g = [System.Drawing.Graphics]::FromImage($iconBmp)
                $g.Clear([System.Drawing.Color]::FromArgb(44, 62, 80))
                $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(236, 240, 241))
                $font = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
                $g.DrawString(">", $font, $brush, 8, 4)
                $font.Dispose()
                $brush.Dispose()
                $g.Dispose()
            }
        }
        $pb.Image = $iconBmp
        $tile.Controls.Add($pb)
        
        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Text = $fav.Title
        $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $lblTitle.Location = New-Object System.Drawing.Point(48, 8)
        $lblTitle.Size = New-Object System.Drawing.Size(165, 18)
        $lblTitle.AutoEllipsis = $true
        $lblTitle.BackColor = [System.Drawing.Color]::Transparent
        $tile.Controls.Add($lblTitle)
        
        $lblDesc = New-Object System.Windows.Forms.Label
        $lblDesc.Text = $fav.Description
        $lblDesc.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Regular)
        $lblDesc.Location = New-Object System.Drawing.Point(48, 28)
        $lblDesc.Size = New-Object System.Drawing.Size(165, 48)
        $lblDesc.AutoEllipsis = $true
        $lblDesc.BackColor = [System.Drawing.Color]::Transparent
        $tile.Controls.Add($lblDesc)
        
                $script:TileNormal = Get-TileBmp $false $tileW 82
        $script:TileHover = Get-TileBmp $true $tileW 82
        
        $tile.BackgroundImage = $script:TileNormal
        $tile.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::None
        
        $myTile = $tile
        $onEnter = {
            $myTile.BackgroundImage = $script:TileHover
        }.GetNewClosure()
        
        $onLeave = {
            $pt = $myTile.PointToClient([System.Windows.Forms.Control]::MousePosition)
            if ($pt.X -lt 0 -or $pt.Y -lt 0 -or $pt.X -ge $myTile.Width -or $pt.Y -ge $myTile.Height) {
                $myTile.BackgroundImage = $script:TileNormal
            }
        }.GetNewClosure()
        
        $tile.add_MouseEnter($onEnter)
        $tile.add_MouseLeave($onLeave)
        $pb.add_MouseEnter($onEnter)
        $pb.add_MouseLeave($onLeave)
        $lblTitle.add_MouseEnter($onEnter)
        $lblTitle.add_MouseLeave($onLeave)
        $lblDesc.add_MouseEnter($onEnter)
        $lblDesc.add_MouseLeave($onLeave)
        
        $executeAction = {
            $cmb_Target.Text = $fav.Path
            $txt_Args.Text = $fav.Args
            
            $scopeIndex = $cmb_Scope.FindStringExact($fav.Scope)
            if ($scopeIndex -ge 0) {
                $cmb_Scope.SelectedIndex = $scopeIndex
            } else {
                if ($fav.Scope -and $cmb_Scope.Items -notcontains $fav.Scope) {
                    $cmb_Scope.Items.Add($fav.Scope)
                }
                $cmb_Scope.Text = $fav.Scope
            }
            
            $txt_User.Text = $fav.User
            $txt_Pass.Text = $fav.Pass
            $chk_Interactive.Checked = $fav.Interactive
            $chk_NoPassword.Checked = $fav.NoPassword
            
            $delay = 500
            if ($script:Settings.LastSettings -and $script:Settings.LastSettings.ArtificialDelay) {
                $delay = [int]$script:Settings.LastSettings.ArtificialDelay
            }
            if ($delay -gt 0) {
                $lbl_Status.Text = "Deploying Favorite: $($fav.Title) (Token negotiation)..."
                [System.Windows.Forms.Application]::DoEvents()
                [System.Threading.Thread]::Sleep($delay)
            }
            
            Run-CommandAction
        }.GetNewClosure()
        
        $tile.add_DoubleClick($executeAction); $pb.add_DoubleClick($executeAction); $lblTitle.add_DoubleClick($executeAction); $lblDesc.add_DoubleClick($executeAction)
        
        $tileMenu = New-Object System.Windows.Forms.ContextMenuStrip
        $runItem = $tileMenu.Items.Add("Execute")
        $runItem.add_Click($executeAction)
        
        $editItem = $tileMenu.Items.Add("Edit")
        $editItem.add_Click({
            Show-AddFavoriteDialog -FavToEdit $fav
        }.GetNewClosure())
        
        $deleteItem = $tileMenu.Items.Add("Delete")
        $deleteItem.add_Click({
            $script:Settings.Favorites.Remove($fav) | Out-Null
            Save-Settings
            Refresh-Favorites
        }.GetNewClosure())
        
        $tile.ContextMenuStrip = $tileMenu
        $pb.ContextMenuStrip = $tileMenu
        $lblTitle.ContextMenuStrip = $tileMenu
        $lblDesc.ContextMenuStrip = $tileMenu
        
        $ToolTip.SetToolTip($tile, "Double-click to launch '$($fav.Title)' instantly.")
        
        $flow_Favorites.Controls.Add($tile)
    }
}
#endregion

# ==============================================================================
# #region Script Initialization & Boot Loader
# ==============================================================================
$frm_Main.add_Load({
    $lbl_Status.Text = "Scanning NT authority framework..."
    [System.Windows.Forms.Application]::DoEvents()
    
    # Handle pending drop execution UI state
    if ($script:PendingDropFile) {
        $frm_Main.Opacity = 0
        $frm_Main.ShowInTaskbar = $false
        $frm_Main.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    }
    
    # Premium feel startup delay
    [System.Threading.Thread]::Sleep(500)
    
    # Load persistence settings
    Load-Settings
    
    # Apply loaded customizations to UI
    Apply-Settings-To-UI
    
    # Apply toolbar icon size
    $tool_Main.ImageScalingSize = New-Object System.Drawing.Size($script:ToolbarIconSize, $script:ToolbarIconSize)
    
    # Apply native system icons to toolbar after size initialization
    $btn_ToolRun.Image = Get-ToolIcon "Run"
    $btn_ToolFav.Image = Get-ToolIcon "Favorite"
    $btn_ToolSettings.Image = Get-ToolIcon "Settings"
    $btn_ToolHelp.Image = Get-ToolIcon "Help"
    
    # Populate command history dropdown
    foreach ($cmd in $script:Settings.History) {
        if ($cmd -and $cmb_Target.Items -notcontains $cmd) {
            $cmb_Target.Items.Add($cmd)
        }
    }
    
    # Select last settings
    $scopeIndex = $cmb_Scope.FindStringExact($script:Settings.LastScope)
    if ($scopeIndex -ge 0) {
        $cmb_Scope.SelectedIndex = $scopeIndex
    }
    $txt_User.Text = $script:Settings.LastUser
    $txt_Pass.Text = $script:Settings.LastPass
    $chk_Interactive.Checked = $script:Settings.LastInteractive
    $chk_NoPassword.Checked = $script:Settings.LastNoPassword
    
    # Populate favorites UI
    Refresh-Favorites
    
    # Multi-threaded background loading of user accounts via BackgroundWorker
    $bgWorker = New-Object System.ComponentModel.BackgroundWorker
    $bgWorker.add_DoWork({
        param($sender, $e)
        $LocalUsers = @()
        try {
            $users = Get-LocalUser -ErrorAction SilentlyContinue
            if ($users) {
                $LocalUsers = $users.Name
            } else {
                $computer = [ADSI]"WinNT://$env:COMPUTERNAME"
                $LocalUsers = $computer.Children | Where-Object { $_.SchemaClassName -eq "user" } | ForEach-Object { $_.Name }
            }
        } catch {
            $LocalUsers = @($env:USERNAME, "Administrator", "Guest")
        }
        $e.Result = $LocalUsers
    })
    $bgWorker.add_RunWorkerCompleted({
        param($sender, $e)
        $users = $e.Result
        $action = [System.Action]{
            foreach ($user in $users) {
                if ($user -and $cmb_Scope.Items -notcontains $user) {
                    [void]$cmb_Scope.Items.Add($user)
                }
            }
            $lbl_Status.Text = "NT authority framework loaded successfully."
        }
        if ($frm_Main.InvokeRequired) {
            [void]$frm_Main.Invoke($action)
        } else {
            $action.Invoke()
        }
        
        # Trigger background run of pending drop target target
        if ($script:PendingDropFile) {
            $cmb_Target.Text = $script:PendingDropFile
            $txt_Args.Text = ""
            
            # Default to NT AUTHORITY\SYSTEM for dropped executable payloads
            $sysIndex = $cmb_Scope.FindStringExact("NT AUTHORITY\SYSTEM")
            if ($sysIndex -ge 0) {
                $cmb_Scope.SelectedIndex = $sysIndex
            }
            
            Write-Log "Processing pending drop target payload as SYSTEM: $script:PendingDropFile" "0x0000000A"
            Run-CommandAction
            
            # Reset pending state
            $script:PendingDropFile = $null
            $script:PendingUseNTAS = $false
        }
    })
    $bgWorker.RunWorkerAsync()
})

[void]$frm_Main.ShowDialog()
#endregion