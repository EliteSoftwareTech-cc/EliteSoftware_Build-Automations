#include <iostream>
#include <windows.h>
#include <string>
#include <fstream>
#include <filesystem>
#include <chrono>

using namespace std;

bool IsAiMode() { return strstr(GetCommandLineA(), "--ai-mode") != nullptr; }

string GetTimeSafe() {
    auto now = std::chrono::system_clock::now();
    std::time_t now_time = std::chrono::system_clock::to_time_t(now);
    char timeStr[26];
    ctime_s(timeStr, sizeof(timeStr), &now_time);
    timeStr[24] = '\0';
    string timeSafe = timeStr;
    for (char& c : timeSafe) { if (c == ':' || c == ' ') c = '-'; }
    return timeSafe;
}

int main(int argc, char* argv[]) {
    string targetDir = "";
    string outDir = "";
    bool useCab = false;

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--dir" && i + 1 < argc) targetDir = argv[++i];
        else if (arg == "--out" && i + 1 < argc) outDir = argv[++i];
        else if (arg == "--cab") useCab = true;
    }

    if (targetDir.empty() && !IsAiMode()) {
        cout << "Enter the project directory to backup (or leave blank for current dir): ";
        getline(cin, targetDir);
    }
    
    if (targetDir.empty()) {
        char cwd[MAX_PATH];
        GetCurrentDirectoryA(MAX_PATH, cwd);
        targetDir = string(cwd);
    }

    if (outDir.empty()) {
        outDir = targetDir + "\\Backups";
    }

    if (!std::filesystem::exists(outDir)) {
        std::filesystem::create_directories(outDir);
    }

    string ts = GetTimeSafe();
    
    if (useCab) {
        string cabFile = outDir + "\\Backup_" + ts + ".cab";
        string ddfFile = outDir + "\\temp.ddf";
        ofstream ddf(ddfFile);
        ddf << ".OPTION EXPLICIT\n.Set CabinetNameTemplate=" << cabFile << "\n.Set DiskDirectoryTemplate=\n.Set MaxDiskSize=CDROM\n";
        
        for(auto& p: std::filesystem::recursive_directory_iterator(targetDir)) {
            if (p.is_regular_file()) {
                string path = p.path().string();
                if (path.find("\\Backups\\") == string::npos && path.find(".git\\") == string::npos) {
                    ddf << "\"" << path << "\"\n";
                }
            }
        }
        ddf.close();
        
        cout << "Creating CAB Backup...\n";
        string cmd = "makecab.exe /F \"" + ddfFile + "\"";
        system(cmd.c_str());
        DeleteFileA(ddfFile.c_str());
        DeleteFileA("setup.inf");
        DeleteFileA("setup.rpt");
        cout << "CAB Backup saved to: " << cabFile << "\n";
    } else {
        string wimFile = outDir + "\\Backup_" + ts + ".wim";
        cout << "Creating WIM Backup...\n";
        string cmd = "dism.exe /Capture-Image /ImageFile:\"" + wimFile + "\" /CaptureDir:\"" + targetDir + "\" /Name:\"Backup_" + ts + "\"";
        system(cmd.c_str());
        cout << "WIM Backup saved to: " << wimFile << "\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
