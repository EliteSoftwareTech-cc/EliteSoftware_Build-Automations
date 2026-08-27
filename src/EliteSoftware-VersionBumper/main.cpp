/*
 * Company: EliteSoftwareTech Co
 * Tool Name: EliteVersionBumper
 * Authors: EliteSoftware - Zachary Whiteman - Susan Gemm
 * Version: 1.0.0.0
 * Description: Command line utility to synchronize and bump 4-decimal version numbers across C++, Header, and RC files.
 */

#include <iostream>
#include <fstream>
#include <string>
#include <regex>
#include <filesystem>
#include <chrono>
#include <algorithm>

#pragma warning(disable : 4996) // For getenv and ctime_s

#include <windows.h>

namespace fs = std::filesystem;

void CheckEULA() {
    if (strstr(GetCommandLineA(), "--ai-mode")) {
        char currentTitle[512];
        if (GetConsoleTitleA(currentTitle, 512) > 0) {
            std::string newTitle = std::string(currentTitle) + " (Ai Mode)";
            SetConsoleTitleA(newTitle.c_str());
        } else {
            SetConsoleTitleA("EliteSoftware Tool (Ai Mode)");
        }
        std::cout << "AI Mode active. Bypassing EULA prompt.\n";
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
        } else {
            std::cerr << "EULA Rejected. Exiting.\n";
            exit(1);
        }
    } else {
        RegCloseKey(hKey);
    }
}


// Logging Utility matching EliteSoftware standards
void WriteEliteLog(const std::string& message, const std::string& type = "INFO") {
    const char* sysDrive = std::getenv("SystemDrive");
    std::string drive = sysDrive ? sysDrive : "C:";
    
    // Ensure logs directory exists
    std::string logDir = drive + "\\EliteSoftware\\Logs";
    if (!fs::exists(logDir)) {
        fs::create_directories(logDir);
    }

    std::string logPath = logDir + "\\EliteVersionBumper.log";

    std::ofstream logFile(logPath, std::ios_base::app);
    if (logFile.is_open()) {
        auto now = std::chrono::system_clock::now();
        std::time_t now_time = std::chrono::system_clock::to_time_t(now);
        char timeStr[26];
        ctime_s(timeStr, sizeof(timeStr), &now_time);
        timeStr[24] = '\0'; // Remove newline

        logFile << "[" << timeStr << "] [" << type << "] " << message << std::endl;
        logFile.close();
    }
    
    if (type == "ERROR") {
        std::cerr << "[" << type << "] " << message << "\n";
    } else {
        std::cout << "[" << type << "] " << message << "\n";
    }
}

// Function to replace version strings in file content
bool UpdateVersionInFile(const std::string& filePath, const std::string& newVersionStr, const std::string& newVersionComma) {
    std::ifstream inFile(filePath);
    if (!inFile.is_open()) {
        WriteEliteLog("Failed to open file for reading: " + filePath, "ERROR");
        return false;
    }

    std::string content((std::istreambuf_iterator<char>(inFile)), std::istreambuf_iterator<char>());
    inFile.close();

    bool changed = false;

    // Regex for RC files: FILEVERSION 1,0,0,0
    std::regex rcFileVersionRegex(R"((FILEVERSION\s+)\d+,\d+,\d+,\d+)");
    if (std::regex_search(content, rcFileVersionRegex)) {
        content = std::regex_replace(content, rcFileVersionRegex, "$1" + newVersionComma);
        changed = true;
    }

    // Regex for RC files: PRODUCTVERSION 1,0,0,0
    std::regex rcProductVersionRegex(R"((PRODUCTVERSION\s+)\d+,\d+,\d+,\d+)");
    if (std::regex_search(content, rcProductVersionRegex)) {
        content = std::regex_replace(content, rcProductVersionRegex, "$1" + newVersionComma);
        changed = true;
    }

    // Regex for RC string blocks: VALUE "FileVersion", "1.0.0.0"
    std::regex rcStringRegex(R"REGEX((VALUE\s+"(?:FileVersion|ProductVersion)",\s+")\d+\.\d+\.\d+\.\d+("))REGEX");
    if (std::regex_search(content, rcStringRegex)) {
        content = std::regex_replace(content, rcStringRegex, "$1" + newVersionStr + "$2");
        changed = true;
    }

    // Regex for standard EliteSoftware header: * Version: 1.0.0.0
    std::regex headerRegex(R"((\*\s+Version:\s+)\d+\.\d+\.\d+\.\d+)");
    if (std::regex_search(content, headerRegex)) {
        content = std::regex_replace(content, headerRegex, "$1" + newVersionStr);
        changed = true;
    }

    if (changed) {
        std::ofstream outFile(filePath, std::ios_base::trunc);
        if (outFile.is_open()) {
            outFile << content;
            outFile.close();
            WriteEliteLog("Successfully synchronized version in: " + filePath);
            return true;
        } else {
            WriteEliteLog("Failed to open file for writing: " + filePath, "ERROR");
        }
    }
    return false;
}

