import SwiftUI

struct ToastView: View {
    @EnvironmentObject var toastManager: ToastManager
    
    var body: some View {
        VStack {
            if let toast = toastManager.toast {
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
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 4)
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toastManager.toast)
                .onTapGesture {
                    toastManager.dismiss()
                }
                .padding(.top, 50) // Adjust for status bar/safe area
            }
            Spacer()
        }
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ToastView()
            .environmentObject(ToastManager())
    }
}
