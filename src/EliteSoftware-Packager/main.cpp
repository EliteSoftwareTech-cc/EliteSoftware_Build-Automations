#include "..\EliteLogger.h"
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <regex>
#include <windows.h>
#include <sstream>

#include <windows.h>
#include <chrono>
#include <filesystem>
#include <fstream>
using namespace std;

int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-Packager", argc, argv);

    InitEliteLogger();
    CheckEULA();
    if (argc == 1) {
        WriteEliteLog("No arguments provided. Falling back to interactive mode.");
        std::cout << "\nInteractive Mode. Press Enter to exit...";
        std::string dummy;
        std::getline(std::cin, dummy);
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    }
    string configPath = "EliteBuild.config";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "/help" || arg == "-help" || arg == "--help" || arg == "-?" || arg == "--?" || arg == "//help") {
            PrintHelp();
            if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
            return 0;
        } else if (arg == "--config" && i + 1 < argc) {
            configPath = argv[++i];
        }
    }

    ifstream configFile(configPath);
    if (!configFile.is_open()) {
        cerr << "[Packager] ERROR: Could not open " << configPath << ". Skipping packaging phase." << endl;
        return 0; // Return 0 because packaging might be optional
    }

    stringstream buffer;
    buffer << configFile.rdbuf();
    string configContent = buffer.str();

    // 1. ZIP Archives
    vector<string> zipTargets = ExtractJsonArray(configContent, "ZipTargets");
    for (const string& target : zipTargets) {
        // Simple compress command using PowerShell's Compress-Archive
        string cmd = "powershell.exe -Command \"Compress-Archive -Path '" + target + "\\*' -DestinationPath '" + target + ".zip' -Force\"";
        if (ExecuteCommand(cmd) != 0) {
            cerr << "[Packager] ERROR: Failed to create ZIP archive for: " << target << endl;
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
        }
    }

    // 2. InnoSetup Script
    string innoScript = ExtractJsonString(configContent, "InnoSetupScript");
    if (!innoScript.empty()) {
        // Fallback standard paths for Inno Setup compiler (ISCC.exe)
        string isccPath = "\"C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe\"";
        string cmd = isccPath + " \"" + innoScript + "\"";
        if (ExecuteCommand(cmd) != 0) {
            cerr << "[Packager] ERROR: Failed to compile InnoSetup script: " << innoScript << endl;
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
        }
    }

    cout << "[Packager] Packaging phase completed successfully!" << endl;
    if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
    return 0;
}






