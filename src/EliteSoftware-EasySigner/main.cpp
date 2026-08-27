#include <iostream>
#include <string>
#include <vector>
#include <cstdlib>
#include <windows.h>
#include <fstream>
#include "resources.h"

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

void printHelp() {
    cout << "========================================\n";
    cout << " EliteSoftware EasySigner (C++)\n";
    cout << "========================================\n\n";
    cout << "Usage: EliteEasySigner.exe [options]\n\n";
    cout << "Options:\n";
    cout << "  --file <path>       (Required) Path to the executable/DLL to sign.\n";
    cout << "  --password <string> (Optional) PFX password. Defaults to internal EliteSoftware password.\n";
    cout << "  --help              Display this help message.\n\n";
    cout << "Behavior:\n";
    cout << "  The tool extracts an embedded signtool.exe and EliteSoftware_Special.pfx.\n";
    cout << "  It attempts Method A (Modern SHA256 RFC3161 Timestamping).\n";
    cout << "  If Method A fails, it falls back to Legacy Method (SHA1 Authenticode Timestamping).\n";
    cout << "  Even on total failure, the tool returns a success code to prevent pipeline blocking.\n";
}

bool extractResource(int resourceId, const string& outputPath) {
    HRSRC hRes = FindResource(NULL, MAKEINTRESOURCE(resourceId), RT_RCDATA);
    if (!hRes) return false;
    
    HGLOBAL hMem = LoadResource(NULL, hRes);
    if (!hMem) return false;
    
    void* pData = LockResource(hMem);
    DWORD size = SizeofResource(NULL, hRes);
    if (!pData || size == 0) return false;
    
    ofstream outFile(outputPath, ios::binary);
    if (!outFile) return false;
    
    outFile.write(reinterpret_cast<const char*>(pData), size);
    outFile.close();
    
    return true;
}

int executeCommand(const string& cmd) {
    return system(cmd.c_str());
}

int main(int argc, char* argv[]) {
    CheckEULA();
    vector<string> args;
    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "-help" || arg == "--help" || arg == "/help" || arg == "//help" || arg == "-?" || arg == "--?") {
            printHelp();
            return 0;
        }
        args.push_back(arg);
    }
    
    string targetFile = "";
    string password = "Minecraft145!!";
    
    for (size_t i = 0; i < args.size(); ++i) {
        if (args[i] == "--file" && i + 1 < args.size()) targetFile = args[++i];
        else if (args[i] == "--password" && i + 1 < args.size()) password = args[++i];
    }
    
    // Smart default: If no file is provided, look for any .exe in the current folder? 
    // It's safer to require the file to prevent signing arbitrary things.
    if (targetFile.empty() && !strstr(GetCommandLineA(), "--ai-mode")) {
        cout << "Enter the path to the file you would like to sign: ";
        getline(cin, targetFile);
    }
    if (targetFile.empty()) {
        cerr << "Error: --file argument is required.\n";
        if (!strstr(GetCommandLineA(), "--ai-mode")) system("pause");
        return 1;
    }
    
    cout << "Starting EliteSoftware EasySigner for: " << targetFile << "\n";
    
    char tempPath[MAX_PATH];
    GetTempPath(MAX_PATH, tempPath);
    
    string signtoolPath = string(tempPath) + "elite_signtool.exe";
    string pfxPath = string(tempPath) + "elite_cert.pfx";
    
    if (!extractResource(IDR_SIGNTOOL, signtoolPath)) {
        cerr << "Error: Failed to extract embedded signtool.exe\n";
        return 0; // Return success to avoid blocking build pipeline
    }
    
    if (!extractResource(IDR_PFX, pfxPath)) {
        cerr << "Error: Failed to extract embedded PFX certificate\n";
        DeleteFileA(signtoolPath.c_str());
        return 0; // Return success
    }
    
    cout << "Embedded resources extracted successfully.\n";
    
    // Method A: Modern SHA256 signing with RFC3161 timestamping
    cout << "Attempting Method A (Modern SHA256 / RFC3161 Timestamping)...\n";
    string methodA = "\"" + signtoolPath + "\" sign /f \"" + pfxPath + "\" /p \"" + password + "\" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /v \"" + targetFile + "\"";
    
    int result = executeCommand(methodA);
    
    if (result != 0) {
        cerr << "\nMethod A Failed. Falling back to Legacy Method...\n";
        
        // Legacy Method: SHA1 signing with standard Authenticode timestamping
        cout << "Attempting Legacy Method (SHA1 / Authenticode Timestamping)...\n";
        string legacyMethod = "\"" + signtoolPath + "\" sign /f \"" + pfxPath + "\" /p \"" + password + "\" /fd SHA1 /t http://timestamp.digicert.com /v \"" + targetFile + "\"";
        
        result = executeCommand(legacyMethod);
        
        if (result != 0) {
            cerr << "\nCritical Error: Legacy Method also failed to sign the file.\n";
            cerr << "Continuing with unsigned file as per standard pipeline rules.\n";
        } else {
            cout << "\nSuccess: File signed using Legacy Method.\n";
        }
    } else {
        cout << "\nSuccess: File signed using Method A.\n";
    }
    
    // Cleanup
    DeleteFileA(signtoolPath.c_str());
    DeleteFileA(pfxPath.c_str());
    
    cout << "Cleanup complete. Exiting EasySigner.\n";
    
    // The user strictly requested: "build technically will still be considered successful without signing"
    // So we always return 0 to the calling script unless the arguments were fundamentally malformed.
    return 0;
}




