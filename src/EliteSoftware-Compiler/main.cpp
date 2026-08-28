#include "..\EliteLogger.h"
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <regex>
#include <windows.h>
#include <tlhelp32.h>
#include <sstream>

#include <windows.h>
#include <chrono>
#include <filesystem>
#include <fstream>
using namespace std;

int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-Compiler", argc, argv);

    InitEliteLogger();
    CheckEULA();
    if (argc == 1) {
        WriteEliteLog("No arguments provided. Falling back to interactive mode.");
        std::cout << "\n[Interactive Mode] EliteSoftware-Compiler\n";
        std::cout << "Enter path to EliteBuild.config (leave blank for current directory): ";
        std::string cfg;
        std::getline(std::cin, cfg);
        if (cfg.empty()) cfg = "EliteBuild.config";
        
        char* dummyArgv[] = { argv[0], (char*)cfg.c_str() };
        argc = 2;
        argv = dummyArgv;
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
        cerr << "[Compiler] ERROR: Could not open " << configPath << ". Please ensure it exists." << endl;
        if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
        return 1;
    }

    stringstream buffer;
    buffer << configFile.rdbuf();
    string configContent = buffer.str();

    // 1. Process Killing
    vector<string> processesToKill = ExtractJsonArray(configContent, "KillProcesses");
    for (const string& proc : processesToKill) {
        KillProcessByName(proc);
    }

    // 2. Pre-Build Scripts
    vector<string> preBuildScripts = ExtractJsonArray(configContent, "PreBuildScripts");
    for (const string& script : preBuildScripts) {
        string cmd = "powershell.exe -ExecutionPolicy Bypass -File \"" + script + "\"";
        if (ExecuteCommand(cmd) != 0) {
            cerr << "[Compiler] ERROR: Pre-build script failed: " << script << endl;
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
        }
    }

    // 3. SlnPaths (MSBuild)
    vector<string> slnPaths = ExtractJsonArray(configContent, "SlnPaths");
    for (const string& sln : slnPaths) {
        // Build x64
        string msbuildCmd64 = "MSBuild.exe \"" + sln + "\" /p:Configuration=Release /p:Platform=x64";
        if (ExecuteCommand(msbuildCmd64) != 0) {
            cerr << "[Compiler] ERROR: MSBuild failed for x64 on " << sln << endl;
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
        }
        // Build x86
        string msbuildCmd86 = "MSBuild.exe \"" + sln + "\" /p:Configuration=Release /p:Platform=x86";
        if (ExecuteCommand(msbuildCmd86) != 0) {
            cerr << "[Compiler] ERROR: MSBuild failed for x86 on " << sln << endl;
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
        }
    }

    // 4. GccTargets (MinGW)
    vector<string> gccTargets = ExtractJsonArray(configContent, "GccTargets");
    for (string target : gccTargets) {
        if (target.find("g++ -m64") != string::npos) { target = std::regex_replace(target, std::regex("^g\\+\\+"), "Z:\\\\\\\\BuildTools\\\\\\\\mingw64\\\\\\\\bin\\\\\\\\g++.exe"); }
        else if (target.find("g++ -m32") != string::npos) { target = std::regex_replace(target, std::regex("^g\\+\\+"), "Z:\\\\\\\\BuildTools\\\\\\\\mingw32\\\\\\\\bin\\\\\\\\g++.exe"); }
        if (target.find("windres") != string::npos) {
            if (target.find("pe-x86-64") != string::npos || target.find("res64") != string::npos) { target = std::regex_replace(target, std::regex("^windres"), "Z:\\\\\\\\BuildTools\\\\\\\\mingw64\\\\\\\\bin\\\\\\\\windres.exe"); }
            else { target = std::regex_replace(target, std::regex("^windres"), "Z:\\\\\\\\BuildTools\\\\\\\\mingw32\\\\\\\\bin\\\\\\\\windres.exe"); }
        }
        // If the target is a script, execute it directly, or parse a custom GCC invocation.
        // For simplicity, we assume GccTargets contains direct g++ compilation commands.
        if (ExecuteCommand(target) != 0) {
            cerr << "[Compiler] ERROR: GCC target failed: " << target << endl;
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
        }
    }

    cout << "[Compiler] Compilation phase completed successfully!" << endl;
    if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
    return 0;
}










