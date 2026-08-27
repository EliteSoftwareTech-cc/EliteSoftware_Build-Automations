#include <windows.h>
#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <filesystem>

using namespace std;
namespace fs = std::filesystem;

bool IsAiMode() { return strstr(GetCommandLineA(), "--ai-mode") != nullptr; }

int main(int argc, char* argv[]) {
    string configPath = "repos.txt";
    string targetDir = "Z:\\EliteSoftware-Projects";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--config" && i + 1 < argc) configPath = argv[++i];
        else if (arg == "--dir" && i + 1 < argc) targetDir = argv[++i];
    }

    if (!IsAiMode() && argc == 1) {
        cout << "Enter config file containing repo URLs (default: repos.txt): ";
        string tmp; getline(cin, tmp);
        if (!tmp.empty()) configPath = tmp;
        
        cout << "Enter target directory (default: Z:\\EliteSoftware-Projects): ";
        getline(cin, tmp);
        if (!tmp.empty()) targetDir = tmp;
    }

    ifstream in(configPath);
    if (!in.is_open()) {
        cerr << "Failed to open config file: " << configPath << "\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    if (!fs::exists(targetDir)) {
        fs::create_directories(targetDir);
    }

    string url;
    while (getline(in, url)) {
        if (url.empty() || url[0] == '#') continue;
        
        // Extract repo name from URL
        size_t lastSlash = url.find_last_of('/');
        if (lastSlash != string::npos) {
            string repoName = url.substr(lastSlash + 1);
            if (repoName.substr(repoName.length() - 4) == ".git") {
                repoName = repoName.substr(0, repoName.length() - 4);
            }
            
            string fullPath = targetDir + "\\" + repoName;
            if (fs::exists(fullPath)) {
                cout << "[SKIP] Repository already exists: " << repoName << "\n";
            } else {
                cout << "[CLONE] Cloning " << repoName << "...\n";
                string cmd = "git clone " + url + " \"" + fullPath + "\"";
                system(cmd.c_str());
            }
        }
    }
    in.close();

    cout << "\nRepository cloning phase complete.\n";

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
