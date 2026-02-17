import SwiftUI
import Combine

enum ToastStyle {
    case success
    case error
    case warning
    case info
    
    var themeColor: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
    
    var iconFileName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct Toast: Equatable {
    var style: ToastStyle
    var message: String
    var duration: Double = 3.0
    var width: Double = .infinity
}

class ToastManager: ObservableObject {
    @Published var toast: Toast?
    
    func show(style: ToastStyle, message: String, duration: Double = 3.0) {
        switch style {
        case .success: HapticManager.notification(type: .success)
        case .error: HapticManager.notification(type: .error)
        case .warning: HapticManager.notification(type: .warning)
        case .info: HapticManager.selection()
        }

        withAnimation {
            self.toast = Toast(style: style, message: message, duration: duration)
        }
        
        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation {
                    self.toast = nil
                }
            }
        }
    }
    
    func dismiss() {
        withAnimation {
            self.toast = nil
        }
    }
}
