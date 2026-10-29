# 03: App Protection, Shielding, and Smart Media Whitelisting

**What to build:**
Comprehensive protection safeguards preventing accidental termination of critical tools, system services, and background music. Users can toggle the shield icon on any app row to protect it from "Quit All" operations. Essential system services (Finder, Dock, Control Center) are permanently shielded by default. Media apps (Spotify, Apple Music) are automatically detected and protected during active audio playback. A dedicated "Protected Apps" settings tab allows managing custom whitelisted bundle identifiers.

**Blocked by:** 01: Menu Bar HUD Interface and Native App Discovery

**Status:** ready-for-agent

- [ ] Critical system applications (Finder, Dock, Control Center) are shielded by default.
- [ ] Users can toggle protection for any app directly from the row menu (`•••`) or Preferences.
- [ ] Protected apps render a shield icon, disable row checkboxes, and are excluded from "Quit All" / "Select All" actions.
- [ ] Smart media detection identifies running music players (Spotify, Apple Music) and prevents accidental closure.
- [ ] Protected bundle identifiers persist across application restarts.
- [ ] Automated tests verify default protection invariants, persistence, and exclusion from bulk termination.
