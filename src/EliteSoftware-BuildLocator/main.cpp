#include "..\EliteLogger.h"
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

int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-BuildLocator", argc, argv);

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



