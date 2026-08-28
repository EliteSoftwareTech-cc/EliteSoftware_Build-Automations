#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <fstream>
#include <string>
#include <filesystem>
#include <vector>

using namespace std;
namespace fs = std::filesystem;



string EscapeJsonString(const string& input) {
    string output;
    for (char c : input) {
        if (c == '"') output += "\\\"";
        else if (c == '\\') output += "\\\\";
        else if (c == '\b') output += "\\b";
        else if (c == '\f') output += "\\f";
        else if (c == '\n') output += "\\n";
        else if (c == '\r') output += "\\r";
        else if (c == '\t') output += "\\t";
        else output += c;
    }
    return output;
}

int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-SiteCompiler", argc, argv);

    string dir = ".";
    string outFile = "DocsData.js";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--dir" && i + 1 < argc) dir = argv[++i];
        else if (arg == "--out" && i + 1 < argc) outFile = argv[++i];
    }

    if (!IsAiMode() && argc == 1) {
        cout << "Enter target directory containing .md files (default .): ";
        string temp; getline(cin, temp);
        if (!temp.empty()) dir = temp;
    }

    ofstream out(outFile);
    if (!out.is_open()) {
        cerr << "Failed to create " << outFile << "\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    out << "const EliteDocsData = {\n";
    bool first = true;
    int count = 0;

    try {
        for (const auto& entry : fs::directory_iterator(dir)) {
            if (entry.is_regular_file() && entry.path().extension() == ".md") {
                ifstream in(entry.path());
                if (in.is_open()) {
                    string content((istreambuf_iterator<char>(in)), istreambuf_iterator<char>());
                    if (!first) out << ",\n";
                    out << "  \"" << entry.path().filename().string() << "\": \"" << EscapeJsonString(content) << "\"";
                    first = false;
                    count++;
                }
            }
        }
    } catch (const fs::filesystem_error& e) {
        cerr << "Filesystem error: " << e.what() << "\n";
    }

    out << "\n};\n";
    out.close();

    cout << "Successfully compiled " << count << " Markdown files into " << outFile << "\n";

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
