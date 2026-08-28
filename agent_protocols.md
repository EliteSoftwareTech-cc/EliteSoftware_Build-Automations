# agent_protocols.md

## 1. EXECUTION ENVIRONMENT
- All tools are globally accessible via %PATH% injection through EliteSoftware-EnvManager_GUI.exe
- The canonical binary vault is: Z:\EliteSoftware-Projects\EliteSoftware_Build-Automations\BuildOutputx64\
- Agents do NOT need to source any initialization script. Tools are globally available.
- The --ai-mode flag is MANDATORY for all headless agent execution

## 2. FILESYSTEM PROTOCOLS
- Safe File Deletion Protocol (Recycle Bin mandatory)
- Symlink Rule (EliteSymlinker.exe mandatory, no Copy-Item/Move-Item)
- State Ledger Protocol (agents must NEVER destructively overwrite documentation; append only with What/How/Why)

## 3. UNIFIED EXIT CODE TAXONOMY
- 0: SUCCESS
- 1: GENERAL_FAILURE (unspecified)
- 10: MISSING_CONFIGURATION (config file not found)
- 11: SCHEMA_VIOLATION (invalid argument)
- 20: HANDLE_LOCKED (target file/directory in use)
- 30: ACCESS_DENIED (requires elevation)
- 40: DEPENDENCY_MISSING (prerequisite tool not executed)
- 50: ENVIRONMENT_VARIABLE_EMPTY (required env var not set)

