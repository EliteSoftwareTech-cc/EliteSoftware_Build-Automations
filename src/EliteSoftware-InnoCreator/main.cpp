#include <iostream>
#include <windows.h>
#include <string>
#include <fstream>
#include <vector>

using namespace std;

bool IsAiMode() { return strstr(GetCommandLineA(), "--ai-mode") != nullptr; }

void GenerateTemplate(int type, const string& path) {
    ofstream out(path);
    if (!out) { cerr << "Cannot create file: " << path << "\n"; return; }
    if (type == 1) {
        out << "[Setup]\nAppName=EliteTool\nAppVersion=1.0\nDefaultDirName={autopf}\\EliteTool\n[Files]\nSource: \"*.exe\"; DestDir: \"{app}\"\n";
    } else if (type == 2) {
        out << "[Setup]\nAppName=EliteService\nAppVersion=1.0\nDefaultDirName={sys}\\EliteService\n[Files]\nSource: \"*.dll\"; DestDir: \"{sys}\"; Flags: regserver\n";
    } else {
        out << "[Setup]\nAppName=EliteSuite\nAppVersion=1.0\nDefaultDirName={autopf}\\EliteSuite\n[Files]\nSource: \"*.*\"; DestDir: \"{app}\"; Flags: recursesubdirs\n";
    }
    out.close();
    cout << "Template " << type << " generated at " << path << "\n";
}

int main(int argc, char* argv[]) {
    string mode = "";
    int templateType = 1;
    string outFile = "setup.iss";
    string isccArgs = "";

    if (argc > 1) {
        for (int i = 1; i < argc; ++i) {
            string arg = argv[i];
            if (arg == "--ai-mode") continue;
            if (arg == "--generate" || arg == "--compile") mode = arg;
            else if (arg == "--template" && i + 1 < argc) templateType = stoi(argv[++i]);
            else if (arg == "--out" && i + 1 < argc) outFile = argv[++i];
            else isccArgs += " " + arg;
        }
    }

    if (mode.empty() && !IsAiMode()) {
        cout << "Select mode (1: Generate Template, 2: Compile with ISCC): ";
        string m; getline(cin, m);
        if (m == "1") mode = "--generate";
        else if (m == "2") mode = "--compile";
    }

    if (mode == "--generate") {
        if (!IsAiMode() && argc <= 2) {
            cout << "Select template type (1: Basic EXE, 2: DLL Service, 3: Full Suite): ";
            string t; getline(cin, t);
            if (!t.empty()) templateType = stoi(t);
        }
        GenerateTemplate(templateType, outFile);
    } 
    else if (mode == "--compile") {
        if (!IsAiMode() && argc <= 2) {
            cout << "Enter path to .iss file: ";
            getline(cin, outFile);
        }
        string isccPath = "\"C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe\"";
        string cmd = isccPath + " \"" + outFile + "\"" + isccArgs;
        cout << "Executing: " << cmd << "\n";
        system(cmd.c_str());
    } else {
        cerr << "Invalid or missing mode.\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
