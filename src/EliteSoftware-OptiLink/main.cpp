#include <windows.h>
#include <iostream>
#include <string>

using namespace std;

bool IsAiMode() { return strstr(GetCommandLineA(), "--ai-mode") != nullptr; }

int main(int argc, char* argv[]) {
    string mode = "client";
    string target = "\\\\.\\pipe\\EliteOptiLink";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--server") mode = "server";
        else if (arg == "--target" && i + 1 < argc) target = argv[++i];
    }

    if (!IsAiMode() && argc == 1) {
        cout << "Select mode (server/client): ";
        string tmp; getline(cin, tmp);
        if (!tmp.empty()) mode = tmp;
    }

    cout << "EliteSoftware OptiLink IPC Daemon starting as " << mode << "...\n";

    if (mode == "server") {
        cout << "[Stub] Waiting for connections on " << target << "...\n";
    } else {
        cout << "[Stub] Connecting to " << target << "...\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
