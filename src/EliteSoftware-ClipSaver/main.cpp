#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <string>

using namespace std;



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-ClipSaver", argc, argv);

    string outDir = "C:\\EliteSoftware_Screenshots";

    for (int i = 1; i < argc; ++i) {
        if (string(argv[i]) == "--dir" && i + 1 < argc) outDir = argv[++i];
    }

    if (!IsAiMode() && argc == 1) {
        cout << "Enter Output Directory (default: " << outDir << "): ";
        string tmp; getline(cin, tmp);
        if (!tmp.empty()) outDir = tmp;
    }

    cout << "EliteSoftware ClipSaver Daemon started in: " << outDir << "\n";
    cout << "[Stub] Hooks SetClipboardViewer and saves CF_DIB to disk.\n";
    
    // As a placeholder, we'll just run briefly and exit.
    // In full implementation, this runs a message loop checking WM_DRAWCLIPBOARD.

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
