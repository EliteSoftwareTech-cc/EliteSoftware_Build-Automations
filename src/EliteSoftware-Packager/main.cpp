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






