#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <fstream>
#include <string>

using namespace std;



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-MetaStamper", argc, argv);

    string version = "1.0.0.0";
    string company = "EliteSoftware Co.";
    string product = "EliteSoftware Component";
    string outRc = "version.rc";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--version" && i + 1 < argc) version = argv[++i];
        else if (arg == "--company" && i + 1 < argc) company = argv[++i];
        else if (arg == "--product" && i + 1 < argc) product = argv[++i];
        else if (arg == "--out" && i + 1 < argc) outRc = argv[++i];
    }

    if (argc == 1 && !IsAiMode()) {
        cout << "Enter Version (e.g. 1.0.0.0): "; getline(cin, version);
        cout << "Enter Company: "; getline(cin, company);
        cout << "Enter Product: "; getline(cin, product);
    }

    ofstream out(outRc);
    if (!out.is_open()) {
        cerr << "Failed to create " << outRc << "\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    string commaVersion = version;
    for(auto& c : commaVersion) if(c == '.') c = ',';

    out << "1 VERSIONINFO\n";
    out << "FILEVERSION " << commaVersion << "\n";
    out << "PRODUCTVERSION " << commaVersion << "\n";
    out << "BEGIN\n";
    out << "  BLOCK \"StringFileInfo\"\n";
    out << "  BEGIN\n";
    out << "    BLOCK \"040904E4\"\n";
    out << "    BEGIN\n";
    out << "      VALUE \"CompanyName\", \"" << company << "\"\n";
    out << "      VALUE \"FileVersion\", \"" << version << "\"\n";
    out << "      VALUE \"ProductName\", \"" << product << "\"\n";
    out << "      VALUE \"ProductVersion\", \"" << version << "\"\n";
    out << "    END\n";
    out << "  END\n";
    out << "  BLOCK \"VarFileInfo\"\n";
    out << "  BEGIN\n";
    out << "    VALUE \"Translation\", 0x409, 1252\n";
    out << "  END\n";
    out << "END\n";
    out.close();

    cout << "Successfully generated " << outRc << " for windres compilation.\n";

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
