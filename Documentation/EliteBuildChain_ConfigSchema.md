<div align="center"> <a href='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' target='_blank'><img src='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' height='80' border='0' alt='Elite-Software-Company-Logo'></a> </div>

# EliteBuildChain Config Schema

**Information-First Engineering. Absolute System Purity.**

Every project migrating to the new EliteBuildChain framework will utilize a single configuration file named `EliteBuild.config` placed in the project root. The toolchain executables will parse this file (JSON or INI format; JSON presented below) to automate builds without interactive prompts.

## 📄 Proposed Schema Example (`EliteBuild.config`)

```json
{
  "ProjectName": "ResourceAlchemyHacker",
  "TargetArchitectures": ["x86", "x64"],
  
  "PreBuild": {
    "KillProcesses": [
      "ResourceAlchemyHacker_GUI.exe", 
      "ResourceAlchemyHacker_CLI.exe"
    ],
    "VersionBumpFile": "version.h",
    "VersionRegex": "#define RAH_VERSION L\"(.*?)\""
  },

  "Compiler": {
    "SlnPaths": [
      "ResourceAlchemyHacker.sln"
    ],
    "MSBuildPath": "C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\MSBuild\\Current\\Bin\\MSBuild.exe",
    "GccTargets": [
      {
        "Output": "../HostsURL_Redirector_UI.dll",
        "IsShared": true,
        "Sources": ["dll_main.cpp", "dll_res.o", "exports.def"],
        "Libraries": ["-mwindows", "-lcomctl32", "-lws2_32", "-lwininet", "-liphlpapi", "-lpsapi"],
        "Windres": {
          "Input": "dll_res.rc",
          "Output": "dll_res.o"
        }
      }
    ],
    "CustomScripts": [
      "Scripts/pre_build.bat"
    ]
  },

  "Signer": {
    "PfxPath": "C:\\EliteSoftware PE TOOLS\\Elite-EasySigner\\EliteSoftware_Special.pfx",
    "PfxPasswordEnvVar": "ELITE_SIGN_PASS", 
    "Targets": [
      "Output/x64/Release/ResourceAlchemyHacker_CLI.exe",
      "Output/x86/Release/ResourceAlchemyHacker_CLI.exe",
      "Output/x64/Release/ResourceAlchemyHacker_GUI.exe",
      "Output/x86/Release/ResourceAlchemyHacker_GUI.exe",
      "Output/x64/Release/ResourceAlchemyHacker_ShellExt.dll",
      "Output/x86/Release/ResourceAlchemyHacker_ShellExt.dll"
    ]
  },

  "Packager": {
    "GenerateDocs": true,
    "DocsSourceDir": "./",
    "DocsOutputPdf": "ResourceAlchemyHacker_Documentation.pdf",
    "InnoSetupScripts": [
      "Installer/setup_x64.iss",
      "Installer/setup_x86.iss"
    ],
    "ZipOutput": true,
    "ZipNameTemplate": "ResourceAlchemyHacker_{arch}.zip"
  },

  "Publisher": {
    "GitAutoCommit": true,
    "CommitMessageTemplate": "Auto-build and release v{version}",
    "PushBranch": "master",
    "ExtractChangelog": true,
    "ChangelogFile": "changelog.md",
    "GitHubRelease": true,
    "UploadArtifacts": [
      "Output/x64/ResourceAlchemyHacker_x64.zip",
      "Output/x86/ResourceAlchemyHacker_x86.zip",
      "Installer/ResourceAlchemyHacker_Installer_x64_{version}.exe",
      "Installer/ResourceAlchemyHacker_Installer_x86_{version}.exe"
    ]
  }
}
```

## ⚙️ Execution Flow

When a developer (or AI Agent) runs `EliteBuild.exe --all`, the executable will:
1. Parse `EliteBuild.config`.
2. Stop listed processes.
3. Call the `Compiler` module to build MSBuild targets.
4. Call the `Signer` module to locate `signtool.exe` and sign binaries.
5. Call the `Packager` module to generate PDFs and ZIP archives.
6. Call the `Publisher` module to execute `git add`, `git commit`, `git push`, and `gh release create`.

This eliminates the need for 200+ line PowerShell scripts scattered across `Run_Program\AddHardware\`, `Local_APK_Store`, `File_Splitter_ForAI-Upload`, and `Elite-TaskBar`.
