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

std::string __currentLogFile = "";

std::string __GetExePath() {
    char result[MAX_PATH];
    return std::string(result, GetModuleFileNameA(NULL, result, MAX_PATH));
}

std::string __GetExeDir() {
    std::string path = __GetExePath();
    return path.substr(0, path.find_last_of("\\/"));
}

void WriteEliteLog(const std::string& message, const std::string& type = "INFO") {
    if (__currentLogFile.empty()) {
        std::string logDir = __GetExeDir() + "\\Logs";
        if (!std::filesystem::exists(logDir)) std::filesystem::create_directories(logDir);
        
        auto now = std::chrono::system_clock::now();
        std::time_t now_time = std::chrono::system_clock::to_time_t(now);
        char timeStr[26];
        ctime_s(timeStr, sizeof(timeStr), &now_time);
        timeStr[24] = '\0';
        std::string timeSafe = timeStr;
        for (char& c : timeSafe) { if (c == ':' || c == ' ') c = '-'; }
        
        __currentLogFile = logDir + "\\EliteTool_Run_" + timeSafe + ".log";
    }

    std::ofstream logFile(__currentLogFile, std::ios_base::app);
    if (logFile.is_open()) {
        auto now = std::chrono::system_clock::now();
        std::time_t now_time = std::chrono::system_clock::to_time_t(now);
        char timeStr[26];
        ctime_s(timeStr, sizeof(timeStr), &now_time);
        timeStr[24] = '\0';
        logFile << "[" << timeStr << "] [" << type << "] " << message << std::endl;
    }
    
    if (type == "ERROR") std::cerr << "[" << type << "] " << message << "\n";
    else std::cout << "[" << type << "] " << message << "\n";
}

void CheckEULA() {
    if (strstr(GetCommandLineA(), "--ai-mode")) {
        char currentTitle[512];
        if (GetConsoleTitleA(currentTitle, 512) > 0) {
            std::string newTitle = std::string(currentTitle) + " (Ai Mode)";
            SetConsoleTitleA(newTitle.c_str());
        } else {
            SetConsoleTitleA("EliteSoftware Tool (Ai Mode)");
        }
        WriteEliteLog("AI Mode active. Bypassing EULA prompt.");
        return;
    }
    HKEY hKey;
    LSTATUS status = RegOpenKeyExA(HKEY_CURRENT_USER, "Software\\EliteSoftware\\EULA", 0, KEY_READ, &hKey);
    if (status != ERROR_SUCCESS) {
        std::cout << "\n======================================================\n";
        std::cout << " EliteSoftwareTech Co. End User License Agreement\n";
        std::cout << "======================================================\n";
        std::cout << "By using this tool, you agree to absolute system purity.\n";
        std::cout << "Do you accept? (Y/N): ";
        std::string resp;
        std::getline(std::cin, resp);
        if (resp == "Y" || resp == "y" || resp == "yes") {
            RegCreateKeyExA(HKEY_CURRENT_USER, "Software\\EliteSoftware\\EULA", 0, NULL, REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hKey, NULL);
            DWORD val = 1;
            RegSetValueExA(hKey, "Accepted", 0, REG_DWORD, (const BYTE*)&val, sizeof(val));
            RegCloseKey(hKey);
            WriteEliteLog("EULA Accepted. Registry updated.");
        } else {
            std::cerr << "EULA Rejected. Exiting.\n";
            exit(1);
        }
    } else {
        RegCloseKey(hKey);
    }
}

// Function to print help
void PrintHelp() {
    cout << "========================================" << endl;
    cout << " EliteBuild Compiler (Native C++ Tool)" << endl;
    cout << "========================================" << endl;
    cout << "Usage: EliteBuild_Compiler.exe [OPTIONS]" << endl;
    cout << "Options:" << endl;
    cout << "  /help, -help, -?    Show this help message." << endl;
    cout << "  --config <path>     Specify a custom .config path (default: EliteBuild.config)" << endl;
    cout << endl;
    cout << "Description:" << endl;
    cout << "  Reads EliteBuild.config, kills conflicting processes, acquires a file lock, and" << endl;
    cout << "  invokes MSBuild or GCC/windres targets based on the configuration." << endl;
}

// Function to kill a process by name
void KillProcessByName(const string& processName) {
    HANDLE hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hSnap != INVALID_HANDLE_VALUE) {
        PROCESSENTRY32 pe;
        pe.dwSize = sizeof(PROCESSENTRY32);
        if (Process32First(hSnap, &pe)) {
            do {
                if (string(pe.szExeFile) == processName) {
                    cout << "[Compiler] Terminating conflicting process: " << processName << endl;
                    HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, FALSE, pe.th32ProcessID);
                    if (hProcess) {
                        TerminateProcess(hProcess, 0);
                        CloseHandle(hProcess);
                    }
                }
            } while (Process32Next(hSnap, &pe));
        }
        CloseHandle(hSnap);
    }
}



// Simple JSON array regex extractor
vector<string> ExtractJsonArray(const string& jsonContent, const string& key) {
    vector<string> results;
    // Look for "key" : [ "val1", "val2" ]
    regex r("\"" + key + "\"\\s*:\\s*\\[([\\s\\S]*?)\\]");
    smatch match;
    if (regex_search(jsonContent, match, r)) {
        string arrayContent = match[1].str();
        regex stringMatcher("\"([^\"]+)\"");
        sregex_iterator currentMatch(arrayContent.begin(), arrayContent.end(), stringMatcher);
        sregex_iterator lastMatch;
        while (currentMatch != lastMatch) {
            results.push_back(currentMatch->str(1));
            currentMatch++;
        }
    }
    return results;
}

int main(int argc, char* argv[]) {
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
    for (const string& target : gccTargets) {
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






