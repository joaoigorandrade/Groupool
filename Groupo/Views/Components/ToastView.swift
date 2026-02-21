import SwiftUI

struct ToastView: View {
    @EnvironmentObject private var toastManager: ToastManager
    
    var body: some View {
        VStack {
            if let toast = toastManager.toast {
                toastContent(for: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toastManager.toast)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func toastContent(for toast: Toast) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: toast.style.iconFileName)
                .foregroundColor(toast.style.themeColor)
                .font(.system(size: 24))
            
            Text(toast.message)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color.appPrimaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.top, 50)
        .onTapGesture {
            toastManager.dismiss()
        }
    }
}

#Preview {
    ToastView()
        .environmentObject(ToastManager())
}
