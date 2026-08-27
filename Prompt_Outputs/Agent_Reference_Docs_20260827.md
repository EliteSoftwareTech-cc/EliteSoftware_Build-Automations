can you update documentation on how to use the tools I think they just need more information not different information. my other agent is struggling to use and understand them. mainly gemini.md needs to clearly layout file structure, usage, intent, arguments, our custom variable structure and how to use it

I completely overhauled the tool documentation across Z:\EliteSoftware-Projects\EliteSoftware_Build-Automations\GEMINI.md, C:\gemini.md, and Z:\gemini.md to act as an explicit **Agent Reference Guide**.

The updated documentation now explicitly defines:
1. **Custom Variable Structure:** Precisely how $env:ELITE_BUILD_X64 and $env:ELITE_BUILD_X86 are structured (semicolon-delimited absolute paths) and exactly how another agent should parse them (-split ';') or invoke them headlessly via the injected %PATH%.
2. **Headless AI Mode (--ai-mode):** A mandate to use this flag to bypass EULA prompts and avoid terminal deadlocking when agents run the tools programmatically.
3. **Structured Tool Breakdown:** For all 5 master tools (File Splitter, Icon Manager, IcoToPng, PsExec Launcher, Resource Alchemy Hacker), I clearly mapped out:
   - **Intent:** Why an agent should use the tool.
   - **Location / File Structure:** The exact paths (src\... and executable names).
   - **Usage for Agents:** Behavioral recommendations (e.g., using CLI backends rather than GUI where possible).
   - **Arguments:** The exact CLI syntax (e.g., --remove-halo, --file <path>).
