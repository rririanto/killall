<div align="center">

# ⚡ QuiteAll

**The modern, lightning-fast app manager & task killer for macOS.**  
*Crafted in pure Swift 6 and SwiftUI. Zero telemetry, zero bloat, instant response.*

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple)](https://apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Apple%20Silicon%20%7C%20Intel-lightgrey)](https://apple.com)
[![CI](https://github.com/rririanto/quiteall/actions/workflows/ci.yml/badge.svg)](https://github.com/rririanto/quiteall/actions)

<p align="center">
  <img src="https://raw.githubusercontent.com/rririanto/quiteall/main/Resources/AppIcon.icns" alt="QuiteAll Icon" width="128" height="128" />
</p>

</div>

---

## 🌟 Highlights

- **⚡ Blazing Fast & Ultra Lightweight**: Instant startup (<50ms) and minimal RAM footprint (<15MB). No electron, no webviews, no background CPU drain.
- **🛡️ Intelligent App Shielding**: 1-click protection for critical apps. Core macOS services (Finder, Dock, Control Center) are permanently shielded against accidental termination.
- **🎵 Smart Media Protection**: Automatically detects active playback in Spotify, Apple Music, and other media players to prevent interrupting your tunes.
- **⚡ Reactive Multi-Action Quitting**:
  - Graceful Quit (`SIGTERM`)
  - Instant Force Quit (`SIGKILL`) with `Option` key modifier
  - **Quit Others** (quits everything while preserving your current frontmost app)
  - **Relaunch / Restart** buggy applications with a single click or shortcut
- **📊 Real-Time Process Telemetry**: Accurate, live CPU% and Resident Memory gauges measured directly via Darwin kernel `libproc` (`proc_pidinfo`).
- **✨ Live Memory Reclamation**: Visual feedback showcasing exact RAM freed upon closing apps (e.g. *"✨ Reclaimed 1.8 GB RAM"*).
- **⏳ Inactivity Watchdog**: Configurable automated timer that terminates idle background apps after 15, 30, 45, or 60+ minutes to conserve battery life.
- **⌨️ Universal Keyboard Workflow**: Complete HUD keyboard navigation (`↑`/`↓`, `Space`, `R`, `Esc`) plus global Carbon event hotkeys (`⌥⌘Q`, `⌥⇧⌘Q`, `⌥⌘O`).
- **🎛️ Audio & Haptic Feedback**: Crisp synthesized audio cues and Taptic trackpad confirmations (`NSHapticFeedbackManager`).
- **🚀 Modern Launch at Login**: Built with modern macOS `SMAppService` — zero legacy helper daemons or privileged helpers.

---

## ⌨️ Keyboard Shortcuts Reference

### Global Shortcuts (Anywhere in macOS)

| Shortcut | Action | Description |
|---|---|---|
| `⌥ ⌘ Q` | **Toggle QuiteAll HUD** | Instant popover access from any active application |
| `⌥ ⇧ ⌘ Q` | **Force Quit All** | Immediately terminates all non-protected apps with `SIGKILL` |
| `⌥ ⌘ O` | **Quit Others** | Terminates all other apps while keeping your current frontmost app active |

### In-HUD Keyboard Navigation

| Key | Action |
|---|---|
| `↑` / `↓` | Navigate selected row in application list |
| `Space` | Toggle selection checkbox of the highlighted app |
| `⌥` *(Hold Option)* | Instantly transforms all buttons into **⚡ Force Quit** |
| `Return` / `Enter` | Trigger Quit / Force Quit action for selection |
| `R` | Relaunch / restart highlighted app |
| `Esc` | Clear search input, or dismiss HUD |

---

## 🏗 Architecture & Code Structure

```
quiteall/
├── Package.swift                  # Swift Package Manager manifest
├── QuiteAll.app/                  # Standalone macOS Application Bundle
├── Resources/
│   ├── Info.plist                 # LSUIElement menu-bar metadata
│   ├── AppIcon.icns               # Clean custom application icon
│   └── Sounds/                    # Synthesized audio effects
├── Sources/QuiteAll/
│   ├── Main.swift                 # App bootstrap
│   ├── AppDelegate.swift          # NSApplicationDelegate & accessory activation policy
│   ├── Models/
│   │   ├── AppItem.swift          # Live application model (PID, CPU, RAM, BundleID)
│   │   ├── AppPolicy.swift        # App execution policy enum
│   │   ├── FilterCategory.swift   # Category filter chips (All, Dock, Background, etc.)
│   │   └── SortOption.swift       # Name, CPU, RAM, Recent sorting models
│   ├── Services/
│   │   ├── ProcessMonitor.swift   # libproc wrapper for exact thread/CPU and RSS metrics
│   │   ├── AppManager.swift       # Process termination, signal handling, and relaunch logic
│   │   ├── InactivityWatchdog.swift # Automated idle background process monitor
│   │   ├── SmartMediaDetector.swift # Active audio playback detection
│   │   ├── SoundService.swift     # Audio synthesis & NSHapticFeedbackManager
│   │   ├── HotKeyManager.swift    # Carbon Event RegisterEventHotKey bridge
│   │   └── LaunchAtLogin.swift    # Modern ServiceManagement SMAppService integration
│   ├── State/
│   │   └── AppState.swift         # Unified observable state & reactive modifier monitors
│   ├── Views/
│   │   ├── MenuBarHUDView.swift   # Glassmorphic floating popover HUD
│   │   ├── AppRowView.swift       # Dynamic interactive application row
│   │   ├── FilterBarView.swift    # Category pill filter bar
│   │   └── PreferencesView.swift  # Multi-tab settings panel (General, Protected, Auto-Quit, etc.)
│   └── Window/
│       ├── StatusBarController.swift # NSStatusItem & popover coordinator
│       └── FloatingHUDWindow.swift   # Non-activating panel window
└── Tests/QuiteAllTests/
    └── QuiteAllTests.swift        # Comprehensive test suite (31 automated unit tests)
```

---

## 🛠 Building & Installation

### Requirements
- macOS 13.0 (Ventura), 14.0 (Sonoma), 15.0 (Sequoia) or newer
- Xcode 15+ / Swift 5.9+ toolchain

### Running Locally with SwiftPM:
```bash
git clone https://github.com/rririanto/quiteall.git
cd quiteall
swift run
```

### Running the Test Suite:
```bash
swift test
```

### Packaging Standalone `.app`:
```bash
./scripts/build_app.sh
```

To install permanently:
```bash
cp -R QuiteAll.app /Applications/
open /Applications/QuiteAll.app
```

---

## ⚖️ Legal & Trademark Disclaimer

QuiteAll is an independent, original, open-source project written from scratch in Swift and SwiftUI.

- QuiteAll is **NOT** affiliated, associated, authorized, endorsed by, or in any way officially connected with *QuitAll* or its creators.
- All product names, logos, trademarks, and registered trademarks mentioned are property of their respective owners. Their use does not imply any affiliation or endorsement.
- All code, audio effects, and graphical assets included in this repository are 100% original and distributed under the permissive MIT License.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
