#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <regex>
#include <windows.h>
#include <sstream>

using namespace std;

void PrintHelp() {
    cout << "========================================" << endl;
    cout << " EliteBuild Packager (Native C++ Tool)" << endl;
    cout << "========================================" << endl;
    cout << "Usage: EliteBuild_Packager.exe [OPTIONS]" << endl;
    cout << "Options:" << endl;
    cout << "  /help, -help, -?    Show this help message." << endl;
    cout << "  --config <path>     Specify a custom .config path (default: EliteBuild.config)" << endl;
    cout << endl;
    cout << "Description:" << endl;
    cout << "  Reads EliteBuild.config, creates ZIP archives, and compiles InnoSetup scripts." << endl;
}

int ExecuteCommand(const string& cmd) {
    cout << "[Packager] Executing: " << cmd << endl;
    
    STARTUPINFO si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    if (!CreateProcess(NULL, (LPSTR)cmd.c_str(), NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        cerr << "[Packager] ERROR: Failed to execute command. Error code: " << GetLastError() << endl;
        return 1;
    }

    WaitForSingleObject(pi.hProcess, INFINITE);
    
    DWORD exitCode;
    GetExitCodeProcess(pi.hProcess, &exitCode);
    
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    
    return exitCode;
}

vector<string> ExtractJsonArray(const string& jsonContent, const string& key) {
    vector<string> results;
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

string ExtractJsonString(const string& jsonContent, const string& key) {
    regex r("\"" + key + "\"\\s*:\\s*\"([^\"]+)\"");
    smatch match;
    if (regex_search(jsonContent, match, r)) {
        return match[1].str();
    }
    return "";
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
            return 1;
        }
    }

    cout << "[Packager] Packaging phase completed successfully!" << endl;
    return 0;
}
