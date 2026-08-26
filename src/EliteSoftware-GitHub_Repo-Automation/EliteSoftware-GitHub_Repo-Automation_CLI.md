<div align="center"> <a href='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' target='_blank'><img src='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' height='80' border='0' alt='Elite-Software-Company-Logo'></a> </div>

# EliteSoftware GitHub Automator (CLI Component)

**Information-First Engineering. Absolute System Purity.**

This document details the **EliteGitHubAutomator** CLI tool, written in native C++, responsible for standardizing Git and GitHub operations across all EliteSoftware projects. It is designed to be highly reusable, project-aware, and entirely argument-driven.

## 🛠️ Tool Features

- **Native C++ Execution:** Eliminates dependencies on PS2EXE wrappers and invokes `git` and `gh` system commands natively.
- **Smart Project-Aware Defaults:** The CLI automatically infers the repository name from the current working directory, requiring zero configuration for initialization in most cases.
- **Robust Argument Parsing:** Every hardcoded string (commit messages, repository visibility, release names) is now parameter-driven.
- **Comprehensive Help System:** Global and command-specific help guides built into the executable.

## 📜 Command Reference

The tool responds to `/help`, `//help`, `-help`, `--help`, `-?`, and `--?` anywhere to print detailed instructions.

### 1. `init`
Initializes a local git repository, makes an initial commit, creates the remote via `gh repo create`, and pushes.
* **Smart Default:** If `--name` is omitted, it pulls the current directory name.

**Options:**
- `--name <string>`: Override the target repository name.
- `--public`: Set the remote to public (Defaults to strictly private).
- `--msg <string>`: Customize the initial commit message.

### 2. `commit`
Auto-stages and commits all pending changes to the repository. Designed to be chained into post-build scripts.

**Options:**
- `--force`: Forcefully overwrites remote history (`git push --force`). Use with caution.
- `--msg <string>`: Customize the commit message.

### 3. `release`
Packages and drafts a comprehensive GitHub release utilizing attached binaries and release notes.

**Options:**
- `--version <string>`: **(Required)** Semantic version string (e.g., `1.0.0`).
- `--x86 <path>`: Path to attach an x86 binary or zip archive.
- `--x64 <path>`: Path to attach an x64 binary or zip archive.
- `--notes <path>`: Path to a markdown file for the body of the release notes.
- `--title <string>`: Title of the release. (Defaults to `Release v<version>`).

## 🧠 Component Philosophy
This CLI embodies the EliteSoftware goal of eliminating massive, nested PowerShell scripts. By parsing flags directly, agents and developers can reuse this single `.exe` across every project simply by varying the arguments passed to it.
