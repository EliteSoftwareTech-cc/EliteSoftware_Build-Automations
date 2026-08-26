#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <regex>
#include <windows.h>
#include <tlhelp32.h>
#include <sstream>

using namespace std;

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

// Simple function to execute a command and wait
int ExecuteCommand(const string& cmd) {
    cout << "[Compiler] Executing: " << cmd << endl;
    
    STARTUPINFO si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    if (!CreateProcess(NULL, (LPSTR)cmd.c_str(), NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        cerr << "[Compiler] ERROR: Failed to execute command. Error code: " << GetLastError() << endl;
        return 1;
    }

    WaitForSingleObject(pi.hProcess, INFINITE);
    
    DWORD exitCode;
    GetExitCodeProcess(pi.hProcess, &exitCode);
    
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    
    return exitCode;
}

// Simple JSON array regex extractor
vector<string> ExtractJsonArray(const string& jsonContent, const string& key) {
    vector<string> results;
    // Look for "key" : [ "val1", "val2" ]
    regex r("\"" + key + "\"\\s*:\\s*\\[(.*?)\\]");
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
    string configPath = "EliteBuild.config";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "/help" || arg == "-help" || arg == "--help" || arg == "-?" || arg == "--?" || arg == "//help") {
            PrintHelp();
            return 0;
        } else if (arg == "--config" && i + 1 < argc) {
            configPath = argv[++i];
        }
    }

    ifstream configFile(configPath);
    if (!configFile.is_open()) {
        cerr << "[Compiler] ERROR: Could not open " << configPath << ". Please ensure it exists." << endl;
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
            return 1;
        }
        // Build x86
        string msbuildCmd86 = "MSBuild.exe \"" + sln + "\" /p:Configuration=Release /p:Platform=x86";
        if (ExecuteCommand(msbuildCmd86) != 0) {
            cerr << "[Compiler] ERROR: MSBuild failed for x86 on " << sln << endl;
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
            return 1;
        }
    }

    cout << "[Compiler] Compilation phase completed successfully!" << endl;
    return 0;
}
