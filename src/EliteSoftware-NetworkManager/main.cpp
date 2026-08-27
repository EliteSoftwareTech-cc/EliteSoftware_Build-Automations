#include <windows.h>
#include <iostream>

using namespace std;

bool IsAiMode() { return strstr(GetCommandLineA(), "--ai-mode") != nullptr; }

int main(int argc, char* argv[]) {
    cout << "EliteSoftware Network Manager\n";

    bool flushDns = false;
    for (int i = 1; i < argc; ++i) {
        if (string(argv[i]) == "--flush-dns") flushDns = true;
    }

    if (!IsAiMode() && argc == 1) {
        cout << "Flush DNS? (y/n): ";
        string r; getline(cin, r);
        if (r == "y" || r == "Y") flushDns = true;
    }

    if (flushDns) {
        cout << "Executing DNS Flush...\n";
        system("ipconfig /flushdns");
    } else {
        cout << "[Stub] Network Manager interface. Add --flush-dns to operate.\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
