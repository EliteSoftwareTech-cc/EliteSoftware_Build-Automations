#include "..\EliteLogger.h"
#include <windows.h>
#include <urlmon.h>
#include <iostream>
#include <string>

#pragma comment(lib, "urlmon.lib")

using namespace std;



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-AssetManager", argc, argv);

    string url = "";
    string outPath = "";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--url" && i + 1 < argc) url = argv[++i];
        else if (arg == "--out" && i + 1 < argc) outPath = argv[++i];
    }

    if (url.empty() && !IsAiMode()) {
        cout << "Enter Asset URL: ";
        getline(cin, url);
        cout << "Enter Output File Path: ";
        getline(cin, outPath);
    }

    if (url.empty() || outPath.empty()) {
        cerr << "URL and Output path required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    cout << "Downloading asset from: " << url << "...\n";
    HRESULT hr = URLDownloadToFileA(NULL, url.c_str(), outPath.c_str(), 0, NULL);
    
    if (SUCCEEDED(hr)) {
        cout << "Successfully downloaded asset to " << outPath << "\n";
    } else {
        cerr << "Failed to download asset. HRESULT: 0x" << hex << hr << dec << "\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return SUCCEEDED(hr) ? 0 : 1;
}
