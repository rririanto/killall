# 02: Multi-Action Process Termination and Force Quit Engine

**What to build:**
A robust, high-performance process termination engine. Users can click "Quit All" to terminate all open applications in a single click, or select individual apps and click "Quit Selected (N)". Holding the `Option` (`⌥`) key dynamically switches the action button to "Force Quit All" or "Force Quit Selected", bypassing graceful termination and immediately killing unresponsive tasks via `SIGKILL`. Each app row provides an options menu (`•••`) with "Quit Others" (keeping only the frontmost app) and "Relaunch App".

**Blocked by:** 01: Menu Bar HUD Interface and Native App Discovery

**Status:** ready-for-agent

- [ ] Top action button dynamically reflects current selection state ("Quit All" vs "Quit Selected (N)").
- [ ] Holding the `Option` key dynamically updates button styling (red accent) and label to "Force Quit".
- [ ] Standard quitting executes graceful termination (`terminate()`) while force-quitting dispatches direct `SIGKILL`.
- [ ] "Quit Others" accurately preserves the frontmost application while terminating other non-protected apps.
- [ ] "Relaunch App" closes the selected application and re-opens it via system workspace APIs.
- [ ] Automated tests verify termination action dispatch, selection isolation, and state updates.
