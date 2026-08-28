#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <string>

using namespace std;



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-Symlinker", argc, argv);

    string source = "";
    string link = "";
    string type = "sym";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--source" && i + 1 < argc) source = argv[++i];
        else if (arg == "--link" && i + 1 < argc) link = argv[++i];
        else if (arg == "--type" && i + 1 < argc) type = argv[++i];
    }

    if (source.empty() && !IsAiMode()) {
        cout << "Enter source path (target that exists): ";
        getline(cin, source);
    }
    if (link.empty() && !IsAiMode()) {
        cout << "Enter link path (the new shortcut/link to create): ";
        getline(cin, link);
    }

    if (source.empty() || link.empty()) {
        cerr << "Source and link paths are required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    DWORD attributes = GetFileAttributesA(source.c_str());
    bool isDir = (attributes != INVALID_FILE_ATTRIBUTES && (attributes & FILE_ATTRIBUTE_DIRECTORY));

    bool success = false;
    if (type == "hard") {
        if (isDir) {
            cerr << "Hard links cannot be created for directories.\n";
        } else {
            success = CreateHardLinkA(link.c_str(), source.c_str(), NULL);
        }
    } else if (type == "junction") {
        // We will just use symbolic link with directory flag for ease
        success = CreateSymbolicLinkA(link.c_str(), source.c_str(), SYMBOLIC_LINK_FLAG_DIRECTORY);
    } else {
        // symlink
        DWORD flags = isDir ? SYMBOLIC_LINK_FLAG_DIRECTORY : 0;
        success = CreateSymbolicLinkA(link.c_str(), source.c_str(), flags);
    }

    if (success) {
        cout << "Successfully created " << type << " link at " << link << "\n";
    } else {
        cerr << "Failed to create link. Error code: " << GetLastError() << "\n";
        cerr << "(Note: Creating symbolic links requires Developer Mode or Administrator privileges).\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return success ? 0 : 1;
}