## 4. TOOL PARAMETER SCHEMAS
`json
{
  "tool": "EliteSoftware-ADBManager",
  "description": "The ADBManager acts as the Elite ADB FastBoot Bridge.",
  "arguments": "- `<adb arguments>`: Any arguments provided (other than `--ai-mode`) are forwarded directly to `adb`. \n    - *Example:* `ADBManager.exe --ai-mode devices`"
}
``n`json
{
  "tool": "EliteSoftware-AssetManager",
  "description": "The AssetManager is a utility designed to download remote assets via HTTP/HTTPS.",
  "arguments": "- `--url <url>`: The URL of the asset to download. \n    - *Example:* `--url https://example.com/image.png`\n  - `--out <path>`: The local file path where the downloaded asset will be saved.\n    - *Example:* `--out C:\Downloads\image.png`"
}
``n`json
{
  "tool": "EliteSoftware-BuildLocator",
  "description": "The BuildLocator is a core configuration utility that scans drives (C:, D:, Z:) for essential build tools like the MinGW toolchain.",
  "arguments": "- `--ai-mode`: Bypasses the mandatory interactive EULA prompt and automated console pauses.\n    - *Example:* `BuildLocator.exe --ai-mode`"
}
``n`json
{
  "tool": "EliteSoftware-CertManager",
  "description": "The CertManager is a security utility that installs or uninstalls `.cer` certificate files directly into the local machine's Trusted Root Certification Authorities store (`ROOT`).",
  "arguments": "- `--cert <path>`: The absolute or relative path to the `.cer` certificate file.\n    - *Example:* `--cert C:\Certs\MyRootCA.cer`\n  - `--uninstall`: If provided, the tool will attempt to remove the specified certificate from the Root store instead of installing it.\n    - *Example:* `--cert C:\Certs\MyRootCA.cer --uninstall`"
}
``n`json
{
  "tool": "EliteSoftware-ClipSaver",
  "description": "The ClipSaver is a background daemon designed to hook into the Windows clipboard (using `SetClipboardViewer`) and automatically save image data (CF_DIB) directly to disk.",
  "arguments": "- `--dir <path>`: The output directory where clipboard images will be saved. Defaults to `C:\EliteSoftware_Screenshots`.\n    - *Example:* `--dir D:\Screenshots`"
}
``n`json
{
  "tool": "EliteSoftware-CLSIDGenerator",
  "description": "The CLSIDGenerator is a lightweight utility that generates unique Component Object Model (COM) Class IDs (CLSIDs).",
  "arguments": "- `--name <program_name>`: Generates a new CLSID for the specified program name and logs it.\n    - *Example:* `--name MyComPlugin`\n  - `--list`: Iterates through the registry and lists all registered CLSIDs.\n    - *Example:* `--list`\n  - `--filter <string>`: Used in conjunction with `--list` to filter the output by the CLSID string or its registry value.\n    - *Example:* `--list --filter MyPlugin`"
}
``n`json
{
  "tool": "EliteSoftware-ComLoader",
  "description": "The ComLoader is a utility meant for dynamically registering or unregistering COM DLLs and OCX files.",
  "arguments": "- `--dll <path>`: The path to the DLL or OCX file to register/unregister.\n    - *Example:* `--dll C:\MyCom.dll`\n  - `--unregister`: Switches the behavior to call `DllUnregisterServer` instead of `DllRegisterServer`.\n    - *Example:* `--dll C:\MyCom.dll --unregister`"
}
``n`json
{
  "tool": "EliteSoftware-Compiler",
  "description": "The EliteBuild_Compiler.exe is the absolute core of the EliteSoftware master toolchain.",
  "arguments": "- --ai-mode (Bypasses EULA)\n  - --config <path> (Sets the config JSON path)\n  - /help, -help, --help, -?, --?, //help (Displays universal help)"
}
``n`json
{
  "tool": "EliteSoftware-DevServer",
  "description": "The DevServer is a PowerShell-based local development static HTTP/HTTPS file server.",
  "arguments": "- `Target` (Position 0): The path to a directory to serve, or a specific default document file to launch. Defaults to the current working directory (`$PWD`).\n    - *Example:* `.\EliteDevServer.ps1 \"C:\inetpub\wwwroot\"`\n    - *Example:* `.\EliteDevServer.ps1 \"C:\Project\index.html\"`"
}
``n`json
{
  "tool": "EliteSoftware-DocConverter",
  "description": "The DocConverter is a raw text extraction utility that flattens binary or formatted document files (like `.rtf` or `.doc`) into plain text or markdown.",
  "arguments": "- `--in <path>`: The path to the input formatted document file.\n    - *Example:* `--in \"C:\Docs\input.rtf\"`\n  - `--out <path>`: The path to the output plain text or markdown file.\n    - *Example:* `--out \"C:\Docs\output.md\"`"
}
``n`json
{
  "tool": "EliteSoftware-DotNetEnv",
  "description": "The DotNetEnv analyzer is a diagnostic tool that scans the local machine's registry (`HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP`) to detect and report which versions of the .NET Framework (v2.0, v3.0, v3.5, and v4 releases) are currently installed on the system.",
  "arguments": "- `--ai-mode`: Bypasses the interactive pause at the end of the scan.\n    - *Example:* `DotNetEnv.exe --ai-mode`"
}
``n`json
{
  "tool": "EliteSoftware-DummyDllGen",
  "description": "This tool generates a dummy DLL with specified exports.",
  "arguments": "- `--name <string>`: Output DLL Name (e.g. test.dll)\n  - `--exports <string>`: Comma separated exports (e.g. DllRegisterServer,DllUnregisterServer)"
}
``n`json
{
  "tool": "EliteSoftware-DuplicateSweeper",
  "description": "This tool recursively scans a given directory for files matching a set of specific extensions.",
  "arguments": "- `--dir <string>`: Target directory to sweep.\n  - `--ext <string>`: Target extensions, separated by '|' (e.g., `.obj|.pdb`).\n  - `--auto-delete`: Automatically deletes the matched files."
}
``n`json
{
  "tool": "EliteSoftware-EasySigner",
  "description": "Digital Authenticode signature tool (`EliteEasySigner.exe`).",
  "arguments": "  - --ai-mode: MANDATORY for headless execution"
}
``n`json
{
  "tool": "EliteSoftware-EntryPoint",
  "description": "EliteBuild.exe is the master orchestrator.",
  "arguments": "- --ai-mode (Bypasses EULA)\n  - --config <path> (Overrides the auto-discovery and targets a specific config)\n  - --tool <name> (Overrides the default execution pipeline and strictly runs a single specific tool, e.g. --tool EliteBuild_Compiler.exe)"
}
``n`json
{
  "tool": "EliteSoftware-EnvManager",
  "description": "This CLI tool manages Windows Environment Variables in the `HKEY_CURRENT_USER\Environment` registry key.",
  "arguments": "- `--var <string>`: Environment Variable Name (e.g. ELITE_BUILD_X64).\n  - `--set <string>`: Sets the variable to the specified value.\n  - `--append <string>`: Appends the specified value to the variable (delimiters are handled automatically).\n  - `--remove`: Removes the specified environment variable."
}
``n`json
{
  "tool": "EliteSoftware-EnvManager_GUI",
  "description": "A PowerShell WinForms GUI designed to easily manage the `ELITE_BUILD_X64` and `ELITE_BUILD_X86` system environment variables.",
  "arguments": "- N/A (GUI Tool; requires Administrator execution)."
}
``n`json
{
  "tool": "EliteSoftware-ExecPolToggle",
  "description": "This tool provides a rapid way to alter the PowerShell ExecutionPolicy setting within the Windows Registry.",
  "arguments": "- `--level <string>`: Execution Policy to set (e.g. Bypass, RemoteSigned, Restricted). Defaults to Bypass if left empty."
}
``n`json
{
  "tool": "EliteSoftware-EXEKiller",
  "description": "A low-level Windows process terminator.",
  "arguments": "- Arg 1 (positional): The name of the executable to kill (e.g. `Filename.exe`). Case-insensitive."
}
``n`json
{
  "tool": "EliteSoftware-FolderScanner",
  "description": "A fast, recursive C++ directory scanner that traverses a target directory and compiles statistics using the Windows FindFirstFile/FindNextFile API.",
  "arguments": "- `--dir <string>`: Target directory path to scan. (Defaults to current working directory if omitted)."
}
``n`json
{
  "tool": "EliteSoftware-GitHub_Repo-Automation",
  "description": "A master orchestrator for GitHub repository management.",
  "arguments": "**Command: `init`**\n  - `--org <string>`: Target GitHub Organization (Defaults to personal account).\n  - `--name <string>`: Repository name. (Default: current directory name).\n  - `--public`: Make the remote repository public. (Default: private).\n  - `--msg <string>`: Initial commit message.\n  **Command: `commit`**\n  - `--force`: Forcefully push changes to remote (`git push --force`).\n  - `--msg <string>`: Commit message.\n  **Command: `release`**\n  - `--version <string>`: (Required) The version string for the release (e.g., 1.0.0).\n  - `--x86 <path>`: Path to the x86 binary/zip to attach.\n  - `--x64 <path>`: Path to the x64 binary/zip to attach.\n  - `--notes <path>`: Path to a markdown file for release notes.\n  - `--title <string>`: Title of the release. (Default: 'Release v<version>')"
}
``n`json
{
  "tool": "EliteSoftware-HostConfigurator",
  "description": "A system utility for modifying the Windows `hosts` file (`System32\drivers\etc\hosts`).",
  "arguments": "- `--domain <string>`: Domain Name to configure (e.g. elitesoftwaretech.cc).\n  - `--ip <string>`: IP address to route the domain to (default is 127.0.0.1).\n  - `--remove`: Removes the domain entry from the hosts file entirely."
}
``n`json
{
  "tool": "EliteSoftware-IconReplacer",
  "description": "A sophisticated PE executable resource modification tool.",
  "arguments": "- `--exe <path>`: Path to the target EXE file to be modified.\n  - `--icon <path>`: Path to the source ICO file."
}
``n`json
{
  "tool": "EliteSoftware-InnoCreator",
  "description": "Generates Inno Setup (.iss) templates (Basic EXE, DLL Service, Full Suite) and compiles them using ISCC.exe.",
  "arguments": "- `--ai-mode`: Bypasses interactive prompts.\n  - `--generate`: Mode to generate an .iss template.\n  - `--compile`: Mode to compile an .iss file.\n  - `--template <type>`: Template type (1: Basic EXE, 2: DLL Service, 3: Full Suite). Example: `--template 1`\n  - `--out <path>`: Output file path for generated template or input file for compilation. Example: `--out setup.iss`\n  - Any other arguments are passed directly to `ISCC.exe`."
}
``n`json
{
  "tool": "EliteSoftware-LaunchAsTI",
  "description": "A utility stub for launching a process with TrustedInstaller privileges.",
  "arguments": "- `--ai-mode`: Bypasses interactive prompts.\n  - `--cmd <command>`: Command line to execute as TrustedInstaller. Example: `--cmd cmd.exe`"
}
``n`json
{
  "tool": "EliteSoftware-MetaStamper",
  "description": "Generates version information resource scripts (.rc) containing FileVersion, ProductVersion, CompanyName, etc., to be used for windres compilation.",
  "arguments": "- `--ai-mode`: Bypasses interactive prompts.\n  - `--version <version_string>`: Version string. Example: `--version 1.0.0.0`\n  - `--company <company_name>`: Company name string. Example: `--company \"EliteSoftware Co.\"`\n  - `--product <product_name>`: Product name string. Example: `--product \"EliteSoftware Component\"`\n  - `--out <file_path>`: Output .rc file path. Example: `--out version.rc`"
}
``n`json
{
  "tool": "EliteSoftware-NetworkManager",
  "description": "A network management utility stub.",
  "arguments": "- `--ai-mode`: Bypasses interactive prompts.\n  - `--flush-dns`: Flushes the DNS resolver cache. Example: `--flush-dns`"
}
``n`json
{
  "tool": "EliteSoftware-OptiLink",
  "description": "OptiLink IPC Daemon stub that can run in server or client mode to facilitate communication over a named pipe.",
  "arguments": "- `--ai-mode`: Bypasses interactive prompts.\n  - `--server`: Runs the daemon in server mode (default is client). Example: `--server`\n  - `--target <pipe_name>`: Specifies target named pipe. Example: `--target \\.\pipe\EliteOptiLink`"
}
``n`json
{
  "tool": "EliteSoftware-Packager",
  "description": "Reads an `EliteBuild.config` (JSON) file to orchestrate packaging operations.",
  "arguments": "- `--ai-mode`: Bypasses interactive EULA and wait prompts.\n  - `/help`, `-help`, `--help`, `-?`, `--?`, `//help`: Shows help message.\n  - `--config <path>`: Specify a custom `.config` path (default: `EliteBuild.config`). Example: `--config build.config`"
}
``n`json
{
  "tool": "EliteSoftware-PIDKiller",
  "description": "A direct utility for forcefully terminating a process by its PID using the Win32 `OpenProcess` and `TerminateProcess` APIs.",
  "arguments": "- `<pid>`: The Process ID to kill. Passed as the first argument. Example: `ElitePIDKiller.exe 1234`"
}
``n`json
{
  "tool": "EliteSoftware-ProfileManager",
  "description": "Injects the EliteSoftware environment (aliases and functions like `ll` and `Reload-Profile`) into the user's PowerShell profile script (`Microsoft.PowerShell_profile.ps1`).",
  "arguments": "- `--ai-mode`: Bypasses interactive prompts."
}
``n`json
{
  "tool": "EliteSoftware-ProjectBackup",
  "description": "Creates full backups of a specified project directory (excluding Backups and .git folders).",
  "arguments": "- `--ai-mode`: Bypasses interactive prompts.\n  - `--dir <path>`: The project directory to backup (defaults to current working directory). Example: `--dir C:\Project`\n  - `--out <path>`: The output directory for the backup (defaults to `targetDir\Backups`). Example: `--out C:\Backups`\n  - `--cab`: Uses `makecab.exe` to create a `.cab` archive instead of the default `.wim` image. Example: `--cab`"
}
``n`json
{
  "tool": "EliteSoftware-PSWrapper",
  "description": "A CLI wrapper that invokes `Invoke-PS2EXE` to compile PowerShell scripts (`.ps1`) into native Windows executables (`.exe`), with options to control console visibility, threading model, and custom icons.",
  "arguments": "- `--ai-mode`: Bypasses interactive prompts.\n  - `--ps1 <file>`: Path to the source `.ps1` script. Example: `--ps1 source.ps1`\n  - `--exe <file>`: Path for the output `.exe` file. Example: `--exe output.exe`\n  - `--icon <file>`: Path to the `.ico` file to embed. Example: `--icon app.ico`\n  - `--disable-sta`: Disables Single-Threaded Apartment (STA) mode (STA is default for UI scripts). Example: `--disable-sta`\n  - `--show-console`: Retains the console window (removes `-noConsole` flag). Example: `--show-console`"
}
``n`json
{
  "tool": "EliteSoftware-RCManager",
  "description": "EliteRCManager is a native C++ utility that automates the generation of Resource Script (`.rc`) files and compiles them into compiled Resource (`.res`) objects using `windres`.",
  "arguments": "- `--rc <path>`: Specifies the output `.rc` file path (e.g., `--rc app.rc`).\n  - `--res <path>`: Specifies the output `.res` file path to be compiled by windres (e.g., `--res app.res`).\n  - `--icon <path>`: (Optional) Path to an `.ico` file to embed into the generated `.rc` file.\n  - `--ai-mode`: Bypasses interactive prompts to allow headless execution."
}
``n`json
{
  "tool": "EliteSoftware-ReadmeGenerator",
  "description": "EliteReadmeGenerator is a C++ CLI utility that generates standardized `readme.md` files based on predefined EliteSoftware templates.",
  "arguments": "- `<TemplateID>`: Positional argument 1. An integer from 1 to 5 specifying the template to use (e.g., `1` for Master Hybrid).\n  - `<ProjectName>`: Positional argument 2. The name of the project (e.g., `Elite-Taskbar`).\n  - `[Tagline]`: Positional argument 3 (Optional). A tagline string. Defaults to \"An EliteSoftware Engineering Initiative.\"\n  - `/help`, `-help`, `-?`: Displays the help and usage menu.\n  - `--ai-mode`: Bypasses the interactive EULA prompt and input prompts to allow headless execution. Can be passed anywhere in the command line."
}
``n`json
{
  "tool": "EliteSoftware-RegSnapshot",
  "description": "EliteRegSnapshot is a lightweight C++ utility designed to capture and restore snapshots of Windows Registry keys.",
  "arguments": "- `--key <registry_key>`: Specifies the registry key to snapshot/export (e.g., `--key HKLM\Software\Classes\CLSID`).\n  - `--export <path>`: Specifies the output `.reg` file path to save the snapshot to (e.g., `--export backup.reg`).\n  - `--restore <path>`: Specifies a `.reg` file to import/restore into the registry (e.g., `--restore backup.reg`).\n  - `--ai-mode`: Bypasses interactive prompts to allow headless execution."
}
``n`json
{
  "tool": "EliteSoftware-RepoCloner",
  "description": "EliteRepoCloner is a C++ automation tool designed to parse a configuration file containing a list of git repository URLs and bulk clone them into a designated target directory.",
  "arguments": "- `--config <path>`: Path to a text file containing git repository URLs, one per line (e.g., `--config repos.txt`). Defaults to `repos.txt`.\n  - `--dir <path>`: Target directory where repositories will be cloned (e.g., `--dir \"C:\MyRepos\"`). Defaults to `Z:\EliteSoftware-Projects`.\n  - `--ai-mode`: Bypasses interactive prompts to allow headless execution."
}
``n`json
{
  "tool": "EliteSoftware-ServiceForge",
  "description": "EliteServiceForge is a native C++ utility that interacts directly with the Windows Service Control Manager (SCM) to create or remove Windows Services.",
  "arguments": "- `--name <string>`: The short system name of the service (e.g., `--name EliteAppSvc`).\n  - `--display <string>`: The human-readable display name of the service (e.g., `--display \"Elite Application Service\"`). Defaults to the service name if omitted during creation.\n  - `--bin <path>`: Absolute path to the service executable binary (e.g., `--bin \"C:\App\svc.exe\"`). Required for creation.\n  - `--remove`: Flag indicating the tool should delete the service specified by `--name` instead of creating it.\n  - `--ai-mode`: Bypasses interactive prompts to allow headless execution."
}
``n`json
{
  "tool": "EliteSoftware-ShortcutForge",
  "description": "EliteShortcutForge is a native C++ Windows utility that uses COM and `IShellLink` APIs to programmatically generate Windows Shortcuts (`.lnk` files).",
  "arguments": "- `--target <path>`: The absolute path to the target executable or file the shortcut points to (e.g., `--target \"C:\app.exe\"`).\n  - `--out <path>`: The output path where the `.lnk` file will be created (e.g., `--out \"C:\Desktop\App.lnk\"`).\n  - `--icon <path>`: (Optional) The path to an `.ico` file to use as the shortcut icon.\n  - `--args <string>`: (Optional) Command-line arguments to embed in the shortcut.\n  - `--workdir <path>`: (Optional) The working directory (Start in) path for the shortcut.\n  - `--ai-mode`: Bypasses interactive prompts to allow headless execution."
}
``n`json
{
  "tool": "EliteSoftware-SiteCompiler",
  "description": "EliteSiteCompiler is a lightweight C++ tool designed to compile multiple Markdown (`.md`) files from a directory into a single JSON-like JavaScript file.",
  "arguments": "- `--dir <path>`: Target directory containing the `.md` files to compile (e.g., `--dir ./docs`). Defaults to `.` (current directory).\n  - `--out <path>`: The output JavaScript file path (e.g., `--out DocsData.js`). Defaults to `DocsData.js`.\n  - `--ai-mode`: Bypasses interactive prompts to allow headless execution."
}
``n`json
{
  "tool": "EliteSoftware-SmartRegsvr",
  "description": "EliteSmartRegsvr is an intelligent native C++ utility that registers COM DLLs and ActiveX controls dynamically.",
  "arguments": "- `--file <path>`: The path to the DLL or PE file to register (e.g., `--file \"C:\MyControl.dll\"`). It also supports receiving the path as a positional argument.\n  - `--ai-mode`: Bypasses interactive prompts to allow headless execution."
}
``n`json
{
  "tool": "EliteSoftware-Symlinker",
  "description": "EliteSymlinker is a native C++ utility that interacts directly with the Windows API to create various forms of file links.",
  "arguments": "- `--source <path>`: The target path that already exists (e.g., `--source \"C:\original_file.txt\"`).\n  - `--link <path>`: The path where the new link or shortcut will be created (e.g., `--link \"C:\link_file.txt\"`).\n  - `--type <sym|hard|junction>`: The type of link to create. Defaults to `sym`.\n  - `--ai-mode`: Bypasses interactive prompts to allow headless execution."
}
``n`json
{
  "tool": "EliteSoftware-SystemRestore",
  "description": "EliteSystemRestore is a C++ wrapper utility that interacts directly with the Windows System Restore API (`srclient.dll`).",
  "arguments": "- `--desc <string>`: A descriptive name for the restore point (e.g., `--desc \"Before EliteApp Install\"`). Defaults to \"EliteSoftware Auto-Snapshot\".\n  - `--ai-mode`: Bypasses interactive prompts to allow headless execution."
}
``n`json
{
  "tool": "EliteSoftware-TaskAssassin",
  "description": "A native C++ command line utility designed to aggressively terminate running processes by their executable names.",
  "arguments": "- `--targets <processes>`: A semicolon-delimited string of target executable names to kill. (e.g., `--targets notepad.exe;calc.exe`)"
}
``n`json
{
  "tool": "EliteSoftware-VersionBumper",
  "description": "A native C++ command line utility built to recursively scan a project directory and automatically synchronize or bump a 4-decimal version number across source code, headers, resource scripts (.rc), powershell scripts, config files, and markdown files.",
  "arguments": "- `<ProjectPath>`: The target directory to recursively scan. Use `.` for the current directory.\n  - `<NewVersion>`: The new 4-decimal target version. (e.g., `1.0.42.6`)\n  Example usage: `EliteVersionBumper.exe \"C:\MyProject\" \"1.0.42.6\"`"
}
``n`json
{
  "tool": "EliteSoftware-VSBuildTools",
  "description": "A native C++ utility acting as a stub/bootstrapper to verify and trigger the installation of Visual Studio Build Tools.",
  "arguments": "- Does not explicitly parse named command-line arguments beyond `--ai-mode` in the current stub version."
}
``n`json
{
  "tool": "EliteSoftware-Win7Enabler",
  "description": "A native C++ command line utility designed to modify system registry configurations to enable Windows 7 Extended Security Updates (ESU).",
  "arguments": "- Does not explicitly parse named command-line arguments beyond `--ai-mode`."
}
``n`json
{
  "tool": "IconManager_CLI",
  "description": "A comprehensive native C++ utility for image and icon manipulation.",
  "arguments": "- `<input_file(s)>`: Path to the image or PE binary to process.\n  - `[output_file]`: Target output file path (optional).\n  - `--remove-halo`: Removes classic magenta/pink transparency backgrounds.\n  - `--remove-bg`: Smart auto-edge background flood-fill removal.\n  - `--remove-bg-white`, `--remove-bg-black`, `--remove-bg-tl`, `--remove-bg-tr`, `--remove-bg-bl`, `--remove-bg-br`: Specific corner or color-based background removal methods."
}
``n`json
{
  "tool": "IcoToPngConverter_CLI",
  "description": "A PowerShell-based utility that extracts all embedded resolution frames from `.ico` files and saves them as individual `.png` files.",
  "arguments": "- `[string[]]$DroppedFiles`: A list of file paths (implicitly via positional arguments or drag-and-drop)."
}
``n`json
{
  "tool": "ResourceAlchemyHacker_CLI",
  "description": "A high-performance native C++ command-line backend for advanced manipulation of resources within Windows PE binaries (executables, DLLs, MUI, MUN).",
  "arguments": "- `/list <TARGET_EXE>`: Enumerates all resources.\n  - `/extract <TARGET_EXE> <TYPE> <NAME> <LANG> <OUTPATH>`: Extracts a specific resource to disk.\n  - `/replace <TARGET_EXE> <TYPE> <NAME> <LANG> <INPATH>`: Replaces a resource. (Alias: `/add`)\n  - `/delete <TARGET_EXE> <TYPE> <NAME> <LANG>`: Deletes a resource.\n  - `/flatten <TARGET_BASE> <TARGET_MUN> <TARGET_MUI>`: Flattens separated MUN/MUI files into the base binary."
}
``n`json
{
  "tool": "FileSplitter_GUI",
  "description": "A native Win32/WinForms C++ GUI wrapper for file splitting operations.",
  "arguments": "- Primarily a GUI application; no explicit command-line flags besides `--ai-mode`."
}
``n`json
{
  "tool": "PsExec64Launcher_GUI",
  "description": "A highly detailed legacy-styled WinForms GUI built in PowerShell to act as a frontend for launching executables via PsExec64 under the SYSTEM context.",
  "arguments": "- Accepts arbitrary file paths via `$args` (drag-and-drop functionality).\n  - `//NTAS`: Flag to trigger automated `NT AUTHORITY\SYSTEM` execution mode for a dropped file."
}
``n`json
{
  "tool": "ResourceAlchemyHacker_GUI",
  "description": "A comprehensive Win32 C++ graphical user interface for PE binary resource manipulation.",
  "arguments": "- `<TargetFile>`: Implicitly accepts a file path to load on launch (used by the Shell Extension)."
}
``n
## 5. WORKFLOW DEPENDENCY GRAPHS (DAG)

### Full Build & Release Pipeline
EliteSoftware-VersionBumper -> EliteSoftware-Compiler -> EliteSoftware-RCManager -> EliteSoftware-IconReplacer -> EliteSoftware-EasySigner -> EliteSoftware-Packager -> EliteSoftware-GitHub_Repo-Automation (release)

### Icon Asset Pipeline
IconManager_CLI (create .ico) -> EliteSoftware-RCManager (compile .rc to .res) -> EliteSoftware-Compiler (link .res) -> EliteSoftware-IconReplacer (inject into existing PE)

### Repository Scaffolding Pipeline
EliteSoftware-GitHub_Repo-Automation (init) -> EliteSoftware-ReadmeGenerator -> EliteSoftware-Symlinker (link EliteBuild.exe)

