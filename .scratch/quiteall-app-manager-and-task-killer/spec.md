# QuiteAll: Lightweight macOS Application Manager and Task Killer

Status: ready-for-agent

## Problem Statement

macOS users running multiple demanding desktop applications (such as Xcode, Chrome, Docker, IDEs, and creative suites) frequently experience system slowdowns, high fan noise, and depleted battery life caused by accumulating background processes and idle applications. While the built-in macOS "Force Quit Applications" dialog (`⌥⌘Esc`) provides basic termination, it lacks bulk operations, selective quitting, background process filtering, application protection safeguards, and resource visibility. Existing legacy utilities such as QuitAll 1.3.6 rely on dated 2019 AppKit Nib architectures, heavy Objective-C runtime wrappers, third-party telemetry frameworks (Microsoft AppCenter), and Setapp DRM hooks, resulting in sluggish startup times and unnecessary memory overhead.

Users require a fast, clean, native macOS menu bar utility built in pure Swift 6 and SwiftUI that provides immediate one-click "Quit All" and "Force Quit All", live search and selection, protected app whitelisting to safeguard crucial tools (like Finder or playing music), and granular process management directly from the menu bar.

## Solution

A lightning-fast, zero-bloat menu bar application and task manager for macOS:

1. **Compact Menu Bar HUD & Reactive App Discovery**: A streamlined popover anchored to the macOS menu bar displaying all running user applications with genuine app icons, process names, selection checkboxes, and live count badges.
2. **Multi-Action Process Termination Engine**: Instant one-click "Quit All" and "Quit Selected" via standard graceful Cocoa termination (`NSRunningApplication.terminate()`), with automatic reactive switching to immediate hard termination (`kill(pid, SIGKILL)`) when holding the `Option` (`⌥`) modifier key.
3. **App Protection & Whitelisting**: Protection toggle allowing users to shield essential utilities, Finder, Dock, and media applications (Spotify, Apple Music) from accidental termination during "Quit All" sweeps.
4. **Fuzzy Search & Fast Keyboard Control**: Real-time app filtering with keyboard shortcuts (`↑`/`↓` row navigation, `Space` toggle selection, `Esc` dismiss) and global Carbon event hotkeys (`⌥⌘Q` toggle HUD, `⌥⇧⌘Q` Force Quit All).
5. **Inactivity Watchdog & Auto-Quit Service**: Configurable background timer monitoring idle applications and automatically closing unneeded apps after designated periods of inactivity.
6. **Native Preferences & Launch at Login**: Modern macOS Settings interface for configuring protected apps, auto-quit intervals, sound/haptic feedback, and modern `SMAppService` launch-at-login integration.

## User Stories

1. As a macOS user, I want to click an icon in the macOS menu bar to immediately view a clean list of all currently active applications.
2. As a macOS user, I want to see a live badge count on the menu bar icon showing how many user applications are currently running.
3. As a user with too many apps open, I want to click a large, prominent "Quit All" button at the top of the HUD to cleanly close all open applications in a single action.
4. As a power user, I want to hold the `Option` (`⌥`) key while looking at the HUD to see the button dynamically change to "Force Quit All" with instant visual feedback.
5. As a user, I want to select specific individual applications using square checkboxes and click "Quit Selected (N)" to terminate only the chosen apps.
6. As a user with protected tools (like my browser or music player), I want to shield specific applications so they are never closed when I trigger "Quit All".
7. As a user, I want critical system services (such as Finder, Dock, and Control Center) to be protected by default to prevent accidental system disruption.
8. As a user playing background music on Spotify or Apple Music, I want the app to detect media playback and protect the music app from quitting.
9. As a user managing high-resource tasks, I want to open an options menu (`•••`) on any app row to access "Quit Others" (closing everything except the active app), "Relaunch App", or "Reveal in Finder".
10. As a keyboard-centric developer, I want to press `⌥⌘Q` from anywhere in macOS to toggle the QuiteAll menu bar HUD without touching the trackpad.
11. As a keyboard-centric developer, I want to use `↑` and `↓` arrow keys to highlight app rows and `Space` to toggle row selection.
12. As a user working on battery power, I want an automatic Inactivity Watchdog that detects when an app has been idle for 15, 30, or 60 minutes and terminates it automatically.
13. As a user, I want to hear crisp audio feedback and feel trackpad haptic confirmation when apps are successfully terminated.
14. As a user, I want QuiteAll to launch automatically at login via modern macOS `SMAppService` without requiring legacy helper bundles.
15. As a privacy-conscious user, I want QuiteAll to operate completely offline with zero telemetry, analytics, or background internet access.
16. As a user on macOS Sequoia, I want the popover interface to use native glassmorphic styling (`.ultraThinMaterial`) and responsive SF Symbols that blend seamlessly into the operating system.

