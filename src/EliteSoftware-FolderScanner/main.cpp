#include <windows.h>
#include <iostream>
#include <string>
#include <vector>

using namespace std;

bool IsAiMode() { return strstr(GetCommandLineA(), "--ai-mode") != nullptr; }

void ScanDirectory(const string& dir, ULONGLONG& totalSize, ULONGLONG& fileCount, ULONGLONG& dirCount) {
    WIN32_FIND_DATAA findData;
    HANDLE hFind = FindFirstFileA((dir + "\\*").c_str(), &findData);

    if (hFind == INVALID_HANDLE_VALUE) return;

    do {
        string name = findData.cFileName;
        if (name == "." || name == "..") continue;

        if (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
            dirCount++;
            ScanDirectory(dir + "\\" + name, totalSize, fileCount, dirCount);
        } else {
            fileCount++;
            ULARGE_INTEGER sz;
            sz.LowPart = findData.nFileSizeLow;
            sz.HighPart = findData.nFileSizeHigh;
            totalSize += sz.QuadPart;
        }
    } while (FindNextFileA(hFind, &findData));

    FindClose(hFind);
}

int main(int argc, char* argv[]) {
    string targetDir = ".";

    for (int i = 1; i < argc; ++i) {
        if (string(argv[i]) == "--dir" && i + 1 < argc) targetDir = argv[++i];
    }

    if (!IsAiMode() && argc == 1) {
        cout << "Enter target directory to scan (default is current): ";
        string tmp; getline(cin, tmp);
        if (!tmp.empty()) targetDir = tmp;
    }

    cout << "Scanning directory: " << targetDir << "...\n";

    ULONGLONG totalSize = 0, fileCount = 0, dirCount = 0;
    DWORD tStart = GetTickCount();
    
    ScanDirectory(targetDir, totalSize, fileCount, dirCount);
    
    DWORD tEnd = GetTickCount();

    cout << "\n--- EliteFolderScanner Results ---\n";
    cout << "Total Files: " << fileCount << "\n";
    cout << "Total Directories: " << dirCount << "\n";
    cout << "Total Size (Bytes): " << totalSize << "\n";
    cout << "Scan Time: " << (tEnd - tStart) << " ms\n";

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
