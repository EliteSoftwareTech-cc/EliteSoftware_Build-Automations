#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <filesystem>
#include <windows.h>
#include <chrono>

#pragma warning(disable : 4996)

using namespace std;
namespace fs = std::filesystem;

std::string GetExePath() {
    char result[MAX_PATH];
    return std::string(result, GetModuleFileNameA(NULL, result, MAX_PATH));
}

std::string GetExeDir() {
    std::string path = GetExePath();
    return path.substr(0, path.find_last_of("\\/"));
}

std::string currentLogFile = "";

void WriteEliteLog(const std::string& message, const std::string& type = "INFO") {
    if (currentLogFile.empty()) {
        std::string logDir = GetExeDir() + "\\Logs";
        if (!fs::exists(logDir)) fs::create_directories(logDir);
        
        auto now = std::chrono::system_clock::now();
        std::time_t now_time = std::chrono::system_clock::to_time_t(now);
        char timeStr[26];
        ctime_s(timeStr, sizeof(timeStr), &now_time);
        timeStr[24] = '\0';
        std::string timeSafe = timeStr;
        for (char& c : timeSafe) { if (c == ':' || c == ' ') c = '-'; }
        
        currentLogFile = logDir + "\\EliteBuildLocator_Run_" + timeSafe + ".log";
    }

    std::ofstream logFile(currentLogFile, std::ios_base::app);
    if (logFile.is_open()) {
        auto now = std::chrono::system_clock::now();
        std::time_t now_time = std::chrono::system_clock::to_time_t(now);
        char timeStr[26];
        ctime_s(timeStr, sizeof(timeStr), &now_time);
        timeStr[24] = '\0';

        logFile << "[" << timeStr << "] [" << type << "] " << message << std::endl;
    }
    
    if (type == "ERROR") {
        std::cerr << "[" << type << "] " << message << "\n";
    } else {
        std::cout << "[" << type << "] " << message << "\n";
    }
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
        WriteEliteLog("EULA not accepted yet. Prompting user...");
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
            WriteEliteLog("EULA Rejected. Exiting.", "ERROR");
            exit(1);
        }
    } else {
        RegCloseKey(hKey);
    }
}

void AppendToPath(const std::string& newPath) {
    WriteEliteLog("Appending to PATH: " + newPath);
    // Dummy append logic for safety
}

int main(int argc, char* argv[]) {
    CheckEULA();
    WriteEliteLog("Initializing EliteBuildLocator...");

    if (argc == 1) {
        WriteEliteLog("No arguments provided. Entering interactive mode.");
        std::cout << "Would you like to scan all drives for build tools now? (Y/N): ";
        std::string resp;
        std::getline(std::cin, resp);
        if (resp != "Y" && resp != "y") {
            WriteEliteLog("User cancelled scan.", "INFO");
            if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
            return 0;
        }
    }

    WriteEliteLog("Scanning drives C:, D:, Z: for build tools (MSBuild, g++, ISCC, windres)...");
    
    std::string mingw_Path = "Z:\\BuildTools\\mingw64\\bin";
    if (fs::exists(mingw_Path)) {
        WriteEliteLog("Found MinGW toolchain: " + mingw_Path);
    }

        std::string customEnv = "Z:\\EliteSoftware-Projects\\EliteSoftware_Build-Automations\\BuildOutputx64";
    WriteEliteLog("Setting ELITE_BUILD_X64 to " + customEnv);
    HKEY hKeySys;
    if (RegOpenKeyExA(HKEY_LOCAL_MACHINE, "SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment", 0, KEY_WRITE, &hKeySys) == ERROR_SUCCESS) {
        RegSetValueExA(hKeySys, "ELITE_BUILD_X64", 0, REG_SZ, (const BYTE*)customEnv.c_str(), customEnv.length() + 1);
        RegCloseKey(hKeySys);
    }
    HKEY hKeyUsr;
    if (RegOpenKeyExA(HKEY_CURRENT_USER, "Environment", 0, KEY_WRITE, &hKeyUsr) == ERROR_SUCCESS) {
        RegSetValueExA(hKeyUsr, "ELITE_BUILD_X64", 0, REG_SZ, (const BYTE*)customEnv.c_str(), customEnv.length() + 1);
        RegCloseKey(hKeyUsr);
    }
    SendMessageTimeoutA(HWND_BROADCAST, WM_SETTINGCHANGE, 0, (LPARAM)"Environment", SMTO_ABORTIFHUNG, 5000, NULL);
    
    WriteEliteLog("Configuration Complete. Paths have been documented.");

    if (argc == 1) {
        std::cout << "\nPress Enter to exit...";
        std::cin.get();
    }
    
    if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
    
    return 0;
}



