/**
 * @file Resource.h
 * @brief Win32 Resource and Control ID definitions for File Splitter GUI.
 * @author EliteSoftwareTech Co.
 */

#pragma once

#ifndef IDC_STATIC
#define IDC_STATIC -1
#endif

// Resource IDs
#define IDI_APPICON             101
#define IDI_BANNER_ICON        102

// Manifest
#ifndef CREATEPROCESS_MANIFEST_RESOURCE_ID
#define CREATEPROCESS_MANIFEST_RESOURCE_ID 1
#endif

// Menu & Command IDs
#define IDM_MAINMENU            200
#define IDM_FILE_OPEN           201
#define IDM_FILE_ADDBATCH        202
#define IDM_FILE_STARTSPLIT     203
#define IDM_FILE_CANCEL         204
#define IDM_FILE_EXIT           205
#define IDM_TOOLS_SETTINGS      210
#define IDM_TOOLS_VIEWLOG       211
#define IDM_TOOLS_CLEARBATCH    212
#define IDM_HELP_DOCUMENTATION  220
#define IDM_HELP_ABOUT          221

// Toolbar Command IDs
#define IDB_TOOLBAR_OPEN        301
#define IDB_TOOLBAR_STARTSPLIT  302
#define IDB_TOOLBAR_CANCEL      303
#define IDB_TOOLBAR_SETTINGS    304
#define IDB_TOOLBAR_VIEWLOG     305
#define IDB_TOOLBAR_HELP        306

// Dialog IDs
#define IDD_ABOUT_DIALOG        400
#define IDD_HELP_DIALOG         401
#define IDD_SETTINGS_DIALOG     402

// Main Window Control IDs
#define IDC_MAIN_TOOLBAR        500
#define IDC_STATUSBAR           501
#define IDC_PROGRESSBAR         502
#define IDC_TXT_FILEPATH        503
#define IDC_BTN_BROWSE          504
#define IDC_RAD_CHARS           505
#define IDC_RAD_LINES           506
#define IDC_TXT_LIMIT           507
#define IDC_SPN_LIMIT           508
#define IDC_CHK_SUBFOLDER       509
#define IDC_LST_BATCHFILES      510
#define IDC_BTN_ADDBATCH        511
#define IDC_BTN_CLEARBATCH      512
#define IDC_BTN_REMOVEBATCH     513
#define IDC_LNK_LOGFILE         514
#define IDC_BTN_OKAY            515
#define IDC_BTN_APPLY           516
#define IDC_BTN_CANCEL          517
#define IDC_BTN_EXIT            518
#define IDC_PIC_BANNERICON      519
#define IDC_LBL_BANNERTITLE     520
#define IDC_LBL_BANNERSUB       521
#define IDC_GRP_SPLITMODE       522
#define IDC_GRP_BATCHQUEUE      523
#define IDC_LBL_FILEPATH        524
#define IDC_LBL_LIMIT           525

// About Dialog Control IDs
#define IDC_ABOUT_BANNER_TITLE  601
#define IDC_ABOUT_BANNER_SUB    602
#define IDC_ABOUT_DETAILS_TXT   603
#define IDC_ABOUT_BTN_EXPAND    604
#define IDC_ABOUT_BTN_OKAY      605
#define IDC_ABOUT_ICON          606
#define IDC_ABOUT_APPNAME       607
#define IDC_ABOUT_VERSION       608
#define IDC_ABOUT_COMPANY       609

// Help Dialog Control IDs
#define IDC_HELP_BANNER_TITLE   701
#define IDC_HELP_BANNER_SUB     702
#define IDC_HELP_CONTENT_TXT    703
#define IDC_HELP_BTN_DONE       704
#define IDC_HELP_ICON           705

// Settings Dialog Control IDs
#define IDC_SETT_RAD_CHARS      801
#define IDC_SETT_RAD_LINES      802
#define IDC_SETT_TXT_CHARLIMIT  803
#define IDC_SETT_TXT_LINELIMIT  804
#define IDC_SETT_CHK_AUTOOPEN   805
#define IDC_SETT_CMB_LOGLEVEL   806
#define IDC_SETT_TXT_PATTERNTXT 807
#define IDC_SETT_BTN_OKAY       808
#define IDC_SETT_BTN_APPLY      809
#define IDC_SETT_BTN_CANCEL     810
#define IDC_SETT_LBL_MODE       811
#define IDC_SETT_LBL_CHARLIMIT  812
#define IDC_SETT_LBL_LINELIMIT  813
#define IDC_SETT_LBL_LOGLEVEL   814
#define IDC_SETT_LBL_PATTERN    815

// Custom Window Messages (WM_USER + N)
#define WM_SPLIT_PROGRESS       (WM_USER + 101)  // WPARAM = percent, LPARAM = ProgressInfo*
#define WM_SPLIT_COMPLETE       (WM_USER + 102)  // WPARAM = success (BOOL), LPARAM = FileSplitResult*
#define WM_SPLIT_ERROR          (WM_USER + 103)  // WPARAM = error code, LPARAM = wchar_t* error str
