# ⚠️ MASTER COPY - DO NOT USE FROM HERE ⚠️

**Agents & Users:** This directory (`src/EliteSoftware-GitHub_Repo-Automation`) contains the master source code for the `EliteSoftware-GitHub_Repo-Automation` module. 
**DO NOT** execute the binary from this folder. The compiled, globally accessible binary resides in `Local_Build_Tools\` (and `BuildOutputx64\`) and is mapped system-wide via the `%ELITE_COMPILER_PATHS%` variable.

---

## 🛠️ Tool Overview: EliteSoftware-GitHub_Repo-Automation

Headless CLI tool to interact with the GitHub API, auto-commit, and publish releases.

## 🚀 Execution & Agent Guide
- **Execution Path:** The live tool is invoked as `EliteBuild_GitHub_Repo-Automation.exe`.
- **Global Pathing:** Do not use absolute paths to invoke this tool. Because `%ELITE_COMPILER_PATHS%` is registered, you can invoke it headlessly from anywhere.
- **AI Mode:** Always pass the `--ai-mode` flag when invoking via an LLM agent to bypass EULA prompts and avoid terminal deadlocks.
- **Config Driven:** For tools that support configurations, pass `--config <path_to_config.json>` to securely orchestrate tasks.

*Note: If you need to modify the logic of this tool, modify the `.cpp` or `.ps1` files inside this directory, then run `EliteBuild.exe` from the project root to compile the updates back into `Local_Build_Tools`.*


### 🔍 Autodetected Source Parameters (Reference)
Based on deep-scanning the source code in this directory, the following arguments/flags are actively parsed by this tool:
- `--ai-mode`
- `--force`
- `--help`
- `--msg`
- `--name`
- `--notes`
- `--org`
- `--private`
- `--public`
- `--title`
- `--version`
- `--x64`
- `--x86`
- `-help`
