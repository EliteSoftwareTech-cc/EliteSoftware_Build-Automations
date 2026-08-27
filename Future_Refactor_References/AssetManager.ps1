<#
.SYNOPSIS
    A self-contained PowerShell launcher for the entirely web-based EliteSoftware - AssetManager Pro.

.DESCRIPTION
    EliteSoftware - AssetManager Pro (Web App Launcher)
    Project Version: 9.0 (Network Discovery & Theming)
    Created by: Zachary Whiteman & Google Gemini AI
    Date: 7/23/2025 - 3:00 PM

    This script launches a comprehensive, local, Python-based web application for asset management.
    It performs a one-time setup and stores all data permanently in C:\AssetManager.

    Version 9.0 is a major overhaul, introducing powerful new features and fixing key issues:
    - Network Discovery: Automatically scan your local network to find devices and add them as assets.
    - IPAM Upgrade: Automatic detection of the server's local subnet for scanning.
    - Expanded Theming: Includes new themes like Vista, Windows Classic, Terminal, and more.
    - Functional Kiosk/Scan Modes: Reworked to be reliable with hardware barcode scanners.
    - Attachment Fix: Correctly displays uploaded images for assets.
    - Advanced Settings: Control asset number prefixes, default checkout user, and dashboard pagination.
    - Dashboard Pagination: Easily navigate large lists of assets.
    - General UI/UX improvements and bug fixes throughout the application.

