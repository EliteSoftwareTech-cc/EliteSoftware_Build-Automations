clsid generator should also not be able to generate new ids that are the same as existing native windows ids. as the tool will most likely be used by just parsing the string there would be no way of knowing until it was too late. however what if it did also have the ability to list CLSIDs and GUIDs of the system and tell us their corresponding component names? that way if someone is modifying system files they can look up the correct clsid to use so their modified file properly impersoates the file they are aiming for. also need a fool-proof way to ensure that the ai agents dont accidentally move the files instead of copying them when they need them. lastly I would like you to make me a tool that we can use to backup entire project folders at once the tool will output WIM image files by default buy an argument can make it output CAB files instead. this would now be part of the tool chain and guides to keep incremental wim backups that should auto complete after each successful build. also we need a way for each projects copies of any build tools if they have any (Our build tools we have in this project not MSbuild) we need a way for them to know if they are not the same version or not latest versions.

Another major upgrade complete! Here is how I implemented these new features:

1. **CLSID Generator Auto-Collision & Lookup (EliteCLSIDGenerator.exe)**:
   - I updated the generator's core logic. If CoCreateGuid happens to generate an ID that already exists in HKCR\CLSID, it will automatically loop and generate a new one until it finds an absolutely unique ID. 
   - I added a new --list argument (or type --list in interactive mode) which iterates through the entire HKEY_CLASSES_ROOT\CLSID registry hive. It lists out every registered CLSID and its corresponding component name so you can easily lookup existing IDs for impersonation!

2. **AI Move-Protection Protocol**:
   - I have appended a strict rule to all GEMINI.md files: Agents are explicitly forbidden from using Move-Item or mv on files within the Master Tool directories (BuildOutput). They must only copy or execute them in place.

3. **New Tool: Project Backup (EliteProjectBackup.exe)**:
   - I built a native C++ utility that captures entire project directories. By default, it interfaces with dism.exe to compile high-compression .wim files, avoiding large uncompressed folders.
   - If passed the --cab flag, it generates a native .ddf directive file on the fly and utilizes makecab.exe to output standard .cab archives.
   - **Toolchain Integration**: I have updated EliteBuild.exe (The Entry Point) so that the Project Backup step is now appended automatically at the end of the default build chain pipeline. Incremental backups will now trigger after every successful build.

4. **Build Tool Version Sync (EliteBuild.exe --check-version)**:
   - I added a new --check-version argument to the EliteBuild.exe orchestrator. 
   - When run, it reads the local directory for any copies of the Elite build tools, parses %ELITE_BUILD_X64% to find the master copies, and actively compares their last_write_time metadata. If a local copy is older than the master framework copy, it throws a loud warning alerting you that the local tool is out of date!