## Implementation Decisions

### 1. Unified State & Application Discovery (`AppState`, `AppItem`, `AppManager`)
- `AppState` acts as the single source of truth for all reactive UI bindings, holding `apps: [AppItem]`, search query, selection states, and protected bundle identifiers.
- Process polling leverages `NSWorkspace.shared.runningApplications` filtered for regular GUI apps (`.regular`), with optional user toggle for accessory/helper processes (`.accessory`).
- Option-key monitoring uses a local `NSEvent.addLocalMonitorForEvents(matching: .flagsChanged)` to reactively update button titles and force-quit state without polling.

### 2. Process Termination & Force-Quit Mechanics
- Standard termination invokes `app.runningApp?.terminate()`.
- Force-quit termination sends `SIGKILL` directly via Darwin `kill(pid_t, SIGKILL)` or `runningApp?.forceTerminate()`.
- "Quit Others" queries `NSWorkspace.shared.frontmostApplication` and terminates all other quitable processes.
- "Relaunch" initiates termination followed by `NSWorkspace.shared.openApplication(at:configuration:)`.

### 3. Popover Window Controller (`StatusBarController`)
- Uses standard `NSPopover` with `.transient` behavior attached to `NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)`.
- When opened, activates keyboard focus and monitors global mouse clicks outside the popover frame to dismiss cleanly.

### 4. Audio & Haptics Service (`SoundService`)
- Audio playback utilizes system sound files (`quit-single.aiff`, `quit-all.aiff`) bundled in `Resources/Sounds/`.
- Haptic feedback utilizes `NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)`.

### 5. Inactivity Watchdog (`InactivityWatchdog`)
- Background timer periodically evaluates running applications against user-configured threshold in minutes.
- Evaluates activity based on window presence and process activity before dispatching graceful termination.

## Testing Decisions

### What Makes a Good Test
- Tests must verify external behavioral contracts, data models, filtering rules, and state transformations rather than private implementation details.
- Validating that default protection lists include Finder and Dock.
- Validating that selecting all items never selects protected applications.
- Validating that RAM formatting converts bytes into human-readable strings (MB/GB).
- Validating that filter categories, sort options, and policy transitions produce expected collections.

### Proposed Testing Seams

1. **State & Policy Invariant Seam (Highest Model/State Seam)**:
   - Test `AppState` selection, select-all behavior, protection toggles, and memory calculations.
   - Assert protected apps remain unselected and quitable count matches expectations.
   - Prior art: `Tests/QuiteAllTests/QuiteAllTests.swift`.

2. **Process Monitoring Seam (Highest System Service Seam)**:
   - Test `ProcessMonitor` for valid PID metrics and zero metrics for non-existent PIDs.
   - Assert safe memory query without crashing on terminated processes.
   - Prior art: `Tests/QuiteAllTests/QuiteAllTests.swift`.

3. **Termination & Selection Contract Seam (Highest Action Seam)**:
   - Verify selection and bulk action filters correctly isolate target processes.

## Out of Scope

- Kernel extension (KEXT) or system extension process injection.
- Windows or Linux cross-platform compilation (macOS 13+ only).
- Cloud synchronization or external account registration.
- Third-party analytics or crash reporting SDKs.

## Further Notes

- Built with pure Swift 6 and standard SwiftUI / AppKit APIs with zero third-party dependencies.
- Build and bundle packaging is managed via `swift build` and `scripts/build_app.sh`.
