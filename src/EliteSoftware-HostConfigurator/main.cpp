#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>

using namespace std;



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-HostConfigurator", argc, argv);

    string domain = "";
    string ip = "127.0.0.1";
    bool remove = false;

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--domain" && i + 1 < argc) domain = argv[++i];
        else if (arg == "--ip" && i + 1 < argc) ip = argv[++i];
        else if (arg == "--remove") remove = true;
    }

    if (domain.empty() && !IsAiMode()) {
        cout << "Enter Domain Name (e.g. elitesoftwaretech.cc): ";
        getline(cin, domain);
        cout << "Remove routing? (y/n): ";
        string r; getline(cin, r);
        if (r == "y" || r == "Y") remove = true;
        else {
            cout << "Enter IP to route to (default 127.0.0.1): ";
            getline(cin, ip);
            if (ip.empty()) ip = "127.0.0.1";
        }
    }

    if (domain.empty()) {
        cerr << "Domain name required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    char winDir[MAX_PATH];
    GetWindowsDirectoryA(winDir, MAX_PATH);
    string hostsFile = string(winDir) + "\\System32\\drivers\\etc\\hosts";

    vector<string> lines;
    ifstream in(hostsFile);
    if (in.is_open()) {
        string line;
        while (getline(in, line)) {
            if (line.find(domain) == string::npos) {
                lines.push_back(line);
            }
        }
        in.close();
    }

    ofstream out(hostsFile);
    if (out.is_open()) {
        for (const string& l : lines) out << l << "\n";
        if (!remove) {
            out << ip << "\t" << domain << "\n";
            cout << "Routed " << domain << " to " << ip << " in hosts file.\n";
        } else {
            cout << "Removed " << domain << " from hosts file.\n";
        }
        out.close();
    } else {
        cerr << "Failed to open hosts file. (Are you running as Administrator?)\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