int main(int argc, char* argv[]) {
    CheckEULA();
    WriteEliteLog("Initializing EliteVersionBumper v1.0.0.0...");

    if (argc == 1) {
        WriteEliteLog("No arguments provided. Entering interactive mode.", "INFO");
        std::string projectPath, targetVersion;
        std::cout << "\n[Interactive Mode] EliteVersionBumper\n";
        std::cout << "Enter target Project Path (or . for current directory): ";
        std::getline(std::cin, projectPath);
        std::cout << "Enter New Version (e.g., 1.0.42.6): ";
        std::getline(std::cin, targetVersion);
        
        if (projectPath.empty()) projectPath = ".";
        
        if (targetVersion.empty()) {
            WriteEliteLog("Invalid version input. Exiting.", "ERROR");
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
        }

        // Generate comma-separated version for RC binaries (e.g., 1,0,42,6)
        std::string commaVersion = targetVersion;
        std::replace(commaVersion.begin(), commaVersion.end(), '.', ',');

        WriteEliteLog("Scanning project path: " + projectPath);
        WriteEliteLog("Target Version: " + targetVersion);

        int updatedFiles = 0;
        try {
            for (const auto& entry : fs::recursive_directory_iterator(projectPath)) {
                if (entry.is_regular_file()) {
                    std::string ext = entry.path().extension().string();
                    if (ext == ".cpp" || ext == ".h" || ext == ".rc" || ext == ".ps1" || ext == ".config" || ext == ".md") {
                        if (UpdateVersionInFile(entry.path().string(), targetVersion, commaVersion)) {
                            updatedFiles++;
                        }
                    }
                }
            }
        } catch (const std::exception& e) {
            WriteEliteLog(std::string("File system error: ") + e.what(), "ERROR");
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
        }

        WriteEliteLog("Operation complete. Files synchronized: " + std::to_string(updatedFiles));
        std::cout << "\nPress Enter to exit...";
        std::getline(std::cin, projectPath);
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    }

    if (argc < 3) {
        WriteEliteLog("Usage: EliteVersionBumper.exe <ProjectPath> <NewVersion e.g., 1.0.42.6>", "ERROR");
        std::cout << "\nView EliteVersionBumper Logs (Run: notepad.exe %SystemDrive%\\EliteSoftware\\Logs\\EliteVersionBumper.log)\n";
        if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
        return 1;
    }

    std::string projectPath = argv[1];
    std::string targetVersion = argv[2]; 

    // Generate comma-separated version for RC binaries (e.g., 1,0,42,6)
    std::string commaVersion = targetVersion;
    std::replace(commaVersion.begin(), commaVersion.end(), '.', ',');

    WriteEliteLog("Scanning project path: " + projectPath);
    WriteEliteLog("Target Version: " + targetVersion);

    int updatedFiles = 0;

    try {
        for (const auto& entry : fs::recursive_directory_iterator(projectPath)) {
            if (entry.is_regular_file()) {
                std::string ext = entry.path().extension().string();
                // Target typical project files where versions hide
                if (ext == ".cpp" || ext == ".h" || ext == ".rc" || ext == ".ps1" || ext == ".config" || ext == ".md") {
                    if (UpdateVersionInFile(entry.path().string(), targetVersion, commaVersion)) {
                        updatedFiles++;
                    }
                }
            }
        }
    } catch (const std::exception& e) {
        WriteEliteLog(std::string("File system error: ") + e.what(), "ERROR");
        if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
        return 1;
    }

    WriteEliteLog("Operation complete. Files synchronized: " + std::to_string(updatedFiles));
    std::cout << "\nView EliteVersionBumper Logs (Run: notepad.exe %SystemDrive%\\EliteSoftware\\Logs\\EliteVersionBumper.log)\n";
    
    if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
    
    return 0;
}





