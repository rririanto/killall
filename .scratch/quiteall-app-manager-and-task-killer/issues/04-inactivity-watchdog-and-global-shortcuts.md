# 04: Inactivity Watchdog, Carbon Hotkeys, and Preferences Settings

**What to build:**
Automated power management and global keyboard control. An Inactivity Watchdog service monitors background applications and automatically terminates idle apps after a user-configured inactivity threshold (15, 30, or 60 minutes) to conserve battery and CPU. Global Carbon event hotkeys (`⌥⌘Q` to toggle HUD, `⌥⇧⌘Q` to Force Quit All) provide keyboard access from any application. A multi-tab Preferences window enables configuring launch at login (`SMAppService`), audio feedback, and haptic confirmations.

**Blocked by:** 02: Multi-Action Process Termination and Force Quit Engine

**Status:** ready-for-agent

- [ ] Inactivity Watchdog monitors background processes and terminates idle apps exceeding the configured threshold.
- [ ] Global Carbon hotkey `⌥⌘Q` toggles the popover HUD from any application window.
- [ ] Keyboard navigation within the HUD supports `↑`/`↓` row selection, `Space` toggle, and `Esc` dismiss.
- [ ] Audio effects (`quit-single.aiff`, `quit-all.aiff`) and trackpad haptic feedback trigger on successful actions.
- [ ] Preferences window supports General, Protected Apps, Auto-Quit, Shortcuts, and About settings tabs.
- [ ] Modern macOS `SMAppService` handles launch at login without helper processes.
- [ ] Automated tests verify watchdog timer mechanics, settings persistence, and policy constraints.
