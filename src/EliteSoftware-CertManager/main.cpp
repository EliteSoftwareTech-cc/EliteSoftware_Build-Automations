#include "..\EliteLogger.h"
#include <windows.h>
#include <wincrypt.h>
#include <iostream>
#include <string>
#include <fstream>
#include <vector>

#pragma comment(lib, "crypt32.lib")

using namespace std;



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-CertManager", argc, argv);

    string certPath = "";
    bool uninstall = false;

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--cert" && i + 1 < argc) certPath = argv[++i];
        else if (arg == "--uninstall") uninstall = true;
    }

    if (certPath.empty() && !IsAiMode()) {
        cout << "Enter path to .cer file: ";
        getline(cin, certPath);
        cout << "Uninstall instead of install? (y/n): ";
        string r; getline(cin, r);
        if (r == "y" || r == "Y") uninstall = true;
    }

    if (certPath.empty()) {
        cerr << "Certificate path required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    ifstream in(certPath, ios::binary | ios::ate);
    if (!in.is_open()) {
        cerr << "Failed to open certificate file: " << certPath << "\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    streamsize size = in.tellg();
    in.seekg(0, ios::beg);
    vector<BYTE> buffer(size);
    if (!in.read((char*)buffer.data(), size)) {
        cerr << "Failed to read certificate.\n";
        return 1;
    }
    in.close();

    PCCERT_CONTEXT pCertContext = CertCreateCertificateContext(X509_ASN_ENCODING | PKCS_7_ASN_ENCODING, buffer.data(), size);
    if (!pCertContext) {
        cerr << "Failed to parse certificate context. Error: " << GetLastError() << "\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    HCERTSTORE hStore = CertOpenStore(CERT_STORE_PROV_SYSTEM_A, 0, NULL, CERT_SYSTEM_STORE_LOCAL_MACHINE, "ROOT");
    if (!hStore) {
        cerr << "Failed to open Root certificate store. (Are you running as Administrator?)\n";
        CertFreeCertificateContext(pCertContext);
        if (!IsAiMode()) system("pause");
        return 1;
    }

    bool success = false;
    if (uninstall) {
        PCCERT_CONTEXT pFoundContext = CertFindCertificateInStore(
            hStore, X509_ASN_ENCODING | PKCS_7_ASN_ENCODING, 0, CERT_FIND_EXISTING, pCertContext, NULL);
        if (pFoundContext) {
            if (CertDeleteCertificateFromStore(pFoundContext)) {
                cout << "Successfully uninstalled certificate from Root Store.\n";
                success = true;
            } else {
                cerr << "Failed to uninstall certificate.\n";
            }
        } else {
            cerr << "Certificate not found in Root Store.\n";
        }
    } else {
        if (CertAddCertificateContextToStore(hStore, pCertContext, CERT_STORE_ADD_REPLACE_EXISTING, NULL)) {
            cout << "Successfully installed certificate to Trusted Root Store.\n";
            success = true;
        } else {
            cerr << "Failed to install certificate. Error: " << GetLastError() << "\n";
        }
    }

    CertCloseStore(hStore, 0);
    CertFreeCertificateContext(pCertContext);

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return success ? 0 : 1;
}
