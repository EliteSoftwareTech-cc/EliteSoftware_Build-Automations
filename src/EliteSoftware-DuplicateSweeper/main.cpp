#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <string>
#include <filesystem>
#include <vector>
#include <algorithm>

using namespace std;
namespace fs = std::filesystem;



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-DuplicateSweeper", argc, argv);

    string dir = "";
    vector<string> extensions;
    bool autoDelete = false;

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--dir" && i + 1 < argc) dir = argv[++i];
        else if (arg == "--ext" && i + 1 < argc) {
            string exts = argv[++i];
            size_t pos = 0;
            while ((pos = exts.find('|')) != string::npos) {
                extensions.push_back(exts.substr(0, pos));
                exts.erase(0, pos + 1);
            }
            extensions.push_back(exts);
        }
        else if (arg == "--auto-delete") autoDelete = true;
    }

    if (dir.empty() && !IsAiMode()) {
        cout << "Enter directory to sweep: ";
        getline(cin, dir);
    }
    if (extensions.empty() && !IsAiMode()) {
        string exts;
        cout << "Enter extensions to sweep (e.g. .obj|.pdb): ";
        getline(cin, exts);
        size_t pos = 0;
        while ((pos = exts.find('|')) != string::npos) {
            extensions.push_back(exts.substr(0, pos));
            exts.erase(0, pos + 1);
        }
        extensions.push_back(exts);
    }

    if (dir.empty()) {
        cerr << "Directory is required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    int foundCount = 0;
    int deletedCount = 0;

    try {
        for (const auto& entry : fs::recursive_directory_iterator(dir)) {
            if (entry.is_regular_file()) {
                string ext = entry.path().extension().string();
                // Lowercase the extension for comparison
                transform(ext.begin(), ext.end(), ext.begin(), ::tolower);
                
                for (string& targetExt : extensions) {
                    transform(targetExt.begin(), targetExt.end(), targetExt.begin(), ::tolower);
                    if (ext == targetExt) {
                        foundCount++;
                        cout << "Found target file: " << entry.path().string() << "\n";
                        if (autoDelete) {
                            fs::remove(entry.path());
                            deletedCount++;
                            cout << " -> DELETED\n";
                        }
                    }
                }
            }
        }
    } catch (const fs::filesystem_error& e) {
        cerr << "Filesystem error: " << e.what() << "\n";
    }

    cout << "\nSweep Complete.\n";
    cout << "Files found: " << foundCount << "\n";
    cout << "Files deleted: " << deletedCount << "\n";

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
