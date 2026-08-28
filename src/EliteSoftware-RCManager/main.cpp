#include "..\EliteLogger.h"
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <windows.h>

using namespace std;



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-RCManager", argc, argv);

    string rcFile = "";
    string resFile = "";
    string iconPath = "";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--rc" && i + 1 < argc) rcFile = argv[++i];
        else if (arg == "--res" && i + 1 < argc) resFile = argv[++i];
        else if (arg == "--icon" && i + 1 < argc) iconPath = argv[++i];
    }

    if (rcFile.empty() && !IsAiMode()) {
        cout << "Enter output RC file path (e.g. app.rc): ";
        getline(cin, rcFile);
    }
    if (resFile.empty() && !IsAiMode()) {
        cout << "Enter output RES file path (e.g. app.res): ";
        getline(cin, resFile);
    }

    if (rcFile.empty() || resFile.empty()) {
        cerr << "RC and RES file paths are required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    // Generate RC file
    ofstream rc(rcFile);
    if (!rc.is_open()) {
        cerr << "Failed to create RC file.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    if (!iconPath.empty()) {
        rc << "IDI_ICON1 ICON \"" << iconPath << "\"\n";
    }
    rc.close();
    cout << "Generated RC file: " << rcFile << "\n";

    // Compile to RES using windres
    string cmd = "windres -O coff -i \"" + rcFile + "\" -o \"" + resFile + "\"";
    cout << "Compiling to RES...\n";
    int ret = system(cmd.c_str());
    
    if (ret == 0) {
        cout << "Successfully compiled " << resFile << "\n";
    } else {
        cerr << "Failed to compile using windres. Is it in your PATH?\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return ret;
}
