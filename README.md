# 🚀 QuiteAll (v2.0)

> **The ultimate, lightning-fast app manager & task killer for macOS.**  
> Reverse engineered from QuitAll with REA and reimagined in pure Swift 6 + SwiftUI.

---

## ⚡ Why QuiteAll is Far Better than QuitAll

| Feature | Original QuitAll 1.3.6 | **QuiteAll 2.0** |
|---|---|---|
| **Technology** | 2019 AppKit Storyboards, Objective-C wrappers, Microsoft AppCenter telemetry, PLCrashReporter, Setapp DRM | **Pure Swift 6 + SwiftUI**, zero telemetry, zero bloat, instant startup (<50ms), minimal RAM footprint (<15MB) |
| **Interface** | Rigid fixed-frame nib views, dated styling | **Modern Glassmorphic HUD** (`.ultraThinMaterial`), dynamic SF Symbols 6, smooth spring transitions, macOS Sequoia aesthetics |
| **Quitting Actions** | Single Quit or Quit All | **Multi-Action Power**: Quit, Force Quit (holding `⌥`), **Quit Others** (keep active app), **Relaunch / Restart App** |
| **RAM & CPU Metrics** | Static label | **Real-time animated resource gauges** via direct `proc_pidinfo` with instant color-coded CPU alerts |
| **Memory Reclaim Gauge** | None | **Live Memory Reclaim Toast**: *"✨ Reclaimed 2.4 GB RAM"* |
| **Search & Filtering** | Basic slow search | **Instant Fuzzy Search** + Smart category chips: **All**, **Dock Apps**, **Background / Helpers**, **High Usage**, **Protected** |
| **Protection / Whitelist** | Hidden inside cell popup menus | **1-Click Shield Toggle** right on every row + dedicated Protected Apps manager with smart media auto-detection (Spotify, Apple Music) |
| **Auto-Quit Inactivity** | Clunky background timer | **Inactivity Watchdog**: Automatically closes idle background apps after user-configured minutes |
| **Keyboard Navigation** | None | **Full keyboard workflow**: `↑`/`↓` navigate, `Space` toggle select, `⌥` hold for Force Quit, `R` restart, `Esc` dismiss |
| **Global Shortcuts** | Fixed hotkeys | Carbon Event hotkeys: `⌥⌘Q` toggle HUD, `⌥⇧⌘Q` Force Quit All, `⌥⌘O` Quit Others |
| **Audio & Haptics** | Static audio clips only | **Trackpad Haptic Feedback** (`NSHapticFeedbackManager`) + short audio feedback |
| **Launch at Login** | Deprecated login item helper | Modern macOS 13+ **`SMAppService.mainApp`** integration |

---

## 🏗 Project Architecture

```
quiteall/
├── Package.swift                  # Swift Package Manager definition
├── QuiteAll.app/                  # Ready-to-run macOS Application Bundle
├── Resources/
│   ├── Info.plist                 # Bundle metadata & LSUIElement flag
│   ├── AppIcon.icns               # Application icon
│   └── Sounds/                    # Crisp sound effects (quit, quit-all)
├── Sources/QuiteAll/
│   ├── Main.swift                 # Application entry point
│   ├── AppDelegate.swift          # Lifecycle & NSApp.setActivationPolicy(.accessory)
│   ├── Models/
│   │   ├── AppItem.swift          # Rich app model with live PID, CPU, RAM metrics
│   │   ├── AppPolicy.swift        # Standard, Protected, AlwaysQuit policies
│   │   ├── FilterCategory.swift   # Filter pills (All, Dock, Background, Resource Hogs, Protected)
│   │   └── SortOption.swift       # Name, CPU, RAM, and Launch time sorting
│   ├── Services/
│   │   ├── ProcessMonitor.swift   # Darwin proc_pidinfo reader for CPU% and RAM
│   │   ├── AppManager.swift       # Process termination, relaunch, and AppleScript bridge
│   │   ├── InactivityWatchdog.swift # Automatic idle app termination service
│   │   ├── SoundService.swift     # Audio synthesis & trackpad haptics
│   │   ├── HotKeyManager.swift    # Global Carbon event hotkeys
│   │   └── LaunchAtLogin.swift    # ServiceManagement SMAppService integration
│   ├── State/
│   │   └── AppState.swift         # Unified observable state & reactive option-key monitor
│   ├── Views/
│   │   ├── MenuBarHUDView.swift   # Glassmorphic floating menu bar panel
│   │   ├── AppRowView.swift       # Interactive row with dynamic force-quit & relaunch
│   │   ├── FilterBarView.swift    # Filter pill chips with live counters
│   │   ├── SummaryBannerView.swift # Memory reclamation notification banner
│   │   ├── PreferencesView.swift  # Complete Settings window
│   │   └── Components/
│   │       ├── GlassCard.swift    # macOS vibrancy modifier
│   │       └── ResourceGauge.swift# Micro-gauges for CPU% and RAM
│   └── Window/
│       ├── FloatingHUDWindow.swift# Custom floating non-activating NSPanel
│       └── StatusBarController.swift # NSStatusItem & screen placement coordinator
└── scripts/
    └── build_app.sh               # Builds release binary and bundles QuiteAll.app
```

---

## ⌨️ Shortcuts Reference

| Shortcut | Scope | Action |
|---|---|---|
| `⌥ ⌘ Q` | Global | Toggle QuiteAll Menu Bar HUD |
| `⌥ ⇧ ⌘ Q` | Global | Force Quit All eligible apps |
| `⌥` (Hold Option) | In HUD | Instantly transforms all Quit buttons into **⚡ Force Quit** |
| `Space` | In HUD | Toggle selection of highlighted app |
| `R` | In HUD | Relaunch / restart selected app |
| `Esc` | In HUD | Close HUD |

---

## 🛠 Building & Installing

### Run locally via Swift Package Manager:
```bash
swift run
```

### Build & package the standalone `QuiteAll.app`:
```bash
./scripts/build_app.sh
```

### Install to `/Applications`:
```bash
cp -R QuiteAll.app /Applications/
open /Applications/QuiteAll.app
```
