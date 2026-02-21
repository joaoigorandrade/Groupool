
import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var backgroundColor: Color = .brandTeal
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: handleAction) {
            buttonLabel
        }
        .disabled(isDisabled || isLoading)
        .overlay(borderOverlay)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var buttonLabel: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.headlineText)
            }
            
            Text(title)
                .font(.bodyBold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(currentBackgroundColor)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.3), lineWidth: 1)
            .allowsHitTesting(false)
    }
    
    // MARK: - Helpers
    
    private var currentBackgroundColor: Color {
        isDisabled || isLoading ? .gray : backgroundColor
    }
    
    private func handleAction() {
        HapticManager.impact(style: .medium)
        action()
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Active Button", icon: "arrow.right") {}
        PrimaryButton(title: "Loading", isLoading: true) {}
        PrimaryButton(title: "Disabled", isDisabled: true) {}
    }
    .padding()
}
