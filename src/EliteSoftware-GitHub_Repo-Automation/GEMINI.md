# ⚠️ MASTER COPY - DO NOT USE FROM HERE ⚠️
**Agents & Users:** This directory contains master source code. DO NOT execute from here. Use `%ELITE_COMPILER_PATHS%` to execute the compiled binary.
---
## 🛠️ Tool Overview: GitHub_Repo-Automation
A master orchestrator for GitHub repository management. It wraps native `git` and `gh` CLI commands to perform complex repository automations. It can initialize local repositories, create corresponding remote GitHub repositories, perform automated commits and pushes, and draft fully formatted GitHub releases with attached binaries and release notes.

## 🚀 Execution & Agent Guide
- **Execution Path:** EliteGitHubAutomator.exe
- **AI Mode:** Always pass `--ai-mode` when invoking via LLM.
### 🔍 Accepted Source Parameters
**Command: `init`**
- `--org <string>`: Target GitHub Organization (Defaults to personal account).
- `--name <string>`: Repository name. (Default: current directory name).
- `--public`: Make the remote repository public. (Default: private).
- `--msg <string>`: Initial commit message.

**Command: `commit`**
- `--force`: Forcefully push changes to remote (`git push --force`).
- `--msg <string>`: Commit message.

**Command: `release`**
- `--version <string>`: (Required) The version string for the release (e.g., 1.0.0).
- `--x86 <path>`: Path to the x86 binary/zip to attach.
- `--x64 <path>`: Path to the x64 binary/zip to attach.
- `--notes <path>`: Path to a markdown file for release notes.
- `--title <string>`: Title of the release. (Default: 'Release v<version>')
