#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <windows.h>
#include <sstream>
#include <filesystem>

using namespace std;

bool IsAiMode() { return strstr(GetCommandLineA(), "--ai-mode") != nullptr; }

vector<string> Split(const string& s, char delimiter) {
    vector<string> tokens;
    string token;
    istringstream tokenStream(s);
    while (getline(tokenStream, token, delimiter)) {
        if (!token.empty()) tokens.push_back(token);
    }
    return tokens;
}

string FindToolInVar(const string& toolName) {
    char* globalPath = nullptr;
    size_t len = 0;
    _dupenv_s(&globalPath, &len, "ELITE_BUILD_X64");
    if (globalPath) {
        vector<string> paths = Split(globalPath, ';');
        free(globalPath);
        for (const auto& p : paths) {
            if (p.find(toolName) != string::npos) return p;
        }
    }
    return toolName;
}

int ExecuteCommand(const string& cmd) {
    cout << "[EliteBuild] Executing: " << cmd << endl;
    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    if (!CreateProcessA(NULL, (LPSTR)cmd.c_str(), NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        cerr << "[EliteBuild] ERROR: Failed to execute. Error: " << GetLastError() << endl;
        return 1;
    }
    WaitForSingleObject(pi.hProcess, INFINITE);
    DWORD exitCode;
    GetExitCodeProcess(pi.hProcess, &exitCode);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    return exitCode;
}

int main(int argc, char* argv[]) {
    vector<string> configs;
    vector<string> toolsToRun;

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--ai-mode") continue;
        if (arg == "--config" && i + 1 < argc) { configs.push_back(argv[++i]); }
        else if (arg == "--tool" && i + 1 < argc) { toolsToRun.push_back(argv[++i]); }
    }

    if (configs.empty()) {
        // Auto-discover configs in ./Build_Configurations/ or current dir
        if (std::filesystem::exists("Build_Configurations")) {
            for (auto const& entry : std::filesystem::directory_iterator("Build_Configurations")) {
                if (entry.path().extension() == ".config") {
                    configs.push_back(entry.path().string());
                }
            }
        }
        for (auto const& entry : std::filesystem::directory_iterator(".")) {
            if (entry.path().extension() == ".config") {
                configs.push_back(entry.path().string());
            }
        }
    }

    if (configs.empty()) {
        cout << "[EliteBuild] No .config files found. Generating EliteBuild.config...\n";
        ofstream autoConfig("EliteBuild.config");
        autoConfig << "{\n  \"GccTargets\": []\n}\n";
        configs.push_back("EliteBuild.config");
    }

    if (toolsToRun.empty()) {
        toolsToRun.push_back("EliteBuild_Compiler.exe");
        toolsToRun.push_back("EliteEasySigner.exe");
        toolsToRun.push_back("EliteProjectBackup.exe");
    }

    for (const string& cfg : configs) {
        cout << "\n============================================\n";
        cout << "[EliteBuild] Processing Config: " << cfg << "\n";
        cout << "============================================\n";
        for (const string& tool : toolsToRun) {
            string fullPath = FindToolInVar(tool);
            string cmd = "\"" + fullPath + "\" --config \"" + cfg + "\" " + (IsAiMode() ? "--ai-mode" : "");
            ExecuteCommand(cmd);
        }
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
