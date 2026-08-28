# ⚠️ MASTER COPY - DO NOT USE FROM HERE ⚠️

**Agents & Users:** This directory (`src/IconManager_CLI`) contains the master source code for the `IconManager_CLI` module. 
**DO NOT** execute the binary from this folder. The compiled, globally accessible binary resides in `Local_Build_Tools\` (and `BuildOutputx64\`) and is mapped system-wide via the `%ELITE_COMPILER_PATHS%` variable.

---

## 🛠️ Tool Overview: IconManager_CLI

Pragmatically converts images into multi-resolution `.ico` containers, or batch extracts embedded icons from PE binaries.

## 🚀 Execution & Agent Guide
- **Execution Path:** The live tool is invoked as `IconManager_CLI.exe`.
- **Global Pathing:** Do not use absolute paths to invoke this tool. Because `%ELITE_COMPILER_PATHS%` is registered, you can invoke it headlessly from anywhere.
- **AI Mode:** Always pass the `--ai-mode` flag when invoking via an LLM agent to bypass EULA prompts and avoid terminal deadlocks.
- **Config Driven:** For tools that support configurations, pass `--config <path_to_config.json>` to securely orchestrate tasks.

*Note: If you need to modify the logic of this tool, modify the `.cpp` or `.ps1` files inside this directory, then run `EliteBuild.exe` from the project root to compile the updates back into `Local_Build_Tools`.*


### 🔍 Autodetected Source Parameters (Reference)
Based on deep-scanning the source code in this directory, the following arguments/flags are actively parsed by this tool:
- `--remove-bg`
- `--remove-bg-bl`
- `--remove-bg-black`
- `--remove-bg-br`
- `--remove-bg-tl`
- `--remove-bg-tr`
- `--remove-bg-white`
- `--remove-halo`
