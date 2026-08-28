#include "..\EliteLogger.h"
#include <iostream>
#include <windows.h>
#include <string>
#include <fstream>
#include <chrono>
#include <vector>

using namespace std;



void ListCLSIDs(const string& filter = "") {
    HKEY hKey;
    if (RegOpenKeyExA(HKEY_CLASSES_ROOT, "CLSID", 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        char subKeyName[256];
        DWORD subKeyNameSize;
        DWORD index = 0;
        cout << "Listing Registered CLSIDs...\n";
        while (true) {
            subKeyNameSize = sizeof(subKeyName);
            if (RegEnumKeyExA(hKey, index, subKeyName, &subKeyNameSize, NULL, NULL, NULL, NULL) != ERROR_SUCCESS) {
                break;
            }
            HKEY hSubKey;
            string fullPath = string("CLSID\\") + subKeyName;
            if (RegOpenKeyExA(HKEY_CLASSES_ROOT, fullPath.c_str(), 0, KEY_READ, &hSubKey) == ERROR_SUCCESS) {
                char value[512];
                DWORD valueSize = sizeof(value);
                if (RegQueryValueExA(hSubKey, NULL, NULL, NULL, (LPBYTE)value, &valueSize) == ERROR_SUCCESS) {
                    string valStr(value);
                    if (filter.empty() || valStr.find(filter) != string::npos || string(subKeyName).find(filter) != string::npos) {
                        cout << subKeyName << " -> " << valStr << "\n";
                    }
                }
                RegCloseKey(hSubKey);
            }
            index++;
        }
        RegCloseKey(hKey);
    }
}

int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-CLSIDGenerator", argc, argv);

    string programName = "";
    bool listMode = false;
    string filter = "";

    if (argc > 1) {
        for (int i = 1; i < argc; ++i) {
            string arg = argv[i];
            if (arg == "--name" && i + 1 < argc) programName = argv[++i];
            else if (arg == "--list") listMode = true;
            else if (arg == "--filter" && i + 1 < argc) filter = argv[++i];
        }
    }

    if (listMode) {
        ListCLSIDs(filter);
        if (!IsAiMode()) { cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    }

    if (programName.empty() && !IsAiMode()) {
        cout << "Enter the name of the program to generate a CLSID for (or type --list to view registry): ";
        getline(cin, programName);
        if (programName == "--list") {
            ListCLSIDs();
            system("pause");
            return 0;
        }
    }

    if (programName.empty()) {
        cerr << "Program name is required.\n";
        if(!IsAiMode()) system("pause");
        return 1;
    }

    char guidStr[40];
    bool isUnique = false;
    
    while (!isUnique) {
        GUID guid;
        CoCreateGuid(&guid);
        sprintf_s(guidStr, "{%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X}",
            guid.Data1, guid.Data2, guid.Data3,
            guid.Data4[0], guid.Data4[1], guid.Data4[2], guid.Data4[3],
            guid.Data4[4], guid.Data4[5], guid.Data4[6], guid.Data4[7]);

        HKEY hKey;
        string regPath = "CLSID\\" + string(guidStr);
        if (RegOpenKeyExA(HKEY_CLASSES_ROOT, regPath.c_str(), 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
            RegCloseKey(hKey);
            // Collision! Loop again
        } else {
            isUnique = true;
        }
    }

    cout << "Generated Unique CLSID: " << guidStr << "\n";
    cout << "SUCCESS: This CLSID is unique and not currently registered.\n";

    char exePath[MAX_PATH];
    GetModuleFileNameA(NULL, exePath, MAX_PATH);
    string dbPath = string(exePath);
    dbPath = dbPath.substr(0, dbPath.find_last_of("\\/")) + "\\clsid_database.txt";

    ofstream db(dbPath, ios::app);
    if (db.is_open()) {
        db << programName << " = " << guidStr << "\n";
        db.close();
        cout << "Saved to database: " << dbPath << "\n";
    } else {
        cerr << "Failed to open database file.\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