.NOTES
    REQUIREMENTS:
    - Python 3 must be installed and added to the system's PATH.
    - The nmap network scanning tool (https://nmap.org/) must be installed for the Network Discovery feature.
    - The script will self-elevate to run as Administrator for the initial setup.
#>

# --- SCRIPT CONFIGURATION & INITIAL SETUP ---

# Define global paths and variables
$appDataPath = "C:\AssetManager"
$pythonScriptPath = Join-Path -Path $appDataPath -ChildPath "_asset_manager_webapp.py"
$hostsFilePath = Join-Path -Path $env:SystemRoot -ChildPath "System32\drivers\etc\hosts"
$webDomain = "asset.manager.local"

# --- HELPER FUNCTIONS ---

function Ensure-EnvironmentSetup {
    # This function now also handles Python dependency installation and checks for nmap.
    $needsSetup = $false
    $pythonInPath = $false
    $nmapInPath = $false
    $hostsEntryExists = $false

    if (Get-Command python -ErrorAction SilentlyContinue) { $pythonInPath = $true }
    if (Get-Command nmap -ErrorAction SilentlyContinue) { $nmapInPath = $true }
    if (Select-String -Path $hostsFilePath -Pattern $webDomain -Quiet) { $hostsEntryExists = $true }

    if (-not $pythonInPath -or -not $hostsEntryExists -or -not $nmapInPath) { $needsSetup = $true }

    if (-not $needsSetup) { Write-Verbose "Environment is already configured."; return }

    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Add-Type -AssemblyName System.Windows.Forms
        $message = "AssetManager Pro needs to perform a one-time setup. This requires administrator rights to configure the environment and check for required software (Python, Nmap). Please click OK to grant permission."
        [System.Windows.Forms.MessageBox]::Show($message, "Administrator Privileges Required", "OK", "Information") | Out-Null
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`"" -Verb RunAs
        exit
    }

    Write-Host "Running one-time setup as Administrator..." -ForegroundColor Yellow
    if (-not $pythonInPath) {
        throw "Python could not be found in your system's PATH. Please install Python 3 and ensure it is added to the PATH."
    }
    if (-not $nmapInPath) {
        Write-Warning "The 'nmap' command was not found. The Network Discovery feature will not work."
        Write-Warning "Please install Nmap from https://nmap.org/ and ensure its directory is in your system PATH."
        Start-Sleep -Seconds 3
    }
    if (-not $hostsEntryExists) {
        Write-Host "Adding '$webDomain' to hosts file..."
        Add-Content -Path $hostsFilePath -Value "`n127.0.0.1`t$webDomain"
        Write-Host "Hosts file updated successfully." -ForegroundColor Green
    }
    Write-Host "Setup complete. The application will now launch." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
}

function Ensure-PythonDependencies {
    param($ModuleName, $InstallName)
    if (-not $InstallName) { $InstallName = $ModuleName }
    Write-Host "Checking for Python module: $ModuleName..."
    $pythonExe = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $pythonExe) {
        throw "Could not find python.exe. Please ensure Python is installed and in your PATH."
    }

    # Correctly formatted Python command to avoid syntax errors
    $checkScript = "try: import $ModuleName; print('True')`nexcept ImportError: print('False')"
    $isInstalled = & $pythonExe -c $checkScript
    
    if ($isInstalled -match 'False') {
        Write-Host "Module '$ModuleName' not found. Attempting to install '$InstallName' with pip..." -ForegroundColor Yellow
        & $pythonExe -m pip install $InstallName
        $isInstalledAfter = & $pythonExe -c $checkScript
        if ($isInstalledAfter -match 'False') {
            throw "Failed to install Python module '$ModuleName'. Please try installing it manually: python -m pip install $InstallName"
        }
        Write-Host "Module '$ModuleName' installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Module '$ModuleName' is already installed." -ForegroundColor Green
    }
}

function Test-PortAvailability {
    param($Port)
    $connection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if ($connection -eq $null) { return $true } else { return $false }
}


# --- MAIN SCRIPT LOGIC ---
$pythonProcess = $null
try {
    # 1. Run environment setup checks.
    Ensure-EnvironmentSetup

    # 2. Ensure Python dependencies are installed.
    Ensure-PythonDependencies -ModuleName "barcode" -InstallName "python-barcode"
    Ensure-PythonDependencies -ModuleName "qrcode"
    Ensure-PythonDependencies -ModuleName "PIL" -InstallName "Pillow"
    Ensure-PythonDependencies -ModuleName "nmap" -InstallName "python-nmap"


    # 3. Create the permanent application directory if it doesn't exist.
    if (-not (Test-Path -Path $appDataPath)) {
        Write-Host "Creating permanent application directory at $appDataPath"
        New-Item -Path $appDataPath -ItemType Directory | Out-Null
        New-Item -Path (Join-Path -Path $appDataPath -ChildPath "icons") -ItemType Directory | Out-Null

        # First-time setup: Prompt for favicon
        Add-Type -AssemblyName System.Windows.Forms
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = "Select a Favicon (Optional)"
        $dialog.Filter = "Icon Files (*.ico)|*.ico"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            # Set as the active icon
            Copy-Item -Path $dialog.FileName -Destination (Join-Path -Path $appDataPath -ChildPath "favicon.ico")
            # Also save to history
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            Copy-Item -Path $dialog.FileName -Destination (Join-Path -Path $appDataPath -ChildPath "icons\icon-$timestamp.ico")
            Write-Host "Favicon has been set." -ForegroundColor Green
        }
    }

    # 4. Minimize the console window.
    try {
        $code = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
        Add-Type -name "User32" -namespace "Win32" -memberDefinition $code -passthru | Out-Null
        [Win32.User32]::ShowWindow((Get-Process -Id $pid).MainWindowHandle, 2) | Out-Null
    } catch { Write-Warning "Could not minimize console window." }

    # --- PYTHON WEB APP SCRIPT CONTENT ---
    $pythonScript = @"
# EliteSoftware - AssetManager Pro
# Project Version: 9.0 (Network Discovery & Theming)
# Created by: Zachary Whiteman & Google Gemini AI
# Date: 7/23/2025 - 3:00 PM

import sqlite3, os, sys, webbrowser, threading, json, re, socket, io, csv, shutil, math
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse, unquote_plus
import datetime
import barcode
from barcode.writer import SVGWriter
import qrcode
from PIL import Image
try:
    import nmap
except ImportError:
    nmap = None # Gracefully handle if python-nmap is not installed

# --- CONFIGURATION ---
SCRIPT_ROOT = os.path.dirname(os.path.abspath(__file__))
DATABASE_PATH = os.path.join(SCRIPT_ROOT, "asset_manager.db")
ATTACHMENTS_PATH = os.path.join(SCRIPT_ROOT, "attachments")
BACKUP_PATH = os.path.join(SCRIPT_ROOT, "backups")
ICONS_PATH = os.path.join(SCRIPT_ROOT, "icons")
FAVICON_PATH = os.path.join(SCRIPT_ROOT, "favicon.ico")
WEB_PORT = 8080 # Default
OUI_DATA_URL = "http://standards-oui.ieee.org/oui/oui.txt"
OUI_FILE_PATH = os.path.join(SCRIPT_ROOT, "oui.txt")


# --- DATABASE FUNCTIONS ---
def get_db_connection():
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn

def initialize_database():
    for path in [ATTACHMENTS_PATH, BACKUP_PATH, ICONS_PATH]:
        if not os.path.exists(path): os.makedirs(path)

    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Main Tables
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS Assets (
            AssetID INTEGER PRIMARY KEY AUTOINCREMENT, AssetNumber TEXT NOT NULL UNIQUE,
            Name TEXT NOT NULL, Category TEXT, Status TEXT DEFAULT 'Checked In',
            PurchaseDate TEXT, Cost REAL
        );
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS Logs (
            LogID INTEGER PRIMARY KEY AUTOINCREMENT, AssetID INTEGER, Timestamp TEXT,
            User TEXT, Action TEXT, Notes TEXT,
            FOREIGN KEY(AssetID) REFERENCES Assets(AssetID) ON DELETE CASCADE
        );
    ''')
    
    # Feature Tables
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS Maintenance (
            MaintenanceID INTEGER PRIMARY KEY AUTOINCREMENT, AssetID INTEGER, Date TEXT,
            Type TEXT, Notes TEXT, Cost REAL,
            FOREIGN KEY(AssetID) REFERENCES Assets(AssetID) ON DELETE CASCADE
        );
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS AssetAttachments (
            AttachmentID INTEGER PRIMARY KEY AUTOINCREMENT, AssetID INTEGER, FileName TEXT,
            StoredPath TEXT, UploadDate TEXT,
            FOREIGN KEY(AssetID) REFERENCES Assets(AssetID) ON DELETE CASCADE
        );
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS AssetRelationships (
            ParentAssetID INTEGER, ChildAssetID INTEGER,
            PRIMARY KEY (ParentAssetID, ChildAssetID),
            FOREIGN KEY(ParentAssetID) REFERENCES Assets(AssetID) ON DELETE CASCADE,
            FOREIGN KEY(ChildAssetID) REFERENCES Assets(AssetID) ON DELETE CASCADE
        );
    ''')
    cursor.execute("CREATE TABLE IF NOT EXISTS Settings (SettingKey TEXT PRIMARY KEY, SettingValue TEXT);")
    cursor.execute("CREATE TABLE IF NOT EXISTS Tags (TagID INTEGER PRIMARY KEY AUTOINCREMENT, TagName TEXT UNIQUE);")
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS AssetTags (
            AssetID INTEGER, TagID INTEGER,
            PRIMARY KEY (AssetID, TagID),
            FOREIGN KEY(AssetID) REFERENCES Assets(AssetID) ON DELETE CASCADE,
            FOREIGN KEY(TagID) REFERENCES Tags(TagID) ON DELETE CASCADE
        );
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS CustomFields (
            FieldID INTEGER PRIMARY KEY AUTOINCREMENT, AssetID INTEGER, FieldName TEXT, FieldValue TEXT,
            FOREIGN KEY(AssetID) REFERENCES Assets(AssetID) ON DELETE CASCADE
        );
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS Racks (
            RackID INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, Location TEXT, UHeight INTEGER
        );
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS Vendors (
            VendorID INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, Website TEXT, SupportContact TEXT
        );
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS SoftwareLicenses (
            LicenseID INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, LicenseKey TEXT,
            PurchaseDate TEXT, ExpiryDate TEXT, Seats INTEGER, VendorID INTEGER,
            FOREIGN KEY(VendorID) REFERENCES Vendors(VendorID) ON DELETE SET NULL
        );
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS AssetSoftware (
            AssetID INTEGER, LicenseID INTEGER,
            PRIMARY KEY (AssetID, LicenseID),
            FOREIGN KEY(AssetID) REFERENCES Assets(AssetID) ON DELETE CASCADE,
            FOREIGN KEY(LicenseID) REFERENCES SoftwareLicenses(LicenseID) ON DELETE CASCADE
        );
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS Subnets (
            SubnetID INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT, NetworkAddress TEXT NOT NULL, VlanID INTEGER
        );
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS IPAddresses (
            IPAddressID INTEGER PRIMARY KEY AUTOINCREMENT, Address TEXT NOT NULL UNIQUE, SubnetID INTEGER,
            AssetID INTEGER, Notes TEXT,
            FOREIGN KEY(SubnetID) REFERENCES Subnets(SubnetID) ON DELETE CASCADE,
            FOREIGN KEY(AssetID) REFERENCES Assets(AssetID) ON DELETE SET NULL
        );
    ''')
    
    # --- SCHEMA MIGRATION LOGIC ---
    # Get all columns for a given table
    def get_columns(cursor, table_name):
        return [info['name'] for info in cursor.execute(f"PRAGMA table_info({table_name})").fetchall()]

    # Assets table migration
    asset_columns = get_columns(cursor, 'Assets')
    required_asset_columns = {
        "Manufacturer": "TEXT", "Model": "TEXT", "SerialNumber": "TEXT", "Location": "TEXT", 
        "ImagePath": "TEXT", "CheckedOutTo": "TEXT", "WarrantyEndDate": "TEXT", 
        "NextMaintenanceDate": "TEXT", "DisposalDate": "TEXT", "DisposalMethod": "TEXT", 
        "IsArchived": "INTEGER DEFAULT 0", "AssetType": "TEXT DEFAULT 'Physical'",
        "HostID": "INTEGER", "RackID": "INTEGER", "RackUnit": "INTEGER"
    }
    for col, col_type in required_asset_columns.items():
        if col not in asset_columns:
            print(f"Schema migration: Adding column '{col}' to Assets table.")
            cursor.execute(f"ALTER TABLE Assets ADD COLUMN {col} {col_type}")
    
    # Tags table migration (FIX for TagColor)
    tag_columns = get_columns(cursor, 'Tags')
    if 'TagColor' not in tag_columns:
        print("Schema migration: Adding column 'TagColor' to Tags table.")
        cursor.execute("ALTER TABLE Tags ADD COLUMN TagColor TEXT")

    conn.commit()

    # Default settings
    default_settings = {
        'theme': 'royale',
        'items_per_page': '25',
        'asset_prefix': 'VTR',
        'default_checkout_user': ''
    }
    for key, value in default_settings.items():
        cursor.execute("INSERT OR IGNORE INTO Settings (SettingKey, SettingValue) VALUES (?, ?)", (key, value))
    
    conn.commit()
    conn.close()

def log_asset(conn, asset_id, user, action, notes=''):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    conn.execute("INSERT INTO Logs (AssetID, Timestamp, User, Action, Notes) VALUES (?, ?, ?, ?, ?)", (asset_id, timestamp, user, action, notes))

def get_local_ip_and_subnet():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        ip = s.getsockname()[0]
        # A common assumption for home/small networks; might not always be right
        subnet = '.'.join(ip.split('.')[:3]) + '.0/24' 
    except Exception:
        ip = '127.0.0.1'
        subnet = '127.0.0.1/32'
    finally:
        s.close()
    return ip, subnet

# --- OUI LOOKUP FUNCTIONS ---
_oui_cache = {}
def parse_oui_file():
    global _oui_cache
    if not os.path.exists(OUI_FILE_PATH): return
    try:
        with open(OUI_FILE_PATH, 'r', encoding='utf-8') as f:
            for line in f:
                if "(hex)" in line:
                    parts = line.split('(hex)')
                    mac_prefix = parts[0].strip().replace('-', '').upper()
                    vendor = parts[1].strip()
                    _oui_cache[mac_prefix] = vendor
        print(f"Loaded {len(_oui_cache)} OUI entries from local file.")
    except Exception as e:
        print(f"Error parsing OUI file: {e}")

def get_vendor_from_mac(mac_address):
    if not _oui_cache: parse_oui_file()
    if not mac_address: return "Unknown"
    mac_prefix = mac_address.replace(':', '').replace('-', '').upper()[:6]
    return _oui_cache.get(mac_prefix, "Unknown")


# --- HTML TEMPLATES ---
def render_template(title, content, show_utils_button=True, local_ip_info=''):
    conn = get_db_connection()
    settings = {row['SettingKey']: row['SettingValue'] for row in conn.execute("SELECT * FROM Settings").fetchall()}
    conn.close()
    theme = settings.get('theme', 'royale')

    theme_css = {
        'royale': "background: linear-gradient(to bottom, #76B4F7, #2872C4);",
        'olive': "background: linear-gradient(to bottom, #d2d8b4, #7f8849);",
        'silver': "background: linear-gradient(to bottom, #f0f1f5, #b4b5b9);",
        'dark': "background: linear-gradient(to bottom, #4a5568, #2d3748);",
        'vista': "background: linear-gradient(to bottom, rgba(132,162,249,1) 0%, rgba(81,123,232,1) 42%, rgba(44,83,176,1) 100%);",
        'classic': "background: #0A246A;",
        'terminal': "background: linear-gradient(to bottom, #282a36, #191a21);",
        'cacao': "background: linear-gradient(to bottom, #5a3e36, #3c2a21);"
    }
    
    full_theme_css = f'''
    <style id="full-theme-styles">
        /* Base styles for all themes */
        a.button, button {{
            font-family: Tahoma, Verdana, sans-serif; font-size: 8pt;
            background: linear-gradient(to bottom, #FEFEFE, #D1D1D1); border: 1px solid #003C74;
            border-radius: 4px; padding: 4px 12px; text-decoration: none; color: black; cursor: pointer;
            box-shadow: 0 2px 5px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.4);
            text-shadow: 0 1px 0 rgba(255,255,255,0.5); transition: all 0.1s ease-in-out;
            height: 25px; box-sizing: border-box; display: inline-flex; align-items: center; justify-content: center;
        }}
        a.button:hover, button:hover {{ background: linear-gradient(to bottom, #FFFFFF, #E1E1E1); box-shadow: 0 3px 6px rgba(0,0,0,0.3), inset 0 1px 0 rgba(255,255,255,0.5); }}
        a.button:active, button:active {{ background: linear-gradient(to top, #FEFEFE, #D1D1D1); box-shadow: inset 0 2px 4px rgba(0,0,0,0.3), 0 1px 0 rgba(255,255,255,1); transform: translateY(1px); }}
        .pagination a {{ text-decoration: none; padding: 5px 10px; border: 1px solid #ACA899; margin: 0 2px; }}
        .pagination a.disabled {{ color: #ccc; pointer-events: none; }}
        .pagination strong {{ padding: 5px 10px; background-color: #D4D0C8; border: 1px solid #ACA899; }}
        
        /* Royale Blue Theme (Default) */
        html[data-theme="royale"] body, html[data-theme="royale"] .container, html[data-theme="royale"] .modal-content {{ background-color: #ECE9D8; }}
        html[data-theme="royale"] h2, html[data-theme="royale"] h3, html[data-theme="royale"] .stat-item h3 {{ color: #003C74; }}
        html[data-theme="royale"] a {{ color: #003C74; }}
        html[data-theme="royale"] th, html[data-theme="royale"] .filter-panel, html[data-theme="royale"] .dashboard-stats, html[data-theme="royale"] .ip-info {{ background-color: #D4D0C8; }}
        html[data-theme="royale"] .tab-link {{ background-color: #D4D0C8; }}
        html[data-theme="royale"] .tab-link.active {{ background-color: #ECE9D8; }}

        /* Olive Green Theme */
        html[data-theme="olive"] body, html[data-theme="olive"] .container, html[data-theme="olive"] .modal-content {{ background-color: #f4f2e8; color: #3f472a; }}
        html[data-theme="olive"] header {{ background: linear-gradient(to bottom, #d2d8b4, #7f8849); border-color: #7f8849; }}
        html[data-theme="olive"] h2, html[data-theme="olive"] h3, html[data-theme="olive"] .stat-item h3 {{ color: #5d653a; border-color: #c2c8a1; }}
        html[data-theme="olive"] a {{ color: #5d653a; }}
        html[data-theme="olive"] table, html[data-theme="olive"] td, html[data-theme="olive"] th, html[data-theme="olive"] .container {{ border-color: #c2c8a1; }}
        html[data-theme="olive"] th, html[data-theme="olive"] .filter-panel, html[data-theme="olive"] .dashboard-stats, html[data-theme="olive"] .ip-info {{ background-color: #e4e2d8; }}
        html[data-theme="olive"] tr:nth-of-type(even) {{ background-color: #f9f8f2; }}
        html[data-theme="olive"] .tab-link {{ background-color: #e4e2d8; border-color: #c2c8a1; }}
        html[data-theme="olive"] .tab-link.active {{ background-color: #f4f2e8; border-bottom-color: #f4f2e8; }}
        html[data-theme="olive"] a.button, html[data-theme="olive"] button {{ border-color: #7f8849; }}
        
        /* Silver Theme */
        html[data-theme="silver"] body, html[data-theme="silver"] .container, html[data-theme="silver"] .modal-content {{ background-color: #eceef3; color: #4c4c63; }}
        html[data-theme="silver"] header {{ background: linear-gradient(to bottom, #f0f1f5, #b4b5b9); border-color: #9090a8; }}
        html[data-theme="silver"] h2, html[data-theme="silver"] h3, html[data-theme="silver"] .stat-item h3 {{ color: #606078; border-color: #c5c5d2; }}
        html[data-theme="silver"] a {{ color: #606078; }}
        html[data-theme="silver"] table, html[data-theme="silver"] td, html[data-theme="silver"] th, html[data-theme="silver"] .container {{ border-color: #c5c5d2; }}
        html[data-theme="silver"] th, html[data-theme="silver"] .filter-panel, html[data-theme="silver"] .dashboard-stats, html[data-theme="silver"] .ip-info {{ background-color: #d5d5e2; }}
        html[data-theme="silver"] tr:nth-of-type(even) {{ background-color: #f8f8fa; }}
        html[data-theme="silver"] .tab-link {{ background-color: #d5d5e2; border-color: #c5c5d2; }}
        html[data-theme="silver"] .tab-link.active {{ background-color: #eceef3; border-bottom-color: #eceef3; }}
        html[data-theme="silver"] a.button, html[data-theme="silver"] button {{ border-color: #9090a8; }}

        /* Dark Mode Theme */
        html[data-theme="dark"] body {{ background-color: #2d3748; color: #e2e8f0; }}
        html[data-theme="dark"] .container, html[data-theme="dark"] .modal-content {{ background-color: #4a5568; border-color: #718096; }}
        html[data-theme="dark"] header {{ background: linear-gradient(to bottom, #4a5568, #2d3748); }}
        html[data-theme="dark"] h2, html[data-theme="dark"] h3, html[data-theme="dark"] a, html[data-theme="dark"] .stat-item h3 {{ color: #90cdf4; border-color: #718096; }}
        html[data-theme="dark"] th, html[data-theme="dark"] .filter-panel, html[data-theme="dark"] .dashboard-stats, html[data-theme="dark"] .ip-info {{ background-color: #2d3748; }}
        html[data-theme="dark"] tr:nth-of-type(even) {{ background-color: #4a5568; }}
        html[data-theme="dark"] td, html[data-theme="dark"] th, html[data-theme="dark"] table, html[data-theme="dark"] .filter-panel {{ border-color: #718096; }}
        html[data-theme="dark"] input, html[data-theme="dark"] textarea, html[data-theme="dark"] select {{ background-color: #2d3748; color: #e2e8f0; border-color: #718096; }}
        html[data-theme="dark"] .tab-link {{ background-color: #2d3748; border-color: #718096; }}
        html[data-theme="dark"] .tab-link.active {{ background-color: #4a5568; border-bottom-color: #4a5568; }}
        html[data-theme="dark"] .tab-content {{ background-color: #2d3748; }}
        html[data-theme="dark"] a.button, html[data-theme="dark"] button {{ background: linear-gradient(to bottom, #718096, #4a5568); border-color: #a0aec0; color: #e2e8f0; text-shadow: none;}}
        html[data-theme="dark"] a.button:hover, html[data-theme="dark"] button:hover {{ background: linear-gradient(to bottom, #a0aec0, #718096); }}
        html[data-theme="dark"] .pagination a, html[data-theme="dark"] .pagination strong {{ border-color: #718096; }}
        html[data-theme="dark"] .pagination strong {{ background-color: #2d3748; }}

        /* Vista Theme */
        html[data-theme="vista"] body {{ background-color: #d1dff1; font-family: "Segoe UI", Calibri, "Myriad Pro", "Myriad", "Helvetica Neue", Helvetica, Arial, sans-serif; }}
        html[data-theme="vista"] .container, html[data-theme="vista"] .modal-content {{ background-color: #f0f0f0; border: 1px solid #707070; box-shadow: 0 4px 12px rgba(0,0,0,0.3); border-radius: 8px; }}
        html[data-theme="vista"] header {{ background: linear-gradient(to bottom, rgba(132,162,249,0.8) 0%, rgba(81,123,232,0.8) 42%, rgba(44,83,176,0.8) 100%); border-radius: 8px 8px 0 0; backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px); border-bottom: 1px solid rgba(0,0,0,0.3); }}
        html[data-theme="vista"] h2, html[data-theme="vista"] h3 {{ color: #003399; font-weight: 600; }}
        html[data-theme="vista"] a {{ color: #003399; }}
        html[data-theme="vista"] th {{ background-color: #e3eefc; }}
        html[data-theme="vista"] a.button, html[data-theme="vista"] button {{ background: linear-gradient(to bottom, #f5faff, #e3eefc); border: 1px solid #7da2ce; border-radius: 4px; box-shadow: 0 1px 1px rgba(0,0,0,0.1); text-shadow: none; color: #333; }}
        html[data-theme="vista"] a.button:hover, html[data-theme="vista"] button:hover {{ border-color: #3399ff; background: linear-gradient(to bottom, #ffffff, #ebf3fc); }}

        /* Classic Theme */
        html[data-theme="classic"] body, html[data-theme="classic"] .container, html[data-theme="classic"] .modal-content {{ background-color: #C0C0C0; color: #000; font-family: "MS Sans Serif", "Tahoma", "Geneva", "sans-serif"; }}
        html[data-theme="classic"] .container {{ border: 2px outset #fff; box-shadow: none; }}
        html[data-theme="classic"] header {{ background: #0A246A; padding: 2px 4px; }}
        html[data-theme="classic"] h2, html[data-theme="classic"] h3, html[data-theme="classic"] th {{ color: #000; }}
        html[data-theme="classic"] th {{ background: #c0c0c0; border: 1px solid; border-color: #fff #808080 #808080 #fff;}}
        html[data-theme="classic"] table, html[data-theme="classic"] td {{ border: 1px solid #808080; }}
        html[data-theme="classic"] a.button, html[data-theme="classic"] button {{ background: #c0c0c0; border: 2px outset #fff; border-radius: 0; box-shadow: none; text-shadow: none; height: 28px; padding: 2px 8px; }}
        html[data-theme="classic"] a.button:active, html[data-theme="classic"] button:active {{ border-style: inset; }}

        /* Terminal Theme */
        html[data-theme="terminal"] body {{ background-color: #1a1a1a; color: #00ff41; font-family: 'Consolas', 'Monaco', 'Lucida Console', 'monospace'; }}
        html[data-theme="terminal"] .container, html[data-theme="terminal"] .modal-content {{ background-color: #000; border: 1px solid #00ff41; }}
        html[data-theme="terminal"] header {{ background: #000; border-bottom: 1px solid #00ff41; }}
        html[data-theme="terminal"] h1, html[data-theme="terminal"] h2, html[data-theme="terminal"] h3, html[data-theme="terminal"] a {{ color: #00ff41; }}
        html[data-theme="terminal"] th, html[data-theme="terminal"] .filter-panel, html[data-theme="terminal"] .dashboard-stats, html[data-theme="terminal"] .ip-info {{ background-color: #111; }}
        html[data-theme="terminal"] input, html[data-theme="terminal"] textarea, html[data-theme="terminal"] select {{ background-color: #111; color: #00ff41; border: 1px solid #00ff41; }}
        html[data-theme="terminal"] a.button, html[data-theme="terminal"] button {{ background: #000; border: 1px solid #00ff41; color: #00ff41; border-radius: 0; text-shadow: none; }}

        /* Cacao Theme */
        html[data-theme="cacao"] body {{ background-color: #D6C7AE; color: #3C2A21; }}
        html[data-theme="cacao"] .container, html[data-theme="cacao"] .modal-content {{ background-color: #F5E8C7; border-color: #8D7B68; }}
        html[data-theme="cacao"] header {{ background: linear-gradient(to bottom, #5a3e36, #3c2a21); }}
        html[data-theme="cacao"] h2, html[data-theme="cacao"] h3, html[data-theme="cacao"] a {{ color: #5a3e36; }}
        html[data-theme="cacao"] th {{ background-color: #EAE0C8; }}
        html[data-theme="cacao"] a.button, html[data-theme="cacao"] button {{ background: #DEB6AB; border: 1px solid #8D7B68; color: #3C2A21; }}
    </style>
    '''

    utils_button_html = '<a href="/utils" class="button">Utilities</a>' if show_utils_button else ''
    return f'''
    <!DOCTYPE html>
    <html lang="en" data-theme="{theme}">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>EliteSoftware - {title}</title>
        <link rel="icon" href="/favicon.ico?v={datetime.datetime.now().timestamp()}" type="image/x-icon">
        <link rel="manifest" href="/manifest.json">
        {full_theme_css}
        <style>
            body {{ font-family: Tahoma, Verdana, sans-serif; font-size: 8pt; margin: 0; padding: 10px; }}
            .container {{ border: 1px solid #003C74; box-shadow: 0 0 10px rgba(0,0,0,0.5); }}
            header {{
                {theme_css.get(theme, theme_css['royale'])}
                color: white; padding: 3px 10px; display: flex; justify-content: space-between; align-items: center;
                border-bottom: 1px solid #003C74; font-family: "Franklin Gothic Medium", "Arial Narrow", Arial, sans-serif;
            }}
            header h1 {{ font-size: 11pt; margin: 0; font-weight: normal; text-shadow: 1px 1px 1px #000; }}
            header h1 a {{ color: white; text-decoration: none; }}
            main {{ padding: 15px; }}
            h2 {{ border-bottom: 1px solid #ACA899; padding-bottom: 5px; font-size: 12pt; }}
            h3 {{ border-bottom: 1px solid #ACA899; padding-bottom: 3px; font-size: 10pt; margin-top: 20px;}}
            table {{ width: 100%; border-collapse: collapse; margin-top: 15px; border: 1px solid #ACA899; }}
            th, td {{ padding: 6px; border: 1px solid #D4D0C8; text-align: left; vertical-align: middle; }}
            form {{ display: grid; grid-template-columns: 150px 1fr; gap: 8px; align-items: center; margin-top: 15px; }}
            form.inline-form {{ display: inline; grid-template-columns: none; }}
            form label {{ text-align: right; }}
            form input, form textarea, form select {{
                width: 100%; padding: 3px; border: 1px solid #7F9DB9; box-sizing: border-box;
            }}
            form .form-actions {{ grid-column: 2; text-align: left; padding-top: 10px; }}
            .asset-details-grid {{ display: grid; grid-template-columns: 250px 1fr; gap: 20px; }}
            .ip-info {{ display: flex; justify-content: center; align-items: center; gap: 15px; text-align: center; padding: 10px; border-top: 1px solid #ACA899; font-size: 8pt; }}
            .dashboard-stats {{ display: flex; flex-wrap: wrap; justify-content: space-around; padding: 10px; border: 1px solid #ACA899; margin-bottom: 15px; }}
            .stat-item {{ text-align: center; padding: 5px 10px; }}
            .stat-item h3 {{ margin: 0 0 5px 0; font-size: 9pt; border: none; }}
            .stat-item p {{ margin: 0; font-size: 12pt; font-weight: bold; }}
            .modal {{ display: none; position: fixed; z-index: 100; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.4); }}
            .modal-content {{ margin: 10% auto; padding: 20px; border: 1px solid #003C74; width: 80%; max-width: 500px; box-shadow: 0 0 10px rgba(0,0,0,0.5); }}
            .barcode-container {{ display: flex; align-items: flex-start; gap: 10px; margin-top: 10px; }}
            .barcode-item {{ flex: 2; background: white; padding: 5px; border: 1px solid #7F9DB9; }}
            .qrcode-item {{ flex: 1; max-width: 90px; background: white; padding: 5px; border: 1px solid #7F9DB9; }}
            .barcode-container img {{ max-width: 100%; height: auto; display: block; }}
            .tabs {{ display: flex; border-bottom: 1px solid #ACA899; margin-top: 20px; }}
            .tab-link {{ padding: 8px 12px; cursor: pointer; border: 1px solid #ACA899; border-bottom: none; margin-bottom: -1px; border-radius: 4px 4px 0 0; }}
            .tab-link.active {{ font-weight: bold; border-bottom: 1px solid;}}
            .tab-content {{ display: none; padding: 15px; border: 1px solid #ACA899; border-top: none; }}
            .tab-content.active {{ display: block; }}
            .filter-panel {{ border: 1px solid #ACA899; padding: 10px; margin-bottom: 15px; }}
            .filter-panel details summary {{ cursor: pointer; font-weight: bold; }}
            .filter-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; margin-top: 10px; }}
            .dashboard-actions {{ margin-bottom:15px; display:flex; flex-wrap:wrap; align-items:center; gap:10px; justify-content: space-between; }}
            .dashboard-actions .bulk-group {{ display:flex; align-items:center; gap:5px; }}
            .kiosk-container {{ text-align: center; max-width: 600px; margin: auto; }}
            .kiosk-input-wrapper {{ display: flex; align-items: center; justify-content: center; gap: 5px; margin-bottom: 20px; }}
            .kiosk-input {{ font-size: 16pt; padding: 10px; width: 80%; text-align: center; }}
            #kiosk-result {{ min-height: 100px; border: 1px solid #ACA899; padding: 20px; }}
            #scanner-container {{ width: 100%; max-width: 500px; margin: 10px auto; border: 1px solid #ACA899; display: none; }}
            .icon-history-grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(80px, 1fr)); gap: 10px; }}
            .icon-history-item {{ border: 1px solid #ACA899; padding: 5px; text-align: center; }}
            .icon-history-item img {{ width: 32px; height: 32px; margin-bottom: 5px; }}
            .pagination {{ margin-top: 15px; text-align: center; }}
        </style>
    </head>
    <body>
        <div class="container">
            <header>
                <h1><a href="/">Elite Asset Management Suite</a></h1>
                <div>
                    <a href="/logistics" class="button">Logistics</a>
                    {utils_button_html}
                    <a href="/kiosk" class="button">Kiosk Mode</a>
                    <a href="/scan" class="button">Scan & Lookup</a>
                    <a href="/settings" class="button">&#9881;</a>
                </div>
            </header>
            <main>{content}</main>
            {local_ip_info}
        </div>
        <script>
            // PWA Service Worker Registration
            if ('serviceWorker' in navigator) {{
                navigator.serviceWorker.register('/sw.js').then(function(registration) {{
                    console.log('Service Worker registered with scope:', registration.scope);
                }}).catch(function(error) {{
                    console.log('Service Worker registration failed:', error);
                }});
            }}

            function switchTab(evt, tabName) {{
                var i, tabcontent, tablinks;
                tabcontent = document.getElementsByClassName("tab-content");
                for (i = 0; i < tabcontent.length; i++) {{
                    tabcontent[i].style.display = "none";
                }}
                tablinks = document.getElementsByClassName("tab-link");
                for (i = 0; i < tablinks.length; i++) {{
                    tablinks[i].className = tablinks[i].className.replace(" active", "");
                }}
                document.getElementById(tabName).style.display = "block";
                evt.currentTarget.className += " active";
            }}
            document.addEventListener("DOMContentLoaded", function() {{
                if(document.querySelector('.tab-link')){{
                    document.querySelector('.tab-link').click();
                }}
            }});
        </script>
    </body>
    </html>
    '''

# --- WEB REQUEST HANDLER ---
class WebRequestHandler(BaseHTTPRequestHandler):
    def send_html_response(self, code, content):
        self.send_response(code)
        self.send_header("Content-type", "text/html; charset=utf-8"); self.end_headers()
        self.wfile.write(bytes(content, "utf-8"))

    def parse_post_data(self):
        ctype = self.headers.get('Content-Type')
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)
        
        form_data = {}
        file_data = {}

        if 'multipart/form-data' in ctype:
            boundary_match = re.search(r'boundary=([^;]+)', ctype)
            if not boundary_match: return {}, {}
            boundary = b'--' + boundary_match.group(1).encode('utf-8')
            
            parts = body.split(boundary)
            for part in parts:
                if not part.strip() or part == b'--\r\n': continue
                try:
                    headers_raw, content = part.split(b'\r\n\r\n', 1)
                except ValueError: continue
                
                content = content.rstrip(b'\r\n--')
                headers_str = headers_raw.decode('utf-8', errors='ignore')
                
                name_match = re.search(r'name="([^"]+)"', headers_str, re.IGNORECASE)
                if not name_match: continue
                name = name_match.group(1)

                filename_match = re.search(r'filename="([^"]+)"', headers_str, re.IGNORECASE)
                if filename_match:
                    filename = filename_match.group(1)
                    if not filename: continue # Skip empty file uploads
                    file_data[name] = {'filename': filename, 'content': content}
                else:
                    form_data[name] = content.decode('utf-8', errors='ignore')
        elif 'application/x-www-form-urlencoded' in ctype:
            parsed_qs = parse_qs(body.decode('utf-8'))
            form_data = {k: v[0] if len(v) == 1 else v for k, v in parsed_qs.items()}

        return form_data, file_data

    def do_GET(self):
        try:
            path = urlparse(self.path).path
            if path == '/': self.serve_home_page()
            elif path == '/favicon.ico': self.serve_favicon()
            elif path == '/manifest.json': self.serve_manifest()
            elif path == '/sw.js': self.serve_service_worker()
            elif path.startswith('/icons/'): self.serve_historical_icon(path.split('/')[-1])
            elif path == '/new': self.serve_add_edit_form()
            elif path.startswith('/edit/'): self.serve_add_edit_form(int(path.split('/')[-1]))
            elif path.startswith('/history/'): self.serve_history_page(int(path.split('/')[-1]))
            elif path.startswith('/barcode/'): self.serve_barcode_svg(path.split('/')[-1].replace('.svg',''))
            elif path.startswith('/qrcode/'): self.serve_qrcode_png(path.split('/')[-1].replace('.png',''))
            elif path == '/utils': self.serve_utils_page()
            elif path == '/scan': self.serve_scan_page()
            elif path.startswith('/attachments/'): self.serve_attachment(int(path.split('/')[-1]))
            elif path == '/api/search': self.handle_api_search()
            elif path == '/export/csv': self.handle_export_csv()
            elif path == '/settings': self.serve_settings_page()
            elif path == '/kiosk': self.serve_kiosk_page()
            elif path == '/archived': self.serve_archived_page()
            elif path == '/backup': self.handle_backup()
            elif path == '/api/network_qr.png': self.serve_network_qr()
            elif path == '/print_labels': self.serve_print_labels_page()
            # Logistics Routes
            elif path == '/logistics': self.serve_logistics_dashboard()
            elif path == '/logistics/ipam': self.serve_ipam_page()
            elif path == '/logistics/ipam/scan': self.serve_ipam_scan_page()
            elif path == '/logistics/software': self.serve_software_page()
            elif path == '/logistics/racks': self.serve_racks_page()
            elif path == '/logistics/vendors': self.serve_vendors_page()
            elif path == '/logistics/tags': self.serve_tags_page()
            else: self.send_error(404, "Not Found")
        except Exception as e:
            print(f"Error in do_GET for path {self.path}: {e}")
            import traceback
            traceback.print_exc()
            self.send_error(500, f"Server error: {e}")

    def do_POST(self):
        try:
            path = urlparse(self.path).path
            if path == '/save': self.handle_save()
            elif path == '/upload_favicon': self.handle_upload_favicon()
            elif path == '/set_active_favicon': self.handle_set_active_favicon()
            elif path.startswith('/delete/'): self.handle_delete(int(path.split('/')[-1]))
            elif path.startswith('/checkout/'): self.handle_check_in_out(int(path.split('/')[-1]), 'out')
            elif path.startswith('/checkin/'): self.handle_check_in_out(int(path.split('/')[-1]), 'in')
            elif path == '/import/csv': self.handle_import_csv()
            elif path == '/save_settings': self.handle_save_settings()
            elif path.startswith('/archive/'): self.handle_archive(int(path.split('/')[-1]))
            elif path.startswith('/restore_asset/'): self.handle_restore_asset(int(path.split('/')[-1]))
            elif path == '/bulk_action': self.handle_bulk_action()
            elif path == '/restore_backup': self.handle_restore_backup()
            elif path.startswith('/add_maintenance/'): self.handle_add_maintenance(int(path.split('/')[-1]))
            elif path.startswith('/delete_maintenance/'): self.handle_delete_maintenance(int(path.split('/')[-1]))
            elif path.startswith('/add_attachment/'): self.handle_add_attachment(int(path.split('/')[-1]))
            elif path.startswith('/delete_attachment/'): self.handle_delete_attachment(int(path.split('/')[-1]))
            elif path.startswith('/assign_software/'): self.handle_assign_software(int(path.split('/')[-1]))
            elif path.startswith('/unassign_software/'): self.handle_unassign_software(int(path.split('/')[-1]))
            elif path.startswith('/assign_tag/'): self.handle_assign_tag(int(path.split('/')[-1]))
            elif path.startswith('/unassign_tag/'): self.handle_unassign_tag(int(path.split('/')[-1]))
            # Logistics POST Handlers
            elif path == '/print_labels': self.serve_print_labels_page()
            elif path == '/logistics/ipam/add_subnet': self.handle_add_subnet()
            elif path == '/logistics/ipam/add_ip': self.handle_add_ip()
            elif path == '/logistics/software/add': self.handle_add_software()
            elif path == '/logistics/racks/add': self.handle_add_rack()
            elif path == '/logistics/racks/assign': self.handle_assign_rack()
            elif path == '/logistics/vendors/add': self.handle_add_vendor()
            elif path == '/logistics/tags/add': self.handle_add_tag()
            elif path.startswith('/add_custom_field/'): self.handle_add_custom_field(int(path.split('/')[-1]))
            elif path.startswith('/delete_custom_field/'): self.handle_delete_custom_field(int(path.split('/')[-1]))
            else: self.send_error(404, "Not Found")
        except Exception as e:
            print(f"Error in do_POST for path {self.path}: {e}")
            import traceback
            traceback.print_exc()
            self.send_error(500, f"Server error: {e}")

    # --- PAGE SERVING METHODS ---

    def serve_home_page(self):
        query_params = parse_qs(urlparse(self.path).query)
        filters = {
            'category': query_params.get('category', [''])[0],
            'status': query_params.get('status', [''])[0],
            'location': query_params.get('location', [''])[0],
            'search': query_params.get('search', [''])[0]
        }
        
        conn = get_db_connection()
        settings = {row['SettingKey']: row['SettingValue'] for row in conn.execute("SELECT * FROM Settings").fetchall()}
        
        # Pagination
        items_per_page = int(settings.get('items_per_page', 25))
        try:
            page = int(query_params.get('page', ['1'])[0])
        except (ValueError, IndexError):
            page = 1
        
        # Build query
        sql_base = "FROM Assets WHERE IsArchived = 0"
        sql_where = ""
        params = []
        if filters['category']: sql_where += " AND Category = ?"; params.append(filters['category'])
        if filters['status']: sql_where += " AND Status = ?"; params.append(filters['status'])
        if filters['location']: sql_where += " AND Location = ?"; params.append(filters['location'])
        if filters['search']:
            sql_where += " AND (AssetNumber LIKE ? OR Name LIKE ? OR SerialNumber LIKE ? OR Model LIKE ?)"
            search_term = f"%{filters['search']}%"
            params.extend([search_term, search_term, search_term, search_term])
        
        # Get total count for pagination
        count_sql = f"SELECT COUNT(*) as total {sql_base} {sql_where.replace(' AND', ' AND', 1) if sql_where.startswith(' AND') else sql_where.replace(' AND', 'WHERE', 1)}"
        total_items = conn.execute(count_sql, tuple(params)).fetchone()['total']
        total_pages = math.ceil(total_items / items_per_page)
        offset = (page - 1) * items_per_page
        
        # Get assets for the current page
        sql = f"SELECT * {sql_base} {sql_where.replace(' AND', ' AND', 1) if sql_where.startswith(' AND') else sql_where.replace(' AND', 'WHERE', 1)} ORDER BY AssetNumber LIMIT ? OFFSET ?"
        params.extend([items_per_page, offset])
        assets = conn.execute(sql, tuple(params)).fetchall()

        stats = conn.execute("SELECT COUNT(AssetID) as TotalCount, SUM(Cost) as TotalValue, Status FROM Assets WHERE IsArchived = 0 GROUP BY Status").fetchall()
        
        categories = conn.execute("SELECT DISTINCT Category FROM Assets WHERE IsArchived = 0 AND Category IS NOT NULL ORDER BY Category").fetchall()
        locations = conn.execute("SELECT DISTINCT Location FROM Assets WHERE IsArchived = 0 AND Location IS NOT NULL ORDER BY Location").fetchall()
        conn.close()
        
        total_count = sum(s['TotalCount'] for s in stats)
        total_value = sum(s['TotalValue'] for s in stats if s['TotalValue'])
        status_counts = {s['Status']: s['TotalCount'] for s in stats}
        checked_in = status_counts.get('Checked In', 0)
        checked_out = status_counts.get('Checked Out', 0)
        
        dashboard_html = f'''
        <div class="dashboard-stats">
            <div class="stat-item"><h3>Total Assets</h3><p>{total_count}</p></div>
            <div class="stat-item"><h3>Total Value</h3><p>${total_value:,.2f}</p></div>
            <div class="stat-item"><h3>Checked In</h3><p style="color:#008000;">{checked_in}</p></div>
            <div class="stat-item"><h3>Checked Out</h3><p style="color:#C00000;">{checked_out}</p></div>
        </div>
        '''
        
        rows_html = "".join(
            f"""<tr>
                <td><input type="checkbox" name="asset_ids" value="{asset['AssetID']}"></td>
                <td><a href="/edit/{asset['AssetID']}">{asset['AssetNumber']}</a></td>
                <td>{asset['Name']}</td><td>{asset['Category'] or ''}</td>
                <td style="color:{'#008000' if asset['Status'] == 'Checked In' else '#C00000'}; font-weight:bold;">{asset['Status']}</td>
                <td>{asset['Location'] or ''}</td>
            </tr>""" for asset in assets)
        
        # Pagination HTML
        pagination_html = ""
        if total_pages > 1:
            pagination_html += '<div class="pagination">'
            # Build query string for links
            query_string = urlparse(self.path).query
            base_url = f"/?{re.sub(r'&?page=\d+', '', query_string)}".rstrip('?&')
            
            prev_disabled = "class='disabled'" if page <= 1 else ""
            pagination_html += f'<a href="{base_url}&page={page - 1}" {prev_disabled}>&laquo; Prev</a>'
            
            pagination_html += f'<span> Page <strong>{page}</strong> of <strong>{total_pages}</strong> </span>'
            
            next_disabled = "class='disabled'" if page >= total_pages else ""
            pagination_html += f'<a href="{base_url}&page={page + 1}" {next_disabled}>Next &raquo;</a>'
            pagination_html += '</div>'

        local_ip, _ = get_local_ip_and_subnet()
        ip_info = f'<div class="ip-info"><span>Network Access: http://{local_ip}:{self.server.server_port}</span><img src="/api/network_qr.png" style="width:60px; height:60px; vertical-align:middle; margin-left:10px;"></div>'
        content = f"""
        <h2>Asset Dashboard</h2>
        {dashboard_html}
        <form method="POST" action="/bulk_action" style="display:block; grid-template-columns:none;">
            <div class="dashboard-actions">
                <a href="/new" class="button">Add New Asset</a>
                <div class="bulk-group">
                    <select name="action">
                        <option value="archive">Archive Selected</option>
                        <option value="checkout">Check Out Selected</option>
                        <option value="checkin">Check In Selected</option>
                    </select>
                    <button type="submit">Apply</button>
                </div>
            </div>

            <div class="filter-panel">
                <details>
                    <summary>Filter & Search</summary>
                    <div class="filter-grid">
                        <div>
                            <label for="search" style="text-align:left;display:block;">Search</label>
                            <input type="text" name="search" id="search" value="{filters['search']}">
                        </div>
                        <div>
                            <label for="category" style="text-align:left;display:block;">Category</label>
                            <select name="category" id="category"><option value="">All</option>
                                {''.join(f"<option value='{c['Category']}' {'selected' if c['Category'] == filters['category'] else ''}>{c['Category']}</option>" for c in categories)}
                            </select>
                        </div>
                        <div>
                            <label for="status" style="text-align:left;display:block;">Status</label>
                            <select name="status" id="status"><option value="">All</option>
                                <option value="Checked In" {'selected' if 'Checked In' == filters['status'] else ''}>Checked In</option>
                                <option value="Checked Out" {'selected' if 'Checked Out' == filters['status'] else ''}>Checked Out</option>
                            </select>
                        </div>
                        <div>
                            <label for="location" style="text-align:left;display:block;">Location</label>
                            <select name="location" id="location"><option value="">All</option>
                                {''.join(f"<option value='{l['Location']}' {'selected' if l['Location'] == filters['location'] else ''}>{l['Location']}</option>" for l in locations)}
                            </select>
                        </div>
                    </div>
                    <div style="padding-top:10px;">
                        <button type="submit" formaction="/" formmethod="GET">Filter</button>
                        <a href="/" class="button">Clear</a>
                    </div>
                </details>
            </div>

            <table>
                <thead><tr>
                    <th><input type="checkbox" onclick="var cbs=document.querySelectorAll('input[name=asset_ids]'); for(var i=0; i<cbs.length; i++) {{cbs[i].checked=this.checked;}}"></th>
                    <th>Asset #</th><th>Name</th><th>Category</th><th>Status</th><th>Location</th>
                </tr></thead>
                <tbody>{rows_html if assets else "<tr><td colspan='6'>No assets found matching criteria.</td></tr>"}</tbody>
            </table>
            {pagination_html}
        </form>
        """
        self.send_html_response(200, render_template("AssetManager Pro", content, local_ip_info=ip_info))

    def serve_add_edit_form(self, asset_id=None):
        conn = get_db_connection()
        asset = conn.execute("SELECT * FROM Assets WHERE AssetID = ?", (asset_id,)).fetchone() if asset_id else None
        settings = {row['SettingKey']: row['SettingValue'] for row in conn.execute("SELECT * FROM Settings").fetchall()}
        
        # Data for tabs
        maintenance_logs = []
        attachments = []
        custom_fields = []
        logistics_html = "<p>Save the asset first to manage logistics.</p>"

        if asset:
            maintenance_logs = conn.execute("SELECT * FROM Maintenance WHERE AssetID = ? ORDER BY Date DESC", (asset_id,)).fetchall()
            attachments = conn.execute("SELECT * FROM AssetAttachments WHERE AssetID = ? ORDER BY UploadDate DESC", (asset_id,)).fetchall()
            custom_fields = conn.execute("SELECT * FROM CustomFields WHERE AssetID = ?", (asset_id,)).fetchall()
            
            # Build Logistics Tab
            # Assigned IPs
            assigned_ips = conn.execute("SELECT Address FROM IPAddresses WHERE AssetID = ?", (asset_id,)).fetchall()
            ips_html = "".join(f"<li>{ip['Address']}</li>" for ip in assigned_ips) or "<li>None</li>"

            # Assigned Software
            assigned_software = conn.execute("SELECT sl.LicenseID, sl.Name FROM SoftwareLicenses sl JOIN AssetSoftware asw ON sl.LicenseID = asw.LicenseID WHERE asw.AssetID = ?", (asset_id,)).fetchall()
            software_html = "".join(f"<li>{s['Name']} <form class='inline-form' action='/unassign_software/{asset_id}' method='POST'><input type='hidden' name='license_id' value='{s['LicenseID']}'><button type='submit' style='height:18px;font-size:7pt;'>X</button></form></li>" for s in assigned_software) or "<li>None</li>"
            
            # Assigned Tags
            assigned_tags = conn.execute("SELECT t.TagID, t.TagName, t.TagColor FROM Tags t JOIN AssetTags at ON t.TagID = at.TagID WHERE at.AssetID = ?", (asset_id,)).fetchall()
            tags_html = "".join(f"<span style='background-color:{t['TagColor']}; padding: 2px 5px; border-radius: 3px; color: white; text-shadow: 1px 1px 1px #000; margin-right: 5px;'>{t['TagName']} <form class='inline-form' action='/unassign_tag/{asset_id}' method='POST'><input type='hidden' name='tag_id' value='{t['TagID']}'><button type='submit' style='height:16px;font-size:7pt;color:red;background:transparent;border:none;text-shadow:none;'>X</button></form></span>" for t in assigned_tags) or "None"

            # Rack Info
            rack_info = conn.execute("SELECT r.Name, a.RackUnit FROM Racks r JOIN Assets a ON r.RackID = a.RackID WHERE a.AssetID = ?", (asset_id,)).fetchone()
            rack_html = f"<p><strong>Rack:</strong> {rack_info['Name']} at <strong>U{rack_info['RackUnit']}</strong></p>" if rack_info else "<p>Not racked. <a href='/logistics/racks'>Assign to rack</a>.</p>"

            # Forms for assigning new logistics items
            unassigned_software = conn.execute("SELECT LicenseID, Name FROM SoftwareLicenses WHERE LicenseID NOT IN (SELECT LicenseID FROM AssetSoftware WHERE AssetID = ?)", (asset_id,)).fetchall()
            unassigned_software_options = "".join(f"<option value='{s['LicenseID']}'>{s['Name']}</option>" for s in unassigned_software)
            
            unassigned_tags = conn.execute("SELECT TagID, TagName FROM Tags WHERE TagID NOT IN (SELECT TagID FROM AssetTags WHERE AssetID = ?)", (asset_id,)).fetchall()
            unassigned_tags_options = "".join(f"<option value='{t['TagID']}'>{t['TagName']}</option>" for t in unassigned_tags)

            logistics_html = f'''
            {rack_html}
            <h3>Assigned IP Addresses</h3><ul>{ips_html}</ul><a href="/logistics/ipam">Manage IPs</a>
            
            <h3>Assigned Software</h3><ul>{software_html}</ul>
            <form action="/assign_software/{asset_id}" method="POST" style="display:block;">
                <label style="text-align:left;">Assign Software:</label>
                <select name="license_id">{unassigned_software_options}</select>
                <button type="submit">Assign</button>
            </form>

            <h3>Assigned Tags</h3><p>{tags_html}</p>
            <form action="/assign_tag/{asset_id}" method="POST" style="display:block;">
                <label style="text-align:left;">Assign Tag:</label>
                <select name="tag_id">{unassigned_tags_options}</select>
                <button type="submit">Assign</button>
            </form>
            '''

        title = f"Edit: {asset['Name']}" if asset else "Add New Asset"
        
        form_values = {k: (v if v is not None else '') for k, v in dict(asset).items()} if asset else {}
        details_tab_html = f'''
        <form action="/save" method="POST">
            <input type="hidden" name="asset_id" value="{form_values.get('AssetID', '')}">
            <input type="hidden" name="AssetNumber" value="{form_values.get('AssetNumber', '')}">
            <label for="Name">Asset Name:</label><input type="text" id="Name" name="Name" value="{form_values.get('Name', '')}" required>
            <label for="Category">Category:</label><input type="text" id="Category" name="Category" value="{form_values.get('Category', '')}">
            <label for="Location">Location:</label><input type="text" id="Location" name="Location" value="{form_values.get('Location', '')}">
            <label for="Manufacturer">Manufacturer:</label><input type="text" id="Manufacturer" name="Manufacturer" value="{form_values.get('Manufacturer', '')}">
            <label for="Model">Model:</label><input type="text" id="Model" name="Model" value="{form_values.get('Model', '')}">
            <label for="SerialNumber">Serial Number:</label><input type="text" id="SerialNumber" name="SerialNumber" value="{form_values.get('SerialNumber', '')}">
            <label for="PurchaseDate">Purchase Date:</label><input type="date" id="PurchaseDate" name="PurchaseDate" value="{form_values.get('PurchaseDate', '')}">
            <label for="Cost">Cost:</label><input type="number" step="0.01" id="Cost" name="Cost" value="{form_values.get('Cost', '')}">
            <label for="WarrantyEndDate">Warranty End:</label><input type="date" id="WarrantyEndDate" name="WarrantyEndDate" value="{form_values.get('WarrantyEndDate', '')}">
            <label for="NextMaintenanceDate">Next Maintenance:</label><input type="date" id="NextMaintenanceDate" name="NextMaintenanceDate" value="{form_values.get('NextMaintenanceDate', '')}">
            <div class="form-actions">
                <button type="submit">Save Asset</button>
                <button type="submit" name="save_and_new" value="true">Save & Add Another</button>
            </div>
        </form>
        '''
        
        maintenance_rows = "".join(f"<tr><td>{m['Date']}</td><td>{m['Type']}</td><td>{m['Notes']}</td><td>${m['Cost'] or 0:.2f}</td><td><form class='inline-form' action='/delete_maintenance/{m['MaintenanceID']}' method='POST' onsubmit='return confirm(\"Delete this maintenance log?\");'><button type='submit'>X</button></form></td></tr>" for m in maintenance_logs)
        maintenance_tab_html = f'''
        <h3>Maintenance History</h3>
        <table><thead><tr><th>Date</th><th>Type</th><th>Notes</th><th>Cost</th><th></th></tr></thead><tbody>{maintenance_rows or "<tr><td colspan=5>No maintenance logged.</td></tr>"}</tbody></table>
        <h3>Log New Maintenance</h3>
        <form action="/add_maintenance/{asset_id}" method="POST" style="display:block;">
            <div class="filter-grid">
                <div><label style="text-align:left;">Date:</label><input type="date" name="date" value="{datetime.date.today().isoformat()}" required></div>
                <div><label style="text-align:left;">Type:</label><input type="text" name="type" placeholder="e.g., Repair, Upgrade" required></div>
                <div><label style="text-align:left;">Cost:</label><input type="number" name="cost" step="0.01" placeholder="0.00"></div>
            </div>
            <label style="text-align:left; display:block; margin-top:10px;">Notes:</label>
            <textarea name="notes" rows="3"></textarea>
            <div style="padding-top:10px;"><button type="submit">Add Log</button></div>
        </form>
        ''' if asset else "<p>Save the asset first to add maintenance logs.</p>"

        attachment_rows = "".join(f"<tr><td><a href='/attachments/{att['AttachmentID']}' target='_blank'>{att['FileName']}</a></td><td>{att['UploadDate']}</td><td><form class='inline-form' action='/delete_attachment/{att['AttachmentID']}' method='POST' onsubmit='return confirm(\"Delete this attachment?\");'><button>X</button></form></td></tr>" for att in attachments)
        attachments_tab_html = f'''
        <h3>Attachments</h3>
        <table><thead><tr><th>File</th><th>Uploaded</th><th></th></tr></thead><tbody>{attachment_rows or "<tr><td colspan=3>No files attached.</td></tr>"}</tbody></table>
        <h3>Upload New Attachment</h3>
        <form action="/add_attachment/{asset_id}" method="POST" enctype="multipart/form-data" style="display:block;">
             <label style="text-align:left;">File:</label><input type="file" name="attachment" required>
             <div style="padding-top:10px;"><button type="submit">Upload</button></div>
        </form>
        ''' if asset else "<p>Save the asset first to add attachments.</p>"

        custom_field_rows = "".join(f"<tr><td>{f['FieldName']}</td><td>{f['FieldValue']}</td><td><form class='inline-form' action='/delete_custom_field/{f['FieldID']}' method='POST' onsubmit='return confirm(\"Delete this custom field?\");'><button>X</button></form></td></tr>" for f in custom_fields)
        custom_fields_tab_html = f'''
        <h3>Custom Fields</h3>
        <table><thead><tr><th>Field Name</th><th>Value</th><th></th></tr></thead><tbody>{custom_field_rows or "<tr><td colspan=3>No custom fields.</td></tr>"}</tbody></table>
        <h3>Add New Custom Field</h3>
        <form action="/add_custom_field/{asset_id}" method="POST" style="display:block;">
            <div class="filter-grid">
                <div><label style="text-align:left;">Field Name:</label><input type="text" name="FieldName" required></div>
                <div><label style="text-align:left;">Field Value:</label><input type="text" name="FieldValue" required></div>
            </div>
            <div style="padding-top:10px;"><button type="submit">Add Field</button></div>
        </form>
        ''' if asset else "<p>Save the asset first to add custom fields.</p>"
        
        # *** FIX for image display ***
        image_html = '<p>No image uploaded.</p>'
        if asset:
            image_attachments = [att for att in attachments if att['FileName'].lower().endswith(('.png', '.jpg', '.jpeg', '.gif'))]
            if image_attachments:
                primary_image_id = image_attachments[0]['AttachmentID']
                image_html = f'<img src="/attachments/{primary_image_id}" style="max-width:100%; max-height:150px; border:1px solid #7F9DB9;">'
        
        asset_num = asset['AssetNumber'] if asset else 'new'
        
        action_button_html = ''
        if asset:
            if asset['Status'] == 'Checked In':
                action_button_html = f'<button type="button" onclick="document.getElementById(\\\'checkoutModal\\\').style.display=\\\'block\\\'">Check Out</button>'
            else:
                action_button_html = f'<form class="inline-form" action="/checkin/{asset_id}" method="POST"><button type="submit">Check In</button></form>'
        
        content = f'''
        <h2>{title}</h2>
        <div style="margin-bottom:15px; display:flex; gap:10px; align-items:center;">
            {action_button_html}
            <a href="/history/{asset_id}" class="button">View History</a>
            <form class="inline-form" action="/archive/{asset_id}" method="POST" onsubmit="return confirm('Are you sure you want to archive this asset?');"><button type="submit">Archive</button></form>
        </div>
        <div class="asset-details-grid">
            <div>
                {image_html}
                <div class="barcode-container">
                    <div class="barcode-item"><img src="/barcode/{asset_num}.svg"></div>
                    <div class="qrcode-item"><img src="/qrcode/{asset_num}.png"></div>
                </div>
            </div>
            <div>
                <div class="tabs">
                    <button class="tab-link" onclick="switchTab(event, 'details')">Details</button>
                    <button class="tab-link" onclick="switchTab(event, 'logistics')">Logistics</button>
                    <button class="tab-link" onclick="switchTab(event, 'maintenance')">Maintenance</button>
                    <button class="tab-link" onclick="switchTab(event, 'attachments')">Attachments</button>
                    <button class="tab-link" onclick="switchTab(event, 'custom')">Custom Fields</button>
                </div>
                <div id="details" class="tab-content active">{details_tab_html}</div>
                <div id="logistics" class="tab-content">{logistics_html}</div>
                <div id="maintenance" class="tab-content">{maintenance_tab_html}</div>
                <div id="attachments" class="tab-content">{attachments_tab_html}</div>
                <div id="custom" class="tab-content">{custom_fields_tab_html}</div>
            </div>
        </div>
        '''
        if asset:
            default_user = settings.get('default_checkout_user', '')
            content += f'''
            <div id="checkoutModal" class="modal">
              <div class="modal-content">
                <span onclick="this.parentElement.parentElement.style.display='none'" style="float:right; cursor:pointer; font-weight:bold;">&times;</span>
                <h3>Check Out Asset: {asset['Name']}</h3>
                <form action="/checkout/{asset['AssetID']}" method="POST" style="display:block;">
                  <label for="user" style="text-align:left;">Your Name/ID:</label>
                  <input type="text" id="user" name="user" value="{default_user}" required>
                  <label for="notes" style="text-align:left;">Notes (Optional):</label>
                  <textarea id="notes" name="notes" rows="3"></textarea>
                  <div style="padding-top:10px;"><button type="submit">Confirm Check Out</button></div>
                </form>
              </div>
            </div>
            '''
        conn.close()
        self.send_html_response(200, render_template(title, content, show_utils_button=True))

    def serve_utils_page(self):
        conn = get_db_connection()
        backups = sorted([f for f in os.listdir(BACKUP_PATH) if f.endswith('.db')], reverse=True)
        assets = conn.execute("SELECT AssetID, Name, AssetNumber FROM Assets WHERE IsArchived = 0 ORDER BY Name").fetchall()
        conn.close()

        backup_options = "".join(f"<option value='{b}'>{b}</option>" for b in backups)
        asset_options = "".join(f"<option value='{a['AssetID']}'>{a['Name']} ({a['AssetNumber']})</option>" for a in assets)

        content = f'''
        <h2>Data Management Utilities</h2>
        
        <h3>Export Data</h3>
        <p>Export all asset data to a CSV file. This can be used for backups or external analysis.</p>
        <a href="/export/csv" class="button">Export to CSV</a>

        <h3>Import from CSV</h3>
        <p>Import assets from a CSV file. The CSV must have headers: AssetNumber, Name, Category, PurchaseDate, Cost, Manufacturer, Model, SerialNumber, Location.</p>
        <form action="/import/csv" method="POST" enctype="multipart/form-data" style="display:block;">
            <label style="text-align:left;">CSV File:</label><input type="file" name="csv_file" accept=".csv" required>
            <div style="padding-top:10px;"><button type="submit">Import CSV</button></div>
        </form>

        <h3>Barcode Utilities</h3>
        <p>Select assets below to generate a printable sheet of barcode labels, or print all/unassigned labels.</p>
        <form action="/print_labels" method="POST" target="_blank" style="display:block; border: 1px solid #ACA899; padding: 10px; margin-top: 10px;">
            <h4 style="margin-top:0;">Print Specific Labels</h4>
            <label style="text-align:left;">Select Assets for Printing:</label>
            <select name="asset_ids" multiple size="10" required>{asset_options}</select>
            <div style="padding-top:10px;"><button type="submit">Generate Label Sheet</button></div>
        </form>
        <form action="/print_labels" method="POST" target="_blank" style="display:block; border: 1px solid #ACA899; padding: 10px; margin-top: 10px;">
            <h4 style="margin-top:0;">Print Unassigned Labels</h4>
            <p>Generate and print barcodes for new asset numbers that have not yet been created.</p>
            <label style="text-align:left;">Number of new labels to generate:</label>
            <input type="number" name="unassigned_count" value="10" min="1" max="100" style="width:100px;">
            <div style="padding-top:10px;"><button type="submit">Generate Unassigned Labels</button></div>
        </form>
        <div style="border: 1px solid #ACA899; padding: 10px; margin-top: 10px;">
            <h4 style="margin-top:0;">Print All Labels</h4>
            <p>Generate a printable sheet containing a barcode for every asset in the database.</p>
            <a href="/print_labels?all=true" class="button" target="_blank">Print All Asset Labels</a>
        </div>
        
        <h3>Database Backup & Restore</h3>
        <p>Create an immediate backup of the entire database file. <a href="/archived">View Archived Assets</a></p>
        <a href="/backup" class="button">Create Backup Now</a>
        
        <h3 style="margin-top:20px;">Restore from Backup</h3>
        <p>Restore the database from a previous backup. <strong>WARNING: This will overwrite all current data.</strong></p>
        <form action="/restore_backup" method="POST" onsubmit="return confirm('ARE YOU SURE? This will overwrite all current data with the selected backup.');" style="display:block;">
            <label style="text-align:left;">Select Backup:</label>
            <select name="backup_file" required>
                {backup_options if backups else "<option>No backups found</option>"}
            </select>
            <div style="padding-top:10px;"><button type="submit" {'disabled' if not backups else ''}>Restore from Backup</button></div>
        </form>
        '''
        self.send_html_response(200, render_template("Utilities", content))
        
    def serve_scan_page(self):
        content = '''
        <h2>Scan & Lookup</h2>
        <p>Enter an Asset Number below to look up its details, or use your camera to scan a barcode.</p>
        <div class="kiosk-container">
            <form onsubmit="performLookup(); return false;" class="kiosk-input-wrapper">
                <input type="text" id="assetNumberInput" class="kiosk-input" placeholder="Enter or Scan Asset #" autofocus>
                <button type="button" id="scan-button" title="Scan with Camera" style="height: 40px; width: 40px; padding: 5px;">&#128247;</button>
                <button type="submit" style="height: 40px;">Lookup</button>
            </form>
            <div id="scanner-container">
                <div id="reader"></div>
                <button id="stop-scan-button" style="margin-top:10px; display:none;">Stop Scanning</button>
            </div>
            <div id="kiosk-result">
                <p>Waiting for input...</p>
            </div>
        </div>
        <script src="https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js"></script>
        <script>
            let html5QrcodeScanner = null;

            function onScanSuccess(decodedText, decodedResult) {
                console.log(`Code matched = ${decodedText}`, decodedResult);
                document.getElementById('assetNumberInput').value = decodedText;
                stopScanning();
                performLookup();
            }

            function onScanFailure(error) {
                // console.warn(`Code scan error = ${error}`);
            }

            function startScanning() {
                const readerDiv = document.getElementById('reader');
                const container = document.getElementById('scanner-container');
                const stopButton = document.getElementById('stop-scan-button');
                
                container.style.display = 'block';
                stopButton.style.display = 'inline-block';
                
                if (!html5QrcodeScanner) {
                    html5QrcodeScanner = new Html5QrcodeScanner("reader", { fps: 10, qrbox: {width: 250, height: 250} }, false);
                }
                html5QrcodeScanner.render(onScanSuccess, onScanFailure);
            }

            function stopScanning() {
                if (html5QrcodeScanner) {
                    html5QrcodeScanner.clear().catch(error => {
                        console.error("Failed to clear html5QrcodeScanner.", error);
                    });
                    html5QrcodeScanner = null;
                    document.getElementById('scanner-container').style.display = 'none';
                    document.getElementById('stop-scan-button').style.display = 'none';
                }
            }

            document.getElementById('scan-button').addEventListener('click', startScanning);
            document.getElementById('stop-scan-button').addEventListener('click', stopScanning);

            function performLookup() {
                const assetNumber = document.getElementById('assetNumberInput').value;
                if (!assetNumber) return;
                fetch(`/api/search?asset_number=${assetNumber}`)
                    .then(response => response.json())
                    .then(data => {
                        const resultDiv = document.getElementById('kiosk-result');
                        if (data.error) {
                            resultDiv.innerHTML = `<p style="color:red;">${data.error}</p>`;
                        } else {
                            resultDiv.innerHTML = `
                                <h3>${data.Name} (${data.AssetNumber})</h3>
                                <p><strong>Status:</strong> <span style="font-weight:bold; color:${data.Status === 'Checked In' ? 'green' : 'red'};">${data.Status}</span></p>
                                <p><strong>Category:</strong> ${data.Category || 'N/A'}</p>
                                <p><strong>Location:</strong> ${data.Location || 'N/A'}</p>
                                <a href="/edit/${data.AssetID}" class="button">View Full Details</a>
                            `;
                        }
                        document.getElementById('assetNumberInput').value = '';
                        document.getElementById('assetNumberInput').focus();
                    });
            }
        </script>
        '''
        self.send_html_response(200, render_template("Scan & Lookup", content))

    def serve_kiosk_page(self):
        content = '''
        <h2>Kiosk Mode</h2>
        <p>Scan an asset barcode to see its status and perform quick actions.</p>
        <div class="kiosk-container">
             <form onsubmit="performLookup(); return false;" class="kiosk-input-wrapper">
                 <input type="text" id="assetNumberInput" class="kiosk-input" placeholder="Scan Barcode..." autofocus>
                 <button type="button" id="scan-button" title="Scan with Camera" style="height: 40px; width: 40px; padding: 5px;">&#128247;</button>
                 <button type="submit" style="display:none;"></button> </form>
            <div id="scanner-container">
                <div id="reader"></div>
                <button id="stop-scan-button" style="margin-top:10px; display:none;">Stop Scanning</button>
            </div>
            <div id="kiosk-result">
                <p>Ready to scan...</p>
            </div>
        </div>
        <script src="https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js"></script>
        <script>
            let html5QrcodeScanner = null;

            function onScanSuccess(decodedText, decodedResult) {
                document.getElementById('assetNumberInput').value = decodedText;
                stopScanning();
                performLookup();
            }

            function onScanFailure(error) { /* Quietly ignore */ }

            function startScanning() {
                document.getElementById('scanner-container').style.display = 'block';
                document.getElementById('stop-scan-button').style.display = 'inline-block';
                if (!html5QrcodeScanner) {
                    html5QrcodeScanner = new Html5QrcodeScanner("reader", { fps: 10, qrbox: {width: 250, height: 250} }, false);
                }
                html5QrcodeScanner.render(onScanSuccess, onScanFailure);
            }

            function stopScanning() {
                if (html5QrcodeScanner) {
                    html5QrcodeScanner.clear().catch(error => console.error("Scanner clear failed.", error));
                    html5QrcodeScanner = null;
                }
                document.getElementById('scanner-container').style.display = 'none';
                document.getElementById('stop-scan-button').style.display = 'none';
            }

            document.getElementById('scan-button').addEventListener('click', startScanning);
            document.getElementById('stop-scan-button').addEventListener('click', stopScanning);

            function performLookup() {
                const assetNumber = document.getElementById('assetNumberInput').value;
                if (!assetNumber) return;
                fetch(`/api/search?asset_number=${assetNumber}`)
                    .then(response => response.json())
                    .then(data => {
                        const resultDiv = document.getElementById('kiosk-result');
                        if (data.error) {
                            resultDiv.innerHTML = `<h3>Asset Not Found</h3><p style="color:red;">${data.error}</p>`;
                        } else {
                            let actionButton = '';
                            if (data.Status === 'Checked In') {
                                actionButton = `<form action="/checkout/${data.AssetID}" method="POST" style="display:block; grid-template-columns:none;"><input type="hidden" name="user" value="Kiosk"><button type="submit" style="font-size:12pt; padding:10px 20px;">Check Out</button></form>`;
                            } else {
                                actionButton = `<form action="/checkin/${data.AssetID}" method="POST" style="display:block; grid-template-columns:none;"><button type="submit" style="font-size:12pt; padding:10px 20px;">Check In</button></form>`;
                            }
                            resultDiv.innerHTML = `
                                <h3>${data.Name}</h3>
                                <p style="font-size:14pt;"><strong>Status:</strong> <span style="font-weight:bold; color:${data.Status === 'Checked In' ? 'green' : 'red'};">${data.Status}</span></p>
                                <p><strong>Location:</strong> ${data.Location || 'N/A'}</p>
                                ${actionButton}
                                <a href="/edit/${data.AssetID}" class="button" style="margin-top:10px;">Full Details</a>
                            `;
                        }
                        document.getElementById('assetNumberInput').value = '';
                        document.getElementById('assetNumberInput').focus();
                    });
            }
            // Refocus input if user clicks away
            document.body.addEventListener('click', (e) => {
                if(e.target.tagName !== 'BUTTON' && e.target.tagName !== 'A' && e.target.tagName !== 'INPUT') {
                   document.getElementById('assetNumberInput').focus()
                }
            });
        </script>
        '''
        self.send_html_response(200, render_template("Kiosk Mode", content, show_utils_button=False))

    def serve_logistics_dashboard(self):
        content = '''
        <h2>Logistics Dashboard</h2>
        <p>Manage all physical and virtual aspects of your homelab and infrastructure.</p>
        <div class="filter-grid">
            <a href="/logistics/ipam" class="button" style="display:block; text-align:center; padding: 20px;">IP Address Management (IPAM)</a>
            <a href="/logistics/software" class="button" style="display:block; text-align:center; padding: 20px;">Software & Licenses</a>
            <a href="/logistics/racks" class="button" style="display:block; text-align:center; padding: 20px;">Rack Manager</a>
            <a href="/logistics/vendors" class="button" style="display:block; text-align:center; padding: 20px;">Vendor Management</a>
            <a href="/logistics/tags" class="button" style="display:block; text-align:center; padding: 20px;">Tag Management</a>
        </div>
        '''
        self.send_html_response(200, render_template("Logistics", content))

    def serve_racks_page(self):
        conn = get_db_connection()
        racks = conn.execute("SELECT * FROM Racks ORDER BY Name").fetchall()
        assets_in_racks = conn.execute("SELECT * FROM Assets WHERE RackID IS NOT NULL ORDER BY RackUnit DESC").fetchall()
        unracked_assets = conn.execute("SELECT AssetID, Name FROM Assets WHERE RackID IS NULL AND IsArchived = 0 ORDER BY Name").fetchall()
        conn.close()

        rack_html = ""
        for rack in racks:
            rack_html += f"<h3>{rack['Name']} - {rack['Location']} ({rack['UHeight']}U)</h3>"
            rack_html += "<table style='table-layout: fixed;'><tr><th style='width:50px;'>U</th><th>Asset</th></tr>"
            
            units = {asset['RackUnit']: asset for asset in assets_in_racks if asset['RackID'] == rack['RackID']}
            
            for u in range(rack['UHeight'], 0, -1):
                if u in units:
                    asset = units[u]
                    rack_html += f"<tr><td>{u}</td><td><a href='/edit/{asset['AssetID']}'>{asset['Name']}</a> ({asset['AssetNumber']})</td></tr>"
                else:
                    rack_html += f"<tr><td>{u}</td><td>-</td></tr>"
            rack_html += "</table>"

        unracked_options = "".join(f"<option value='{a['AssetID']}'>{a['Name']}</option>" for a in unracked_assets)
        rack_options = "".join(f"<option value='{r['RackID']}'>{r['Name']}</option>" for r in racks)

        content = f'''
        <h2>Rack Manager</h2>
        <div class="asset-details-grid">
            <div>
                <h3>Add New Rack</h3>
                <form action="/logistics/racks/add" method="POST" style="display:block;">
                    <label style="text-align:left;">Rack Name:</label><input type="text" name="name" required>
                    <label style="text-align:left;">Location:</label><input type="text" name="location">
                    <label style="text-align:left;">U Height:</label><input type="number" name="u_height" required>
                    <div style="padding-top:10px;"><button type="submit">Add Rack</button></div>
                </form>

                <h3 style="margin-top:20px;">Assign Asset to Rack</h3>
                <form action="/logistics/racks/assign" method="POST" style="display:block;">
                    <label style="text-align:left;">Asset:</label><select name="asset_id" required>{unracked_options}</select>
                    <label style="text-align:left;">Rack:</label><select name="rack_id" required>{rack_options}</select>
                    <label style="text-align:left;">U Position:</label><input type="number" name="rack_unit" required>
                    <div style="padding-top:10px;"><button type="submit">Assign to Rack</button></div>
                </form>
            </div>
            <div>
                {rack_html if racks else "<p>No racks defined. Add one to get started.</p>"}
            </div>
        </div>
        '''
        self.send_html_response(200, render_template("Rack Manager", content))

    def serve_history_page(self, asset_id):
        conn = get_db_connection()
        asset = conn.execute("SELECT Name, AssetNumber FROM Assets WHERE AssetID = ?", (asset_id,)).fetchone()
        logs = conn.execute("SELECT * FROM Logs WHERE AssetID = ? ORDER BY Timestamp DESC", (asset_id,)).fetchall()
        conn.close()

        if not asset:
            self.send_error(404, "Asset not found")
            return

        log_rows = "".join(f"<tr><td>{log['Timestamp']}</td><td>{log['User']}</td><td>{log['Action']}</td><td>{log['Notes']}</td></tr>" for log in logs)

        content = f'''
        <h2>History for: {asset['Name']} ({asset['AssetNumber']})</h2>
        <a href="/edit/{asset_id}" class="button" style="margin-bottom:15px;">&larr; Back to Asset</a>
        <table>
            <thead>
                <tr><th>Timestamp</th><th>User</th><th>Action</th><th>Notes</th></tr>
            </thead>
            <tbody>
                {log_rows if logs else "<tr><td colspan='4'>No history logs found for this asset.</td></tr>"}
            </tbody>
        </table>
        '''
        self.send_html_response(200, render_template(f"History: {asset['Name']}", content))

    def serve_ipam_page(self):
        conn = get_db_connection()
        subnets = conn.execute("SELECT * FROM Subnets ORDER BY Name").fetchall()
        ips = conn.execute("SELECT IP.*, S.Name as SubnetName, A.Name as AssetName FROM IPAddresses IP LEFT JOIN Subnets S ON IP.SubnetID = S.SubnetID LEFT JOIN Assets A ON IP.AssetID = A.AssetID ORDER BY IP.Address").fetchall()
        assets = conn.execute("SELECT AssetID, Name FROM Assets WHERE IsArchived = 0 ORDER BY Name").fetchall()
        conn.close()

        subnet_rows = "".join(f"<tr><td>{s['Name']}</td><td>{s['NetworkAddress']}</td><td>{s['VlanID'] or ''}</td></tr>" for s in subnets)
        ip_rows = "".join(f"<tr><td>{ip['Address']}</td><td>{ip['SubnetName']}</td><td>{ip['AssetName'] or ''}</td><td>{ip['Notes'] or ''}</td></tr>" for ip in ips)
        asset_options = "".join(f"<option value='{a['AssetID']}'>{a['Name']}</option>" for a in assets)
        subnet_options = "".join(f"<option value='{s['SubnetID']}'>{s['Name']} ({s['NetworkAddress']})</option>" for s in subnets)
        
        # Check if nmap is available
        nmap_available = nmap is not None
        scan_button_html = '<a href="/logistics/ipam/scan" class="button">Scan Network for Devices</a>' if nmap_available else '<p style="color:red;">Nmap not found. Network scanning is disabled.</p>'


        content = f'''
        <h2>IP Address Management (IPAM)</h2>
        {scan_button_html}
        <div class="asset-details-grid">
            <div>
                <h3>Add New Subnet</h3>
                <form action="/logistics/ipam/add_subnet" method="POST" style="display:block;">
                    <label style="text-align:left;">Name:</label><input type="text" name="name" required>
                    <label style="text-align:left;">Network Address (CIDR):</label><input type="text" name="network_address" placeholder="e.g., 192.168.1.0/24" required>
                    <label style="text-align:left;">VLAN ID:</label><input type="number" name="vlan_id">
                    <div style="padding-top:10px;"><button type="submit">Add Subnet</button></div>
                </form>
                <h3 style="margin-top:20px;">Assign IP Address</h3>
                <form action="/logistics/ipam/add_ip" method="POST" style="display:block;">
                    <label style="text-align:left;">IP Address:</label><input type="text" name="address" required>
                    <label style="text-align:left;">Subnet:</label><select name="subnet_id" required>{subnet_options}</select>
                    <label style="text-align:left;">Assigned Asset:</label><select name="asset_id"><option value="">None</option>{asset_options}</select>
                    <label style="text-align:left;">Notes:</label><input type="text" name="notes">
                    <div style="padding-top:10px;"><button type="submit">Assign IP</button></div>
                </form>
            </div>
            <div>
                <h3>Subnets</h3>
                <table><thead><tr><th>Name</th><th>Network</th><th>VLAN</th></tr></thead><tbody>{subnet_rows or "<tr><td colspan=3>No subnets defined.</td></tr>"}</tbody></table>
                <h3 style="margin-top:20px;">Assigned IP Addresses</h3>
                <table><thead><tr><th>Address</th><th>Subnet</th><th>Asset</th><th>Notes</th></tr></thead><tbody>{ip_rows or "<tr><td colspan=4>No IPs assigned.</td></tr>"}</tbody></table>
            </div>
        </div>
        '''
        self.send_html_response(200, render_template("IPAM", content))

    def serve_ipam_scan_page(self):
        if not nmap:
            self.send_html_response(501, "Nmap support is not available.")
            return

        query_params = parse_qs(urlparse(self.path).query)
        scan_target = query_params.get('target', [None])[0]
        
        _, default_subnet = get_local_ip_and_subnet()
        if not scan_target:
            scan_target = default_subnet

        results_html = "<h3>Scanning...</h3><p>Please be patient, this may take a few minutes.</p><meta http-equiv='refresh' content='1'>"
        scan_in_progress = True

        try:
            nm = nmap.PortScanner()
            # -sn: Ping Scan - disable port scan. -T4: Aggressive timing.
            nm.scan(hosts=scan_target, arguments='-sn -T4')
            
            hosts_list = []
            for host in nm.all_hosts():
                mac = nm[host]['addresses'].get('mac', 'N/A')
                vendor = get_vendor_from_mac(mac)
                hosts_list.append({'ip': host, 'mac': mac, 'vendor': vendor})

            # Filter out hosts already in the DB
            conn = get_db_connection()
            existing_ips = {row['Address'] for row in conn.execute("SELECT Address FROM IPAddresses").fetchall()}
            conn.close()

            new_hosts = [h for h in hosts_list if h['ip'] not in existing_ips]

            rows_html = "".join(
                f"""<tr>
                    <td>{host['ip']}</td>
                    <td>{host['mac']}</td>
                    <td>{host['vendor']}</td>
                    <td><a href="/new?prefill_ip={host['ip']}&prefill_manufacturer={host['vendor']}" class="button">Add Asset</a></td>
                </tr>""" for host in new_hosts)
            
            results_html = f'''
            <h3>Discovered Devices on {scan_target}</h3>
            <p>{len(new_hosts)} new devices found. Devices already in IPAM are not shown.</p>
            <table>
                <thead><tr><th>IP Address</th><th>MAC Address</th><th>Manufacturer</th><th>Action</th></tr></thead>
                <tbody>{rows_html if new_hosts else "<tr><td colspan='4'>No new devices found.</td></tr>"}</tbody>
            </table>
            '''
            scan_in_progress = False

        except Exception as e:
            results_html = f"<p style='color:red;'><strong>Scan failed:</strong> {e}</p><p>Ensure nmap is installed and accessible via your system's PATH.</p>"
            scan_in_progress = False
        
        content = f'''
        <h2>Network Device Discovery</h2>
        <a href="/logistics/ipam" class="button">&larr; Back to IPAM</a>
        <form action="/logistics/ipam/scan" method="GET" style="display:block; margin-top:15px;">
            <label style="text-align:left;">Scan Target (CIDR):</label>
            <input type="text" name="target" value="{scan_target}">
            <button type="submit">Start Scan</button>
        </form>
        <div style="margin-top: 20px;" id="scan-results">
            {results_html}
        </div>
        '''
        if not scan_in_progress:
            # Add script to prevent refresh spamming
            content += "<script>setTimeout(() => window.location.href = window.location.href, 600000);</script>"

        self.send_html_response(200, render_template("Network Scan", content))


    def serve_software_page(self):
        conn = get_db_connection()
        licenses = conn.execute("SELECT S.*, V.Name as VendorName FROM SoftwareLicenses S LEFT JOIN Vendors V ON S.VendorID = V.VendorID ORDER BY S.Name").fetchall()
        vendors = conn.execute("SELECT VendorID, Name FROM Vendors ORDER BY Name").fetchall()
        conn.close()

        license_rows = "".join(f"<tr><td>{l['Name']}</td><td>{l['LicenseKey']}</td><td>{l['ExpiryDate'] or 'N/A'}</td><td>{l['Seats']}</td><td>{l['VendorName'] or ''}</td></tr>" for l in licenses)
        vendor_options = "".join(f"<option value='{v['VendorID']}'>{v['Name']}</option>" for v in vendors)

        content = f'''
        <h2>Software & License Management</h2>
        <div class="asset-details-grid">
            <div>
                <h3>Add New License</h3>
                <form action="/logistics/software/add" method="POST" style="display:block;">
                    <label style="text-align:left;">Software Name:</label><input type="text" name="name" required>
                    <label style="text-align:left;">License Key:</label><input type="text" name="license_key">
                    <label style="text-align:left;">Purchase Date:</label><input type="date" name="purchase_date">
                    <label style="text-align:left;">Expiry Date:</label><input type="date" name="expiry_date">
                    <label style="text-align:left;">Seats:</label><input type="number" name="seats" value="1">
                    <label style="text-align:left;">Vendor:</label><select name="vendor_id"><option value="">None</option>{vendor_options}</select>
                    <div style="padding-top:10px;"><button type="submit">Add License</button></div>
                </form>
            </div>
            <div>
                <h3>All Licenses</h3>
                <table><thead><tr><th>Name</th><th>Key</th><th>Expires</th><th>Seats</th><th>Vendor</th></tr></thead><tbody>{license_rows or "<tr><td colspan=5>No licenses logged.</td></tr>"}</tbody></table>
            </div>
        </div>
        '''
        self.send_html_response(200, render_template("Software Licenses", content))

    def serve_vendors_page(self):
        conn = get_db_connection()
        vendors = conn.execute("SELECT * FROM Vendors ORDER BY Name").fetchall()
        conn.close()

        vendor_rows = "".join(f"<tr><td>{v['Name']}</td><td><a href='{v['Website']}' target='_blank'>{v['Website']}</a></td><td>{v['SupportContact']}</td></tr>" for v in vendors)
        
        content = f'''
        <h2>Vendor Management</h2>
        <div class="asset-details-grid">
            <div>
                <h3>Add New Vendor</h3>
                <form action="/logistics/vendors/add" method="POST" style="display:block;">
                    <label style="text-align:left;">Vendor Name:</label><input type="text" name="name" required>
                    <label style="text-align:left;">Website:</label><input type="text" name="website">
                    <label style="text-align:left;">Support Contact:</label><input type="text" name="support_contact">
                    <div style="padding-top:10px;"><button type="submit">Add Vendor</button></div>
                </form>
            </div>
            <div>
                <h3>All Vendors</h3>
                <table><thead><tr><th>Name</th><th>Website</th><th>Support</th></tr></thead><tbody>{vendor_rows or "<tr><td colspan=3>No vendors defined.</td></tr>"}</tbody></table>
            </div>
        </div>
        '''
        self.send_html_response(200, render_template("Vendors", content))

    def serve_tags_page(self):
        conn = get_db_connection()
        tags = conn.execute("SELECT * FROM Tags ORDER BY TagName").fetchall()
        conn.close()

        tag_rows = "".join(f"<tr><td><span style='background-color:{t['TagColor']}; padding: 2px 5px; border-radius: 3px; color: white; text-shadow: 1px 1px 1px #000;'>{t['TagName']}</span></td><td>{t['TagColor']}</td></tr>" for t in tags)

        content = f'''
        <h2>Tag Management</h2>
        <div class="asset-details-grid">
            <div>
                <h3>Add New Tag</h3>
                <form action="/logistics/tags/add" method="POST" style="display:block;">
                    <label style="text-align:left;">Tag Name:</label><input type="text" name="name" required>
                    <label style="text-align:left;">Tag Color:</label><input type="color" name="color" value="#808080">
                    <div style="padding-top:10px;"><button type="submit">Add Tag</button></div>
                </form>
            </div>
            <div>
                <h3>All Tags</h3>
                <table><thead><tr><th>Tag</th><th>Color</th></tr></thead><tbody>{tag_rows or "<tr><td colspan=2>No tags defined.</td></tr>"}</tbody></table>
            </div>
        </div>
        '''
        self.send_html_response(200, render_template("Tags", content))

    def serve_settings_page(self):
        conn = get_db_connection()
        settings = {row['SettingKey']: row['SettingValue'] for row in conn.execute("SELECT * FROM Settings").fetchall()}
        conn.close()
        
        theme = settings.get('theme', 'royale')
        items_per_page = settings.get('items_per_page', '25')
        asset_prefix = settings.get('asset_prefix', 'VTR')
        default_user = settings.get('default_checkout_user', '')

        icon_history_html = ""
        try:
            # Sort by filename descending to show newest first
            icons = sorted(os.listdir(ICONS_PATH), reverse=True)
            for icon_file in icons:
                icon_history_html += f'''
                <div class="icon-history-item">
                    <img src="/icons/{icon_file}">
                    <form action="/set_active_favicon" method="POST" class="inline-form">
                        <input type="hidden" name="icon_filename" value="{icon_file}">
                        <button type="submit" style="font-size:7pt; height: 20px; padding: 2px 6px;">Set Active</button>
                    </form>
                </div>
                '''
        except FileNotFoundError:
            pass # No icons yet

        content = f'''
        <h2>System Settings</h2>
        <form action="/save_settings" method="POST" style="display:block;">
            <h3>Display Settings</h3>
            <label for="theme" style="text-align:left;">UI Theme:</label>
            <select id="theme" name="theme">
                <option value="royale" {'selected' if theme == 'royale' else ''}>Royale Blue (XP)</option>
                <option value="vista" {'selected' if theme == 'vista' else ''}>Aero (Vista)</option>
                <option value="classic" {'selected' if theme == 'classic' else ''}>Classic (9x)</option>
                <option value="olive" {'selected' if theme == 'olive' else ''}>Olive Green (XP)</option>
                <option value="silver" {'selected' if theme == 'silver' else ''}>Silver (XP)</option>
                <option value="dark" {'selected' if theme == 'dark' else ''}>Dark Mode</option>
                <option value="terminal" {'selected' if theme == 'terminal' else ''}>Terminal</option>
                <option value="cacao" {'selected' if theme == 'cacao' else ''}>Cacao</option>
            </select>
            <br>
            <label for="items_per_page" style="text-align:left;">Assets per Page:</label>
            <input type="number" id="items_per_page" name="items_per_page" value="{items_per_page}" min="5" max="100">

            <h3 style="margin-top:20px;">Functional Settings</h3>
            <label for="asset_prefix" style="text-align:left;">Asset Number Prefix:</label>
            <input type="text" id="asset_prefix" name="asset_prefix" value="{asset_prefix}" placeholder="e.g., VTR, ASSET">
            <br>
            <label for="default_checkout_user" style="text-align:left;">Default Checkout User:</label>
            <input type="text" id="default_checkout_user" name="default_checkout_user" value="{default_user}" placeholder="Your Name/ID">
            
            <div class="form-actions" style="grid-column: 1 / span 2; margin-top:20px;">
                <button type="submit">Save Settings</button>
            </div>
        </form>

        <h3 style="margin-top:20px;">Application Icon (Favicon)</h3>
        <p>Upload a new .ico file to change the browser tab icon. The server will restart to apply the change.</p>
        <form action="/upload_favicon" method="POST" enctype="multipart/form-data" style="display:block;">
            <label for="favicon_file" style="text-align:left;">Current Icon: <img src="/favicon.ico?v={datetime.datetime.now().timestamp()}" style="width:16px; height:16px; vertical-align:middle;"></label>
            <input type="file" id="favicon_file" name="favicon_file" accept=".ico" required>
            <div class="form-actions" style="grid-column: 1 / span 2;">
                <button type="submit">Upload New Icon</button>
            </div>
        </form>

        <h3 style="margin-top:20px;">Icon History</h3>
        <p>Set a previously uploaded icon as the active one.</p>
        <div class="icon-history-grid">
            {icon_history_html or "<p>No icon history found.</p>"}
        </div>
        '''
        self.send_html_response(200, render_template("Settings", content))

    def serve_archived_page(self):
        conn = get_db_connection()
        assets = conn.execute("SELECT * FROM Assets WHERE IsArchived = 1 ORDER BY AssetNumber").fetchall()
        conn.close()

        rows_html = "".join(
            f"""<tr>
                <td>{asset['AssetNumber']}</td>
                <td>{asset['Name']}</td>
                <td>{asset['DisposalDate'] or 'N/A'}</td>
                <td>{asset['DisposalMethod'] or 'N/A'}</td>
                <td>
                    <form action="/restore_asset/{asset['AssetID']}" method="POST" class="inline-form">
                        <button type="submit">Restore</button>
                    </form>
                </td>
            </tr>""" for asset in assets)

        content = f"""
        <h2>Archived Assets</h2>
        <a href="/" class="button">&larr; Back to Dashboard</a>
        <table>
            <thead><tr>
                <th>Asset #</th><th>Name</th><th>Disposal Date</th><th>Disposal Method</th><th>Actions</th>
            </tr></thead>
            <tbody>{rows_html if assets else "<tr><td colspan='5'>No archived assets found.</td></tr>"}</tbody>
        </table>
        """
        self.send_html_response(200, render_template("Archived Assets", content))

    def serve_print_labels_page(self):
        query_params = parse_qs(urlparse(self.path).query)
        form_data, _ = self.parse_post_data()

        labels_to_print = []
        
        conn = get_db_connection()
        if query_params.get('all', ['false'])[0] == 'true':
            # Print all assets
            assets = conn.execute("SELECT Name, AssetNumber FROM Assets WHERE IsArchived = 0 ORDER BY AssetNumber").fetchall()
            labels_to_print = [{'Name': a['Name'], 'AssetNumber': a['AssetNumber']} for a in assets]
        elif 'unassigned_count' in form_data:
            # Print unassigned labels
            try:
                count = int(form_data.get('unassigned_count', 0))
                if 0 < count <= 100:
                    asset_numbers = self.generate_unassigned_asset_numbers(count)
                    labels_to_print = [{'Name': 'Unassigned Asset', 'AssetNumber': num} for num in asset_numbers]
            except (ValueError, TypeError):
                pass
        elif 'asset_ids' in form_data:
            # Print specific assets
            asset_ids = form_data.get('asset_ids', [])
            if not isinstance(asset_ids, list): asset_ids = [asset_ids]
            
            if asset_ids:
                placeholders = ','.join('?' for _ in asset_ids)
                assets = conn.execute(f"SELECT Name, AssetNumber FROM Assets WHERE AssetID IN ({placeholders})", asset_ids).fetchall()
                labels_to_print = [{'Name': a['Name'], 'AssetNumber': a['AssetNumber']} for a in assets]
        conn.close()

        if not labels_to_print:
            self.send_html_response(400, "No assets selected or specified for printing.")
            return

        labels_html = ""
        for label in labels_to_print:
            labels_html += f'''
            <div class="label">
                <div class="label-name">{label['Name']}</div>
                <div class="label-barcode"><img src="/barcode/{label['AssetNumber']}.svg" /></div>
            </div>
            '''

        content = f'''
        <!DOCTYPE html>
        <html>
        <head>
            <title>Print Asset Labels</title>
            <style>
                @media screen {{
                    body {{ font-family: sans-serif; text-align: center; }}
                    .controls {{ margin-bottom: 20px; }}
                }}
                .label-grid {{
                    display: grid;
                    grid-template-columns: repeat(2, 1fr); /* 2 columns */
                    gap: 10px;
                    width: 210mm; /* A4 width */
                    margin: auto;
                }}
                .label {{
                    border: 1px solid #ccc;
                    padding: 10px;
                    text-align: center;
                    overflow: hidden;
                    page-break-inside: avoid;
                    height: 80px; /* Fixed height for consistency */
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                }}
                .label-name {{ font-size: 10pt; font-weight: bold; margin-bottom: 5px; }}
                .label-barcode img {{ max-width: 100%; height: 40px; }}
                @media print {{
                    body {{ margin: 0; }}
                    .controls {{ display: none; }}
                    @page {{ size: A4; margin: 1cm; }}
                    .label-grid {{
                        width: 100%;
                        gap: 0;
                    }}
                    .label {{ border: 1px dotted #ccc; }}
                }}
            </style>
        </head>
        <body>
            <div class="controls">
                <button onclick="window.print()">Print Labels</button>
                <a href="/utils" class="button">Back to Utilities</a>
            </div>
            <div class="label-grid">
                {labels_html}
            </div>
        </body>
        </html>
        '''
        self.send_html_response(200, content)

    # --- PWA & STATIC FILE SERVERS ---
    def serve_manifest(self):
        manifest = {
            "name": "EliteSoftware - AssetManager Pro",
            "short_name": "AssetManager",
            "start_url": "/",
            "display": "standalone",
            "background_color": "#ECE9D8",
            "theme_color": "#2872C4",
            "icons": [
                { "src": "/favicon.ico", "sizes": "48x48", "type": "image/x-icon" }
            ]
        }
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(manifest).encode('utf-8'))

    def serve_service_worker(self):
        sw_content = """
        // A basic service worker for PWA installability
        self.addEventListener('fetch', function(event) {
            // We are not implementing any caching or offline functionality yet.
            // This is just to satisfy the PWA criteria.
            event.respondWith(fetch(event.request));
        });
        """
        self.send_response(200)
        self.send_header('Content-Type', 'application/javascript')
        self.end_headers()
        self.wfile.write(sw_content.encode('utf-8'))

    def serve_barcode_svg(self, asset_number):
        try:
            code128 = barcode.get_barcode_class('code128')
            bc = code128(asset_number, writer=SVGWriter())
            
            buffer = io.BytesIO()
            bc.write(buffer)
            
            self.send_response(200)
            self.send_header('Content-Type', 'image/svg+xml')
            self.end_headers()
            self.wfile.write(buffer.getvalue())
        except Exception as e:
            print(f"Error generating barcode for {asset_number}: {e}")
            self.send_error(500, "Could not generate barcode")

    def serve_qrcode_png(self, asset_number):
        local_ip, _ = get_local_ip_and_subnet()
        url = f"http://{local_ip}:{self.server.server_port}/scan?asset_number={asset_number}"
        
        img = qrcode.make(url)
        img_buffer = io.BytesIO()
        img.save(img_buffer, format='PNG')
        
        self.send_response(200); self.send_header('Content-Type', 'image/png'); self.end_headers()
        self.wfile.write(img_buffer.getvalue())
        
    def serve_network_qr(self):
        local_ip, _ = get_local_ip_and_subnet()
        url = f"http://{local_ip}:{self.server.server_port}"
        img = qrcode.make(url)
        img_buffer = io.BytesIO()
        img.save(img_buffer, format='PNG')
        self.send_response(200); self.send_header('Content-Type', 'image/png'); self.end_headers()
        self.wfile.write(img_buffer.getvalue())

    def serve_favicon(self):
        if not os.path.exists(FAVICON_PATH):
            self.send_error(404, "Favicon not found")
            return
        try:
            with open(FAVICON_PATH, 'rb') as f:
                self.send_response(200)
                self.send_header('Content-type', 'image/x-icon')
                self.end_headers()
                self.wfile.write(f.read())
        except Exception as e:
            self.send_error(500, f"Could not serve favicon: {e}")

    def serve_historical_icon(self, filename):
        # Security: ensure filename is safe
        safe_filename = re.sub(r'[^a-zA-Z0-9_.-]', '_', filename)
        icon_path = os.path.join(ICONS_PATH, safe_filename)

        if not os.path.exists(icon_path):
            self.send_error(404, "Icon not found in history")
            return
        try:
            with open(icon_path, 'rb') as f:
                self.send_response(200)
                self.send_header('Content-type', 'image/x-icon')
                self.end_headers()
                self.wfile.write(f.read())
        except Exception as e:
            self.send_error(500, f"Could not serve historical icon: {e}")


    def serve_attachment(self, attachment_id):
        conn = get_db_connection()
        attachment = conn.execute("SELECT * FROM AssetAttachments WHERE AttachmentID = ?", (attachment_id,)).fetchone()
        conn.close()

        if not attachment or not os.path.exists(attachment['StoredPath']):
            self.send_error(404, "Attachment not found")
            return
        
        try:
            with open(attachment['StoredPath'], 'rb') as f:
                self.send_response(200)
                # More robust content type detection
                content_type = 'application/octet-stream'
                filename_lower = attachment['FileName'].lower()
                if filename_lower.endswith('.png'): content_type = 'image/png'
                elif filename_lower.endswith(('.jpg', '.jpeg')): content_type = 'image/jpeg'
                elif filename_lower.endswith('.gif'): content_type = 'image/gif'
                elif filename_lower.endswith('.svg'): content_type = 'image/svg+xml'
                elif filename_lower.endswith('.pdf'): content_type = 'application/pdf'
                elif filename_lower.endswith('.txt'): content_type = 'text/plain'
                
                self.send_header('Content-type', content_type)
                self.end_headers()
                self.wfile.write(f.read())
        except Exception as e:
            self.send_error(500, f"Could not serve attachment: {e}")

    # --- API HANDLERS ---
    def handle_api_search(self):
        query_params = parse_qs(urlparse(self.path).query)
        asset_number = query_params.get('asset_number', [None])[0]
        
        if not asset_number:
            self.send_response(400)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': 'asset_number parameter is required'}).encode('utf-8'))
            return

        conn = get_db_connection()
        asset = conn.execute("SELECT * FROM Assets WHERE AssetNumber = ? AND IsArchived = 0", (asset_number,)).fetchone()
        conn.close()

        if asset:
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            asset_dict = dict(asset)
            self.wfile.write(json.dumps(asset_dict).encode('utf-8'))
        else:
            self.send_response(404)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': 'Asset not found'}).encode('utf-8'))

    # --- ACTION HANDLERS ---
    
    def handle_save(self):
        form_data, file_data = self.parse_post_data()
        if not form_data: self.send_error(400, "Bad Request"); return
        
        def get_form_value(key): return form_data.get(key, '')
        
        asset_id = get_form_value('asset_id')
        asset_data = {
            k: (v if v else None) for k, v in {
                'Name': get_form_value('Name'), 'Category': get_form_value('Category'), 
                'PurchaseDate': get_form_value('PurchaseDate'), 'Manufacturer': get_form_value('Manufacturer'), 
                'Model': get_form_value('Model'), 'SerialNumber': get_form_value('SerialNumber'), 
                'Location': get_form_value('Location'), 'WarrantyEndDate': get_form_value('WarrantyEndDate'), 
                'NextMaintenanceDate': get_form_value('NextMaintenanceDate'),
                'DisposalDate': get_form_value('DisposalDate'), 'DisposalMethod': get_form_value('DisposalMethod')
            }.items()
        }
        asset_data['Cost'] = float(get_form_value('Cost')) if get_form_value('Cost') else None

        conn = get_db_connection()
        
        if asset_id: # Update existing asset
            asset_data['AssetID'] = int(asset_id)
            set_clause = ", ".join([f"{key} = ?" for key in asset_data if key != 'AssetID'])
            values = list(v for k, v in asset_data.items() if k != 'AssetID') + [asset_data['AssetID']]
            
            conn.execute(f"UPDATE Assets SET {set_clause} WHERE AssetID=?", tuple(values))
            log_asset(conn, asset_id, 'System', 'Asset Details Updated')
        else: # Insert new asset
            asset_number = self.generate_unassigned_asset_numbers(1)[0]
            asset_data['AssetNumber'] = asset_number
            columns = ', '.join(asset_data.keys())
            placeholders = ', '.join('?' * len(asset_data))
            sql = f"INSERT INTO Assets ({columns}) VALUES ({placeholders})"
            cursor = conn.execute(sql, tuple(asset_data.values()))
            asset_id = cursor.lastrowid
            log_asset(conn, asset_id, 'System', 'Asset Created')
        
        conn.commit()
        conn.close()

        if get_form_value('save_and_new'):
            self.send_response(303); self.send_header('Location', '/new'); self.end_headers()
        else:
            self.send_response(303); self.send_header('Location', f'/edit/{asset_id}'); self.end_headers()

    def handle_delete(self, asset_id):
        conn = get_db_connection()
        # Optional: Log before deleting if needed
        conn.execute("DELETE FROM Assets WHERE AssetID = ?", (asset_id,))
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', '/'); self.end_headers()

    def handle_check_in_out(self, asset_id, direction):
        conn = get_db_connection()
        if direction == 'out':
            form_data, _ = self.parse_post_data()
            user = form_data.get('user', 'Unknown')
            notes = form_data.get('notes', '')
            conn.execute("UPDATE Assets SET Status = 'Checked Out', CheckedOutTo = ? WHERE AssetID = ?", (user, asset_id))
            log_asset(conn, asset_id, user, 'Checked Out', notes)
        else: # 'in'
            conn.execute("UPDATE Assets SET Status = 'Checked In', CheckedOutTo = NULL WHERE AssetID = ?", (asset_id,))
            log_asset(conn, asset_id, 'System', 'Checked In')
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', self.headers.get('referer', '/')); self.end_headers()

    def handle_save_settings(self):
        form_data, _ = self.parse_post_data()
        conn = get_db_connection()
        for key, value in form_data.items():
            conn.execute("INSERT OR REPLACE INTO Settings (SettingKey, SettingValue) VALUES (?, ?)", (key, value))
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', '/settings'); self.end_headers()

    def handle_upload_favicon(self):
        _, file_data = self.parse_post_data()
        favicon_file = file_data.get('favicon_file')
        if not favicon_file:
            self.send_html_response(400, "No file uploaded.")
            return
        
        try:
            timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
            history_filename = f"icon-{timestamp}.ico"
            history_filepath = os.path.join(ICONS_PATH, history_filename)

            # Save to history
            with open(history_filepath, 'wb') as f:
                f.write(favicon_file['content'])
            
            # Set as active
            shutil.copy(history_filepath, FAVICON_PATH)

        except Exception as e:
            self.send_html_response(500, f"Error saving favicon: {e}")
            return
        self.send_response(303); self.send_header('Location', '/settings'); self.end_headers()

    def handle_set_active_favicon(self):
        form_data, _ = self.parse_post_data()
        icon_filename = form_data.get('icon_filename')
        if not icon_filename:
            self.send_html_response(400, "No icon filename provided.")
            return

        source_path = os.path.join(ICONS_PATH, icon_filename)
        if os.path.exists(source_path):
            shutil.copy(source_path, FAVICON_PATH)
        
        self.send_response(303); self.send_header('Location', '/settings'); self.end_headers()

    def handle_add_rack(self):
        form_data, _ = self.parse_post_data()
        conn = get_db_connection()
        conn.execute("INSERT INTO Racks (Name, Location, UHeight) VALUES (?, ?, ?)",
                       (form_data.get('name'), form_data.get('location'), form_data.get('u_height')))
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', '/logistics/racks'); self.end_headers()

    def handle_assign_rack(self):
        form_data, _ = self.parse_post_data()
        conn = get_db_connection()
        conn.execute("UPDATE Assets SET RackID = ?, RackUnit = ? WHERE AssetID = ?",
                       (form_data.get('rack_id'), form_data.get('rack_unit'), form_data.get('asset_id')))
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', '/logistics/racks'); self.end_headers()

    def handle_add_custom_field(self, asset_id):
        form_data, _ = self.parse_post_data()
        conn = get_db_connection()
        conn.execute("INSERT INTO CustomFields (AssetID, FieldName, FieldValue) VALUES (?, ?, ?)",
                       (asset_id, form_data.get('FieldName'), form_data.get('FieldValue')))
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', f'/edit/{asset_id}'); self.end_headers()

    def handle_delete_custom_field(self, field_id):
        conn = get_db_connection()
        asset_id = conn.execute("SELECT AssetID FROM CustomFields WHERE FieldID = ?", (field_id,)).fetchone()['AssetID']
        conn.execute("DELETE FROM CustomFields WHERE FieldID = ?", (field_id,))
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', f'/edit/{asset_id}'); self.end_headers()

    def handle_backup(self):
        backup_filename = f"backup-{datetime.datetime.now().strftime('%Y%m%d-%H%M%S')}.db"
        shutil.copy(DATABASE_PATH, os.path.join(BACKUP_PATH, backup_filename))
        self.send_response(303); self.send_header('Location', '/utils'); self.end_headers()

    def handle_restore_backup(self):
        form_data, _ = self.parse_post_data()
        backup_file = form_data.get('backup_file')
        if backup_file:
            shutil.copy(os.path.join(BACKUP_PATH, backup_file), DATABASE_PATH)
        self.send_response(303); self.send_header('Location', '/'); self.end_headers()

    def handle_add_subnet(self):
        form_data, _ = self.parse_post_data()
        conn = get_db_connection()
        conn.execute("INSERT INTO Subnets (Name, NetworkAddress, VlanID) VALUES (?, ?, ?)",
                       (form_data.get('name'), form_data.get('network_address'), form_data.get('vlan_id')))
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', '/logistics/ipam'); self.end_headers()

    def handle_add_ip(self):
        form_data, _ = self.parse_post_data()
        conn = get_db_connection()
        conn.execute("INSERT INTO IPAddresses (Address, SubnetID, AssetID, Notes) VALUES (?, ?, ?, ?)",
                       (form_data.get('address'), form_data.get('subnet_id'), form_data.get('asset_id'), form_data.get('notes')))
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', '/logistics/ipam'); self.end_headers()

    def handle_add_software(self):
        form_data, _ = self.parse_post_data()
        conn = get_db_connection()
        conn.execute("INSERT INTO SoftwareLicenses (Name, LicenseKey, PurchaseDate, ExpiryDate, Seats, VendorID) VALUES (?, ?, ?, ?, ?, ?)",
                       (form_data.get('name'), form_data.get('license_key'), form_data.get('purchase_date'), form_data.get('expiry_date'), form_data.get('seats'), form_data.get('vendor_id')))
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', '/logistics/software'); self.end_headers()

    def handle_add_vendor(self):
        form_data, _ = self.parse_post_data()
        conn = get_db_connection()
        conn.execute("INSERT INTO Vendors (Name, Website, SupportContact) VALUES (?, ?, ?)",
                       (form_data.get('name'), form_data.get('website'), form_data.get('support_contact')))
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', '/logistics/vendors'); self.end_headers()

    def handle_add_tag(self):
        form_data, _ = self.parse_post_data()
        conn = get_db_connection()
        conn.execute("INSERT INTO Tags (TagName, TagColor) VALUES (?, ?)", (form_data.get('name'), form_data.get('color')))
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', '/logistics/tags'); self.end_headers()

    def generate_unassigned_asset_numbers(self, count=1):
        conn = get_db_connection()
        settings = {row['SettingKey']: row['SettingValue'] for row in conn.execute("SELECT * FROM Settings").fetchall()}
        asset_prefix = settings.get('asset_prefix', 'VTR')
        
        prefix = f"{asset_prefix}-{datetime.date.today().year}"
        last_asset = conn.execute(f"SELECT AssetNumber FROM Assets WHERE AssetNumber LIKE '{prefix}-%' ORDER BY AssetNumber DESC LIMIT 1").fetchone()
        conn.close()
        
        start_num = 1
        
        if last_asset:
            try:
                start_num = int(last_asset['AssetNumber'].split('-')[-1]) + 1
            except (IndexError, ValueError):
                start_num = 1
        
        return [f"{prefix}-{i:04d}" for i in range(start_num, start_num + count)]
        
    def handle_add_maintenance(self, asset_id):
        form_data, _ = self.parse_post_data()
        conn = get_db_connection()
        cost = form_data.get('cost')
        cost = float(cost) if cost else None
        conn.execute("INSERT INTO Maintenance (AssetID, Date, Type, Notes, Cost) VALUES (?, ?, ?, ?, ?)",
                       (asset_id, form_data.get('date'), form_data.get('type'), form_data.get('notes'), cost))
        log_asset(conn, asset_id, 'System', 'Maintenance Log Added', f"Type: {form_data.get('type')}")
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', f'/edit/{asset_id}'); self.end_headers()

    def handle_delete_maintenance(self, maintenance_id):
        conn = get_db_connection()
        asset_id = conn.execute("SELECT AssetID FROM Maintenance WHERE MaintenanceID = ?", (maintenance_id,)).fetchone()['AssetID']
        conn.execute("DELETE FROM Maintenance WHERE MaintenanceID = ?", (maintenance_id,))
        log_asset(conn, asset_id, 'System', 'Maintenance Log Deleted')
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', f'/edit/{asset_id}'); self.end_headers()

    def handle_add_attachment(self, asset_id):
        form_data, file_data = self.parse_post_data()
        attachment = file_data.get('attachment')
        if not attachment:
            self.send_html_response(400, "No file uploaded.")
            return

        # Sanitize filename
        filename = re.sub(r'[^a-zA-Z0-9_.-]', '_', attachment['filename'])
        timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
        stored_filename = f"{asset_id}_{timestamp}_{filename}"
        stored_path = os.path.join(ATTACHMENTS_PATH, stored_filename)

        with open(stored_path, 'wb') as f:
            f.write(attachment['content'])

        conn = get_db_connection()
        conn.execute("INSERT INTO AssetAttachments (AssetID, FileName, StoredPath, UploadDate) VALUES (?, ?, ?, ?)",
                       (asset_id, filename, stored_path, datetime.date.today().isoformat()))
        log_asset(conn, asset_id, 'System', 'Attachment Added', filename)
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', f'/edit/{asset_id}'); self.end_headers()

    def handle_delete_attachment(self, attachment_id):
        conn = get_db_connection()
        attachment = conn.execute("SELECT AssetID, StoredPath, FileName FROM AssetAttachments WHERE AttachmentID = ?", (attachment_id,)).fetchone()
        if attachment:
            asset_id = attachment['AssetID']
            if os.path.exists(attachment['StoredPath']):
                os.remove(attachment['StoredPath'])
            conn.execute("DELETE FROM AssetAttachments WHERE AttachmentID = ?", (attachment_id,))
            log_asset(conn, asset_id, 'System', 'Attachment Deleted', attachment['FileName'])
            conn.commit()
            conn.close()
            self.send_response(303); self.send_header('Location', f'/edit/{asset_id}'); self.end_headers()
        else:
            conn.close()
            self.send_error(404, "Attachment not found")

    def handle_assign_software(self, asset_id):
        form_data, _ = self.parse_post_data()
        license_id = form_data.get('license_id')
        if license_id:
            conn = get_db_connection()
            conn.execute("INSERT OR IGNORE INTO AssetSoftware (AssetID, LicenseID) VALUES (?, ?)", (asset_id, license_id))
            conn.commit()
            conn.close()
        self.send_response(303); self.send_header('Location', f'/edit/{asset_id}'); self.end_headers()

    def handle_unassign_software(self, asset_id):
        form_data, _ = self.parse_post_data()
        license_id = form_data.get('license_id')
        if license_id:
            conn = get_db_connection()
            conn.execute("DELETE FROM AssetSoftware WHERE AssetID = ? AND LicenseID = ?", (asset_id, license_id))
            conn.commit()
            conn.close()
        self.send_response(303); self.send_header('Location', f'/edit/{asset_id}'); self.end_headers()

    def handle_assign_tag(self, asset_id):
        form_data, _ = self.parse_post_data()
        tag_id = form_data.get('tag_id')
        if tag_id:
            conn = get_db_connection()
            conn.execute("INSERT OR IGNORE INTO AssetTags (AssetID, TagID) VALUES (?, ?)", (asset_id, tag_id))
            conn.commit()
            conn.close()
        self.send_response(303); self.send_header('Location', f'/edit/{asset_id}'); self.end_headers()

    def handle_unassign_tag(self, asset_id):
        form_data, _ = self.parse_post_data()
        tag_id = form_data.get('tag_id')
        if tag_id:
            conn = get_db_connection()
            conn.execute("DELETE FROM AssetTags WHERE AssetID = ? AND TagID = ?", (asset_id, tag_id))
            conn.commit()
            conn.close()
        self.send_response(303); self.send_header('Location', f'/edit/{asset_id}'); self.end_headers()

    def handle_import_csv(self):
        _, file_data = self.parse_post_data()
        csv_file = file_data.get('csv_file')
        if not csv_file:
            self.send_html_response(400, "No CSV file uploaded.")
            return
        
        try:
            content = csv_file['content'].decode('utf-8').splitlines()
            reader = csv.DictReader(content)
            conn = get_db_connection()
            for row in reader:
                asset_number = row.get('AssetNumber') or self.generate_unassigned_asset_numbers(1)[0]
                conn.execute("""
                    INSERT INTO Assets (AssetNumber, Name, Category, PurchaseDate, Cost, Manufacturer, Model, SerialNumber, Location)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    asset_number, row.get('Name'), row.get('Category'), row.get('PurchaseDate'),
                    row.get('Cost'), row.get('Manufacturer'), row.get('Model'), row.get('SerialNumber'), row.get('Location')
                ))
            conn.commit()
            conn.close()
        except Exception as e:
            self.send_html_response(500, f"Error processing CSV: {e}")
            return
        self.send_response(303); self.send_header('Location', '/'); self.end_headers()

    def handle_export_csv(self):
        conn = get_db_connection()
        assets = conn.execute("SELECT * FROM Assets WHERE IsArchived = 0").fetchall()
        conn.close()

        output = io.StringIO()
        if not assets:
            output.write("No assets to export.")
        else:
            writer = csv.writer(output)
            writer.writerow(assets[0].keys()) # Header row
            for asset in assets:
                writer.writerow(asset)

        self.send_response(200)
        self.send_header('Content-type', 'text/csv')
        self.send_header('Content-Disposition', 'attachment; filename=asset_export.csv')
        self.end_headers()
        self.wfile.write(output.getvalue().encode('utf-8'))

    def handle_archive(self, asset_id):
        conn = get_db_connection()
        conn.execute("UPDATE Assets SET IsArchived = 1 WHERE AssetID = ?", (asset_id,))
        log_asset(conn, asset_id, 'System', 'Asset Archived')
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', '/'); self.end_headers()

    def handle_restore_asset(self, asset_id):
        conn = get_db_connection()
        conn.execute("UPDATE Assets SET IsArchived = 0 WHERE AssetID = ?", (asset_id,))
        log_asset(conn, asset_id, 'System', 'Asset Restored')
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', '/archived'); self.end_headers()

    def handle_bulk_action(self):
        form_data, _ = self.parse_post_data()
        action = form_data.get('action')
        asset_ids = form_data.get('asset_ids', [])
        if not isinstance(asset_ids, list): asset_ids = [asset_ids]

        if not action or not asset_ids:
            self.send_html_response(400, "No action or assets selected.")
            return

        conn = get_db_connection()
        for asset_id in asset_ids:
            if action == 'archive':
                conn.execute("UPDATE Assets SET IsArchived = 1 WHERE AssetID = ?", (asset_id,))
                log_asset(conn, asset_id, 'System', 'Bulk Archived')
            elif action == 'checkout':
                conn.execute("UPDATE Assets SET Status = 'Checked Out', CheckedOutTo = 'Bulk Action' WHERE AssetID = ?", (asset_id,))
                log_asset(conn, asset_id, 'System', 'Bulk Checked Out')
            elif action == 'checkin':
                conn.execute("UPDATE Assets SET Status = 'Checked In', CheckedOutTo = NULL WHERE AssetID = ?", (asset_id,))
                log_asset(conn, asset_id, 'System', 'Bulk Checked In')
        conn.commit()
        conn.close()
        self.send_response(303); self.send_header('Location', '/'); self.end_headers()

# --- MAIN EXECUTION ---
if __name__ == "__main__":
    try:
        port = WEB_PORT
        if len(sys.argv) > 1:
            try: port = int(sys.argv[1])
            except ValueError: print(f"Invalid port '{sys.argv[1]}'. Using default {WEB_PORT}.")
        
        initialize_database()
        parse_oui_file() # Pre-load the OUI cache on startup
        
        server_address = ('0.0.0.0', port)
        httpd = HTTPServer(server_address, WebRequestHandler)
        url = f"http://{ 'asset.manager.local' }:{port}"
        print(f"Starting web server at {url}")
        
        def open_browser():
            webbrowser.open(url)
        threading.Timer(1, open_browser).start()
        
        httpd.serve_forever()

    except Exception as e:
        print("!!! FATAL ERROR ON STARTUP !!!")
        print(str(e))
        input("Press Enter to exit...")

    finally:
        try:
            if 'httpd' in locals() and httpd:
                httpd.server_close()
            print("Server stopped.")
        except:
            pass
"@

    # 5. Find an available port, starting with 8080.
    $port = 8080
    while (-not (Test-PortAvailability -Port $port)) {
        $port++
    }
    Write-Host "Using available port: $port" -ForegroundColor Green

    # 6. Check if the Python script needs to be updated.
    $embeddedScriptHash = Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($pythonScript))) -Algorithm SHA256
    $onDiskScriptHash = if (Test-Path $pythonScriptPath) { Get-FileHash -Path $pythonScriptPath -Algorithm SHA256 } else { $null }

    if ($embeddedScriptHash.Hash -ne $onDiskScriptHash.Hash) {
        Write-Host "Python script has changed. Updating file on disk..." -ForegroundColor Yellow
        $pythonScript | Set-Content -Path $pythonScriptPath -Encoding UTF8
    } else {
        Write-Host "Python script is up-to-date. Launching directly." -ForegroundColor Green
    }

    # 7. Launch the Python web server in its permanent directory.
    Write-Host "Launching AssetManager Pro Web Server..." -ForegroundColor Cyan
    $processArgs = @{
        FilePath         = "python.exe"
        ArgumentList     = "-u `"$pythonScriptPath`" $port"
        NoNewWindow      = $true
        PassThru         = $true
        WorkingDirectory = $appDataPath
    }
    $pythonProcess = Start-Process @processArgs
    
    # 8. Wait for the user to stop the server.
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Green
    Write-Host "  Elite Asset Management Suite is RUNNING."
    Write-Host "  Access it at: http://$webDomain`:$port"
    Write-Host "  PRESS ENTER IN THIS WINDOW TO STOP THE SERVER." -ForegroundColor Yellow
    Write-Host "-----------------------------------------------------------------"

    Read-Host
}
catch {
    # Display any errors that occurred during the process in a clear format.
    Write-Host "An error occurred:" -ForegroundColor Red
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Script Error", "OK", "Error") | Out-Null
    Write-Host $_.Exception.Message -ForegroundColor Red
}
finally {
    # This block runs regardless of whether an error occurred or not.
    if ($pythonProcess -ne $null -and (-not $pythonProcess.HasExited)) {
        Write-Host "Stopping the Python web server..."
        $pythonProcess | Stop-Process -Force
        Write-Host "Server stopped."
    }

    # The python script is now permanent, so we no longer delete it here.
    Write-Host "Script finished. Press Enter to exit."
    Read-Host
}