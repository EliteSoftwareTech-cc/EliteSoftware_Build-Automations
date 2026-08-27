go through this and compile a list of components we could refactor as c++ and use for this project / purpose. EliteSoftware build automation, file prep/modification anything that could be made to be a single exe that accepts reusable dynamic arguments. not sure if all the scripts work//still work but I want them to be C++ tools so you would have to conver the logic and stuff but please make a list of all the ones and or you can even send copies of the files to the project folder too just dont alter originals and remember that we dont want ps1 files for the end product here. you have no limits here take your time and really think through it like if something is done often enough and is a lot of steps commands or other whatever we can make it way less! Z:\EliteSoftware-Projects\EliteSoftware-ScriptTools-Archive\PowerShell-Script_Archive

I did a deep dive through Z:\EliteSoftware-Projects\EliteSoftware-ScriptTools-Archive and identified 7 high-impact PowerShell scripts that we should absolutely refactor into native C++ CLI tools.

I have safely copied these 7 original .ps1 files into a new folder here: Z:\EliteSoftware-Projects\EliteSoftware_Build-Automations\Future_Refactor_References. Your original files were NOT altered in any way.

Here is the master plan for what these will become when we rewrite them in C++:

### 1. EliteMetaStamper.exe (from MetaData Editor Tool.PS1)
- **What it will do:** Directly injects or modifies the RT_VERSION resource block in compiled .exe or .dll files.
- **Why we need it in C++:** Currently, we bump versions in .config files (EliteVersionBumper.exe), but modifying the actual compiled PE metadata (File Version, Copyright, Product Name) requires a dedicated Win32 resource tool to avoid breaking binary integrity.

### 2. EliteShortcutForge.exe (from Create-Shortcuts.PS1)
- **What it will do:** Natively creates Windows .lnk shortcut files without needing WScript/COM objects via PowerShell.
- **Why we need it in C++:** Many compiled GUI projects need shortcuts generated in the BuildOutput folder or on the Desktop post-compilation. A native C++ CLI makes this instant and handles custom icons dynamically.

### 3. EliteSymlinker.exe (from Link & Mover Utility.PS1)
- **What it will do:** High-speed creation of NTFS Hard Links, Symbolic Links, and Directory Junctions.
- **Why we need it in C++:** Crucial for sharing large assets (like the upcoming EliteIcons.dll) across multiple project folders without eating up disk space with physical file duplicates.

### 4. EliteDuplicateSweeper.exe (from FileScanner_and_DuplicateFinder.PS1)
- **What it will do:** Rapidly scans build directories to find and purge duplicate output files, temporary .obj files, or abandoned .pdb debug symbols.
- **Why we need it in C++:** Keeps the project repositories perfectly clean ("Absolute System Purity") before packaging or committing to GitHub.

### 5. EliteDocConverter.exe (from Doc-Docx to TXT Converter.ps1)
- **What it will do:** Headless conversion of .rtf, .doc, or .docx files into flat .md or .txt files.
- **Why we need it in C++:** If older documentation is dropped into a project, this instantly flat-files it so that LLM agents (like myself) can natively read and parse it without binary interference.

### 6. ElitePSWrapper.exe (from PS1_2_EXE.PS1)
- **What it will do:** A strict C++ build wrapper that interfaces with the PS2EXE module, but automatically enforces EliteSoftware global standards.
- **Why we need it in C++:** Forces -STA, -noConsole, and injects the correct DLL fallback icon logic automatically. Removes the chance of human error when compiling PowerShell GUI tools.

### 7. EliteRegSnapshot.exe (from RegistryBackup_Inator.PS1)
- **What it will do:** Takes instantaneous snapshots of specific Windows Registry hives/keys (like HKCR\CLSID) before and after a build or installation.
- **Why we need it in C++:** When registering new COM DLLs (EliteSmartRegsvr.exe) or shell extensions, this acts as a safety net to immediately roll back the registry if a build fails.
