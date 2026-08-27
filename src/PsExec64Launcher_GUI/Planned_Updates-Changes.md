[PsExec64-Launcher.ps1](file;file:///s%3A/Projects/PsExec64-Launcher/PsExec64-Launcher.ps1) 

Can you make a backup CAB file of the entire project and save it to the Backups folder 

Then update the app with the following changes:

# - General:   
1. [Complete] Tray Icon should always be visible if program is open not just when minimized. 
2. [Complete] Program should only allow one instance of its self at a time trying to open a new instance will ask user if you want to cancel or close existing one
3. [Complete] When running things with interactive box checked user should not see a console window popup. in fact I dont ever want to see the sysinternals console window from PsExec64 ever. 
4. [Complete] Apply button should be renamed to "Execute"
5. [Complete] Can you make the active area just slightly off-white instead of pure white like literally darker by 1%-1.5% or so
6. [Complete] "Administrator" and other named accounts on system do not populate in the dropdown for "Run As" 
7. [Complete] When minimized to tray force to not go into overflow menu it should stay on the taskbar 
8. can you make it so it does not throw a unhandled exception when a file does not exist or path was typed incorrectly.
9. can you make it so when adding an item to favorites from the main tab it locates that file and populates its directory as the working directory  also the standard default working directory should be System32 like it is in windows normally lol. 

# - Settings Window:  
1. [Complete] the new stay open on exit option is cut off at bottom of ui.  
2. [Complete] The theme changing does not work it stays default with all options nothing changes.  
3. [Complete] Add ability to toggle saving to registry instead of XML File and optionally make the registry save option be able to have user chose between global all users registry location or per user location.

# - Favorites Tab:   
1. [Complete] Outlines around favorites items are not in line with the actual item or the descriptions. The outlines should use the standard windows clear bubble like glass hover and outline effects
2. [Complete] They should be made to fit horizontally regardless of what or how big they are. I never want to see a horizontal scroll  bar ever. While remaining dual Columns 
3. [Complete] I want to be able to right click and edit existing entries 
4. [Complete] There should be a way to customize the Icon displayed for favorites 
5. Allow setting the Run As scope in the pin to Favorites Dialog // allow editing this in the favorites tab as well. 

# - About Dialog Window:   
1. [Complete] The down button and the label for it are clipping and overlapping and its not a native windows button like it should be 
2. [Complete] Information in about window needs to be adjusted as its not very detailed in the right ways