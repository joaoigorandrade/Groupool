
import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var backgroundColor: Color = .brandTeal
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.impact(style: .medium)
            action()
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                }
                
                if let icon = icon, !isLoading {
                    Image(systemName: icon)
                    .font(.headlineText)
                }
                
                Text(title)
                    .font(.bodyBold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isDisabled || isLoading ? Color.gray : backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .contentShape(Rectangle())
        }
        .disabled(isDisabled || isLoading)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
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
