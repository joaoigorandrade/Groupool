import SwiftUI

extension View {
    func treasuryCardStyle(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 8,
        shadowOpacity: Double = 0.05
    ) -> some View {
        self
            .padding(padding)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: 4
            )
    }
}
