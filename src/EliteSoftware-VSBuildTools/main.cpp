#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <string>

using namespace std;



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-VSBuildTools", argc, argv);

    cout << "EliteSoftware MSVC BuildTools Bootstrapper\n";
    cout << "Verifying Visual Studio Build Tools installation...\n";

    // Stub for headless bootstrapper
    cout << "[Stub] MSVC Build Tools integration point. Can natively invoke vs_buildtools.exe --quiet --wait\n";
    
    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
