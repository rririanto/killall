import SwiftUI

public struct ResourceGauge: View {
    let cpuPercent: Double
    let formattedMemory: String
    
    public init(cpuPercent: Double, formattedMemory: String) {
        self.cpuPercent = cpuPercent
        self.formattedMemory = formattedMemory
    }
    
    private var cpuColor: Color {
        if cpuPercent >= 50.0 {
            return Color.red
        } else if cpuPercent >= 20.0 {
            return Color.orange
        } else if cpuPercent >= 5.0 {
            return Color.blue
        } else {
            return Color.secondary.opacity(0.8)
        }
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // CPU Pill
            HStack(spacing: 3) {
                Circle()
                    .fill(cpuColor)
                    .frame(width: 5, height: 5)
                Text(cpuPercent > 0.0 ? String(format: "%.1f%%", cpuPercent) : "0%")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(cpuColor)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(cpuColor.opacity(0.12))
            .clipShape(Capsule())
            
            // RAM Pill
            HStack(spacing: 3) {
                Image(systemName: "memorychip")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                Text(formattedMemory)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary.opacity(0.85))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(Color.primary.opacity(0.06))
            .clipShape(Capsule())
        }
    }
}
