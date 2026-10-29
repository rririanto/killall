import SwiftUI

public struct FilterBarView: View {
    @ObservedObject var state: AppState
    
    public init(state: AppState) {
        self.state = state
    }
    
    private func count(for category: FilterCategory) -> Int {
        switch category {
        case .all:
            return state.apps.count
        case .dock:
            return state.apps.filter { !$0.isBackground }.count
        case .background:
            return state.apps.filter { $0.isBackground }.count
        case .resourceHogs:
            return state.apps.filter { $0.cpuPercent >= 5.0 || $0.memoryBytes >= 500 * 1024 * 1024 }.count
        case .protected:
            return state.apps.filter { $0.isProtected }.count
        }
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(FilterCategory.allCases) { category in
                        let isSelected = state.selectedFilter == category
                        let itemCount = count(for: category)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                state.selectedFilter = category
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 9, weight: .semibold))
                                Text(category.title)
                                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                                Text("\(itemCount)")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(isSelected ? Color.white.opacity(0.25) : Color.primary.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                isSelected
                                ? AnyShapeStyle(Color.accentColor)
                                : AnyShapeStyle(Color.primary.opacity(0.05))
                            )
                            .foregroundColor(isSelected ? .white : .primary.opacity(0.8))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
            
            Spacer(minLength: 4)
            
            // Sort Menu
            Menu {
                ForEach(SortOption.allCases) { option in
                    Button {
                        state.sortOption = option
                    } label: {
                        HStack {
                            Text(option.title)
                            if state.sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(5)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Circle())
            }
            .menuStyle(.borderlessButton)
            .help("Sort apps")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }
}
