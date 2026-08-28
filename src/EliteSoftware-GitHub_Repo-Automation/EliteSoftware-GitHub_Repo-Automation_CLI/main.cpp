#include "..\..\EliteLogger.h"
#include <iostream>
#include <string>
#include <vector>
#include <cstdlib>
#include <algorithm>
#include <direct.h> // For _getcwd

#include <windows.h>
#include <chrono>
#include <filesystem>
#include <fstream>
using namespace std;

int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-GitHub_Repo-Automation", argc, argv);

    InitEliteLogger();
    CheckEULA();
    if (argc < 2) {
        printGlobalHelp();
        if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
        return 1;
    }
    
    string command = argv[1];
    
    if (isHelpFlag(command)) {
        printGlobalHelp();
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    }
    
    vector<string> args;
    for (int i = 2; i < argc; ++i) {
        args.push_back(argv[i]);
    }
    
    if (command == "init") {
        return handleInit(args);
    } else if (command == "commit") {
        return handleCommit(args);
    } else if (command == "release") {
        return handleRelease(args);
    } else {
        cerr << "Unknown command: " << command << "\n";
        printGlobalHelp();
        if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
        return 1;
    }
}









