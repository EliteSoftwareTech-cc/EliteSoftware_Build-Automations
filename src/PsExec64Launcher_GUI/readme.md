# EliteSoftware PsExec64 Launcher ﻿



----

<!-- EliteSoftware Co. LOGO -->


<div align="center">

 <a href='https://i.postimg.cc/DZTjtNg1/Elite-Software-Company-Simulator-LOGO.png' target='_blank'><img src='https://i.postimg.cc/DZTjtNg1/Elite-Software-Company-Simulator-LOGO.png' border='0' alt='Elite-Software-Client' width="200"></a> 
 </div>


 ### Core Information 

 * **Company**: EliteSoftware / EliteSoftwareTech Co. 
 * **Authors**: Zachary Whiteman, Susan Gemm, TheShadyRainbow4, EliteSoftwareTech Co.  
 * **Document Version**: 1.2.0.0  
 * **Target Framework**: .NET Framework 4.6 (WinForms / Legacy Win32)  
 * **Minimum OS Target**: Windows Vista / Windows 7  


---

<!-- Scope -->

## 🏛️ Project Scope & Overview The 


**EliteSoftware PsExec64 Launcher** is a legacy-styled WinForms frontend launcher utility designed to interact with Sysinternals `PsExec64.exe` to run commands with administrative privileges or under custom user tokens (e.g. `NT AUTHORITY\SYSTEM` or `TrustedInstaller`). 

This launcher operates **unelevated by default** to resolve User Interface Privilege Isolation (UIPI) issues. This guarantees that user interactions like Drag and Drop from Windows Explorer work seamlessly. The launcher utilizes `psexec64.exe` (with `-Verb RunAs` UAC prompts on invocation) to execute target payloads with full elevated permissions.

--- 

<!-- Design -->

## 🎨 Design & Aesthetic System
(The application adheres strictly to the classic high-density native Win32/WinForms visual style: )

* **No Modern Flat Design**: Uses native visual styles (`Application.EnableVisualStyles()`). 
* **Title Banner**: A top-docked linear gradient banner (respects Teal, Silver, or Blue themes) with the application title, subtitle, and dynamic 48x48 icon display. * 
**3D Inset Area**: A defined client area bordered by `Fixed3D` to give the Classic Vista dialog layout. The TabPages are styled in native grey (`SystemColors.Control`) and house white active client panels (`SystemColors.Window`) to provide a sunken contrast. 
* **The "Chin"**: A darker bottom area hosting action buttons ("Apply", "Exit") and a link to view execution log transcripts. 
* **System Tray Integration**: Ability to minimize/close the application to the Windows system tray area. Uses an opacity-based minimize state to keep the WinForms thread alive and active without terminating the runspace.

---

<!-- Features -->

## ✨ Features

### 1. Launcher and Command Execution 


* **Run-Dialog-like Resolution**: Supports launching executables by typing simple names like `cmd` or `regedit` without full paths or extensions. It automatically crawls the local folder, script directory, and system `%PATH%` variables to locate files. 
* **Expanded User Scopes**: Support for executing payloads under diverse privileges:   - `NT AUTHORITY\SYSTEM` (SYSTEM token)   - `NT SERVICE\TrustedInstaller` (TrustedInstaller service token)   - `Administrator` (Built-in Local Administrator)   - `Guest` (Low-privileged Guest account)   - `Current User (Elevated)` (Standard administrative token) 
* **Command History**: Tracks and logs all successful command executions to allow quick re-selection. 
* **Credential Persistence**: Remembers typed user profile details and credentials locally inside `PsExec64-Launcher.xml` for seamless re-run capabilities. 
* **"No Password" Flag**: Option to run under target accounts without passing a password credential (useful for certain local guest accounts or specific environment setups).

### 2. Tabbed Organization 


* **Launcher Tab**: Houses the core fields: Target Command, Arguments, Scope dropdown, username, password, interactive mode, and no password toggle. 
* **Favorites Tab**: A pinned dashboard displaying custom templates with icons, titles, and descriptions. Favorites can be configured with specific settings, user scopes, variables, and custom working directories. 
* **Explorer Hot-Tracking Tiles**: Favorite tiles are rendered on white background. Hovering over a tile displays a native Windows Explorer-style light-blue gradient and blue outline. 
* **Native Large Icon Extraction**: Uses Win32 `ExtractIconEx` to pull true large 32x32 desktop icons from the target executables instead of stretched 16x16 frames.

