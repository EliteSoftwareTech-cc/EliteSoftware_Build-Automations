get website ready for this suite using Z:\EliteSoftware-Projects\EliteSoftware_HTML_Assembler\EliteSoftwareTech-Site-Main_Landing-Page as strict layout and design template. all other information can be purged for this portion. 

please make another tool that is called PID-KILLER and another called EXE-KILLER all it does is asks for a "Filename.exe" or PID and kills it then exits.
continue

I have deployed your gorgeous web template and built the two new assassin tools! 

### 1. The Aero Website Integration
I navigated to your `EliteSoftwareTech-Site-Main_Landing-Page` template, extracted the pristine Frutiger Aero CSS, the taskbar navigation layout, and the `glass-box` main content frames.
I then **purged** all the hardcoded sample text/links from the template, and injected our `DocsData.js` parsing engine directly into it!
Now, your `index.html` uses the absolute full visual aesthetic of your real homepage, but dynamically builds the top navigation tabs based on the `.md` files in our repository, and seamlessly renders their Markdown inside the beautiful `glass-box`! 

### 2. PID-KILLER & EXE-KILLER Created
I scaffolded and compiled two lightning-fast native C++ Win32 process executioners:
- **`ElitePIDKiller.exe` (PID-KILLER)**: Prompts for (or accepts via `--pid`) a process ID. It natively binds `OpenProcess(PROCESS_TERMINATE)` and instantly wipes the PID from memory.
- **`EliteEXEKiller.exe` (EXE-KILLER)**: Prompts for (or accepts via `--exe`) a target like `notepad.exe`. It sweeps the system using `CreateToolhelp32Snapshot`, finds every single process with a matching name, and bulk-terminates them.

### Documentation Updated
- Both tools have been added as the start of **Phase 4 (Active Interceptors)** in the `Refactoring_Checklist.md`.
- Both tools have been written into the `Tool_Catalogue.md`.
- `build.ps1` has been updated to compile all 47 utilities.

Everything is logged into `Prompt_Outputs/` and pushed to your remote repository! We are moving extremely fast. Ready to continue!
