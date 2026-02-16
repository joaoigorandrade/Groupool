
import SwiftUI

struct CardContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding()
        .background(Color("PrimaryBackground"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
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
