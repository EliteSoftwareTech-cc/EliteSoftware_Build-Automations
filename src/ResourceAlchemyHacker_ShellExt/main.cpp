#include <windows.h>
#include <shlobj.h>
#include <unknwn.h>
#include <shlwapi.h>
#pragma comment(lib, "shlwapi.lib")
#include <string>
#include <vector>
#include <olectl.h>

// #pragma comment(linker, "/EXPORT:DllGetClassObject,PRIVATE")
// #pragma comment(linker, "/EXPORT:DllCanUnloadNow,PRIVATE")
// #pragma comment(linker, "/EXPORT:DllRegisterServer,PRIVATE")
// #pragma comment(linker, "/EXPORT:DllUnregisterServer,PRIVATE")

// Global DLL reference count
long g_cRefThisDll = 0;
HINSTANCE g_hInst = NULL;

// Unique GUID for the new Resource Alchemy Hacker Shell Extension
// {A1B2C3D4-E5F6-7890-1234-567890ABCDEF}
const GUID CLSID_ResourceAlchemyHackerExt = 
{ 0xa1b2c3d4, 0xe5f6, 0x7890, { 0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef } };

class CResourceAlchemyHackerExt : public IShellExtInit, public IContextMenu, public IShellPropSheetExt
{
protected:
    long m_cRef;
    std::wstring m_szSelectedFile;

public:
    CResourceAlchemyHackerExt() : m_cRef(1) { InterlockedIncrement(&g_cRefThisDll); }
    ~CResourceAlchemyHackerExt() { InterlockedDecrement(&g_cRefThisDll); }

    // IUnknown
    IFACEMETHODIMP QueryInterface(REFIID riid, void **ppv) {
        static const QITAB qit[] = {
            QITABENT(CResourceAlchemyHackerExt, IShellExtInit),
            QITABENT(CResourceAlchemyHackerExt, IContextMenu),
            QITABENT(CResourceAlchemyHackerExt, IShellPropSheetExt),
            { 0 },
        };
        return QISearch(this, qit, riid, ppv);
    }
    IFACEMETHODIMP_(ULONG) AddRef() { return InterlockedIncrement(&m_cRef); }
    IFACEMETHODIMP_(ULONG) Release() {
        ULONG cRef = InterlockedDecrement(&m_cRef);
        if (0 == cRef) delete this;
        return cRef;
    }

    // IShellExtInit
    IFACEMETHODIMP Initialize(PCIDLIST_ABSOLUTE pidlFolder, IDataObject *pdtobj, HKEY hkeyProgID) {
        if (!pdtobj) return E_INVALIDARG;
        FORMATETC fe = { CF_HDROP, NULL, DVASPECT_CONTENT, -1, TYMED_HGLOBAL };
        STGMEDIUM stm;
        if (SUCCEEDED(pdtobj->GetData(&fe, &stm))) {
            HDROP hDrop = static_cast<HDROP>(GlobalLock(stm.hGlobal));
            if (hDrop) {
                UINT nFiles = DragQueryFileW(hDrop, 0xFFFFFFFF, NULL, 0);
                if (nFiles == 1) { // Only handle single file for property sheet/context menu right now
                    wchar_t szFile[MAX_PATH];
                    if (DragQueryFileW(hDrop, 0, szFile, ARRAYSIZE(szFile))) {
                        m_szSelectedFile = szFile;
                    }
                }
                GlobalUnlock(stm.hGlobal);
            }
            ReleaseStgMedium(&stm);
            return S_OK;
        }
        return E_FAIL;
    }

    // IContextMenu
    IFACEMETHODIMP QueryContextMenu(HMENU hmenu, UINT indexMenu, UINT idCmdFirst, UINT idCmdLast, UINT uFlags) {
        if (CMF_DEFAULTONLY & uFlags) return MAKE_HRESULT(SEVERITY_SUCCESS, 0, USHORT(0));
        
        InsertMenuW(hmenu, indexMenu, MF_STRING | MF_BYPOSITION, idCmdFirst + 1, L"Resource Alchemy Hacker");
        
        // Return the number of menu items added
        return MAKE_HRESULT(SEVERITY_SUCCESS, 0, USHORT(1));
    }
    
