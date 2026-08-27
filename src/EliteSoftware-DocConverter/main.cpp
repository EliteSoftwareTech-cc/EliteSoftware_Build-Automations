#include <windows.h>
#include <iostream>
#include <fstream>
#include <string>

using namespace std;

bool IsAiMode() { return strstr(GetCommandLineA(), "--ai-mode") != nullptr; }

int main(int argc, char* argv[]) {
    string inFile = "";
    string outFile = "";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--in" && i + 1 < argc) inFile = argv[++i];
        else if (arg == "--out" && i + 1 < argc) outFile = argv[++i];
    }

    if (inFile.empty() && !IsAiMode()) {
        cout << "Enter input file (.rtf, .doc, etc): ";
        getline(cin, inFile);
    }
    if (outFile.empty() && !IsAiMode()) {
        cout << "Enter output file (.md, .txt): ";
        getline(cin, outFile);
    }

    if (inFile.empty() || outFile.empty()) {
        cerr << "Input and output paths required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    ifstream in(inFile, ios::binary);
    if (!in.is_open()) {
        cerr << "Failed to open input file.\n";
        return 1;
    }

    ofstream out(outFile);
    if (!out.is_open()) {
        cerr << "Failed to open output file.\n";
        return 1;
    }

    char ch;
    bool lastWasPrintable = false;
    while (in.get(ch)) {
        if (isprint((unsigned char)ch) || ch == '\n' || ch == '\r' || ch == '\t') {
            out << ch;
            lastWasPrintable = true;
        } else {
            if (lastWasPrintable) {
                out << " ";
                lastWasPrintable = false;
            }
        }
    }

    in.close();
    out.close();

    cout << "Flattened " << inFile << " into " << outFile << "\n";

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
