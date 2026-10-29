import SwiftUI

public struct HUDNavigationState {
    public static func handleArrowNavigation(currentIndex: Int, totalCount: Int, isUp: Bool) -> Int {
        guard totalCount > 0 else { return 0 }
        if isUp {
            return max(0, currentIndex - 1)
        } else {
            return min(totalCount - 1, currentIndex + 1)
        }
    }
    
    public static func handleEscapeKey(
        hasSearchText: Bool,
        clearSearch: () -> Void,
        dismiss: () -> Void
    ) {
        if hasSearchText {
            clearSearch()
        } else {
            dismiss()
        }
    }
}

public struct MenuBarHUDView: View {
    @ObservedObject var state: AppState
    @FocusState private var isSearchFocused: Bool
    @State private var highlightedIndex: Int = 0
    @State private var keyMonitor: Any? = nil
    var onOpenSettings: () -> Void
    var onQuitApp: () -> Void
    var onDismiss: () -> Void
    
    public init(
        state: AppState,
        onOpenSettings: @escaping () -> Void,
        onQuitApp: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.state = state
        self.onOpenSettings = onOpenSettings
        self.onQuitApp = onQuitApp
        self.onDismiss = onDismiss ?? {}
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - 1. Top "Quit All" Action Button
            topActionButton
            
            // MARK: - 2. Select All Checkbox + Search Bar Row
            searchAndSelectRow
                .padding(.bottom, 6)
            
            // MARK: - 3. Application List
            appListScrollView
            
            // MARK: - 4. Bottom Hint & Settings Bar
            bottomBar
        }
        .frame(width: 300, height: 380)
        .onAppear {
            setupKeyboardMonitor()
        }
        .onDisappear {
            teardownKeyboardMonitor()
        }
    }
    
    // MARK: - 1. Top Action Button
    private var topActionButton: some View {
        let hasSelection = state.selectedCount > 0
        let isAll = state.selectedCount == state.quitableCount && state.quitableCount > 0
        
        return Button {
            if hasSelection && !isAll {
                state.quitSelected(force: state.isOptionKeyPressed)
            } else {
                state.quitAll(force: state.isOptionKeyPressed)
            }
        } label: {
            HStack(spacing: 6) {
                if state.isOptionKeyPressed {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 13, weight: .bold))
                }
                Text(state.actionButtonTitle)
                    .font(.system(size: 14.5, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                state.isActionButtonDisabled
                ? Color.secondary.opacity(0.2)
                : (state.isOptionKeyPressed ? Color.red : Color(red: 0.05, green: 0.52, blue: 1.0))
            )
            .foregroundColor(state.isActionButtonDisabled ? .secondary.opacity(0.6) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(state.isActionButtonDisabled)
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    
    // MARK: - 2. Select All + Search Bar
    private var searchAndSelectRow: some View {
        HStack(spacing: 8) {
            // Select All Checkbox
            Button {
                state.toggleSelectAll()
            } label: {
                let targetApps = state.filteredAndSortedApps.filter { !$0.isProtected }
                let allSelected = !targetApps.isEmpty && targetApps.allSatisfy { $0.isSelected }
                Image(systemName: allSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundColor(allSelected ? Color(red: 0.05, green: 0.52, blue: 1.0) : Color.secondary.opacity(0.55))
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .help("Select all / Deselect all")
            
            // Search Input Field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                TextField("Search", text: $state.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isSearchFocused)
                
                if !state.searchText.isEmpty {
                    Button {
                        state.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .padding(.horizontal, 10)
    }
    
    // MARK: - 3. App List
    private var appListScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 1) {
                    let items = state.filteredAndSortedApps
                    if items.isEmpty {
                        VStack(spacing: 8) {
                            Text("No apps running")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                                .padding(.top, 30)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, app in
                            AppRowView(app: app, state: state, isHighlighted: index == highlightedIndex)
                                .id(app.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    highlightedIndex = index
                                }
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
            .onChange(of: highlightedIndex) { newIndex in
                let items = state.filteredAndSortedApps
                if newIndex >= 0 && newIndex < items.count {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        proxy.scrollTo(items[newIndex].id, anchor: .center)
                    }
                }
            }
            .onChange(of: state.searchText) { _ in
                highlightedIndex = 0
            }
        }
    }
    
    // MARK: - 4. Bottom Hint & Settings Bar
    private var bottomBar: some View {
        HStack {
            if let msg = state.reclaimedMemoryMessage {
                Text(msg)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.green)
                    .lineLimit(1)
            } else {
                Text("Click ••• above for options 👆")
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button {
                onOpenSettings()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Preferences...")
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }
    
    // MARK: - Keyboard Event Handling
    
    private func setupKeyboardMonitor() {
        teardownKeyboardMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            return handleKeyEvent(event)
        }
    }
    
    private func teardownKeyboardMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        let items = state.filteredAndSortedApps
        
        switch event.keyCode {
        case 126: // Up Arrow
            if !items.isEmpty {
                highlightedIndex = HUDNavigationState.handleArrowNavigation(
                    currentIndex: highlightedIndex,
                    totalCount: items.count,
                    isUp: true
                )
            }
            return nil
            
        case 125: // Down Arrow
            if !items.isEmpty {
                highlightedIndex = HUDNavigationState.handleArrowNavigation(
                    currentIndex: highlightedIndex,
                    totalCount: items.count,
                    isUp: false
                )
            }
            return nil
            
        case 49: // Space
            if !isSearchFocused || state.searchText.isEmpty {
                if highlightedIndex >= 0 && highlightedIndex < items.count {
                    state.toggleSelect(app: items[highlightedIndex])
                    return nil
                }
            }
            return event
            
        case 15: // 'R' key (Relaunch)
            if !isSearchFocused {
                if highlightedIndex >= 0 && highlightedIndex < items.count {
                    state.restart(app: items[highlightedIndex])
                    return nil
                }
            }
            return event
            
        case 36: // Return / Enter
            if !isSearchFocused {
                if state.selectedCount > 0 {
                    state.quitSelected(force: state.isOptionKeyPressed)
                } else if highlightedIndex >= 0 && highlightedIndex < items.count {
                    let app = items[highlightedIndex]
                    if state.isOptionKeyPressed {
                        state.forceQuit(app: app)
                    } else {
                        state.quit(app: app)
                    }
                }
                return nil
            }
            return event
            
        case 53: // Escape
            HUDNavigationState.handleEscapeKey(
                hasSearchText: isSearchFocused && !state.searchText.isEmpty,
                clearSearch: {
                    state.searchText = ""
                },
                dismiss: {
                    onDismiss()
                }
            )
            return nil
            
        default:
            return event
        }
    }
}