    IFACEMETHODIMP InvokeCommand(CMINVOKECOMMANDINFO *pici) {
        wchar_t szDllPath[MAX_PATH];
        if (GetModuleFileNameW(g_hInst, szDllPath, ARRAYSIZE(szDllPath)) == 0) {
            return E_FAIL;
        }

        PathRemoveFileSpecW(szDllPath);

        std::wstring guiPath = std::wstring(szDllPath) + L"\\ResourceAlchemyHacker_GUI.exe";
        std::wstring cmdLine = L"\"" + guiPath + L"\" \"" + m_szSelectedFile + L"\"";
        
        std::vector<wchar_t> cmdLineBuf(cmdLine.begin(), cmdLine.end());
        cmdLineBuf.push_back(L'\0');

        STARTUPINFOW si = { sizeof(si) };
        PROCESS_INFORMATION pi = { 0 };

        if (CreateProcessW(NULL, cmdLineBuf.data(), NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
            CloseHandle(pi.hProcess);
            CloseHandle(pi.hThread);
            return S_OK;
        }
        
        return E_FAIL;
    }
    
    IFACEMETHODIMP GetCommandString(UINT_PTR idCmd, UINT uType, UINT *pReserved, LPSTR pszName, UINT cchMax) {
        return S_OK;
    }

    // IShellPropSheetExt
    IFACEMETHODIMP AddPages(LPFNADDPROPSHEETPAGE pfnAddPage, LPARAM lParam) {
        // Here we would create a Property Sheet Page that looks like the Native Icon Picker
        // PROPSHEETPAGE psp = { sizeof(PROPSHEETPAGE) }; ...
        return S_OK;
    }
    
    IFACEMETHODIMP ReplacePage(UINT uPageID, LPFNADDPROPSHEETPAGE pfnReplaceWith, LPARAM lParam) {
        return E_NOTIMPL;
    }
};

class CClassFactory : public IClassFactory
{
protected:
    long m_cRef;
public:
    CClassFactory() : m_cRef(1) { InterlockedIncrement(&g_cRefThisDll); }
    ~CClassFactory() { InterlockedDecrement(&g_cRefThisDll); }

    IFACEMETHODIMP QueryInterface(REFIID riid, void **ppv) {
        static const QITAB qit[] = {
            QITABENT(CClassFactory, IClassFactory),
            { 0 },
        };
        return QISearch(this, qit, riid, ppv);
    }
    IFACEMETHODIMP_(ULONG) AddRef() { return InterlockedIncrement(&m_cRef); }
    IFACEMETHODIMP_(ULONG) Release() {
        ULONG cRef = InterlockedDecrement(&m_cRef);
        if (0 == cRef) delete this;
        return cRef;
    }

    IFACEMETHODIMP CreateInstance(IUnknown *pUnkOuter, REFIID riid, void **ppv) {
        if (pUnkOuter) return CLASS_E_NOAGGREGATION;
        CResourceAlchemyHackerExt *pExt = new (std::nothrow) CResourceAlchemyHackerExt();
        if (!pExt) return E_OUTOFMEMORY;
        HRESULT hr = pExt->QueryInterface(riid, ppv);
        pExt->Release();
        return hr;
    }
    IFACEMETHODIMP LockServer(BOOL fLock) {
        if (fLock) InterlockedIncrement(&g_cRefThisDll);
        else InterlockedDecrement(&g_cRefThisDll);
        return S_OK;
    }
};

STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, void **ppv)
{
    if (rclsid == CLSID_ResourceAlchemyHackerExt) {
        CClassFactory *pCF = new (std::nothrow) CClassFactory();
        if (!pCF) return E_OUTOFMEMORY;
        HRESULT hr = pCF->QueryInterface(riid, ppv);
        pCF->Release();
        return hr;
    }
    return CLASS_E_CLASSNOTAVAILABLE;
}

STDAPI DllCanUnloadNow(void)
{
    return (g_cRefThisDll == 0) ? S_OK : S_FALSE;
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
        g_hInst = hModule;
        DisableThreadLibraryCalls(hModule);
        break;
    }
    return TRUE;
}

