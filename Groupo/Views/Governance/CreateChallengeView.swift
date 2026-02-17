import SwiftUI

struct CreateChallengeView: View {
    var body: some View {
        VStack {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.3))
                .padding()
            
            Text("Create Challenge")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Content Coming Soon")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Create Challenge")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CreateChallengeView()
    }
}
