#include <windows.h>
#include <iostream>
#include <fstream>
#include <string>
#include <filesystem>

using namespace std;
namespace fs = std::filesystem;

bool IsAiMode() { return strstr(GetCommandLineA(), "--ai-mode") != nullptr; }

int main(int argc, char* argv[]) {
    cout << "EliteSoftware Profile Manager\n";

    char* userProfile = nullptr;
    size_t len;
    _dupenv_s(&userProfile, &len, "USERPROFILE");
    if (!userProfile) {
        cerr << "Failed to find USERPROFILE.\n";
        return 1;
    }

    string psDir = string(userProfile) + "\\Documents\\WindowsPowerShell";
    if (!fs::exists(psDir)) fs::create_directories(psDir);

    string profilePath = psDir + "\\Microsoft.PowerShell_profile.ps1";
    ofstream out(profilePath, ios::app);
    if (out.is_open()) {
        out << "\n# EliteSoftware Injected Environment\n";
        out << "Set-Alias -Name ll -Value Get-ChildItem\n";
        out << "function Reload-Profile { & $profile }\n";
        out << "Write-Host 'EliteSoftware Environment Loaded!' -ForegroundColor Cyan\n";
        out.close();
        cout << "[SUCCESS] PowerShell profile injected at: " << profilePath << "\n";
    } else {
        cerr << "[ERROR] Failed to write to profile.\n";
    }

    free(userProfile);

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
