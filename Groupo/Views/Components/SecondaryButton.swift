
import SwiftUI

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            buttonLabel
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var buttonLabel: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.headlineText)
            }
            
            Text(title)
                .font(.bodyBold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .foregroundColor(.brandTeal)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack {
        SecondaryButton(title: "Cancel", action: {})
        SecondaryButton(title: "Learn More", icon: "info.circle", action: {})
    }
    .padding()
}
