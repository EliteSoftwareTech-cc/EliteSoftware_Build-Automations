#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <string>

using namespace std;



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-PSWrapper", argc, argv);

    string ps1 = "";
    string exe = "";
    bool disableSta = false;
    bool showConsole = false;
    string icon = "";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--ps1" && i + 1 < argc) ps1 = argv[++i];
        else if (arg == "--exe" && i + 1 < argc) exe = argv[++i];
        else if (arg == "--icon" && i + 1 < argc) icon = argv[++i];
        else if (arg == "--disable-sta") disableSta = true;
        else if (arg == "--show-console") showConsole = true;
    }

    if (ps1.empty() && !IsAiMode()) {
        cout << "Enter source .ps1 file: ";
        getline(cin, ps1);
    }
    if (exe.empty() && !IsAiMode()) {
        cout << "Enter output .exe file: ";
        getline(cin, exe);
    }

    if (ps1.empty() || exe.empty()) {
        cerr << "Source and output paths are required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    string psCommand = "Invoke-PS2EXE -inputFile '" + ps1 + "' -outputFile '" + exe + "'";
    
    if (!disableSta) psCommand += " -STA";
    if (!showConsole) psCommand += " -noConsole";
    if (!icon.empty()) psCommand += " -iconFile '" + icon + "'";

    string cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"" + psCommand + "\"";
    
    cout << "Executing Elite PS2EXE Wrapper...\n";
    cout << "Command: " << psCommand << "\n\n";

    int ret = system(cmd.c_str());

    if (ret == 0) {
        cout << "\nSuccessfully compiled " << exe << "\n";
    } else {
        cerr << "\nCompilation failed! Is PS2EXE installed in your PowerShell modules?\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return ret;
}
