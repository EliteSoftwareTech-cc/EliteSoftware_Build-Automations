# Original User Request

## 2026-07-29T11:55:53Z

<USER_REQUEST>
# Teamwork Project Prompt — Draft

> Status: Step 9 — Assemble and Validate (Awaiting user approval)
> Goal: Craft prompt → get user approval → delegate to teamwork_preview

A C++ Win32 native styled GUI application (Windows Vista and up) that splits large text-based files into smaller `.txt` chunks based on configurable character or line limits. It supports single and batch file processing, saving the resulting parts into subfolders named after the original files.

Working directory: ~/teamwork_projects/file_splitter_cxx
Integrity mode: development

## Requirements

### R1. Core Splitting Logic
The application must split large text files into smaller files that do not exceed a configurable maximum character count or line count. The resulting files must be saved with a `.txt` extension in a new subfolder named after the original file. The logic should handle single files or batch processing of multiple files.

### R2. GUI Configuration & Interaction
The application must provide a graphical interface allowing the user to select input files, specify the splitting mode (by lines or by characters), input the maximum limit, and initiate the process.

### R3. Legacy Aesthetic Guidelines (EliteSoftwareTech Co.)
The UI must be implemented in C++ (Win32 API) but strictly adhere to the EliteSoftwareTech Co. visual guidelines:
- A distinct Title Banner at the top.
- A 3D-like Inset shadow for the main active area.
- A darker "Chin" at the bottom behind the standard convention buttons (e.g., "Okay", "Cancel").
- Segoe UI Semibold/Regular fonts.
- Accurate and slightly witty tooltips for all interactive elements.

## Acceptance Criteria

### Core Splitting Logic Verification
- [ ] A programmatic test (e.g., a Python script or a C++ unit test) can take a 10,000-character test file and split it by 3,000 characters. The test passes if the output is exactly 4 files in a subfolder, none exceeding 3,000 characters, and their concatenated content equals the original file.

### GUI Guidelines Adherence
- [ ] Code inspection confirms the use of Win32 API to create a main form with a top banner, a 3D inset client edge, and a bottom chin.
- [ ] Code inspection confirms the use of Segoe UI fonts and standard button labels (never "OK").
- [ ] Code inspection confirms that tooltips are implemented for all buttons and text inputs.

---
*Next: when approved → delegate via invoke_subagent (see Delegation Protocol)*
</USER_REQUEST>

## Follow-up — 2026-07-29T12:07:15Z

<USER_REQUEST>
Additional requirements for the project that must be incorporated immediately:

1. **Tooltips**: Tooltips for all interactive elements must be highly detailed and multi-line. They must explain the implications of all options, cover all states of the item, and maintain the slightly witty undertone.
2. **Build System**: Create a `Scripts` folder and a `Build.ps1` file in the project root. `Build.ps1` will act as an orchestrator for a consecutive script build chain (each step being its own script in the `Scripts` folder) and manage excessively verbose colorfold and organized output. Builds must output exclusively to `BuildOutput` and `BuildOutputx86` in the project root. All builds must target a minimum OS of Windows Vista and produce both 32-bit and 64-bit versions.
3. **Dynamic Icon**: The application must dynamically look for an `.ico` file that shares the exact same name as the executable (e.g., `program.exe` looks for `program.ico`) in its directory. This dynamic icon takes precedence over any embedded icon and must be applied to the titlebar, taskbar, and banner, allowing users to sideload an icon easily.
</USER_REQUEST>

## Follow-up — 2026-07-29T12:12:22Z

<USER_REQUEST>
Additional requirement:

1. **Live Agent HTML Thread**:
- Create an `Agent-Thread_HTML` folder in the project root.
- Inside it, create an HTML file that dynamically loads sub-files to act as a continuous live thread of messages from each agent.
- Each agent must have a distinct name and color in the thread.
- As the agents work, they must output their detailed turn summaries (or copy/paste) directly to a designated sub-file loaded by the HTML to maintain this live feed.
- The HTML page must have a second tab that displays a fully historical view of the agents' inter-communications and thoughts.
- Create a `gemini.md` file in this folder with detailed instructions on how the HTML file works and how the agents append data to it.

Please ensure the Orchestrator and the team adapt their plan to build this HTML UI first or concurrently, and that all agents begin appending their status updates to it as requested.
</USER_REQUEST>

## Follow-up — 2026-07-29T12:16:16Z

<USER_REQUEST>
As soon as the team finishes building the HTML previewer (the `Agent-Thread_HTML/index.html` file), please execute a command to open it in Chrome (e.g., `chrome.exe Agent-Thread_HTML\index.html`) so the user can immediately start reviewing the live output.
</USER_REQUEST>

## Follow-up — 2026-07-29T12:31:56Z

<USER_REQUEST>
The HTML file must auto-reload on changes so it acts like a true live feed. If necessary, please create a background service PS1 script to facilitate this and start it immediately. 

Please pass this to the orchestrator to update the HTML implementation right away so the live feed automatically refreshes for the user.
</USER_REQUEST>

## Follow-up — 2026-07-29T12:32:46Z

<USER_REQUEST>
Please ensure that the HTML output is highly detailed and comprehensive. When agents append to their feed, they should provide descriptive, verbose, and comprehensive summaries of their actions, thoughts, and technical data so that the live feed is very informative for the user.
</USER_REQUEST>

## Follow-up — 2026-07-29T12:33:39Z

<USER_REQUEST>
The HTML file should also have sections/tabs to bake in the build artifacts (and any historical versions of those artifacts), as well as a section that displays the entire project's plan and outline.

Please pass this to the orchestrator so the HTML previewer architecture is updated to support displaying these additional elements!
</USER_REQUEST>

## Follow-up — 2026-07-29T12:34:48Z

<USER_REQUEST>
Because the HTML file needs more and more stuff constantly parsed, a background script (e.g., a PS1 service) to automatically parse data and append it for viewing is required. Make sure this script runs continuously (always running) in the background to handle the parsing and appending.

Please instruct the orchestrator to implement this continuous background parsing service immediately so the live feed is seamlessly updated!
</USER_REQUEST>

## Follow-up — 2026-07-29T14:50:20Z

<USER_REQUEST>
Instead of launching the HTML file directly as a local file, host it using a local HTTP service bound to all network adapters (`0.0.0.0`) so it is accessible across the local network. 

Please instruct the orchestrator to set up and run this local web server (e.g., via PowerShell `System.Net.HttpListener` or Python `http.server` listening on `0.0.0.0`) so the HTML thread is hosted on all network interfaces.
</USER_REQUEST>
