import SwiftUI

struct WithdrawalView: View {
    var body: some View {
        VStack {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.3))
                .padding()
            
            Text("Request Withdrawal")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Content Coming Soon")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Withdrawal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WithdrawalView()
    }
}
