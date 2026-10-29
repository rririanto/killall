# 01: Menu Bar HUD Interface and Native App Discovery

**What to build:**
A streamlined macOS menu bar status item and popover interface that discovers running GUI applications, renders crisp application icons, process names, and selection checkboxes, and provides instant fuzzy search and live running app count badges. Users can open the HUD with a single click, see all running applications instantly, filter the list by typing in the search bar, and select or deselect all quitable items with a single click.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [x] Status bar item displays a clean menu bar icon with optional running application count badge.
- [x] Popover HUD opens anchored below the status bar item with smooth animation and auto-dismiss on external clicks.
- [x] Running regular applications (`.regular`) are accurately enumerated with genuine high-resolution system icons and process names.
- [x] Real-time search bar filters the application list instantly without lag or dropped keystrokes.
- [x] "Select All" square checkbox toggles selection state across all non-protected applications.
- [x] Automated state tests verify application enumeration, search filtering, and selection toggles.
