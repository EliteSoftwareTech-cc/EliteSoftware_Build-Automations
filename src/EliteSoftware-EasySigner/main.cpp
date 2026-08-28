#include "..\EliteLogger.h"
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

// Logging and EULA handled by EliteLogger.h


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



int main(int argc, char* argv[]) {
    InitEliteLogger();
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
    
    int result = ExecuteCommand(methodA);
    
    if (result != 0) {
        cerr << "\nMethod A Failed. Falling back to Legacy Method...\n";
        
        // Legacy Method: SHA1 signing with standard Authenticode timestamping
        cout << "Attempting Legacy Method (SHA1 / Authenticode Timestamping)...\n";
        string legacyMethod = "\"" + signtoolPath + "\" sign /f \"" + pfxPath + "\" /p \"" + password + "\" /fd SHA1 /t http://timestamp.digicert.com /v \"" + targetFile + "\"";
        
        result = ExecuteCommand(legacyMethod);
        
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





