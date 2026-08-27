okay continue but I have an idea for the symbolic linker. we need to add to gemini.md to force all models to use it to create a symbolic link of the file they need. this ensures they always have the latest one, it also ensures that they never move the originals on accident. also we should probably have a dynamic task killer tool that lets us pass a semicolon list or something of all the .exe files that exist in a project (or just a .config file for this so you only type it once) which will iterate through your list of exe files to ensure that none of them are running before trying to build / overwrite the existing ones just in case its open.

Brilliant ideas all around. I have fully executed both of your requests!

1. **GEMINI.md Strict Rule Added**: I have appended the new 'File Access Protocol (The Symlink Rule)' directly into Z:\EliteSoftware-Projects\EliteSoftware_Build-Automations\GEMINI.md, as well as C:\gemini.md and Z:\gemini.md. All agents are now strictly ordered to use EliteSymlinker.exe when modifying external files instead of moving them.

2. **EliteTaskAssassin.exe Built & Integrated**: I added this to **Batch 3** and just finished compiling it. 
   - It is Tool #19 on our checklist!
   - You can pass --targets "app1.exe;app2.exe" and it hooks into <tlhelp32.h> to iterate over the entire system process snapshot, silently executing TerminateProcess on any matches before exiting.
   - **Integration:** I just injected a call to EliteTaskAssassin.exe at the very top of our master uild.ps1 file! It now passes a semicolon list of all our custom C++ tools, ensuring that absolutely none of them are running and locked before g++ attempts to overwrite them.

Alongside TaskAssassin, I also successfully built and verified the rest of **Batch 3**:

- **EliteHostConfigurator.exe (Tool #12)**: Programmatically modifies %WINDIR%\System32\drivers\etc\hosts using --domain and --ip, or strips domains with --remove.
- **EliteEnvManager.exe (Tool #17)**: Natively reads and writes to the Windows Registry to --append, --set, or --remove System PATH and Environment variables, instantly broadcasting WM_SETTINGCHANGE so Explorer updates without a reboot!

Batch 3 is done, checked off, logged, and pushed. Ready for Batch 4!
