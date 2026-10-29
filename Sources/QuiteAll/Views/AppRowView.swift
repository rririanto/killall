import SwiftUI

public struct AppRowView: View {
    let app: AppItem
    @ObservedObject var state: AppState
    var isHighlighted: Bool = false
    @State private var isHovered: Bool = false
    
    public init(app: AppItem, state: AppState, isHighlighted: Bool = false) {
        self.app = app
        self.state = state
        self.isHighlighted = isHighlighted
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // 1. Checkbox (Square like QuitAll)
            Button {
                state.toggleSelect(app: app)
            } label: {
                if app.isProtected {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(nsColor: .systemBlue))
                } else if app.isSelected {
                    Image(systemName: "checkmark.square.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color(nsColor: .systemBlue))
                } else {
                    Image(systemName: "square")
                        .font(.system(size: 15))
                        .foregroundColor(Color.secondary.opacity(0.45))
                }
            }
            .buttonStyle(.plain)
            .disabled(app.isProtected)
            
            // 2. App Icon
            Image(nsImage: app.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            
            // 3. App Name
            Text(app.name)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(app.isProtected ? .secondary : .primary)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer(minLength: 4)
            
            // 4. Options Menu (•••)
            Menu {
                Button(app.isProtected ? "Unprotect (Allow Quitting)" : "Protect (Never Quit)") {
                    state.toggleProtection(app: app)
                }
                Button("Relaunch App") {
                    state.restart(app: app)
                }
                Button("Quit Others") {
                    state.quitOthers(preservingPID: app.id, force: state.isOptionKeyPressed)
                }
                Divider()
                Button(app.isHidden ? "Unhide" : "Hide") {
                    AppManager.shared.toggleHide(app: app)
                }
                Button("Reveal in Finder") {
                    AppManager.shared.revealInFinder(app: app)
                }
                Divider()
                Text("RAM: \(app.formattedMemory)")
                Text("PID: \(app.id)")
                if let bundleID = app.bundleIdentifier {
                    Text("ID: \(bundleID)")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isHovered ? .primary.opacity(0.8) : .secondary.opacity(0.6))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            
            // 5. CPU Percentage (Never wraps!)
            Text(app.formattedCPU)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(cpuColor)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(width: 44, alignment: .trailing)
            
            // 6. Single Quit Button (Power icon like QuitAll)
            if !app.isProtected {
                Button {
                    if state.isOptionKeyPressed {
                        state.forceQuit(app: app)
                    } else {
                        state.quit(app: app)
                    }
                } label: {
                    Group {
                        if state.isOptionKeyPressed {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                        } else {
                            Image(systemName: "power")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(isHovered ? .red : .secondary.opacity(0.75))
                        }
                    }
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(
                                state.isOptionKeyPressed
                                ? Color.red.opacity(0.18)
                                : (isHovered ? Color.red.opacity(0.12) : Color.primary.opacity(0.04))
                            )
                    )
                }
                .buttonStyle(.plain)
                .help(state.isOptionKeyPressed ? "Force Quit (⌥)" : "Quit")
            } else {
                Color.clear
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 3.5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    isHighlighted
                    ? Color.accentColor.opacity(0.12)
                    : (isHovered ? Color.primary.opacity(0.04) : Color.clear)
                )
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var cpuColor: Color {
        if app.cpuPercent >= 50.0 {
            return .red
        } else if app.cpuPercent >= 20.0 {
            return .orange
        } else {
            return .secondary.opacity(0.85)
        }
    }
}
