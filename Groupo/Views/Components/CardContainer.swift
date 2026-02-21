import SwiftUI

struct CardContainer<Content: View>: View {
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color.appPrimaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        Color.appSecondaryBackground
            .ignoresSafeArea()
        
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Title")
                    .font(.titleLarge)
                Text("Content inside the card container.")
                    .font(.body)
            }
        }
        .padding()
    }
}
