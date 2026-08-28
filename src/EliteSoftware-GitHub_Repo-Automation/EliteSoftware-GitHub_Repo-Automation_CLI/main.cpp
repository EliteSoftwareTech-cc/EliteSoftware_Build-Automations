#include "..\..\EliteLogger.h"
#include <iostream>
#include <string>
#include <vector>
#include <cstdlib>
#include <algorithm>
#include <direct.h> // For _getcwd

#include <windows.h>
#include <chrono>
#include <filesystem>
#include <fstream>
using namespace std;

// Logging and EULA handled by EliteLogger.h


// Utility to get current directory name
string getCurrentDirectoryName() {
    char buff[FILENAME_MAX];
    _getcwd(buff, FILENAME_MAX);
    string current_working_dir(buff);
    size_t pos = current_working_dir.find_last_of("/\\");
    if (pos != string::npos) {
        return current_working_dir.substr(pos + 1);
    }
    return "UnknownProject";
}

bool isHelpFlag(const string& arg) {
    return arg == "-help" || arg == "--help" || arg == "/help" || arg == "//help" || arg == "-?" || arg == "--?";
}

void printGlobalHelp() {
    cout << "========================================\n";
    cout << " EliteSoftware GitHub Automator (C++)\n";
    cout << "========================================\n\n";
    cout << "Usage: EliteGitHubAutomator.exe <command> [options]\n\n";
    cout << "Commands:\n";
    cout << "  init       Initialize local git, create remote repo, and push.\n";
    cout << "  commit     Auto-commit and push all changes.\n";
    cout << "  release    Create a GitHub release.\n\n";
    cout << "Run 'EliteGitHubAutomator.exe <command> --help' for more information on a command.\n";
}

void printInitHelp() {
        cout << "Usage: EliteGitHubAutomator.exe init [options]\n\n";
    cout << "Options:\n";
    cout << "  --org <string>      Target GitHub Organization (Defaults to personal account).\n";
    cout << "  --name <string>     Repository name. (Default: current directory name)\n";
    cout << "  --public            Make the remote repository public. (Default: private)\n";
    cout << "  --msg <string>      Initial commit message. (Default: 'Initial repository structure commit')\n";
}

void printCommitHelp() {
    cout << "Usage: EliteGitHubAutomator.exe commit [options]\n\n";
    cout << "Options:\n";
    cout << "  --force             Forcefully push changes to remote (git push --force).\n";
    cout << "  --msg <string>      Commit message. (Default: 'Auto-commit after successful build')\n";
}

void printReleaseHelp() {
    cout << "Usage: EliteGitHubAutomator.exe release --version <version> [options]\n\n";
    cout << "Options:\n";
    cout << "  --version <string>  (Required) The version string for the release (e.g., 1.0.0).\n";
    cout << "  --x86 <path>        Path to the x86 binary/zip to attach.\n";
    cout << "  --x64 <path>        Path to the x64 binary/zip to attach.\n";
    cout << "  --notes <path>      Path to a markdown file for release notes.\n";
    cout << "  --title <string>    Title of the release. (Default: 'Release v<version>')\n";
}

int executeCommand(const string& cmd) {
    cout << "Executing: " << cmd << "\n";
    return ExecuteCommand(cmd);
}

int handleInit(const vector<string>& args) {
    for (const string& arg : args) {
        if (isHelpFlag(arg)) {
            printInitHelp();
            if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
            return 0;
        }
    }

        string name = getCurrentDirectoryName();
    bool isPublic = false;
    string msg = "Initial repository structure commit";
    string orgName = "";

    for (size_t i = 0; i < args.size(); ++i) {
        if (args[i] == "--public") isPublic = true;
        else if (args[i] == "--name" && i + 1 < args.size()) name = args[++i];
        else if (args[i] == "--msg" && i + 1 < args.size()) msg = args[++i];
        else if (args[i] == "--org" && i + 1 < args.size()) orgName = args[++i];
    }
    
    cout << "Initializing Local Repository: " << name << "\n";
    
    executeCommand("git init");
    executeCommand("git add .");
    executeCommand("git commit -m \"" + msg + "\"");
    
    cout << "Creating Remote GitHub Repository...\n";
    string visibility = isPublic ? "--public" : "--private";
    
    string targetName = name;
    if (!orgName.empty()) {
        targetName = orgName + "/" + name;
    }
    
    string ghCommand = "gh repo create " + targetName + " " + visibility + " --source=. --remote=origin --push";
    int result = executeCommand(ghCommand);
    
    if (result != 0) {
        cerr << "Warning: Failed to create or push to remote repository. It may already exist.\n";
        return result;
    }
    
    cout << "Repository " << name << " successfully created and pushed!\n";
    if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
    return 0;
}

