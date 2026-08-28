#include "..\EliteLogger.h"
#include <iostream>
#include <fstream>
#include <string>
#include <regex>

#include <windows.h>
#include <chrono>
#include <filesystem>
#include <fstream>
using namespace std;

int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-ReadmeGenerator", argc, argv);

    CheckEULA();
    if (argc == 1) {
        WriteEliteLog("No arguments provided. Falling back to interactive mode.");
        std::cout << "\n[Interactive Mode] EliteReadmeGenerator\n";
        std::cout << "Enter Template ID (1-5): ";
        std::string tId;
        std::getline(std::cin, tId);
        
        std::cout << "Enter Project Name: ";
        std::string pName;
        std::getline(std::cin, pName);
        
        std::cout << "Enter Tagline (optional): ";
        std::string tLine;
        std::getline(std::cin, tLine);
        if (tLine.empty()) tLine = "An EliteSoftware Engineering Initiative.";

        char* dummyArgv[] = { argv[0], (char*)tId.c_str(), (char*)pName.c_str(), (char*)tLine.c_str() };
        argc = 4;
        argv = dummyArgv;
    }
    if (argc < 3) {
        PrintHelp();
        if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
        return 1;
    }

    string templateIdStr = argv[1];
    string projectName = argv[2];
    string tagline = (argc >= 4) ? argv[3] : "An EliteSoftware Engineering Initiative.";

    if (templateIdStr == "/help" || templateIdStr == "-help" || templateIdStr == "-?") {
        PrintHelp();
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    }

    int templateId = 1;
    try {
        templateId = stoi(templateIdStr);
    } catch (...) {
        cerr << "[ReadmeGenerator] ERROR: Invalid Template ID." << endl;
        if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
        return 1;
    }

    string selectedTemplate;
    switch (templateId) {
        case 1: selectedTemplate = TEMPLATE_1; break;
        case 2: selectedTemplate = TEMPLATE_2; break;
        case 3: selectedTemplate = TEMPLATE_3; break;
        case 4: selectedTemplate = TEMPLATE_4; break;
        case 5: selectedTemplate = TEMPLATE_5; break;
        default:
            cerr << "[ReadmeGenerator] ERROR: Template ID must be 1-5." << endl;
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
    }

    // Replace Placeholders
    selectedTemplate = regex_replace(selectedTemplate, regex("__PROJECT_NAME__"), projectName);
    selectedTemplate = regex_replace(selectedTemplate, regex("__TAGLINE__"), tagline);

    // Write to readme.md
    ofstream outFile("readme.md");
    if (!outFile.is_open()) {
        cerr << "[ReadmeGenerator] ERROR: Could not open readme.md for writing in current directory." << endl;
        if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
        return 1;
    }

    outFile << selectedTemplate;
    outFile.close();

    cout << "[ReadmeGenerator] Successfully generated readme.md using Template " << templateId << " for project '" << projectName << "'!" << endl;
    if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
    return 0;
}





