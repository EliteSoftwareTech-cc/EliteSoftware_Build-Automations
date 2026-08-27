#include <windows.h>
#include <shobjidl.h>
#include <objbase.h>
#include <shlguid.h>
#include <iostream>
#include <string>

using namespace std;

bool IsAiMode() { return strstr(GetCommandLineA(), "--ai-mode") != nullptr; }

HRESULT CreateLink(LPCSTR lpszPathObj, LPCSTR lpszPathLink, LPCSTR lpszDesc, LPCSTR lpszArgs, LPCSTR lpszDir, LPCSTR lpszIcon) {
    HRESULT hres;
    IShellLinkA* psl;

    hres = CoCreateInstance(CLSID_ShellLink, NULL, CLSCTX_INPROC_SERVER, IID_IShellLinkA, (LPVOID*)&psl);
    if (SUCCEEDED(hres)) {
        IPersistFile* ppf;
        psl->SetPath(lpszPathObj);
        if (lpszDesc && lpszDesc[0]) psl->SetDescription(lpszDesc);
        if (lpszArgs && lpszArgs[0]) psl->SetArguments(lpszArgs);
        if (lpszDir && lpszDir[0]) psl->SetWorkingDirectory(lpszDir);
        if (lpszIcon && lpszIcon[0]) psl->SetIconLocation(lpszIcon, 0);

        hres = psl->QueryInterface(IID_IPersistFile, (LPVOID*)&ppf);
        if (SUCCEEDED(hres)) {
            WCHAR wsz[MAX_PATH];
            MultiByteToWideChar(CP_ACP, 0, lpszPathLink, -1, wsz, MAX_PATH);
            hres = ppf->Save(wsz, TRUE);
            ppf->Release();
        }
        psl->Release();
    }
    return hres;
}

int main(int argc, char* argv[]) {
    string target = "";
    string outLink = "";
    string icon = "";
    string args = "";
    string workdir = "";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--target" && i + 1 < argc) target = argv[++i];
        else if (arg == "--out" && i + 1 < argc) outLink = argv[++i];
        else if (arg == "--icon" && i + 1 < argc) icon = argv[++i];
        else if (arg == "--args" && i + 1 < argc) args = argv[++i];
        else if (arg == "--workdir" && i + 1 < argc) workdir = argv[++i];
    }

    if (target.empty() && !IsAiMode()) {
        cout << "Enter target executable path: ";
        getline(cin, target);
    }
    if (outLink.empty() && !IsAiMode()) {
        cout << "Enter output .lnk path: ";
        getline(cin, outLink);
    }

    if (target.empty() || outLink.empty()) {
        cerr << "Target and output link paths are required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    CoInitialize(NULL);
    HRESULT hr = CreateLink(target.c_str(), outLink.c_str(), "EliteSoftware Shortcut", args.c_str(), workdir.c_str(), icon.c_str());
    CoUninitialize();

    if (SUCCEEDED(hr)) {
        cout << "Successfully created shortcut at " << outLink << "\n";
    } else {
        cerr << "Failed to create shortcut. HRESULT: 0x" << hex << hr << dec << "\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return SUCCEEDED(hr) ? 0 : 1;
}