int handleCommit(const vector<string>& args) {
    for (const string& arg : args) {
        if (isHelpFlag(arg)) {
            printCommitHelp();
            if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
            return 0;
        }
    }

    bool force = false;
    string msg = "Auto-commit after successful build";

    for (size_t i = 0; i < args.size(); ++i) {
        if (args[i] == "--force") force = true;
        else if (args[i] == "--msg" && i + 1 < args.size()) msg = args[++i];
    }
    
    cout << "Auto-Committing Repository...\n";
    executeCommand("git add .");
    executeCommand("git commit -m \"" + msg + "\"");
    
    cout << "Pushing to remote...\n";
    string pushCommand = force ? "git push origin HEAD --force" : "git push origin HEAD";
    
    int result = executeCommand(pushCommand);
    if (result != 0) {
        cerr << "Warning: Git push encountered an issue.\n";
        return result;
    }
    
    cout << "Changes successfully pushed!\n";
    if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
    return 0;
}

int handleRelease(const vector<string>& args) {
    for (const string& arg : args) {
        if (isHelpFlag(arg)) {
            printReleaseHelp();
            if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
            return 0;
        }
    }

    string version = "";
    string x86Path = "";
    string x64Path = "";
    string notesPath = "";
    string title = "";
    
    for (size_t i = 0; i < args.size(); ++i) {
        if (args[i] == "--version" && i + 1 < args.size()) version = args[++i];
        else if (args[i] == "--x86" && i + 1 < args.size()) x86Path = args[++i];
        else if (args[i] == "--x64" && i + 1 < args.size()) x64Path = args[++i];
        else if (args[i] == "--notes" && i + 1 < args.size()) notesPath = args[++i];
        else if (args[i] == "--title" && i + 1 < args.size()) title = args[++i];
    }

    if (version.empty()) {
        cerr << "Error: --version parameter is required for release.\n";
        printReleaseHelp();
        if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
        return 1;
    }

    if (title.empty()) {
        title = "Release v" + version;
    }
    
    cout << "Drafting GitHub Release v" << version << "...\n";
    
    string ghCommand = "gh release create v" + version + " --title \"" + title + "\"";
    
    if (!notesPath.empty()) {
        ghCommand += " --notes-file \"" + notesPath + "\"";
    } else {
        ghCommand += " --notes \"Automated release v" + version + " built via EliteSoftware toolchain.\"";
    }
    
    if (!x86Path.empty()) ghCommand += " \"" + x86Path + "\"";
    if (!x64Path.empty()) ghCommand += " \"" + x64Path + "\"";
    
    int result = executeCommand(ghCommand);
    if (result != 0) {
        cerr << "Error: Failed to create GitHub release.\n";
        return result;
    }
    
    cout << "Release v" << version << " successfully published!\n";
    if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
    return 0;
}

int main(int argc, char* argv[]) {
    InitEliteLogger();
    CheckEULA();
    if (argc < 2) {
        printGlobalHelp();
        if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
        return 1;
    }
    
    string command = argv[1];
    
    if (isHelpFlag(command)) {
        printGlobalHelp();
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    }
    
    vector<string> args;
    for (int i = 2; i < argc; ++i) {
        args.push_back(argv[i]);
    }
    
    if (command == "init") {
        return handleInit(args);
    } else if (command == "commit") {
        return handleCommit(args);
    } else if (command == "release") {
        return handleRelease(args);
    } else {
        cerr << "Unknown command: " << command << "\n";
        printGlobalHelp();
        if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
        return 1;
    }
}