### 3. Drag & Drop Payload Automation 


* **Instant Command Line Execution**: Drop another application directly onto the compiled executable to immediately launch it under the `NT AUTHORITY\SYSTEM` context in the background, and minimize the launcher directly to the tray.

### 4. Expanded Menus and Statusbar 


* **MenuStrip Controls**:   
- **File**: Run As (SYSTEM, Administrator shortcuts), Clear History, Minimize to Tray, Exit.   
- **Settings**: Banner Color Theme (Teal, Silver, Steel Blue), Window Opacity (100%, 90%, 80%, 70%), Configure settings.   
- **Help**: EliteSoftware Website, View Logs, User Manual, About. 
* **Statusbar Panels**: Segmented statusstrip containing live state updates, session execution count, and current theme configuration.

---

 # **🏢 PsExec64-Launcher 🏢**

<!-- Logging and Configuration -->

## 📂 Logging and Configuration


* **Settings Persistence**: Saves configurations, history, and favorites to `PsExec64-Launcher.xml` located in the same directory as the executable. 
* **Logs location**: `%SystemDrive%\EliteSoftware\Logs\PsExecDropTarget.log` with double-spaced layout formatting. 

</div>

## **🚀 What It Is** 
A privileged command launcher wrapping PsExec64 to execute system-level operations.

## Scope 


## **📋 Scope** 
* Outlines the core functions, limitations, and operational boundaries of the PsExec64-Launcher utility.

## Plans Roadmap includes UI refinements, bug fixes, and expanded compatibility options. 

## **📅 Plans** 


- UI refinements to align with classic WinForms high-density layout guidelines. 
- Dynamic registry-driven settings manager expansion. 
- Detailed operations logging enhancements.

## Development 


## **🛠️ Development** Built in accordance with EliteSoftware GUI development guidelines. 
- **Framework**: .NET Framework 4.6 / WinForms 
- **Visual Styles**: Enabled 
- **Apartment State**: STA Mode enforced for GUI reliability. 
- **Framework**: PowerShell Scripting / .NET WinForms wrapper 
- **Visual Styles**: Enabled for classic desktop theme compatibility. 
- **Apartment State**: STA Mode enforced for GUI/clipboard stability.

## What It Is 
* A dedicated system utility developed by EliteSoftwareTech Co. to perform system tasks cleanly and efficiently.

## How to Use 


1. Launch the utility. 
2. Follow the on-screen instructions or refer to tooltips for interactive elements. 
3. Access Settings from the main menu for configuration. 

## **💻 How to Use** 

1. Run the primary script in PowerShell with ExecutionPolicy set to Bypass, or launch the compiled executable. 
2. Use tooltips and controls to interact with system management features.

--- 

### EliteSoftwareTech Co. - GUI Guidelines


A dedicated system utility developed by EliteSoftwareTech Co. to perform system 


- **Company**: EliteSoftware / EliteSoftwareTech Co. 
- **Document Version**: 1.2.0.0 
- **Target Framework**: .NET Framework 4.6 (WinForms / Legacy Win32) 
- **Minimum OS Target**: Windows Vista / Windows 7 No newline at end of file 
- **Minimum OS Target**: Windows Vista / Windows 7

---

## **📜 A Note on "Vibe Coding"**

This project was built in close collaboration with Google's Gemini. Many features, design choices, and lines of code were generated or heavily influenced by AI. The goal was less about perfect, clean code and more about exploring the creative potential of human-AI partnership. It's an experiment in letting the "vibe" of an idea guide the development process.

Expect the unexpected. Embrace the chaos. And have fun!

---

## **🎨 Media Assets**

<div align="center">

 <a href='https://i.postimg.cc/DZTjtNg1/Elite-Software-Company-Simulator-LOGO.png' target='_blank'><img src='https://i.postimg.cc/DZTjtNg1/Elite-Software-Company-Simulator-LOGO.png' border='0' alt='Elite-Software-Client' width="250"></a> &nbsp;&nbsp;&nbsp;&nbsp; <a href='https://i.postimg.cc/85mKDbX8/Elite-Software-Company-Logo.png' target='_blank'><img src='https://i.postimg.cc/85mKDbX8/Elite-Software-Company-Logo.png' border='0' alt='Elite-Software-LOGO' width="250"></a> 

</div>

--- 

No newline at end of file