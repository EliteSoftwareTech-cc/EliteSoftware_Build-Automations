# ⚠️ MASTER COPY - DO NOT USE FROM HERE ⚠️
**Agents & Users:** This directory contains master source code. DO NOT execute from here. Use `%ELITE_COMPILER_PATHS%` to execute the compiled binary.
---
## 🛠️ Tool Overview: IconManager_CLI
A comprehensive native C++ utility for image and icon manipulation. It can convert images into multi-resolution `.ico` files, extract RT_BITMAP, RT_RCDATA, and RT_ICON resources from compiled PE binaries, and generate scaled image formats. Features advanced flood-fill background removal algorithms.
## 🚀 Execution & Agent Guide
- **Execution Path:** `icon_maker.exe`
- **AI Mode:** Always pass `--ai-mode` when invoking via LLM.
### 🔍 Accepted Source Parameters
- `<input_file(s)>`: Path to the image or PE binary to process.
- `[output_file]`: Target output file path (optional).
- `--remove-halo`: Removes classic magenta/pink transparency backgrounds.
- `--remove-bg`: Smart auto-edge background flood-fill removal.
- `--remove-bg-white`, `--remove-bg-black`, `--remove-bg-tl`, `--remove-bg-tr`, `--remove-bg-bl`, `--remove-bg-br`: Specific corner or color-based background removal methods.
