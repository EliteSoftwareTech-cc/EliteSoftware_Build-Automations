#include <windows.h>
#include <iostream>
#include <string>

using namespace std;

bool IsAiMode() { return strstr(GetCommandLineA(), "--ai-mode") != nullptr; }

int main(int argc, char* argv[]) {
    string adbArgs = "";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg != "--ai-mode") {
            adbArgs += arg + " ";
        }
    }

    if (adbArgs.empty() && !IsAiMode()) {
        cout << "Enter ADB command (e.g. devices): ";
        getline(cin, adbArgs);
    }

    if (adbArgs.empty()) {
        cerr << "ADB arguments required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    cout << "Executing Elite ADB FastBoot Bridge...\n";
    string cmd = "adb " + adbArgs;
    
    int ret = system(cmd.c_str());

    if (ret != 0) {
        cerr << "\n[WARN] ADB execution failed. Is adb.exe in your PATH?\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return ret;
}