BOOL SetRegKeyValue(HKEY hKeyParent, const wchar_t* subKey, const wchar_t* valueName, const wchar_t* data) {
    HKEY hKey;
    LONG result = RegCreateKeyExW(hKeyParent, subKey, 0, NULL, REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hKey, NULL);
    if (result != ERROR_SUCCESS) return FALSE;
    result = RegSetValueExW(hKey, valueName, 0, REG_SZ, (BYTE*)data, (DWORD)(wcslen(data) + 1) * sizeof(wchar_t));
    RegCloseKey(hKey);
    return (result == ERROR_SUCCESS);
}

BOOL DeleteRegKey(HKEY hKeyParent, const wchar_t* subKey) {
    if (RegDeleteKeyW(hKeyParent, subKey) == ERROR_SUCCESS) {
        return TRUE;
    }
    return (RegDeleteTreeW(hKeyParent, subKey) == ERROR_SUCCESS);
}

STDAPI DllRegisterServer(void) {
    wchar_t szModule[MAX_PATH];
    if (GetModuleFileNameW(g_hInst, szModule, ARRAYSIZE(szModule)) == 0) {
        return HRESULT_FROM_WIN32(GetLastError());
    }

    const wchar_t* clsidStr = L"{A1B2C3D4-E5F6-7890-1234-567890ABCDEF}";
    std::wstring clsidKey = std::wstring(L"CLSID\\") + clsidStr;
    std::wstring inprocKey = clsidKey + L"\\InprocServer32";

    if (!SetRegKeyValue(HKEY_CLASSES_ROOT, clsidKey.c_str(), NULL, L"Resource Alchemy Hacker Shell Extension")) {
        return SELFREG_E_CLASS;
    }
    if (!SetRegKeyValue(HKEY_CLASSES_ROOT, inprocKey.c_str(), NULL, szModule)) {
        return SELFREG_E_CLASS;
    }
    if (!SetRegKeyValue(HKEY_CLASSES_ROOT, inprocKey.c_str(), L"ThreadingModel", L"Apartment")) {
        return SELFREG_E_CLASS;
    }

    // Context Menu Handlers
    if (!SetRegKeyValue(HKEY_CLASSES_ROOT, L"*\\shellex\\ContextMenuHandlers\\ResourceAlchemyHacker", NULL, clsidStr)) {
        return SELFREG_E_CLASS;
    }
    if (!SetRegKeyValue(HKEY_CLASSES_ROOT, L"exefile\\shellex\\ContextMenuHandlers\\ResourceAlchemyHacker", NULL, clsidStr)) {
        return SELFREG_E_CLASS;
    }

    // Property Sheet Handlers
    if (!SetRegKeyValue(HKEY_CLASSES_ROOT, L"*\\shellex\\PropertySheetHandlers\\ResourceAlchemyHacker", NULL, clsidStr)) {
        return SELFREG_E_CLASS;
    }
    if (!SetRegKeyValue(HKEY_CLASSES_ROOT, L"exefile\\shellex\\PropertySheetHandlers\\ResourceAlchemyHacker", NULL, clsidStr)) {
        return SELFREG_E_CLASS;
    }

    return S_OK;
}

STDAPI DllUnregisterServer(void) {
    const wchar_t* clsidStr = L"{A1B2C3D4-E5F6-7890-1234-567890ABCDEF}";
    std::wstring clsidKey = std::wstring(L"CLSID\\") + clsidStr;

    DeleteRegKey(HKEY_CLASSES_ROOT, clsidKey.c_str());
    DeleteRegKey(HKEY_CLASSES_ROOT, L"*\\shellex\\ContextMenuHandlers\\ResourceAlchemyHacker");
    DeleteRegKey(HKEY_CLASSES_ROOT, L"exefile\\shellex\\ContextMenuHandlers\\ResourceAlchemyHacker");
    DeleteRegKey(HKEY_CLASSES_ROOT, L"*\\shellex\\PropertySheetHandlers\\ResourceAlchemyHacker");
    DeleteRegKey(HKEY_CLASSES_ROOT, L"exefile\\shellex\\PropertySheetHandlers\\ResourceAlchemyHacker");

    return S_OK;
}



