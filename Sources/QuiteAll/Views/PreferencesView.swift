import SwiftUI

public struct PreferencesView: View {
    @ObservedObject var state: AppState
    @State private var launchAtLogin: Bool = LaunchAtLogin.shared.isEnabled
    @State private var newBundleIDText: String = ""
    
    public init(state: AppState) {
        self.state = state
    }
    
    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            protectedTab
                .tabItem {
                    Label("Protected Apps", systemImage: "shield.fill")
                }
            
            inactivityTab
                .tabItem {
                    Label("Auto-Quit", systemImage: "timer")
                }
            
            shortcutsTab
                .tabItem {
                    Label("Shortcuts", systemImage: "command")
                }
            
            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 380)
        .padding(16)
    }
    
    // MARK: - General Tab
    private var generalTab: some View {
        Form {
            Section {
                Toggle("Launch QuiteAll automatically at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        LaunchAtLogin.shared.setEnabled(newValue)
                    }
                
                Toggle("Show running app count in menu bar", isOn: $state.showAppCountInMenuBar)
                Toggle("Play sound effects when quitting", isOn: $state.soundEnabled)
                Toggle("Provide trackpad haptic feedback", isOn: $state.hapticsEnabled)
            } header: {
                Text("Startup & Feedback")
            }
            
            Section {
                Toggle("Show background & helper applications", isOn: $state.showBackgroundApps)
                    .onChange(of: state.showBackgroundApps) { _ in
                        state.refreshApps()
                    }
                
                Toggle("Group background applications at the bottom", isOn: $state.groupBackgroundApps)
                
                Toggle("Automatically protect media & music apps (Spotify, Music, etc.)", isOn: $state.skipMusicApps)
                    .onChange(of: state.skipMusicApps) { _ in
                        state.refreshApps()
                    }
            } header: {
                Text("Application Display")
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Protected Apps Tab
    private var protectedTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Protected apps will never be quit during 'Quit All' or 'Quit Others' operations.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            HStack {
                TextField("Add bundle identifier (e.g. com.apple.Safari)...", text: $newBundleIDText)
                    .textFieldStyle(.roundedBorder)
                
                Button("Add") {
                    let trimmed = newBundleIDText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    state.protectedBundleIDs.insert(trimmed)
                    state.saveProtectedIDs()
                    state.refreshApps()
                    newBundleIDText = ""
                }
                .disabled(newBundleIDText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            List {
                ForEach(Array(state.protectedBundleIDs).sorted(), id: \.self) { bundleID in
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 11))
                        Text(bundleID)
                            .font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Button {
                            state.protectedBundleIDs.remove(bundleID)
                            state.saveProtectedIDs()
                            state.refreshApps()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.bordered)
            
            HStack {
                Button("Reset to Defaults") {
                    state.protectedBundleIDs = AppManager.defaultProtectedBundleIDs
                    state.saveProtectedIDs()
                    state.refreshApps()
                }
                .font(.system(size: 11))
                Spacer()
                Text("\(state.protectedBundleIDs.count) apps protected")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
    }
    
    // MARK: - Auto-Quit Inactivity Tab
    private var inactivityTab: some View {
        Form {
            Section {
                Toggle("Automatically quit apps when inactive", isOn: $state.autoQuitInactiveEnabled)
                    .onChange(of: state.autoQuitInactiveEnabled) { _ in
                        state.updateInactivityWatchdog()
                    }
                
                if state.autoQuitInactiveEnabled {
                    Picker("Quit inactive apps after:", selection: $state.autoQuitInactiveMinutes) {
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("45 minutes").tag(45)
                        Text("1 hour").tag(60)
                        Text("2 hours").tag(120)
                        Text("4 hours").tag(240)
                    }
                    .onChange(of: state.autoQuitInactiveMinutes) { _ in
                        state.updateInactivityWatchdog()
                    }
                }
            } header: {
                Text("Inactivity Watchdog")
            } footer: {
                Text("Background monitor tracks apps that haven't been frontmost. Protected apps are always excluded from auto-quitting.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Shortcuts Tab
    private var shortcutsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Global Keyboard Shortcuts")
                .font(.system(size: 13, weight: .bold))
            
            VStack(spacing: 8) {
                shortcutRow(title: "Toggle QuiteAll HUD", keys: "⌥ ⌘ Q")
                shortcutRow(title: "Force Quit All Apps", keys: "⌥ ⇧ ⌘ Q")
                shortcutRow(title: "Quit Others (Keep Active App)", keys: "⌥ ⌘ O")
            }
            .padding(10)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text("In-App Shortcuts")
                .font(.system(size: 13, weight: .bold))
                .padding(.top, 6)
            
            VStack(spacing: 6) {
                shortcutRow(title: "Hold ⌥ Option", keys: "Instantly switches all buttons to Force Quit")
                shortcutRow(title: "Space", keys: "Toggle app selection")
                shortcutRow(title: "R", keys: "Relaunch selected app")
                shortcutRow(title: "Esc", keys: "Close menu HUD")
            }
            .padding(10)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Spacer()
        }
        .padding(10)
    }
    
    private func shortcutRow(title: String, keys: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
            Spacer()
            Text(keys)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
    
    // MARK: - About Tab
    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(for: .application))
                .resizable()
                .frame(width: 56, height: 56)
            
            Text("QuiteAll")
                .font(.system(size: 18, weight: .bold))
            
            Text("Version 2.0.0 (Native Swift 6 & SwiftUI)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text("The ultimate, lightning-fast app manager & task killer for macOS.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Divider()
                .frame(width: 200)
            
            VStack(spacing: 4) {
                Text("• Zero telemetry, zero bloat, zero background drain")
                Text("• Accurate real-time CPU & RAM metrics via libproc")
                Text("• Reverse engineered from QuitAll with REA & rebuilt for macOS")
            }
            .font(.system(size: 11))
            .foregroundColor(.secondary.opacity(0.8))
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
    }
}
