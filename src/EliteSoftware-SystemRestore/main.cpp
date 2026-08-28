#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <string>

using namespace std;

// SrRestorePtApi.h structures
#pragma pack(push, 1)
typedef struct _RESTOREPTINFOA {
    DWORD dwEventType;
    DWORD dwRestorePtType;
    INT64 llSequenceNumber;
    CHAR  szDescription[256];
} RESTOREPTINFOA, *PRESTOREPTINFOA;

typedef struct _STATEMGRSTATUS {
    DWORD nStatus;
    INT64 llSequenceNumber;
} STATEMGRSTATUS, *PSTATEMGRSTATUS;
#pragma pack(pop)

typedef BOOL (WINAPI *SRSetRestorePointA_t)(PRESTOREPTINFOA, PSTATEMGRSTATUS);



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-SystemRestore", argc, argv);

    string desc = "EliteSoftware Auto-Snapshot";

    for (int i = 1; i < argc; ++i) {
        if (string(argv[i]) == "--desc" && i + 1 < argc) desc = argv[++i];
    }

    if (!IsAiMode() && argc == 1) {
        cout << "Enter Restore Point Description: ";
        string tmp; getline(cin, tmp);
        if (!tmp.empty()) desc = tmp;
    }

    HMODULE hSrClient = LoadLibraryA("srclient.dll");
    if (!hSrClient) {
        cerr << "[ERROR] System Restore is not available or srclient.dll is missing.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    SRSetRestorePointA_t pSRSetRestorePoint = (SRSetRestorePointA_t)GetProcAddress(hSrClient, "SRSetRestorePointA");
    if (!pSRSetRestorePoint) {
        cerr << "[ERROR] Could not find SRSetRestorePoint API.\n";
        FreeLibrary(hSrClient);
        if (!IsAiMode()) system("pause");
        return 1;
    }

    RESTOREPTINFOA rpInfo = {0};
    STATEMGRSTATUS smStatus = {0};

    rpInfo.dwEventType = 100; // BEGIN_SYSTEM_CHANGE
    rpInfo.dwRestorePtType = 0; // APPLICATION_INSTALL
    rpInfo.llSequenceNumber = 0;
    strncpy(rpInfo.szDescription, desc.c_str(), sizeof(rpInfo.szDescription) - 1);

    cout << "Creating Restore Point: '" << desc << "'...\n";
    
    if (pSRSetRestorePoint(&rpInfo, &smStatus)) {
        cout << "[SUCCESS] Restore point created. Sequence: " << smStatus.llSequenceNumber << "\n";
    } else {
        cerr << "[ERROR] Failed to create restore point. (Ensure you are running as Administrator and System Protection is ON).\n";
    }

    FreeLibrary(hSrClient);

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
