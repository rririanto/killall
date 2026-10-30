import SwiftUI

public struct SummaryBannerView: View {
    let message: String
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundColor(.green)
                .font(.system(size: 13, weight: .bold))
            Text(message)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.green.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
    }
}
