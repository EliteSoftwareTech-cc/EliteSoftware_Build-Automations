#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <string>

using namespace std;



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-RegSnapshot", argc, argv);

    string key = "";
    string exportPath = "";
    string restorePath = "";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--key" && i + 1 < argc) key = argv[++i];
        else if (arg == "--export" && i + 1 < argc) exportPath = argv[++i];
        else if (arg == "--restore" && i + 1 < argc) restorePath = argv[++i];
    }

    if (!IsAiMode() && exportPath.empty() && restorePath.empty()) {
        cout << "Enter registry key to snapshot (e.g. HKLM\\Software\\Classes\\CLSID): ";
        getline(cin, key);
        cout << "Enter export file path (e.g. backup.reg): ";
        getline(cin, exportPath);
    }

    if (!exportPath.empty() && !key.empty()) {
        string cmd = "reg export \"" + key + "\" \"" + exportPath + "\" /y";
        cout << "Exporting " << key << " to " << exportPath << "...\n";
        int ret = system(cmd.c_str());
        if (ret == 0) cout << "Snapshot successful.\n";
        else cerr << "Snapshot failed.\n";
    } else if (!restorePath.empty()) {
        string cmd = "reg import \"" + restorePath + "\"";
        cout << "Restoring snapshot from " << restorePath << "...\n";
        int ret = system(cmd.c_str());
        if (ret == 0) cout << "Restore successful.\n";
        else cerr << "Restore failed.\n";
    } else {
        cerr << "Invalid arguments. Provide --key and --export, or --restore.\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
