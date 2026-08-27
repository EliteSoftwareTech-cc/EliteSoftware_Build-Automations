# Elite Clipboard Image Saver - Changelog

All notable changes to this project during this development cycle will be documented in this file.

## [1.2.0.0] - Active Development

### Added
- **GUI Migration:** Complete overhaul from a background script to a full WinForms GUI adhering to the EliteSoftware legacy aesthetic standards.
- **Dynamic Theming:** Implemented `Get-GradientBmp` allowing users to switch the banner and dialog color themes dynamically (Classic Silver, Vista Teal, Steel Blue) via the new `Settings` menu bar.
- **Window Opacity Controls:** Users can now set the main application window opacity (100%, 90%, 80%) via the `Settings` menu.
- **Help & About Dialogs:** Added native Win32 dialogs for "User Manual" and "About" matching the `PsExec64-Launcher.ps1` template, including proper 3D borders, gradients, and icon implementation.
- **Dedicated Log Viewer:** Added a separate GUI window for viewing runtime system logs, launchable via the tray menu.
- **Hidden Launch Parameter:** Added `-Hidden` switch to the entry script to allow shortcuts/compiled versions to launch silently into the system tray without showing the main GUI.
- **Progress Bar Integration:** Reintroduced the progress bar on the Control tab to visualize monitoring activity (toggles between Marquee and Blocks depending on state).
- **Extensive Configuration Controls:** The Settings tab now includes dedicated inputs for:
  - Save Directory Selection
  - Hotkey modification (Modifier + Key)
  - Mute Save Sound toggle
  - Show Balloon Tips toggle
  - Supported Extension management (.png, .jpg, etc.)
  - Always On Top configuration
  - Custom Sound File Selection
- **Raw Configuration Editor:** Added a tab containing a raw text editor for the `config.json` file allowing advanced editing, saving, and reverting of configuration variables.
- **Action Verbs in Tray Menu:** Context menu items dynamically change verbiage to indicate the action they will perform (e.g., "Disable Logging" or "Enable Hotkey").

### Changed
- **Z-Order Clipping Fix:** Repaired a severe docking calculation bug where the main TabControl was bleeding off the right and bottom edges of the screen by correcting the `BringToFront()` and `SendToBack()` order.
- **Visual Button Overhaul:** Forced all standard buttons (`Okay`, `Apply`, `Exit`, etc.) to use native `UseVisualStyleBackColor = $true` dropping any custom backfills per the development guidelines.
- **Tray Icon Functionality:** Double-clicking the notification tray icon now correctly summons the main Settings GUI instead of the activity log window.
- **Status Bar Positioning:** Explicitly shifted the status bar to anchor itself correctly at the absolute bottom beneath the "chin".
- **Dynamic Icons:** Upgraded logic to correctly pull icons dynamically based on the executable/script name and apply them uniformly across the Taskbar, Titlebar, and UI Banners.
- **Default State:** Changed default configuration so Monitoring/Saving is instantly active "out of the box" upon launch.

### Fixed
- Fixed an issue where the activity log output text box was cut off.
- Repaired the balloon tip integration to fire correctly when an image is saved (if enabled in settings).
- Corrected issues where background clipboard polling thread logic was omitted during the GUI merging phase.
