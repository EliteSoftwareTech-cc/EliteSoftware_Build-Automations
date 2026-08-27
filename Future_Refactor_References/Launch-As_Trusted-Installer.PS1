# 1. DEFINE NATIVE WINDOWS API (User32.dll)
$windowMagic = @"
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
"@

# 2. HIDE THE CONSOLE INSTANTLY
# We compile the C# code on the fly and call it immediately.
# 0 = Hide (Invisible)
try {
    $win32 = Add-Type -MemberDefinition $windowMagic -Name "Win32ShowWindow" -Namespace Win32Functions -PassThru
    $handle = $win32::GetConsoleWindow()
    $win32::ShowWindow($handle, 0) 
} catch {
    # If hiding fails (rare), we continue anyway so the script still works.
}

# 3. PREPARE PATHS
$CurrentDir = $PSScriptRoot
$TargetScript = Join-Path -Path $CurrentDir -ChildPath "Restore-Legacy-Resolution-Control-Panel.PS1"

# 4. LAUNCH PAYLOAD (TRUSTED INSTALLER)
# -WindowStyle Hidden: Ensures NSudo itself doesn't pop a window
# -ShowWindowMode:Show : Forces the TARGET script to be visible
# -Wait: We wait for the process to finish so this script stays "running" (hidden) until done
Start-Process "NSudo.exe" -WindowStyle Hidden -Wait -ArgumentList "-U:T -P:E -ShowWindowMode:Show pwsh.exe -ExecutionPolicy Bypass -NoProfile -File `"$TargetScript`""

# 5. CLOSE NATURALLY
Exit
