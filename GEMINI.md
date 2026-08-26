# 🧠 GEMINI.md - EliteBuildChain 

## 🚨 Local Project Architectural Rules

This repository (`EliteSoftware_Build-Automations`) holds the **master build tools** that will be compiled and distributed to all other EliteSoftware projects.

### 1. Toolchain Purpose
- Never write hardcoded build parameters in PowerShell scripts within this repo.
- The overarching goal of this repo is to produce generic, config-driven CLI tools (`EliteBuildChain.exe`) that can ingest `.config` files and orchestrate builds dynamically.
- The ultimate output of this repo must be highly portable standalone `.exe` binaries (either written in C++ or PS2EXE).

### 2. Compilation Rules
- All tools generated here must output to the `x86/` and `x64/` directories at the project root.
- All code logic must remain generic. E.g., when signing, do not hardcode the certificate path in the code. It must be read from the parsed `.config` file. The only exception is falling back to standard OS-level SDK directories (`C:\Program Files (x86)\Windows Kits\...`) for `signtool.exe` or `MSBuild.exe`.

### 3. Agent Navigation
- Reference `Migration_Mapping.md` to see what legacy scripts we are actively studying and replacing.
- Reference `EliteBuildChain_Architecture.md` for the overarching vision of this project.
- Reference `EliteBuildChain_ConfigSchema.md` for the unified `.config` structure we expect other projects to use.

### 4. Logging and Aesthetics
- Ensure the master GUI / CLI logs out in the classic EliteSoftware witty tone.
- If we build a WinForms UI for the build chain later, it MUST adhere strictly to the `user_global` UI guidelines (Classic 3D inset, Title Banner, Frutiger Aero).
- All prompt outputs generated during development in this folder MUST be logged into `Prompt_Outputs/` as per the global rule.

### 5. The C++ CLI Design Premise (Core Framework Rule)
All new components and standalone CLI tools built for this framework MUST adhere to the following strict guidelines:
- **Native C++ Codebase:** Tools must be written in C++ (avoiding `PS2EXE` wrappers where possible). DLL dependencies are permitted if absolutely necessary.
- **Project Awareness (Smart Defaults):** Tools must automatically infer context (e.g., pulling the repository name from the current working directory) to minimize required arguments.
- **Argument-Driven Overrides:** Every project-specific command, string, or action that would normally be hardcoded must become an argument so the tool is 100% reusable across any project.
- **Dedicated Component Documentation:** Every individual component must have its own `.md` file located at its root outlining its specific CLI features and parameters.
- **Universal Help System:** Every tool and subcommand must implement robust help flag parsing responding to `/help`, `//help`, `-help`, `--help`, `-?`, and `--?`.

## ⚙️ Environment Variables & Global Access

We have instituted a new standard for reusing the **EliteBuild CLI Tools**. Instead of dropping these 8 components into every single project folder, they only need to exist **once** globally on the system (usually residing in Z:\EliteSoftware-Projects\EliteSoftware_Build-Automations\BuildOutputx64).

To achieve this, we use the custom EliteSoftware Environment Manager UI to set up system environment variables:
*   ELITE_BUILD_X64: Points to the 64-bit compiled EXEs.
*   ELITE_BUILD_X86: Points to the 32-bit compiled EXEs.

The **Environment Manager GUI** will also append these locations to your system %PATH%, meaning you can call EliteBuild_Compiler.exe from any terminal, anywhere.

### The Entry Point (EliteBuild.exe)
For every new project, you only need to copy **one** tool into the repository root: EliteBuild.exe (The Entry Point). 
1. EliteBuild.exe reads the local .config file.
2. It looks up %ELITE_BUILD_X64% in the environment variables.
3. It seamlessly passes the instructions to the globally installed backend tools.

### The Version Bumper (EliteBuild_VersionBumper.exe)
We also include EliteBuild_VersionBumper.exe to parse files like changelog.md or ersion.h, find the X.X.X.X string, and automatically increment the Major, Minor, Feature, or Bugfix number.

### The Readme Generator (EliteReadmeGenerator.exe)
A C++ CLI utility containing 5 hardcoded Markdown templates tailored for various EliteSoftware project architectures. It takes <TemplateID>, <ProjectName>, and an optional <Tagline> to output a perfectly formatted eadme.md.
*   1 = Master Hybrid (Architecture & GUI)
*   2 = Legacy GUI Application
*   3 = Headless CLI Tool
*   4 = Client/Server Architecture
*   5 = Automation & Shell Extension
